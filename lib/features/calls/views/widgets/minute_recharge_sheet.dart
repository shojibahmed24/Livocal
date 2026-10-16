import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/models/user_wallet.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
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
  bool _isProcessing = false;
  final TextEditingController _promoController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _trxIdController = TextEditingController();
  bool _showPromoField = false;

  @override
  void initState() {
    super.initState();
    _senderPhoneController.text = widget.user.phoneNumber;
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
    final senderPhone = _senderPhoneController.text.trim();
    final trxId = _trxIdController.text.trim();

    if (senderPhone.isEmpty) {
      showSnackBar(
        context: context,
        content: 'অনুগ্রহ করে টাকা পাঠানোর ফোন নম্বরটি লিখুন।',
        type: SnacBarType.error,
      );
      return;
    }

    if (trxId.isEmpty) {
      showSnackBar(
        context: context,
        content: 'অনুগ্রহ করে bKash / Nagad ট্রানজেকশন আইডি (TrxID) লিখুন।',
        type: SnacBarType.error,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final promo = _promoController.text.trim();
    int bonusMinutes = 0;
    if (promo.toUpperCase() == 'LIVOCAL2026') {
      bonusMinutes = 20;
    } else if (promo.toUpperCase() == 'FREELANCERPRO') {
      bonusMinutes = 30;
    }

    final totalMinutes = _selectedPackMinutes + bonusMinutes;

    final repo = ref.read(walletRepositoryProvider);
    final success = await repo.submitPaymentRequest(
      packId: _selectedPackId,
      minutes: totalMinutes,
      amount: _selectedPackAmount,
      senderPhone: senderPhone,
      trxId: trxId,
      paymentMethod: _selectedPaymentMethod,
      promoCode: promo.isNotEmpty ? promo : null,
    );

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (success) {
      Navigator.of(context).pop();
      widget.onRecharged?.call();
      showSnackBar(
        context: context,
        content: 'পেমেন্ট রিকোয়েস্ট জমা হয়েছে! অ্যাডমিন অনুমোদন করলেই $totalMinutes মিনিট যোগ হবে।',
        type: SnacBarType.info,
      );
    } else {
      showSnackBar(
        context: context,
        content: 'পেমেন্ট রিকোয়েস্ট জমা দেওয়া যায়নি। TrxID ইতিমধ্যে জমা হয়েছে অথবা সার্ভার ত্রুটি।',
        type: SnacBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF131D2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = AppColors.primary;
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
                  color: primaryColor.withOpacity(0.18),
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
                      'মিনিট রিচার্জ (Voice Minutes)',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'আন্তর্জাতিক ক্লায়েন্টদের সাথে কথা বলুন যেকোনো ভাষায়',
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
                    border: Border.all(color: primaryColor.withOpacity(0.35)),
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
                                'বর্তমান ব্যালেন্স: ${wallet.effectiveRemainingMinutes} মিনিট',
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
                                color: primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ট্রায়াল: ${wallet.trialMinutes} মি.',
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
                            ? 'ফ্রি ট্রায়ালের মেয়াদ বাকি: ${wallet.daysRemainingInTrial} দিন (পেইড ব্যালেন্স: ${wallet.balanceMinutes} মি.)'
                            : 'পেইড ব্যালেন্স কখনো মেয়াদোত্তীর্ণ হয় না (Lifetime validity)',
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
                              '🗣️ একই ভাষার লোকাল কল ১০০% ফ্রি (কোনো মিনিট কাটবে না)',
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
                              '🤖 Gemini 3.5 Live AI অনুবাদিত কল: ১ মিনিট/মিনিট',
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
                  'প্যাকেজ নির্বাচন করুন (Select Minute Pack)',
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
                  title: 'স্টার্টার প্যাক (Starter Pack)',
                  minutes: 60,
                  amount: 1200.0,
                  subtitle: 'দ্রুত ক্লায়েন্ট ইন্টারভিউ ও প্রাথমিক ব্রিফের জন্য (~৳২০/মি.)',
                  badge: null,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 10),

                // Pack 2: Freelancer Pro (180 Mins) - POPULAR
                _buildPackCard(
                  packId: 'pro_180',
                  title: 'ফ্রিল্যান্সার প্রো (Freelancer Pro)',
                  minutes: 180,
                  amount: 3000.0,
                  subtitle: 'সাপ্তাহিক প্রজেক্ট মিটিং ও নিয়মিত ফ্রিল্যান্সিং (~৳১৬.৬/মি., ১৭% সাশ্রয়)',
                  badge: '⭐ সেরা পছন্দ (POPULAR)',
                  isPopular: true,
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 10),

                // Pack 3: Agency Pack (500 Mins) - BEST VALUE
                _buildPackCard(
                  packId: 'agency_500',
                  title: 'এজেন্সি প্যাক (Agency / Heavy Pack)',
                  minutes: 500,
                  amount: 7200.0,
                  subtitle: 'এজেন্সি টিম ও দীর্ঘ আন্তর্জাতিক কলের জন্য (~৳১৪.৪/মি., ২৮% সাশ্রয়)',
                  badge: '💎 সর্বোচ্চ ভ্যালু (BEST VALUE)',
                  isDark: isDark,
                  textColor: textColor,
                ),
                const SizedBox(height: 16),

                // Payment Method Selector
                Text(
                  'পেমেন্ট মাধ্যম (Payment Method)',
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
                        subtitle: 'তাত্ক্ষণিক রিচার্জ',
                        icon: Icons.account_balance_wallet_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPaymentMethodTile(
                        title: 'Card / Visa',
                        subtitle: 'Mastercard / Amex',
                        icon: Icons.credit_card_rounded,
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
                        children: const [
                          Icon(Icons.discount_outlined, color: AppColors.primary, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'প্রোমো কোড বা ভাউচার আছে? ক্লিক করুন',
                            style: TextStyle(
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
                            showSnackBar(context: context, content: 'কোড প্রযোজ্য! +২০ মিনিট বোনাস পাবেন।', type: SnacBarType.info);
                          } else if (code == 'FREELANCERPRO') {
                            showSnackBar(context: context, content: 'কোড প্রযোজ্য! +৩০ মিনিট বোনাস পাবেন।', type: SnacBarType.info);
                          } else {
                            showSnackBar(context: context, content: 'মেয়াদোত্তীর্ণ বা অবৈধ প্রোমো কোড।', type: SnacBarType.error);
                          }
                        },
                        child: const Text('প্রয়োগ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),

                // Real bKash / Nagad Payment Instructions Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryColor.withOpacity(0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'রিয়েল পেমেন্ট নির্দেশিকা (Real Payment Verification)',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Payment Number Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'bKash / Nagad পার্সোনাল / মার্চেন্ট নম্বর:',
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                                const Text(
                                  '01721013902',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                backgroundColor: primaryColor.withOpacity(0.12),
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                              label: const Text(
                                'কপি করুন',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: '01721013902'));
                                showSnackBar(
                                  context: context,
                                  content: 'নম্বর 01721013902 ক্লিপবোর্ডে কপি করা হয়েছে!',
                                  type: SnacBarType.info,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '১. আপনার bKash বা Nagad অ্যাপে গিয়ে Send Money বা পেমেন্ট করুন ৳${_selectedPackAmount.toStringAsFixed(0)}।\n২. সফল ট্রানজেকশনের পর নিচের ঘরে আপনার নম্বর ও TrxID লিখুন:',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Sender Phone Field
                      TextField(
                        controller: _senderPhoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'আপনার টাকা পাঠানোর ফোন নম্বর (Sender Number)',
                          labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                          prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
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
                      // TrxID Field
                      TextField(
                        controller: _trxIdController,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'bKash / Nagad TrxID (Transaction ID)',
                          labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                          hintText: 'e.g. BKA8X92K4L',
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
                      '৳${_selectedPackAmount.toStringAsFixed(0)} পেমেন্ট ভেরিফিকেশন জমা দিন',
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
    final primaryColor = AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _selectPack(packId: packId, minutes: minutes, amount: amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(isDark ? 0.16 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isPopular ? const Color(0xFFF59E0B).withOpacity(0.5) : (isDark ? Colors.white12 : Colors.black12)),
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
                      color: isPopular ? const Color(0xFFF59E0B).withOpacity(0.2) : primaryColor.withOpacity(0.2),
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
                    '৳${amount.toStringAsFixed(0)}',
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
    final primaryColor = AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(isDark ? 0.16 : 0.08)
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
