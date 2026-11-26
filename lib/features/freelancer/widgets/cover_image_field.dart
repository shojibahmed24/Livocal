import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/services/profile_image_service.dart';
import 'package:livocal/theme/app_colors.dart';

/// Picks a cover image from the phone and uploads it to Storage.
class CoverImageField extends StatefulWidget {
  final FreelancerProfile profile;
  final String Function(String key) t;
  final void Function(void Function(FreelancerProfile)) mutate;

  const CoverImageField({
    super.key,
    required this.profile,
    required this.t,
    required this.mutate,
  });

  @override
  State<CoverImageField> createState() => _CoverImageFieldState();
}

class _CoverImageFieldState extends State<CoverImageField> {
  bool _uploading = false;

  Future<void> _pick() async {
    if (_uploading) return;
    HapticFeedback.lightImpact();
    try {
      final picked = await ProfileImageService.pick();
      if (picked == null) return;

      setState(() => _uploading = true);
      final url = await ProfileImageService.upload(
        ownerUid: widget.profile.ownerUid,
        prefix: 'cover',
        image: picked,
      );
      widget.mutate((p) => p.coverUrl = url);
    } catch (e) {
      debugPrint('[CoverImageField] upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.t('imageUploadFailed')} ($e)'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final hasCover = widget.profile.coverUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.t('coverImage').toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              image: hasCover
                  ? DecorationImage(
                      image: NetworkImage(widget.profile.coverUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasCover
                ? null
                : Icon(Icons.image_outlined, size: 30, color: muted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pick,
                  icon: _uploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library_outlined, size: 16),
                  label: Text(
                    _uploading
                        ? widget.t('uploadingImage')
                        : widget.t('chooseImage'),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ),
              ),
              if (hasCover) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _uploading
                      ? null
                      : () => widget.mutate((p) => p.coverUrl = ''),
                  tooltip: widget.t('removeImage'),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: muted,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
