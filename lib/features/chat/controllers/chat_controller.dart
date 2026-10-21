import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:livocal/features/chat/models/message.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/compression_service.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/repositories/upload_service.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/attachment_utils.dart';
import 'package:livocal/shared/utils/storage_paths.dart';
import 'package:livocal/shared/widgets/camera.dart';

import '../../../shared/repositories/download_service.dart';
import '../../../shared/repositories/push_notifications.dart';
import '../../../shared/utils/abc.dart';
import '../../../shared/utils/shared_pref.dart';
import '../../../shared/widgets/gallery.dart';
import '../models/attachement.dart';
import '../views/attachment_sender.dart';

final chatControllerProvider =
    StateNotifierProvider.autoDispose<ChatStateNotifier, ChatState>(
  (ref) => ChatStateNotifier(ref: ref),
);

enum RecordingState {
  notRecording,
  recording,
  recordingLocked,
  paused,
}

class ChatState {
  ChatState({
    this.hideElements = false,
    this.recordingState = RecordingState.notRecording,
    this.showScrollBtn = false,
    this.unreadCount = 0,
    this.showEmojiPicker = false,
    this.replyingMessage,
    required this.recordingSamples,
    required this.soundRecorder,
    required this.messageController,
    required this.fieldFocusNode,
  });

  final bool hideElements;
  final RecordingState recordingState;
  final TextEditingController messageController;
  final FocusNode fieldFocusNode;
  final FlutterSoundRecorder soundRecorder;
  final bool showScrollBtn;
  final int unreadCount;
  final List<RecordingDisposition> recordingSamples;
  final bool showEmojiPicker;
  final Message? replyingMessage;

  void dispose() {
    fieldFocusNode.dispose();
    messageController.dispose();
    soundRecorder.closeRecorder();
  }

  ChatState copyWith({
    bool? hideElements,
    RecordingState? recordingState,
    bool? showScrollBtn,
    int? unreadCount,
    bool? showEmojiPicker,
    List<RecordingDisposition>? recordingSamples,
    Message? replyingMessage,
    bool clearReplying = false,
  }) {
    return ChatState(
      hideElements: hideElements ?? this.hideElements,
      recordingState: recordingState ?? this.recordingState,
      showScrollBtn: showScrollBtn ?? this.showScrollBtn,
      unreadCount: unreadCount ?? this.unreadCount,
      showEmojiPicker: showEmojiPicker ?? this.showEmojiPicker,
      messageController: messageController,
      fieldFocusNode: fieldFocusNode,
      soundRecorder: soundRecorder,
      recordingSamples: recordingSamples ?? this.recordingSamples,
      replyingMessage:
          clearReplying ? null : (replyingMessage ?? this.replyingMessage),
    );
  }
}

class ChatStateNotifier extends StateNotifier<ChatState> {
  ChatStateNotifier({required this.ref})
      : super(
          ChatState(
            messageController: TextEditingController(),
            fieldFocusNode: FocusNode(),
            soundRecorder: FlutterSoundRecorder(logLevel: Level.error),
            recordingSamples: [],
          ),
        );

  final AutoDisposeStateNotifierProviderRef ref;

  void setReplyingMessage(Message? message) {
    state = state.copyWith(replyingMessage: message);
    if (message != null) {
      state.fieldFocusNode.requestFocus();
    }
  }

  void clearReplyingMessage() {
    state = state.copyWith(clearReplying: true);
  }
  User? _self;
  User? _other;
  String? _otherUserContactName;

  User get self =>
      _self ??
      getCurrentUser() ??
      User(
        id: '',
        name: 'Me',
        avatarUrl: '',
        phone: Phone(code: '', number: '', formattedNumber: ''),
        activityStatus: UserActivityStatus.offline,
      );
  set self(User val) => _self = val;

  User get other =>
      _other ??
      User(
        id: '',
        name: 'Status',
        avatarUrl: '',
        phone: Phone(code: '', number: '', formattedNumber: ''),
        activityStatus: UserActivityStatus.offline,
      );
  set other(User val) => _other = val;

  String get otherUserContactName => _otherUserContactName ?? other.name;
  set otherUserContactName(String val) => _otherUserContactName = val;

  StreamSubscription<RecordingDisposition>? recordingStream;

  void initUsers(User self, User other, String otherUserContactName) {
    _self = self;
    _other = other;
    _otherUserContactName = otherUserContactName;
    IsarDb.saveUser(self);
    IsarDb.saveUser(other);
  }

  bool _isRecorderInited = false;

