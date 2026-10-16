import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/models/user_wallet.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class FakeCallRepository extends CallRepository {
  CallSession? lastCreatedSession;

  FakeCallRepository() : super();

  @override
  Future<bool> createCall(CallSession session) async {
    lastCreatedSession = session;
    return true;
  }

  @override
  List<CallHistoryRecord> getCallHistory() => [];

  @override
  Stream<CallSession?> watchCallSession(String callId, String ownId) {
    return const Stream.empty();
  }
}

class FakeWalletRepository extends WalletRepository {
  UserWallet returnedWallet;

  FakeWalletRepository(this.returnedWallet) : super();

  @override
  Future<UserWallet> getWallet(String userId) async {
    return returnedWallet;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPref.init();
  });

  group('CallSession isTranslatedCall (Paid vs Free) Logic', () {
    test('Different languages with translation enabled is a Translated Call', () {
      final session = CallSession(
        callId: 'call_1',
        callerId: 'u1',
        callerName: 'Rahim',
        callerAvatar: '',
        callerPhone: '+8801700000000',
        calleeId: 'u2',
        calleeName: 'John',
        calleeAvatar: '',
        calleePhone: '+14155552671',
        callerLangCode: 'bn',
        calleeLangCode: 'en',
        translationEnabled: true,
        status: CallStateStatus.dialing,
        isIncoming: false,
        createdAt: DateTime.now(),
      );

      expect(session.isTranslatedCall, isTrue);
      expect(session.toMap()['isTranslatedCall'], isTrue);
    });

    test('Same languages with translation enabled is a Free Local Call', () {
      final session = CallSession(
        callId: 'call_2',
        callerId: 'u1',
        callerName: 'Rahim',
        callerAvatar: '',
        callerPhone: '+8801700000000',
        calleeId: 'u2',
        calleeName: 'Karim',
        calleeAvatar: '',
        calleePhone: '+8801800000000',
        callerLangCode: 'bn',
        calleeLangCode: 'BN', // case insensitive
        translationEnabled: true,
        status: CallStateStatus.dialing,
        isIncoming: false,
        createdAt: DateTime.now(),
      );

      expect(session.isTranslatedCall, isFalse);
      expect(session.toMap()['isTranslatedCall'], isFalse);
    });

    test('Different languages with translation disabled is a Free Local Call', () {
      final session = CallSession(
        callId: 'call_3',
        callerId: 'u1',
        callerName: 'Rahim',
        callerAvatar: '',
        callerPhone: '+8801700000000',
        calleeId: 'u2',
        calleeName: 'John',
        calleeAvatar: '',
        calleePhone: '+14155552671',
        callerLangCode: 'bn',
        calleeLangCode: 'en',
        translationEnabled: false,
        status: CallStateStatus.dialing,
        isIncoming: false,
        createdAt: DateTime.now(),
      );

      expect(session.isTranslatedCall, isFalse);
      expect(session.toMap()['isTranslatedCall'], isFalse);
    });
  });

  group('CallHistoryRecord isTranslatedCall Logic', () {
    test('History record correctly identifies translated vs free call', () {
      final now = DateTime.now();
      final translatedRecord = CallHistoryRecord(
        callId: 'c1',
        peerId: 'p1',
        peerName: 'Alex',
        peerAvatar: '',
        peerPhone: '+1000000000',
        timestamp: now,
        durationSeconds: 120,
        isIncoming: false,
        isMissed: false,
        translationEnabled: true,
        myLangCode: 'bn',
        peerLangCode: 'en',
      );
      expect(translatedRecord.isTranslatedCall, isTrue);

      final sameLangRecord = CallHistoryRecord(
        callId: 'c2',
        peerId: 'p2',
        peerName: 'Sujon',
        peerAvatar: '',
        peerPhone: '+8801700000000',
        timestamp: now,
        durationSeconds: 65,
        isIncoming: true,
        isMissed: false,
        translationEnabled: true,
        myLangCode: 'bn',
        peerLangCode: 'bn',
      );
      expect(sameLangRecord.isTranslatedCall, isFalse);
    });
  });

  group('CallController Pre-Call Gatekeeper Tests', () {
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

    final calleeBangla = User(
      id: 'callee_bn',
      name: 'Karim Ullah',
      avatarUrl: '',
      phone: Phone(code: '+880', number: '1800000000'),
      activityStatus: UserActivityStatus.online,
    );

    test('Zero minutes blocks translated call (myLang bn -> peerLang en)', () async {
      final fakeCallRepo = FakeCallRepository();
      final emptyWallet = UserWallet.noTrial(); // 0 minutes
      final fakeWalletRepo = FakeWalletRepository(emptyWallet);

      final controller = CallController(
        repo: fakeCallRepo,
        walletRepo: fakeWalletRepo,
      );

      final session = await controller.startOutgoingCall(
        caller: caller,
        callee: calleeEnglish,
        calleeDisplayName: 'John Doe',
        overrideMyLangCode: 'bn',
        overridePeerLangCode: 'en',
      );

      expect(session, isNull);
      expect(controller.state.error, equals('INSUFFICIENT_MINUTES'));
      expect(controller.state.activeSession, isNull);
    });

    test('Active trial/paid minutes allows translated call to proceed', () async {
      final fakeCallRepo = FakeCallRepository();
      final activeWallet = UserWallet.newTrial(); // 20 minutes
      final fakeWalletRepo = FakeWalletRepository(activeWallet);

      final controller = CallController(
        repo: fakeCallRepo,
        walletRepo: fakeWalletRepo,
      );

      final session = await controller.startOutgoingCall(
        caller: caller,
        callee: calleeEnglish,
        calleeDisplayName: 'John Doe',
        overrideMyLangCode: 'bn',
        overridePeerLangCode: 'en',
      );

      expect(session, isNotNull);
      expect(controller.state.error, isNull);
      expect(session!.isTranslatedCall, isTrue);
    });

    test('Zero minutes does NOT block same-language call (Free Local Call)', () async {
      final fakeCallRepo = FakeCallRepository();
      final emptyWallet = UserWallet.noTrial(); // 0 minutes
      final fakeWalletRepo = FakeWalletRepository(emptyWallet);

      final controller = CallController(
        repo: fakeCallRepo,
        walletRepo: fakeWalletRepo,
      );

      final session = await controller.startOutgoingCall(
        caller: caller,
        callee: calleeBangla,
        calleeDisplayName: 'Karim Ullah',
        overrideMyLangCode: 'bn',
        overridePeerLangCode: 'bn',
      );

      expect(session, isNotNull);
      expect(controller.state.error, isNull);
      expect(session!.isTranslatedCall, isFalse);
    });

    test('Zero minutes does NOT block call when translationEnabled is false (Free Local Call)', () async {
      final fakeCallRepo = FakeCallRepository();
      final emptyWallet = UserWallet.noTrial(); // 0 minutes
      final fakeWalletRepo = FakeWalletRepository(emptyWallet);

      final controller = CallController(
        repo: fakeCallRepo,
        walletRepo: fakeWalletRepo,
      );

      final session = await controller.startOutgoingCall(
        caller: caller,
        callee: calleeEnglish,
        calleeDisplayName: 'John Doe',
        overrideMyLangCode: 'bn',
        overridePeerLangCode: 'en',
        translationEnabled: false,
      );

      expect(session, isNotNull);
      expect(controller.state.error, isNull);
      expect(session!.isTranslatedCall, isFalse);
    });
  });
}
