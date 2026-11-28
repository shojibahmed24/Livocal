import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/services/ai_summary_service.dart';
import 'package:livocal/theme/app_colors.dart';

/// Bottom sheet that drafts the CV summary with AI and returns it on accept.
Future<String?> showSummarySheet({
  required BuildContext context,
  required FreelancerProfile profile,
  required String Function(String key) t,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SummarySheet(profile: profile, t: t),
  );
}

class _SummarySheet extends StatefulWidget {
  final FreelancerProfile profile;
  final String Function(String key) t;

  const _SummarySheet({required this.profile, required this.t});

  @override
  State<_SummarySheet> createState() => _SummarySheetState();
}

class _SummarySheetState extends State<_SummarySheet> {
  static const List<String> _tones = ['professional', 'concise', 'friendly'];
  static const Map<String, String> _toneKeys = {
    'professional': 'summaryProfessional',
    'concise': 'summaryConcise',
    'friendly': 'summaryFriendly',
  };

  String _tone = 'professional';
  String _text = '';
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final text = await AiSummaryService.generate(
      profile: widget.profile,
      tone: _tone,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _text = text ?? '';
      _failed = text == null;
    });
  }

  Future<void> _selectTone(String tone) async {
    if (tone == _tone) return;
    setState(() => _tone = tone);
    await _generate();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.t('summaryTitle'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            widget.t('summarySub'),
            style: TextStyle(fontSize: 11.5, color: muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final tone in _tones)
                ChoiceChip(
                  label: Text(
                    widget.t(_toneKeys[tone]!),
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: tone == _tone,
                  onSelected: _loading ? null : (_) => _selectTone(tone),
                  selectedColor: AppColors.primary.withValues(alpha: 0.18),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 108),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _loading
                ? Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.t('summaryGenerating'),
                          style: TextStyle(fontSize: 12.5, color: muted),
                        ),
                      ),
                    ],
                  )
                : _failed
                    ? Text(
                        widget.t('summaryFailed'),
                        style: TextStyle(fontSize: 12.5, color: muted),
                      )
                    : SelectableText(
                        _text,
                        style: const TextStyle(fontSize: 13.5, height: 1.5),
                      ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.t('summaryAiNote'),
            style: TextStyle(fontSize: 10.5, color: muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: Text(
                    widget.t('summaryRegenerate'),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _loading || _text.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_text),
                  child: Text(
                    widget.t('summaryUse'),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
