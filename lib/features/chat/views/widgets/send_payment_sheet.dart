import 'package:flutter/material.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

void showSendPaymentSheet({
  required BuildContext context,
  required User self,
  required User other,
  required String contactName,
  required Function(String amount, String note) onPaymentConfirmed,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
    ),
    builder: (ctx) => _SendPaymentSheetContent(
      self: self,
      other: other,
      contactName: contactName,
      onPaymentConfirmed: onPaymentConfirmed,
    ),
  );
}

class _SendPaymentSheetContent extends StatefulWidget {
  const _SendPaymentSheetContent({
    required this.self,
    required this.other,
    required this.contactName,
    required this.onPaymentConfirmed,
  });

  final User self;
  final User other;
  final String contactName;
  final Function(String amount, String note) onPaymentConfirmed;

  @override
  State<_SendPaymentSheetContent> createState() => _SendPaymentSheetContentState();
}

class _SendPaymentSheetContentState extends State<_SendPaymentSheetContent> {
  final TextEditingController _amountController = TextEditingController(text: '10');
  final TextEditingController _noteController = TextEditingController();
  String _selectedMethod = 'card';
  bool _isProcessing = false;

  final List<String> _quickAmounts = ['5', '10', '25', '50', '100'];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _processPayment() {
    final amount = _amountController.text.trim();
    if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) {
      showSnackBar(
        context: context,
        content: 'Please enter a valid amount',
        type: SnacBarType.error,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      Navigator.pop(context);
      widget.onPaymentConfirmed(amount, _noteController.text.trim());
      showSnackBar(
        context: context,
        content: '\$$amount successfully sent to ${widget.contactName}!',
        type: SnacBarType.info,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.attach_money_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Money to ${widget.contactName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.other.phone.getFormattedNumber(),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Amount input
            Center(
              child: IntrinsicWidth(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                      ),
                    ),
                    const Text(
                      'USD',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quick chips
            Center(
              child: Wrap(
                spacing: 8,
                children: _quickAmounts.map((amt) {
                  final isSelected = _amountController.text == amt;
                  return ChoiceChip(
                    label: Text('\$$amt'),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (val) {
                      setState(() {
                        _amountController.text = amt;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Note field
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add a note (e.g. Dinner, Freelance, Gift)',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Payment method selection
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'card',
                    groupValue: _selectedMethod,
                    title: const Row(
                      children: [
                        Icon(Icons.credit_card, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Credit / Debit Card (Stripe USD)', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _selectedMethod = val!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'gpay',
                    groupValue: _selectedMethod,
                    title: const Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 20, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text('Google Pay / Apple Pay', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _selectedMethod = val!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'mfs',
                    groupValue: _selectedMethod,
                    title: const Row(
                      children: [
                        Icon(Icons.phone_android, size: 20, color: Colors.pinkAccent),
                        SizedBox(width: 8),
                        Text('bKash / Nagad (BDT Exchange)', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _selectedMethod = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Send button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _isProcessing ? null : _processPayment,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Pay \$${_amountController.text.isEmpty ? "0" : _amountController.text}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
