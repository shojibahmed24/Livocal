import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:livocal/shared/utils/network_tracker.dart';

class DownloadService {
  final Map<String, DownloadTask> _downloadTasks = {};
  static DownloadService instance = DownloadService();

  static Future<void> download({
    required String taskId,
    required String url,
    required String path,
    required void Function(TaskSnapshot) onDownloadComplete,
    required void Function() onDownloadError,
  }) async {
    try {
      final downloadTask =
          FirebaseStorage.instance.refFromURL(url).writeToFile(File(path));

      instance._downloadTasks[taskId] = downloadTask;
      downloadTask.then<void>(
        (snapshot) {
          NetworkTracker.recordBytesReceived(snapshot.totalBytes);
          onDownloadComplete(snapshot);
          instance._downloadTasks.remove(taskId);
        },
        onError: (err) {
          debugPrint('[DownloadService] download task failed for $taskId: $err');
          instance._downloadTasks.remove(taskId);
          onDownloadError();
        },
      );
    } catch (e) {
      debugPrint('[DownloadService] writeToFile failed for $taskId: $e');
      instance._downloadTasks.remove(taskId);
      onDownloadError();
    }
  }

  static Future<void> cancelDownload(String taskId) async {
    final task = instance._downloadTasks[taskId];
    if (task == null) return;

    await task.cancel();
    instance._downloadTasks.remove(taskId);
  }

  static Stream<TaskSnapshot>? getDownloadStream(String taskId) {
    final task = instance._downloadTasks[taskId];
    if (task == null) return null;

    return task.snapshotEvents;
  }
}
