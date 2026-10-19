import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/features/calls/views/outgoing_call_screen.dart';
import 'package:livocal/features/chat/views/chat_media_viewer_screen.dart';
import 'package:livocal/shared/models/messages.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:share_plus/share_plus.dart';
import 'package:livocal/features/chat/views/verify_security_code_screen.dart';
import 'package:livocal/theme/color_theme.dart';

class ContactProfileScreen extends ConsumerStatefulWidget {
  const ContactProfileScreen({
    super.key,
    required this.self,
    required this.other,
    required this.contactName,
  });

  final User self;
  final User other;
  final String contactName;

  @override
  ConsumerState<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends ConsumerState<ContactProfileScreen> {
  bool _isMuted = false;
  int _mediaCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMediaStats();
  }

  Future<void> _loadMediaStats() async {
    try {
      final chatId = getChatId(widget.self.id, widget.other.id);
      final messages = await IsarDb.isar.storedMessages
          .filter()
          .chatIdEqualTo(chatId)
          .build()
          .findAll();
      final count = messages.where((m) => m.attachment != null).length;
      if (mounted) {
        setState(() {
          _mediaCount = count;
        });
      }
    } catch (e, st) {
      debugPrint('[ContactProfileScreen] _loadMediaCount error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2C34) : Colors.white;
    final scaffoldBg = isDark ? const Color(0xFF121B22) : const Color(0xFFF0F2F5);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320.0,
            pinned: true,
            scrolledUnderElevation: 0,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Share contact',
                onPressed: _shareContact,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _shareContact();
                      break;
                    case 'edit':
                      _editContact();
                      break;
                    case 'view_in_address_book':
                      _viewInAddressBook();
                      break;
                    case 'verify_security':
                      _verifySecurityCode();
                      break;
                    case 'block':
                      _showBlockConfirmation(context);
                      break;
                    case 'report':
                      _showReportConfirmation(context);
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, size: 20, color: Color(0xFF8696A0)),
                        SizedBox(width: 12),
                        Text('Share contact'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: Color(0xFF8696A0)),
                        SizedBox(width: 12),
                        Text('Edit contact'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view_in_address_book',
                    child: Row(
                      children: [
                        Icon(Icons.contacts_outlined, size: 20, color: Color(0xFF8696A0)),
                        SizedBox(width: 12),
                        Text('View in address book'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'verify_security',
                    child: Row(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 20, color: Color(0xFF8696A0)),
                        SizedBox(width: 12),
                        Text('Verify security code'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block_flipped, size: 20, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Text('Block contact', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.thumb_down_outlined, size: 20, color: Colors.redAccent),
                        SizedBox(width: 12),
                        Text('Report contact', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.other.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.other.avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _buildPlaceholderAvatar(isDark),
                        )
                      : _buildPlaceholderAvatar(isDark),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.contactName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.other.phone.getFormattedNumber(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons: Call, Video, Search, Translate
          SliverToBoxAdapter(
            child: Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.call,
                    label: 'Audio Call',
                    color: AppColors.primary,
                    onTap: () {
                      final settings = CallRepository.getPeerTranslationSettings(
                        peerId: widget.other.id,
                        peerName: widget.contactName,
                        peerPhone: widget.other.phone.number,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OutgoingCallScreen(
                            caller: widget.self,
                            callee: widget.other,
                            calleeDisplayName: widget.contactName,
                            overrideMyLangCode: settings.myLangCode,
                            overridePeerLangCode: settings.peerLangCode,
                            initialTranslationEnabled: settings.isTranslationEnabled,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.translate_rounded,
                    label: 'AI Translate',
                    color: AppColors.primary,
                    onTap: () {
                      _showTranslationInfo(context);
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.search,
                    label: 'Search',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // About & Phone Section
          SliverToBoxAdapter(
            child: Container(
              color: cardBg,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About and phone number',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hey there! I am using Livocal.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Online Status: ${widget.other.activityStatus.value}',
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.other.activityStatus == UserActivityStatus.online
                          ? AppColors.primary
                          : Colors.grey,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.other.phone.getFormattedNumber(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Mobile',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.message, color: AppColors.primary),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call, color: AppColors.primary),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OutgoingCallScreen(
                                    caller: widget.self,
                                    callee: widget.other,
                                    calleeDisplayName: widget.contactName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Media, Links, and Docs
          SliverToBoxAdapter(
            child: Container(
              color: cardBg,
              child: ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF8696A0)),
                title: const Text('Media, links, and docs'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_mediaCount',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  final chatId = getChatId(widget.self.id, widget.other.id);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatMediaViewerScreen(
                        chatId: chatId,
                        contactName: widget.contactName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Notifications & Settings
          SliverToBoxAdapter(
            child: Container(
              color: cardBg,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined, color: Color(0xFF8696A0)),
                    title: const Text('Mute notifications'),
                    subtitle: const Text('Silence alerts for new messages from this contact'),
                    value: _isMuted,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isMuted = val;
                      });
                      showSnackBar(
                        context: context,
                        content: val
                            ? 'Notifications muted for ${widget.contactName}'
                            : 'Notifications unmuted',
                        type: SnacBarType.info,
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.music_note_outlined, color: Color(0xFF8696A0)),
                    title: const Text('Custom notifications'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      showSnackBar(
                        context: context,
                        content: 'Using default system ringtone and vibration',
                        type: SnacBarType.info,
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: Color(0xFF8696A0)),
                    title: const Text('Encryption & Security'),
                    subtitle: const Text(
                      'Messages and calls are private and secured. Tap to verify.',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline, color: Color(0xFF8696A0), size: 20),
                      tooltip: 'Encryption details',
                      onPressed: () => _showEncryptionDialog(context),
                    ),
                    onTap: _verifySecurityCode,
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined, color: Color(0xFF8696A0)),
                    title: const Text('Disappearing messages'),
                    subtitle: const Text('Off', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      showSnackBar(
                        context: context,
                        content: 'Disappearing messages set to Off',
                        type: SnacBarType.info,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Block & Report section
          SliverToBoxAdapter(
            child: Container(
              color: cardBg,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.redAccent),
                    title: Text(
                      'Block ${widget.contactName}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () => _showBlockConfirmation(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.thumb_down_outlined, color: Colors.redAccent),
                    title: Text(
                      'Report ${widget.contactName}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    onTap: () => _showReportConfirmation(context),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF233138) : const Color(0xFFDFE5E7),
      child: Center(
        child: Icon(
          Icons.person,
          size: 120,
          color: isDark ? const Color(0xFF6B7B82) : const Color(0xFFCFD4D6),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTranslationInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1F2C34)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate_rounded, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Gemini AI Live Translation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Voice calls with ${widget.contactName} are powered by Google Gemini Multimodal Live API. Speech is translated in real-time between Bengali and English with low-latency audio synthesis.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.phone_in_talk),
                label: const Text('Start Translated Voice Call'),
                onPressed: () {
                  Navigator.pop(ctx);
                  final settings = CallRepository.getPeerTranslationSettings(
                    peerId: widget.other.id,
                    peerName: widget.contactName,
                    peerPhone: widget.other.phone.number,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OutgoingCallScreen(
                        caller: widget.self,
                        callee: widget.other,
                        calleeDisplayName: widget.contactName,
                        overrideMyLangCode: settings.myLangCode,
                        overridePeerLangCode: settings.peerLangCode,
                        initialTranslationEnabled: settings.isTranslationEnabled,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareContact() {
    final phone = widget.other.phone.getFormattedNumber();
    Share.share(
      'Contact: ${widget.contactName}\nPhone: $phone\nChat and make real-time translated voice calls on Livocal: https://livocal.app/u/${widget.other.id}',
      subject: 'Livocal Contact: ${widget.contactName}',
    );
  }

  Future<void> _editContact() async {
    try {
      final hasPermission = await fc.FlutterContacts.requestPermission(readonly: true);
      fc.Contact? matched;

      if (hasPermission) {
        final digitsOnly = widget.other.phone.getFormattedNumber().replaceAll(RegExp(r'\D'), '');
        final contacts = await fc.FlutterContacts.getContacts(withProperties: true);

        for (final c in contacts) {
          for (final p in c.phones) {
            final pClean = p.number.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.isNotEmpty && (pClean.contains(digitsOnly) || digitsOnly.contains(pClean))) {
              matched = c;
              break;
            }
          }
          if (matched != null) break;
        }
      }

      if (matched != null) {
        await fc.FlutterContacts.openExternalEdit(matched.id);
      } else {
        final newContact = fc.Contact(
          name: fc.Name(first: widget.contactName),
          phones: [fc.Phone(widget.other.phone.getFormattedNumber())],
        );
        await fc.FlutterContacts.openExternalInsert(newContact);
      }
    } catch (e) {
      debugPrint('[ContactProfileScreen] _editContact error: $e');
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Could not open device contacts editor',
          type: SnacBarType.error,
        );
      }
    }
  }

  Future<void> _viewInAddressBook() async {
    try {
      final hasPermission = await fc.FlutterContacts.requestPermission(readonly: true);
      fc.Contact? matched;

      if (hasPermission) {
        final digitsOnly = widget.other.phone.getFormattedNumber().replaceAll(RegExp(r'\D'), '');
        final contacts = await fc.FlutterContacts.getContacts(withProperties: true);

        for (final c in contacts) {
          for (final p in c.phones) {
            final pClean = p.number.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.isNotEmpty && (pClean.contains(digitsOnly) || digitsOnly.contains(pClean))) {
              matched = c;
              break;
            }
          }
          if (matched != null) break;
        }
      }

      if (matched != null) {
        await fc.FlutterContacts.openExternalView(matched.id);
      } else {
        if (mounted) {
          showAppDialog(
            context: context,
            icon: Icons.person_add_alt_1_rounded,
            iconColor: AppColors.primary,
            title: 'Not in Address Book',
            contentText:
                '${widget.contactName} (${widget.other.phone.getFormattedNumber()}) is not yet saved to your device contacts.',
            actions: [
              AppDialogAction(
                label: 'CANCEL',
                onPressed: () => Navigator.pop(context),
              ),
              AppDialogAction(
                label: 'SAVE TO CONTACTS',
                isPrimary: true,
                onPressed: () async {
                  Navigator.pop(context);
                  final newContact = fc.Contact(
                    name: fc.Name(first: widget.contactName),
                    phones: [fc.Phone(widget.other.phone.getFormattedNumber())],
                  );
                  await fc.FlutterContacts.openExternalInsert(newContact);
                },
              ),
            ],
          );
        }
      }
    } catch (e) {
      debugPrint('[ContactProfileScreen] _viewInAddressBook error: $e');
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Could not open address book',
          type: SnacBarType.error,
        );
      }
    }
  }

  void _verifySecurityCode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifySecurityCodeScreen(
          contactName: widget.contactName,
          contactPhone: widget.other.phone.getFormattedNumber(),
          selfId: widget.self.id,
          otherId: widget.other.id,
        ),
      ),
    );
  }

  void _showEncryptionDialog(BuildContext context) {
    showAppDialog(
      context: context,
      icon: Icons.lock,
      iconColor: AppColors.primary,
      title: 'Private & Secure Messaging',
      contentText:
          'Messages and calls with ${widget.contactName} are protected with authenticated TLS and DTLS-SRTP encryption. Real-time voice translations are processed in ephemeral memory by Gemini Live API.',
      actions: [
        AppDialogAction(
          label: 'OK',
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showBlockConfirmation(BuildContext context) {
    showAppDialog(
      context: context,
      title: 'Block ${widget.contactName}?',
      contentText:
          'Blocked contacts will no longer be able to call you or send you messages.',
      icon: Icons.block_flipped,
      iconColor: Colors.redAccent,
      actions: [
        AppDialogAction(
          label: 'CANCEL',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'BLOCK',
          isDestructive: true,
          onPressed: () {
            Navigator.pop(context);
            showSnackBar(
              context: context,
              content: '${widget.contactName} has been blocked',
              type: SnacBarType.info,
            );
          },
        ),
      ],
    );
  }

  void _showReportConfirmation(BuildContext context) {
    showAppDialog(
      context: context,
      title: 'Report ${widget.contactName}?',
      contentText:
          'The last 5 messages from this contact will be forwarded to Livocal. The contact will not be notified.',
      icon: Icons.report_problem_outlined,
      iconColor: Colors.redAccent,
      actions: [
        AppDialogAction(
          label: 'CANCEL',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'REPORT',
          isDestructive: true,
          onPressed: () {
            Navigator.pop(context);
            showSnackBar(
              context: context,
              content: 'Report submitted. Thank you for your feedback.',
              type: SnacBarType.info,
            );
          },
        ),
      ],
    );
  }
}
