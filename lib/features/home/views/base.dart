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
import 'package:livocal/features/chat/models/attachement.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/features/chat/models/recent_chat.dart';
import 'package:livocal/features/chat/views/chat.dart';
import 'package:livocal/features/home/data/repositories/contact_repository.dart';
import 'package:livocal/shared/repositories/download_service.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/models/contact.dart';
import 'package:livocal/features/home/views/contacts.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/repositories/push_notifications.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/theme/theme.dart';
import '../../../shared/utils/storage_paths.dart';
import '../../../theme/color_theme.dart';
import 'package:livocal/features/auth/domain/auth_service.dart';
import 'package:livocal/features/home/views/settings_screen.dart';
import 'package:camera/camera.dart';
import 'package:livocal/features/home/views/status_tab.dart';
import 'package:livocal/shared/widgets/camera.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/features/home/views/linked_devices_screen.dart';
import 'package:livocal/features/home/views/starred_messages_screen.dart';
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        ref.read(firebaseFirestoreRepositoryProvider).setActivityStatus(
            userId: widget.user.id,
            statusValue: UserActivityStatus.online.value);
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

    messageListener = firestore.getChatStream(widget.user.id).listen(
      (messages) async {
        for (final message in messages) {
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

        IsarDb.addMessages(messages);
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
        .watchIncomingCalls(widget.user.id)
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).custom.textTheme;
    final colorTheme = Theme.of(context).custom.colorTheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
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
              : Text(
                  'Livocal',
                  style: textTheme.titleLarge.copyWith(color: colorTheme.iconColor),
                ),
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
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        String privacy = SharedPref.instance.getString('status_privacy') ?? 'contacts';
                        return StatefulBuilder(
                          builder: (ctx, setDlgState) => AlertDialog(
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1F2C34)
                                : Colors.white,
                            title: const Text('Status privacy', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Who can see my status updates:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                const SizedBox(height: 8),
                                RadioListTile<String>(
                                  title: const Text('My contacts'),
                                  subtitle: const Text('Share with all contacts in phonebook'),
                                  value: 'contacts',
                                  groupValue: privacy,
                                  activeColor: const Color(0xFF00A884),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDlgState(() => privacy = val);
                                      SharedPref.instance.setString('status_privacy', val);
                                    }
                                  },
                                ),
                                RadioListTile<String>(
                                  title: const Text('My contacts except...'),
                                  subtitle: const Text('Hide status from selected contacts'),
                                  value: 'except',
                                  groupValue: privacy,
                                  activeColor: const Color(0xFF00A884),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDlgState(() => privacy = val);
                                      SharedPref.instance.setString('status_privacy', val);
                                    }
                                  },
                                ),
                                RadioListTile<String>(
                                  title: const Text('Only share with...'),
                                  subtitle: const Text('Share only with chosen friends'),
                                  value: 'only',
                                  groupValue: privacy,
                                  activeColor: const Color(0xFF00A884),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDlgState(() => privacy = val);
                                      SharedPref.instance.setString('status_privacy', val);
                                    }
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('DONE', style: TextStyle(color: Color(0xFF00A884))),
                              ),
                            ],
                          ),
                        );
                      },
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
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1F2C34)
                            : Colors.white,
                        title: const Text(
                          'Log out of Livocal?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'Are you sure you want to log out? Local data and credentials will be cleared.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('CANCEL'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await AuthController.logout(
                                context: context,
                                ref: ref,
                                userId: widget.user.id,
                              );
                            },
                            child: const Text('LOG OUT'),
                          ),
                        ],
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (context) {
                if (_tabController.index == 2) {
                  // CALLS tab
                  return const [
                    PopupMenuItem(
                      value: 'clear_call_log',
                      child: Text('Clear call log'),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Text('Settings'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        'Log out',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ];
                } else if (_tabController.index == 1) {
                  // STATUS tab
                  return const [
                    PopupMenuItem(
                      value: 'status_privacy',
                      child: Text('Status privacy'),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Text('Settings'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        'Log out',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ];
                }

                // CHATS tab (default)
                return const [
                  PopupMenuItem(
                    value: 'linked_devices',
                    child: Text('Linked devices'),
                  ),
                  PopupMenuItem(
                    value: 'starred_messages',
                    child: Text('Starred messages'),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Text('Settings'),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text(
                      'Log out',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ];
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelStyle: textTheme.labelLarge,
            tabs: [
              Tab(
                text: AppStrings.tr(ref, 'chats'),
              ),
              Tab(
                text: AppStrings.tr(ref, 'status'),
              ),
              Tab(
                text: AppStrings.tr(ref, 'calls'),
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
          return const HomePageContactsList();
        }
        if (!snapshot.hasData) {
          return Container();
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
          return const HomePageContactsList();
        }

        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ListView.builder(
                itemCount: chats.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
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
              ),
            ),
            if (chats.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 18,
                      color: Theme.of(context).brightness == Brightness.light
                          ? colorTheme.greyColor
                          : colorTheme.iconColor,
                    ),
                    const SizedBox(width: 4),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: 'Your personal messages are ',
                            style: TextStyle(color: colorTheme.greyColor),
                          ),
                          TextSpan(
                            text: 'private and encrypted',
                            style: TextStyle(color: colorTheme.greenColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
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
      future: IsarDb.getWhatsAppContacts(),
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

  @override
  Widget build(BuildContext context) {
    final trailingChildren = [
      RecentChatTime(chat: chat, colorTheme: colorTheme),
      if (chat.unreadCount > 0) ...[
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorTheme.greenColor,
          ),
          margin: const EdgeInsets.only(left: 4.0),
          padding: const EdgeInsets.all(6.0),
          child: Text(
            chat.unreadCount.toString(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        )
      ],
    ];

    return ListTile(
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
      leading: CircleAvatar(
        radius: 28.0,
        backgroundImage: chat.user.avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(chat.user.avatarUrl)
            : const AssetImage('assets/images/avatar.png') as ImageProvider,
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .custom
            .textTheme
            .titleMedium
            .copyWith(color: colorTheme.textColor1),
      ),
      subtitle: Row(
        children: [
          if (msgStatus.isNotEmpty) ...[
            Image.asset(
              'assets/images/$msgStatus.png',
              color: msgStatus != 'SEEN' ? colorTheme.textColor1 : null,
              width: 15.0,
            ),
            const SizedBox(
              width: 2.0,
            )
          ],
          if (chat.message.attachment != null) ...[
            LayoutBuilder(
              builder: (context, _) {
                switch (chat.message.attachment!.type) {
                  case AttachmentType.audio:
                    return const Icon(
                      Icons.audiotrack_rounded,
                      size: 20,
                    );

                  case AttachmentType.voice:
                    return const Icon(
                      Icons.mic,
                      size: 20,
                    );

                  case AttachmentType.image:
                    return const Icon(
                      Icons.image_rounded,
                      size: 20,
                    );

                  case AttachmentType.video:
                    return const Icon(
                      Icons.videocam_rounded,
                      size: 20,
                    );

                  default:
                    return const Icon(
                      Icons.file_copy,
                      size: 20,
                    );
                }
              },
            ),
            const SizedBox(
              width: 2.0,
            )
          ],
          Text(
              msgContent.length > 30
                  ? '${msgContent.substring(0, 30)}...'
                  : msgContent == "\u00A0" || msgContent.isEmpty
                      ? (chat.message.attachment?.type.value ?? '')
                      : msgContent,
              style: Theme.of(context).custom.textTheme.subtitle2)
        ],
      ),
      trailing: chat.unreadCount > 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: trailingChildren,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: trailingChildren,
            ),
    );
  }
}

class RecentChatTime extends StatefulWidget {
  const RecentChatTime({
    super.key,
    required this.chat,
    required this.colorTheme,
  });

  final RecentChat chat;
  final ColorTheme colorTheme;

  @override
  State<RecentChatTime> createState() => _RecentChatTimeState();
}

class _RecentChatTimeState extends State<RecentChatTime> {
  late final Timer timer;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formattedTimestamp(
        widget.chat.message.timestamp,
      ),
      style: Theme.of(context).custom.textTheme.caption.copyWith(
            color: widget.chat.unreadCount > 0
                ? widget.colorTheme.greenColor
                : Theme.of(context).custom.colorTheme.greyColor,
          ),
    );
  }
}
