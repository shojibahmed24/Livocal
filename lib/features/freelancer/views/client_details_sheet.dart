import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:livocal/features/freelancer/models/crm_entry.dart';
import 'package:livocal/features/freelancer/services/crm_service.dart';
import 'package:livocal/features/freelancer/widgets/client_details_form.dart';
import 'package:livocal/features/freelancer/widgets/follow_up_field.dart';
import 'package:livocal/shared/utils/app_localizations.dart';

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
  bool _savedRecently = false;

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

  @override
  Widget build(BuildContext context) {
    final entry = _entry;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: entry == null
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClientDetailsForm(
                      entry: entry,
                      peerName: widget.peerName,
                      savedRecently: _savedRecently,
                      rateCtrl: _rateCtrl,
                      noteCtrl: _noteCtrl,
                      notes: _notes,
                      t: _t,
                      mutate: _mutate,
                      onAddNote: _addNote,
                    ),
                    const SizedBox(height: 16),
                    FollowUpField(
                      entry: entry,
                      t: _t,
                      onPick: _pickFollowUp,
                      mutate: _mutate,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
