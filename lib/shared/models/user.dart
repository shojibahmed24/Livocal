import 'package:livocal/features/calls/models/call_language.dart';
import 'package:isar/isar.dart';
part 'user.g.dart';

enum UserActivityStatus {
  online('Online'),
  offline('Offline');

  const UserActivityStatus(this.value);
  final String value;

  factory UserActivityStatus.fromValue(String value) {
    final res = UserActivityStatus.values.where(
      (element) => element.value == value,
    );

    if (res.isEmpty) {
      throw 'ValueError: $value is not a valid status code';
    }

    return res.first;
  }
}

@collection
class User {
  Id isarId = Isar.autoIncrement;
  final String id;
  final String name;
  final String avatarUrl;
  final Phone phone;

  @Enumerated(EnumType.value, 'value')
  UserActivityStatus activityStatus;
  @ignore
  String spokenLanguage;
  @ignore
  bool hasExplicitSpokenLanguage;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.phone,
    required this.activityStatus,
    this.spokenLanguage = 'bn',
    this.hasExplicitSpokenLanguage = false,
  });

  factory User.fromMap(Map<String, dynamic> userData) {
    final explicitLang = (userData['spokenLanguage'] as String?)?.trim();
    final phone = Phone.fromMap(userData['phone']);
    final hasExplicit = explicitLang != null && explicitLang.isNotEmpty;
    final resolvedLang = hasExplicit
        ? explicitLang
        : CallLanguageRegistry.inferLanguageFromPhone(phone);

    return User(
      id: userData['id'],
      name: userData['name'],
      avatarUrl: userData['avatarUrl'],
      phone: phone,
      activityStatus: UserActivityStatus.fromValue(userData['activityStatus']),
      spokenLanguage: resolvedLang,
      hasExplicitSpokenLanguage: hasExplicit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'phone': phone.toMap(),
      'activityStatus': activityStatus.value,
      'spokenLanguage': spokenLanguage,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    Phone? phone,
    UserActivityStatus? activityStatus,
    String? spokenLanguage,
    bool? hasExplicitSpokenLanguage,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      activityStatus: activityStatus ?? this.activityStatus,
      spokenLanguage: spokenLanguage ?? this.spokenLanguage,
      hasExplicitSpokenLanguage:
          hasExplicitSpokenLanguage ?? this.hasExplicitSpokenLanguage,
    );
  }

  @ignore
  String get phoneNumber => phone.getFormattedNumber();

  @override
  String toString() {
    return name;
  }
}

@embedded
class Phone {
  String? code;
  String? number;
  String? formattedNumber;

  Phone({
    this.code,
    this.number,
    this.formattedNumber,
  });

  String getFormattedNumber() => formattedNumber ?? '$code $number';
  String get rawNumber => '$code$number';

  factory Phone.fromMap(Map<String, dynamic> phoneData) {
    return Phone(
      code: phoneData['code'],
      number: phoneData['number'],
      formattedNumber: phoneData['formattedNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'number': number,
      'formattedNumber': formattedNumber,
      'rawNumber': rawNumber,
    };
  }
}
