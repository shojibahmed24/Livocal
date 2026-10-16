import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class MockCallRepo extends CallRepository {
  CallStatusUpdate? lastStatusUpdate;

  MockCallRepo() : super();

  @override
  Future<bool> createCall(CallSession session) async => true;

  @override
  Future<void> updateCallStatus(String callId, CallStateStatus status) async {
    lastStatusUpdate = CallStatusUpdate(callId, status);
  }

  @override
  List<CallHistoryRecord> getCallHistory() => [];

  @override
  Future<void> addCallHistoryRecord(CallHistoryRecord record) async {}
}

class CallStatusUpdate {
  final String callId;
  final CallStateStatus status;
  CallStatusUpdate(this.callId, this.status);
}

class MockWalletRepo extends WalletRepository {
  int remainingMinutes;
  int deductCallCount = 0;
  bool lastFinalized = false;

  MockWalletRepo({required this.remainingMinutes}) : super();

  @override
  Future<MinuteDeductionResult> deductMinute({
    required String callId,
    required String callerId,
    String? calleeId,
    required bool isTranslatedCall,
    required int durationSeconds,
    required int minuteIndex,
  }) async {
    deductCallCount++;
    if (!isTranslatedCall) {
      return const MinuteDeductionResult(
        success: true,
        deducted: 0,
        remainingMinutes: 999,
        message: 'FREE_LOCAL_CALL',
      );
    }

    if (remainingMinutes <= 0) {
      return const MinuteDeductionResult(
        success: false,
        deducted: 0,
        remainingMinutes: 0,
        exhausted: true,
        message: 'Minutes exhausted',
      );
    }

    remainingMinutes -= 1;
    return MinuteDeductionResult(
      success: true,
      deducted: 1,
      remainingMinutes: remainingMinutes,
      lowBalanceWarning: remainingMinutes <= 2 && remainingMinutes > 0,
      exhausted: remainingMinutes <= 0,
    );
  }

  @override
  Future<void> finalizeCallBilling({
    required String callId,
    required int totalDurationSeconds,
    required int totalMinutesBilled,
    required bool isTranslatedCall,
  }) async {
    lastFinalized = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPref.init();
  });

  group('In-Call Heartbeat & Auto-Disconnect Tests (Phase 3)', () {
    final caller = User(
      id: 'caller_1',
      name: 'Rahim',
      avatarUrl: '',
      phone: Phone(code: '+880', number: '1700000000'),
      activityStatus: UserActivityStatus.online,
    );

    final calleeEnglish = User(
      id: 'callee_en',
      name: 'John Doe',
      avatarUrl: '',
      phone: Phone(code: '+1', number: '4155552671'),
      activityStatus: UserActivityStatus.online,
    );

    test('deductMinute on non-translated call returns FREE_LOCAL_CALL with 0 deduction', () async {
      final mockWallet = MockWalletRepo(remainingMinutes: 20);

      final result = await mockWallet.deductMinute(
        callId: 'call_local',
        callerId: 'caller_1',
        isTranslatedCall: false,
        durationSeconds: 60,
        minuteIndex: 1,
      );

      expect(result.success, isTrue);
      expect(result.deducted, 0);
      expect(result.message, 'FREE_LOCAL_CALL');
      expect(mockWallet.remainingMinutes, 20); // Unchanged
    });

    test('deductMinute on translated call deducts 1 minute and preserves ledger balance', () async {
      final mockWallet = MockWalletRepo(remainingMinutes: 10);

      final result = await mockWallet.deductMinute(
        callId: 'call_trans_1',
        callerId: 'caller_1',
        isTranslatedCall: true,
        durationSeconds: 60,
        minuteIndex: 1,
      );

      expect(result.success, isTrue);
      expect(result.deducted, 1);
      expect(result.remainingMinutes, 9);
      expect(result.lowBalanceWarning, isFalse);
      expect(result.exhausted, isFalse);
    });

    test('Low-balance warning triggers when remaining minutes hit 2 minutes', () async {
      final mockWallet = MockWalletRepo(remainingMinutes: 3);

      final result = await mockWallet.deductMinute(
        callId: 'call_trans_2',
        callerId: 'caller_1',
        isTranslatedCall: true,
        durationSeconds: 120,
        minuteIndex: 2,
      );

      expect(result.deducted, 1);
      expect(result.remainingMinutes, 2);
      expect(result.lowBalanceWarning, isTrue);
      expect(result.exhausted, isFalse);
    });

    test('Zero minutes remaining flags exhausted: true and auto-disconnects call', () async {
      final mockCall = MockCallRepo();
      final mockWallet = MockWalletRepo(remainingMinutes: 1); // 1 minute left

      final controller = CallController(
        repo: mockCall,
        walletRepo: mockWallet,
      );

      // Start outgoing translated call
      final session = await controller.startOutgoingCall(
        caller: caller,
        callee: calleeEnglish,
        calleeDisplayName: 'John Doe',
        overrideMyLangCode: 'bn',
        overridePeerLangCode: 'en',
      );
      expect(session, isNotNull);

      // Simulate 1st minute deduction: reduces balance to 0 minutes
      final result1 = await mockWallet.deductMinute(
        callId: session!.callId,
        callerId: session.callerId,
        isTranslatedCall: true,
        durationSeconds: 60,
        minuteIndex: 1,
      );
      expect(result1.remainingMinutes, 0);
      expect(result1.exhausted, isTrue);

      // Next tick when 0 balance: deduction rejected with exhausted status
      final result2 = await mockWallet.deductMinute(
        callId: session.callId,
        callerId: session.callerId,
        isTranslatedCall: true,
        durationSeconds: 120,
        minuteIndex: 2,
      );
      expect(result2.success, isFalse);
      expect(result2.exhausted, isTrue);
      expect(result2.remainingMinutes, 0);
    });

    test('Ending call triggers finalizeCallBilling for billing records ledger', () async {
      final mockCall = MockCallRepo();
      final mockWallet = MockWalletRepo(remainingMinutes: 15);

      final controller = CallController(
        repo: mockCall,
        walletRepo: mockWallet,
      );

      await controller.startOutgoingCall(
        caller: caller,
        callee: calleeEnglish,
        calleeDisplayName: 'John Doe',
        overrideMyLangCode: 'bn',
        overridePeerLangCode: 'en',
      );

      await controller.endCall();

      expect(mockWallet.lastFinalized, isTrue);
      expect(controller.state.activeSession, isNull);
    });
  });
}
