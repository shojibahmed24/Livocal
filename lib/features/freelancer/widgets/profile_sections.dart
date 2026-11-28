import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/widgets/accent_picker.dart';
import 'package:livocal/features/freelancer/widgets/case_studies_section.dart';
import 'package:livocal/features/freelancer/widgets/case_study_dialog.dart';
import 'package:livocal/features/freelancer/widgets/experience_dialog.dart';
import 'package:livocal/features/freelancer/widgets/experience_section.dart';
import 'package:livocal/features/freelancer/widgets/extras_dialogs.dart';
import 'package:livocal/features/freelancer/widgets/extras_section.dart';
import 'package:livocal/features/freelancer/widgets/portfolio_dialog.dart';
import 'package:livocal/features/freelancer/widgets/portfolio_section.dart';
import 'package:livocal/features/freelancer/widgets/section_order_sheet.dart';
import 'package:livocal/features/freelancer/widgets/service_dialog.dart';
import 'package:livocal/features/freelancer/widgets/services_section.dart';

/// One repeatable profile section: how to edit, read and write it.
class _Section {
  final List<String> Function(FreelancerProfile p) raw;
  final List<Map<String, String>> Function(FreelancerProfile p) entries;
  final void Function(FreelancerProfile p, List<String> value) write;
  final Future<Map<String, String>?> Function(
    BuildContext context,
    FreelancerProfile p,
    Map<String, String>? existing,
  ) edit;

  const _Section({
    required this.raw,
    required this.entries,
    required this.write,
    required this.edit,
  });
}

/// Portfolio and CV editors (self-contained dialogs and mutations).
class ProfileSections extends StatelessWidget {
  final FreelancerProfile profile;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final void Function(void Function(FreelancerProfile)) mutate;

  const ProfileSections({
    super.key,
    required this.profile,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.mutate,
  });

  static final _Section _experience = _Section(
    raw: (p) => p.experience,
    entries: (p) => p.experienceEntries,
    write: (p, value) => p.experience = value,
    edit: (context, p, existing) =>
        showExperienceDialog(context, existing: existing),
  );

  static final _Section _education = _Section(
    raw: (p) => p.education,
    entries: (p) => p.educationEntries,
    write: (p, value) => p.education = value,
    edit: (context, p, existing) =>
        showEducationDialog(context, existing: existing),
  );

  static final _Section _certifications = _Section(
    raw: (p) => p.certifications,
    entries: (p) => p.certificationEntries,
    write: (p, value) => p.certifications = value,
    edit: (context, p, existing) =>
        showCertificationDialog(context, existing: existing),
  );

  static final _Section _faq = _Section(
    raw: (p) => p.faq,
    entries: (p) => p.faqEntries,
    write: (p, value) => p.faq = value,
    edit: (context, p, existing) => showFaqDialog(context, existing: existing),
  );

  static final _Section _cases = _Section(
    raw: (p) => p.caseStudies,
    entries: (p) => p.caseEntries,
    write: (p, value) => p.caseStudies = value,
    edit: (context, p, existing) => showCaseStudyDialog(
      context,
      ownerUid: p.ownerUid,
      existing: existing,
    ),
  );

  static final _Section _services = _Section(
    raw: (p) => p.services,
    entries: (p) => p.serviceEntries,
    write: (p, value) => p.services = value,
    edit: (context, p, existing) =>
        showServiceDialog(context, existing: existing),
  );

  static final _Section _portfolio = _Section(
    raw: (p) => p.portfolio,
    entries: (p) => p.portfolioEntries,
    write: (p, value) => p.portfolio = value,
    edit: (context, p, existing) => showPortfolioDialog(
      context,
      ownerUid: p.ownerUid,
      existing: existing,
    ),
  );

  Future<void> _add(BuildContext context, _Section section) async {
    final result = await section.edit(context, profile, null);
    if (result == null) return;
    mutate((p) => section.write(p, [...section.raw(p), jsonEncode(result)]));
  }

  Future<void> _edit(
    BuildContext context,
    _Section section,
    int index,
  ) async {
    final current = section.entries(profile);
    if (index >= current.length) return;
    final result = await section.edit(context, profile, current[index]);
    if (result == null) return;
    mutate((p) {
      final next = [...section.raw(p)];
      if (index < next.length) next[index] = jsonEncode(result);
      section.write(p, next);
    });
  }

  void _remove(BuildContext context, _Section section, int index) {
    final raw = section.raw(profile);
    if (index >= raw.length) return;
    final removed = raw[index];
    mutate((p) => section.write(p, [...section.raw(p)]..removeAt(index)));
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(t('itemDeleted')),
        action: SnackBarAction(
          label: t('undo'),
          onPressed: () => mutate((p) {
            final next = [...section.raw(p)];
            final at = index > next.length ? next.length : index;
            section.write(p, next..insert(at, removed));
          }),
        ),
      ),
    );
  }

  Future<void> _arrangeSections(BuildContext context) async {
    final order = await showSectionOrderSheet(
      context,
      current: profile.sectionOrder,
      t: t,
      muted: muted,
      textColor: textColor,
    );
    if (order == null) return;
    mutate((p) => p.sectionOrder = order);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExperienceSection(
          entries: profile.experienceEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _add(context, _experience),
          onEdit: (index) => _edit(context, _experience, index),
          onRemove: (index) => _remove(context, _experience, index),
        ),
        ExtrasSection(
          labelKey: 'educationLabel',
          addKey: 'addEducation',
          primaryKey: 'school',
          secondaryKey: 'degree',
          trailingKey: 'start',
          entries: profile.educationEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _add(context, _education),
          onEdit: (index) => _edit(context, _education, index),
          onRemove: (index) => _remove(context, _education, index),
        ),
        ExtrasSection(
          labelKey: 'certificationsLabel',
          addKey: 'addCertification',
          primaryKey: 'name',
          secondaryKey: 'issuer',
          trailingKey: 'year',
          entries: profile.certificationEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _add(context, _certifications),
          onEdit: (index) => _edit(context, _certifications, index),
          onRemove: (index) => _remove(context, _certifications, index),
        ),
        ExtrasSection(
          labelKey: 'faqLabel',
          addKey: 'addFaq',
          primaryKey: 'question',
          secondaryKey: 'answer',
          entries: profile.faqEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _add(context, _faq),
          onEdit: (index) => _edit(context, _faq, index),
          onRemove: (index) => _remove(context, _faq, index),
        ),
        CaseStudiesSection(
          entries: profile.caseEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _add(context, _cases),
          onEdit: (index) => _edit(context, _cases, index),
          onRemove: (index) => _remove(context, _cases, index),
        ),
        ServicesSection(
          entries: profile.serviceEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          currency: profile.rateCurrency,
          onAdd: () => _add(context, _services),
          onEdit: (index) => _edit(context, _services, index),
          onRemove: (index) => _remove(context, _services, index),
        ),
        PortfolioSection(
          entries: profile.portfolioEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _add(context, _portfolio),
          onEdit: (index) => _edit(context, _portfolio, index),
          onRemove: (index) => _remove(context, _portfolio, index),
        ),
        AccentPicker(
          selected: profile.accentColor,
          t: t,
          muted: muted,
          onSelect: (value) => mutate((p) => p.accentColor = value),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _arrangeSections(context),
            icon: const Icon(Icons.swap_vert_rounded, size: 18),
            label:
                Text(t('sectionOrder'), style: const TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
