import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/models/user_wallet.dart';
import 'package:livocal/shared/services/device_fingerprint_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserWallet Model Tests', () {
    test('UserWallet.newTrial generates valid 14-day 20-minute trial', () {
      final now = DateTime.now();
      final wallet = UserWallet.newTrial(now: now);

      expect(wallet.balanceMinutes, 0);
      expect(wallet.trialMinutes, 20);
      expect(wallet.trialActive, isTrue);
      expect(wallet.isTrialExpired, isFalse);
      expect(wallet.effectiveTrialMinutes, 20);
      expect(wallet.effectiveRemainingMinutes, 20);
      expect(wallet.hasMinutes, isTrue);
      expect(wallet.daysRemainingInTrial, greaterThanOrEqualTo(13));
      expect(wallet.daysRemainingInTrial, lessThanOrEqualTo(14));
      expect(wallet.currency, 'BDT');
    });

    test('UserWallet.noTrial initializes zero trial for repeat devices', () {
      final now = DateTime.now();
      final wallet = UserWallet.noTrial(now: now);

      expect(wallet.balanceMinutes, 0);
      expect(wallet.trialMinutes, 0);
      expect(wallet.trialActive, isFalse);
      expect(wallet.effectiveTrialMinutes, 0);
      expect(wallet.effectiveRemainingMinutes, 0);
      expect(wallet.hasMinutes, isFalse);
      expect(wallet.daysRemainingInTrial, 0);
    });

    test('Expired trial correctly zeroes trial minutes while preserving paid balance', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 15));
      final wallet = UserWallet(
        balanceMinutes: 45,
        trialMinutes: 20,
        trialActive: true,
        trialExpiresAt: pastDate,
        totalMinutesUsed: 10,
        totalMinutesPurchased: 45,
        createdAt: pastDate,
        updatedAt: DateTime.now(),
      );

      expect(wallet.isTrialExpired, isTrue);
      expect(wallet.effectiveTrialMinutes, 0); // Trial expired: 0 usable trial minutes
      expect(wallet.effectiveRemainingMinutes, 45); // Paid balance preserved
      expect(wallet.hasMinutes, isTrue);
      expect(wallet.daysRemainingInTrial, 0);
    });

    test('Expired trial with 0 paid balance correctly reports hasMinutes == false', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final wallet = UserWallet(
        balanceMinutes: 0,
        trialMinutes: 20,
        trialActive: true,
        trialExpiresAt: pastDate,
        createdAt: pastDate,
        updatedAt: DateTime.now(),
      );

      expect(wallet.isTrialExpired, isTrue);
      expect(wallet.effectiveRemainingMinutes, 0);
      expect(wallet.hasMinutes, isFalse);
    });

    test('UserWallet toMap and fromMap serialization round-trip', () {
      final now = DateTime.now();
      final wallet = UserWallet(
        balanceMinutes: 120,
        trialMinutes: 15,
        trialActive: true,
        trialExpiresAt: now.add(const Duration(days: 7)),
        totalMinutesUsed: 25,
        totalMinutesPurchased: 120,
        currency: 'BDT',
        createdAt: now,
        updatedAt: now,
      );

      final map = wallet.toMap();
      expect(map['balanceMinutes'], 120);
      expect(map['trialMinutes'], 15);
      expect(map['trialActive'], isTrue);
      expect(map['trialExpiresAt'], isA<Timestamp>());
      expect(map['currency'], 'BDT');

      final reconstructed = UserWallet.fromMap(map);
      expect(reconstructed.balanceMinutes, 120);
      expect(reconstructed.trialMinutes, 15);
      expect(reconstructed.trialActive, isTrue);
      expect(reconstructed.totalMinutesUsed, 25);
      expect(reconstructed.effectiveRemainingMinutes, 135);
      expect(reconstructed.hasMinutes, isTrue);
    });

    test('UserWallet copyWith updates selected fields immutably', () {
      final wallet = UserWallet.newTrial();
      final updated = wallet.copyWith(
        balanceMinutes: 60,
        trialMinutes: 10,
      );

      expect(updated.balanceMinutes, 60);
      expect(updated.trialMinutes, 10);
      expect(updated.trialActive, wallet.trialActive);
      expect(updated.currency, wallet.currency);
    });
  });

  group('DeviceFingerprintService Tests', () {
    test('DeviceFingerprintService is a singleton instance', () {
      final s1 = DeviceFingerprintService();
      final s2 = DeviceFingerprintService();
      expect(identical(s1, s2), isTrue);
    });
  });
}
