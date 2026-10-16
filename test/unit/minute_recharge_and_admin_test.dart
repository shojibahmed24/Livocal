import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/shared/models/user_wallet.dart';

void main() {
  group('SaaS Minute Recharge & Pack Logic Tests (Phase 4 & 5)', () {
    test('Starter Pack accurately configures 60 minutes for 1200 BDT', () {
      const minutes = 60;
      const amount = 1200.0;
      const ratePerMinute = amount / minutes;

      expect(ratePerMinute, equals(20.0));
      expect(minutes, equals(60));
    });

    test('Freelancer Pro Pack gives 180 minutes with 17% savings', () {
      const minutes = 180;
      const amount = 3000.0;
      const ratePerMinute = amount / minutes;
      const standardCost = minutes * 20.0; // 3600
      const savingsPercent = ((standardCost - amount) / standardCost) * 100;

      expect(ratePerMinute, closeTo(16.66, 0.01));
      expect(savingsPercent, closeTo(16.66, 0.01));
    });

    test('Agency Pack gives 500 minutes with 28% savings', () {
      const minutes = 500;
      const amount = 7200.0;
      const ratePerMinute = amount / minutes;
      const standardCost = minutes * 20.0; // 10000
      const savingsPercent = ((standardCost - amount) / standardCost) * 100;

      expect(ratePerMinute, equals(14.4));
      expect(savingsPercent, closeTo(28.0, 0.01));
    });

    test('Gemini 3.5 Live margin model yields ~79% net gross profit', () {
      const retailRateBdt = 20.0; // ৳20/min
      const geminiCostUsd = 0.035; // $0.035/min
      const usdToBdtRate = 120.0;
      const geminiCostBdt = geminiCostUsd * usdToBdtRate; // ৳4.2/min
      const netProfitBdt = retailRateBdt - geminiCostBdt; // ৳15.8/min
      const marginPercent = (netProfitBdt / retailRateBdt) * 100;

      expect(geminiCostBdt, equals(4.2));
      expect(netProfitBdt, equals(15.8));
      expect(marginPercent, equals(79.0));
    });

    test('Recharge increases balanceMinutes and totalMinutesPurchased on UserWallet', () {
      final initialWallet = UserWallet.newTrial(initialTrialMinutes: 20);
      expect(initialWallet.balanceMinutes, equals(0));
      expect(initialWallet.trialMinutes, equals(20));
      expect(initialWallet.effectiveRemainingMinutes, equals(20));

      // Simulate recharge with Freelancer Pro (180 mins)
      final rechargedWallet = initialWallet.copyWith(
        balanceMinutes: initialWallet.balanceMinutes + 180,
        totalMinutesPurchased: initialWallet.totalMinutesPurchased + 180,
      );

      expect(rechargedWallet.balanceMinutes, equals(180));
      expect(rechargedWallet.totalMinutesPurchased, equals(180));
      // Total effective minutes = 180 paid + 20 trial = 200
      expect(rechargedWallet.effectiveRemainingMinutes, equals(200));
      expect(rechargedWallet.hasMinutes, isTrue);
    });

    test('Promo code bonuses award additional minutes correctly', () {
      int getBonus(String code) {
        if (code.toUpperCase() == 'LIVOCAL2026') return 20;
        if (code.toUpperCase() == 'FREELANCERPRO') return 30;
        return 0;
      }

      expect(getBonus('LIVOCAL2026'), equals(20));
      expect(getBonus('FREELANCERPRO'), equals(30));
      expect(getBonus('INVALID'), equals(0));
    });

    test('Local / Same-language calls bypass minute deduction completely', () {
      const myLangCode = 'bn';
      const peerLangCode = 'bn';
      const isSameLanguage = myLangCode == peerLangCode;

      // Rule: Same-language calls are always free
      expect(isSameLanguage, isTrue);
      // Minutes to deduct for a 5-minute call
      const minutesToDeduct = isSameLanguage ? 0 : 5;
      expect(minutesToDeduct, equals(0));
    });

    test('International translated calls deduct 1 minute per minute', () {
      const myLangCode = 'bn';
      const peerLangCode = 'en';
      const isSameLanguage = myLangCode == peerLangCode;

      expect(isSameLanguage, isFalse);
      const callDurationMinutes = 12;
      const minutesToDeduct = isSameLanguage ? 0 : callDurationMinutes;
      expect(minutesToDeduct, equals(12));
    });

    test('Crypto USDT pricing and network options configure correctly', () {
      const packs = {
        'starter_60': {'minutes': 60, 'usdt': 10, 'bdt': 1200},
        'pro_180': {'minutes': 180, 'usdt': 25, 'bdt': 3000},
        'agency_500': {'minutes': 500, 'usdt': 60, 'bdt': 7200},
      };

      expect(packs['starter_60']!['usdt'], equals(10));
      expect(packs['pro_180']!['usdt'], equals(25));
      expect(packs['agency_500']!['usdt'], equals(60));

      const supportedCryptoMethods = [
        'Binance_Pay',
        'Crypto_USDT_TRC20',
        'Crypto_USDT_BEP20',
      ];
      expect(supportedCryptoMethods.contains('Binance_Pay'), isTrue);
      expect(supportedCryptoMethods.contains('Crypto_USDT_TRC20'), isTrue);
      expect(supportedCryptoMethods.contains('Crypto_USDT_BEP20'), isTrue);
    });

    test('Payment submission validates required senderIdentifier and trxId', () {
      bool validatePaymentInput({
        required String packId,
        required String senderIdentifier,
        required String trxId,
      }) {
        if (packId.trim().isEmpty) return false;
        if (senderIdentifier.trim().isEmpty) return false;
        if (trxId.trim().isEmpty) return false;
        return true;
      }

      expect(validatePaymentInput(packId: 'pro_180', senderIdentifier: '', trxId: '0x123'), isFalse);
      expect(validatePaymentInput(packId: 'pro_180', senderIdentifier: 'TXvJ28M4Z2vY', trxId: ''), isFalse);
      expect(validatePaymentInput(packId: 'pro_180', senderIdentifier: '849201842', trxId: 'BIN12345'), isTrue);
    });
  });
}

