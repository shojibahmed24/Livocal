import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/services/profile_image_service.dart';
import 'package:livocal/shared/utils/app_localizations.dart';

/// Collects one portfolio item (image from phone + label + link).
Future<Map<String, String>?> showPortfolioDialog(
  BuildContext context, {
  required String ownerUid,
  Map<String, String>? existing,
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (_) => _PortfolioDialog(ownerUid: ownerUid, existing: existing),
  );
}

class _PortfolioDialog extends StatefulWidget {
  final String ownerUid;
  final Map<String, String>? existing;

  const _PortfolioDialog({required this.ownerUid, this.existing});

  @override
  State<_PortfolioDialog> createState() => _PortfolioDialogState();
}

class _PortfolioDialogState extends State<_PortfolioDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?['label'] ?? '');
  late final TextEditingController _url =
      TextEditingController(text: widget.existing?['url'] ?? '');
  late String _imageUrl = widget.existing?['imageUrl'] ?? '';
  bool _uploading = false;

  String get _lang => Localizations.localeOf(context).languageCode;

  String _t(String key) => AppStrings.get(key, _lang);

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_uploading) return;
    try {
      final picked = await ProfileImageService.pick();
      if (picked == null) return;
      setState(() => _uploading = true);
      final url = await ProfileImageService.upload(
        ownerUid: widget.ownerUid,
        prefix: 'portfolio',
        image: picked,
      );
      if (mounted) setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_t('imageUploadFailed')} ($e)')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(_t(widget.existing == null ? 'addPortfolio' : 'editPortfolio')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(
                isDense: true,
                labelText: _t('portfolioName'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                isDense: true,
                labelText: _t('portfolioUrl'),
                hintText: 'https://',
              ),
            ),
            const SizedBox(height: 12),
            if (_imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _imageUrl,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploading ? null : _pickImage,
                icon: _uploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_outlined, size: 16),
                label: Text(
                  _uploading ? _t('uploadingImage') : _t('chooseImage'),
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final label = _title.text.trim();
            if (label.isEmpty) return;
            final url = _url.text.trim();
            Navigator.of(context).pop({
              'label': label,
              'url': url.isEmpty
                  ? ''
                  : (url.startsWith('http') ? url : 'https://$url'),
              'imageUrl': _imageUrl,
            });
          },
          child: Text(_t('save')),
        ),
      ],
    );
  }
}
