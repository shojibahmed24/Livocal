import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/services/freelancer_profile_service.dart';
import 'package:livocal/features/freelancer/widgets/summary_sheet.dart';
import 'package:livocal/features/freelancer/widgets/tag_input_field.dart';
import 'package:livocal/theme/app_colors.dart';

/// Headline → availability fields of the freelancer profile form.
class ProfileFormFields extends StatelessWidget {
  final FreelancerProfile profile;
  final TextEditingController displayNameCtrl;
  final TextEditingController headlineCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController rateCtrl;
  final String Function(String key) t;
  final void Function(void Function(FreelancerProfile)) mutate;

  const ProfileFormFields({
    super.key,
    required this.profile,
    required this.displayNameCtrl,
    required this.headlineCtrl,
    required this.bioCtrl,
    required this.rateCtrl,
    required this.t,
    required this.mutate,
  });

  static const List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'BDT',
    'INR',
    'AED',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t('displayNameLabel'), muted),
        TextField(
          controller: displayNameCtrl,
          maxLength: 60,
          textInputAction: TextInputAction.next,
          scrollPadding: const EdgeInsets.only(bottom: 140),
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            counterText: '',
          ),
          style: TextStyle(fontSize: 13.5, color: textColor),
          onChanged: (value) {
            final next = value.trim();
            if (next.isNotEmpty) mutate((p) => p.displayName = next);
          },
        ),
        const SizedBox(height: 14),
        _label(t('headlineLabel'), muted),
        TextField(
          controller: headlineCtrl,
          maxLength: 80,
          textInputAction: TextInputAction.next,
          scrollPadding: const EdgeInsets.only(bottom: 140),
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            counterText: '',
          ),
          style: TextStyle(fontSize: 13.5, color: textColor),
          onChanged: (value) => mutate((p) => p.headline = value.trim()),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _label(t('bioLabel'), muted)),
            TextButton.icon(
              onPressed: () => _writeSummary(context),
              icon: const Icon(Icons.auto_awesome_outlined, size: 15),
              label: Text(
                t('summaryAi'),
                style: const TextStyle(fontSize: 11.5),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
        TextField(
          controller: bioCtrl,
          maxLines: 4,
          maxLength: 600,
          scrollPadding: const EdgeInsets.only(bottom: 180),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            counterText: '',
          ),
          style: TextStyle(fontSize: 13, color: textColor),
          onChanged: (value) => mutate((p) => p.bio = value.trim()),
        ),
        const SizedBox(height: 16),
        _label(t('skillsLabel'), muted),
        TagInputField(
          values: profile.skills,
          hint: t('addSkill'),
          addTooltip: t('addSkill'),
          onAdd: (value) => mutate((p) => p.skills = [...p.skills, value]),
          onRemove: (value) =>
              mutate((p) => p.skills = [...p.skills]..remove(value)),
        ),
        const SizedBox(height: 16),
        _label(t('languagesLabel'), muted),
        TagInputField(
          values: profile.languages,
          hint: t('addLanguage'),
          addTooltip: t('addLanguage'),
          display: (value) => value.replaceAll(':', ' · '),
          onAdd: (value) =>
              mutate((p) => p.languages = [...p.languages, value]),
          onRemove: (value) =>
              mutate((p) => p.languages = [...p.languages]..remove(value)),
        ),
        const SizedBox(height: 16),
        _label(t('rateLabel'), muted),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                scrollPadding: const EdgeInsets.only(bottom: 160),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined, size: 18),
                ),
                onChanged: (value) => mutate(
                  (p) => p.rateAmount = double.tryParse(value.trim()) ?? 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: _currencies.contains(profile.rateCurrency)
                    ? profile.rateCurrency
                    : 'USD',
                isDense: true,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: _currencies
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child:
                              Text(code, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  mutate((p) => p.rateCurrency = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _choiceRow(
          context,
          options: const [
            ('hourly', 'rateHourly'),
            ('project', 'rateProject'),
          ],
          selected: profile.rateBasis,
          onSelect: (value) => mutate((p) => p.rateBasis = value),
        ),
        const SizedBox(height: 16),
        _label(t('availabilityLabel'), muted),
        _choiceRow(
          context,
          options: const [
            (FreelancerProfileService.availabilityFullTime, 'availFullTime'),
            (FreelancerProfileService.availabilityPartTime, 'availPartTime'),
            (FreelancerProfileService.availabilityBusy, 'availBusy'),
          ],
          selected: profile.availability,
          onSelect: (value) => mutate((p) => p.availability = value),
        ),
      ],
    );
  }

  Future<void> _writeSummary(BuildContext context) async {
    if (profile.headline.trim().isEmpty && profile.skills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('summaryEmpty'))),
      );
      return;
    }
    final text = await showSummarySheet(
      context: context,
      profile: profile,
      t: t,
    );
    if (text == null) return;
    bioCtrl.text = text;
    mutate((p) => p.bio = text);
  }

  Widget _label(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Widget _choiceRow(
    BuildContext context, {
    required List<(String, String)> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.map((option) {
        final isSelected = option.$1 == selected;
        return ChoiceChip(
          label: Text(t(option.$2), style: const TextStyle(fontSize: 12)),
          selected: isSelected,
          onSelected: (_) => onSelect(option.$1),
          selectedColor: AppColors.primary.withValues(alpha: 0.18),
          side: BorderSide(
            color:
                isSelected ? AppColors.primary : Theme.of(context).dividerColor,
          ),
        );
      }).toList(),
    );
  }
}
