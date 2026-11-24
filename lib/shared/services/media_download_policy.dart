import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:livocal/features/chat/models/attachement.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

/// Decides whether a received attachment should download automatically based on
/// the user's Media auto-download settings and the current network type.
///
/// Settings are evaluated per network:
/// - Wi-Fi / Ethernet / VPN → `storage_wifi_auto`
/// - Mobile data → `storage_mobile_auto`
/// - No connection → never auto-download
class MediaDownloadPolicy {
  MediaDownloadPolicy._();

  static const _wifiValues = {'Photos', 'Photos, Audio', 'All media'};

  static Future<bool> allow(AttachmentType type) async {
    // Voice notes are tiny and needed to play the message inline.
    if (type == AttachmentType.voice) return true;

    final pref = await _prefForCurrentNetwork();
    return _allows(pref, type);
  }

  static Future<String> _prefForCurrentNetwork() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isEmpty) return 'No media';

      final onWifi = results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet) ||
          results.contains(ConnectivityResult.vpn);
      if (onWifi) {
        return SharedPref.instance.getString('storage_wifi_auto') ??
            'All media';
      }
      if (results.contains(ConnectivityResult.mobile)) {
        return SharedPref.instance.getString('storage_mobile_auto') ?? 'Photos';
      }
      return 'No media';
    } catch (e) {
      debugPrint('[MediaDownloadPolicy] network check failed: $e');
      // Fail closed: never auto-download when the network type is unknown.
      return 'No media';
    }
  }

  static bool _allows(String pref, AttachmentType type) {
    if (!_wifiValues.contains(pref)) return false;
    switch (pref) {
      case 'No media':
        return false;
      case 'Photos':
        return type == AttachmentType.image;
      case 'Photos, Audio':
        return type == AttachmentType.image || type == AttachmentType.audio;
      case 'All media':
        return true;
      default:
        return false;
    }
  }
}
