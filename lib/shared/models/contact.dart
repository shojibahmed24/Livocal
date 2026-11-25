import 'package:isar/isar.dart';

part 'contact.g.dart';

@collection
class Contact {
  Id id = Isar.autoIncrement;

  @Index()
  String contactId;

  String displayName;
  String phoneNumber;
  String? avatarUrl;

  @Index()
  String? userId;

  Contact({
    required this.contactId,
    required this.displayName,
    required this.phoneNumber,
    this.avatarUrl,
    this.userId,
  });

  @override
  String toString() {
    return displayName;
  }
}
