import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Portfolio link list with an add button.
class PortfolioSection extends StatelessWidget {
  final List<Map<String, String>> entries;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const PortfolioSection({
    super.key,
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
                t('portfolioLabel').toUpperCase(),
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
              tooltip: t('addPortfolio'),
              icon: const Icon(Icons.add_link_rounded, size: 20),
              color: AppColors.primary,
            ),
          ],
        ),
        ...entries.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value['label'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: textColor),
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
        const SizedBox(height: 12),
      ],
    );
  }
}
