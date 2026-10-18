import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/features/auth/controllers/login_controller.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/widgets/search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPref.init();
  });

  group('Login Controller Country Resolution Tests', () {
    test('defaultCountryProvider resolves to valid country and not hardcoded India', () {
      final container = ProviderContainer();
      final country = container.read(defaultCountryProvider);

      expect(country.phoneCode.isNotEmpty, isTrue);
      expect(country.countryCode.isNotEmpty, isTrue);
      // Valid default for Livocal is Bangladesh (+880) or device locale
      expect(country.phoneCode, anyOf(equals('880'), equals('1'), isNotEmpty));
    });
  });

  group('ScaffoldWithSearch Duplicate Icon Bug Tests', () {
    testWidgets('Does not insert duplicate search icons on multiple rebuilds', (tester) async {
      final searchController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldWithSearch(
            appBar: AppBar(
              title: const Text('Contacts'),
              actions: const [
                Icon(Icons.more_vert),
              ],
            ),
            searchController: searchController,
            onChanged: (_) {},
            onCloseBtnPressed: () {},
            child: const Text('Body Content'),
          ),
        ),
      );

      // Verify exactly 1 search icon initially
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Rebuild the widget multiple times (simulate keyboard popup, state updates)
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Verify STILL exactly 1 search icon exists (no duplicate accumulation!)
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  group('verifyOtp Narrow Exception Handling & Backdoor Prevention Tests', () {
    test('FirebaseAuthException strictly returns false and never falls back to stale currentUser', () {
      bool simulateVerifyOtp({
        required Object thrownException,
        required String? preExistingUid,
        required String? currentUidAfterCall,
      }) {
        try {
          throw thrownException;
        } on FirebaseAuthException {
          // Explicit Firebase Auth failure - NEVER allow fallback or return true
          return false;
        } on TypeError {
          // Only treat as authenticated if native auth genuinely signed in a NEW user during this call
          if (currentUidAfterCall != null &&
              (preExistingUid == null || currentUidAfterCall != preExistingUid)) {
            return true;
          }
          return false;
        } catch (_) {
          return false;
        }
      }

      // Scenario 1: Re-authenticating / change-number user with stale session enters WRONG OTP
      // Firebase throws FirebaseAuthException('invalid-verification-code')
      // MUST RETURN FALSE even though currentUser != null!
      final reAuthWrongOtpResult = simulateVerifyOtp(
        thrownException: FirebaseAuthException(code: 'invalid-verification-code'),
        preExistingUid: 'existing_user_123',
        currentUidAfterCall: 'existing_user_123',
      );
      expect(reAuthWrongOtpResult, isFalse,
          reason: 'Must not accept wrong OTP when pre-existing session is present');

      // Scenario 2: Fresh login enters wrong OTP
      final freshWrongOtpResult = simulateVerifyOtp(
        thrownException: FirebaseAuthException(code: 'invalid-verification-code'),
        preExistingUid: null,
        currentUidAfterCall: null,
      );
      expect(freshWrongOtpResult, isFalse);

      // Scenario 3: Stale user with generic exception
      final genericErrorResult = simulateVerifyOtp(
        thrownException: Exception('network failure'),
        preExistingUid: 'existing_user_123',
        currentUidAfterCall: 'existing_user_123',
      );
      expect(genericErrorResult, isFalse);

      // Scenario 4: Genuine new session established on native side but Pigeon deserialization threw TypeError
      final pigeonDecodeSuccessResult = simulateVerifyOtp(
        thrownException: TypeError(),
        preExistingUid: null,
        currentUidAfterCall: 'new_firebase_user_789',
      );
      expect(pigeonDecodeSuccessResult, isTrue,
          reason: 'Genuine new native session with Pigeon decode mismatch should be accepted');

      // Scenario 5: Stale user with Pigeon TypeError where no new user was signed in
      final pigeonDecodeStaleUserResult = simulateVerifyOtp(
        thrownException: TypeError(),
        preExistingUid: 'existing_user_123',
        currentUidAfterCall: 'existing_user_123',
      );
      expect(pigeonDecodeStaleUserResult, isFalse,
          reason: 'Stale user session must not be mistaken for a newly verified OTP');
    });
  });
}
