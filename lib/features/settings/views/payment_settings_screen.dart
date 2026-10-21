import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:livocal/features/calls/services/gemini_live_translator.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
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
    final uid = (authUid != null && authUid.isNotEmpty) ? authUid : widget.user.id;

    // 1. Immediately populate from user-scoped local cache so UI is responsive
    try {
      final localBinance = SharedPref.instance.getString(_prefKey(uid, 'binancePayId')) ?? '';
      final localTrc20 = SharedPref.instance.getString(_prefKey(uid, 'cryptoUsdtTrc20')) ?? '';
      final localBep20 = SharedPref.instance.getString(_prefKey(uid, 'cryptoUsdtBep20')) ?? '';
      final localBkash = SharedPref.instance.getString(_prefKey(uid, 'bkashNumber')) ?? '';
      final localNagad = SharedPref.instance.getString(_prefKey(uid, 'nagadNumber')) ?? '';

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
          final bPay = (walletData['binancePayId'] ?? userData['binancePayId'] ?? '').toString();
          final trc = (walletData['cryptoUsdtTrc20'] ?? userData['cryptoUsdtTrc20'] ?? '').toString();
          final bep = (walletData['cryptoUsdtBep20'] ?? userData['cryptoUsdtBep20'] ?? '').toString();
          final bks = (walletData['bkashNumber'] ?? userData['bkashNumber'] ?? '').toString();
          final ngd = (walletData['nagadNumber'] ?? userData['nagadNumber'] ?? '').toString();

          _binancePayController.text = bPay;
          _trc20Controller.text = trc;
          _bep20Controller.text = bep;
          _bkashController.text = bks;
          _nagadController.text = ngd;

          _isLoading = false;
        });

        // Mirror remote data into user-scoped cache
        try {
          await SharedPref.instance.setString(_prefKey(uid, 'binancePayId'), _binancePayController.text);
          await SharedPref.instance.setString(_prefKey(uid, 'cryptoUsdtTrc20'), _trc20Controller.text);
          await SharedPref.instance.setString(_prefKey(uid, 'cryptoUsdtBep20'), _bep20Controller.text);
          await SharedPref.instance.setString(_prefKey(uid, 'bkashNumber'), _bkashController.text);
          await SharedPref.instance.setString(_prefKey(uid, 'nagadNumber'), _nagadController.text);
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
    final uid = (authUid != null && authUid.isNotEmpty) ? authUid : widget.user.id;

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

        // Sync top-level doc
        await firestore.collection('users').doc(uid).set({
          'id': uid,
          'binancePayId': binancePay,
          'cryptoUsdtTrc20': trc20,
          'cryptoUsdtBep20': bep20,
          'bkashNumber': bkash,
          'nagadNumber': nagad,
        }, SetOptions(merge: true));

        remoteSaved = true;
      } catch (e) {
        debugPrint('[PaymentSettings] Firestore save error: $e');
      }
    }

    // 3. Handle outcome: update local cache and dismiss ONLY on verified remote success
    if (remoteSaved) {
      try {
        await SharedPref.instance.setString(_prefKey(uid, 'binancePayId'), binancePay);
        await SharedPref.instance.setString(_prefKey(uid, 'cryptoUsdtTrc20'), trc20);
        await SharedPref.instance.setString(_prefKey(uid, 'cryptoUsdtBep20'), bep20);
        await SharedPref.instance.setString(_prefKey(uid, 'bkashNumber'), bkash);
        await SharedPref.instance.setString(_prefKey(uid, 'nagadNumber'), nagad);
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
          content: 'Failed to save payment accounts to server. Please check your internet connection.',
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
        title: const Text('Payment Receiving Accounts'),
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
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
                                const Text(
                                  'P2P Payment Settings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Configure the accounts where other users can transfer money and cryptocurrency to you in chats. Ensure your TRC-20 and BEP-20 addresses are accurate.',
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
                    const SizedBox(height: 24),

                    // Section 1: Crypto & Binance Pay
                    Text(
                      'Cryptocurrency & Binance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Binance Pay ID
                    TextFormField(
                      controller: _binancePayController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Binance Pay ID / Binance Email',
                        hintText: 'e.g. 849201842 or user@email.com',
                        prefixIcon: const Icon(Icons.currency_bitcoin_rounded,
                            color: Colors.amber),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        helperText: 'Optional • Used for 0-fee Binance transfers',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // USDT TRC-20 Address
                    TextFormField(
                      controller: _trc20Controller,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'USDT TRC-20 Address (Tron Network)',
                        hintText: 'Starts with T (34 characters)',
                        prefixIcon: const Icon(Icons.account_balance_wallet,
                            color: Colors.redAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        final val = (value ?? '').trim();
                        if (val.isEmpty) return null;
                        if (!RegExp(r'^T[a-zA-HJ-NP-Z0-9]{33}$').hasMatch(val)) {
                          return 'Invalid TRC-20 address format (must start with T and be 34 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // USDT BEP-20 Address
                    TextFormField(
                      controller: _bep20Controller,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'USDT BEP-20 Address (BNB Smart Chain)',
                        hintText: 'Starts with 0x (42 characters)',
                        prefixIcon: const Icon(Icons.toll_rounded,
                            color: Colors.amber),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        final val = (value ?? '').trim();
                        if (val.isEmpty) return null;
                        if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(val)) {
                          return 'Invalid BEP-20 address format (must start with 0x and be 42 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Section 2: Mobile Financial Services (bKash / Nagad)
                    Text(
                      'Mobile Financial Services (MFS)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // bKash Number
                    TextFormField(
                      controller: _bkashController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'bKash Personal Number',
                        hintText: 'e.g. 017XXXXXXXX',
                        prefixIcon: const Icon(Icons.phone_android_rounded,
                            color: Colors.pinkAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nagad Number
                    TextFormField(
                      controller: _nagadController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nagad Personal Number',
                        hintText: 'e.g. 018XXXXXXXX',
                        prefixIcon: const Icon(Icons.phone_android_rounded,
                            color: Colors.deepOrangeAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSaving ? null : _saveSettings,
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Payment Accounts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
