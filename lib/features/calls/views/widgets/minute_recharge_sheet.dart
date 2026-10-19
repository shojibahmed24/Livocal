import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/models/user_wallet.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';

Future<void> showMinuteRechargeSheet(
  BuildContext context, {
  required User user,
  VoidCallback? onRecharged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => MinuteRechargeSheet(
      user: user,
      onRecharged: onRecharged,
    ),
  );
}

class MinuteRechargeSheet extends ConsumerStatefulWidget {
  final User user;
  final VoidCallback? onRecharged;

  const MinuteRechargeSheet({
    super.key,
    required this.user,
    this.onRecharged,
  });

  @override
  ConsumerState<MinuteRechargeSheet> createState() => _MinuteRechargeSheetState();
}

class _MinuteRechargeSheetState extends ConsumerState<MinuteRechargeSheet> {
  int _selectedPackMinutes = 180;
  double _selectedPackAmount = 3000.0;
  String _selectedPackId = 'pro_180';
  String _selectedPaymentMethod = 'bKash / Nagad';
  String _selectedCryptoNetwork = 'TRC-20'; // 'TRC-20' or 'BEP-20'
  bool _isProcessing = false;
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _trxIdController = TextEditingController();
  bool _showPromoField = false;
  Map<String, dynamic>? _depositInfo;
  bool _isLoadingDepositInfo = true;
  String? _depositInfoError;

  double get _selectedPackAmountUsdt {
    if (_selectedPackId == 'starter_60') return 10.0;
    if (_selectedPackId == 'pro_180') return 25.0;
    if (_selectedPackId == 'agency_500') return 60.0;
    return 25.0;
  }

  String get _bkashNumber =>
      _depositInfo?['bkash']?['number'] as String? ?? '';
  String get _nagadNumber =>
      _depositInfo?['nagad']?['number'] as String? ?? '';
  String get _binancePayId =>
      _depositInfo?['binancePay']?['payId'] as String? ?? '';
  String get _trc20Address =>
      _depositInfo?['cryptoUsdt']?['trc20']?['address'] as String? ?? '';
  String get _bep20Address =>
      _depositInfo?['cryptoUsdt']?['bep20']?['address'] as String? ?? '';

  String get _currentDepositAccount {
    if (_selectedPaymentMethod == 'bKash / Nagad') {
      return _bkashNumber.isNotEmpty ? _bkashNumber : _nagadNumber;
    }
    if (_selectedPaymentMethod == 'Binance Pay') return _binancePayId;
    return _selectedCryptoNetwork == 'BEP-20' ? _bep20Address : _trc20Address;
  }

  @override
  void initState() {
    super.initState();
    _senderPhoneController.text = widget.user.phoneNumber;
    _fetchDepositInfo();
  }

