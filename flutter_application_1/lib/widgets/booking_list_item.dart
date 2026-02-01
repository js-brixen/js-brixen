import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking.dart';
import 'status_chip.dart';

class BookingListItem extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final Function(String) onStatusChange;
  final Function(String?) onAssign;

  const BookingListItem({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onStatusChange,
    required this.onAssign,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    // Remove any non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'https://wa.me/91$cleanPhone?text=Hi, regarding your booking inquiry...',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.cyan.withValues(alpha: 0.2),
                child: Text(
                  booking.name.isNotEmpty ? booking.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      booking.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Phone
                    Text(
                      booking.formattedPhone,
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 6),

                    // District & Type
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          booking.district,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            booking.typeOfWork,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(
                            booking.preferredDate ?? booking.createdAt,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status & Menu
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: booking.status, isCompact: true),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'call':
                          _makePhoneCall(booking.phone);
                          break;
                        case 'whatsapp':
                          _openWhatsApp(booking.phone);
                          break;
                        case 'contacted':
                        case 'follow_up':
                        case 'scheduled':
                        case 'closed':
                          onStatusChange(value);
                          break;
                        case 'assign':
                          // TODO: Show assign dialog
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'call',
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 18),
                            SizedBox(width: 8),
                            Text('Call'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'whatsapp',
                        child: Row(
                          children: [
                            Icon(Icons.chat, size: 18),
                            SizedBox(width: 8),
                            Text('WhatsApp'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'contacted',
                        child: Text('Mark as Contacted'),
                      ),
                      const PopupMenuItem(
                        value: 'follow_up',
                        child: Text('Mark as Follow Up'),
                      ),
                      const PopupMenuItem(
                        value: 'scheduled',
                        child: Text('Mark as Scheduled'),
                      ),
                      const PopupMenuItem(
                        value: 'closed',
                        child: Text('Mark as Closed'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
