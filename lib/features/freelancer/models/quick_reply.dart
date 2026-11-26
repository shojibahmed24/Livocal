import 'package:isar/isar.dart';

part 'quick_reply.g.dart';

/// Freelancer message template (pitch, rate, availability, closing).
@collection
class QuickReply {
  Id id = Isar.autoIncrement;

  @Index()
  String ownerUid;

  String title;
  String body;

  /// `pitch` | `rate` | `availability` | `closing`
  String category;

  int sortOrder;

  /// Seeded defaults can be edited but are marked so we never duplicate them.
  bool isDefault;

  QuickReply({
    required this.ownerUid,
    required this.title,
    required this.body,
    this.category = 'pitch',
    this.sortOrder = 0,
    this.isDefault = false,
  });
}
