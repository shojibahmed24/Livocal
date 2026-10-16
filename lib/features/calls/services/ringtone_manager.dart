import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

/// Centralized Ringtone and Notification Tone Manager for Livocal.
/// Supports built-in harmonic presets and user-selected custom audio files from device storage.
class RingtoneManager {
  static final RingtoneManager _instance = RingtoneManager._internal();
  factory RingtoneManager() => _instance;
  RingtoneManager._internal();

  AudioPlayer? _ringtonePlayer;
  AudioPlayer get _effectiveRingtonePlayer => _ringtonePlayer ??= AudioPlayer();

  AudioPlayer? _previewPlayer;
  AudioPlayer get _effectivePreviewPlayer => _previewPlayer ??= AudioPlayer();

  bool _isRinging = false;
  bool get isRinging => _isRinging;

  // Cached preset WAV bytes to avoid regenerating repeatedly
  final Map<String, Uint8List> _synthCache = {};

  /// Pre-defined ringtone options
  static const List<String> ringtonePresets = [
    'Livocal Harmony (Default)',
    'Digital Pulse',
    'Marimba Bloom',
    'Classic Bell',
    'Custom (Choose from phone)...',
  ];

  /// Pre-defined message tone options
  static const List<String> messageTonePresets = [
    'Livocal Chime (Default)',
    'Subtle Ding',
    'Crystal Pop',
    'Custom (Choose from phone)...',
  ];

