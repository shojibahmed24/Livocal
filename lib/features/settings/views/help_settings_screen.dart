import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';

class HelpSettingsScreen extends StatelessWidget {
  const HelpSettingsScreen({super.key});

  void _showContactUsDialog(BuildContext context) {
    final textController = TextEditingController();
    bool isSubmitting = false;
    void Function(void Function())? dialogStateSetter;

    showAppDialog(
      context: context,
      title: 'Contact Support',
      icon: Icons.support_agent_outlined,
      barrierDismissible: false,
      content: StatefulBuilder(
        builder: (ctx, setDialogState) {
          dialogStateSetter = setDialogState;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us how we can help you. Describe your issue or suggestion:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                enabled: !isSubmitting,
                decoration: const InputDecoration(
                  hintText: 'Type your message here...',
                  border: OutlineInputBorder(),
                ),
              ),
              if (isSubmitting) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        AppDialogAction(
          label: 'CANCEL',
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: 'SUBMIT',
          isPrimary: true,
          onPressed: () async {
            final message = textController.text.trim();
            if (message.isEmpty) {
              showSnackBar(
                context: context,
                content: 'Please enter a message before submitting.',
                type: SnacBarType.error,
              );
              return;
            }

            dialogStateSetter?.call(() => isSubmitting = true);
            try {
              final user = FirebaseAuth.instance.currentUser;
              await FirebaseFirestore.instance.collection('feedback').add({
                'userId': user?.uid ?? 'anonymous',
                'phoneNumber': user?.phoneNumber ?? '',
                'message': message,
                'platform': Platform.operatingSystem,
                'appVersion': '1.0.0',
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                showSnackBar(
                  context: context,
                  content:
                      'Thank you! Your feedback has been sent to the Livocal engineering team.',
                  type: SnacBarType.info,
                );
              }
            } catch (e) {
              dialogStateSetter?.call(() => isSubmitting = false);
              if (context.mounted) {
                showSnackBar(
                  context: context,
                  content: 'Failed to send feedback: $e',
                  type: SnacBarType.error,
                );
              }
            }
          },
        ),
      ],
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showAppDialog(
      context: context,
      title: 'About Livocal',
      icon: Icons.bolt_rounded,
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Livocal for Android',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text('Version 1.0.0 (Production Build 2026.10.15)'),
          SizedBox(height: 12),
          Text(
            'Real-Time AI Voice Translation & Secure Messaging powered by WebRTC, Gemini Multimodal Live API, and Flutter.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          SizedBox(height: 12),
          Text('© 2026 Livocal Inc. All rights reserved.'),
        ],
      ),
      actions: [
        AppDialogAction(
          label: 'CLOSE',
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Help',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SettingsSectionHeader(title: 'Support & Knowledge'),
          SettingsRow(
            icon: Icons.help_center_outlined,
            title: 'Help Centre',
            subtitle: 'FAQs, user guides, troubleshooting',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FAQScreen()),
              );
            },
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.support_agent_outlined,
            title: 'Contact us',
            subtitle: 'Questions? Need help? Reach our team',
            onTap: () => _showContactUsDialog(context),
          ),
          const SettingsSectionHeader(title: 'Legal & Info'),
          SettingsRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Terms and Privacy Policy',
            subtitle: 'Private communication & zero-knowledge policy',
            onTap: () {
              showAppDialog(
                context: context,
                title: 'Terms & Privacy',
                icon: Icons.privacy_tip_outlined,
                content: const Text(
                  'Livocal values your privacy:\n\n'
                  '1. Private Encryption: Your 1-on-1 calls and messages are strictly protected.\n\n'
                  '2. Gemini Live Translation: Voice streams are processed in ephemeral secure memory during active calls and are never stored or trained on.\n\n'
                  '3. Zero Phonebook Harvesting: Contact matching occurs via cryptographic hash lookups without uploading your unhashed address book.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                actions: [
                  AppDialogAction(
                    label: 'ONLINE POLICY',
                    isPrimary: true,
                    onPressed: () async {
                      final uri = Uri.parse(AppConfig.privacyPolicyUrl);
                      try {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) {
                          showSnackBar(
                            context: context,
                            content: 'Could not open privacy policy URL: $uri',
                            type: SnacBarType.error,
                          );
                        }
                      }
                    },
                  ),
                  AppDialogAction(
                    label: 'I UNDERSTAND',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.info_outline,
            title: 'App info',
            subtitle: 'Livocal v1.0.0',
            onTap: () => _showAppInfoDialog(context),
          ),
        ],
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Help Centre & FAQs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: const [
          ExpansionTile(
            title: Text('How does Real-Time AI Live Translation work?'),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'During a voice call, Livocal streams raw audio via WebRTC. When AI translation is toggled on, speech is streamed to the Gemini Multimodal Live API which translates bidirectional speech with sub-second latency.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Are my voice calls and messages encrypted?'),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Yes! All WebRTC audio streams use DTLS-SRTP encryption, and all chat messages are authenticated with zero-trust Firestore security rules.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How do I add or invite contacts?'),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Tap the floating action button on the home screen to open Contacts. You can tap any contact registered on Livocal to chat or call immediately, or tap "Invite" to send an SMS invitation.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How do I configure my Gemini API Key?'),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Go to Settings > Gemini Live Voice Translation. You can enter your personal Gemini API key from Google AI Studio, select your preferred voice (Puck, Charon, Kore, Fenrir, Aoede), and save securely.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
