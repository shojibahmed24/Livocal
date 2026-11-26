import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/services/freelancer_profile_service.dart';
import 'package:livocal/theme/app_colors.dart';

/// Custom link editor: `…/u/<username>`.
class UsernameEditor extends StatefulWidget {
  final FreelancerProfile profile;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onUpdated;

  const UsernameEditor({
    super.key,
    required this.profile,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onUpdated,
  });

  @override
  State<UsernameEditor> createState() => _UsernameEditorState();
}

class _UsernameEditorState extends State<UsernameEditor> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.profile.handle);
  bool _saving = false;
  String? _errorKey;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _errorKey = null;
    });
    final error = await FreelancerProfileService.changeUsername(
      widget.profile,
      _controller.text,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _errorKey = error;
      if (error == null) _controller.text = widget.profile.handle;
    });
    if (error == null) widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.t('usernameLabel').toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: widget.muted,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autocorrect: false,
                style: TextStyle(fontSize: 13, color: widget.textColor),
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: '/u/ ',
                  prefixStyle: TextStyle(
                    fontSize: 12,
                    color: widget.muted,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _saving ? null : _save,
              tooltip: widget.t('usernameSave'),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
        if (_errorKey != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.t(_errorKey!),
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
