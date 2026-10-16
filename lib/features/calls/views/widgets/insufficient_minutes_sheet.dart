import 'package:flutter/material.dart';
import 'package:livocal/theme/app_colors.dart';

/// Modal bottom sheet shown when a user attempts an AI-translated call
/// but has 0 minutes remaining in their wallet.
class InsufficientMinutesSheet extends StatelessWidget {
  final VoidCallback onRechargePressed;
  final VoidCallback onCallWithoutTranslation;

  const InsufficientMinutesSheet({
    super.key,
    required this.onRechargePressed,
    required this.onCallWithoutTranslation,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRechargePressed,
    required VoidCallback onCallWithoutTranslation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsufficientMinutesSheet(
        onRechargePressed: onRechargePressed,
        onCallWithoutTranslation: onCallWithoutTranslation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1F2C34) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111B21);
    final secondaryText = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    color: Colors.amber,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'অনুবাদ মিনিট শেষ • Minutes Exhausted',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AI লাইভ অনুবাদ কলের জন্য মিনিট ব্যালেন্স প্রয়োজন',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Explanatory Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A3942) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'একই ভাষার সাধারণ কল সম্পূর্ণ ফ্রি! শুধুমাত্র ভিন্ন ভাষার রিয়েল-টাইম AI অনুবাদের ক্ষেত্রে মিনিট প্রযোজ্য।',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : const Color(0xFF3B4A54),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Package preview cards
            _buildBundleOption(
              context: context,
              title: 'স্টার্টার প্যাক (Starter)',
              minutes: '৬০ মিনিট',
              price: '৳১,২০০ (\$৯.৯৯)',
              isPopular: false,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildBundleOption(
              context: context,
              title: 'ফ্রিল্যান্সার প্রো (Pro)',
              minutes: '১৮০ মিনিট',
              price: '৳৩,০০০ (\$২৪.৯৯)',
              isPopular: true,
              isDark: isDark,
            ),

            const SizedBox(height: 18),

            // Primary Action: Buy Minutes
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRechargePressed();
              },
              icon: const Icon(Icons.flash_on_rounded, size: 20),
              label: const Text(
                'মিনিট রিচার্জ করুন • Buy Minutes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),

            const SizedBox(height: 10),

            // Secondary Action: Call Without Translation (Free)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onCallWithoutTranslation();
              },
              icon: const Icon(Icons.phone_outlined, size: 18),
              label: const Text(
                'অনুবাদ ছাড়া ফ্রি কল করুন • Call Free (No AI)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black87,
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBundleOption({
    required BuildContext context,
    required String title,
    required String minutes,
    required String price,
    required bool isPopular,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isPopular
            ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.08)
            : (isDark ? const Color(0xFF26343D) : Colors.grey[100]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'সেরা পছন্দ',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  minutes,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
