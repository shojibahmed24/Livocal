import 'package:flutter_test/flutter_test.dart';
import 'package:livocal/features/freelancer/models/invoice.dart';

void main() {
  group('Invoice', () {
    Invoice build({double tax = 0, double discount = 0}) {
      return Invoice(
        ownerUid: 'me',
        clientUid: 'client',
        clientName: 'Alex',
        number: 'INV-2026-001',
        items: [
          InvoiceLine(description: 'Landing page', qty: 1, rate: 300),
          InvoiceLine(description: 'Extra section', qty: 2, rate: 50),
        ],
        taxPct: tax,
        discount: discount,
        createdAt: DateTime(2026, 11, 26),
      );
    }

    test('totals include tax and discount', () {
      final invoice = build(tax: 10, discount: 20);
      expect(invoice.subtotal, 400);
      expect(invoice.taxAmount, 40);
      expect(invoice.total, 420);
      expect(invoice.totalLabel, 'USD 420.00');
    });

    test('total never goes below zero', () {
      final invoice = build(discount: 1000);
      expect(invoice.total, 0);
    });

    test('overdue only applies to sent invoices past due date', () {
      final invoice = build()
        ..status = 'sent'
        ..dueDate = DateTime.now().subtract(const Duration(days: 2));
      expect(invoice.isOverdue, isTrue);

      invoice.status = 'draft';
      expect(invoice.isOverdue, isFalse);
    });

    test('toMap/fromMap roundtrip keeps items and status', () {
      final invoice = build(tax: 5)
        ..status = 'sent'
        ..dueDate = DateTime(2026, 12, 3);

      final restored = Invoice.fromMap('me', 'log', invoice.toMap());

      expect(restored.number, invoice.number);
      expect(restored.items.length, 2);
      expect(restored.items.first.rate, 300);
      expect(restored.taxPct, 5);
      expect(restored.status, 'sent');
      expect(restored.dueDate, DateTime(2026, 12, 3));
      expect(restored.synced, isTrue);
    });
  });
}
