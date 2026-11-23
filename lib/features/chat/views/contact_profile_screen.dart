import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:livocal/features/calls/views/widgets/different_language_call_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/features/chat/views/chat_media_viewer_screen.dart';
import 'package:livocal/features/chat/views/custom_notifications_screen.dart';
import 'package:livocal/features/settings/services/block_service.dart';
import 'package:livocal/shared/models/messages.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/ui/livocal_avatar.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/services/mute_service.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/text_theme.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:share_plus/share_plus.dart';
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
  ConsumerState<ContactProfileScreen> createState() =>
      _ContactProfileScreenState();
}

class _ContactProfileScreenState extends ConsumerState<ContactProfileScreen> {
  bool _isMuted = false;
  bool _isBlocked = false;
  String _disappearingTimer = 'Off';
  int _mediaCount = 0;

  @override
  void initState() {
    super.initState();
    _isMuted = MuteService.isContactMuted(widget.other.id);
    _isBlocked = BlockService.isBlocked(widget.other.id);
    final chatId = getChatId(widget.self.id, widget.other.id);
    _disappearingTimer =
        SharedPref.instance.getString('chat_disappearing_$chatId') ??
            SharedPref.instance
                .getString('contact_disappearing_${widget.other.id}') ??
            'Off';
    _loadMediaStats();
    _loadSharedDisappearingSettings(chatId);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('muted_contacts')
          .doc(widget.other.id)
          .get()
          .then((doc) {
        if (doc.exists && mounted) {
          final serverMuted = doc.data()?['muted'] == true;
          final untilMs = (doc.data()?['untilMs'] as num?)?.toInt() ?? 0;
          if (serverMuted &&
              (untilMs == 0 ||
                  DateTime.now().millisecondsSinceEpoch < untilMs)) {
            if (!_isMuted) setState(() => _isMuted = true);
            SharedPref.instance
                .setBool('contact_muted_${widget.other.id}', true);
            SharedPref.instance
                .setInt('contact_muted_until_${widget.other.id}', untilMs);
          } else if (_isMuted) {
            MuteService.unmuteContact(widget.other.id);
            setState(() => _isMuted = false);
          }
        }
      }).catchError((_) {});
    }
  }

  Future<void> _loadSharedDisappearingSettings(String chatId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chat_settings')
          .doc(chatId)
          .get();
      if (doc.exists && doc.data() != null) {
        final val = doc.data()!['disappearingDuration'] as String?;
        if (val != null && val.isNotEmpty && mounted) {
          setState(() => _disappearingTimer = val);
          await SharedPref.instance.setString('chat_disappearing_$chatId', val);
          await SharedPref.instance
              .setString('contact_disappearing_${widget.other.id}', val);
        }
      }
    } catch (_) {}
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
    final cardBg = isDark ? const Color(0xFF16203A) : Colors.white;
    final scaffoldBg =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 268.0,
            pinned: true,
            scrolledUnderElevation: 0,
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            foregroundColor:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.share,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                tooltip: AppStrings.tr(ref, 'shareContact'),
                onPressed: _shareContact,
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
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
                    case 'encryption_info':
                      _showEncryptionDialog(context);
                      break;
                    case 'block':
                      _toggleBlockStatus();
                      break;
                    case 'report':
                      _showReportConfirmation(context);
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined,
                            size: 20, color: Color(0xFF8A96B2)),
                        const SizedBox(width: 12),
                        Text(AppStrings.tr(ref, 'shareContact')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined,
                            size: 20, color: Color(0xFF8A96B2)),
                        const SizedBox(width: 12),
                        Text(AppStrings.tr(ref, 'editContact')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_in_address_book',
                    child: Row(
                      children: [
                        const Icon(Icons.contacts_outlined,
                            size: 20, color: Color(0xFF8A96B2)),
                        const SizedBox(width: 12),
                        Text(AppStrings.tr(ref, 'viewInAddressBook')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'encryption_info',
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 20, color: Color(0xFF8A96B2)),
                        const SizedBox(width: 12),
                        Text(AppStrings.tr(ref, 'transportSecurity')),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(
                          _isBlocked
                              ? Icons.check_circle_outline
                              : Icons.block_flipped,
                          size: 20,
                          color:
                              _isBlocked ? AppColors.primary : Colors.redAccent,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isBlocked ? 'Unblock contact' : 'Block contact',
                          style: TextStyle(
                            color: _isBlocked
                                ? AppColors.primary
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.thumb_down_outlined,
                            size: 20, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.tr(ref, 'reportContact'),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF1E2A47),
                            AppColors.darkSurface,
                            AppColors.darkBackground,
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.16),
                            AppColors.accent.withValues(alpha: 0.10),
                            Colors.white,
                          ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 40, 22, 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LivocalAvatar(
                          name: widget.contactName,
                          imageUrl: widget.other.avatarUrl,
                          size: 92,
                          ring: AvatarRing.brand,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.contactName,
                          style: TextStyle(
                            fontFamily: CustomTextTheme.display,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.other.phone.getFormattedNumber(),
                          style: TextStyle(
                            fontSize: 14.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    onTap: () async {
                      if (_isBlocked) {
                        final unblock = await showAppDialog<bool>(
                          context: context,
                          title: 'Unblock to call',
                          icon: Icons.block_flipped,
                          iconColor: Colors.redAccent,
                          contentText:
                              'Unblock ${widget.contactName} to place an audio call.',
                          actions: [
                            AppDialogAction(
                              label: 'CANCEL',
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            AppDialogAction(
                              label: 'UNBLOCK',
                              isPrimary: true,
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        );
                        if (unblock == true && mounted) {
                          try {
                            await BlockService.unblockContact(widget.other.id);
                            setState(() => _isBlocked = false);
                            if (mounted) {
                              showSnackBar(
                                context: context,
                                content:
                                    '${widget.contactName} has been unblocked',
                                type: SnacBarType.info,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showSnackBar(
                                context: context,
                                content:
                                    'Failed to unblock. Please check connection.',
                                type: SnacBarType.error,
                              );
                            }
                          }
                        }
                        return;
                      }
                      initiateSmartCall(
                        context,
                        ref,
                        caller: widget.self,
                        callee: widget.other,
                        calleeDisplayName: widget.contactName,
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
                    AppStrings.tr(ref, 'aboutAndPhoneNumber'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF8A96B2)
                          : const Color(0xFF5B6785),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.tr(ref, 'defaultAbout'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.tr(
                      ref,
                      'onlineStatus',
                      args: {'status': widget.other.activityStatus.value},
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.other.activityStatus ==
                              UserActivityStatus.online
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
                            icon: const Icon(Icons.message,
                                color: AppColors.primary),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    self: widget.self,
                                    other: widget.other,
                                    otherUserContactName: widget.contactName,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.call,
                                color: AppColors.primary),
                            onPressed: () async {
                              await initiateSmartCall(
                                context,
                                ref,
                                caller: widget.self,
                                callee: widget.other,
                                calleeDisplayName: widget.contactName,
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
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF8A96B2)),
                title: Text(AppStrings.tr(ref, 'mediaLinksDocs')),
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
                    secondary: const Icon(Icons.notifications_outlined,
                        color: Color(0xFF8A96B2)),
                    title: Text(AppStrings.tr(ref, 'muteNotifications')),
                    subtitle: Text(AppStrings.tr(ref, 'muteDesc')),
                    value: _isMuted,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isMuted = val;
                      });
                      if (val) {
                        MuteService.muteContact(
                          contactId: widget.other.id,
                          duration: 'Always',
                        );
                      } else {
                        MuteService.unmuteContact(widget.other.id);
                      }
                      showSnackBar(
                        context: context,
                        content: val
                            ? 'Notifications muted for ${widget.contactName}'
                            : 'Notifications unmuted for ${widget.contactName}',
                        type: SnacBarType.info,
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.music_note_outlined,
                        color: Color(0xFF8A96B2)),
                    title: Text(AppStrings.tr(ref, 'customNotifications')),
                    subtitle: Text(
                      (SharedPref.instance.getBool(
                                  'custom_notif_enabled_${widget.other.id}') ??
                              false)
                          ? 'Enabled'
                          : 'Default system tone and vibration',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (_) => CustomNotificationsScreen(
                            contact: widget.other,
                            contactName: widget.contactName,
                          ),
                        ),
                      )
                          .then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined,
                        color: Color(0xFF8A96B2)),
                    title: Text(AppStrings.tr(ref, 'encryptionAndSecurity')),
                    subtitle: Text(
                      AppStrings.tr(ref, 'encryptionDesc'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.info_outline,
                        color: Color(0xFF8A96B2), size: 20),
                    onTap: () => _showEncryptionDialog(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined,
                        color: Color(0xFF8A96B2)),
                    title: const Text('Disappearing messages'),
                    subtitle: Text(_disappearingTimer,
                        style: const TextStyle(fontSize: 12)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _showDisappearingMessagesDialog,
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
                    leading: Icon(
                      _isBlocked ? Icons.check_circle_outline : Icons.block,
                      color: _isBlocked ? AppColors.primary : Colors.redAccent,
                    ),
                    title: Text(
                      _isBlocked
                          ? 'Unblock ${widget.contactName}'
                          : 'Block ${widget.contactName}',
                      style: TextStyle(
                        color:
                            _isBlocked ? AppColors.primary : Colors.redAccent,
                      ),
                    ),
                    onTap: _toggleBlockStatus,
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.thumb_down_outlined,
                        color: Colors.redAccent),
                    title: Text(
                      AppStrings.tr(
                        ref,
                        'reportContactName',
                        args: {'name': widget.contactName},
                      ),
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
          ? const Color(0xFF16203A)
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
              const Icon(Icons.translate_rounded,
                  color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                AppStrings.tr(ref, 'geminiAiLiveTranslation'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.phone_in_talk),
                label: Text(
                  AppStrings.tr(ref, 'startTranslatedVoiceCall'),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await initiateSmartCall(
                    context,
                    ref,
                    caller: widget.self,
                    callee: widget.other,
                    calleeDisplayName: widget.contactName,
                    forceTranslation: true,
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
      final hasPermission =
          await fc.FlutterContacts.requestPermission(readonly: true);
      fc.Contact? matched;

      if (hasPermission) {
        final digitsOnly = widget.other.phone
            .getFormattedNumber()
            .replaceAll(RegExp(r'\D'), '');
        final contacts =
            await fc.FlutterContacts.getContacts(withProperties: true);

        for (final c in contacts) {
          for (final p in c.phones) {
            final pClean = p.number.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.isNotEmpty &&
                (pClean.contains(digitsOnly) || digitsOnly.contains(pClean))) {
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
      final hasPermission =
          await fc.FlutterContacts.requestPermission(readonly: true);
      fc.Contact? matched;

      if (hasPermission) {
        final digitsOnly = widget.other.phone
            .getFormattedNumber()
            .replaceAll(RegExp(r'\D'), '');
        final contacts =
            await fc.FlutterContacts.getContacts(withProperties: true);

        for (final c in contacts) {
          for (final p in c.phones) {
            final pClean = p.number.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.isNotEmpty &&
                (pClean.contains(digitsOnly) || digitsOnly.contains(pClean))) {
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

  void _showEncryptionDialog(BuildContext context) {
    showAppDialog(
      context: context,
      icon: Icons.shield_rounded,
      iconColor: AppColors.primary,
      title: 'Transport Encryption & Privacy',
      contentText:
          'Messages and calls with ${widget.contactName} are protected in transit using authenticated TLS 1.3 and WebRTC DTLS-SRTP encryption.\n\nVoice translations are securely processed in ephemeral server memory via Gemini Multimodal Live API without persistent disk logging.',
      actions: [
        AppDialogAction(
          label: 'OK',
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showDisappearingMessagesDialog() {
    final options = ['Off', '24 hours', '7 days', '90 days'];
    showAppDialog(
      context: context,
      title: 'Disappearing messages',
      content: RadioGroup<String>(
        groupValue: _disappearingTimer,
        onChanged: (val) {
          if (val != null) {
            setState(() => _disappearingTimer = val);
            final chatId = getChatId(widget.self.id, widget.other.id);
            SharedPref.instance
                .setString('contact_disappearing_${widget.other.id}', val);
            SharedPref.instance.setString('chat_disappearing_$chatId', val);
            FirebaseFirestore.instance
                .collection('chat_settings')
                .doc(chatId)
                .set({
              'chatId': chatId,
              'participants': [widget.self.id, widget.other.id],
              'disappearingDuration': val,
              'updatedBy': widget.self.id,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            Navigator.pop(context);
            showSnackBar(
              context: context,
              content: 'Disappearing messages set to $val',
              type: SnacBarType.info,
            );
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (opt) => RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        AppDialogAction(
          label: 'CANCEL',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _toggleBlockStatus() async {
    if (_isBlocked) {
      final confirmed = await showAppDialog<bool>(
        context: context,
        title: 'Unblock ${widget.contactName}?',
        contentText:
            'Unblocked contacts will be able to call you and send you messages.',
        icon: Icons.lock_open_rounded,
        iconColor: AppColors.primary,
        actions: [
          AppDialogAction(
            label: 'CANCEL',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            label: 'UNBLOCK',
            isPrimary: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );

      if (confirmed == true && mounted) {
        try {
          await BlockService.unblockContact(widget.other.id);
          setState(() => _isBlocked = false);
          if (mounted) {
            showSnackBar(
              context: context,
              content: '${widget.contactName} has been unblocked',
              type: SnacBarType.info,
            );
          }
        } catch (e) {
          if (mounted) {
            showSnackBar(
              context: context,
              content:
                  'Failed to unblock ${widget.contactName}. Please check connection.',
              type: SnacBarType.error,
            );
          }
        }
      }
    } else {
      final confirmed = await showAppDialog<bool>(
        context: context,
        title: 'Block ${widget.contactName}?',
        contentText:
            'Blocked contacts will no longer be able to call you or send you messages.',
        icon: Icons.block_flipped,
        iconColor: Colors.redAccent,
        actions: [
          AppDialogAction(
            label: 'CANCEL',
            onPressed: () => Navigator.pop(context, false),
          ),
          AppDialogAction(
            label: 'BLOCK',
            isDestructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );

      if (confirmed == true && mounted) {
        try {
          await BlockService.blockContact(
            contactId: widget.other.id,
            contactName: widget.contactName,
            phone: widget.other.phone.getFormattedNumber(),
            avatarUrl: widget.other.avatarUrl,
          );
          setState(() => _isBlocked = true);
          if (mounted) {
            showSnackBar(
              context: context,
              content: '${widget.contactName} has been blocked',
              type: SnacBarType.info,
            );
          }
        } catch (e) {
          if (mounted) {
            showSnackBar(
              context: context,
              content:
                  'Failed to block ${widget.contactName}. Please check connection.',
              type: SnacBarType.error,
            );
          }
        }
      }
    }
  }

  void _showReportConfirmation(BuildContext context) {
    bool alsoBlock = true;
    String selectedReason = 'Spam';
    const reportReasons = [
      'Spam',
      'Harassment or abuse',
      'Fraud or scam',
      'Inappropriate content',
      'Other',
    ];

    showAppDialog(
      context: context,
      title: 'Report ${widget.contactName}?',
      icon: Icons.report_problem_outlined,
      iconColor: Colors.redAccent,
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'reportForwardWarning'),
                style: const TextStyle(fontSize: 13.5),
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.tr(ref, 'reasonForReport'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedReason,
                    isExpanded: true,
                    items: reportReasons.map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(r, style: const TextStyle(fontSize: 13.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedReason = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: alsoBlock,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: Text(
                  AppStrings.tr(ref, 'blockContactClearMessages'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setDialogState(() {
                    alsoBlock = val ?? false;
                  });
                },
              ),
            ],
          );
        },
      ),
      actions: [
        AppDialogAction(
          label: 'CANCEL',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'REPORT',
          isDestructive: true,
          onPressed: () async {
            Navigator.pop(context);

            try {
              final chatId = getChatId(widget.self.id, widget.other.id);
              final recent = await IsarDb.isar.storedMessages
                  .filter()
                  .chatIdEqualTo(chatId)
                  .sortByTimestampDesc()
                  .limit(5)
                  .findAll();

              final messageList = recent
                  .map((m) => {
                        'messageId': m.messageId,
                        'senderId': m.senderId,
                        'content': m.content,
                        'timestamp': m.timestamp.toIso8601String(),
                      })
                  .toList();

              await FirebaseFirestore.instance.collection('reports').add({
                'reportedUserId': widget.other.id,
                'reportedUserName': widget.contactName,
                'reportedUserPhone': widget.other.phone.getFormattedNumber(),
                'reporterId': widget.self.id,
                'reporterPhone': widget.self.phone.getFormattedNumber(),
                'reason': selectedReason,
                'recentMessages': messageList,
                'timestamp': FieldValue.serverTimestamp(),
                'alsoBlocked': alsoBlock,
                'status': 'pending_review',
              });

              if (alsoBlock) {
                await BlockService.blockContact(
                  contactId: widget.other.id,
                  contactName: widget.contactName,
                  phone: widget.other.phone.getFormattedNumber(),
                  avatarUrl: widget.other.avatarUrl,
                );
                await IsarDb.deleteChat(chatId);
                if (mounted) {
                  setState(() => _isBlocked = true);
                }
              }

              if (mounted) {
                showSnackBar(
                  context: context,
                  content: alsoBlock
                      ? 'Report submitted and ${widget.contactName} blocked.'
                      : 'Report submitted. Thank you for your feedback.',
                  type: SnacBarType.info,
                );
              }
            } catch (e) {
              debugPrint('[ContactProfileScreen] Report error: $e');
              if (mounted) {
                showSnackBar(
                  context: context,
                  content:
                      'Failed to submit report. Please check your network and try again.',
                  type: SnacBarType.error,
                );
              }
            }
          },
        ),
      ],
    );
  }
}
