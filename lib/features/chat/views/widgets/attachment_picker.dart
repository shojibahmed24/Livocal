import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/theme/design_tokens.dart';
import 'package:livocal/theme/theme.dart';

import '../../controllers/chat_controller.dart';
import 'buttons.dart';

class AttachmentPicker extends ConsumerWidget {
  const AttachmentPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            color: isDark ? colorTheme.appBarColor : colorTheme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  LabelledButton(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      ref
                          .read(chatControllerProvider.notifier)
                          .pickDocuments(context);
                    },
                    backgroundColor: const Color(0xFF6750A4),
                    label: 'Document',
                    child: const Icon(
                      Icons.description_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  LabelledButton(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      ref
                          .read(chatControllerProvider.notifier)
                          .navigateToCameraView(context);
                    },
                    label: 'Camera',
                    backgroundColor: const Color(0xFFB3261E),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  LabelledButton(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      ref
                          .read(chatControllerProvider.notifier)
                          .pickAttachmentsFromGallery(context);
                    },
                    label: 'Gallery',
                    backgroundColor: const Color(0xFF9C27B0),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                  LabelledButton(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      ref
                          .read(chatControllerProvider.notifier)
                          .pickAudioFiles(context);
                    },
                    label: 'Audio',
                    backgroundColor: const Color(0xFFE65100),
                    child: const Icon(
                      Icons.headphones_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}
