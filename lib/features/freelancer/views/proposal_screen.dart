import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:livocal/features/freelancer/models/crm_entry.dart';
import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/models/proposal.dart';
import 'package:livocal/features/freelancer/services/crm_service.dart';
import 'package:livocal/features/freelancer/services/freelancer_profile_service.dart';
import 'package:livocal/features/freelancer/services/proposal_pdf_service.dart';
import 'package:livocal/features/freelancer/services/proposal_service.dart';
import 'package:livocal/features/freelancer/services/proposal_share_service.dart';
import 'package:livocal/features/freelancer/widgets/proposal_actions_row.dart';
import 'package:livocal/features/freelancer/widgets/proposal_form_fields.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// AI proposal drafter for one client (F8).
class ProposalScreen extends StatefulWidget {
  final User user;
  final String clientUid;
  final String clientName;

  const ProposalScreen({
    super.key,
    required this.user,
    required this.clientUid,
    required this.clientName,
  });

  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  final TextEditingController _brief = TextEditingController();
  final TextEditingController _headline = TextEditingController();
  final TextEditingController _scope = TextEditingController();
  final TextEditingController _timeline = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _terms = TextEditingController();

  FreelancerProfile? _profile;
  CrmEntry? _crm;
  bool _generating = false;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _brief.dispose();
    _headline.dispose();
    _scope.dispose();
    _timeline.dispose();
    _price.dispose();
    _terms.dispose();
    super.dispose();
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _load() async {
    final profile = await FreelancerProfileService.ensure(
      widget.user.id,
      displayName: widget.user.name,
      avatarUrl: widget.user.avatarUrl,
    );
    final crm = await CrmService.read(widget.user.id, widget.clientUid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _crm = crm;
    });
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  String _plainText() => Proposal(
        headline: _headline.text.trim(),
        scope: _scope.text.trim(),
        timeline: _timeline.text.trim(),
        price: _price.text.trim(),
        terms: _terms.text.trim(),
      ).toPlainText(
        title: _t('proposal'),
        scopeLabel: _t('scopeLabel'),
        timelineLabel: _t('timelineLabel'),
        priceLabel: _t('priceLabel'),
        termsLabel: _t('termsLabel'),
      );

  Future<void> _generate() async {
    if (_generating) return;
    setState(() => _generating = true);
    final profile = _profile;
    final crm = _crm;
    final proposal = await ProposalService.generate(
      displayName: profile?.displayName ?? widget.user.name,
      headline: profile?.headline ?? '',
      skills: profile?.skills ?? const [],
      clientName: widget.clientName,
      brief: _brief.text,
      rateAmount: crm?.rateAmount ?? profile?.rateAmount ?? 0,
      rateCurrency: crm?.rateCurrency ?? profile?.rateCurrency ?? 'USD',
      rateBasis: crm?.rateBasis ?? profile?.rateBasis ?? 'hourly',
    );
    if (!mounted) return;
    setState(() => _generating = false);
    if (proposal == null) {
      _snack(_t('proposalFailed'));
      return;
    }
    setState(() {
      _headline.text = proposal.headline;
      _scope.text = proposal.scope;
      _timeline.text = proposal.timeline;
      _price.text = proposal.price;
      _terms.text = proposal.terms;
      _ready = true;
    });
  }

  Future<void> _shareLink() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final token = await ProposalShareService.publish(
        ownerUid: widget.user.id,
        ownerName: _profile?.displayName ?? widget.user.name,
        clientName: widget.clientName,
        proposal: Proposal(
          headline: _headline.text.trim(),
          scope: _scope.text.trim(),
          timeline: _timeline.text.trim(),
          price: _price.text.trim(),
          terms: _terms.text.trim(),
        ),
      );
      final url = '${AppConfig.relayHttpBaseUrl}/pr/$token';
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) _snack(_t('linkCopied'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _plainText()));
    if (mounted) _snack(_t('linkCopied'));
  }

  Future<void> _share() async {
    await Share.share(_plainText(), subject: _t('proposal'));
  }

  Future<void> _sharePdf() async {
    if (!_ready || _saving) return;
    setState(() => _saving = true);
    try {
      final file = await ProposalPdfService.build(
        fromName: _profile?.displayName ?? widget.user.name,
        clientName: widget.clientName,
        headline: _headline.text,
        scope: _scope.text,
        timeline: _timeline.text,
        price: _price.text,
        terms: _terms.text,
        title: _t('proposal'),
        scopeLabel: _t('scopeLabel'),
        timelineLabel: _t('timelineLabel'),
        priceLabel: _t('priceLabel'),
        termsLabel: _t('termsLabel'),
      );
      await Share.shareXFiles([XFile(file.path)], subject: _t('proposal'));
    } catch (e) {
      debugPrint('[ProposalScreen] pdf failed: $e');
      if (mounted) _snack(_t('proposalFailed'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveToCrm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final entry = await CrmService.ensure(widget.user.id, widget.clientUid);
      final text = _plainText();
      final note = jsonEncode({
        'text': text.length > 900 ? text.substring(0, 900) : text,
        'at': DateTime.now().toIso8601String(),
      });
      entry.notes = [...entry.notes, note];
      entry.lastContactedAt = DateTime.now();
      await CrmService.save(entry);
      if (!mounted) return;
      _snack(_t('proposalSaved'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('proposal')),
        actions: [
          IconButton(
            onPressed: _ready ? _sharePdf : null,
            tooltip: _t('sharePdf'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          TextField(
            controller: _brief,
            maxLines: 4,
            maxLength: 1200,
            style: TextStyle(fontSize: 12.5, color: textColor),
            decoration: InputDecoration(
              isDense: true,
              labelText: _t('jobBrief'),
              hintText: _t('jobBriefHint'),
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              _generating ? _t('generatingProposal') : _t('generateProposal'),
            ),
          ),
          const SizedBox(height: 16),
          if (_ready) ...[
            ProposalFormFields(
              headline: _headline,
              scope: _scope,
              timeline: _timeline,
              price: _price,
              terms: _terms,
              t: _t,
            ),
            const SizedBox(height: 12),
            ProposalActionsRow(
              copyLabel: _t('copySummary'),
              shareLabel: _t('shareProposal'),
              saveLabel: _t('saveProposalNote'),
              linkLabel: _t('copyProfileLink'),
              onCopy: _copy,
              onShare: _share,
              onLink: _saving ? () {} : _shareLink,
              onSave: _saving ? null : _saveToCrm,
            ),
          ],
        ],
      ),
    );
  }
}
