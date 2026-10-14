import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/calls/views/outgoing_call_screen.dart';
import 'package:whatsapp_clone/features/chat/views/chat.dart';
import 'package:whatsapp_clone/shared/models/user.dart';
import 'package:whatsapp_clone/shared/repositories/firebase_firestore.dart';
import 'package:whatsapp_clone/shared/utils/snackbars.dart';

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

    final targetUser = _foundUser ??
        User(
          id: 'phone_${phone.replaceAll(RegExp(r"[^\d+]"), "")}',
          name: phone,
          avatarUrl: '',
          phone: Phone(
            code: phone.startsWith('+') ? '' : '+880',
            number: phone,
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
          isSimulatedDemo: false,
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

    final targetUser = _foundUser ??
        User(
          id: 'phone_${phone.replaceAll(RegExp(r"[^\d+]"), "")}',
          name: phone,
          avatarUrl: '',
          phone: Phone(
            code: phone.startsWith('+') ? '' : '+880',
            number: phone,
            formattedNumber: phone,
          ),
          activityStatus: UserActivityStatus.online,
        );

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
    final bgColor = isDark ? const Color(0xFF1F2C34) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = const Color(0xFF00A884);

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
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF00A884)),
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
                fillColor: isDark ? const Color(0xFF121B22) : const Color(0xFFF0F2F5),
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
                              Text(
                                _foundUser!.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF00E5B0),
                                size: 16,
                              ),
                            ],
                          ),
                          Text(
                            'Registered Livocal User (${_foundUser!.phone.getFormattedNumber()})',
                            style: const TextStyle(
                              color: Color(0xFF00A884),
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
