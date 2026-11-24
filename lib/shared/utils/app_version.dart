import 'package:package_info_plus/package_info_plus.dart';

/// Single source of truth for the app version shown in the UI.
///
/// Reads the installed package metadata once at startup so the displayed
/// version can never drift from `pubspec.yaml` (the old hardcoded "1.0.0
/// Production Ready" strings were wrong).
class AppVersion {
  AppVersion._();

  static PackageInfo? _info;

  static Future<void> load() async {
    try {
      _info = await PackageInfo.fromPlatform();
    } catch (_) {
      _info = null;
    }
  }

  static String get version => _info?.version ?? '0.0.0';

  static String get buildNumber {
    final build = _info?.buildNumber ?? '';
    return build.isEmpty ? '' : build;
  }

  /// e.g. `v0.1.1 (12)`
  static String get display {
    final build = buildNumber;
    return build.isEmpty ? 'v$version' : 'v$version ($build)';
  }
}