  Future<void> initRecorder() async {
    if (_isRecorderInited) return;
    try {
      await state.soundRecorder.openRecorder();
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth |
                AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      state.soundRecorder.setSubscriptionDuration(
        const Duration(milliseconds: 120),
      );
      _isRecorderInited = true;
    } catch (e) {
      debugPrint('[ChatController] initRecorder error: $e');
    }
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  void navigateToHome(BuildContext context) {
    Navigator.pop(context);
  }

  void setRecordingState(RecordingState recordingState) {
    state = state.copyWith(recordingState: recordingState);
  }

  Future<void> pauseRecording() async {
    await state.soundRecorder.pauseRecorder();
    setRecordingState(RecordingState.paused);
  }

  Future<void> resumeRecording() async {
    await state.soundRecorder.resumeRecorder();
    setRecordingState(RecordingState.recordingLocked);
  }

  Future<void> cancelRecording() async {
    await state.soundRecorder.stopRecorder();
    recordingStream?.cancel();
    recordingStream = null;
    state = state.copyWith(
      recordingSamples: [],
      recordingState: RecordingState.notRecording,
    );
  }

  Future<void> startRecording() async {
    if (!await hasPermission(Permission.microphone)) return;
    try {
      if (!_isRecorderInited) {
        await initRecorder();
      }
      if (state.soundRecorder.isRecording) {
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final audioPath =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      await state.soundRecorder.startRecorder(
        codec: Codec.aacADTS,
        sampleRate: 44100,
        bitRate: 48000,
        toFile: audioPath,
      );

      recordingStream = state.soundRecorder.onProgress!.listen(
        recordingListener,
      );
      setRecordingState(RecordingState.recording);
    } catch (e, st) {
      debugPrint('[ChatController] startRecording error: $e\n$st');
      setRecordingState(RecordingState.notRecording);
    }
  }

  Future<void> startRecordingLocked() async {
    await startRecording();
    if (state.recordingState == RecordingState.recording) {
      setRecordingState(RecordingState.recordingLocked);
    }
  }

  void recordingListener(RecordingDisposition data) {
    state = state.copyWith(
      recordingSamples: state.recordingSamples..add(data),
    );
  }

  Future<void> onMicDragLeft(double dx, double deviceWidth) async {
    if (dx > deviceWidth * 0.6) return;

    await state.soundRecorder.stopRecorder();
    setRecordingState(RecordingState.notRecording);
  }

  Future<void> onMicDragUp(double dy, double deviceHeight) async {
    if (dy > deviceHeight - 100 ||
        state.recordingState == RecordingState.recordingLocked) {
      return;
    }

    setRecordingState(RecordingState.recordingLocked);
  }

  Future<void> onRecordingDone() async {
    try {
      final path = await state.soundRecorder.stopRecorder();
      recordingStream?.cancel();
      recordingStream = null;

      final samples = state.recordingSamples.map((e) => e.decibels ?? 0).toList();

      state = state.copyWith(
        recordingSamples: [],
        recordingState: RecordingState.notRecording,
      );

      if (path == null || path.isEmpty) return;
      final recordedFile = File(path);
      if (!recordedFile.existsSync()) return;

      final messageId = const Uuid().v4();
      final timestamp = Timestamp.now();
      final ext = path.split(".").last;
      final fileName = "AUD_${timestamp.seconds}.$ext";

      final savedFilePath = DeviceStorage.getMediaFilePath(fileName);
      final savedFile = await recordedFile.copy(savedFilePath);

      final senderId = ref.read(chatControllerProvider.notifier).self.id;
      final receiverId = ref.read(chatControllerProvider.notifier).other.id;

      ref.read(chatControllerProvider.notifier).sendMessageWithAttachments(
            Message(
              id: messageId,
              content: "",
              status: MessageStatus.pending,
              senderId: senderId,
              receiverId: receiverId,
              timestamp: timestamp,
              attachment: Attachment(
                type: AttachmentType.voice,
                url: "",
                fileName: fileName,
                fileSize: savedFile.existsSync() ? savedFile.lengthSync() : recordedFile.lengthSync(),
                fileExtension: ext,
                uploadStatus: UploadStatus.uploading,
                autoDownload: true,
                file: savedFile,
                samples: samples,
              ),
            ),
          );
    } catch (e, st) {
      debugPrint('[ChatController] onRecordingDone error: $e\n$st');
      state = state.copyWith(
        recordingSamples: [],
        recordingState: RecordingState.notRecording,
      );
    }
  }

  void onTextChanged(String value) {
    if (value.isEmpty) {
      state = state.copyWith(hideElements: false);
    } else if (value != ' ') {
      state = state.copyWith(hideElements: true);
    } else {
      state.messageController.text = "";
    }
  }

  void toggleScrollBtnVisibility() {
    state = state.copyWith(showScrollBtn: !state.showScrollBtn);
  }

  void setUnreadCount(int count) {
    if (state.unreadCount == count) return;
    state = state.copyWith(unreadCount: count);
  }

  void setShowEmojiPicker(bool shouldShowEmojiPicker) {
    state = state.copyWith(showEmojiPicker: shouldShowEmojiPicker);
  }

  void onSendBtnPressed(WidgetRef ref, User sender, User receiver) async {
    String textContent = state.messageController.text.trim();
    if (textContent.isEmpty) return;

    if (state.replyingMessage != null) {
      final replyMsg = state.replyingMessage!;
      final isSelf = replyMsg.senderId == sender.id;
      final senderLabel = isSelf ? 'You' : (_other?.name ?? 'Contact');
      String snippet = replyMsg.content.trim();
      if (snippet.startsWith('💬 Replying to @')) {
        final newlineIdx = snippet.indexOf('\n');
        if (newlineIdx != -1) {
          snippet = snippet.substring(newlineIdx + 1).trim();
        }
      }
      if (snippet.isEmpty && replyMsg.attachment != null) {
        snippet = replyMsg.attachment!.fileName.isNotEmpty
            ? replyMsg.attachment!.fileName
            : replyMsg.attachment!.type.name;
      }
      if (snippet.length > 60) {
        snippet = '${snippet.substring(0, 57)}...';
      }
      textContent = '💬 Replying to @$senderLabel: "$snippet"\n$textContent';
      clearReplyingMessage();
    }

    final chatId = getChatId(sender.id, receiver.id);
    final disappearingTimer = SharedPref.instance.getString('chat_disappearing_$chatId') ??
        SharedPref.instance.getString('contact_disappearing_${receiver.id}') ??
        SharedPref.instance.getString('privacy_disappearing') ??
        'Off';

    Timestamp? expiresAt;
    if (disappearingTimer == '24 hours') {
      expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));
    } else if (disappearingTimer == '7 days') {
      expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)));
    } else if (disappearingTimer == '90 days') {
      expiresAt = Timestamp.fromDate(DateTime.now().add(const Duration(days: 90)));
    }

    sendMessageNoAttachments(
      Message(
        id: const Uuid().v4(),
        content: textContent,
        status: MessageStatus.pending,
        senderId: sender.id,
        receiverId: receiver.id,
        timestamp: Timestamp.now(),
        expiresAt: expiresAt,
        disappearingDuration: disappearingTimer != 'Off' ? disappearingTimer : null,
      ),
    );

    state.messageController.text = "";
    state = state.copyWith(
      hideElements: false,
    );
  }

  Future<void> sendMessageNoAttachments(Message message) async {
    if (_other != null) await IsarDb.saveUser(_other!);
    await IsarDb.addMessage(message);

    // Delay for smooth animation
    Future.delayed(const Duration(milliseconds: 300), () {
      ref
          .read(firebaseFirestoreRepositoryProvider)
          .sendMessage(message.copyWith(status: MessageStatus.sent))
          .then((_) {
        IsarDb.updateMessage(message.id, status: MessageStatus.sent);
        ref.read(pushNotificationsRepoProvider).sendPushNotification(message);
      }).catchError((e) {
        debugPrint('Message saved locally; sending offline (status pending): $e');
        IsarDb.updateMessage(message.id, status: MessageStatus.pending);
      });
    });
  }

  Future<void> retrySendMessage(Message message) async {
    try {
      await ref
          .read(firebaseFirestoreRepositoryProvider)
          .sendMessage(message.copyWith(status: MessageStatus.sent));
      await IsarDb.updateMessage(message.id, status: MessageStatus.sent);
      ref.read(pushNotificationsRepoProvider).sendPushNotification(message);
    } catch (e) {
      debugPrint('[ChatController] Retry sending message failed: $e');
      await IsarDb.updateMessage(message.id, status: MessageStatus.pending);
    }
  }

  static bool _isFlushingPending = false;

  /// Flushes pending offline messages across all chats upon network recovery or app resume.
  Future<void> flushPendingOutbox() async {
    if (_isFlushingPending) return;
    _isFlushingPending = true;
    try {
      final pendingMessages = await IsarDb.getPendingMessages();
      if (pendingMessages.isEmpty) return;
      debugPrint('[ChatController] Flushing ${pendingMessages.length} pending offline messages');
      for (final msg in pendingMessages) {
        if (msg.attachment == null) {
          await retrySendMessage(msg);
        } else if (msg.attachment!.uploadStatus == UploadStatus.uploaded &&
            (msg.attachment!.url.isNotEmpty)) {
          await retrySendMessage(msg);
        }
      }
    } catch (e) {
      debugPrint('[ChatController] flushPendingOutbox error: $e');
    } finally {
      _isFlushingPending = false;
    }
  }

  void sendMessageWithAttachments(Message message) async {
    if (_other != null) await IsarDb.saveUser(_other!);
    if ({
      AttachmentType.document,
      AttachmentType.audio,
      AttachmentType.voice,
      AttachmentType.video
    }.contains(message.attachment!.type)) {
      message.attachment!.uploadStatus = UploadStatus.preparing;
      await IsarDb.addMessage(message);

      message.attachment!.uploadStatus = UploadStatus.uploading;
      await uploadAttachment(message);
      await IsarDb.updateMessage(message.id, attachment: message.attachment);
      return;
    }

    message.attachment!.uploadStatus = UploadStatus.preparing;
    await IsarDb.addMessage(message);

    await compressAttachment(message);
    await uploadAttachment(message);
  }

  Future<void> uploadAttachment(Message message) async {
    await UploadService.upload(
      taskId: message.id,
      file: message.attachment!.file!,
      path:
          'attachments/${message.senderId}/${message.receiverId}/${message.attachment!.fileName}',
      onUploadDone: (snapshot) async =>
          await uploadCompleteHandler(snapshot, message),
      onUploadError: () async => await stopUpload(message),
    );

    message.attachment!.uploadStatus = UploadStatus.uploading;
    await IsarDb.updateMessage(message.id, attachment: message.attachment);
  }

  Future<void> uploadCompleteHandler(
    TaskSnapshot snapshot,
    Message message,
  ) async {
    final url = await snapshot.ref.getDownloadURL();

    ref
        .read(firebaseFirestoreRepositoryProvider)
        .sendMessage(
          message
            ..status = MessageStatus.sent
            ..attachment!.url = url
            ..attachment!.uploadStatus = UploadStatus.uploaded,
        )
        .then((_) async {
      await IsarDb.updateMessage(
        message.id,
        status: MessageStatus.sent,
        attachment: message.attachment!
          ..url = url
          ..uploadStatus = UploadStatus.uploaded,
      );

      ref.read(pushNotificationsRepoProvider).sendPushNotification(message);
    }).catchError((e) {
      debugPrint('Media message upload complete but firestore send failed: $e');
      IsarDb.updateMessage(message.id, status: MessageStatus.pending);
    });
  }

  Future<void> stopUpload(Message message) async {
    if (message.attachment!.uploadStatus == UploadStatus.notUploading) {
      return;
    }

    await UploadService.cancelUpload(message.id);
    await IsarDb.updateMessage(
      message.id,
      attachment: message.attachment!..uploadStatus = UploadStatus.notUploading,
    );
  }

  Future<void> downloadAttachment(
    Message message,
    void Function(TaskSnapshot) onComplete,
    void Function() onError,
  ) async {
    await DownloadService.download(
      taskId: message.id,
      url: message.attachment!.url,
      path: DeviceStorage.getMediaFilePath(message.attachment!.fileName),
      onDownloadComplete: onComplete,
      onDownloadError: onError,
    );
  }

  Future<void> cancelDownload(Message message) async {
    await DownloadService.cancelDownload(message.id);
  }

  Future<void> compressAttachment(Message message) async {
    final compressedFile = await CompressionService.compressImage(
      message.attachment!.file!,
    );

    await compressedFile.copy(
      DeviceStorage.getMediaFilePath(
        message.attachment!.fileName,
      ),
    );

    message.attachment!.file = compressedFile;
    message.attachment!.fileSize = await compressedFile.length();
    message.attachment!.fileExtension = compressedFile.path.split('.').last;
  }

  Future<void> markMessageAsSeen(Message message) async {
    ref
        .read(firebaseFirestoreRepositoryProvider)
        .sendSystemMessage(
          message: SystemMessage(
            targetId: message.id,
            action: MessageAction.statusUpdate,
            update: MessageStatus.seen.value,
          ),
          receiverId: message.senderId,
        )
        .then((value) {
      IsarDb.updateMessage(message.id, status: MessageStatus.seen);
    });
  }

  Future<void> navigateToCameraView(BuildContext context) async {
    if (!await hasPermission(Permission.camera)) return;
    if (!context.mounted) return;
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CameraView(cameras: cameras)),
    );
  }

  Future<List<Attachment>?> pickAttachmentsFromGallery(
    BuildContext context, {
    bool returnAttachments = false,
  }) async {
    bool hasAccess = false;
    try {
      if (Platform.isAndroid) {
        final ps = await PhotoManager.requestPermissionExtend();
        hasAccess = ps.isAuth || ps.hasAccess;
      } else {
        hasAccess = await hasPermission(Permission.photos);
      }
    } catch (e, st) {
      debugPrint('[ChatController] PhotoManager permission check error: $e\n$st');
      hasAccess = true;
    }

    if (!context.mounted) return null;

    if (hasAccess && Platform.isAndroid) {
      try {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Gallery(
              title: 'Send to $otherUserContactName',
            ),
          ),
        );
        return null;
      } catch (e) {
        debugPrint('Gallery opening failed, falling back to picker: $e');
      }
    }

    // Seamless fallback to system image picker
    final key = showLoading(context);
    try {
      List<File>? files = await pickMultimedia();
      if (files == null || files.isEmpty) return null;

      final attachmentsFuture = createAttachmentsFromFiles(files);
      if (returnAttachments) {
        return await attachmentsFuture;
      }

      if (!mounted || !context.mounted) return null;
      navigateToAttachmentSender(context, attachmentsFuture);
      return null;
    } catch (e) {
      debugPrint('Error in pickAttachmentsFromGallery: $e');
      return null;
    } finally {
      if (context.mounted && key.currentContext != null) {
        Navigator.pop(key.currentContext!);
      }
    }
  }

  Future<void> pickAudioFiles(
    BuildContext context,
  ) async {
    final key = showLoading(context);
    try {
      List<File>? files = await pickFiles(type: FileType.audio);
      if (files == null || files.isEmpty) return;

      final attachmentsFuture = createAttachmentsFromFiles(files);

      if (!mounted || !context.mounted) return;
      navigateToAttachmentSender(context, attachmentsFuture);
    } catch (e) {
      debugPrint('Error in pickAudioFiles: $e');
    } finally {
      if (context.mounted && key.currentContext != null) {
        Navigator.pop(key.currentContext!);
      }
    }
  }

  Future<List<Attachment>?> pickDocuments(
    BuildContext context, {
    bool returnAttachments = false,
  }) async {
    final key = showLoading(context);
    try {
      List<File>? files = await pickFiles(type: FileType.any);
      if (files == null || files.isEmpty) return null;

      final attachmentsFuture = createAttachmentsFromFiles(
        files,
        areDocuments: true,
      );

      if (returnAttachments) {
        return await attachmentsFuture;
      }

      if (!mounted || !context.mounted) return null;
      navigateToAttachmentSender(context, attachmentsFuture);
      return null;
    } catch (e) {
      debugPrint('Error in pickDocuments: $e');
      return null;
    } finally {
      if (context.mounted && key.currentContext != null) {
        Navigator.pop(key.currentContext!);
      }
    }
  }

  GlobalKey showLoading(context) {
    final dialogKey = GlobalKey();
    showAppProgressDialog(
      context: context,
      message: 'Preparing media',
      key: dialogKey,
    );
    return dialogKey;
  }

  Future<List<Attachment>> createAttachmentsFromFiles(
    List<File> files, {
    bool areDocuments = false,
  }) async {
    return await Future.wait(
      files.map((file) async {
        final type = areDocuments
            ? AttachmentType.document
            : AttachmentType.fromValue(
                lookupMimeType(file.path)?.split("/")[0].toUpperCase() ??
                    'DOCUMENT',
              );

        double? width, height;
        if (type == AttachmentType.image) {
          (width, height) = await getImageDimensions(File(file.path));
        } else if (type == AttachmentType.video) {
          (width, height) = await getVideoDimensions(File(file.path));
        }

        final fileName = file.path.split("/").last;

        return Attachment(
          type: type,
          url: "",
          autoDownload:
              type == AttachmentType.image || type == AttachmentType.voice,
          fileName: fileName,
          fileSize: await file.length(),
          fileExtension: fileName.split(".").last,
          width: width,
          height: height,
          file: file,
        );
      }),
    );
  }

  void navigateToAttachmentSender(
    BuildContext context,
    Future<List<Attachment>> attachments,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttachmentMessageSender(
          attachmentsFuture: attachments,
        ),
      ),
    );
  }
}
