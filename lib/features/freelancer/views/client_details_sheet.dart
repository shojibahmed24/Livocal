import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:livocal/features/freelancer/models/crm_entry.dart';
import 'package:livocal/features/freelancer/services/crm_service.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Client-details sheet for the freelancer CRM (tag, stage, rate, notes,
/// follow-up). Everything is saved locally first and mirrored to Firestore.
Future<void> showClientDetailsSheet(
  BuildContext context, {
  required String ownerUid,
  required String peerUid,
  required String peerName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ClientDetailsSheet(
      ownerUid: ownerUid,
      peerUid: peerUid,
      peerName: peerName,
    ),
  );
}

class ClientDetailsSheet extends StatefulWidget {
  final String ownerUid;
  final String peerUid;
  final String peerName;

  const ClientDetailsSheet({
    super.key,
    required this.ownerUid,
    required this.peerUid,
    required this.peerName,
  });

  @override
  State<ClientDetailsSheet> createState() => _ClientDetailsSheetState();
}

class _ClientDetailsSheetState extends State<ClientDetailsSheet> {
  final TextEditingController _rateCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  CrmEntry? _entry;
  Timer? _saveTimer;
  bool _loading = true;
  bool _savedRecently = false;

  static const List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'BDT',
    'INR',
    'AED'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _rateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _load() async {
    unawaited(CrmService.refresh(widget.ownerUid, widget.peerUid));
    final entry = await CrmService.ensure(widget.ownerUid, widget.peerUid);
    if (!mounted) return;
    setState(() {
      _entry = entry;
      if (entry.rateAmount > 0) {
        _rateCtrl.text = entry.rateAmount % 1 == 0
            ? entry.rateAmount.toInt().toString()
            : entry.rateAmount.toString();
      }
      _loading = false;
    });
  }

  void _mutate(void Function(CrmEntry entry) change) {
    final entry = _entry;
    if (entry == null) return;
    HapticFeedback.selectionClick();
    setState(() => change(entry));
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _persist);
  }

  Future<void> _persist() async {
    final entry = _entry;
    if (entry == null) return;
    await CrmService.save(entry);
    if (!mounted) return;
    setState(() => _savedRecently = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _savedRecently = false);
  }

  List<Map<String, String>> get _notes {
    final entry = _entry;
    if (entry == null) return const [];
    return entry.notes.map<Map<String, String>>((raw) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return {
          'text': (map['text'] ?? '').toString(),
          'at': (map['at'] ?? '').toString(),
        };
      } catch (_) {
        return {'text': raw, 'at': ''};
      }
    }).toList();
  }

  void _addNote() {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty || _entry == null) return;
    final note = jsonEncode({
      'text': text,
      'at': DateTime.now().toIso8601String(),
    });
    _noteCtrl.clear();
    _mutate((entry) => entry.notes = [...entry.notes, note]);
  }

  Future<void> _pickFollowUp() async {
    final entry = _entry;
    if (entry == null) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: entry.followUpAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    _mutate(
      (e) => e.followUpAt = DateTime(picked.year, picked.month, picked.day, 9),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final entry = _entry;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _loading || entry == null
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (_savedRecently)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                _t('saved'),
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
                      _t('clientDetails'),
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                    const SizedBox(height: 16),
                    _label(_t('tagLabel'), muted),
                    _choiceRow(
                      options: const [
                        (CrmService.tagProspect, 'tagProspect'),
                        (CrmService.tagClient, 'tagClient'),
                        (CrmService.tagArchived, 'tagArchived'),
                      ],
                      selected: entry.tag,
                      onSelect: (value) => _mutate((e) => e.tag = value),
                    ),
                    const SizedBox(height: 14),
                    _label(_t('stageLabel'), muted),
                    _choiceRow(
                      options: const [
                        (CrmService.stageNew, 'stageNew'),
                        (CrmService.stageNegotiating, 'stageNegotiating'),
                        (CrmService.stageActive, 'stageActive'),
                        (CrmService.stagePaid, 'stagePaid'),
                      ],
                      selected: entry.stage,
                      onSelect: (value) => _mutate((e) => e.stage = value),
                    ),
                    const SizedBox(height: 16),
                    _label(_t('rateLabel'), muted),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _rateCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              prefixIcon:
                                  Icon(Icons.payments_outlined, size: 18),
                            ),
                            onChanged: (value) {
                              final amount = double.tryParse(value.trim()) ?? 0;
                              _mutate((e) => e.rateAmount = amount);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                _currencies.contains(entry.rateCurrency)
                                    ? entry.rateCurrency
                                    : 'USD',
                            isDense: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: _currencies
                                .map(
                                  (code) => DropdownMenuItem(
                                    value: code,
                                    child: Text(code,
                                        style: const TextStyle(fontSize: 13)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              _mutate((e) => e.rateCurrency = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _choiceRow(
                      options: const [
                        (CrmService.basisHourly, 'rateHourly'),
                        (CrmService.basisProject, 'rateProject'),
                      ],
                      selected: entry.rateBasis,
                      onSelect: (value) => _mutate((e) => e.rateBasis = value),
                    ),
                    const SizedBox(height: 18),
                    _label(_t('notesLabel'), muted),
                    if (_notes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _t('noNotes'),
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      )
                    else
                      ..._notes.reversed.take(4).map(
                            (note) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      note['text'] ?? '',
                                      style: TextStyle(
                                          fontSize: 12.5, color: textColor),
                                    ),
                                    if ((note['at'] ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          _formatDate(
                                            DateTime.tryParse(note['at']!) ??
                                                DateTime.now(),
                                          ),
                                          style: TextStyle(
                                              fontSize: 10, color: muted),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteCtrl,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: _t('addNote'),
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addNote(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addNote,
                          icon: const Icon(Icons.add_circle_rounded),
                          color: AppColors.primary,
                          tooltip: _t('addNote'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label(_t('followUpLabel'), muted),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _pickFollowUp,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: (isDark
                                      ? Colors.white24
                                      : Colors.black12),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.followUpAt == null
                                        ? _t('noFollowUp')
                                        : _formatDate(entry.followUpAt!),
                                    style: TextStyle(
                                        fontSize: 12.5, color: textColor),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (entry.followUpAt != null)
                          IconButton(
                            onPressed: () =>
                                _mutate((e) => e.followUpAt = null),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: _t('noFollowUp'),
                          ),
                      ],
                    ),
                    if (entry.lastContactedAt != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${_t('lastContacted')}: ${_formatDate(entry.lastContactedAt!)}',
                        style: TextStyle(fontSize: 11.5, color: muted),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
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

  Widget _choiceRow({
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
          label: Text(_t(option.$2), style: const TextStyle(fontSize: 12)),
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
