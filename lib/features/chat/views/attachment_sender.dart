import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:livocal/features/chat/views/widgets/attachment_renderers.dart';
import 'package:livocal/features/chat/views/widgets/chat_field.dart';
import 'package:livocal/shared/widgets/bottom_inset.dart';
import 'package:livocal/theme/app_colors.dart';
import 'package:livocal/theme/design_tokens.dart';
import 'package:livocal/theme/theme.dart';
import 'package:livocal/shared/utils/snackbars.dart';

import '../../../shared/models/user.dart';
import '../../../shared/utils/abc.dart';
import '../../../shared/utils/shared_pref.dart';
import '../../../shared/utils/storage_paths.dart';
import '../controllers/chat_controller.dart';
import '../models/attachement.dart';
import '../models/message.dart';

class AttachmentMessageSender extends ConsumerStatefulWidget {
  const AttachmentMessageSender({
    super.key,
    required this.attachmentsFuture,
    this.tags,
  });

  final Future<List<Attachment>> attachmentsFuture;
  final List<String>? tags;

  @override
  ConsumerState<AttachmentMessageSender> createState() =>
      _AttachmentMessageSenderState();
}

class _AttachmentMessageSenderState
    extends ConsumerState<AttachmentMessageSender> {
  late User self;
  late User other;
  late Attachment current;
  List<TextEditingController> controllers = [];
  List<Attachment> attachments = [];
  late StreamSubscription<bool> keyboardListener;
  late final attachmentsFuture = awaitAttachments();
  bool isKeyboardVisible = false;

  @override
  void initState() {
    self = ref.read(chatControllerProvider.notifier).self;
    other = ref.read(chatControllerProvider.notifier).other;

    keyboardListener = KeyboardVisibilityController().onChange.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          isKeyboardVisible = event;
        });
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    keyboardListener.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> awaitAttachments() async {
    final list = await widget.attachmentsFuture;
    if (list.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    attachments = [...list];
    controllers = attachments.map((_) => TextEditingController()).toList();
    current = attachments[0];
  }

  Future<void> addNewAttachments() async {
    List<Attachment>? newAttachments;
    if (current.type == AttachmentType.document) {
      newAttachments =
          await ref.read(chatControllerProvider.notifier).pickDocuments(
                context,
                returnAttachments: true,
              );
    } else {
      if (Platform.isAndroid) {
        Navigator.pop(context, attachments);
        return;
      }
      newAttachments = await ref
          .read(chatControllerProvider.notifier)
          .pickAttachmentsFromGallery(
            context,
            returnAttachments: true,
          );
    }

    if (newAttachments == null) return;
    setState(() {
      attachments.addAll(newAttachments!);
      controllers.addAll(
        List.generate(
          newAttachments.length,
          (_) => TextEditingController(),
        ),
      );
    });
  }

  Future<void> sendAttachments() async {
    if (other.id.isEmpty) {
      if (mounted) {
        showSnackBar(
          context: context,
          content: 'Open a chat or select a contact to send attachments',
          type: SnacBarType.info,
        );
      }
      return;
    }

    for (var i = 0; i < controllers.length; i++) {
      final attachment = attachments[i];

      String messageId = const Uuid().v4();
      String msgContent = controllers[i].text.trim();
      if (msgContent.isEmpty && attachment.type == AttachmentType.document) {
        msgContent = "\u00A0";
      }

      await attachment.file!.copy(
        DeviceStorage.getMediaFilePath(
          attachment.fileName,
        ),
      );

      final chatId = getChatId(self.id, other.id);
      final disappearingTimer = SharedPref.instance.getString('chat_disappearing_$chatId') ??
          SharedPref.instance.getString('contact_disappearing_${other.id}') ??
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

      ref.read(chatControllerProvider.notifier).sendMessageWithAttachments(
            Message(
              id: messageId,
              content: msgContent,
              status: MessageStatus.pending,
              senderId: self.id,
              receiverId: other.id,
              timestamp: Timestamp.now(),
              expiresAt: expiresAt,
              disappearingDuration: disappearingTimer != 'Off' ? disappearingTimer : null,
              attachment: attachment..uploadStatus = UploadStatus.uploading,
            ),
          );
    }

    if (!mounted) return;
    try {
      Navigator.of(context).popUntil((route) => route.settings.name == 'chat');
    } catch (e, st) {
      debugPrint('[AttachmentMessageSender] popUntil route error: $e\n$st');
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void removeSelectedAttachment() {
    if (attachments.length == 1) {
      Navigator.pop(context, []);
      return;
    }
    setState(() {
      final idx = attachments.indexOf(current);
      attachments.removeAt(idx);
      controllers[idx].dispose();
      controllers.removeAt(idx);

      if (widget.tags != null) {
        widget.tags!.removeAt(idx);
      }

      current = attachments.first;
    });
  }

  void selectAttachment(Attachment attachment) {
    setState(() {
      current = attachment;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        Navigator.of(context).pop(attachments);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? colorTheme.backgroundColor
            : const Color.fromARGB(236, 225, 233, 235),
        body: Stack(
          children: [
            FutureBuilder(
                future: attachmentsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final currentType = current.type;
                  final currentImageRenderer = AttachmentRenderer(
                    attachment: current.file!,
                    attachmentType: currentType,
                    fit: BoxFit.contain,
                    controllable: true,
                  );

                  return Stack(
                    children: [
                      Center(
                        child: KeyboardDismissOnTap(
                          child: widget.tags != null
                              ? Hero(
                                  tag: widget
                                      .tags![attachments.indexOf(current)],
                                  child: currentImageRenderer,
                                )
                              : currentImageRenderer,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: AvoidBottomInset(
                          conditions: const [false],
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Offstage(
                                offstage: isKeyboardVisible,
                                child: Preview(
                                  attachments: attachments,
                                  current: current,
                                  onAttachmentClicked: selectAttachment,
                                  onDeleteClicked: removeSelectedAttachment,
                                ),
                              ),
                              Column(children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: ChatField(
                                    textController: controllers[
                                        attachments.indexOf(current)],
                                    leading: GestureDetector(
                                      onTap: addNewAttachments,
                                      child: Icon(
                                        Icons.add_box_rounded,
                                        size: 24.0,
                                        color: colorTheme.greyColor,
                                      ),
                                    ),
                                    actions: const [],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  color: const Color.fromARGB(152, 0, 0, 0),
                                  child: SafeArea(
                                    top: false,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? colorTheme.appBarColor
                                                  : const Color.fromARGB(
                                                      255, 242, 251, 254),
                                              borderRadius:
                                                  BorderRadius.circular(AppRadius.large),
                                            ),
                                            child: Text(
                                              other.name,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black87,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(24),
                                              onTap: () {
                                                HapticFeedback.lightImpact();
                                                sendAttachments();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors.primary,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.primary.withValues(alpha: 0.35),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.send,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(attachments),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(140, 0, 0, 0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Preview extends StatelessWidget {
  const Preview({
    super.key,
    required this.attachments,
    required this.current,
    required this.onDeleteClicked,
    required this.onAttachmentClicked,
  });

  final List<Attachment> attachments;
  final Attachment current;
  final VoidCallback onDeleteClicked;
  final Function(Attachment) onAttachmentClicked;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: SizedBox(
          height: 60,
          child: ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            itemCount: attachments.length,
            itemBuilder: (context, idx) {
              final attachment = attachments[idx];
              final attachmentType = attachment.type;

              return Center(
                child: GestureDetector(
                    onTap: () => onAttachmentClicked(attachment),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: current == attachment
                            ? Border.all(
                                color: Colors.white,
                                width: 2,
                              )
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 50,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: AttachmentRenderer(
                                  attachment: attachment.file!,
                                  attachmentType: attachmentType,
                                  fit: BoxFit.cover,
                                  compact: true,
                                ),
                              ),
                            ),
                            if (current == attachment) ...[
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.black38,
                                child: GestureDetector(
                                  onTap: onDeleteClicked,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )),
              );
            },
            separatorBuilder: (context, idx) {
              return const SizedBox(width: 6);
            },
          ),
        ),
      ),
    );
  }
}
