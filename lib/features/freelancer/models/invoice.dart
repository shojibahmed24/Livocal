import 'package:isar/isar.dart';

part 'invoice.g.dart';

/// One billed row on an invoice.
@embedded
class InvoiceLine {
  String description;
  double qty;
  double rate;

  InvoiceLine({
    this.description = '',
    this.qty = 1,
    this.rate = 0,
  });

  @ignore
  double get amount => qty * rate;

  Map<String, dynamic> toMap() => {
        'description': description,
        'qty': qty,
        'rate': rate,
      };

  static InvoiceLine fromMap(Map<String, dynamic> map) {
    return InvoiceLine(
      description: (map['description'] ?? '').toString(),
      qty: (map['qty'] as num?)?.toDouble() ?? 1,
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Freelancer quote/invoice, stored locally and mirrored to
/// `users/{ownerUid}/invoices/{id}`.
@collection
class Invoice {
  Id id = Isar.autoIncrement;

  @Index()
  String ownerUid;

  @Index()
  String clientUid;

  String clientName;

  /// `INV-<year>-<seq>`
  String number;

  String currency;
  List<InvoiceLine> items;
  double taxPct;
  double discount;

  /// `draft` | `sent` | `paid` | `void`
  String status;

  DateTime? dueDate;
  String notes;
  DateTime createdAt;
  DateTime? sentAt;
  DateTime? paidAt;
  String? paymentMsgId;

  /// Public share token (set when the invoice is first sent).
  String publicToken;
  bool synced;

  Invoice({
    required this.ownerUid,
    required this.clientUid,
    required this.clientName,
    required this.number,
    this.currency = 'USD',
    List<InvoiceLine> items = const <InvoiceLine>[],
    this.taxPct = 0,
    this.discount = 0,
    this.status = 'draft',
    this.dueDate,
    this.notes = '',
    required this.createdAt,
    this.sentAt,
    this.paidAt,
    this.paymentMsgId,
    this.publicToken = '',
    this.synced = false,
  }) : items = List<InvoiceLine>.from(items);

  @ignore
  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.amount);

  @ignore
  double get taxAmount => subtotal * taxPct / 100;

  @ignore
  double get total {
    final value = subtotal + taxAmount - discount;
    return value < 0 ? 0 : value;
  }

  @ignore
  bool get isDraft => status == 'draft';

  @ignore
  bool get isPaid => status == 'paid';

  @ignore
  bool get isVoid => status == 'void';

  @ignore
  bool get isOverdue {
    if (status != 'sent' || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  @ignore
  String get totalLabel => '$currency ${total.toStringAsFixed(2)}';

  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Map<String, dynamic> toMap() => {
        'number': number,
        'clientUid': clientUid,
        'clientName': clientName,
        'items': items.map((item) => item.toMap()).toList(),
        'currency': currency,
        'taxPct': taxPct,
        'discount': discount,
        'total': total,
        'status': status,
        'dueDate': dueDate?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'sentAt': sentAt?.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
        'paymentMsgId': paymentMsgId,
        'publicToken': publicToken,
      };

  static Invoice fromMap(
      String ownerUid, String idForLog, Map<String, dynamic> map) {
    final rawItems = map['items'];
    return Invoice(
      ownerUid: ownerUid,
      clientUid: (map['clientUid'] ?? '').toString(),
      clientName: (map['clientName'] ?? '').toString(),
      number: (map['number'] ?? idForLog).toString(),
      currency: (map['currency'] ?? 'USD').toString(),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (e) => InvoiceLine.fromMap(
                  e.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
          : const <InvoiceLine>[],
      taxPct: (map['taxPct'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      status: (map['status'] ?? 'draft').toString(),
      dueDate: DateTime.tryParse((map['dueDate'] ?? '').toString()),
      notes: (map['notes'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      sentAt: DateTime.tryParse((map['sentAt'] ?? '').toString()),
      paidAt: DateTime.tryParse((map['paidAt'] ?? '').toString()),
      paymentMsgId: map['paymentMsgId']?.toString(),
      publicToken: (map['publicToken'] ?? '').toString(),
      synced: true,
    );
  }
}
