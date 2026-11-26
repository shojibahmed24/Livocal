import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:livocal/features/freelancer/models/availability_day.dart';
import 'package:livocal/features/freelancer/services/availability_service.dart';
import 'package:livocal/features/freelancer/services/freelancer_profile_service.dart';
import 'package:livocal/features/freelancer/widgets/availability_day_tile.dart';
import 'package:livocal/shared/constants/app_config.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Weekly booking hours plus the public booking link.
class AvailabilityScreen extends StatefulWidget {
  final User user;

  const AvailabilityScreen({super.key, required this.user});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  static const _dayKeys = [
    'dayMon',
    'dayTue',
    'dayWed',
    'dayThu',
    'dayFri',
    'daySat',
    'daySun',
  ];

  String? _bookingUrl;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  Future<void> _bootstrap() async {
    await AvailabilityService.ensureDefaults(widget.user.id);
    await AvailabilityService.syncTimezone(widget.user.id);
    final profile = await FreelancerProfileService.ensure(
      widget.user.id,
      displayName: widget.user.name,
      avatarUrl: widget.user.avatarUrl,
    );
    if (!mounted) return;
    setState(() {
      _bookingUrl = '${AppConfig.relayHttpBaseUrl}/book/${profile.slug}';
    });
  }

  String _hm(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _toggle(AvailabilityDay day, bool value) async {
    day.enabled = value;
    if (value && day.validSlots.isEmpty) {
      day.slots = [AvailabilitySlot()];
    }
    await AvailabilityService.saveDay(day);
  }

  Future<void> _addSlot(AvailabilityDay day) async {
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (end == null) return;

    if (end.hour * 60 + end.minute <= start.hour * 60 + start.minute) {
      _snack(_t('slotInvalid'));
      return;
    }
    day.slots = [
      ...day.slots,
      AvailabilitySlot(start: _hm(start), end: _hm(end)),
    ];
    await AvailabilityService.saveDay(day);
  }

  Future<void> _removeSlot(AvailabilityDay day, AvailabilitySlot slot) async {
    day.slots = day.slots
        .where((row) => !(row.start == slot.start && row.end == slot.end))
        .toList();
    await AvailabilityService.saveDay(day);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _copyLink() async {
    final url = _bookingUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    _snack(_t('bookingLinkCopied'));
  }

  Future<void> _shareLink() async {
    final url = _bookingUrl;
    if (url == null) return;
    await Share.share(url, subject: _t('bookings'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(_t('availability'))),
      body: StreamBuilder<List<AvailabilityDay>>(
        stream: AvailabilityService.watch(widget.user.id),
        builder: (context, snapshot) {
          final days = snapshot.data ?? const <AvailabilityDay>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                _t('availabilitySub'),
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 10),
              _linkCard(),
              const SizedBox(height: 14),
              if (days.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...days.map(
                  (day) => AvailabilityDayTile(
                    day: day,
                    label: _t(_dayKeys[day.dayOfWeek - 1]),
                    t: _t,
                    onToggle: (value) => _toggle(day, value),
                    onAddSlot: () => _addSlot(day),
                    onRemoveSlot: (slot) => _removeSlot(day, slot),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _linkCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _t('bookingLink'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: _copyLink,
                tooltip: _t('copyProfileLink'),
                icon: const Icon(Icons.copy_rounded, size: 17),
                color: AppColors.primary,
              ),
              IconButton(
                onPressed: _shareLink,
                tooltip: _t('shareLink'),
                icon: const Icon(Icons.ios_share_rounded, size: 17),
                color: AppColors.primary,
              ),
            ],
          ),
          Text(
            _bookingUrl ?? '…',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
