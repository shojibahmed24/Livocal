/// Bilingual client proposal returned by the relay.
class Proposal {
  final String headline;
  final String scope;
  final String timeline;
  final String price;
  final String terms;

  /// openrouter | gemini | allback`r
  String source;
  String reason;

  Proposal({
    required this.headline,
    required this.scope,
    required this.timeline,
    required this.price,
    required this.terms,
    this.source = 'ai',
    this.reason = '',
  });

  static Proposal? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    String text(String key) => (json[key] ?? '').toString().trim();
    final proposal = Proposal(
      headline: text('headline'),
      scope: text('scope'),
      timeline: text('timeline'),
      price: text('price'),
      terms: text('terms'),
    );
    if (proposal.headline.isEmpty || proposal.scope.isEmpty) return null;
    return proposal;
  }

  String toPlainText({
    required String title,
    required String scopeLabel,
    required String timelineLabel,
    required String priceLabel,
    required String termsLabel,
  }) {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln(headline)
      ..writeln()
      ..writeln('$scopeLabel:')
      ..writeln(scope)
      ..writeln()
      ..writeln('$timelineLabel:')
      ..writeln(timeline);
    if (price.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('$priceLabel:')
        ..writeln(price);
    }
    if (terms.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('$termsLabel:')
        ..writeln(terms);
    }
    return buffer.toString().trim();
  }
}
