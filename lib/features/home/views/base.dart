import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/calls/models/call_model.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/features/calls/views/calls_tab.dart';
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
import 'package:camera/camera.dart';
import 'package:livocal/features/home/views/status_tab.dart';
import 'package:livocal/shared/widgets/camera.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/features/home/views/linked_devices_screen.dart';
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
                debugPrint('Auto-download complete for message ${message.id}: $filePath');
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
          RingtoneManager().playMessageNotificationTone(contactId: lastIncomingSenderId);
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
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(handleTabIndexChange);

    _floatingButtons = [
      FloatingActionButton(
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
            backgroundColor: AppColorsDark.appBarColor,
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
        if (current != null && current.status == CallStateStatus.ringing && current.isIncoming) {
          CallKitService().endAllCalls();
          ref.read(callControllerProvider.notifier).endCall(recordAsMissed: false);
        }
        return;
      }
      if (!mounted) return;
      if (BlockService.isBlocked(incomingSession.callerId)) {
        debugPrint('[base.dart] Suppressing incoming call from blocked caller: ${incomingSession.callerId}');
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
          otherUserContactName:
              contact?.displayName ?? (author.name.isNotEmpty ? author.name : author.phone.getFormattedNumber()),
        ),
      ),
    );
  }

  Widget _buildBrandTitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Logo Emblem with subtle glow
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(right: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A884).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Brand Typography: "Li" (White/Light) + "Vocal" (Emerald Green)
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(
                text: 'Li ',
                style: TextStyle(
                  color: isDark ? const Color(0xFFF0F2F5) : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const TextSpan(
                text: 'Vocal',
                style: TextStyle(
                  color: Color(0xFF25D366),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Modern "AI" Pill Accent
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00A884), Color(0xFF25D366)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Text(
            'AI',
            style: TextStyle(
              color: Colors.black,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.primary,
          foregroundColor: Colors.white,
          scrolledUnderElevation: 0,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          leading: _isSearching
              ? IconButton(
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
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                  cursorColor: colorTheme.greenColor,
                  decoration: const InputDecoration(
                    hintText: 'Search chats, messages...',
                    hintStyle: TextStyle(color: Colors.white60, fontSize: 15),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : _buildBrandTitle(context),
          actions: [
            if (_isSearching) ...[
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
              ),
            ] else ...[
              IconButton(
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
                  case 'linked_devices':
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            LinkedDevicesScreen(user: widget.user),
                      ),
                    );
                    break;
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
                        content: 'Call log cleared',
                        type: SnacBarType.info,
                      );
                      setState(() {});
                    }
                    break;
                  case 'status_privacy':
                    String privacy = SharedPref.instance.getString('status_privacy') ?? 'contacts';
                    showAppDialog(
                      context: context,
                      title: 'Status privacy',
                      icon: Icons.lock_outline_rounded,
                      content: StatefulBuilder(
                        builder: (ctx, setDlgState) => RadioGroup<String>(
                          groupValue: privacy,
                          onChanged: (val) {
                            if (val != null) {
                              setDlgState(() => privacy = val);
                              SharedPref.instance.setString('status_privacy', val);
                            }
                          },
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Who can see my status updates:',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              SizedBox(height: 8),
                              RadioListTile<String>(
                                title: Text('My contacts'),
                                subtitle: Text('Share with all contacts in phonebook'),
                                value: 'contacts',
                              ),
                              RadioListTile<String>(
                                title: Text('My contacts except...'),
                                subtitle: Text('Hide status from selected contacts'),
                                value: 'except',
                              ),
                              RadioListTile<String>(
                                title: Text('Only share with...'),
                                subtitle: Text('Share only with chosen friends'),
                                value: 'only',
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        AppDialogAction(
                          label: 'DONE',
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
                if (_tabController.index == 2) {
                  // CALLS tab
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
                    value: 'linked_devices',
                    child: Text(AppStrings.tr(ref, 'linkedDevices')),
                  ),
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
          bottom: TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(
                width: 3.2,
                color: Color(0xFF25D366),
              ),
              borderRadius: BorderRadius.all(Radius.circular(3)),
              insets: EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF25D366)
                : Colors.white,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8696A0)
                : Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            dividerColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF252D32)
                : Colors.white24,
            dividerHeight: 1.0,
            tabs: [
              Tab(
                text: AppStrings.tr(ref, 'chats').toUpperCase(),
              ),
              Tab(
                text: AppStrings.tr(ref, 'status').toUpperCase(),
              ),
              Tab(
                text: AppStrings.tr(ref, 'calls').toUpperCase(),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            RecentChatsBody(
              user: widget.user,
              searchQuery: _isSearching ? _searchController.text.trim().toLowerCase() : '',
            ),
            StatusTab(user: widget.user),
            CallsTab(user: widget.user),
          ],
        ),
        floatingActionButton: _floatingButtons[_tabController.index],
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
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
                    "Couldn't load chats",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and tap retry.',
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const ChatListShimmerSkeleton();
        }

        var chats = snapshot.data!;
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
                  'No chats found matching "$searchQuery"',
                  style: const TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            );
          }
        } else if (chats.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
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
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with your contacts with real-time translation and voice calls.',
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                    label: const Text(
                      'Start new chat',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
              color: isDark ? const Color(0xFF1F2C34) : const Color(0xFFF0F2F5),
            );
          },
          itemBuilder: (context, index) {
            if (index == chats.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                    ),
                    const SizedBox(width: 6),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isDark ? const Color(0xFF8696A0) : const Color(0xFF667781),
                        ),
                        children: const [
                          TextSpan(text: 'Your personal messages are '),
                          TextSpan(
                            text: 'end-to-end encrypted',
                            style: TextStyle(
                              color: Color(0xFF25D366),
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
      [Color(0xFF00A884), Color(0xFF128C7E)],
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
          color: const Color(0xFF25D366).withValues(alpha: 0.18),
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
        ? (isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21))
        : (isDark ? const Color(0xFF8696A0) : const Color(0xFF667781));

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
          attachmentIcon = isSentByMe ? Icons.call_missed_outgoing_rounded : Icons.call_missed_rounded;
          iconCustomColor = Colors.redAccent;
          attachmentLabel = isSentByMe ? 'মিসড কল' : 'মিসড ভয়েস কল';
        } else {
          attachmentIcon = isSentByMe ? Icons.call_made_rounded : Icons.call_received_rounded;
          iconCustomColor = isDark ? Colors.tealAccent : const Color(0xFF00A884);
          attachmentLabel = isSentByMe
              ? (durStr.isNotEmpty ? "ভয়েস কল ($durStr)" : "ভয়েস কল")
              : (durStr.isNotEmpty ? "ইনকামিং কল ($durStr)" : "ইনকামিং কল");
        }
        text = attachmentLabel;
      }
    } else

    if (chat.message.attachment != null) {
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
                : (isDark ? const Color(0xFF8696A0) : const Color(0xFF667781)),
            width: 16.0,
          ),
          const SizedBox(width: 4.0),
        ],
        if (attachmentIcon != null) ...[
          Icon(
            attachmentIcon,
            size: 16.0,
            color: iconCustomColor ?? (isDark ? const Color(0xFF8696A0) : const Color(0xFF667781)),
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
      leading: GestureDetector(
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
            color: isDark
                ? const Color(0xFFE9EDEF)
                : const Color(0xFF111B21),
          ),
        ),
      ),
      subtitle: _buildSubtitle(context, isDark, hasUnread),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            RecentChatTime(
              chat: chat,
              hasUnread: hasUnread,
            ),
            const SizedBox(height: 5.0),
            Builder(
              builder: (context) {
                final isMuted = SharedPref.instance
                        .getBool('contact_muted_${chat.user.id}') ??
                    false;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMuted) ...[
                      const Icon(
                        Icons.volume_off_rounded,
                        size: 15,
                        color: Color(0xFF8696A0),
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
                            colors: [Color(0xFF00A884), Color(0xFF25D366)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF25D366).withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
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
                ? const Color(0xFF25D366)
                : (isDark
                    ? const Color(0xFF8696A0)
                    : const Color(0xFF667781)),
          ),
        );
      },
    );
  }
}
