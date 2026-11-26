import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/booking.dart';
import 'package:livocal/features/freelancer/services/booking_service.dart';
import 'package:livocal/features/freelancer/widgets/booking_tile.dart';
import 'package:livocal/shared/models/user.dart';
import 'package:livocal/shared/utils/app_localizations.dart';
import 'package:livocal/theme/app_colors.dart';

/// Host-side booking inbox: confirm, reschedule or cancel requests.
class BookingsScreen extends StatefulWidget {
  final User user;

  const BookingsScreen({super.key, required this.user});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    BookingService.pull(widget.user.id);
  }

  String _t(String key) =>
      AppStrings.get(key, Localizations.localeOf(context).languageCode);

  bool _matches(Booking booking) {
    switch (_filter) {
      case 'pending':
        return booking.isPending;
      case 'confirmed':
        return booking.isConfirmed;
      case 'cancelled':
        return booking.isCancelled;
      default:
        return true;
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _confirm(Booking booking) async {
    await BookingService.confirm(booking, hostUid: widget.user.id);
    if (!mounted) return;
    _snack(_t('bookingConfirmedMsg'));
  }

  Future<void> _cancel(Booking booking) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('cancelBooking')),
        content: Text(booking.guestName),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('statusVoid')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_t('cancelBooking')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await BookingService.cancel(booking);
    if (!mounted) return;
    _snack(_t('bookingCancelledMsg'));
  }

  Future<void> _reschedule(Booking booking) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: booking.startAt.isAfter(now) ? booking.startAt : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(booking.startAt),
    );
    if (time == null) return;
    final start =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await BookingService.reschedule(booking, start);
    if (!mounted) return;
    _snack(_t('bookingRescheduledMsg'));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(_t('bookings'))),
      body: StreamBuilder<List<Booking>>(
        stream: BookingService.watch(widget.user.id),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Booking>[];
          final visible = all.where(_matches).toList();

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    _chip('all', 'filterAll', muted),
                    _chip('pending', 'bookingPending', muted),
                    _chip('confirmed', 'bookingConfirmed', muted),
                    _chip('cancelled', 'bookingCancelled', muted),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          _t('noBookings'),
                          style: TextStyle(fontSize: 13, color: muted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final booking = visible[index];
                          return BookingTile(
                            booking: booking,
                            t: _t,
                            textColor: textColor,
                            muted: muted,
                            onConfirm: () => _confirm(booking),
                            onReschedule: () => _reschedule(booking),
                            onCancel: () => _cancel(booking),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String value, String labelKey, Color muted) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(_t(labelKey), style: const TextStyle(fontSize: 11.5)),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        side: BorderSide(
          color: selected ? AppColors.primary : muted.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
