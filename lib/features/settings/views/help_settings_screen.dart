import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/utils/app_dialog.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/snackbars.dart';
import 'package:livocal/shared/widgets/settings_row.dart';
import 'package:livocal/theme/app_colors.dart';

class HelpSettingsScreen extends ConsumerWidget {
  const HelpSettingsScreen({super.key});

  void _showContactUsDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    bool isSubmitting = false;
    void Function(void Function())? dialogStateSetter;

    showAppDialog(
      context: context,
      title: AppStrings.tr(ref, 'contactSupport'),
      icon: Icons.support_agent_outlined,
      barrierDismissible: false,
      content: StatefulBuilder(
        builder: (ctx, setDialogState) {
          dialogStateSetter = setDialogState;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(ref, 'contactSupportDesc'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 4,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  hintText: AppStrings.tr(ref, 'typeYourMessage'),
                  border: const OutlineInputBorder(),
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
          label: AppStrings.tr(ref, 'cancel').toUpperCase(),
          onPressed: () => Navigator.pop(context),
        ),
        AppDialogAction(
          label: AppStrings.tr(ref, 'submit'),
          isPrimary: true,
          onPressed: () async {
            final message = textController.text.trim();
            if (message.isEmpty) {
              showSnackBar(
                context: context,
                content: AppStrings.tr(ref, 'enterMessageError'),
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
                  content: AppStrings.tr(ref, 'feedbackSentSuccess'),
                  type: SnacBarType.info,
                );
              }
            } catch (e) {
              debugPrint('HelpSettingsScreen sendFeedback error: $e');
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

  void _showAppInfoDialog(BuildContext context, WidgetRef ref) {
    showAppDialog(
      context: context,
      title: AppStrings.tr(ref, 'aboutLivocal'),
      icon: Icons.bolt_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Livocal for Android',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Version 1.0.0 (Production Build 2026.10.15)'),
          const SizedBox(height: 12),
          Text(
            AppStrings.tr(ref, 'appInfoDesc'),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Text('© 2026 Livocal Inc. All rights reserved.'),
        ],
      ),
      actions: [
        AppDialogAction(
          label: AppStrings.tr(ref, 'close'),
          isPrimary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.tr(ref, 'help'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          SettingsSectionHeader(title: AppStrings.tr(ref, 'supportAndKnowledge')),
          SettingsRow(
            icon: Icons.help_center_outlined,
            title: AppStrings.tr(ref, 'helpCentre'),
            subtitle: AppStrings.tr(ref, 'helpCentreSub'),
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
            title: AppStrings.tr(ref, 'contactSupport'),
            subtitle: AppStrings.tr(ref, 'contactSupportSub'),
            onTap: () => _showContactUsDialog(context, ref),
          ),
          SettingsSectionHeader(title: AppStrings.tr(ref, 'legalAndInfo')),
          SettingsRow(
            icon: Icons.privacy_tip_outlined,
            title: AppStrings.tr(ref, 'termsAndPrivacy'),
            subtitle: AppStrings.tr(ref, 'termsAndPrivacySub'),
            onTap: () {
              bool isBnSelected = false;
              showAppDialog(
                context: context,
                title: AppStrings.tr(ref, 'termsAndPrivacy'),
                icon: Icons.privacy_tip_outlined,
                content: StatefulBuilder(
                  builder: (ctx, setContentState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ChoiceChip(
                              label: const Text('English', style: TextStyle(fontSize: 12)),
                              selected: !isBnSelected,
                              onSelected: (val) => setContentState(() => isBnSelected = !val),
                              selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('বাংলা', style: TextStyle(fontSize: 12)),
                              selected: isBnSelected,
                              onSelected: (val) => setContentState(() => isBnSelected = val),
                              selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isBnSelected
                              ? 'Livocal আপনার গোপনীয়তাকে সর্বোচ্চ অগ্রাধিকার দেয়:\n\n'
                                '১. ব্যক্তিগত এনক্রিপশন: আপনার প্রতিটি ব্যক্তিগত কল ও চ্যাট মেসেজ সম্পূর্ণরূপে সুরক্ষিত।\n\n'
                                '২. জেমিনি লাইভ অনুবাদ: লাইভ ভয়েস অনুবাদ শুধুমাত্র সক্রিয় কলের সময় ক্ষণস্থায়ী সুরক্ষিত মেমরিতে প্রক্রিয়া করা হয়, কখনোই এটি স্থায়ীভাবে রেকর্ড বা এআই প্রশিক্ষণে ব্যবহৃত হয় না।\n\n'
                                '৩. সুরক্ষিত কন্টাক্ট ম্যাচিং: আপনার সম্পূর্ণ ফোনবুক সার্ভারে আপলোড না করে ক্রিপ্টোগ্রাফিক হ্যাশ লুকআপের মাধ্যমে নিবন্ধিত ব্যবহারকারী শনাক্ত করা হয়।'
                              : 'Livocal values your privacy:\n\n'
                                '1. Private Encryption: Your 1-on-1 calls and messages are strictly protected.\n\n'
                                '2. Gemini Live Translation: Voice streams are processed in ephemeral secure memory during active calls and are never stored or trained on.\n\n'
                                '3. Zero Phonebook Harvesting: Contact matching occurs via cryptographic hash lookups without uploading your unhashed address book.',
                          style: const TextStyle(fontSize: 13.5, height: 1.45),
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  AppDialogAction(
                    label: AppStrings.tr(ref, 'onlinePolicy'),
                    isPrimary: true,
                    onPressed: () async {
                      final uri = Uri.parse(AppConfig.privacyPolicyUrl);
                      try {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } catch (e) {
                        debugPrint('HelpSettingsScreen launch privacy URL error: $e');
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
                    label: AppStrings.tr(ref, 'iUnderstand'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 1),
          SettingsRow(
            icon: Icons.info_outline,
            title: AppStrings.tr(ref, 'appInfo'),
            subtitle: 'Livocal v1.0.0',
            onTap: () => _showAppInfoDialog(context, ref),
          ),
        ],
      ),
    );
  }
}

class FAQScreen extends ConsumerWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          AppStrings.tr(ref, 'faqTitle'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          ExpansionTile(
            title: Text(AppStrings.tr(ref, 'faqLiveTranslationQ')),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  AppStrings.tr(ref, 'faqLiveTranslationA'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(AppStrings.tr(ref, 'faqSecurityQ')),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  AppStrings.tr(ref, 'faqSecurityA'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(AppStrings.tr(ref, 'faqContactsQ')),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  AppStrings.tr(ref, 'faqContactsA'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(AppStrings.tr(ref, 'faqApiKeyQ')),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  AppStrings.tr(ref, 'faqApiKeyA'),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
