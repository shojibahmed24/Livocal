import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/services/cv_pdf_service.dart';
import 'package:livocal/features/freelancer/widgets/cover_image_field.dart';

/// Phase A professional fields: cover, response time, socials, stats, CV.
class ProfileProFields extends StatefulWidget {
  final FreelancerProfile profile;
  final String Function(String key) t;
  final void Function(void Function(FreelancerProfile)) mutate;

  const ProfileProFields({
    super.key,
    required this.profile,
    required this.t,
    required this.mutate,
  });

  @override
  State<ProfileProFields> createState() => _ProfileProFieldsState();
}

class _ProfileProFieldsState extends State<ProfileProFields> {
  bool _cvLoading = false;

  Future<void> _generateCv() async {
    if (_cvLoading) return;
    setState(() => _cvLoading = true);
    try {
      final file = await CvPdfService.build(widget.profile);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: widget.profile.displayName,
      );
    } catch (e) {
      debugPrint('[ProfileProFields] cv failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.t('cvFailed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _cvLoading = false);
    }
  }

  /// Builds the CV PDF and stores it, so "Download CV" works from the public
  /// page on any device. Storage is optional; a clear message is shown when it
  /// is not provisioned yet.
  Future<void> _uploadCv() async {
    if (_cvLoading) return;
    setState(() => _cvLoading = true);
    try {
      final file = await CvPdfService.build(widget.profile);
      final ref = FirebaseStorage.instance.ref().child(
            'documents/${widget.profile.ownerUid}/'
            'cv_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
      await ref
          .putFile(file, SettableMetadata(contentType: 'application/pdf'))
          .timeout(const Duration(seconds: 30));
      final url = await ref.getDownloadURL();
      widget.mutate((p) => p.cvUrl = url);
      _c['cvUrl']?.text = url;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.t('cvUploaded'))),
        );
      }
    } catch (e) {
      debugPrint('[ProfileProFields] cv upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.t('cvUploadFailed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _cvLoading = false);
    }
  }

  late final Map<String, TextEditingController> _c = {
    'avatarUrl': TextEditingController(text: widget.profile.avatarUrl),
    'coverUrl': TextEditingController(text: widget.profile.coverUrl),
    'responseTime': TextEditingController(text: widget.profile.responseTime),
    'githubUrl': TextEditingController(text: widget.profile.githubUrl),
    'linkedinUrl': TextEditingController(text: widget.profile.linkedinUrl),
    'websiteUrl': TextEditingController(text: widget.profile.websiteUrl),
    'cvUrl': TextEditingController(text: widget.profile.cvUrl),
    'projectsDone': TextEditingController(
      text: widget.profile.projectsDone == 0
          ? ''
          : '${widget.profile.projectsDone}',
    ),
    'yearsExperience': TextEditingController(
      text: widget.profile.yearsExperience == 0
          ? ''
          : '${widget.profile.yearsExperience}',
    ),
    'clientsCount': TextEditingController(
      text: widget.profile.clientsCount == 0
          ? ''
          : '${widget.profile.clientsCount}',
    ),
  };

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _set(String key, String value) {
    widget.mutate((p) {
      switch (key) {
        case 'avatarUrl':
          p.avatarUrl = value.trim();
        case 'coverUrl':
          p.coverUrl = value.trim();
        case 'responseTime':
          p.responseTime = value.trim();
        case 'githubUrl':
          p.githubUrl = value.trim();
        case 'linkedinUrl':
          p.linkedinUrl = value.trim();
        case 'websiteUrl':
          p.websiteUrl = value.trim();
        case 'cvUrl':
          p.cvUrl = value.trim();
        case 'projectsDone':
          p.projectsDone = int.tryParse(value.trim()) ?? 0;
        case 'yearsExperience':
          p.yearsExperience = int.tryParse(value.trim()) ?? 0;
        case 'clientsCount':
          p.clientsCount = int.tryParse(value.trim()) ?? 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1220);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.t('proSection').toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        _photoField(textColor),
        CoverImageField(
          profile: widget.profile,
          t: widget.t,
          mutate: widget.mutate,
        ),
        _field('responseTime', 'responseTime', textColor, url: false),
        _field('githubUrl', 'githubUrl', textColor),
        _field('linkedinUrl', 'linkedinUrl', textColor),
        _field('websiteUrl', 'websiteUrl', textColor),
        _field('cvUrl', 'cvUrl', textColor),
        Row(
          children: [
            Expanded(
                child: _field('projectsDone', 'projectsDone', textColor,
                    number: true)),
            const SizedBox(width: 8),
            Expanded(
                child: _field('yearsExperience', 'yearsExperience', textColor,
                    number: true)),
            const SizedBox(width: 8),
            Expanded(
                child: _field('clientsCount', 'clientsCount', textColor,
                    number: true)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cvLoading ? null : _generateCv,
                icon: _cvLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: Text(
                  widget.t('generateCv'),
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _cvLoading ? null : _uploadCv,
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: Text(
                  widget.t('uploadCv'),
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Profile photo used by the public page and the CV. Uploads arrive with
  /// storage support; until then a public image URL can be pasted here.
  Widget _photoField(Color color) {
    final url = _c['avatarUrl']!.text.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: SizedBox(
              width: 44,
              height: 44,
              child: url.startsWith('http')
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoFallback(),
                    )
                  : _photoFallback(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _textField(
              key: 'avatarUrl',
              label: 'photoUrl',
              color: color,
              url: true,
              action: TextInputAction.next,
              hint: 'https://',
              helper: widget.t('photoUrlHint'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoFallback() {
    return Container(
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: const Icon(Icons.person_outline_rounded, size: 22),
    );
  }

  Widget _field(
    String key,
    String label,
    Color color, {
    bool number = false,
    bool url = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _textField(
        key: key,
        label: label,
        color: color,
        url: url,
        number: number,
        action: number ? TextInputAction.next : TextInputAction.next,
      ),
    );
  }

  Widget _textField({
    required String key,
    required String label,
    required Color color,
    required TextInputAction action,
    bool url = false,
    bool number = false,
    String? hint,
    String? helper,
  }) {
    return TextField(
      key: ValueKey('profilePro-$key'),
      controller: _c[key],
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: false)
          : (url ? TextInputType.url : TextInputType.text),
      textInputAction: action,
      autocorrect: !url && !number,
      scrollPadding: const EdgeInsets.only(bottom: 140),
      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
      style: TextStyle(fontSize: 12.5, color: color),
      decoration: InputDecoration(
        isDense: true,
        labelText: widget.t(label),
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => _set(key, value),
    );
  }
}
