import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:livocal/features/freelancer/models/crm_entry.dart';
import 'package:livocal/features/freelancer/models/time_entry.dart';
import 'package:livocal/features/freelancer/services/crm_service.dart';
import 'package:livocal/features/freelancer/services/time_tracking_service.dart';
import 'package:livocal/features/freelancer/widgets/time_client_row.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Call minutes per client with an estimated bill and CSV export.
class TimeReportsScreen extends StatefulWidget {
  final User user;

  const TimeReportsScreen({super.key, required this.user});

  @override
  State<TimeReportsScreen> createState() => _TimeReportsScreenState();
}

class _TimeReportsScreenState extends State<TimeReportsScreen> {
  String _period = 'week';
  Map<String, CrmEntry> _rates = {};

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _loadRates() async {
    try {
      final rows = await CrmService.readAll(widget.user.id);
      if (!mounted) return;
      setState(() {
        _rates = {for (final row in rows) row.peerUid: row};
      });
    } catch (_) {}
  }

  bool _inPeriod(TimeEntry entry) {
    final now = DateTime.now();
    if (_period == 'week') {
      return entry.at.isAfter(now.subtract(const Duration(days: 7)));
    }
    return entry.at.year == now.year && entry.at.month == now.month;
  }

  double _rateFor(String clientUid) {
    final entry = _rates[clientUid];
    if (entry == null || entry.rateAmount <= 0) return 0;
    return entry.rateAmount;
  }

  String _money(double amount, String currency) =>
      '$currency ${amount.toStringAsFixed(2)}';

  Future<void> _exportCsv(List<TimeEntry> entries) async {
    final buffer = StringBuffer('date,client,minutes,currency,estimated\n');
    for (final entry in entries) {
      final rate = _rateFor(entry.clientUid);
      final amount = rate > 0 ? entry.minutes / 60 * rate : 0;
      final currency = _rates[entry.clientUid]?.rateCurrency ?? 'USD';
      final name = entry.clientName.replaceAll(',', ' ');
      buffer.writeln(
        '${entry.at.toIso8601String()},$name,${entry.minutes},$currency,'
        '${amount.toStringAsFixed(2)}',
      );
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/livocal_time_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(buffer.toString(), flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: _t('timeReports'),
      );
    } catch (e) {
      debugPrint('[TimeReports] export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('timeReports')),
        actions: [
          IconButton(
            tooltip: _t('exportCsv'),
            onPressed: () async {
              final entries =
                  await TimeTrackingService.watch(widget.user.id).first;
              await _exportCsv(entries.where(_inPeriod).toList());
            },
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<TimeEntry>>(
        stream: TimeTrackingService.watch(widget.user.id),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <TimeEntry>[];
          final entries = all.where(_inPeriod).toList();

          final totalMinutes =
              entries.fold<int>(0, (sum, entry) => sum + entry.minutes);
          final totalAmount = entries.fold<double>(
            0,
            (sum, entry) =>
                sum + entry.minutes / 60 * _rateFor(entry.clientUid),
          );
          final currency = entries.isEmpty
              ? 'USD'
              : (_rates[entries.first.clientUid]?.rateCurrency ?? 'USD');

          final byClient = <String, List<TimeEntry>>{};
          for (final entry in entries) {
            byClient.putIfAbsent(entry.clientUid, () => []).add(entry);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                _t('timeReportsSub'),
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip('week', 'thisWeek'),
                  const SizedBox(width: 8),
                  _chip('month', 'thisMonth'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('totalMinutes'),
                            style: TextStyle(fontSize: 10.5, color: muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalMinutes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('estimatedBill'),
                            style: TextStyle(fontSize: 10.5, color: muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _money(totalAmount, currency),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _t('byClient').toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: muted,
                ),
              ),
              const SizedBox(height: 6),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      _t('noTimeEntries'),
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ),
                )
              else
                ...byClient.entries.map((group) {
                  final minutes = group.value
                      .fold<int>(0, (sum, entry) => sum + entry.minutes);
                  final rate = _rateFor(group.key);
                  final name = group.value.first.clientName;
                  return TimeClientRow(
                    name: name,
                    minutesLabel:
                        '$minutes ${_t('totalMinutes').toLowerCase()}',
                    amountLabel: rate > 0
                        ? _money(
                            minutes / 60 * rate,
                            _rates[group.key]?.rateCurrency ?? 'USD',
                          )
                        : _t('rateNotSet'),
                    hasRate: rate > 0,
                    textColor: textColor,
                    muted: muted,
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String value, String labelKey) {
    final selected = _period == value;
    return ChoiceChip(
      label: Text(_t(labelKey), style: const TextStyle(fontSize: 11.5)),
      selected: selected,
      onSelected: (_) => setState(() => _period = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      side: BorderSide(
        color: selected ? AppColors.primary : Theme.of(context).dividerColor,
      ),
    );
  }
}
