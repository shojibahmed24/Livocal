import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/services/freelancer_profile_service.dart';
import 'package:livocal/features/freelancer/widgets/portfolio_dialog.dart';
import 'package:livocal/features/freelancer/widgets/portfolio_section.dart';
import 'package:livocal/features/freelancer/widgets/profile_form_fields.dart';
import 'package:livocal/features/freelancer/widgets/profile_header.dart';
import 'package:livocal/features/freelancer/widgets/regenerate_confirm.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Freelancer public profile editor (F2).
class FreelancerProfileScreen extends StatefulWidget {
  final User user;

  const FreelancerProfileScreen({super.key, required this.user});

  @override
  State<FreelancerProfileScreen> createState() =>
      _FreelancerProfileScreenState();
}

class _FreelancerProfileScreenState extends State<FreelancerProfileScreen> {
  final TextEditingController _headlineCtrl = TextEditingController();
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController();

  FreelancerProfile? _profile;
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
    _headlineCtrl.dispose();
    _bioCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _load() async {
    unawaited(FreelancerProfileService.refresh(widget.user.id));
    final profile = await FreelancerProfileService.ensure(
      widget.user.id,
      displayName: widget.user.name,
      avatarUrl: widget.user.avatarUrl,
    );
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _headlineCtrl.text = profile.headline;
      _bioCtrl.text = profile.bio;
      if (profile.rateAmount > 0) {
        _rateCtrl.text = profile.rateAmount % 1 == 0
            ? profile.rateAmount.toInt().toString()
            : profile.rateAmount.toString();
      }
    });
  }

  void _mutate(void Function(FreelancerProfile profile) change) {
    final profile = _profile;
    if (profile == null) return;
    HapticFeedback.selectionClick();
    setState(() => change(profile));
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), _persist);
  }

  Future<void> _persist() async {
    final profile = _profile;
    if (profile == null) return;
    await FreelancerProfileService.save(profile);
    if (!mounted) return;
    setState(() => _savedRecently = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _savedRecently = false);
  }

  Future<void> _copyLink() async {
    final profile = _profile;
    if (profile == null) return;
    await Clipboard.setData(ClipboardData(text: profile.publicUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('linkCopied')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareLink() async {
    final profile = _profile;
    if (profile == null) return;
    await Share.share(profile.publicUrl, subject: profile.displayName);
  }

  Future<void> _preview() async {
    final profile = _profile;
    if (profile == null) return;
    final uri = Uri.tryParse(profile.publicUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _togglePublish(bool value) async {
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_t('publishPage')),
          content: Text(_t('publishConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(_t('publishPage')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    _mutate((profile) => profile.published = value);
  }

  Future<void> _regenerateSlug() async {
    final profile = _profile;
    if (profile == null) return;
    if (!await confirmRegenerateLink(context, _t)) return;
    _saveTimer?.cancel();
    await FreelancerProfileService.regenerateSlug(profile);
    if (mounted) setState(() {});
  }

  Future<void> _addPortfolio() async {
    final result = await showPortfolioDialog(context);
    if (result == null) return;
    _mutate(
      (profile) =>
          profile.portfolio = [...profile.portfolio, jsonEncode(result)],
    );
  }

  void _removePortfolio(int index) {
    _mutate(
      (profile) => profile.portfolio = [...profile.portfolio]..removeAt(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('freelancerProfile')),
        actions: [
          if (_savedRecently)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
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
            ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  _t('freelancerProfileSub'),
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
                const SizedBox(height: 12),
                ProfileHeader(
                  profile: profile,
                  t: _t,
                  textColor: textColor,
                  muted: muted,
                  onUpdated: () => setState(() {}),
                  onCopy: _copyLink,
                  onShare: _shareLink,
                  onPreview: _preview,
                  onRegenerate: _regenerateSlug,
                ),
                const SizedBox(height: 18),
                ProfileFormFields(
                  profile: profile,
                  headlineCtrl: _headlineCtrl,
                  bioCtrl: _bioCtrl,
                  rateCtrl: _rateCtrl,
                  t: _t,
                  mutate: _mutate,
                ),
                const SizedBox(height: 16),
                PortfolioSection(
                  entries: profile.portfolioEntries,
                  t: _t,
                  textColor: textColor,
                  muted: muted,
                  onAdd: _addPortfolio,
                  onRemove: _removePortfolio,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: profile.published,
                  onChanged: _togglePublish,
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    _t('publishPage'),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    _t('publishSub'),
                    style: TextStyle(fontSize: 11.5, color: muted),
                  ),
                ),
              ],
            ),
    );
  }
}
