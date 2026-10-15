import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/calls/services/ringtone_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RingtoneManager & Audio Synthesis Tests', () {
    test('RingtoneManager is a singleton instance', () {
      final instance1 = RingtoneManager();
      final instance2 = RingtoneManager();
      expect(identical(instance1, instance2), isTrue);
    });

    test('Presets list contains expected default and harmonic options', () {
      expect(RingtoneManager.ringtonePresets, contains('Livocal Harmony (Default)'));
      expect(RingtoneManager.ringtonePresets, contains('Digital Pulse'));
      expect(RingtoneManager.ringtonePresets, contains('Marimba Bloom'));
      expect(RingtoneManager.ringtonePresets, contains('Classic Bell'));
      expect(RingtoneManager.ringtonePresets, contains('Custom (Choose from phone)...'));

      expect(RingtoneManager.messageTonePresets, contains('Livocal Chime (Default)'));
      expect(RingtoneManager.messageTonePresets, contains('Subtle Ding'));
      expect(RingtoneManager.messageTonePresets, contains('Crystal Pop'));
    });

    test('Synthesized preset tone produces valid 44-byte RIFF WAV structure', () {
      final manager = RingtoneManager();
      final wavBytes = manager.synthesizeToneBytes('Livocal Harmony (Default)');

      expect(wavBytes.length, greaterThan(44));

      // Validate RIFF header
      expect(String.fromCharCodes(wavBytes.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(wavBytes.sublist(8, 12)), equals('WAVE'));

      // Validate fmt subchunk
      expect(String.fromCharCodes(wavBytes.sublist(12, 16)), equals('fmt '));
      final byteData = ByteData.sublistView(wavBytes);
      final audioFormat = byteData.getUint16(20, Endian.little);
      final numChannels = byteData.getUint16(22, Endian.little);
      final sampleRate = byteData.getUint32(24, Endian.little);
      final bitsPerSample = byteData.getUint16(34, Endian.little);

      expect(audioFormat, equals(1)); // PCM
      expect(numChannels, equals(1)); // Mono
      expect(sampleRate, equals(22050)); // 22.05kHz
      expect(bitsPerSample, equals(16)); // 16-bit

      // Validate data subchunk
      expect(String.fromCharCodes(wavBytes.sublist(36, 40)), equals('data'));
      final dataSize = byteData.getUint32(40, Endian.little);
      expect(wavBytes.length, equals(44 + dataSize));
    });

    test('Synthesized message tones also produce valid PCM WAV structures', () {
      final manager = RingtoneManager();
      final chimeBytes = manager.synthesizeToneBytes('Livocal Chime (Default)');
      final dingBytes = manager.synthesizeToneBytes('Subtle Ding');
      final popBytes = manager.synthesizeToneBytes('Crystal Pop');

      expect(String.fromCharCodes(chimeBytes.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(dingBytes.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(popBytes.sublist(0, 4)), equals('RIFF'));
    });
  });
}
