import 'package:flutter/material.dart';

import 'package:livocal/features/freelancer/models/booking.dart';
import 'package:livocal/theme/app_colors.dart';

/// One booking row with status and quick actions.
class BookingTile extends StatelessWidget {
  final Booking booking;
  final String Function(String key) t;
  final Color textColor;
  final Color muted;
  final VoidCallback onConfirm;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  const BookingTile({
    super.key,
    required this.booking,
    required this.t,
    required this.textColor,
    required this.muted,
    required this.onConfirm,
    required this.onReschedule,
    required this.onCancel,
  });

  String _date(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _time(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _statusColor() {
    if (booking.isConfirmed) return AppColors.primary;
    if (booking.isCancelled) return Colors.grey;
    return Colors.orangeAccent.shade700;
  }

  String _statusLabel() {
    if (booking.isConfirmed) return t('bookingConfirmed');
    if (booking.isCancelled) return t('bookingCancelled');
    return t('bookingPending');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: muted.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.guestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${_date(booking.startAt)} · ${_time(booking.startAt)} – '
            '${_time(booking.endAt)}',
            style: TextStyle(fontSize: 11.5, color: muted),
          ),
          if (booking.guestContact.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              booking.guestContact,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: textColor),
            ),
          ],
          if (booking.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              booking.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: muted,
              ),
            ),
          ],
          if (!booking.isCancelled) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (booking.isPending)
                  _action(
                    Icons.check_circle_outline_rounded,
                    t('confirmBooking'),
                    onConfirm,
                    primary: true,
                  ),
                _action(
                  Icons.schedule_rounded,
                  t('reschedule'),
                  onReschedule,
                ),
                _action(
                  Icons.cancel_outlined,
                  t('cancelBooking'),
                  onCancel,
                  danger: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool primary = false,
    bool danger = false,
  }) {
    final color = danger
        ? Colors.redAccent
        : primary
            ? AppColors.primary
            : muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
