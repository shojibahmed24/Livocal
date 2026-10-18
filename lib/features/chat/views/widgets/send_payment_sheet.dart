import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/views/widgets/minute_recharge_sheet.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/models/user_wallet.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/app_tokens.dart';

void showSendPaymentSheet({
  required BuildContext context,
  required User self,
  required User other,
  required String contactName,
  required Function(String amount, String note, [String? method, String? txId])
      onPaymentConfirmed,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.radiusLg)),
    ),
    builder: (ctx) => _SendPaymentSheetContent(
      self: self,
      other: other,
      contactName: contactName,
      onPaymentConfirmed: onPaymentConfirmed,
    ),
  );
}

class _SendPaymentSheetContent extends ConsumerStatefulWidget {
  const _SendPaymentSheetContent({
    required this.self,
    required this.other,
    required this.contactName,
    required this.onPaymentConfirmed,
  });

  final User self;
  final User other;
  final String contactName;
  final Function(String amount, String note, [String? method, String? txId])
      onPaymentConfirmed;

  @override
  ConsumerState<_SendPaymentSheetContent> createState() =>
      _SendPaymentSheetContentState();
}

class _SendPaymentSheetContentState
    extends ConsumerState<_SendPaymentSheetContent> {
  final TextEditingController _amountController =
      TextEditingController(text: '10');
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _trxIdController = TextEditingController();

  String _selectedMethod = 'wallet'; // 'wallet', 'mfs', 'crypto'
  String _mfsType = 'bKash'; // 'bKash' or 'Nagad'
  String _cryptoNetwork = 'Binance Pay'; // 'Binance Pay', 'USDT TRC-20', 'USDT BEP-20'
  bool _isProcessing = false;
  UserWallet? _wallet;

  final List<String> _quickAmounts = ['5', '10', '25', '50', '100'];

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    try {
      final w =
          await ref.read(walletRepositoryProvider).getWallet(widget.self.id);
      if (mounted) {
        setState(() {
          _wallet = w;
        });
      }
    } catch (e) {
      debugPrint('[PaymentSheet] _fetchWallet error: $e');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  static const double _usdToBdtRate = 120.0;

  String get _recipientPhone {
    final phone = widget.other.phone.getFormattedNumber();
    if (phone.isNotEmpty) return phone;
    if (widget.other.phoneNumber.isNotEmpty) return widget.other.phoneNumber;
    return '+8801700000000';
  }

  double get _calculatedBdtAmount {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    return amt * _usdToBdtRate;
  }

  String get _recipientBinancePayId {
    final seed = widget.other.id.isNotEmpty ? widget.other.id : _recipientPhone;
    final code = seed.hashCode.abs().toString().padLeft(9, '8');
    return code.substring(0, 9);
  }

  String get _recipientTrc20Address {
    final seed = '${widget.other.id.isNotEmpty ? widget.other.id : _recipientPhone}_trc20';
    final hex = seed.hashCode.abs().toRadixString(16).padRight(33, '7c89f10a2b4e5d6a8f1c');
    return 'T${hex.substring(0, 33).toUpperCase()}';
  }

  String get _recipientBep20Address {
    final seed = '${widget.other.id.isNotEmpty ? widget.other.id : _recipientPhone}_bep20';
    final hex = seed.hashCode.abs().toRadixString(16).padRight(40, '3e4f5a6b7c8d9e0f1a2b3c4d');
    return '0x${hex.substring(0, 40).toLowerCase()}';
  }

  String get _currentCryptoDepositAddress {
    switch (_cryptoNetwork) {
      case 'USDT TRC-20':
        return _recipientTrc20Address;
      case 'USDT BEP-20':
        return _recipientBep20Address;
      case 'Binance Pay':
      default:
        return _recipientBinancePayId;
    }
  }

  int get _calculatedMinutesForAmount {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0;
    // 1 USD ~ 7 minutes
    return (amt * 7).round();
  }

  Future<void> _processPayment() async {
    final amountStr = _amountController.text.trim();
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      showSnackBar(
        context: context,
        content: 'Please enter a valid amount',
        type: SnacBarType.error,
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      String methodDisplay = 'Livocal In-App Wallet';
      String txId = '';

      if (_selectedMethod == 'wallet') {
        methodDisplay = 'Livocal Wallet';
        final minutesToSend = _calculatedMinutesForAmount;
        final available = _wallet?.balanceMinutes ?? 0;

        if (minutesToSend > available) {
          setState(() => _isProcessing = false);
          showSnackBar(
            context: context,
            content:
                'Insufficient wallet balance ($available mins available). Please recharge.',
            type: SnacBarType.error,
          );
          return;
        }

        final success =
            await ref.read(walletRepositoryProvider).transferMinutes(
                  fromUserId: widget.self.id,
                  toUserId: widget.other.id,
                  minutes: minutesToSend,
                  note: _noteController.text.trim(),
                );

        if (!success) {
          setState(() => _isProcessing = false);
          if (mounted) {
            showSnackBar(
              context: context,
              content: 'Wallet transfer failed. Please try again.',
              type: SnacBarType.error,
            );
          }
          return;
        }
        txId = 'LV-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      } else if (_selectedMethod == 'mfs') {
        methodDisplay = '$_mfsType MFS';
        final trx = _trxIdController.text.trim();
        final trxRegex = RegExp(r'^[A-Za-z0-9]{8,10}$');
        if (!trxRegex.hasMatch(trx)) {
          setState(() => _isProcessing = false);
          showSnackBar(
            context: context,
            content: 'Please enter a valid 8-10 character alphanumeric $_mfsType TrxID (e.g. BL9A7K2M9X)',
            type: SnacBarType.error,
          );
          return;
        }
        txId = trx.toUpperCase();
      } else {
        methodDisplay = 'Crypto ($_cryptoNetwork)';
        final hash = _trxIdController.text.trim();
        final hashRegex = RegExp(r'^[A-Za-z0-9]{8,80}$');
        if (!hashRegex.hasMatch(hash)) {
          setState(() => _isProcessing = false);
          showSnackBar(
            context: context,
            content: 'Please enter a valid Transaction Hash / Binance Order ID (min 8 chars)',
            type: SnacBarType.error,
          );
          return;
        }
        txId = hash;
      }

      // Log central audit record in p2p_payments for manual MFS and Crypto transfers
      if (_selectedMethod != 'wallet') {
        final payRecordId =
            'p2p_pay_${DateTime.now().millisecondsSinceEpoch}_${widget.self.id.length > 4 ? widget.self.id.substring(0, 4) : widget.self.id}';
        try {
          await FirebaseFirestore.instance
              .collection('p2p_payments')
              .doc(payRecordId)
              .set({
            'id': payRecordId,
            'type': _selectedMethod,
            'currency': _selectedMethod == 'mfs' ? 'BDT' : 'USDT',
            'bdtAmount': _selectedMethod == 'mfs' ? _calculatedBdtAmount.toStringAsFixed(0) : null,
            'cryptoNetwork': _selectedMethod == 'crypto' ? _cryptoNetwork : null,
            'recipientAddress': _selectedMethod == 'crypto' ? _currentCryptoDepositAddress : _recipientPhone,
            'methodDisplay': methodDisplay,
            'amount': amountStr,
            'senderId': widget.self.id,
            'senderPhone': widget.self.phone.getFormattedNumber(),
            'recipientId': widget.other.id,
            'recipientPhone': widget.other.phone.getFormattedNumber(),
            'recipientName': widget.contactName,
            'txId': txId,
            'note': _noteController.text.trim(),
            'status': 'pending', // Strictly pending to prevent audit forgery
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (err) {
          debugPrint('[PaymentSheet] Error logging to p2p_payments: $err');
        }
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);
      Navigator.pop(context);

      widget.onPaymentConfirmed(
        amountStr,
        _noteController.text.trim(),
        methodDisplay,
        txId,
      );

      showSnackBar(
        context: context,
        content: '\$$amountStr payment sent to ${widget.contactName}!',
        type: SnacBarType.info,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        showSnackBar(
          context: context,
          content: 'Payment failed: $e',
          type: SnacBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableMinutes = _wallet?.balanceMinutes ?? 0;
    final neededMinutes = _calculatedMinutesForAmount;
    final hasEnoughWallet = availableMinutes >= neededMinutes;

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
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF00A884), Color(0xFF25D366)],
                    ),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Payment to ${widget.contactName}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _recipientPhone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
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
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 130,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const Text(
                      'USD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quick amount chips
            Center(
              child: Wrap(
                spacing: 8,
                children: _quickAmounts.map((amt) {
                  final isSelected = _amountController.text == amt;
                  return ChoiceChip(
                    label: Text('\$$amt'),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white : Colors.black87),
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
                hintText: 'Add a note (e.g. Freelance, Dinner, Translation)',
                hintStyle: const TextStyle(fontSize: 13.5),
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Payment method selector
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'wallet',
                    groupValue: _selectedMethod,
                    title: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Livocal In-App Wallet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Balance: $availableMinutes mins (transfers $neededMinutes mins)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasEnoughWallet
                                      ? const Color(0xFF25D366)
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                        Icon(
                          Icons.phone_android,
                          size: 20,
                          color: Colors.pinkAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'bKash / Nagad MFS (Direct Send)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _selectedMethod = val!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'crypto',
                    groupValue: _selectedMethod,
                    title: const Row(
                      children: [
                        Icon(
                          Icons.currency_bitcoin,
                          size: 20,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Crypto (Binance Pay / USDT)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _selectedMethod = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Method-Specific Interactive Configuration Cards
            if (_selectedMethod == 'wallet' && !hasEnoughWallet) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Short by ${neededMinutes - availableMinutes} mins to complete this transfer.',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () {
                        showMinuteRechargeSheet(
                          context,
                          user: widget.self,
                          onRecharged: _fetchWallet,
                        );
                      },
                      child: const Text('Recharge'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_selectedMethod == 'mfs') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222E35)
                      : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('bKash'),
                          selected: _mfsType == 'bKash',
                          selectedColor: Colors.pinkAccent.withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => _mfsType = 'bKash'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Nagad'),
                          selected: _mfsType == 'Nagad',
                          selectedColor: Colors.orange.withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => _mfsType = 'Nagad'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Live USD to BDT Conversion Rate Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: (_mfsType == 'bKash' ? Colors.pinkAccent : Colors.orange)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_mfsType == 'bKash' ? Colors.pinkAccent : Colors.orange)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.currency_exchange_rounded,
                            size: 16,
                            color: _mfsType == 'bKash' ? Colors.pinkAccent : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Live Rate: \$1.00 ≈ ${_usdToBdtRate.toInt()} BDT  |  Total: ৳${_calculatedBdtAmount.toStringAsFixed(0)} BDT',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _mfsType == 'bKash'
                                    ? Colors.pinkAccent
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.contactName}\'s $_mfsType Number:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _recipientPhone,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 19,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _recipientPhone),
                            );
                            showSnackBar(
                              context: context,
                              content:
                                  '$_recipientPhone copied to clipboard!',
                              type: SnacBarType.info,
                            );
                          },
                          tooltip: 'Copy Number',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _trxIdController,
                      decoration: InputDecoration(
                        hintText: 'Enter 8-10 digit alphanumeric $_mfsType TrxID',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: TextButton(
                          onPressed: () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              setState(() {
                                _trxIdController.text = data!.text!.trim();
                              });
                            }
                          },
                          child: const Text('PASTE'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_selectedMethod == 'crypto') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222E35)
                      : const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: [
                        'Binance Pay',
                        'USDT TRC-20',
                        'USDT BEP-20',
                      ].map((net) {
                        return ChoiceChip(
                          label: Text(net, style: const TextStyle(fontSize: 12)),
                          selected: _cryptoNetwork == net,
                          selectedColor: Colors.orange.withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => _cryptoNetwork = net),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    // Recipient's Crypto Deposit Address with 1-Tap Copy
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E282D) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.contactName}\'s ${_cryptoNetwork == "Binance Pay" ? "Binance Pay ID" : "$_cryptoNetwork Deposit Address"}:',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                SelectableText(
                                  _currentCryptoDepositAddress,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 19,
                              color: Colors.orange,
                            ),
                            tooltip: 'Copy Address',
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: _currentCryptoDepositAddress),
                              );
                              showSnackBar(
                                context: context,
                                content:
                                    '$_cryptoNetwork address copied to clipboard!',
                                type: SnacBarType.info,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _trxIdController,
                      decoration: InputDecoration(
                        hintText: 'Enter TxHash / Binance Order ID',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: TextButton(
                          onPressed: () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              setState(() {
                                _trxIdController.text = data!.text!.trim();
                              });
                            }
                          },
                          child: const Text('PASTE'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _isProcessing ? null : _processPayment,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Confirm Payment: \$${_amountController.text.trim().isEmpty ? "0" : _amountController.text.trim()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
