import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:livocal/features/calls/models/call_model.dart';

class CallAudioPipeline {
  static const int inputSampleRate = 16000; // 16kHz PCM16 mono for Gemini Live input
  static const int outputSampleRate = 24000; // 24kHz PCM16 mono for Gemini Live output
  static const int numChannels = 1;
  // 60ms chunk @ 16kHz 16-bit mono = 960 samples * 2 bytes = 1920 bytes
  static const int micChunkBytes = 1920;

  final FlutterSoundRecorder _recorder =
      FlutterSoundRecorder(logLevel: Level.error);
  final FlutterSoundPlayer _aiPlayer =
      FlutterSoundPlayer(logLevel: Level.error);

  StreamController<Uint8List>? _micRawController;
  StreamSubscription<Uint8List>? _micRawSubscription;

  final StreamController<Uint8List> _outgoingPcmController =
      StreamController<Uint8List>.broadcast();
  final StreamController<double> _micRmsController =
      StreamController<double>.broadcast();

  Stream<Uint8List> get outgoingMicPcmStream => _outgoingPcmController.stream;
  Stream<double> get micRmsStream => _micRmsController.stream;

  bool _isInitialized = false;
  bool _isMuted = false;
  bool _isSpeakerphoneOn = true;
  bool _isAiCurrentlySpeaking = false;
  CallAudioMode _audioMode = CallAudioMode.translatedOnly;

  bool get isInitialized => _isInitialized;
  bool get isMuted => _isMuted;
  bool get isSpeakerphoneOn => _isSpeakerphoneOn;
  CallAudioMode get audioMode => _audioMode;
  static const double vadSilenceThreshold = 0.04; // Voice threshold above room noise floor
  static const double bargeInThreshold = 0.13; // Calibrated barge-in threshold during AI speakerphone playback (C3)
  static const int vadHangoverFrames = 7; // ~420ms hangover window (7 * 60ms) to preserve word endings

  int _vadSilenceFramesCount = 0;
  bool _isVadActive = false;

  bool get isVadVoiceActive => _isVadActive;

