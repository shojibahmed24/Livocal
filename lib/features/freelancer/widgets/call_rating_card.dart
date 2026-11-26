import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/services/review_service.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Post-call rating (1–5 stars plus optional comment).
class CallRatingCard extends StatefulWidget {
  final String callId;
  final String targetUid;
  final String targetName;

  const CallRatingCard({
    super.key,
    required this.callId,
    required this.targetUid,
    required this.targetName,
  });

  @override
  State<CallRatingCard> createState() => _CallRatingCardState();
}

class _CallRatingCardState extends State<CallRatingCard> {
  final TextEditingController _comment = TextEditingController();

  int _rating = 0;
  bool _sending = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _done = ReviewService.alreadyReviewed(widget.callId);
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _submit() async {
    if (_rating < 1 || _sending) return;
    setState(() => _sending = true);
    final ok = await ReviewService.submit(
      callId: widget.callId,
      targetUid: widget.targetUid,
      rating: _rating,
      comment: _comment.text,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _done = true;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('reviewFailed')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              _t('reviewThanks'),
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: muted.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_t('rateCall')} · ${widget.targetName}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _t('rateCallSub'),
            style: TextStyle(fontSize: 10.5, color: muted),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= _rating;
              return IconButton(
                onPressed:
                    _sending ? null : () => setState(() => _rating = value),
                tooltip: '$value',
                icon: Icon(
                  selected ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 28,
                  color: selected ? Colors.amber : muted,
                ),
              );
            }),
          ),
          TextField(
            controller: _comment,
            maxLength: 300,
            decoration: InputDecoration(
              isDense: true,
              hintText: _t('guestNote'),
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating < 1 || _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_t('submitRating')),
            ),
          ),
        ],
      ),
    );
  }
}
