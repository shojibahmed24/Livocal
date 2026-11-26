import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/crm_entry.dart';
import 'package:livocal/features/freelancer/services/crm_service.dart';
import 'package:livocal/features/freelancer/widgets/crm_notes_list.dart';
import 'package:livocal/theme/app_colors.dart';

/// Tag / stage / rate / notes block of the CRM sheet.
class ClientDetailsForm extends StatelessWidget {
  final CrmEntry entry;
  final String peerName;
  final bool savedRecently;
  final TextEditingController rateCtrl;
  final TextEditingController noteCtrl;
  final List<Map<String, String>> notes;
  final String Function(String key) t;
  final void Function(void Function(CrmEntry)) mutate;
  final VoidCallback onAddNote;

  const ClientDetailsForm({
    super.key,
    required this.entry,
    required this.peerName,
    required this.savedRecently,
    required this.rateCtrl,
    required this.noteCtrl,
    required this.notes,
    required this.t,
    required this.mutate,
    required this.onAddNote,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                peerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            if (savedRecently)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t('saved'),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          t('clientDetails'),
          style: TextStyle(fontSize: 12.5, color: muted),
        ),
        const SizedBox(height: 16),
        _label(t('tagLabel'), muted),
        _choiceRow(
          context,
          options: const [
            (CrmService.tagProspect, 'tagProspect'),
            (CrmService.tagClient, 'tagClient'),
            (CrmService.tagArchived, 'tagArchived'),
          ],
          selected: entry.tag,
          onSelect: (value) => mutate((e) => e.tag = value),
        ),
        const SizedBox(height: 14),
        _label(t('stageLabel'), muted),
        _choiceRow(
          context,
          options: const [
            (CrmService.stageNew, 'stageNew'),
            (CrmService.stageNegotiating, 'stageNegotiating'),
            (CrmService.stageActive, 'stageActive'),
            (CrmService.stagePaid, 'stagePaid'),
          ],
          selected: entry.stage,
          onSelect: (value) => mutate((e) => e.stage = value),
        ),
        const SizedBox(height: 16),
        _label(t('rateLabel'), muted),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: rateCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments_outlined, size: 18),
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value.trim()) ?? 0;
                  mutate((e) => e.rateAmount = amount);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: _currencies.contains(entry.rateCurrency)
                    ? entry.rateCurrency
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
                  mutate((e) => e.rateCurrency = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _choiceRow(
          context,
          options: const [
            (CrmService.basisHourly, 'rateHourly'),
            (CrmService.basisProject, 'rateProject'),
          ],
          selected: entry.rateBasis,
          onSelect: (value) => mutate((e) => e.rateBasis = value),
        ),
        const SizedBox(height: 18),
        _label(t('notesLabel'), muted),
        CrmNotesList(
          notes: notes,
          t: t,
          textColor: textColor,
          muted: muted,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: noteCtrl,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: t('addNote'),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onAddNote(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onAddNote,
              icon: const Icon(Icons.add_circle_rounded),
              color: AppColors.primary,
              tooltip: t('addNote'),
            ),
          ],
        ),
      ],
    );
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
