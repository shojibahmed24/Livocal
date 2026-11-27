import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Uploads an invoice PDF so it can travel as a chat attachment.
///
/// Storage is optional: when Firebase Storage is not provisioned yet (Spark
/// plan) every call throws and the caller falls back to the public invoice
/// link, so sending an invoice never breaks.
class InvoiceShareService {
  InvoiceShareService._();

  static const _bucketTimeout = Duration(seconds: 25);

  /// Returns a download URL, or null when Storage is unavailable.
  static Future<String?> uploadPdf({
    required String senderUid,
    required String receiverUid,
    required String fileName,
    required File file,
  }) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(
            'attachments/$senderUid/$receiverUid/$fileName',
          );
      final task = ref.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );
      await task.timeout(_bucketTimeout);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('[InvoiceShare] PDF upload unavailable: $e');
      return null;
    }
  }
}
