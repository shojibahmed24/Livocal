import 'package:isar/isar.dart';

part 'crm_entry.g.dart';

/// Freelancer CRM entry: one per (owner, peer) pair.
///
/// Stored locally first (offline-friendly) and mirrored to
/// `users/{ownerUid}/crm/{peerUid}` on Firestore.
@collection
class CrmEntry {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('peerUid')], unique: true)
  String ownerUid;

  String peerUid;

  /// Display name captured from the chat contact.
  String clientName;

  /// `prospect` | `client` | `archived`
  String tag;

  /// `new` | `negotiating` | `active` | `paid`
  String stage;

  double rateAmount;

  /// ISO 4217-ish code the user picked (USD, BDT, …).
  String rateCurrency;

  /// `hourly` | `project`
  String rateBasis;

  /// JSON encoded `{"text": "...", "at": "ISO"}` strings, newest last.
  List<String> notes;

  DateTime? lastContactedAt;
  DateTime? followUpAt;
  DateTime updatedAt;

  /// False when the local row still needs pushing to Firestore.
  bool synced;

  CrmEntry({
    required this.ownerUid,
    required this.peerUid,
    this.clientName = '',
    this.tag = 'prospect',
    this.stage = 'new',
    this.rateAmount = 0,
    this.rateCurrency = 'USD',
    this.rateBasis = 'hourly',
    List<String> notes = const <String>[],
    this.lastContactedAt,
    this.followUpAt,
    required this.updatedAt,
    this.synced = false,
  }) : notes = List<String>.from(notes);

  bool get isClient => tag == 'client';
  bool get isArchived => tag == 'archived';
  bool get isProspect => tag == 'prospect';

  Map<String, dynamic> toMap() => {
        'clientName': clientName,
        'tag': tag,
        'stage': stage,
        'rateAmount': rateAmount,
        'rateCurrency': rateCurrency,
        'rateBasis': rateBasis,
        'notes': notes,
        'lastContactedAt': lastContactedAt?.toIso8601String(),
        'followUpAt': followUpAt?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static CrmEntry fromMap(
    String ownerUid,
    String peerUid,
    Map<String, dynamic> map,
  ) {
    final rawNotes = map['notes'];
    return CrmEntry(
      ownerUid: ownerUid,
      peerUid: peerUid,
      clientName: (map['clientName'] as String?) ?? '',
      tag: (map['tag'] as String?) ?? 'prospect',
      stage: (map['stage'] as String?) ?? 'new',
      rateAmount: (map['rateAmount'] as num?)?.toDouble() ?? 0,
      rateCurrency: (map['rateCurrency'] as String?) ?? 'USD',
      rateBasis: (map['rateBasis'] as String?) ?? 'hourly',
      notes: rawNotes is List
          ? rawNotes.map((e) => e.toString()).toList()
          : const <String>[],
      lastContactedAt:
          DateTime.tryParse((map['lastContactedAt'] as String?) ?? ''),
      followUpAt: DateTime.tryParse((map['followUpAt'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.now(),
      synced: true,
    );
  }
}
