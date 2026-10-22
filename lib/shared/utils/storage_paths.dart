import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:livocal/shared/utils/shared_pref.dart';

class DeviceStorage {
  static late final String appDocsDirPath;
  static late final String tempDirPath;
  static late final String mediaDirPath;

  static init() async {
    appDocsDirPath = (await getApplicationDocumentsDirectory()).path;
    tempDirPath = (await getTemporaryDirectory()).path;
    mediaDirPath = await initMediaDir();
    await syncMediaVisibility();
  }

  static Future<String> initMediaDir() async {
    final dir = Directory("$appDocsDirPath/media");
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    return dir.path;
  }

  static Future<void> syncMediaVisibility() async {
    try {
      final visibility = SharedPref.instance.getBool('chat_media_visibility') ?? true;
      final noMediaFile = File("$mediaDirPath/.nomedia");
      if (!visibility) {
        if (!noMediaFile.existsSync()) {
          await noMediaFile.create(recursive: true);
        }
      } else {
        if (noMediaFile.existsSync()) {
          await noMediaFile.delete();
        }
      }
    } catch (_) {}
  }

  static String getMediaFilePath(String fileName) {
    return "$mediaDirPath/$fileName";
  }

  static String getTempFilePath(String fileName) {
    return "$tempDirPath/$fileName";
  }
}
