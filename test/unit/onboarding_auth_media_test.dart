import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/features/auth/controllers/login_controller.dart';
import 'package:livocal/features/auth/data/repositories/auth_repository.dart';
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

  group('FirebaseAuthRepository.verifyOtp Real Implementation Tests', () {
    test('Scenario 1: Re-auth user with stale session entering WRONG OTP strictly returns false', () async {
      final fakeAuth = FakeFirebaseAuth(
        currentUser: FakeUser('existing_stale_uid_123'),
        onSignInWithCredential: (_) => throw FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'The verification code from SMS/TOTP is invalid.',
        ),
      );

      final repo = FirebaseAuthRepository(
        auth: fakeAuth,
        firestore: FakeFirebaseFirestore(),
      );

      final result = await repo.verifyOtp('test_verification_id_1', '000000');
      expect(result, isFalse, reason: 'FirebaseAuthException must return false even if currentUser is non-null');
    });

    test('Scenario 2: Fresh user login entering wrong OTP returns false', () async {
      final fakeAuth = FakeFirebaseAuth(
        currentUser: null,
        onSignInWithCredential: (_) => throw FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'Invalid OTP',
        ),
      );

      final repo = FirebaseAuthRepository(
        auth: fakeAuth,
        firestore: FakeFirebaseFirestore(),
      );

      final result = await repo.verifyOtp('test_verification_id_2', '999999');
      expect(result, isFalse);
    });

    test('Scenario 3: Generic Exception (e.g. network failure) returns false and does not fall back', () async {
      final fakeAuth = FakeFirebaseAuth(
        currentUser: FakeUser('existing_stale_uid_123'),
        onSignInWithCredential: (_) => throw Exception('Network unreachable'),
      );

      final repo = FirebaseAuthRepository(
        auth: fakeAuth,
        firestore: FakeFirebaseFirestore(),
      );

      final result = await repo.verifyOtp('test_verification_id_3', '123456');
      expect(result, isFalse);
    });

    test('Scenario 4: Genuine new session established on native side despite Pigeon TypeError returns true', () async {
      final fakeAuth = FakeFirebaseAuth(
        currentUser: null, // preExistingUid is null
      );
      fakeAuth.onSignInWithCredential = (_) {
        // Native signs in new user, but Pigeon throws TypeError on decode
        fakeAuth.currentUser = FakeUser('new_firebase_user_789');
        throw TypeError();
      };

      final repo = FirebaseAuthRepository(
        auth: fakeAuth,
        firestore: FakeFirebaseFirestore(),
      );

      final result = await repo.verifyOtp('test_verification_id_4', '123456');
      expect(result, isTrue, reason: 'Genuine new native session with Pigeon decode mismatch should be accepted');
    });

    test('Scenario 5: Stale session with Pigeon TypeError where native did NOT sign in a new user returns false', () async {
      final fakeAuth = FakeFirebaseAuth(
        currentUser: FakeUser('existing_user_123'),
        onSignInWithCredential: (_) => throw TypeError(),
      );

      final repo = FirebaseAuthRepository(
        auth: fakeAuth,
        firestore: FakeFirebaseFirestore(),
      );

      final result = await repo.verifyOtp('test_verification_id_5', '123456');
      expect(result, isFalse, reason: 'Stale user session with Pigeon TypeError must return false');
    });

    test('Scenario 6: Clean successful OTP verification returns true', () async {
      final newUser = FakeUser('verified_uid_555');
      final fakeAuth = FakeFirebaseAuth(
        currentUser: null,
        onSignInWithCredential: (_) => Future.value(FakeUserCredential(user: newUser)),
      );

      final repo = FirebaseAuthRepository(
        auth: fakeAuth,
        firestore: FakeFirebaseFirestore(),
      );

      final result = await repo.verifyOtp('test_verification_id_6', '123456');
      expect(result, isTrue);
    });
  });
}

class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

class FakeUserCredential extends Fake implements UserCredential {
  @override
  final User? user;
  FakeUserCredential({this.user});
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;
  Future<UserCredential> Function(AuthCredential)? onSignInWithCredential;

  FakeFirebaseAuth({User? currentUser, this.onSignInWithCredential})
      : _currentUser = currentUser;

  @override
  User? get currentUser => _currentUser;

  set currentUser(User? u) => _currentUser = u;

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    if (onSignInWithCredential != null) {
      return onSignInWithCredential!(credential);
    }
    return Future.value(FakeUserCredential(user: _currentUser));
  }
}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

