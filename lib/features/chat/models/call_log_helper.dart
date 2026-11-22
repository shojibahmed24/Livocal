import 'package:livocal/shared/utils/app_localizations.dart';

class CallLogData {
  final String direction; // 'outgoing' | 'incoming'
  final String status; // 'answered' | 'missed' | 'declined'
  final int duration; // in seconds
  final bool isTranslated;

  const CallLogData({
    required this.direction,
    required this.status,
    required this.duration,
    required this.isTranslated,
  });

  bool get isMissed => status == 'missed';
  bool get isDeclined => status == 'declined';
  bool get isAnswered => status == 'answered';
  bool get isOutgoing => direction == 'outgoing';
}

class CallLogHelper {
  static const String prefix = '[CALL_LOG]:';

  /// Encodes a call log event into a standardized message string
  static String encode({
    required String direction,
    required String status,
    required int duration,
    bool isTranslated = false,
  }) {
    return '$prefix dir=$direction;status=$status;duration=$duration;trans=$isTranslated';
  }

  /// Checks if message content represents a structured Call Log
  static bool isCallLog(String? content) {
    if (content == null) return false;
    return content.trimLeft().startsWith(prefix);
  }

  /// Parses a message content string into [CallLogData]
  static CallLogData? parse(String? content) {
    if (!isCallLog(content)) return null;

    try {
      final payload = content!.substring(content.indexOf(prefix) + prefix.length).trim();
      final parts = payload.split(';');
      final map = <String, String>{};

      for (final part in parts) {
        final kv = part.split('=');
        if (kv.length == 2) {
          map[kv[0].trim()] = kv[1].trim();
        }
      }

      final dir = map['dir'] ?? 'outgoing';
      final status = map['status'] ?? 'answered';
      final duration = int.tryParse(map['duration'] ?? '0') ?? 0;
      final trans = map['trans'] == 'true';

      return CallLogData(
        direction: dir,
        status: status,
        duration: duration,
        isTranslated: trans,
      );
    } catch (_) {
      return null;
    }
  }

  static String _toBengali(int n) {
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return n.toString().split('').map((d) {
      final idx = int.tryParse(d);
      return idx != null ? bnDigits[idx] : d;
    }).join('');
  }

  /// Formats seconds using the active app locale.
  static String formatDurationLocalized(int seconds, String langCode) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    String num(int value) =>
        langCode == 'bn' ? _toBengali(value) : value.toString();

    if (mins > 0 && secs > 0) {
      return AppStrings.get(
        'minutesSecondsValue',
        langCode,
        args: {'minutes': num(mins), 'seconds': num(secs)},
      );
    } else if (mins > 0) {
      return AppStrings.get(
        'minutesValue',
        langCode,
        args: {'minutes': num(mins)},
      );
    }
    return AppStrings.get(
      'secondsValue',
      langCode,
      args: {'seconds': num(secs)},
    );
  }

  /// Backwards-compatible Bengali formatter.
  static String formatDurationBengali(int seconds) =>
      formatDurationLocalized(seconds, 'bn');

  /// Short duration string: e.g. "2m 45s" or "45s"
  static String formatDurationShort(int seconds) {
    if (seconds <= 0) return '';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs}s';
  }

  /// Formats the subtitle text for Home Screen Recent Chats list
  static String formatSnippet(
    String? content, {
    required bool isSentByMe,
    String langCode = 'en',
  }) {
    final data = parse(content);
    if (data == null) return content ?? '';

    // Relative to the current user reading the chat:
    // If sent by me: was my outgoing call.
    // If received by me: was incoming to me.
    final bool effectiveOutgoing = isSentByMe;

    if (data.isMissed) {
      return effectiveOutgoing
          ? '↗️ ${AppStrings.get('missedCall', langCode)}'
          : '🔴 ${AppStrings.get('missedVoiceCall', langCode)}';
    } else if (data.isDeclined) {
      return '🚫 ${AppStrings.get('declinedCall', langCode)}';
    } else {
      final durStr = formatDurationLocalized(data.duration, langCode);
      return effectiveOutgoing
          ? '📞 ${AppStrings.get('voiceCall', langCode)} ($durStr)'
          : '📞 ${AppStrings.get('incomingCall', langCode)} ($durStr)';
    }
  }
}
