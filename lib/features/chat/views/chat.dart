import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:livocal/features/calls/views/outgoing_call_screen.dart';
import 'package:livocal/features/chat/controllers/chat_controller.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/features/chat/views/widgets/attachment_picker.dart';
import 'package:livocal/features/chat/views/widgets/chat_date.dart';
import 'package:livocal/features/chat/views/widgets/chat_field.dart';
import 'package:livocal/features/chat/views/widgets/chat_mic.dart';
import 'package:livocal/features/chat/views/widgets/message_cards.dart';
import 'package:livocal/features/chat/views/widgets/scroll_btn.dart';
import 'package:livocal/features/chat/views/widgets/voice_recorder.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/abc.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/shared/widgets/bottom_inset.dart';
import 'package:livocal/shared/widgets/shimmer_skeleton.dart';
import 'package:livocal/theme/app_tokens.dart';
import 'package:livocal/theme/color_theme.dart';
import 'package:livocal/theme/theme.dart';
import 'package:livocal/shared/utils/snackbars.dart';

import '../../../shared/widgets/emoji_picker.dart';
import 'contact_profile_screen.dart';
import 'widgets/chat_translation_sheet.dart';
import 'widgets/send_payment_sheet.dart';
import 'widgets/unread_banner.dart';

class ChatPage extends ConsumerStatefulWidget {
  final User self;
  final User other;
  final String otherUserContactName;

  const ChatPage({
    super.key,
    required this.self,
    required this.other,
    required this.otherUserContactName,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    ref
        .read(chatControllerProvider.notifier)
        .initUsers(widget.self, widget.other, widget.otherUserContactName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final self = widget.self;
    final other = widget.other;

    return Platform.isAndroid
        ? PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (!ref.read(chatControllerProvider).showEmojiPicker) {
                Navigator.pop(context);
                return;
              }

              ref
                  .read(chatControllerProvider.notifier)
                  .setShowEmojiPicker(false);
            },
            child: _build(self, other, context),
          )
        : _build(self, other, context);
  }

