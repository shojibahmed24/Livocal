/// Filter-chip labels for the contact picker (7 languages).
class ContactFilterStrings {
  final String all;
  final String onLivocal;
  final String invite;

  const ContactFilterStrings({
    required this.all,
    required this.onLivocal,
    required this.invite,
  });

  static ContactFilterStrings of(String languageCode) =>
      _values[languageCode] ?? _values['en']!;

  static const Map<String, ContactFilterStrings> _values = {
    'en': ContactFilterStrings(
      all: 'All',
      onLivocal: 'On Livocal',
      invite: 'Invite',
    ),
    'bn': ContactFilterStrings(
      all: 'সবাই',
      onLivocal: 'Livocal-এ',
      invite: 'ইনভাইট',
    ),
    'hi': ContactFilterStrings(
      all: 'सभी',
      onLivocal: 'Livocal पर',
      invite: 'आमंत्रण',
    ),
    'ar': ContactFilterStrings(
      all: 'الكل',
      onLivocal: 'على Livocal',
      invite: 'دعوة',
    ),
    'es': ContactFilterStrings(
      all: 'Todos',
      onLivocal: 'En Livocal',
      invite: 'Invitar',
    ),
    'fr': ContactFilterStrings(
      all: 'Tous',
      onLivocal: 'Sur Livocal',
      invite: 'Inviter',
    ),
    'de': ContactFilterStrings(
      all: 'Alle',
      onLivocal: 'Auf Livocal',
      invite: 'Einladen',
    ),
  };
}
