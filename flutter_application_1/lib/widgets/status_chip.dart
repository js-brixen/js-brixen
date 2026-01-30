import 'package:flutter/material.dart';
import '../models/booking.dart';

class StatusChip extends StatelessWidget {
  final BookingStatus status;
  final bool isCompact;

  const StatusChip({super.key, required this.status, this.isCompact = false});

  Color _getStatusColor() {
    switch (status) {
      case BookingStatus.newBooking:
        return Colors.orange;
      case BookingStatus.contacted:
        return Colors.blue;
      case BookingStatus.followUp:
        return Colors.purple;
      case BookingStatus.scheduled:
        return Colors.cyan;
      case BookingStatus.closed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case BookingStatus.newBooking:
        return Icons.fiber_new;
      case BookingStatus.contacted:
        return Icons.phone_in_talk;
      case BookingStatus.followUp:
        return Icons.schedule;
      case BookingStatus.scheduled:
        return Icons.event_available;
      case BookingStatus.closed:
        return Icons.check_circle;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case BookingStatus.newBooking:
        return 'New';
      case BookingStatus.contacted:
        return 'Contacted';
      case BookingStatus.followUp:
        return 'Follow Up';
      case BookingStatus.scheduled:
        return 'Scheduled';
      case BookingStatus.closed:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          _getStatusLabel(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
