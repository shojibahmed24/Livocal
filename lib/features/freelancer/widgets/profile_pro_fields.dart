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

  late final Map<String, TextEditingController> _c = {
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
        CoverImageField(
          profile: widget.profile,
          t: widget.t,
          mutate: widget.mutate,
        ),
        _field('responseTime', 'responseTime', textColor),
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
        SizedBox(
          width: double.infinity,
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
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _field(String key, String label, Color color, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _c[key],
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: false)
            : TextInputType.url,
        style: TextStyle(fontSize: 12.5, color: color),
        decoration: InputDecoration(
          isDense: true,
          labelText: widget.t(label),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => _set(key, value),
      ),
    );
  }
}
