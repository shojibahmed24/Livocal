import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/ui/livocal_buttons.dart';
import 'package:livocal/shared/ui/livocal_card.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  final User user;
  const PaymentSettingsScreen({super.key, required this.user});

  @override
  ConsumerState<PaymentSettingsScreen> createState() =>
      _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _binancePayController = TextEditingController();
  final _trc20Controller = TextEditingController();
  final _bep20Controller = TextEditingController();
  final _bkashController = TextEditingController();
  final _nagadController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
  }

  @override
  void dispose() {
    _binancePayController.dispose();
    _trc20Controller.dispose();
    _bep20Controller.dispose();
    _bkashController.dispose();
    _nagadController.dispose();
    super.dispose();
  }

  String _prefKey(String uid, String field) => 'payment_${uid}_$field';

  Future<void> _loadExistingSettings() async {
    final authUid = fba.FirebaseAuth.instance.currentUser?.uid;
    final uid =
        (authUid != null && authUid.isNotEmpty) ? authUid : widget.user.id;

    // 1. Immediately populate from user-scoped local cache so UI is responsive
    try {
      final localBinance =
          SharedPref.instance.getString(_prefKey(uid, 'binancePayId')) ?? '';
      final localTrc20 =
          SharedPref.instance.getString(_prefKey(uid, 'cryptoUsdtTrc20')) ?? '';
      final localBep20 =
          SharedPref.instance.getString(_prefKey(uid, 'cryptoUsdtBep20')) ?? '';
      final localBkash =
          SharedPref.instance.getString(_prefKey(uid, 'bkashNumber')) ?? '';
      final localNagad =
          SharedPref.instance.getString(_prefKey(uid, 'nagadNumber')) ?? '';

      if (localBinance.isNotEmpty) _binancePayController.text = localBinance;
      if (localTrc20.isNotEmpty) _trc20Controller.text = localTrc20;
      if (localBep20.isNotEmpty) _bep20Controller.text = localBep20;
      if (localBkash.isNotEmpty) _bkashController.text = localBkash;
      if (localNagad.isNotEmpty) _nagadController.text = localNagad;
    } catch (_) {}

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('users').doc(uid);

      final results = await Future.wait([
        docRef.get(),
        docRef.collection('wallet').doc('payment_settings').get(),
      ]);

      final userData = results[0].data() ?? {};
      final walletData = results[1].data() ?? {};

      if (mounted) {
        setState(() {
          // Authoritative remote data: allow clearing fields if deleted remotely
          final bPay =
              (walletData['binancePayId'] ?? userData['binancePayId'] ?? '')
                  .toString();
          final trc = (walletData['cryptoUsdtTrc20'] ??
                  userData['cryptoUsdtTrc20'] ??
                  '')
              .toString();
          final bep = (walletData['cryptoUsdtBep20'] ??
                  userData['cryptoUsdtBep20'] ??
                  '')
              .toString();
          final bks =
              (walletData['bkashNumber'] ?? userData['bkashNumber'] ?? '')
                  .toString();
          final ngd =
              (walletData['nagadNumber'] ?? userData['nagadNumber'] ?? '')
                  .toString();

          _binancePayController.text = bPay;
          _trc20Controller.text = trc;
          _bep20Controller.text = bep;
          _bkashController.text = bks;
          _nagadController.text = ngd;

          _isLoading = false;
        });

        // Mirror remote data into user-scoped cache
        try {
          await SharedPref.instance.setString(
              _prefKey(uid, 'binancePayId'), _binancePayController.text);
          await SharedPref.instance.setString(
              _prefKey(uid, 'cryptoUsdtTrc20'), _trc20Controller.text);
          await SharedPref.instance.setString(
              _prefKey(uid, 'cryptoUsdtBep20'), _bep20Controller.text);
          await SharedPref.instance
              .setString(_prefKey(uid, 'bkashNumber'), _bkashController.text);
          await SharedPref.instance
              .setString(_prefKey(uid, 'nagadNumber'), _nagadController.text);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[PaymentSettings] Error loading remote settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authUid = fba.FirebaseAuth.instance.currentUser?.uid;
    final uid =
        (authUid != null && authUid.isNotEmpty) ? authUid : widget.user.id;

    final binancePay = _binancePayController.text.trim();
    final trc20 = _trc20Controller.text.trim();
    final bep20 = _bep20Controller.text.trim();
    final bkash = _bkashController.text.trim();
    final nagad = _nagadController.text.trim();

    bool remoteSaved = false;

    // 1. Try Backend API
    try {
      final idToken = await GeminiLiveTranslator.getAuthToken();
      final url = Uri.parse(AppConfig.walletMyPaymentSettingsUrl);
      final res = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (idToken != null) 'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'binancePayId': binancePay,
              'cryptoUsdtTrc20': trc20,
              'cryptoUsdtBep20': bep20,
              'bkashNumber': bkash,
              'nagadNumber': nagad,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        remoteSaved = true;
      }
    } catch (backendErr) {
      debugPrint('[PaymentSettings] Backend save note: $backendErr');
    }

    // 2. Direct Firestore fallback if backend failed
    if (!remoteSaved) {
      try {
        final firestore = FirebaseFirestore.instance;
        final paymentSettingsRef = firestore
            .collection('users')
            .doc(uid)
            .collection('wallet')
            .doc('payment_settings');

        await paymentSettingsRef.set({
          'binancePayId': binancePay,
          'cryptoUsdtTrc20': trc20,
          'cryptoUsdtBep20': bep20,
          'bkashNumber': bkash,
          'nagadNumber': nagad,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Scrub any legacy payment fields from the public parent user document to isolate PII
        await firestore.collection('users').doc(uid).update({
          'binancePayId': FieldValue.delete(),
          'cryptoUsdtTrc20': FieldValue.delete(),
          'cryptoUsdtBep20': FieldValue.delete(),
          'bkashNumber': FieldValue.delete(),
          'nagadNumber': FieldValue.delete(),
        }).catchError((_) {});

        remoteSaved = true;
      } catch (e) {
        debugPrint('[PaymentSettings] Firestore save error: $e');
      }
    }

    // 3. Handle outcome: update local cache and dismiss ONLY on verified remote success
    if (remoteSaved) {
      try {
        await SharedPref.instance
            .setString(_prefKey(uid, 'binancePayId'), binancePay);
        await SharedPref.instance
            .setString(_prefKey(uid, 'cryptoUsdtTrc20'), trc20);
        await SharedPref.instance
            .setString(_prefKey(uid, 'cryptoUsdtBep20'), bep20);
        await SharedPref.instance
            .setString(_prefKey(uid, 'bkashNumber'), bkash);
        await SharedPref.instance
            .setString(_prefKey(uid, 'nagadNumber'), nagad);
      } catch (e) {
        debugPrint('[PaymentSettings] Local save warning: $e');
      }

      if (mounted) {
        setState(() => _isSaving = false);
        showSnackBar(
          context: context,
          content: 'Payment receiving accounts saved successfully!',
          type: SnacBarType.info,
        );
        Navigator.pop(context);
      }
    } else {
      // Both remote writes failed: fail loudly so user is never misled
      if (mounted) {
        setState(() => _isSaving = false);
        showSnackBar(
          context: context,
          content:
              'Failed to save payment accounts to server. Please check your internet connection.',
          type: SnacBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr(ref, 'paymentReceivingAccounts')),
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: primaryColor, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.tr(ref, 'p2pPaymentSettings'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  AppStrings.tr(ref, 'p2pPaymentSettingsDesc'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(
                      AppStrings.tr(ref, 'cryptocurrencyAndBinance'),
                      isDark,
                    ),
                    const SizedBox(height: 10),
                    LivocalCard(
                      child: Column(
                        children: [
                          _binanceField(),
                          const SizedBox(height: 16),
                          _trc20Field(),
                          const SizedBox(height: 16),
                          _bep20Field(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle(
                      AppStrings.tr(ref, 'mobileFinancialServices'),
                      isDark,
                    ),
                    const SizedBox(height: 10),
                    LivocalCard(
                      child: Column(
                        children: [
                          _bkashField(),
                          const SizedBox(height: 16),
                          _nagadField(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: AppStrings.tr(ref, 'savePaymentAccounts'),
                      icon: Icons.save_rounded,
                      loading: _isSaving,
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _binanceField() {
    return TextFormField(
      controller: _binancePayController,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: AppStrings.tr(ref, 'binancePayIdLabel'),
        hintText: AppStrings.tr(ref, 'binancePayIdHint'),
        prefixIcon:
            const Icon(Icons.currency_bitcoin_rounded, color: Colors.amber),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: AppStrings.tr(ref, 'binancePayIdHelper'),
      ),
      validator: (value) {
        final val = (value ?? '').trim();
        if (val.isEmpty) return null;
        final isDigits = RegExp(r'^\d{8,12}$').hasMatch(val);
        final isEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(val);
        if (!isDigits && !isEmail) {
          return AppStrings.tr(ref, 'binancePayIdInvalid');
        }
        return null;
      },
    );
  }

  Widget _trc20Field() {
    return TextFormField(
      controller: _trc20Controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: AppStrings.tr(ref, 'usdtTrc20Label'),
        hintText: AppStrings.tr(ref, 'usdtTrc20Hint'),
        prefixIcon:
            const Icon(Icons.account_balance_wallet, color: Colors.redAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        final val = (value ?? '').trim();
        if (val.isEmpty) return null;
        if (!RegExp(r'^T[a-zA-HJ-NP-Z0-9]{33}$').hasMatch(val)) {
          return AppStrings.tr(ref, 'usdtTrc20Invalid');
        }
        return null;
      },
    );
  }

  Widget _bep20Field() {
    return TextFormField(
      controller: _bep20Controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: AppStrings.tr(ref, 'usdtBep20Label'),
        hintText: AppStrings.tr(ref, 'usdtBep20Hint'),
        prefixIcon: const Icon(Icons.toll_rounded, color: Colors.amber),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        final val = (value ?? '').trim();
        if (val.isEmpty) return null;
        if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(val)) {
          return AppStrings.tr(ref, 'usdtBep20Invalid');
        }
        return null;
      },
    );
  }

  Widget _bkashField() {
    return TextFormField(
      controller: _bkashController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: AppStrings.tr(ref, 'bkashPersonalLabel'),
        hintText: AppStrings.tr(ref, 'bkashNumberHint'),
        prefixIcon:
            const Icon(Icons.phone_android_rounded, color: Colors.pinkAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        final val = (value ?? '').trim().replaceAll(RegExp(r'[\s\-]'), '');
        if (val.isEmpty) return null;
        if (!RegExp(r'^(?:\+?8801|01)[3-9]\d{8}$').hasMatch(val)) {
          return AppStrings.tr(ref, 'bkashNumberInvalid');
        }
        return null;
      },
    );
  }

  Widget _nagadField() {
    return TextFormField(
      controller: _nagadController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: AppStrings.tr(ref, 'nagadPersonalLabel'),
        hintText: AppStrings.tr(ref, 'nagadNumberHint'),
        prefixIcon: const Icon(Icons.phone_android_rounded,
            color: Colors.deepOrangeAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        final val = (value ?? '').trim().replaceAll(RegExp(r'[\s\-]'), '');
        if (val.isEmpty) return null;
        if (!RegExp(r'^(?:\+?8801|01)[3-9]\d{8}$').hasMatch(val)) {
          return AppStrings.tr(ref, 'nagadNumberInvalid');
        }
        return null;
      },
    );
  }
}
