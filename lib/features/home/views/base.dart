import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/features/calls/views/calls_tab.dart';
import 'package:livocal/features/calls/views/dialer_tab.dart';
import 'package:livocal/features/calls/views/incoming_call_screen.dart';
import 'package:livocal/features/calls/services/call_kit_service.dart';
import 'package:livocal/features/calls/services/ringtone_manager.dart';
import 'package:livocal/features/chat/models/attachement.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/features/chat/models/call_log_helper.dart';
import 'package:livocal/features/chat/models/recent_chat.dart';
import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/features/chat/views/contact_profile_screen.dart';
import 'package:livocal/features/home/data/repositories/contact_repository.dart';
import 'package:livocal/shared/repositories/download_service.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/features/home/views/contacts.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/repositories/push_notifications.dart';
import 'package:livocal/shared/repositories/wallet_repository.dart';
import 'package:livocal/shared/ui/livocal_app_bar.dart';
import 'package:livocal/shared/ui/livocal_tabs.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/time_ticker.dart';
import 'package:livocal/shared/widgets/shimmer_skeleton.dart';
import 'package:livocal/theme/app_tokens.dart';
import 'package:livocal/theme/theme.dart';
import '../../../shared/utils/storage_paths.dart';
import '../../../theme/color_theme.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/features/home/views/settings_screen.dart';
import 'package:livocal/features/settings/services/block_service.dart';
import 'package:livocal/shared/services/mute_service.dart';
import 'package:camera/camera.dart';
import 'package:livocal/features/home/views/status_tab.dart';
import 'package:livocal/shared/widgets/camera.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/dialer_strings.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/features/home/views/starred_messages_screen.dart';
import 'package:livocal/features/chat/controllers/chat_controller.dart';
import 'package:livocal/features/status/views/text_status_composer_screen.dart';

