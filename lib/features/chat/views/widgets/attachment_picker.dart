import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/theme/theme.dart';

import '../../controllers/chat_controller.dart';
import 'package:whatsapp_clone/shared/utils/snackbars.dart';
import 'buttons.dart';

class AttachmentPicker extends ConsumerStatefulWidget {
  const AttachmentPicker({super.key});

  @override
  ConsumerState<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends ConsumerState<AttachmentPicker> {
  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 32.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: Theme.of(context).brightness == Brightness.dark
              ? colorTheme.appBarColor
              : colorTheme.backgroundColor,
        ),
        child: GridView.count(
          crossAxisCount: 3,
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          children: [
            LabelledButton(
              onTap: () async {
                Navigator.pop(context);
                ref
                    .read(chatControllerProvider.notifier)
                    .pickDocuments(context);
              },
              backgroundColor: Colors.deepPurpleAccent,
              label: 'Document',
              child: const Icon(
                Icons.insert_page_break,
                size: 28,
                color: Colors.white,
              ),
            ),
            LabelledButton(
              onTap: () async {
                Navigator.pop(context);
                ref
                    .read(chatControllerProvider.notifier)
                    .navigateToCameraView(context);
              },
              label: 'Camera',
              backgroundColor: Colors.redAccent[400],
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            LabelledButton(
              onTap: () async {
                Navigator.pop(context);
                ref
                    .read(chatControllerProvider.notifier)
                    .pickAttachmentsFromGallery(context);
              },
              label: 'Gallery',
              backgroundColor: Colors.purple[400],
              child: const Icon(
                Icons.photo_size_select_actual_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            if (Platform.isAndroid) ...[
              LabelledButton(
                onTap: () async {
                  Navigator.pop(context);
                  ref
                      .read(chatControllerProvider.notifier)
                      .pickAudioFiles(context);
                },
                label: 'Audio',
                backgroundColor: Colors.orange[900],
                child: const Icon(
                  Icons.headphones_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              )
            ],
            LabelledButton(
              onTap: () {
                Navigator.pop(context);
                showSnackBar(
                  context: context,
                  content: 'Live location sharing will be available in the upcoming update',
                  type: SnacBarType.info,
                );
              },
              label: 'Location',
              backgroundColor: Colors.green[600],
              child: const Icon(
                Icons.location_on,
                size: 28,
                color: Colors.white,
              ),
            ),
            LabelledButton(
              onTap: () {
                Navigator.pop(context);
                showSnackBar(
                  context: context,
                  content: 'Tap the \$ icon in the message bar to send USD payments',
                  type: SnacBarType.info,
                );
              },
              label: 'Payment',
              backgroundColor: Colors.teal[600],
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.attach_money_rounded,
                  size: 18,
                  color: Colors.teal,
                ),
              ),
            ),
            LabelledButton(
              onTap: () async {
                Navigator.pop(context);
                showSnackBar(
                  context: context,
                  content: 'Select contact from the Contacts tab to start a conversation',
                  type: SnacBarType.info,
                );
              },
              label: 'Contact',
              backgroundColor: Colors.blue[600],
              child: const Icon(
                Icons.person,
                size: 28,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
