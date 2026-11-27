import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Copy / share / open actions for the public profile link.
class ProfileLinkActions {
  ProfileLinkActions._();

  static Future<void> copy(
    BuildContext context,
    String url,
    String Function(String key) t,
  ) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('linkCopied')), duration: const Duration(seconds: 2)),
    );
  }

  static Future<void> share(String url, String name) {
    return Share.share(url, subject: name);
  }

  static Future<void> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
