import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/widgets/profile_link_card.dart';

/// Link card plus the server-managed rating row.
class ProfileHeader extends StatelessWidget {
  final FreelancerProfile profile;
  final String Function(String key) t;
  final Color textColor;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onPreview;
  final VoidCallback onRegenerate;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.t,
    required this.textColor,
    required this.onCopy,
    required this.onShare,
    required this.onPreview,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileLinkCard(
          url: profile.publicUrl,
          published: profile.published,
          t: t,
          onCopy: onCopy,
          onShare: onShare,
          onPreview: onPreview,
          onRegenerate: onRegenerate,
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
            ],
          ),
        ],
      ],
    );
  }
}
