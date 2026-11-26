import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/freelancer_profile.dart';
import 'package:livocal/features/freelancer/widgets/case_studies_section.dart';
import 'package:livocal/features/freelancer/widgets/experience_dialog.dart';
import 'package:livocal/features/freelancer/widgets/experience_section.dart';
import 'package:livocal/features/freelancer/widgets/case_study_dialog.dart';
import 'package:livocal/features/freelancer/widgets/portfolio_dialog.dart';
import 'package:livocal/features/freelancer/widgets/portfolio_section.dart';
import 'package:livocal/features/freelancer/widgets/service_dialog.dart';
import 'package:livocal/features/freelancer/widgets/services_section.dart';

/// Portfolio + services editors (self-contained dialogs and mutations).
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
    final result = await showPortfolioDialog(
      context,
      ownerUid: profile.ownerUid,
    );
    if (result == null) return;
    mutate(
      (p) => p.portfolio = [...p.portfolio, jsonEncode(result)],
    );
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

  Future<void> _addCase(BuildContext context) async {
    final result = await showCaseStudyDialog(
      context,
      ownerUid: profile.ownerUid,
    );
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
      ],
    );
  }
}
