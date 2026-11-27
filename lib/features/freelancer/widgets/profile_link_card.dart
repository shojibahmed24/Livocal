import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Published-state card: public URL plus copy / share / preview actions.
class ProfileLinkCard extends StatelessWidget {
  final String url;
  final bool published;
  final String Function(String key) t;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onPreview;
  final VoidCallback onRegenerate;
  final VoidCallback onQr;
  final VoidCallback onGuestCall;

  const ProfileLinkCard({
    super.key,
    required this.url,
    required this.published,
    required this.t,
    required this.onCopy,
    required this.onShare,
    required this.onPreview,
    required this.onRegenerate,
    required this.onQr,
    required this.onGuestCall,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                published
                    ? Icons.public_rounded
                    : Icons.visibility_off_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  published ? t('profileLinkLabel') : t('publishPage'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              InkWell(
                onTap: onQr,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.qr_code_2_rounded, size: 17, color: muted),
                ),
              ),
              if (published)
                InkWell(
                  onTap: onRegenerate,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.autorenew_rounded,
                      size: 17,
                      color: muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: muted),
          ),
          if (published) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _action(Icons.copy_rounded, t('copyProfileLink'), onCopy),
                _action(Icons.ios_share_rounded, t('shareLink'), onShare),
                _action(Icons.open_in_new_rounded, t('previewPage'), onPreview),
                _action(Icons.mic_none_rounded, t('guestCall'), onGuestCall),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
