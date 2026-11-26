import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/services/profile_image_service.dart';
import 'package:livocal/shared/utils/app_localizations.dart';

/// Collects one case study (with an uploaded image).
Future<Map<String, String>?> showCaseStudyDialog(
  BuildContext context, {
  required String ownerUid,
  Map<String, String>? existing,
}) {
  final lang = Localizations.localeOf(context).languageCode;
  String t(String key) => AppStrings.get(key, lang);
  final title = TextEditingController(text: existing?['title'] ?? '');
  final client = TextEditingController(text: existing?['client'] ?? '');
  final problem = TextEditingController(text: existing?['problem'] ?? '');
  final result = TextEditingController(text: existing?['result'] ?? '');
  final url = TextEditingController(text: existing?['url'] ?? '');
  final tags = TextEditingController(text: existing?['tags'] ?? '');
  var imageUrl = existing?['imageUrl'] ?? '';
  var uploading = false;

  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        Widget field(TextEditingController c, String key, {int lines = 1}) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: c,
              maxLines: lines,
              decoration: InputDecoration(isDense: true, labelText: t(key)),
            ),
          );
        }

        Future<void> pickImage() async {
          try {
            final picked = await ProfileImageService.pick();
            if (picked == null) return;
            setState(() => uploading = true);
            final uploaded = await ProfileImageService.upload(
              ownerUid: ownerUid,
              prefix: 'case',
              image: picked,
            );
            if (ctx.mounted) setState(() => imageUrl = uploaded);
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('${t('imageUploadFailed')} ($e)')),
              );
            }
          } finally {
            if (ctx.mounted) setState(() => uploading = false);
          }
        }

        return AlertDialog(
          title: Text(t('addCaseStudy')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(title, 'caseTitle'),
                field(client, 'caseClient'),
                field(problem, 'caseProblem', lines: 2),
                field(result, 'caseResult', lines: 2),
                field(url, 'caseLink'),
                field(tags, 'caseTags'),
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: uploading ? null : pickImage,
                    icon: uploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      uploading ? t('uploadingImage') : t('chooseImage'),
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final value = title.text.trim();
                if (value.isEmpty) return;
                Navigator.of(ctx).pop({
                  'title': value,
                  'client': client.text.trim(),
                  'problem': problem.text.trim(),
                  'result': result.text.trim(),
                  'imageUrl': imageUrl,
                  'url': url.text.trim(),
                  'tags': tags.text.trim(),
                });
              },
              child: Text(t('save')),
            ),
          ],
        );
      },
    ),
  );
}