  Future<void> configureVoiceSession({bool defaultToSpeaker = true}) async {
    final session = await AudioSession.instance;
    await session.configure(
      AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                (defaultToSpeaker
                    ? AVAudioSessionCategoryOptions.defaultToSpeaker
                    : AVAudioSessionCategoryOptions.none),
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ),
    );
    await session.setActive(true);
  }

  Future<void> startFullDuplex() async {
    if (_isInitialized) return;

    final micPerm = await Permission.microphone.request();
    if (!micPerm.isGranted) {
      throw Exception('Microphone permission is required for voice calls.');
    }

    await configureVoiceSession(defaultToSpeaker: _isSpeakerphoneOn);

    await _recorder.openRecorder();
    await _aiPlayer.openPlayer();

    await _aiPlayer.startPlayerFromStream(
      codec: Codec.pcm16,
      interleaved: true,
      numChannels: numChannels,
      sampleRate: outputSampleRate,
      bufferSize: 2048, // (C1) Reduced from 4096 to 2048 (~85ms @ 24kHz)
    );

    await _applyVolumesForMode(_audioMode);

    _micRawController = StreamController<Uint8List>();
    final BytesBuilder chunkBuffer = BytesBuilder(copy: false);

    _micRawSubscription = _micRawController!.stream.listen((Uint8List data) {
      if (_isMuted || data.isEmpty) {
        _micRmsController.add(0.0);
        _isVadActive = false;
        _vadSilenceFramesCount = 0;
        chunkBuffer.clear();
        return;
      }

      final rms = _computeNormalizedRms(data);
      _micRmsController.add(rms);

      // Determine active dynamic threshold:
      // When speakerphone is on and AI is speaking, require calibrated barge-in threshold (0.13) to avoid echo loop.
      // Otherwise use VAD speech threshold (0.04) to distinguish voice from room silence.
      final activeThreshold = (_isSpeakerphoneOn && _isAiCurrentlySpeaking)
          ? bargeInThreshold
          : vadSilenceThreshold;

      if (rms >= activeThreshold) {
        _isVadActive = true;
        _vadSilenceFramesCount = 0;
      } else {
        _vadSilenceFramesCount++;
        if (_vadSilenceFramesCount > vadHangoverFrames) {
          _isVadActive = false;
        }
      }

      // If VAD is inactive (prolonged silence), drop the audio frame to save uplink bandwidth & Gemini input tokens
      if (!_isVadActive) {
        if (chunkBuffer.length > 0) {
          chunkBuffer.clear();
        }
        return;
      }

      chunkBuffer.add(data);
      while (chunkBuffer.length >= micChunkBytes) {
        final allBytes = chunkBuffer.takeBytes();
        final frame = Uint8List.fromList(
          Uint8List.sublistView(allBytes, 0, micChunkBytes),
        );
        _outgoingPcmController.add(frame);
        if (allBytes.length > micChunkBytes) {
          chunkBuffer.add(Uint8List.sublistView(allBytes, micChunkBytes));
        }
      }
    });

    await _recorder.startRecorder(
      toStream: _micRawController!.sink,
      codec: Codec.pcm16,
      numChannels: numChannels,
      sampleRate: inputSampleRate,
      bufferSize: 1024, // (C1) Reduced from 2048 to 1024 (~64ms @ 16kHz)
      enableVoiceProcessing: true,
      // Disable redundant software noise suppression when VoiceProcessing is active
      // to avoid double-processing robotic/metallic voice distortion
      enableNoiseSuppression: false,
      enableEchoCancellation: true,
    );

    _isInitialized = true;
  }

  void setAiSpeakingState(bool speaking) {
    _isAiCurrentlySpeaking = speaking;
  }

  void feedTranslatedAiPcm(Uint8List pcm24kChunk) {
    if (!_isInitialized || pcm24kChunk.isEmpty) return;
    if (_audioMode == CallAudioMode.originalOnly) return;
    _aiPlayer.uint8ListSink?.add(pcm24kChunk);
  }

  Future<void> flushAiPlayerBuffer() async {
    if (!_isInitialized) return;
    try {
      await _aiPlayer.stopPlayer();
      await _aiPlayer.startPlayerFromStream(
        codec: Codec.pcm16,
        interleaved: true,
        numChannels: numChannels,
        sampleRate: outputSampleRate,
        bufferSize: 2048, // (C1) Reduced from 4096 to 2048 (~85ms @ 24kHz)
      );
      await _applyVolumesForMode(_audioMode);
    } catch (e) {
      debugPrint('Error flushing AI player buffer: $e');
    }
  }

  Future<void> setAudioMode(CallAudioMode mode) async {
    _audioMode = mode;
    if (!_isInitialized) return;
    await _applyVolumesForMode(mode);
  }

  Future<void> _applyVolumesForMode(CallAudioMode mode) async {
    switch (mode) {
      case CallAudioMode.translatedOnly:
      case CallAudioMode.ducking:
        await _aiPlayer.setVolume(1.0);
        break;
      case CallAudioMode.originalOnly:
        await _aiPlayer.setVolume(0.0);
        break;
    }
  }

  void setMuted(bool muted) {
    _isMuted = muted;
  }

  Future<void> setSpeakerphone(bool speakerOn) async {
    _isSpeakerphoneOn = speakerOn;
    await configureVoiceSession(defaultToSpeaker: speakerOn);
  }

  double _computeNormalizedRms(Uint8List pcm16Bytes) {
    if (pcm16Bytes.length < 2) return 0.0;
    final byteData = ByteData.sublistView(pcm16Bytes);
    final sampleCount = pcm16Bytes.length ~/ 2;
    double sumSquares = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little) / 32768.0;
      sumSquares += sample * sample;
    }
    final rms = math.sqrt(sumSquares / sampleCount);
    return (rms * 3.5).clamp(0.0, 1.0);
  }

  Future<void> dispose() async {
    _isInitialized = false;
    _isAiCurrentlySpeaking = false;
    await _micRawSubscription?.cancel();
    await _micRawController?.close();
    try {
      if (_recorder.isRecording) await _recorder.stopRecorder();
      await _recorder.closeRecorder();
    } catch (e, st) {
      debugPrint('[CallAudioPipeline] closeRecorder error: $e\n$st');
    }
    try {
      if (_aiPlayer.isPlaying) await _aiPlayer.stopPlayer();
      await _aiPlayer.closePlayer();
    } catch (e, st) {
      debugPrint('[CallAudioPipeline] closePlayer (ai) error: $e\n$st');
    }
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e, st) {
      debugPrint('[CallAudioPipeline] session setActive false error: $e\n$st');
    }
  }
}