  Widget _build(User self, User other, BuildContext context) {
    final recordingState = ref.watch(
      chatControllerProvider.select((chatState) => chatState.recordingState),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarBg = isDark ? AppColors.darkSurface : AppColors.primary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0.0,
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ContactProfileScreen(
                  self: self,
                  other: other,
                  contactName: widget.otherUserContactName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              children: [
                CircleAvatar(
                  maxRadius: 18,
                  backgroundImage: other.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(other.avatarUrl)
                      : const AssetImage('assets/images/avatar.png') as ImageProvider,
                ),
                const SizedBox(
                  width: 8.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.otherUserContactName,
                        style: Theme.of(context).custom.textTheme.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      StreamBuilder<UserActivityStatus>(
                        stream: ref
                            .read(firebaseFirestoreRepositoryProvider)
                            .userActivityStatusStream(userId: other.id),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          return snapshot.data!.value == 'Online'
                              ? Text(
                                  'Online',
                                  style: Theme.of(context).custom.textTheme.caption.copyWith(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 12,
                                      ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        leadingWidth: 36.0,
        leading: IconButton(
          onPressed: () =>
              ref.read(chatControllerProvider.notifier).navigateToHome(context),
          icon: const Icon(
            Icons.arrow_back,
            size: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              final isTransEnabled = SharedPref.instance.getBool(
                    'chat_trans_${widget.other.id}_enabled',
                  ) ??
                  false;
              return IconButton(
                tooltip: isTransEnabled
                    ? 'In-Chat Live Translation (ON)'
                    : 'In-Chat Live Translation (OFF)',
                onPressed: () {
                  showInChatTranslationSheet(
                    context: context,
                    peerName: widget.otherUserContactName,
                    peerId: widget.other.id,
                    onSettingsChanged: () {
                      setState(() {});
                    },
                  );
                },
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      size: 24,
                      color: isTransEnabled
                          ? const Color(0xFF25D366)
                          : Colors.white,
                    ),
                    if (isTransEnabled)
                      Positioned(
                        right: 0,
                        top: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF25D366),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Voice Call with AI Translation',
            onPressed: recordingState == RecordingState.notRecording
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OutgoingCallScreen(
                          caller: self,
                          callee: other,
                          calleeDisplayName: widget.otherUserContactName,
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(
              Icons.call,
              color: Colors.white,
              size: 24,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 26,
            ),
            onSelected: (value) async {
              switch (value) {
                case 'view_contact':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContactProfileScreen(
                        self: self,
                        other: other,
                        contactName: widget.otherUserContactName,
                      ),
                    ),
                  );
                  break;
                case 'clear_chat':
                  final confirmed = await showAppDialog<bool>(
                    context: context,
                    title: 'Clear this chat?',
                    contentText: 'Messages will be cleared from this device.',
                    icon: Icons.delete_sweep_outlined,
                    iconColor: Colors.redAccent,
                    actions: [
                      AppDialogAction(
                        label: 'CANCEL',
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      AppDialogAction(
                        label: 'CLEAR CHAT',
                        isDestructive: true,
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ],
                  );
                  if (confirmed == true && context.mounted) {
                    final chatId = getChatId(self.id, other.id);
                    await IsarDb.deleteChat(chatId);
                    if (context.mounted) {
                      showSnackBar(
                        context: context,
                        content: 'Chat cleared',
                        type: SnacBarType.info,
                      );
                    }
                  }
                  break;
                case 'mute':
                  showSnackBar(
                    context: context,
                    content: 'Notifications muted for this chat',
                    type: SnacBarType.info,
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'view_contact',
                child: Text('View contact'),
              ),
              PopupMenuItem(
                value: 'mute',
                child: Text('Mute notifications'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear_chat',
                child: Text(
                  'Clear chat',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Theme.of(context).themedImage('chat_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Platform.isIOS
                  ? GestureDetector(
                      onTap: () {
                        SystemChannels.textInput.invokeMethod(
                          "TextInput.hide",
                        );
                        ref
                            .read(chatControllerProvider.notifier)
                            .setShowEmojiPicker(false);
                      },
                      child: const ChatStream(),
                    )
                  : const ChatStream(),
            ),
            const SizedBox(
              height: 4.0,
            ),
            ChatInputContainer(
              self: self,
              other: other,
              otherUserContactName: widget.otherUserContactName,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatInputContainer extends ConsumerStatefulWidget {
  const ChatInputContainer({
    super.key,
    required this.self,
    required this.other,
    required this.otherUserContactName,
  });

  final User self;
  final User other;
  final String otherUserContactName;

  @override
  ConsumerState<ChatInputContainer> createState() => _ChatInputContainerState();
}

class _ChatInputContainerState extends ConsumerState<ChatInputContainer>
    with WidgetsBindingObserver {
  double keyboardHeight =
      SharedPref.instance.getDouble('keyboardHeight') ?? 300.0;
  bool isKeyboardVisible = false;
  late final StreamSubscription<bool> _keyboardSubscription;

  @override
  void initState() {
    ref.read(chatControllerProvider.notifier).initRecorder();
    _keyboardSubscription =
        KeyboardVisibilityController().onChange.listen((isVisible) async {
      isKeyboardVisible = isVisible;
      if (isVisible) {
        ref.read(chatControllerProvider.notifier).setShowEmojiPicker(false);
      }
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();
    _keyboardSubscription.cancel();
  }

  void switchKeyboards() async {
    final showEmojiPicker = ref.read(chatControllerProvider).showEmojiPicker;

    if (!showEmojiPicker && !isKeyboardVisible) {
      ref.read(chatControllerProvider.notifier).setShowEmojiPicker(true);
    } else if (showEmojiPicker) {
      ref.read(chatControllerProvider).fieldFocusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || showEmojiPicker) return;
        ref.read(chatControllerProvider.notifier).setShowEmojiPicker(false);
      });
    } else if (isKeyboardVisible) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      ref.read(chatControllerProvider.notifier).setShowEmojiPicker(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final hideElements = ref.watch(
      chatControllerProvider.select((s) => s.hideElements),
    );
    final recordingState = ref.watch(
      chatControllerProvider.select((s) => s.recordingState),
    );
    final showEmojiPicker = ref.watch(
      chatControllerProvider.select((s) => s.showEmojiPicker),
    );

    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final dynamicBottomPadding = isKeyboardVisible
        ? 0.0
        : (systemBottomPadding > 0
            ? systemBottomPadding + 4.0
            : (Platform.isAndroid ? 8.0 : 24.0));

    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.light
                ? colorTheme.greyColor
                : colorTheme.iconColor),
      ),
      child: AvoidBottomInset(
        padding: EdgeInsets.only(bottom: dynamicBottomPadding),
        conditions: [showEmojiPicker],
        offstage: Offstage(
          offstage: !showEmojiPicker,
          child: CustomEmojiPicker(
            afterEmojiPlaced: (emoji) => ref
                .read(chatControllerProvider.notifier)
                .onTextChanged(emoji.emoji),
            textController: ref.read(chatControllerProvider).messageController,
          ),
        ),
        child: recordingState != RecordingState.recordingLocked &&
                recordingState != RecordingState.paused
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.0),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? colorTheme.appBarColor
                              : colorTheme.backgroundColor,
                        ),
                        child: recordingState == RecordingState.notRecording
                            ? _buildChatField(
                                showEmojiPicker,
                                context,
                                hideElements,
                                colorTheme,
                              )
                            : const VoiceRecorderField(),
                      ),
                    ),
                    const SizedBox(
                      width: 4.0,
                    ),
                    hideElements
                        ? InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(chatControllerProvider.notifier)
                                  .onSendBtnPressed(
                                    ref,
                                    widget.self,
                                    widget.other,
                                  );
                            },
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: colorTheme.greenColor,
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const ChatInputMic(),
                  ],
                ),
              )
            : const VoiceRecorder(),
      ),
    );
  }

  ChatField _buildChatField(bool showEmojiPicker, BuildContext context,
      bool hideElements, ColorTheme colorTheme) {
    return ChatField(
        leading: GestureDetector(
          onTap: switchKeyboards,
          child: Icon(
            !showEmojiPicker ? Icons.emoji_emotions : Icons.keyboard,
            size: 26.0,
          ),
        ),
        focusNode: ref.read(chatControllerProvider).fieldFocusNode,
        onTextChanged: (value) =>
            ref.read(chatControllerProvider.notifier).onTextChanged(value),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            HapticFeedback.lightImpact();
            ref.read(chatControllerProvider.notifier).onSendBtnPressed(
                  ref,
                  widget.self,
                  widget.other,
                );
          }
        },
        textController: ref.read(chatControllerProvider).messageController,
        actions: [
          InkWell(
            onTap: () {
              onAttachmentsIconPressed(
                context,
              );
            },
            child: Transform.rotate(
              angle: -0.8,
              child: const Icon(
                Icons.attach_file_rounded,
                size: 26.0,
              ),
            ),
          ),
          if (!hideElements) ...[
            InkWell(
              onTap: () {
                showSendPaymentSheet(
                  context: context,
                  self: widget.self,
                  other: widget.other,
                  contactName: widget.otherUserContactName,
                  onPaymentConfirmed: (amount, note, [method, txId]) {
                    final methodStr =
                        (method != null && method.isNotEmpty) ? ' via $method' : '';
                    final refStr =
                        (txId != null && txId.isNotEmpty) ? ' (Ref: $txId)' : '';
                    final noteStr = note.isNotEmpty ? '\nNote: $note' : '';
                    final paymentMsg =
                        '💰 Payment sent: \$$amount$methodStr$refStr$noteStr';
                    ref.read(chatControllerProvider.notifier).sendMessageNoAttachments(
                      Message(
                        id: const Uuid().v4(),
                        content: paymentMsg,
                        status: MessageStatus.pending,
                        senderId: widget.self.id,
                        receiverId: widget.other.id,
                        timestamp: Timestamp.now(),
                      ),
                    );
                  },
                );
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).brightness == Brightness.light
                      ? colorTheme.greyColor
                      : colorTheme.iconColor,
                ),
                child: Center(
                  child: Text(
                    '\$',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.light
                          ? colorTheme.backgroundColor
                          : colorTheme.appBarColor,
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                ref
                    .read(
                      chatControllerProvider.notifier,
                    )
                    .navigateToCameraView(context);
              },
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 24.0,
              ),
            ),
          ],
        ]);
  }

  void onAttachmentsIconPressed(BuildContext context) {
    final focusNode = ref.read(chatControllerProvider).fieldFocusNode;
    focusNode.unfocus();
    Future.delayed(
      Duration(
        milliseconds: MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0,
      ),
      () async {
        if (!mounted) return;
        showDialog(
          barrierColor: null,
          context: context,
          builder: (context) {
            return Dialog(
              alignment: Alignment.bottomCenter,
              insetPadding: EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: ref.read(chatControllerProvider).showEmojiPicker
                    ? 36.0
                    : 56.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 0,
              child: const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: AttachmentPicker(),
              ),
            );
          },
        );
      },
    );
  }
}

class ChatStream extends ConsumerStatefulWidget {
  const ChatStream({
    super.key,
  });

  @override
  ConsumerState<ChatStream> createState() => _ChatStreamState();
}

class _ChatStreamState extends ConsumerState<ChatStream> {
  late final User self;
  late final User other;
  late final String chatId;
  late final ScrollController scrollController;
  late Stream<List<Message>> messageStream;

  bool isInitialRender = true;
  int unreadCount = 0;
  int prevMsgCount = 0;
  final bannerKey = GlobalKey();
  int _messageLimit = 100;
  bool _isLoadingMore = false;

  void _onScroll() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 250 &&
        !_isLoadingMore) {
      _isLoadingMore = true;
      _messageLimit += 50;
      setState(() {
        messageStream = IsarDb.getChatStream(chatId, limit: _messageLimit);
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _isLoadingMore = false;
      });
    }
  }

  @override
  void initState() {
    self = ref.read(chatControllerProvider.notifier).self;
    other = ref.read(chatControllerProvider.notifier).other;
    chatId = getChatId(self.id, other.id);

    messageStream = IsarDb.getChatStream(chatId, limit: _messageLimit);
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);

    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void handleNewMessage(Message message) {
    if (message.senderId == self.id) {
      unreadCount = 0;
      if (message.status == MessageStatus.pending) {
        scrollToBottom();
      }
    } else {
      unreadCount = unreadCount > 0 ? unreadCount + 1 : 0;
    }
  }

  void handleInitialData(int unreadMsgCount) {
    isInitialRender = false;
    unreadCount = unreadMsgCount;

    if (unreadCount > 0) {
      scrollToUnreadBanner();
    }
  }

  int updateUnreadCount(List<Message> messages) {
    int unreadCount = 0;

    for (final message in messages) {
      if (message.senderId == self.id) break;
      if (message.status == MessageStatus.seen) break;
      unreadCount++;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).setUnreadCount(unreadCount);
    });

