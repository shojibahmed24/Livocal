import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/services/call_audio_pipeline.dart';
import 'package:livocal/features/calls/services/webrtc_call_client.dart';

void main() {
  group('WebRtcCallClient.tuneAudioSdp (A1. Opus FEC & DTX)', () {
    test('Injects useinbandfec=1 and usedtx=1 when fmtp line does not exist', () {
      const originalSdp = '''
v=0
o=- 123456 2 IN IP4 127.0.0.1
s=-
t=0 0
m=audio 9 UDP/TLS/RTP/SAVPF 111 0 8
c=IN IP4 0.0.0.0
a=rtpmap:111 opus/48000/2
a=sendrecv
''';

      final tuned = WebRtcCallClient.tuneAudioSdp(originalSdp);

      expect(tuned.contains('a=fmtp:111'), isTrue);
      expect(tuned.contains('useinbandfec=1'), isTrue);
      expect(tuned.contains('usedtx=1'), isTrue);
      expect(tuned.contains('minptime=10'), isTrue);
    });

    test('Updates existing fmtp line to enforce useinbandfec=1 and usedtx=1', () {
      const originalSdp = '''
v=0
m=audio 9 UDP/TLS/RTP/SAVPF 111 0 8
a=rtpmap:111 opus/48000/2
a=fmtp:111 minptime=20;useinbandfec=0
a=sendrecv
''';

      final tuned = WebRtcCallClient.tuneAudioSdp(originalSdp);

      expect(tuned.contains('useinbandfec=1'), isTrue);
      expect(tuned.contains('useinbandfec=0'), isFalse);
      expect(tuned.contains('usedtx=1'), isTrue);
    });

    test('Preserves other parameters on existing fmtp line', () {
      const originalSdp = '''
v=0
m=audio 9 UDP/TLS/RTP/SAVPF 96
a=rtpmap:96 opus/48000/2
a=fmtp:96 maxaveragebitrate=64000;cbr=0
''';

      final tuned = WebRtcCallClient.tuneAudioSdp(originalSdp);

      expect(tuned.contains('a=fmtp:96'), isTrue);
      expect(tuned.contains('maxaveragebitrate=64000'), isTrue);
      expect(tuned.contains('cbr=0'), isTrue);
      expect(tuned.contains('useinbandfec=1'), isTrue);
      expect(tuned.contains('usedtx=1'), isTrue);
    });

    test('Handles empty or non-Opus SDP gracefully without crashing', () {
      expect(WebRtcCallClient.tuneAudioSdp(''), equals(''));

      const noOpusSdp = '''
m=audio 9 UDP/TLS/RTP/SAVPF 0 8
a=rtpmap:0 PCMU/8000
a=rtpmap:8 PCMA/8000
''';
      expect(WebRtcCallClient.tuneAudioSdp(noOpusSdp), equals(noOpusSdp));
    });
  });

  group('CallAudioMode & Ducking Model (A3. Original Voice Path)', () {
    test('CallAudioMode enum has expected values and labels', () {
      expect(CallAudioMode.values.length, equals(3));
      expect(CallAudioMode.translatedOnly.value, equals('translated_only'));
      expect(CallAudioMode.ducking.value, equals('ducking'));
      expect(CallAudioMode.originalOnly.value, equals('original_only'));
    });

    test('CallAudioPipeline initializes cleanly with single AI player, tuned VAD & barge-in thresholds', () {
      final pipeline = CallAudioPipeline();
      expect(pipeline.isInitialized, isFalse);
      expect(pipeline.isMuted, isFalse);
      expect(pipeline.audioMode, equals(CallAudioMode.translatedOnly));
      expect(CallAudioPipeline.vadSilenceThreshold, equals(0.04));
      expect(CallAudioPipeline.bargeInThreshold, equals(0.13)); // C3
      expect(CallAudioPipeline.vadHangoverFrames, equals(7));
      expect(pipeline.isVadVoiceActive, isFalse);
    });
  });

  group('Low Internet Speed & Bandwidth Resilience (B1-B6)', () {
    test('B1 & B2: tuneAudioSdp enforces maxaveragebitrate=32000 for voice clarity and low bandwidth', () {
      const originalSdp = '''
m=audio 9 UDP/TLS/RTP/SAVPF 111
a=rtpmap:111 opus/48000/2
''';
      final tuned = WebRtcCallClient.tuneAudioSdp(originalSdp);
      expect(tuned.contains('maxaveragebitrate=32000'), isTrue);
      expect(tuned.contains('usedtx=1'), isTrue);
    });

    test('B5 & D1: CallNetworkQuality enum represents 3-tier quality states with labels and emojis', () {
      expect(CallNetworkQuality.values, contains(CallNetworkQuality.good));
      expect(CallNetworkQuality.values, contains(CallNetworkQuality.fair));
      expect(CallNetworkQuality.values, contains(CallNetworkQuality.poor));

      expect(CallNetworkQuality.good.label, equals('Good'));
      expect(CallNetworkQuality.fair.label, equals('Fair'));
      expect(CallNetworkQuality.poor.label, equals('Poor'));

      expect(CallNetworkQuality.good.emoji, equals('🟢'));
      expect(CallNetworkQuality.fair.emoji, equals('🟡'));
      expect(CallNetworkQuality.poor.emoji, equals('🔴'));
    });

    test('B5 & D2: CallControllerState handles networkQuality and isLowDataMode', () {
      const state = CallControllerState(
        myLangCode: 'bn',
        peerLangCode: 'en',
        networkQuality: CallNetworkQuality.poor,
        isLowDataModeAutoEnabled: true,
      );

      expect(state.networkQuality, equals(CallNetworkQuality.poor));
      expect(state.isLowDataModeAutoEnabled, isTrue);
      expect(state.isLowDataMode, isTrue);

      final updated = state.copyWith(
        networkQuality: CallNetworkQuality.good,
        isLowDataModeAutoEnabled: false,
      );
      expect(updated.networkQuality, equals(CallNetworkQuality.good));
      expect(updated.isLowDataModeAutoEnabled, isFalse);
    });
  });
}
