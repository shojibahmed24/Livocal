import 'package:open_file_plus/open_file_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'package:livocal/features/freelancer/models/invoice.dart';
import 'package:livocal/features/freelancer/services/invoice_pdf_service.dart';

/// Opens or shares a rendered invoice PDF.
class InvoicePdfActions {
  InvoicePdfActions._();

  static Future<void> preview({
    required Future<Invoice?> Function() save,
    required String fromName,
    required String Function(String key) t,
  }) async {
    final invoice = await save();
    if (invoice == null) return;
    final file = await InvoicePdfService.build(
      invoice: invoice,
      fromName: fromName,
      t: t,
    );
    await OpenFile.open(file.path);
  }

  static Future<void> share({
    required Future<Invoice?> Function() save,
    required String fromName,
    required String Function(String key) t,
  }) async {
    final invoice = await save();
    if (invoice == null) return;
    final file = await InvoicePdfService.build(
      invoice: invoice,
      fromName: fromName,
      t: t,
    );
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${t('invoice')} ${invoice.number}',
    );
  }
}
