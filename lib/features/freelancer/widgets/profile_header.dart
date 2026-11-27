import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/widgets/profile_link_card.dart';
import 'package:livocal/features/freelancer/widgets/username_editor.dart';

/// Link card plus the server-managed rating row.
class ProfileHeader extends StatelessWidget {
  final FreelancerProfile profile;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onPreview;
  final VoidCallback onRegenerate;
  final VoidCallback onQr;
  final VoidCallback onUpdated;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onUpdated,
    required this.onCopy,
    required this.onShare,
    required this.onPreview,
    required this.onRegenerate,
    required this.onQr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UsernameEditor(
          profile: profile,
          t: t,
          textColor: textColor,
          muted: muted,
          onUpdated: onUpdated,
        ),
        const SizedBox(height: 12),
        ProfileLinkCard(
          url: profile.publicUrl,
          published: profile.published,
          t: t,
          onCopy: onCopy,
          onShare: onShare,
          onPreview: onPreview,
          onRegenerate: onRegenerate,
          onQr: onQr,
        ),
        if (profile.ratingCount > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 17, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${profile.ratingAvg.toStringAsFixed(1)} · '
                '${profile.ratingCount}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              if (profile.viewCount > 0) ...[
                const SizedBox(width: 12),
                Icon(Icons.visibility_outlined, size: 14, color: muted),
                const SizedBox(width: 3),
                Text(
                  '${profile.viewCount}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ],
            ],
          ),
        ] else if (profile.viewCount > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 14, color: muted),
              const SizedBox(width: 4),
              Text(
                '${profile.viewCount}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
