import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Generic editor list (education, certifications, FAQ).
class ExtrasSection extends StatelessWidget {
  final String labelKey;
  final String addKey;
  final String primaryKey;
  final String secondaryKey;
  final List<Map<String, String>> entries;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const ExtrasSection({
    super.key,
    required this.labelKey,
    required this.addKey,
    required this.primaryKey,
    required this.secondaryKey,
    required this.entries,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t(labelKey).toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: muted,
                ),
              ),
            ),
            IconButton(
              onPressed: onAdd,
              tooltip: t(addKey),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              color: AppColors.primary,
            ),
          ],
        ),
        ...entries.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 7, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value[primaryKey] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: textColor),
                          ),
                          if ((entry.value[secondaryKey] ?? '').isNotEmpty)
                            Text(
                              entry.value[secondaryKey]!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: muted),
                            ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => onRemove(entry.key),
                      child: Icon(Icons.close_rounded, size: 16, color: muted),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 10),
      ],
    );
  }
}
