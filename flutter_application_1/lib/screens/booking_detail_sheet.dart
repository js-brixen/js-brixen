import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/booking.dart';
import '../widgets/status_chip.dart';
import '../widgets/internal_notes_widget.dart';

class BookingDetailSheet extends StatelessWidget {
  final Booking booking;

  const BookingDetailSheet({super.key, required this.booking});

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'https://wa.me/91$cleanPhone?text=Hi ${booking.name}, regarding your booking inquiry...',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not specified';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatPhone(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.cyan.withValues(alpha: 0.2),
                          child: Text(
                            booking.name.isNotEmpty
                                ? booking.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StatusChip(status: booking.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Contact info
                    _buildSection('Contact Information', [
                      _buildInfoRow(
                        context,
                        Icons.phone,
                        'Form Phone',
                        booking.formattedPhone,
                        action: () => _makePhoneCall(booking.phone),
                      ),
                      _buildInfoRow(
                        context,
                        Icons.location_on,
                        'District',
                        booking.district,
                      ),
                      _buildInfoRow(
                        context,
                        Icons.phone_android,
                        'Auth Number',
                        booking.customerPhone != null
                            ? _formatPhone(booking.customerPhone!)
                            : 'Not verified',
                        action: booking.customerPhone != null
                            ? () => _makePhoneCall(booking.customerPhone!)
                            : null,
                      ),
                      _buildInfoRow(
                        context,
                        Icons.email,
                        'Email',
                        booking.customerEmail ?? 'Not verified',
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Project info
                    _buildSection('Project Details', [
                      _buildInfoRow(
                        context,
                        Icons.construction,
                        'Type of Work', // Changed from Type of Service to match user preference
                        booking.typeOfWork,
                      ),
                      _buildInfoRow(
                        context,
                        Icons.place,
                        'Site Location',
                        (booking.siteLocation != null &&
                                booking.siteLocation!.isNotEmpty)
                            ? booking.siteLocation!
                            : 'Not provided',
                      ),
                      if (booking.plotSize != null &&
                          booking.plotSize!.isNotEmpty)
                        _buildInfoRow(
                          context,
                          Icons.square_foot,
                          'Plot Size',
                          booking.plotSize!,
                        ),
                      if (booking.budgetRange != null &&
                          booking.budgetRange!.isNotEmpty)
                        _buildInfoRow(
                          context,
                          Icons.currency_rupee,
                          'Budget Range',
                          booking.budgetRange!,
                        ),
                      _buildInfoRow(
                        context,
                        Icons.calendar_today,
                        'Preferred Date',
                        _formatDate(booking.preferredDate),
                      ),
                      if (booking.preferredTime != null &&
                          booking.preferredTime!.isNotEmpty)
                        _buildInfoRow(
                          context,
                          Icons.access_time,
                          'Preferred Time',
                          booking.preferredTime!,
                        ),
                    ]),
                    const SizedBox(height: 24),

                    // Additional notes
                    if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                      _buildSection('Customer Notes', [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.notes!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                    ],

                    // Metadata
                    _buildSection('Booking Info', [
                      _buildInfoRow(
                        context,
                        Icons.source,
                        'Source',
                        booking.source,
                      ),
                      _buildInfoRow(
                        context,
                        Icons.schedule,
                        'Created',
                        DateFormat(
                          'MMM d, yyyy HH:mm',
                        ).format(booking.createdAt),
                      ),
                      _buildInfoRow(
                        context,
                        Icons.update,
                        'Last Updated',
                        DateFormat(
                          'MMM d, yyyy HH:mm',
                        ).format(booking.updatedAt),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Internal notes
                    InternalNotesWidget(
                      bookingId: booking.id,
                      customerEmail: booking.customerEmail,
                    ),
                  ],
                ),
              ),

              // Fixed bottom action buttons
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).padding.bottom + 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a2e),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _makePhoneCall(booking.phone),
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openWhatsApp(booking.phone),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFF25D366),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? action,
  }) {
    // Special handling for Site Location with Google Maps link
    if (label == 'Site Location' && value.contains('[Google Maps:')) {
      final startIndex = value.indexOf('[Google Maps:');
      final endIndex = value.indexOf(']', startIndex);
      if (startIndex != -1 && endIndex != -1) {
        final addressPart = value.substring(0, startIndex).trim();
        final urlPart = value.substring(startIndex + 14, endIndex).trim();

        value = addressPart; // Display only address
        action = () async {
          final uri = Uri.parse(urlPart);
          try {
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open map')),
                );
              }
            }
          } catch (e) {
            print('Error launching map: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        };
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: action != null ? Colors.cyanAccent : null,
                        decoration: action != null
                            ? TextDecoration.underline
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null)
                Icon(Icons.open_in_new, size: 16, color: Colors.cyanAccent),
            ],
          ),
        ),
      ),
    );
  }
}
