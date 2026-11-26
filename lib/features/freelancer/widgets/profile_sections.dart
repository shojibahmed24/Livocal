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

  Future<void> _addPortfolio(BuildContext context) async {
    final result =
        await showPortfolioDialog(context, ownerUid: profile.ownerUid);
    if (result == null) return;
    mutate((p) => p.portfolio = [...p.portfolio, jsonEncode(result)]);
  }

  void _removePortfolio(int index) {
    mutate((p) => p.portfolio = [...p.portfolio]..removeAt(index));
  }

  Future<void> _addExperience(BuildContext context) async {
    final result = await showExperienceDialog(context);
    if (result == null) return;
    mutate((p) => p.experience = [...p.experience, jsonEncode(result)]);
  }

  void _removeExperience(int index) {
    mutate((p) => p.experience = [...p.experience]..removeAt(index));
  }

  Future<void> _addEducation(BuildContext context) async {
    final result = await showEducationDialog(context);
    if (result == null) return;
    mutate((p) => p.education = [...p.education, jsonEncode(result)]);
  }

  void _removeEducation(int index) {
    mutate((p) => p.education = [...p.education]..removeAt(index));
  }

  Future<void> _addCertification(BuildContext context) async {
    final result = await showCertificationDialog(context);
    if (result == null) return;
    mutate((p) => p.certifications = [...p.certifications, jsonEncode(result)]);
  }

  void _removeCertification(int index) {
    mutate((p) => p.certifications = [...p.certifications]..removeAt(index));
  }

  Future<void> _addFaq(BuildContext context) async {
    final result = await showFaqDialog(context);
    if (result == null) return;
    mutate((p) => p.faq = [...p.faq, jsonEncode(result)]);
  }

  void _removeFaq(int index) {
    mutate((p) => p.faq = [...p.faq]..removeAt(index));
  }

  Future<void> _addCase(BuildContext context) async {
    final result =
        await showCaseStudyDialog(context, ownerUid: profile.ownerUid);
    if (result == null) return;
    mutate((p) => p.caseStudies = [...p.caseStudies, jsonEncode(result)]);
  }

  void _removeCase(int index) {
    mutate((p) => p.caseStudies = [...p.caseStudies]..removeAt(index));
  }

  Future<void> _addService(BuildContext context) async {
    final result = await showServiceDialog(context);
    if (result == null) return;
    mutate((p) => p.services = [...p.services, jsonEncode(result)]);
  }

  void _removeService(int index) {
    mutate((p) => p.services = [...p.services]..removeAt(index));
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
          onAdd: () => _addExperience(context),
          onRemove: _removeExperience,
        ),
        ExtrasSection(
          labelKey: 'educationLabel',
          addKey: 'addEducation',
          primaryKey: 'school',
          secondaryKey: 'degree',
          entries: profile.educationEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _addEducation(context),
          onRemove: _removeEducation,
        ),
        ExtrasSection(
          labelKey: 'certificationsLabel',
          addKey: 'addCertification',
          primaryKey: 'name',
          secondaryKey: 'issuer',
          entries: profile.certificationEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _addCertification(context),
          onRemove: _removeCertification,
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
          onAdd: () => _addFaq(context),
          onRemove: _removeFaq,
        ),
        CaseStudiesSection(
          entries: profile.caseEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _addCase(context),
          onRemove: _removeCase,
        ),
        ServicesSection(
          entries: profile.serviceEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          currency: profile.rateCurrency,
          onAdd: () => _addService(context),
          onRemove: _removeService,
        ),
        PortfolioSection(
          entries: profile.portfolioEntries,
          t: t,
          textColor: textColor,
          muted: muted,
          onAdd: () => _addPortfolio(context),
          onRemove: _removePortfolio,
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
