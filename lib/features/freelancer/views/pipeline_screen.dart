import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/crm_entry.dart';
import 'package:livocal/features/freelancer/services/crm_service.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/repositories/isar_db.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Sales pipeline: every CRM contact grouped by deal stage.
class PipelineScreen extends StatefulWidget {
  final User user;

  const PipelineScreen({super.key, required this.user});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  static const _stages = [
    (CrmService.stageNew, 'stageNew'),
    (CrmService.stageNegotiating, 'stageNegotiating'),
    (CrmService.stageActive, 'stageActive'),
    (CrmService.stagePaid, 'stagePaid'),
  ];

  final Map<String, String> _names = {};

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _loadNames() async {
    try {
      final users = await IsarDb.getUsers();
      final map = <String, String>{};
      for (final user in users) {
        if (user.name.trim().isNotEmpty) map[user.id] = user.name;
      }
      if (mounted) setState(() => _names.addAll(map));
    } catch (_) {
      // Names simply fall back to the uid.
    }
  }

  String _name(CrmEntry entry) {
    final name = _names[entry.peerUid];
    if (name != null && name.isNotEmpty) return name;
    return entry.peerUid.length > 8
        ? '${entry.peerUid.substring(0, 8)}…'
        : entry.peerUid;
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(_t('pipeline'))),
      body: StreamBuilder<List<CrmEntry>>(
        stream: CrmService.watchAll(widget.user.id),
        builder: (context, snapshot) {
          final entries = (snapshot.data ?? const <CrmEntry>[])
              .where((entry) => !entry.isArchived)
              .toList();

          if (entries.isEmpty) {
            return Center(
              child: Text(
                _t('emptyPipeline'),
                style: TextStyle(fontSize: 13, color: muted),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              Text(
                _t('pipelineSub'),
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 12),
              ..._stages.expand((stage) {
                final group =
                    entries.where((entry) => entry.stage == stage.$1).toList();
                if (group.isEmpty) return const <Widget>[];
                return [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _t(stage.$2).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${group.length}',
                          style: TextStyle(fontSize: 10.5, color: muted),
                        ),
                      ],
                    ),
                  ),
                  ...group.map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.025),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: muted.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name(entry),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  entry.rateAmount > 0
                                      ? '${entry.rateCurrency} '
                                          '${entry.rateAmount.toStringAsFixed(0)} · '
                                          '${_t(entry.rateBasis == 'project' ? 'rateProject' : 'rateHourly')}'
                                      : _t('rateLabel'),
                                  style: TextStyle(fontSize: 11, color: muted),
                                ),
                                if (entry.followUpAt != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    '${_t('followUpLabel')}: '
                                    '${_formatDate(entry.followUpAt!)}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (entry.tag == CrmService.tagClient)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                _t('tagClient'),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ];
              }),
            ],
          );
        },
      ),
    );
  }
}
