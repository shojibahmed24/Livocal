import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:livocal/features/calls/controllers/call_controller.dart';
import 'package:livocal/features/freelancer/models/call_summary.dart';
import 'package:livocal/features/freelancer/services/call_summary_service.dart';
import 'package:livocal/features/freelancer/services/crm_service.dart';
import 'package:livocal/features/freelancer/widgets/call_summary_view.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/shared/utils/shared_pref.dart';
import 'package:livocal/theme/app_colors.dart';

/// End-of-call AI summary strip shown inside the call-ended sheet.
class CallSummaryCard extends ConsumerStatefulWidget {
  final String ownerUid;
  final String peerUid;
  final String peerName;
  final int durationSeconds;

  const CallSummaryCard({
    super.key,
    required this.ownerUid,
    required this.peerUid,
    required this.peerName,
    required this.durationSeconds,
  });

  @override
  ConsumerState<CallSummaryCard> createState() => _CallSummaryCardState();
}

class _CallSummaryCardState extends ConsumerState<CallSummaryCard> {
  static const _consentKey = 'call_summary_consent';

  CallSummary? _summary;
  bool _loading = true;
  bool _hadTranscript = false;
  bool _savingToCrm = false;
  bool _savedToCrm = false;
  bool _consentDeclined = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _boot() async {
    if (!mounted) return;
    final prefs = SharedPref.instance;
    var consent = prefs.getString(_consentKey);

    if (consent == null) {
      final accepted = await _askConsent();
      consent = accepted ? 'yes' : 'no';
      await prefs.setString(_consentKey, consent);
    }

    if (consent != 'yes' || !mounted) {
      if (mounted) {
        setState(() {
          _loading = false;
          _consentDeclined = true;
        });
      }
      return;
    }
    await _generate();
  }

  Future<bool> _askConsent() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('summaryConsentTitle')),
        content: Text(_t('summaryConsentBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('summaryNo')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_t('summaryYes')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _generate() async {
    final state = ref.read(callControllerProvider);
    final transcripts = state.transcripts;
    final lastEnded = state.lastEndedCall;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _hadTranscript = transcripts.isNotEmpty;
    });

    final summary = await CallSummaryService.generate(
      callId: lastEnded?.callId ?? '',
      durationSeconds: widget.durationSeconds,
      entries: transcripts,
      myLang: lastEnded?.myLangCode ?? 'auto',
      peerLang: lastEnded?.peerLangCode ?? 'en',
    );

    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  String? _asPlainText() {
    final summary = _summary;
    if (summary == null) return null;
    return summary.toPlainText(
      title: _t('callSummary'),
      decisionsLabel: _t('decisions'),
      actionsLabel: _t('actionItems'),
      hintsLabel: _t('clientHints'),
      meLabel: _t('summaryOwnerMe'),
      clientLabel: _t('summaryOwnerClient'),
    );
  }

  Future<void> _copy() async {
    final text = _asPlainText();
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('linkCopied')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _share() async {
    final text = _asPlainText();
    if (text == null) return;
    await Share.share(text, subject: _t('callSummary'));
  }

  Future<void> _saveToCrm() async {
    final summary = _summary;
    if (summary == null || _savingToCrm) return;
    setState(() => _savingToCrm = true);

    final entry = await CrmService.ensure(widget.ownerUid, widget.peerUid);
    final note = jsonEncode({
      'text': '${_t('callSummary')}: ${summary.summary}',
      'at': DateTime.now().toIso8601String(),
    });
    entry.notes = [...entry.notes, note];
    entry.lastContactedAt = DateTime.now();
    await CrmService.save(entry);

    if (!mounted) return;
    setState(() {
      _savingToCrm = false;
      _savedToCrm = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (_consentDeclined) return const SizedBox.shrink();

    if (!_loading && _summary == null) {
      if (!_hadTranscript) {
        return _infoBox(_t('noTranscript'), muted);
      }
      return _infoBox(_t('summaryFailed'), muted);
    }

    if (_loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              _t('summaryGenerating'),
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ],
        ),
      );
    }

    return CallSummaryView(
      summary: _summary!,
      t: _t,
      onCopy: _copy,
      onShare: _share,
      onSave: _saveToCrm,
      saved: _savedToCrm,
      saving: _savingToCrm,
    );
  }

  Widget _infoBox(String text, Color muted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: muted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.5, color: muted),
      ),
    );
  }
}
