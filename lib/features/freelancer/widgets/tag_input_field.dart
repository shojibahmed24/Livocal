import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Simple chip input: type a value, press enter (or the + button) to add it.
class TagInputField extends StatefulWidget {
  final List<String> values;
  final String hint;
  final String addTooltip;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final String Function(String value) display;

  const TagInputField({
    super.key,
    required this.values,
    required this.hint,
    required this.addTooltip,
    required this.onAdd,
    required this.onRemove,
    this.display = _identity,
  });

  static String _identity(String value) => value;

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _openDialog() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.addTooltip),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: widget.hint),
          onSubmitted: (text) => Navigator.of(ctx).pop(text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    final text = (value ?? '').trim();
    if (text.isNotEmpty) widget.onAdd(text);
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      _focus.requestFocus();
      return;
    }
    widget.onAdd(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.values.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.values
                  .map(
                    (value) => InputChip(
                      label: Text(
                        widget.display(value),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => widget.onRemove(value),
                      deleteIcon: const Icon(Icons.close_rounded, size: 15),
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: widget.hint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () {
                if (_controller.text.trim().isEmpty) {
                  _openDialog();
                } else {
                  _submit();
                }
              },
              tooltip: widget.addTooltip,
              icon: const Icon(Icons.add_circle_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
