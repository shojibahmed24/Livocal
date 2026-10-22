import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class MuteService {
  /// Checks whether a contact is actively muted.
  /// Automatically un-mutes if duration ('8 hours', '1 week') has elapsed.
  static bool isContactMuted(String contactId) {
    if (contactId.isEmpty) return false;
    final isMuted = SharedPref.instance.getBool('contact_muted_$contactId') ?? false;
    if (!isMuted) return false;

    final untilMs = SharedPref.instance.getInt('contact_muted_until_$contactId') ?? 0;
    if (untilMs > 0) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (nowMs >= untilMs) {
        // Mute period has expired -> auto unmute
        unmuteContact(contactId);
        return false;
      }
    }
    return true;
  }

  /// Gets the remaining human-readable duration description or null if not muted.
  static String? getMuteDescription(String contactId) {
    if (!isContactMuted(contactId)) return null;
    return SharedPref.instance.getString('contact_muted_duration_$contactId') ?? 'Always';
  }

  /// Sets mute state with duration ('8 hours', '1 week', 'Always').
  static Future<void> muteContact({
    required String contactId,
    required String duration,
  }) async {
    int untilMs = 0;
    if (duration == '8 hours') {
      untilMs = DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch;
    } else if (duration == '1 week') {
      untilMs = DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
    }

    await SharedPref.instance.setBool('contact_muted_$contactId', true);
    await SharedPref.instance.setString('contact_muted_duration_$contactId', duration);
    await SharedPref.instance.setInt('contact_muted_until_$contactId', untilMs);

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('muted_contacts')
          .doc(contactId)
          .set({
        'muted': true,
        'duration': duration,
        'untilMs': untilMs,
        'contactId': contactId,
        'updatedAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});
    }
  }

  /// Unmutes a contact locally and in Firestore.
  static Future<void> unmuteContact(String contactId) async {
    await SharedPref.instance.setBool('contact_muted_$contactId', false);
    await SharedPref.instance.remove('contact_muted_duration_$contactId');
    await SharedPref.instance.remove('contact_muted_until_$contactId');

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('muted_contacts')
          .doc(contactId)
          .delete()
          .catchError((_) {});
    }
  }
}
