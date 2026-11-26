import 'package:flutter/material.dart';

/// Accent colour picker for the public page.
class AccentPicker extends StatelessWidget {
  final String selected;
  final String Function(String key) t;
  final Color muted;
  final ValueChanged<String> onSelect;

  const AccentPicker({
    super.key,
    required this.selected,
    required this.t,
    required this.muted,
    required this.onSelect,
  });

  static const options = <String, Color>{
    'emerald': Color(0xFF34D399),
    'blue': Color(0xFF60A5FA),
    'violet': Color(0xFFA78BFA),
    'amber': Color(0xFFFBBF24),
    'rose': Color(0xFFFB7185),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('accentLabel').toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
            color: muted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final active = entry.key == selected;
            return InkWell(
              onTap: () => onSelect(entry.key),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: entry.value.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: active
                    ? const Icon(Icons.check, size: 16, color: Colors.black)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Text(
          t('accentHint'),
          style: TextStyle(fontSize: 10, color: muted),
        ),
      ],
    );
  }
}
