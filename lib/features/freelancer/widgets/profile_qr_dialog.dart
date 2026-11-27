import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:livocal/theme/app_colors.dart';

/// Scannable QR for the public profile link.
Future<void> showProfileQrDialog(
  BuildContext context, {
  required String url,
  required String name,
  required String Function(String key) t,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('profileQrTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 210,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            url,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            Navigator.of(ctx).pop();
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: Text(t('copyProfileLink')),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => Share.share(url, subject: name),
          icon: const Icon(Icons.ios_share_rounded, size: 16),
          label: Text(t('shareLink')),
        ),
      ],
    ),
  );
}
