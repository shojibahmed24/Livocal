import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/views/outgoing_call_screen.dart';
import 'package:livocal/features/calls/views/widgets/minute_recharge_sheet.dart';
import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/models/user_wallet.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/theme/app_colors.dart';

Future<void> showDirectDialSheet(
  BuildContext context, {
  required User currentUser,
  String? initialPhone,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DirectDialSheet(
      currentUser: currentUser,
      initialPhone: initialPhone,
    ),
  );
}

class DirectDialSheet extends ConsumerStatefulWidget {
  final User currentUser;
  final String? initialPhone;

  const DirectDialSheet({
    super.key,
    required this.currentUser,
    this.initialPhone,
  });

  @override
  ConsumerState<DirectDialSheet> createState() => _DirectDialSheetState();
}

class _DirectDialSheetState extends ConsumerState<DirectDialSheet> {
  late final TextEditingController _phoneController;
  Timer? _debounceTimer;
  bool _isSearching = false;
  User? _foundUser;
  bool _searchPerformed = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    if (_phoneController.text.isNotEmpty) {
      _checkUser(_phoneController.text);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String val) {
    _debounceTimer?.cancel();
    if (val.trim().length >= 8) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _checkUser(val);
      });
    } else {
      setState(() {
        _foundUser = null;
        _searchPerformed = false;
        _isSearching = false;
      });
    }
  }

  Future<void> _checkUser(String rawPhone) async {
    final clean = rawPhone.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    final firestore = ref.read(firebaseFirestoreRepositoryProvider);
    final user = await firestore.getUserByPhone(clean);

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _searchPerformed = true;
      _foundUser = user;
    });
  }

  void _startCall({required bool withAiTranslation}) {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showSnackBar(
        context: context,
        content: 'Please enter a valid phone number',
        type: SnacBarType.error,
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r"[^\d+]"), "");
    final String phoneCode = cleanPhone.startsWith('+') ? '' : '+880';
    final String phoneNumber = cleanPhone.startsWith('+')
        ? cleanPhone
        : (cleanPhone.startsWith('0') ? cleanPhone.substring(1) : cleanPhone);

    final targetUser = _foundUser ??
        User(
          id: 'phone_$cleanPhone',
          name: phone,
          avatarUrl: '',
          phone: Phone(
            code: phoneCode,
            number: phoneNumber,
            formattedNumber: phone,
          ),
          activityStatus: UserActivityStatus.online,
        );

    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          caller: widget.currentUser,
          callee: targetUser,
          calleeDisplayName: _foundUser != null ? _foundUser!.name : phone,
        ),
      ),
    );
  }

  void _startChat() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showSnackBar(
        context: context,
        content: 'Please enter a valid phone number',
        type: SnacBarType.error,
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r"[^\d+]"), "");
    final String phoneCode = cleanPhone.startsWith('+') ? '' : '+880';
    final String phoneNumber = cleanPhone.startsWith('+')
        ? cleanPhone
        : (cleanPhone.startsWith('0') ? cleanPhone.substring(1) : cleanPhone);

    final targetUser = _foundUser ??
        User(
          id: 'phone_$cleanPhone',
          name: phone,
          avatarUrl: '',
          phone: Phone(
            code: phoneCode,
            number: phoneNumber,
            formattedNumber: phone,
          ),
          activityStatus: UserActivityStatus.online,
        );

    IsarDb.saveUser(targetUser);

    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          self: widget.currentUser,
          other: targetUser,
          otherUserContactName: _foundUser != null ? _foundUser!.name : phone,
        ),
        settings: const RouteSettings(name: 'chat'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final primaryColor = AppColors.primary;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.dialpad_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Call / Chat by Number',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'যেকোনো ফোন নম্বর লিখে সরাসরি কল বা চ্যাট করুন',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Phone input field
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              onChanged: _onPhoneChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                hintText: 'e.g. 01721-013902 or +8801303456776',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 14,
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_phoneController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _phoneController.clear();
                              setState(() {
                                _foundUser = null;
                                _searchPerformed = false;
                              });
                            },
                          )
                        : null),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightSurfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Found user status card
            if (_searchPerformed && _foundUser != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryColor.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.black26,
                      backgroundImage: _foundUser!.avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(_foundUser!.avatarUrl)
                          : const AssetImage('assets/images/avatar.png') as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _foundUser!.name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ],
                          ),
                          Text(
                            'Registered Livocal User (${_foundUser!.phone.getFormattedNumber()})',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_searchPerformed && _foundUser == null && _phoneController.text.trim().length >= 8) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Direct call will ring on this phone if Livocal is installed.',
                        style: TextStyle(
                          color: isDark ? Colors.amber[200] : Colors.amber[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Live SaaS Billing Call Indicator & Balance Chip
            Consumer(
              builder: (context, ref, _) {
                final callState = ref.watch(callControllerProvider);
                final walletAsync = ref.watch(walletStreamProvider(widget.currentUser.id));
                final wallet = walletAsync.value ?? UserWallet.newTrial();
                final isSameLang = callState.myLanguage.code == callState.peerLanguage.code;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSameLang
                        ? AppColors.primary.withOpacity(0.1)
                        : (wallet.hasMinutes ? const Color(0xFF06B6D4).withOpacity(0.1) : Colors.amber.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSameLang
                          ? AppColors.primary.withOpacity(0.3)
                          : (wallet.hasMinutes ? const Color(0xFF06B6D4).withOpacity(0.3) : Colors.amber.withOpacity(0.4)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSameLang ? Icons.record_voice_over_rounded : Icons.translate_rounded,
                        color: isSameLang
                            ? AppColors.primary
                            : (wallet.hasMinutes ? const Color(0xFF06B6D4) : Colors.amber),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSameLang
                              ? '🗣️ ফ্রি লোকাল কল (Same Language - কোনো মিনিট কাটবে না)'
                              : '🤖 AI অনুবাদ কল (১ মি./মি.) • ব্যালেন্স: ${wallet.effectiveRemainingMinutes} মি.',
                          style: TextStyle(
                            color: isSameLang
                                ? (isDark ? Colors.green[200] : Colors.green[800])
                                : (wallet.hasMinutes
                                    ? (isDark ? Colors.cyan[200] : Colors.cyan[900])
                                    : (isDark ? Colors.amber[200] : Colors.amber[900])),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isSameLang && !wallet.hasMinutes)
                        InkWell(
                          onTap: () => showMinuteRechargeSheet(context, user: widget.currentUser),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'রিচার্জ',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.call_rounded, size: 20),
                    label: const Text(
                      'Voice Call (AI)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _startCall(withAiTranslation: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 20),
                    label: const Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _startChat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
