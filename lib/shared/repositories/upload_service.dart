import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class UploadService {
  final Map<String, UploadTask> _uploadTasks = {};
  static UploadService instance = UploadService();

  static Future<void> upload({
    required String taskId,
    required File file,
    required String path,
    required void Function(TaskSnapshot) onUploadDone,
    required void Function() onUploadError,
  }) async {
    try {
      final uploadTask =
          FirebaseStorage.instance.ref().child(path).putFile(file);

      instance._uploadTasks[taskId] = uploadTask;
      uploadTask.then<void>(
        (snapshot) {
          onUploadDone(snapshot);
          instance._uploadTasks.remove(taskId);
        },
        onError: (_) {
          instance._uploadTasks.remove(taskId);
          onUploadError();
        },
      );
    } catch (_) {
      instance._uploadTasks.remove(taskId);
      onUploadError();
    }
  }

  static Future<void> cancelUpload(String taskId) async {
    final task = instance._uploadTasks[taskId];
    if (task == null) return;

    await task.cancel();
    instance._uploadTasks.remove(taskId);
  }

  static Stream<TaskSnapshot>? getUploadStream(String taskId) {
    final task = instance._uploadTasks[taskId];
    if (task == null) return null;

    return task.snapshotEvents;
  }
}
