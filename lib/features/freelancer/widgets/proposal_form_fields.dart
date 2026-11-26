import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Editable proposal sections after generation.
class ProposalFormFields extends StatelessWidget {
  final TextEditingController headline;
  final TextEditingController scope;
  final TextEditingController timeline;
  final TextEditingController price;
  final TextEditingController terms;
  final String Function(String key) t;

  const ProposalFormFields({
    super.key,
    required this.headline,
    required this.scope,
    required this.timeline,
    required this.price,
    required this.terms,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(headline, t('proposal'), textColor, maxLines: 2),
        const SizedBox(height: 10),
        _field(scope, t('scopeLabel'), textColor, maxLines: 6),
        const SizedBox(height: 10),
        _field(timeline, t('timelineLabel'), textColor, maxLines: 3),
        const SizedBox(height: 10),
        _field(price, t('priceLabel'), textColor, maxLines: 3),
        const SizedBox(height: 10),
        _field(terms, t('termsLabel'), textColor, maxLines: 4),
        const SizedBox(height: 6),
        Text(
          t('proposalSub'),
          style: TextStyle(fontSize: 10, color: muted),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    Color textColor, {
    int maxLines = 3,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 12.5, color: textColor),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