    return unreadCount;
  }

  void scrollToUnreadBanner() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Scrollable.ensureVisible(
        bannerKey.currentContext!,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void markAsSeen(Message message) {
    if (message.senderId == self.id) return;
    if (message.status == MessageStatus.seen) return;
    final readReceiptsEnabled = SharedPref.instance.getBool('privacy_read_receipts') ?? true;
    if (!readReceiptsEnabled) {
      IsarDb.updateMessage(message.id, status: MessageStatus.seen);
      return;
    }
    ref.read(chatControllerProvider.notifier).markMessageAsSeen(message);
  }

  int getMessageIndexByKey(Key key, List<Message> messages) {
    final messageKey = key as ValueKey;
    return messages.indexWhere((msg) => msg.id == messageKey.value);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final colorTheme = Theme.of(context).custom.colorTheme;

    return StreamBuilder<List<Message>>(
      stream: messageStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ChatBubbleShimmerSkeleton();
        }

        final messages = snapshot.data!;
        final unreadMsgCount = updateUnreadCount(messages);

        if (isInitialRender) {
          handleInitialData(unreadMsgCount);
        } else if (messages.length - prevMsgCount > 0) {
          handleNewMessage(messages.first);
        }

        prevMsgCount = messages.length;

        if (messages.isEmpty) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(color: Colors.transparent),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSecurityBanner(context, isDarkTheme, colorTheme),
                      const SizedBox(height: 28),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                        child: const Center(
                          child: Text(
                            '👋',
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Say hello to ${other.name.isNotEmpty ? other.name : "your contact"}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkTheme
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No messages here yet. Send a greeting or voice note to begin the conversation.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDarkTheme
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.radiusXl),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref.read(chatControllerProvider.notifier).sendMessageNoAttachments(
                                Message(
                                  id: const Uuid().v4(),
                                  content: 'Hello! 👋',
                                  status: MessageStatus.pending,
                                  senderId: self.id,
                                  receiverId: other.id,
                                  timestamp: Timestamp.now(),
                                ),
                              );
                        },
                        icon: const Text('👋', style: TextStyle(fontSize: 16)),
                        label: const Text(
                          'Say hello!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(color: Colors.transparent),
            CustomScrollView(
              shrinkWrap: true,
              reverse: true,
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (unreadCount > 0) ...[
                  SliverList.builder(
                    itemCount: unreadCount,
                    itemBuilder: (context, index) {
                      return buildMessageCard(index, messages);
                    },
                    findChildIndexCallback: (key) {
                      return getMessageIndexByKey(key, messages);
                    },
                  ),
                  SliverToBoxAdapter(
                    key: bannerKey,
                    child: UnreadMessagesBanner(
                      unreadCount: unreadCount,
                    ),
                  ),
                ],
                SliverList.builder(
                  itemCount: messages.length - unreadCount,
                  itemBuilder: (context, index) {
                    index = index + unreadCount;
                    return buildMessageCard(index, messages);
                  },
                  findChildIndexCallback: (key) {
                    return getMessageIndexByKey(key, messages);
                  },
                ),
                SliverToBoxAdapter(
                  child: _buildSecurityBanner(context, isDarkTheme, colorTheme),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ChatDate(
                      date: dateFromTimestamp(messages.last.timestamp),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ScrollButton(scrollController: scrollController),
            )
          ],
        );
      },
    );
  }

  Widget buildMessageCard(int index, List<Message> messages) {
    final message = messages[index];
    final isFirstMsg = index == messages.length - 1;
    final isSpecial =
        isFirstMsg || messages[index].senderId != messages[index + 1].senderId;
    final currMsgDate = dateFromTimestamp(messages[index].timestamp);
    final showDate = isFirstMsg ||
        currMsgDate != dateFromTimestamp(messages[index + 1].timestamp);

    return Column(
      key: ValueKey(message.id),
      children: [
        if (!isFirstMsg && showDate) ...[
          ChatDate(date: currMsgDate),
        ],
        VisibilityDetector(
          key: ValueKey('${message.id}_vd'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction < 0.1) return;
            markAsSeen(message);
          },
          child: MessageCard(
            message: message,
            currentUserId: self.id,
            special: isSpecial,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBanner(
    BuildContext context,
    bool isDarkTheme,
    ColorTheme colorTheme,
  ) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
        onTap: () {
          showAppDialog(
            context: context,
            icon: Icons.lock_outline_rounded,
            iconColor: AppColors.primary,
            title: 'Private & Secure Messaging',
            contentText:
                'Your messages and media are protected with zero-trust authenticated access control and TLS encryption. Voice calls stream securely via DTLS-SRTP with ephemeral Gemini Live AI translation.',
            actions: [
              AppDialogAction(
                label: 'OK',
                isPrimary: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          margin: const EdgeInsets.only(bottom: 8, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.radiusMd),
            color: isDarkTheme
                ? const Color(0xFF182228)
                : const Color(0xFFFFF9E6),
            border: Border.all(
              color: isDarkTheme
                  ? const Color(0xFF233138)
                  : const Color(0xFFFFE082),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_rounded,
                size: 16,
                color: isDarkTheme
                    ? const Color(0xFFFFD279)
                    : const Color(0xFF8D6E63),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Messages and calls are end-to-end encrypted and private.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: isDarkTheme
                        ? const Color(0xFFFFD279)
                        : const Color(0xFF5D4037),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDarkTheme
                    ? const Color(0xFFFFD279)
                    : const Color(0xFF8D6E63),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
