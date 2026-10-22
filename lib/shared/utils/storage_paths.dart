import 'dart:io';

import 'package:flutter/foundation.dart';
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

      // Also sync to external public directory if on Android
      if (!kIsWeb && Platform.isAndroid) {
        final extDirs = [
          Directory('/storage/emulated/0/Pictures/Livocal'),
          Directory('/storage/emulated/0/Download/Livocal'),
        ];
        for (final dir in extDirs) {
          if (await dir.exists()) {
            final pubNoMedia = File('${dir.path}/.nomedia');
            if (!visibility) {
              if (!pubNoMedia.existsSync()) await pubNoMedia.create();
            } else {
              if (pubNoMedia.existsSync()) await pubNoMedia.delete();
            }
          }
        }
      }
    } catch (_) {}
  }

  static Future<String?> saveMediaToGallery(File sourceFile, {String? fileName}) async {
    try {
      if (!await sourceFile.exists()) return null;
      final name = fileName ?? sourceFile.uri.pathSegments.last;
      Directory? targetDir;

      if (!kIsWeb && Platform.isAndroid) {
        final picturesDir = Directory('/storage/emulated/0/Pictures/Livocal');
        bool created = true;
        if (!await picturesDir.exists()) {
          try {
            await picturesDir.create(recursive: true);
          } catch (_) {
            created = false;
          }
        }
        if (created && await picturesDir.exists()) {
          targetDir = picturesDir;
        } else {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            targetDir = Directory('${extDir.path}/Pictures');
            if (!await targetDir.exists()) await targetDir.create(recursive: true);
          }
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (targetDir == null) return null;

      final targetPath = '${targetDir.path}/$name';
      final savedFile = await sourceFile.copy(targetPath);

      final visibility = SharedPref.instance.getBool('chat_media_visibility') ?? true;
      final noMedia = File('${targetDir.path}/.nomedia');
      if (!visibility) {
        if (!noMedia.existsSync()) await noMedia.create();
      } else {
        if (noMedia.existsSync()) await noMedia.delete();
      }

      return savedFile.path;
    } catch (e) {
      debugPrint('[DeviceStorage] saveMediaToGallery error: $e');
      return null;
    }
  }

  static String getMediaFilePath(String fileName) {
    return "$mediaDirPath/$fileName";
  }

  static String getTempFilePath(String fileName) {
    return "$tempDirPath/$fileName";
  }
}
