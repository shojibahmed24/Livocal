import 'package:flutter/material.dart';

import 'package:livocal/theme/app_colors.dart';

/// Default order used when the profile has no explicit order.
const kDefaultSectionOrder = <String>[
  'about',
  'experience',
  'services',
  'work',
  'cases',
  'skills',
  'education',
  'certifications',
  'reviews',
  'faq',
];

const kSectionLabelKeys = <String, String>{
  'about': 'sectionAbout',
  'experience': 'sectionExperience',
  'services': 'sectionServices',
  'work': 'sectionWork',
  'cases': 'sectionCases',
  'skills': 'sectionSkills',
  'education': 'sectionEducation',
  'certifications': 'sectionCertifications',
  'reviews': 'sectionReviews',
  'faq': 'sectionFaq',
};

/// Lets the freelancer reorder public sections.
Future<List<String>?> showSectionOrderSheet(
  BuildContext context, {
  required List<String> current,
  required String Function(String key) t,
  required Color muted,
  required Color textColor,
}) {
  final order = List<String>.from(
    current.isEmpty ? kDefaultSectionOrder : current,
  );

  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t('sectionOrder'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ReorderableListView(
                  shrinkWrap: true,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = order.removeAt(oldIndex);
                      order.insert(newIndex, item);
                    });
                  },
                  children: order
                      .map(
                        (key) => ListTile(
                          key: ValueKey(key),
                          dense: true,
                          leading: Icon(Icons.drag_indicator_rounded,
                              size: 18, color: muted),
                          title: Text(
                            t(kSectionLabelKeys[key] ?? key),
                            style: TextStyle(fontSize: 13, color: textColor),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(order),
                  child: Text(t('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
