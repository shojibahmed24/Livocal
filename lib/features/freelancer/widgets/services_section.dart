import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Services list (title + starting price) with add/remove.
class ServicesSection extends StatelessWidget {
  final List<Map<String, String>> entries;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final String currency;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const ServicesSection({
    super.key,
    required this.entries,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.currency,
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
                t('servicesLabel').toUpperCase(),
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
              tooltip: t('addService'),
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
                    const Icon(Icons.design_services_outlined,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: textColor),
                      ),
                    ),
                    if ((entry.value['from'] ?? '').isNotEmpty)
                      Text(
                        '$currency ${entry.value['from']}',
                        style: TextStyle(fontSize: 10.5, color: muted),
                      ),
                    const SizedBox(width: 6),
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
