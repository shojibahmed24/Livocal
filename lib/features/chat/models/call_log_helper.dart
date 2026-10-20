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

  /// Formats seconds into Bengali natural duration: e.g. "২ মিনিট ৪৫ সেকেন্ড"
  static String formatDurationBengali(int seconds) {
    if (seconds <= 0) return '০ সেকেন্ড';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;

    String toBengali(int n) {
      const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      return n.toString().split('').map((d) {
        final idx = int.tryParse(d);
        return idx != null ? bnDigits[idx] : d;
      }).join('');
    }

    if (mins > 0 && secs > 0) {
      return '${toBengali(mins)} মিনিট ${toBengali(secs)} সেকেন্ড';
    } else if (mins > 0) {
      return '${toBengali(mins)} মিনিট';
    } else {
      return '${toBengali(secs)} সেকেন্ড';
    }
  }

  /// Short duration string: e.g. "2m 45s" or "45s"
  static String formatDurationShort(int seconds) {
    if (seconds <= 0) return '';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins == 0) return '${secs}s';
    return '${mins}m ${secs}s';
  }

  /// Formats the subtitle text for Home Screen Recent Chats list
  static String formatSnippet(String? content, {required bool isSentByMe}) {
    final data = parse(content);
    if (data == null) return content ?? '';

    // Relative to the current user reading the chat:
    // If sent by me: was my outgoing call.
    // If received by me: was incoming to me.
    final bool effectiveOutgoing = isSentByMe;

    if (data.isMissed) {
      return effectiveOutgoing ? '↗️ মিসড কল' : '🔴 মিসড ভয়েস কল';
    } else if (data.isDeclined) {
      return '🚫 প্রত্যাখ্যাত কল';
    } else {
      final durStr = formatDurationBengali(data.duration);
      return effectiveOutgoing
          ? '📞 ভয়েস কল ($durStr)'
          : '📞 ইনকামিং কল ($durStr)';
    }
  }
}
