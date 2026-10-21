import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livocal/features/calls/models/call_language.dart';
import 'package:livocal/features/calls/repositories/call_repository.dart';
import 'package:livocal/features/calls/views/outgoing_call_screen.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/firebase_firestore.dart';
import 'package:livocal/theme/app_colors.dart';

/// Smart routing entry point for all outgoing calls.
/// If caller and callee speak the same language:
///   -> Dials immediately as a 100% Free Direct Voice Call with zero popup!
/// If caller and callee speak different languages:
///   -> Displays an elegant bottom sheet asking if user wants AI Live Voice Translation.
Future<void> initiateSmartCall(
  BuildContext context,
  WidgetRef ref, {
  required User caller,
  required User callee,
  required String calleeDisplayName,
  bool? forceTranslation,
}) async {
  // 1. Resolve Caller's Spoken Language
  String callerLangCode = caller.spokenLanguage.trim();
  if (callerLangCode.isEmpty) {
    callerLangCode = CallRepository.getMyLanguageCode();
  }
  if (callerLangCode.isEmpty) {
    callerLangCode = 'bn';
  }

  // 2. Resolve Callee's Spoken Language
  String calleeLangCode = callee.spokenLanguage.trim();
  if (calleeLangCode.isEmpty || calleeLangCode == 'bn') {
    // Check if callee has a registered Firestore profile with explicit language
    try {
      final fsRepo = ref.read(firebaseFirestoreRepositoryProvider);
      final fetchedCallee = await fsRepo.getUserById(callee.id);
      if (fetchedCallee != null && fetchedCallee.spokenLanguage.isNotEmpty) {
        calleeLangCode = fetchedCallee.spokenLanguage;
      }
    } catch (_) {}
  }
  if (calleeLangCode.isEmpty) {
    calleeLangCode = 'bn';
  }

  // If forceTranslation is explicitly set, bypass detection modal and use specified setting
  if (forceTranslation != null) {
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          caller: caller,
          callee: callee,
          calleeDisplayName: calleeDisplayName,
          overrideMyLangCode: callerLangCode,
          overridePeerLangCode: calleeLangCode,
          initialTranslationEnabled: forceTranslation,
        ),
      ),
    );
    return;
  }

  // 3. Normalization (e.g. 'bn-BD' vs 'bn' are both Bengali)
  final isSameLang = CallLanguageRegistry.isSameLanguageFamily(callerLangCode, calleeLangCode);

  if (isSameLang) {
    // Both users speak the same language: 100% Automatic Free Direct Voice Call!
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OutgoingCallScreen(
          caller: caller,
          callee: callee,
          calleeDisplayName: calleeDisplayName,
          overrideMyLangCode: callerLangCode,
          overridePeerLangCode: calleeLangCode,
          initialTranslationEnabled: false,
        ),
      ),
    );
    return;
  }

  // Different languages detected: Show smart confirmation bottom sheet
  if (!context.mounted) return;
  final callerLang = CallLanguageRegistry.fromCode(callerLangCode);
  final calleeLang = CallLanguageRegistry.fromCode(calleeLangCode);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DifferentLanguageCallSheet(
      caller: caller,
      callee: callee,
      calleeDisplayName: calleeDisplayName,
      callerLang: callerLang,
      calleeLang: calleeLang,
    ),
  );
}

class DifferentLanguageCallSheet extends StatelessWidget {
  final User caller;
  final User callee;
  final String calleeDisplayName;
  final CallLanguage callerLang;
  final CallLanguage calleeLang;

  const DifferentLanguageCallSheet({
    super.key,
    required this.caller,
    required this.callee,
    required this.calleeDisplayName,
    required this.callerLang,
    required this.calleeLang,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B2730) : Colors.white;
    final cardColor = isDark ? const Color(0xFF101D25) : const Color(0xFFF0F4F8);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Different Language Detected',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ভাষার ভিন্নতা পাওয়া গেছে',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Comparison Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Caller language
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'You Speak',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          callerLang.flagEmoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          callerLang.nativeName,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Arrow Indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),

                  // Callee language
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$calleeDisplayName Speaks',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          calleeLang.flagEmoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          calleeLang.nativeName,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Descriptive prompt text
            Text(
              '$calleeDisplayName speaks ${calleeLang.nativeName} (${calleeLang.englishName}), while you speak ${callerLang.nativeName}. Would you like to call with real-time AI Voice Translation?',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 12.5,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Option 1: Call with Gemini AI Live Translation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text(
                  'Call with AI Voice Translation',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OutgoingCallScreen(
                        caller: caller,
                        callee: callee,
                        calleeDisplayName: calleeDisplayName,
                        overrideMyLangCode: callerLang.code,
                        overridePeerLangCode: calleeLang.code,
                        initialTranslationEnabled: true,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Option 2: Direct Voice Call (Free)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.call_rounded, size: 18),
                label: const Text(
                  'Direct Voice Call (Free)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OutgoingCallScreen(
                        caller: caller,
                        callee: callee,
                        calleeDisplayName: calleeDisplayName,
                        overrideMyLangCode: callerLang.code,
                        overridePeerLangCode: calleeLang.code,
                        initialTranslationEnabled: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
