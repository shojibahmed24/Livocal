import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/chat/models/attachement.dart';
import 'package:livocal/features/chat/models/message.dart';

void main() {
  group('Invoice message in chat', () {
    Message build({String? invoiceId, Attachment? attachment}) {
      return Message(
        id: 'm1',
        content: '📄 Invoice INV-2026-001',
        senderId: 'me',
        receiverId: 'client',
        timestamp: Timestamp.fromDate(DateTime(2026, 11, 28)),
        status: MessageStatus.sent,
        attachment: attachment,
        invoiceId: invoiceId,
      );
    }

    test('invoice id survives a Firestore round trip', () {
      final message = build(invoiceId: '42');
      final restored = Message.fromMap(message.toMap());

      expect(restored.invoiceId, '42');
      expect(restored.content, message.content);
    });

    test('invoice id is omitted when absent', () {
      final map = build().toMap();
      expect(map.containsKey('invoiceId'), isFalse);
    });

    test('PDF attachment keeps its url and type', () {
      final attachment = Attachment(
        type: AttachmentType.document,
        url: 'https://example.test/inv.pdf',
        fileName: 'INV-2026-001.pdf',
        fileSize: 2048,
        fileExtension: 'pdf',
        uploadStatus: UploadStatus.uploaded,
      );
      final restored = Message.fromMap(
        build(invoiceId: '7', attachment: attachment).toMap(),
      );

      expect(restored.attachment, isNotNull);
      expect(restored.attachment!.type, AttachmentType.document);
      expect(restored.attachment!.fileExtension, 'pdf');
      expect(restored.attachment!.url, 'https://example.test/inv.pdf');
      expect(restored.attachment!.uploadStatus, UploadStatus.uploaded);
      expect(restored.invoiceId, '7');
    });

    test('copyWith keeps the invoice link', () {
      final copy = build(invoiceId: '9').copyWith(status: MessageStatus.seen);
      expect(copy.invoiceId, '9');
      expect(copy.status, MessageStatus.seen);
    });
  });
}
