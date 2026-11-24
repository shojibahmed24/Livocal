import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

/// Builds the document that may be read by other signed-in users.
///
/// Only fields the user agreed to share are included:
/// - phone number: never
/// - avatar: hidden when Profile photo privacy is "Nobody"
class ProfilePrivacy {
  ProfilePrivacy._();

  static bool get photoHidden {
    final pref = SharedPref.instance.getString('privacy_profile_photo');
    // Legacy "My contacts" cannot be enforced per-viewer, so it is treated as
    // hidden (privacy-safe) until the user picks Everyone.
    return pref == 'Nobody' || pref == 'My contacts';
  }

  static Map<String, dynamic> publicMap(User user) {
    final map = user.toPublicMap();
    if (photoHidden) {
      map['avatarUrl'] = '';
    }
    return map;
  }
}
