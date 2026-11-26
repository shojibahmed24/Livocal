/// One follow-up task extracted from a call.
class CallActionItem {
  final String text;

  /// `me` | `client`
  final String owner;

  const CallActionItem({required this.text, required this.owner});

  bool get isMine => owner == 'me';

  factory CallActionItem.fromJson(Map<String, dynamic> json) {
    return CallActionItem(
      text: (json['text'] ?? '').toString(),
      owner: json['owner'] == 'client' ? 'client' : 'me',
    );
  }
}

/// Bilingual call summary returned by the relay.
class CallSummary {
  final String summary;
  final List<String> decisions;
  final List<CallActionItem> actionItems;
  final String clientHints;

  const CallSummary({
    required this.summary,
    required this.decisions,
    required this.actionItems,
    required this.clientHints,
  });

  static CallSummary? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final summary = (json['summary'] ?? '').toString().trim();
    if (summary.isEmpty) return null;

    final rawDecisions = json['decisions'];
    final rawActions = json['actionItems'];

    return CallSummary(
      summary: summary,
      decisions: rawDecisions is List
          ? rawDecisions
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : const <String>[],
      actionItems: rawActions is List
          ? rawActions
              .whereType<Map>()
              .map(
                (e) => CallActionItem.fromJson(
                  e.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .where((e) => e.text.isNotEmpty)
              .toList()
          : const <CallActionItem>[],
      clientHints: (json['clientHints'] ?? '').toString().trim(),
    );
  }

  /// Plain text used by copy/share.
  String toPlainText({
    required String title,
    required String decisionsLabel,
    required String actionsLabel,
    required String hintsLabel,
    required String meLabel,
    required String clientLabel,
  }) {
    final buffer = StringBuffer()
      ..writeln('$title:')
      ..writeln(summary);

    if (decisions.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('$decisionsLabel:');
      for (final decision in decisions) {
        buffer.writeln('• $decision');
      }
    }

    if (actionItems.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('$actionsLabel:');
      for (final item in actionItems) {
        final owner = item.isMine ? meLabel : clientLabel;
        buffer.writeln('• [$owner] ${item.text}');
      }
    }

    if (clientHints.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('$hintsLabel:')
        ..writeln(clientHints);
    }

    return buffer.toString().trim();
  }
}
