import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/utils/snackbars.dart';

class HelpSettingsScreen extends StatelessWidget {
  const HelpSettingsScreen({super.key});

  void _showContactUsDialog(BuildContext context) {
    final textController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
          title: const Text('Contact Support'),
          content: Column(
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A884)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final message = textController.text.trim();
                      if (message.isEmpty) {
                        showSnackBar(
                          context: context,
                          content: 'Please enter a message before submitting.',
                          type: SnacBarType.error,
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
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
                          Navigator.pop(ctx);
                          showSnackBar(
                            context: context,
                            content: 'Thank you! Your feedback has been sent to the Livocal engineering team.',
                            type: SnacBarType.info,
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (context.mounted) {
                          showSnackBar(
                            context: context,
                            content: 'Failed to send feedback: $e',
                            type: SnacBarType.error,
                          );
                        }
                      }
                    },
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF00A884),
              radius: 16,
              child: Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            SizedBox(width: 10),
            Text('About Livocal'),
          ],
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF00A884);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.help_center_outlined, color: primaryColor),
            title: const Text('Help Centre'),
            subtitle: const Text('FAQs, user guides, troubleshooting'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FAQScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.support_agent_outlined, color: primaryColor),
            title: const Text('Contact us'),
            subtitle: const Text('Questions? Need help? Reach our team'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showContactUsDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: primaryColor),
            title: const Text('Terms and Privacy Policy'),
            subtitle: const Text('Private communication & zero-knowledge policy'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? const Color(0xFF1F2C34) : Colors.white,
                  title: const Text('Terms & Privacy'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Livocal values your privacy:\n\n'
                      '1. Private Encryption: Your 1-on-1 calls and messages are strictly protected.\n\n'
                      '2. Gemini Live Translation: Voice streams are processed in ephemeral secure memory during active calls and are never stored or trained on.\n\n'
                      '3. Zero Phonebook Harvesting: Contact matching occurs via cryptographic hash lookups without uploading your unhashed address book.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        final uri = Uri.parse(AppConfig.privacyPolicyUrl);
                        try {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                      child: const Text('OPEN ONLINE POLICY', style: TextStyle(color: Color(0xFF00A884))),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('I UNDERSTAND'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.info_outline, color: primaryColor),
            title: const Text('App info'),
            subtitle: const Text('Livocal v1.0.0'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Centre & FAQs'),
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