class HomePage extends ConsumerStatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final StreamSubscription<List<Message>> messageListener;
  StreamSubscription<CallSession?>? _incomingCallSub;
  late TabController _tabController;
  late List<Widget> _floatingButtons;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isFirstChatStreamEmission = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(firebaseFirestoreRepositoryProvider).setActivityStatus(
            userId: widget.user.id,
            statusValue: UserActivityStatus.online.value);
        ref.read(chatControllerProvider.notifier).flushPendingOutbox();
        break;
      default:
        ref.read(firebaseFirestoreRepositoryProvider).setActivityStatus(
            userId: widget.user.id,
            statusValue: UserActivityStatus.offline.value);
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    final firestore = ref.read(firebaseFirestoreRepositoryProvider);
    firestore.setActivityStatus(
      userId: widget.user.id,
      statusValue: UserActivityStatus.online.value,
    );

    // Opportunistically flush pending offline outbox messages
    ref.read(chatControllerProvider.notifier).flushPendingOutbox();

    // Initialize or verify SaaS minute wallet & 14-day 20-min trial
    ref.read(walletRepositoryProvider).initializeOrGetWallet(
          userId: widget.user.id,
          phone: widget.user.phoneNumber,
        );

    messageListener = firestore.getChatStream(widget.user.id).listen(
      (messages) async {
        bool hasIncoming = false;
        String? lastIncomingSenderId;
        final List<Message> nonBlockedMessages = [];
        for (final message in messages) {
          // Drop all incoming messages from blocked senders
          if (message.senderId != widget.user.id &&
              BlockService.isBlocked(message.senderId)) {
            debugPrint(
                '[base.dart] Message from blocked contact ${message.senderId} dropped.');
            continue;
          }

          // Drop already-expired disappearing messages
          if (message.expiresAt != null &&
              message.expiresAt!.toDate().isBefore(DateTime.now())) {
            debugPrint(
                '[base.dart] Dropping expired disappearing message ${message.id}');
            continue;
          }

          nonBlockedMessages.add(message);

          if (message.senderId != widget.user.id) {
            hasIncoming = true;
            lastIncomingSenderId = message.senderId;
          }
          message.status = MessageStatus.delivered;
          firestore.sendSystemMessage(
            message: SystemMessage(
              targetId: message.id,
              action: MessageAction.statusUpdate,
              update: MessageStatus.delivered.value,
            ),
            receiverId: message.senderId,
          );

          if (message.attachment != null && message.attachment!.autoDownload) {
            DownloadService.download(
              taskId: message.id,
              url: message.attachment!.url,
              path: DeviceStorage.getMediaFilePath(
                message.attachment!.fileName,
              ),
              onDownloadComplete: (filePath) {
                debugPrint(
                    'Auto-download complete for message ${message.id}: $filePath');
              },
              onDownloadError: () {
                debugPrint('Auto-download failed for message ${message.id}');
              },
            );
          }
        }

        final isInitialEmission = _isFirstChatStreamEmission;
        _isFirstChatStreamEmission = false;

        // Only play message notification tone for new messages arriving after app launch
        if (hasIncoming && !isInitialEmission) {
          RingtoneManager()
              .playMessageNotificationTone(contactId: lastIncomingSenderId);
        }

        if (nonBlockedMessages.isNotEmpty) {
          IsarDb.addMessages(nonBlockedMessages);
        }
      },
      onError: (err) {
        debugPrint('Firestore chat stream error: $err');
      },
    );

    ref.read(pushNotificationsRepoProvider).init(
      onMessageOpenedApp: (message) async {
        await handleNotificationClick(message);
      },
    );

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message == null) return;

      await handleNotificationClick(message);
    });

    TimeTicker.ensureStarted();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _tabController.addListener(handleTabIndexChange);

    _floatingButtons = [
      FloatingActionButton(
        tooltip: AppStrings.get(
          'newChatTooltip',
          SharedPref.instance.getString('app_language') ?? 'en',
        ),
        onPressed: () async {
          if (!await hasPermission(Permission.contacts)) return;
          if (!mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ContactsPage(
                user: widget.user,
              ),
            ),
          );
        },
        child: const Icon(Icons.chat),
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            tooltip: AppStrings.get(
              'newStatusTooltip',
              SharedPref.instance.getString('app_language') ?? 'en',
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TextStatusComposerScreen(user: widget.user),
                ),
              );
            },
            child: const Icon(Icons.edit),
          ),
          const SizedBox(
            height: 16.0,
          ),
          FloatingActionButton(
            tooltip: 'Camera',
            onPressed: () async {
              if (!await hasPermission(Permission.camera)) return;
              if (!mounted) return;
              try {
                final cameras = await availableCameras();
                if (cameras.isNotEmpty && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CameraView(cameras: cameras),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Camera open error: $e');
              }
            },
            child: const Icon(Icons.camera_alt_rounded),
          ),
        ],
      ),
      FloatingActionButton(
        tooltip: AppStrings.get(
          'newCallTooltip',
          SharedPref.instance.getString('app_language') ?? 'en',
        ),
        onPressed: () async {
          if (!await hasPermission(Permission.contacts)) return;
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ContactsPage(
                user: widget.user,
              ),
            ),
          );
        },
        child: const Icon(Icons.add_call),
      )
    ];

    _incomingCallSub = ref
        .read(callRepositoryProvider)
        .watchIncomingCalls(
          widget.user.id,
          ownPhone: widget.user.phone.rawNumber,
        )
        .listen((incomingSession) {
      if (incomingSession == null) {
        final current = ref.read(callControllerProvider).activeSession;
        if (current != null &&
            current.status == CallStateStatus.ringing &&
            current.isIncoming) {
          CallKitService().endAllCalls();
          ref
              .read(callControllerProvider.notifier)
              .endCall(recordAsMissed: false);
        }
        return;
      }
      if (!mounted) return;
      if (BlockService.isBlocked(incomingSession.callerId)) {
        debugPrint(
            '[base.dart] Suppressing incoming call from blocked caller: ${incomingSession.callerId}');
        return;
      }

      // Complete Mute Suppression: If caller is muted by user, suppress IncomingCallScreen entirely
      final callerId = incomingSession.callerId;
      final isMuted =
          SharedPref.isInitialized && MuteService.isContactMuted(callerId);
      if (isMuted) {
        debugPrint(
            '[base.dart] Completely suppressing incoming call UI from muted caller: $callerId');
        ref.read(callControllerProvider.notifier).recordSuppressedMutedCall(
              self: widget.user,
              incomingSession: incomingSession,
            );
        return;
      }
      final currentSession = ref.read(callControllerProvider).activeSession;
      if (currentSession != null) return;
      ref.read(callControllerProvider.notifier).receiveIncomingCall(
            self: widget.user,
            callerId: incomingSession.callerId,
            callerName: incomingSession.callerName,
            callerAvatar: incomingSession.callerAvatar,
            callerPhone: incomingSession.callerPhone,
            callerLangCode: incomingSession.callerLangCode,
            callId: incomingSession.callId,
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const IncomingCallScreen(),
        ),
      );
    });

    super.initState();
  }

  @override
  void dispose() {
    _tabController.removeListener(handleTabIndexChange);
    _tabController.dispose();
    messageListener.cancel();
    _incomingCallSub?.cancel();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void handleTabIndexChange() {
    setState(() {});
  }

  Future<void> handleNotificationClick(RemoteMessage message) async {
    final authorId = message.data['authorId'] as String?;
    if (authorId == null || authorId.isEmpty) return;

    final User author = (await ref
            .read(firebaseFirestoreRepositoryProvider)
            .getUserById(authorId)) ??
        User(
          id: authorId,
          name: message.data['authorName'] as String? ?? 'Contact',
          avatarUrl: message.data['authorAvatar'] as String? ?? '',
          phone: Phone(code: '+880', number: '', formattedNumber: ''),
          activityStatus: UserActivityStatus.offline,
        );

    Contact? contact;
    if (author.phone.number != null && author.phone.number!.isNotEmpty) {
      try {
        contact = await ref
            .read(contactsRepositoryProvider)
            .getContactByPhone(author.phone.number!);
      } catch (e, st) {
        debugPrint('[Base] getContactByPhone error: $e\n$st');
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          self: widget.user,
          other: author,
          otherUserContactName: contact?.displayName ??
              (author.name.isNotEmpty
                  ? author.name
                  : author.phone.getFormattedNumber()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: livocalAppBar(
          context,
          showWordmark: !_isSearching,
          leading: _isSearching
              ? IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                )
              : null,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 17,
                  ),
                  cursorColor: colorTheme.greenColor,
                  decoration: InputDecoration(
                    hintText: AppStrings.tr(ref, 'searchChatsHint'),
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : null,
          actions: [
            if (_isSearching) ...[
              IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
              ),
            ] else ...[
              IconButton(
                tooltip: 'Camera',
                onPressed: () async {
                  if (!await hasPermission(Permission.camera)) return;
                  if (!context.mounted) return;
                  try {
                    final cameras = await availableCameras();
                    if (cameras.isNotEmpty && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CameraView(cameras: cameras),
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('AppBar Camera open error: $e');
                  }
                },
                icon: const Icon(
                  Icons.camera_alt_outlined,
                ),
              ),
              IconButton(
                tooltip: 'Search',
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
                icon: const Icon(
                  Icons.search,
                ),
              ),
            ],
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                switch (value) {
                  case 'starred_messages':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StarredMessagesScreen(),
                      ),
                    );
                    break;
                  case 'clear_call_log':
                    await ref.read(callRepositoryProvider).clearCallHistory();
                    if (context.mounted) {
                      showSnackBar(
                        context: context,
                        content: AppStrings.tr(ref, 'callLogCleared'),
                        type: SnacBarType.info,
                      );
                      setState(() {});
                    }
                    break;
                  case 'status_privacy':
                    String privacy =
                        SharedPref.instance.getString('status_privacy') ??
                            'contacts';
                    showAppDialog(
                      context: context,
                      title: AppStrings.tr(ref, 'statusPrivacy'),
                      icon: Icons.lock_outline_rounded,
                      content: StatefulBuilder(
                        builder: (ctx, setDlgState) => RadioGroup<String>(
                          groupValue: privacy,
                          onChanged: (val) {
                            if (val != null) {
                              setDlgState(() => privacy = val);
                              SharedPref.instance
                                  .setString('status_privacy', val);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.tr(ref, 'statusPrivacyWhoCanSee'),
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              SizedBox(height: 8),
                              RadioListTile<String>(
                                title: Text(AppStrings.tr(ref, 'myContacts')),
                                subtitle: Text(
                                    AppStrings.tr(ref, 'shareWithAllContacts')),
                                value: 'contacts',
                              ),
                              RadioListTile<String>(
                                title: Text(
                                    AppStrings.tr(ref, 'myContactsExcept')),
                                subtitle: Text(AppStrings.tr(
                                    ref, 'hideStatusFromSelected')),
                                value: 'except',
                              ),
                              RadioListTile<String>(
                                title:
                                    Text(AppStrings.tr(ref, 'onlyShareWith')),
                                subtitle: Text(
                                    AppStrings.tr(ref, 'shareOnlyWithChosen')),
                                value: 'only',
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        AppDialogAction(
                          label: AppStrings.tr(ref, 'doneLabel'),
                          isPrimary: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    );
                    break;
                  case 'settings':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(user: widget.user),
                      ),
                    );
                    break;
                  case 'logout':
                    showAppDialog(
                      context: context,
                      title: AppStrings.tr(ref, 'logoutDialogTitle'),
                      icon: Icons.logout_rounded,
                      iconColor: Colors.redAccent,
                      contentText: AppStrings.tr(ref, 'logoutDialogContent'),
                      actions: [
                        AppDialogAction(
                          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
                          onPressed: () => Navigator.pop(context),
                        ),
                        AppDialogAction(
                          label: AppStrings.tr(ref, 'logout').toUpperCase(),
                          isDestructive: true,
                          onPressed: () async {
                            Navigator.pop(context);
                            await AuthController.logout(
                              context: context,
                              ref: ref,
                              userId: widget.user.id,
                            );
                          },
                        ),
                      ],
                    );
                    break;
                }
              },
              itemBuilder: (context) {
                if (_tabController.index >= 2) {
                  // CALLS / KEYPAD tabs
                  return [
                    PopupMenuItem(
                      value: 'clear_call_log',
                      child: Text(AppStrings.tr(ref, 'clearCallLog')),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Text(AppStrings.tr(ref, 'settings')),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        AppStrings.tr(ref, 'logout'),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ];
                } else if (_tabController.index == 1) {
                  // STATUS tab
                  return [
                    PopupMenuItem(
                      value: 'status_privacy',
                      child: Text(AppStrings.tr(ref, 'statusPrivacy')),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Text(AppStrings.tr(ref, 'settings')),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        AppStrings.tr(ref, 'logout'),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ];
                }

                // CHATS tab (default)
                return [
                  PopupMenuItem(
                    value: 'starred_messages',
                    child: Text(AppStrings.tr(ref, 'starredMessages')),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Text(AppStrings.tr(ref, 'settings')),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text(
                      AppStrings.tr(ref, 'logout'),
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (!_isSearching)
              LivocalTabs(
                controller: _tabController,
                labels: [
                  AppStrings.tr(ref, 'chats'),
                  AppStrings.tr(ref, 'updatesTab'),
                  AppStrings.tr(ref, 'calls'),
                  DialerStrings.of(ref.watch(appLocaleProvider).languageCode)
                      .keypad,
                ],
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  ChatsTabWithHero(
                    user: widget.user,
                    searchQuery: _isSearching
                        ? _searchController.text.trim().toLowerCase()
                        : '',
                  ),
                  StatusTab(user: widget.user),
                  CallsTab(user: widget.user),
                  DialerTab(user: widget.user),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _tabController.index == 3
            ? null
            : _floatingButtons[_tabController.index],
      ),
    );
  }
}

/// Chats tab = AI call hero + the existing recent-chat list.
class ChatsTabWithHero extends StatelessWidget {
  final User user;
  final String searchQuery;

  const ChatsTabWithHero({
    super.key,
    required this.user,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (searchQuery.isEmpty) _AiCallHero(user: user),
        Expanded(
          child: RecentChatsBody(user: user, searchQuery: searchQuery),
        ),
      ],
    );
  }
}

/// Brand hero that finally makes Livocal's AI translation value visible on
/// the first screen instead of hiding it behind the call flow.
class _AiCallHero extends ConsumerWidget {
  final User user;

  const _AiCallHero({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myLang =
        CallLanguageRegistry.fromCode(CallRepository.getMyLanguageCode());
    final walletAsync = ref.watch(walletStreamProvider(user.id));
    final minutes = walletAsync.maybeWhen(
      data: (wallet) => wallet.effectiveRemainingMinutes,
      orElse: () => null,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE AI TRANSLATION',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: AppRadius.full,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      minutes == null ? '…' : '$minutes min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.tr(ref, 'heroTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.tr(ref, 'heroSubtitle'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: AppRadius.full,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      myLang.flagEmoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      myLang.nativeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white70,
                size: 15,
              ),
              const SizedBox(width: 8),
              const Text(
                '70+ languages',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMd),
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ContactsPage(user: user),
                ),
              ),
              icon: const Icon(Icons.call_rounded, size: 18),
              label: Text(
                AppStrings.tr(ref, 'newCall'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentChatsBody extends ConsumerStatefulWidget {
  const RecentChatsBody({
    super.key,
    required this.user,
    this.searchQuery = '',
  });

  final User user;
  final String searchQuery;

  @override
  ConsumerState<RecentChatsBody> createState() => _RecentChatsBodyState();
}

class _RecentChatsBodyState extends ConsumerState<RecentChatsBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorTheme = Theme.of(context).custom.colorTheme;
    final searchQuery = widget.searchQuery;

    return StreamBuilder<List<RecentChat>>(
      stream: IsarDb.getRecentChatStream(ref),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: colorTheme.greyColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.tr(ref, 'couldNotLoadChats'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.tr(ref, 'checkConnectionRetry'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorTheme.greyColor, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorTheme.greenColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(AppStrings.tr(ref, 'retryTooltip')),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const ChatListShimmerSkeleton();
        }

        var chats = snapshot.data!
            .where((c) =>
                !BlockService.isBlocked(c.user.id) &&
                !BlockService.isBlocked(c.message.senderId == widget.user.id
                    ? c.message.receiverId
                    : c.message.senderId))
            .toList();
        if (searchQuery.isNotEmpty) {
          chats = chats
              .where((c) =>
                  c.user.name.toLowerCase().contains(searchQuery) ||
                  c.message.content.toLowerCase().contains(searchQuery))
              .toList();
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  AppStrings.tr(
                    ref,
                    'noChatsMatching',
                    args: {'query': searchQuery},
                  ),
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            );
          }
        } else if (chats.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorTheme.greenColor.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 46,
                        color: colorTheme.greenColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.tr(ref, 'noConversationsYet'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.tr(ref, 'startChattingDesc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorTheme.greyColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorTheme.greenColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      if (!await hasPermission(Permission.contacts)) return;
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ContactsPage(
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_comment_rounded, size: 20),
                    label: Text(
                      AppStrings.tr(ref, 'startNewChat'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListView.separated(
          padding: const EdgeInsets.only(top: 6.0, bottom: 20.0),
          itemCount: chats.length + (chats.isNotEmpty ? 1 : 0),
          separatorBuilder: (context, index) {
            if (index >= chats.length - 1) return const SizedBox.shrink();
            return Divider(
              height: 1,
              thickness: 0.5,
              indent: 82,
              endIndent: 16,
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.lightSurfaceContainer,
            );
          },
          itemBuilder: (context, index) {
            if (index == chats.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF8A96B2)
                          : const Color(0xFF5B6785),
                    ),
                    const SizedBox(width: 6),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isDark
                              ? const Color(0xFF8A96B2)
                              : const Color(0xFF5B6785),
                        ),
                        children: const [
                          TextSpan(text: 'Your personal messages are '),
                          TextSpan(
                            text: 'encrypted in transit and stored securely',
                            style: TextStyle(
                              color: Color(0xFF00D4C8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            RecentChat chat = chats[index];
            Message msg = chat.message;
            String msgContent = chat.message.content;
            String msgStatus = '';

            if (msg.senderId == widget.user.id) {
              msgStatus = msg.status.value;
            }
            return RecentChatWidget(
              user: widget.user,
              chat: chat,
              colorTheme: colorTheme,
              title: chat.user.name,
              msgStatus: msgStatus,
              msgContent: msgContent,
            );
          },
        );
      },
    );
  }
}

class HomePageContactsList extends StatelessWidget {
  const HomePageContactsList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;

    return FutureBuilder(
      future: IsarDb.getLivocalContacts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }

        final users = snapshot.data!;
        final userCount = users.length;
        if (userCount < 2) return Container();

        int avatarDisplayCount;
        if (userCount > 4) {
          avatarDisplayCount = 5;
        } else {
          avatarDisplayCount = userCount;
        }

        final descriptionList = <String>['', ''];
        if (userCount > 3) {
          descriptionList[0] = users.getRange(0, 3).join(', ');
          descriptionList[1] =
              ' and ${userCount - 3} more of your contacts\n are on Livocal';
        } else if (userCount > 2) {
          descriptionList[0] = users.getRange(0, 2).join(', ');
          descriptionList[1] = ' and ${users[2]} are on Livocal';
        } else if (userCount > 1) {
          descriptionList[0] = users.join(' and ');
          descriptionList[1] = ' are on Livocal';
        } else {
          descriptionList[0] = '${users.first}';
          descriptionList[1] = ' is on Livocal.';
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 55,
              width: (avatarDisplayCount * 36) + 30,
              child: Stack(
                children: [
                  for (var i = 0; i < avatarDisplayCount; i++) ...[
                    Positioned(
                      right: (i * 36),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            width: 2,
                            color: AppColorsDark.backgroundColor,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: users[i].avatarUrl != null
                              ? CachedNetworkImageProvider(
                                  users[i].avatarUrl!,
                                )
                              : const AssetImage('assets/images/avatar.png')
                                  as ImageProvider,
                        ),
                      ),
                    )
                  ],
                ],
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: descriptionList[0],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? colorTheme.unselectedLabelColor
                      : colorTheme.textColor1,
                ),
                children: [
                  TextSpan(
                    text: descriptionList[1],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class RecentChatWidget extends StatelessWidget {
  const RecentChatWidget({
    super.key,
    required this.user,
    required this.chat,
    required this.colorTheme,
    required this.title,
    required this.msgStatus,
    required this.msgContent,
  });

  final User user;
  final RecentChat chat;
  final ColorTheme colorTheme;
  final String title;
  final String msgStatus;
  final String msgContent;

  List<Color> _getGradientForName(String name) {
    const gradients = [
      [Color(0xFF5B6CF9), Color(0xFF00A79E)],
      [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      [Color(0xFFDB2777), Color(0xFFBE185D)],
      [Color(0xFFD97706), Color(0xFFB45309)],
      [Color(0xFF059669), Color(0xFF047857)],
      [Color(0xFF0891B2), Color(0xFF0E7490)],
      [Color(0xFF4F46E5), Color(0xFF4338CA)],
    ];
    if (name.isEmpty) return gradients[0];
    final hash = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return gradients[hash % gradients.length];
  }

  Widget _buildAvatar(BuildContext context, bool isDark) {
    final avatarUrl = chat.user.avatarUrl;
    final displayName =
        title.trim().isNotEmpty ? title.trim() : chat.user.name.trim();
    final initial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';
    final gradient = _getGradientForName(displayName);

    Widget avatarContent;
    if (avatarUrl.isNotEmpty && avatarUrl.startsWith('http')) {
      avatarContent = CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.cover,
        memCacheWidth: 120,
        memCacheHeight: 120,
        placeholder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else {
      avatarContent = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00D4C8).withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: avatarContent,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, bool isDark, bool hasUnread) {
    final textColor = hasUnread
        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    String text = msgContent;
    if (text == "\u00A0" || text.isEmpty) {
      text = chat.message.attachment?.type.value ?? '';
    }

    IconData? attachmentIcon;
    String? attachmentLabel;
    Color? iconCustomColor;

    if (CallLogHelper.isCallLog(msgContent)) {
      final callData = CallLogHelper.parse(msgContent);
      if (callData != null) {
        final isSentByMe = chat.message.senderId == user.id;
        final durStr = CallLogHelper.formatDurationShort(callData.duration);
        if (callData.isMissed) {
          attachmentIcon = isSentByMe
              ? Icons.call_missed_outgoing_rounded
              : Icons.call_missed_rounded;
          iconCustomColor = Colors.redAccent;
          attachmentLabel = AppStrings.ctx(
            context,
            isSentByMe ? 'missedCall' : 'missedVoiceCall',
          );
        } else {
          attachmentIcon = isSentByMe
              ? Icons.call_made_rounded
              : Icons.call_received_rounded;
          iconCustomColor =
              isDark ? Colors.tealAccent : const Color(0xFF5B6CF9);
          attachmentLabel = isSentByMe
              ? (durStr.isNotEmpty
                  ? '${AppStrings.ctx(context, 'voiceCall')} ($durStr)'
                  : AppStrings.ctx(context, 'voiceCall'))
              : (durStr.isNotEmpty
                  ? '${AppStrings.ctx(context, 'incomingCallLabel')} ($durStr)'
                  : AppStrings.ctx(context, 'incomingCallLabel'));
        }
        text = attachmentLabel;
      }
    } else if (chat.message.attachment != null) {
      switch (chat.message.attachment!.type) {
        case AttachmentType.audio:
          attachmentIcon = Icons.audiotrack_rounded;
          attachmentLabel = 'Audio';
          break;
        case AttachmentType.voice:
          attachmentIcon = Icons.mic_rounded;
          attachmentLabel = 'Voice message';
          break;
        case AttachmentType.image:
          attachmentIcon = Icons.photo_rounded;
          attachmentLabel = 'Photo';
          break;
        case AttachmentType.video:
          attachmentIcon = Icons.videocam_rounded;
          attachmentLabel = 'Video';
          break;
        case AttachmentType.document:
          attachmentIcon = Icons.insert_drive_file_rounded;
          attachmentLabel = 'Document';
          break;
      }
    }

    return Row(
      children: [
        if (msgStatus.isNotEmpty) ...[
          Image.asset(
            'assets/images/$msgStatus.png',
            color: msgStatus == 'SEEN'
                ? const Color(0xFF53BDEB)
                : (isDark ? const Color(0xFF8A96B2) : const Color(0xFF5B6785)),
            width: 16.0,
          ),
          const SizedBox(width: 4.0),
        ],
        if (attachmentIcon != null) ...[
          Icon(
            attachmentIcon,
            size: 16.0,
            color: iconCustomColor ??
                (isDark ? const Color(0xFF8A96B2) : const Color(0xFF5B6785)),
          ),
          const SizedBox(width: 4.0),
        ],
        Expanded(
          child: Text(
            attachmentLabel != null && text.isEmpty ? attachmentLabel : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.0,
              height: 1.25,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = chat.unreadCount > 0;
    final contactDisplayName = title.isNotEmpty
        ? title
        : (chat.user.phone.getFormattedNumber().isNotEmpty
            ? chat.user.phone.getFormattedNumber()
            : 'Unknown');

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      onTap: () {
        chat.unreadCount = 0;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              self: user,
              other: chat.user,
              otherUserContactName: title,
            ),
            settings: const RouteSettings(name: 'chat'),
          ),
        );
      },
      leading: Semantics(
        button: true,
        label: AppStrings.get(
          'viewContactProfile',
          SharedPref.instance.getString('app_language') ?? 'en',
        ),
        child: ExcludeSemantics(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ContactProfileScreen(
                    self: user,
                    other: chat.user,
                    contactName: title,
                  ),
                ),
              );
            },
            child: _buildAvatar(context, isDark),
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 3.0),
        child: Text(
          contactDisplayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      subtitle: _buildSubtitle(context, isDark, hasUnread),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 92),
        child: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: RecentChatTime(
                  chat: chat,
                  hasUnread: hasUnread,
                ),
              ),
              const SizedBox(height: 5.0),
              Builder(
                builder: (context) {
                  final isMuted = MuteService.isContactMuted(chat.user.id);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMuted) ...[
                        const Icon(
                          Icons.volume_off_rounded,
                          size: 15,
                          color: Color(0xFF8A96B2),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (hasUnread)
                        Container(
                          constraints:
                              const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.5, vertical: 2.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5B6CF9), Color(0xFF00D4C8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00D4C8)
                                    .withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : '${chat.unreadCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        )
                      else if (!isMuted)
                        const SizedBox(height: 20.0),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentChatTime extends StatelessWidget {
  const RecentChatTime({
    super.key,
    required this.chat,
    this.hasUnread = false,
  });

  final RecentChat chat;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<DateTime>(
      valueListenable: TimeTicker.minuteTicker,
      builder: (context, _, __) {
        return Text(
          formattedTimestamp(
            chat.message.timestamp,
          ),
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
            letterSpacing: -0.1,
            color: hasUnread
                ? const Color(0xFF00D4C8)
                : (isDark ? const Color(0xFF8A96B2) : const Color(0xFF5B6785)),
          ),
        );
      },
    );
  }
}