  Future<void> _fetchDepositInfo() async {
    setState(() {
      _isLoadingDepositInfo = true;
      _depositInfoError = null;
    });
    try {
      final info = await ref.read(walletRepositoryProvider).getDepositInfo();
      if (!mounted) return;
      if (info != null) {
        setState(() {
          _depositInfo = info;
          _isLoadingDepositInfo = false;
          _depositInfoError = null;
        });
      } else {
        setState(() {
          _isLoadingDepositInfo = false;
          _depositInfoError = AppStrings.tr(ref, 'depositAccountNotFound');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDepositInfo = false;
        _depositInfoError = '${AppStrings.tr(ref, 'depositAccountNotFound')} ($e)';
      });
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    _senderPhoneController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  void _selectPack({
    required String packId,
    required int minutes,
    required double amount,
  }) {
    setState(() {
      _selectedPackId = packId;
      _selectedPackMinutes = minutes;
      _selectedPackAmount = amount;
    });
  }

  Future<void> _processRecharge() async {
    if (_currentDepositAccount.isEmpty) {
      showSnackBar(
        context: context,
        content: AppStrings.tr(ref, 'waitForDepositAccountSnack'),
        type: SnacBarType.error,
      );
      return;
    }

    final identifier = _senderPhoneController.text.trim();
    final trxId = _trxIdController.text.trim();

    if (identifier.isEmpty) {
      showSnackBar(
        context: context,
        content: _selectedPaymentMethod == 'bKash / Nagad'
            ? AppStrings.tr(ref, 'enterSenderPhoneSnack')
            : (_selectedPaymentMethod == 'Binance Pay'
                ? AppStrings.tr(ref, 'enterBinancePayIdSnack')
                : AppStrings.tr(ref, 'enterSenderCryptoAddressSnack')),
        type: SnacBarType.error,
      );
      return;
    }

    if (trxId.isEmpty) {
      showSnackBar(
        context: context,
        content: _selectedPaymentMethod == 'Crypto USDT'
            ? AppStrings.tr(ref, 'enterTxHashSnack')
            : AppStrings.tr(ref, 'enterTrxIdSnack'),
        type: SnacBarType.error,
      );
      return;
    }

    // Client-side address and tx hash sanity checks
    if (_selectedPaymentMethod == 'Crypto USDT') {
      if (_selectedCryptoNetwork == 'TRC-20' && (!identifier.startsWith('T') || identifier.length != 34)) {
        showSnackBar(
          context: context,
          content: AppStrings.tr(ref, 'trc20AddressLengthError'),
          type: SnacBarType.error,
        );
        return;
      }
      if (_selectedCryptoNetwork == 'BEP-20' && (!identifier.startsWith('0x') || identifier.length != 42)) {
        showSnackBar(
          context: context,
          content: AppStrings.tr(ref, 'bep20AddressLengthError'),
          type: SnacBarType.error,
        );
        return;
      }
      final cleanHash = trxId.replaceAll('0x', '');
      if (cleanHash.length != 64) {
        showSnackBar(
          context: context,
          content: AppStrings.tr(ref, 'invalidTxHashError'),
          type: SnacBarType.error,
        );
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    final promo = _promoController.text.trim();

    String paymentMethodKey = 'bKash';
    if (_selectedPaymentMethod == 'Binance Pay') {
      paymentMethodKey = 'Binance_Pay';
    } else if (_selectedPaymentMethod == 'Crypto USDT') {
      paymentMethodKey = _selectedCryptoNetwork == 'BEP-20' ? 'Crypto_USDT_BEP20' : 'Crypto_USDT_TRC20';
    }

    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.submitPaymentRequest(
      packId: _selectedPackId,
      senderIdentifier: identifier,
      trxId: trxId,
      paymentMethod: paymentMethodKey,
      promoCode: promo.isNotEmpty ? promo : null,
      senderPhone: _selectedPaymentMethod == 'bKash / Nagad' ? identifier : widget.user.phoneNumber,
      minutes: _selectedPackMinutes,
      amount: _selectedPaymentMethod == 'bKash / Nagad' ? _selectedPackAmount : _selectedPackAmountUsdt,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (result.success) {
      Navigator.of(context).pop();
      widget.onRecharged?.call();
      showSnackBar(
        context: context,
        content: AppStrings.tr(ref, 'paymentSubmittedSuccess'),
        type: SnacBarType.info,
      );
    } else {
      showSnackBar(
        context: context,
        content: result.message ?? AppStrings.tr(ref, 'paymentFailedSnack'),
        type: SnacBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF131D2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    const primaryColor = AppColors.primary;
    final walletAsync = ref.watch(walletStreamProvider(widget.user.id));
    final wallet = walletAsync.value ?? UserWallet.newTrial();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.diamond_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr(ref, 'voiceMinutesRecharge'),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      AppStrings.tr(ref, 'talkToInternationalClients'),
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                color: isDark ? Colors.white54 : Colors.black45,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              children: [
                // Current Wallet Status Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0F2B24), const Color(0xFF13232C)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFE0F2F1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                wallet.effectiveRemainingMinutes > 0 ? '💎' : '⚠️',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.trParams(ref, 'currentBalanceText', {'minutes': '${wallet.effectiveRemainingMinutes}'}),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          if (wallet.trialActive && !wallet.isTrialExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                AppStrings.trParams(ref, 'trialBadgeText', {'minutes': '${wallet.trialMinutes}'}),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        wallet.trialActive && !wallet.isTrialExpired
                            ? AppStrings.trParams(ref, 'trialValidityText', {
                                'days': '${wallet.daysRemainingInTrial}',
                                'paid': '${wallet.balanceMinutes}',
                              })
                            : AppStrings.tr(ref, 'paidBalanceLifetimeText'),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 11.5,
                        ),
                      ),
                      const Divider(height: 16, thickness: 0.8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppStrings.tr(ref, 'sameLanguageFreeRule'),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF06B6D4), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppStrings.tr(ref, 'geminiAiRateRule'),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Package Selection Title
                Text(
                  AppStrings.tr(ref, 'selectMinutePack'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),

                // Pack 1: Starter Pack (60 Mins)
                _buildPackCard(
                  packId: 'starter_60',
                  title: AppStrings.tr(ref, 'starterPackTitle'),
                  minutes: 60,
                  amount: 1200.0,
                  subtitle: AppStrings.tr(ref, 'starterPackDesc'),
                  badge: null,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 10),

                // Pack 2: Freelancer Pro (180 Mins) - POPULAR
                _buildPackCard(
                  packId: 'pro_180',
                  title: AppStrings.tr(ref, 'proPackTitle'),
                  minutes: 180,
                  amount: 3000.0,
                  subtitle: AppStrings.tr(ref, 'proPackDesc'),
                  badge: AppStrings.tr(ref, 'popularBadge'),
                  isPopular: true,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 10),

                // Pack 3: Agency Pack (500 Mins) - BEST VALUE
                _buildPackCard(
                  packId: 'agency_500',
                  title: AppStrings.tr(ref, 'agencyPackTitle'),
                  minutes: 500,
                  amount: 7200.0,
                  subtitle: AppStrings.tr(ref, 'agencyPackDesc'),
                  badge: AppStrings.tr(ref, 'bestValueBadge'),
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),

                // Payment Method Selector
                Text(
                  AppStrings.tr(ref, 'paymentMethod'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodTile(
                        title: 'bKash / Nagad',
                        subtitle: AppStrings.tr(ref, 'bdtLocal'),
                        icon: Icons.account_balance_wallet_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMethodTile(
                        title: 'Binance Pay',
                        subtitle: 'Binance ID (USDT)',
                        icon: Icons.currency_exchange_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMethodTile(
                        title: 'Crypto USDT',
                        subtitle: 'TRC20 / BEP20',
                        icon: Icons.toll_rounded,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Promo / Voucher Code Button / Field
                if (!_showPromoField)
                  InkWell(
                    onTap: () => setState(() => _showPromoField = true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.discount_outlined, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.tr(ref, 'havePromoCode'),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(color: textColor, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. LIVOCAL2026',
                            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          final code = _promoController.text.trim().toUpperCase();
                          if (code == 'LIVOCAL2026') {
                            showSnackBar(
                              context: context,
                              content: AppStrings.trParams(ref, 'promoAppliedBonus', {'bonus': '20'}),
                              type: SnacBarType.info,
                            );
                          } else if (code == 'FREELANCERPRO') {
                            showSnackBar(
                              context: context,
                              content: AppStrings.trParams(ref, 'promoAppliedBonus', {'bonus': '30'}),
                              type: SnacBarType.info,
                            );
                          } else {
                            showSnackBar(
                              context: context,
                              content: AppStrings.tr(ref, 'invalidPromoCode'),
                              type: SnacBarType.error,
                            );
                          }
                        },
                        child: Text(AppStrings.tr(ref, 'apply'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),

                // Real Payment Instructions Box (bKash / Binance Pay / Crypto USDT)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedPaymentMethod == 'bKash / Nagad'
                                ? Icons.verified_user_rounded
                                : (_selectedPaymentMethod == 'Binance Pay'
                                    ? Icons.currency_exchange_rounded
                                    : Icons.toll_rounded),
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedPaymentMethod == 'bKash / Nagad'
                                ? AppStrings.tr(ref, 'realPaymentGuideBkash')
                                : (_selectedPaymentMethod == 'Binance Pay'
                                    ? AppStrings.tr(ref, 'realPaymentGuideBinance')
                                    : AppStrings.tr(ref, 'realPaymentGuideCrypto')),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Crypto Network Switcher (For Crypto USDT)
                      if (_selectedPaymentMethod == 'Crypto USDT') ...[
                        Row(
                          children: [
                            Text(
                              AppStrings.tr(ref, 'selectNetwork'),
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text('TRC-20 (TRON)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: _selectedCryptoNetwork == 'TRC-20',
                              onSelected: (_) => setState(() => _selectedCryptoNetwork = 'TRC-20'),
                              selectedColor: primaryColor.withValues(alpha: 0.25),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('BEP-20 (BSC)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: _selectedCryptoNetwork == 'BEP-20',
                              onSelected: (_) => setState(() => _selectedCryptoNetwork = 'BEP-20'),
                              selectedColor: primaryColor.withValues(alpha: 0.25),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Payment Account / Address Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: _isLoadingDepositInfo
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      AppStrings.tr(ref, 'loadingDepositAccount'),
                                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              )
                            : (_depositInfoError != null || _currentDepositAccount.isEmpty)
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _depositInfoError ?? AppStrings.tr(ref, 'depositAccountNotFound'),
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
                                          onPressed: _fetchDepositInfo,
                                          tooltip: AppStrings.tr(ref, 'retryTooltip'),
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedPaymentMethod == 'bKash / Nagad'
                                                  ? AppStrings.tr(ref, 'bkashMerchantNumber')
                                                  : (_selectedPaymentMethod == 'Binance Pay'
                                                      ? AppStrings.tr(ref, 'binancePayOfficialId')
                                                      : AppStrings.trParams(ref, 'cryptoOfficialDepositAddress', {'network': _selectedCryptoNetwork})),
                                              style: TextStyle(
                                                color: isDark ? Colors.white60 : Colors.black54,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _currentDepositAccount,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                                letterSpacing: 0.8,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          backgroundColor: primaryColor.withValues(alpha: 0.12),
                                        ),
                                        icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                                        label: Text(
                                          AppStrings.tr(ref, 'copyBtn'),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () {
                                          final textToCopy = _currentDepositAccount;
                                          Clipboard.setData(ClipboardData(text: textToCopy));
                                          showSnackBar(
                                            context: context,
                                            content: AppStrings.trParams(ref, 'copiedToClipboardSnack', {'text': textToCopy}),
                                            type: SnacBarType.info,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedPaymentMethod == 'bKash / Nagad'
                            ? AppStrings.trParams(ref, 'paymentInstructionBkash', {'amount': _selectedPackAmount.toStringAsFixed(0)})
                            : (_selectedPaymentMethod == 'Binance Pay'
                                ? AppStrings.trParams(ref, 'paymentInstructionBinance', {'amount': _selectedPackAmountUsdt.toStringAsFixed(0)})
                                : AppStrings.trParams(ref, 'paymentInstructionCrypto', {'amount': _selectedPackAmountUsdt.toStringAsFixed(0), 'network': _selectedCryptoNetwork})),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Sender Identifier Field
                      TextField(
                        controller: _senderPhoneController,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: _selectedPaymentMethod == 'bKash / Nagad'
                              ? AppStrings.tr(ref, 'senderNumberInputLabel')
                              : (_selectedPaymentMethod == 'Binance Pay'
                                  ? AppStrings.tr(ref, 'binancePayIdInputLabel')
                                  : AppStrings.tr(ref, 'senderAddressInputLabel')),
                          labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                          hintText: _selectedPaymentMethod == 'bKash / Nagad'
                              ? '017xxxxxxxx'
                              : (_selectedPaymentMethod == 'Binance Pay' ? '849201842' : 'TXvJ... / 0x48...'),
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12),
                          prefixIcon: Icon(
                            _selectedPaymentMethod == 'bKash / Nagad' ? Icons.phone_android_rounded : Icons.account_box_rounded,
                            size: 18,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // TrxID / TxHash Field
                      TextField(
                        controller: _trxIdController,
                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: _selectedPaymentMethod == 'bKash / Nagad'
                              ? AppStrings.tr(ref, 'trxIdInputLabel')
                              : (_selectedPaymentMethod == 'Binance Pay'
                                  ? AppStrings.tr(ref, 'binancePayOrderIdInputLabel')
                                  : AppStrings.tr(ref, 'txHashInputLabel')),
                          labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                          hintText: _selectedPaymentMethod == 'bKash / Nagad'
                              ? 'e.g. BKA8X92K4L'
                              : (_selectedPaymentMethod == 'Binance Pay' ? 'e.g. 293847291039485' : 'e.g. 0x8a9b... / 7c4e...'),
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 12),
                          prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Primary Recharge Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              onPressed: _isProcessing ? null : _processRecharge,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      _selectedPaymentMethod == 'bKash / Nagad'
                          ? AppStrings.trParams(ref, 'submitPaymentBdt', {'amount': _selectedPackAmount.toStringAsFixed(0)})
                          : AppStrings.trParams(ref, 'submitPaymentUsdt', {'amount': _selectedPackAmountUsdt.toStringAsFixed(0)}),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard({
    required String packId,
    required String title,
    required int minutes,
    required double amount,
    required String subtitle,
    String? badge,
    bool isPopular = false,
    required bool isDark,
    required Color textColor,
  }) {
    final isSelected = _selectedPackId == packId;
    const primaryColor = AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _selectPack(packId: packId, minutes: minutes, amount: amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isPopular ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.black12)),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.black38),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPopular ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: isPopular ? const Color(0xFFF59E0B) : primaryColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  Text(
                    AppStrings.tr(
                      ref,
                      'bdtAmount',
                      args: {'amount': amount.toStringAsFixed(0)},
                    ),
                    style: TextStyle(
                      color: isSelected ? primaryColor : textColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedPaymentMethod == title;
    const primaryColor = AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.16 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : (isDark ? Colors.white54 : Colors.black54), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? primaryColor : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
