import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads profile images (cover, portfolio, case study) to Storage.
class ProfileImageService {
  ProfileImageService._();

  static const maxUploadTime = Duration(seconds: 90);

  static Future<String> upload({
    required String ownerUid,
    required String prefix,
    required XFile image,
  }) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('userAvatars')
        .child(ownerUid)
        .child('${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task = ref.putFile(
      File(image.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    await task.timeout(maxUploadTime);
    return ref.getDownloadURL();
  }

  /// Opens the gallery and returns a compressed image.
  static Future<XFile?> pick() {
    return ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 70,
    );
  }
}