  /// Starts continuous ringing for incoming calls based on user preferences.
  Future<void> startIncomingRingtone() async {
    if (_isRinging) return;
    _isRinging = true;

    try {
      final ringtoneName =
          SharedPref.instance.getString('notif_call_ringtone') ??
              'Livocal Harmony (Default)';
      final customPath =
          SharedPref.instance.getString('notif_custom_ringtone_path');

      final player = _effectiveRingtonePlayer;
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1.0);

      if (customPath != null &&
          customPath.isNotEmpty &&
          File(customPath).existsSync()) {
        await player.play(DeviceFileSource(customPath));
      } else {
        final wavBytes = _getSynthBytes(ringtoneName, isCall: true);
        await player.play(BytesSource(wavBytes));
      }
    } catch (e) {
      debugPrint('[RingtoneManager] Error starting ringtone: $e');
    }
  }

  /// Stops incoming call ringing immediately.
  Future<void> stopRingtone() async {
    _isRinging = false;
    try {
      await _ringtonePlayer?.stop();
    } catch (e) {
      debugPrint('[RingtoneManager] Error stopping ringtone: $e');
    }
  }

  /// Plays a single notification tone for incoming messages.
  Future<void> playMessageNotificationTone() async {
    final allowTones =
        SharedPref.instance.getBool('notif_conv_tones') ?? true;
    if (!allowTones) return;

    try {
      final toneName =
          SharedPref.instance.getString('notif_msg_tone') ??
              'Livocal Chime (Default)';
      final customPath =
          SharedPref.instance.getString('notif_custom_msg_tone_path');

      final player = _effectivePreviewPlayer;
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.85);

      if (customPath != null &&
          customPath.isNotEmpty &&
          File(customPath).existsSync()) {
        await player.play(DeviceFileSource(customPath));
      } else {
        final wavBytes = _getSynthBytes(toneName, isCall: false);
        await player.play(BytesSource(wavBytes));
      }
    } catch (e) {
      debugPrint('[RingtoneManager] Error playing message tone: $e');
    }
  }

  /// Previews a selected preset or custom file in the settings dialog.
  Future<void> previewTone(String toneName, {String? customPath}) async {
    try {
      final player = _effectivePreviewPlayer;
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.9);

      if (customPath != null &&
          customPath.isNotEmpty &&
          File(customPath).existsSync()) {
        await player.play(DeviceFileSource(customPath));
      } else {
        final wavBytes = _getSynthBytes(toneName, isCall: true);
        await player.play(BytesSource(wavBytes));
      }
    } catch (e) {
      debugPrint('[RingtoneManager] Error previewing tone: $e');
    }
  }

  /// Stops current preview playback.
  Future<void> stopPreview() async {
    try {
      await _previewPlayer?.stop();
    } catch (e) {
      debugPrint('[RingtoneManager] Error stopping preview: $e');
    }
  }

  /// Releases audio players when terminating.
  Future<void> dispose() async {
    try {
      await _ringtonePlayer?.dispose();
      _ringtonePlayer = null;
      await _previewPlayer?.dispose();
      _previewPlayer = null;
    } catch (e) {
      debugPrint('[RingtoneManager] Error disposing players: $e');
    }
  }

  /// Synthesizes high quality PCM 16-bit WAV audio for built-in ringtones and alerts.
  Uint8List synthesizeToneBytes(String name, {bool isCall = true}) =>
      _getSynthBytes(name, isCall: isCall);

  Uint8List _getSynthBytes(String name, {required bool isCall}) {
    final cacheKey = '${name}_$isCall';
    if (_synthCache.containsKey(cacheKey)) {
      return _synthCache[cacheKey]!;
    }

    const sampleRate = 22050;
    final double duration = isCall ? 2.5 : 0.45;
    final int totalSamples = (sampleRate * duration).toInt();
    final Int16List samples = Int16List(totalSamples);

    if (name.contains('Digital Pulse')) {
      // High tech alternating digital frequency
      for (int i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        final freq = (t % 0.3 < 0.15) ? 880.0 : 1320.0;
        final env = sin(pi * ((t % 0.3) / 0.3));
        final val = sin(2 * pi * freq * t) * env * 18000;
        samples[i] = val.toInt().clamp(-32767, 32767);
      }
    } else if (name.contains('Marimba') || name.contains('Pop')) {
      // Percussive pleasant marimba chord
      final freqs = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
      for (int i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        double sum = 0.0;
        for (int f = 0; f < freqs.length; f++) {
          final noteStart = f * 0.12;
          if (t >= noteStart) {
            final noteT = t - noteStart;
            final decay = exp(-noteT * 7.0);
            sum += sin(2 * pi * freqs[f] * noteT) * decay;
          }
        }
        samples[i] = (sum * 8000).toInt().clamp(-32767, 32767);
      }
    } else if (name.contains('Classic Bell') || name.contains('Ding')) {
      // Bell chime with rich dual harmonics
      for (int i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        final decay = exp(-t * 2.5);
        final val = (sin(2 * pi * 784.0 * t) + 0.5 * sin(2 * pi * 1568.0 * t)) *
            decay *
            16000;
        samples[i] = val.toInt().clamp(-32767, 32767);
      }
    } else {
      // Livocal Harmony (Default) — Smooth harmonic ascending cadence
      final notes = [440.0, 554.37, 659.25, 880.0]; // A major arpeggio
      for (int i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        double sum = 0.0;
        for (int n = 0; n < notes.length; n++) {
          final startT = n * 0.22;
          if (t >= startT) {
            final noteTime = t - startT;
            final envelope = exp(-noteTime * 3.5);
            sum += sin(2 * pi * notes[n] * noteTime) * envelope;
          }
        }
        samples[i] = (sum * 9000).toInt().clamp(-32767, 32767);
      }
    }

    final bytes = _createWavContainer(samples, sampleRate);
    _synthCache[cacheKey] = bytes;
    return bytes;
  }

  /// Encodes 16-bit mono PCM samples into a valid RIFF WAV binary byte buffer.
  Uint8List _createWavContainer(Int16List samples, int sampleRate) {
    final byteData = ByteData(44 + samples.length * 2);
    const numChannels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    const blockAlign = numChannels * (bitsPerSample ~/ 8);
    final dataSize = samples.length * 2;
    final chunkSize = 36 + dataSize;

    // RIFF header
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, chunkSize, Endian.little);
    byteData.setUint8(8, 0x57); // 'W'
    byteData.setUint8(9, 0x41); // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little); // AudioFormat (1 = PCM)
    byteData.setUint16(22, numChannels, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, blockAlign, Endian.little);
    byteData.setUint16(34, bitsPerSample, Endian.little);

    // data subchunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataSize, Endian.little);

    int offset = 44;
    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(offset, samples[i], Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
