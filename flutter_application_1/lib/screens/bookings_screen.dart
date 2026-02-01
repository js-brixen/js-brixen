import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../providers/bookings_provider.dart';
import '../widgets/booking_list_item.dart';
import '../widgets/filter_panel.dart';
import '../widgets/action_fab.dart';
import 'booking_detail_sheet.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final bookingDate = DateTime(date.year, date.month, date.day);

    if (bookingDate == today) {
      return 'Today';
    } else if (bookingDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Map<String, List<Booking>> _groupBookingsByDate(List<Booking> bookings) {
    // Use LinkedHashMap to preserve insertion order
    final Map<String, List<Booking>> grouped = {};

    // Sort bookings by date (newest first)
    final sortedBookings = List<Booking>.from(bookings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (var booking in sortedBookings) {
      final label = _getDateLabel(booking.createdAt);
      if (!grouped.containsKey(label)) {
        grouped[label] = [];
      }
      grouped[label]!.add(booking);
    }

    return grouped;
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterPanel(),
    );
  }

  void _showBookingDetail(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingDetailSheet(booking: booking),
    );
  }

  Future<void> _handleStatusChange(Booking booking, String newStatus) async {
    try {
      await context.read<BookingsProvider>().updateBookingStatus(
        booking.id,
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              const Color(0xFF0f3460),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<BookingsProvider>().setSearchQuery(
                              null,
                            );
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  context.read<BookingsProvider>().setSearchQuery(value);
                },
              ),
            ),

            // Quick status filters
            Consumer<BookingsProvider>(
              builder: (context, provider, _) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildQuickFilter(
                        'All',
                        provider.bookings.length,
                        provider.selectedStatuses.isEmpty,
                        () => provider.clearFilters(),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilter(
                        'New',
                        provider.getCountByStatus(BookingStatus.newBooking),
                        provider.selectedStatuses.contains('new'),
                        () => provider.setStatusFilter(['new']),
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilter(
                        'Contacted',
                        provider.getCountByStatus(BookingStatus.contacted),
                        provider.selectedStatuses.contains('contacted'),
                        () => provider.setStatusFilter(['contacted']),
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildQuickFilter(
                        'Follow Up',
                        provider.getCountByStatus(BookingStatus.followUp),
                        provider.selectedStatuses.contains('follow_up'),
                        () => provider.setStatusFilter(['follow_up']),
                        Colors.purple,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Bookings list
            Expanded(
              child: Consumer<BookingsProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${provider.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.startListening(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookings found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bookings from the website will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      provider.startListening();
                    },
                    child: Builder(
                      builder: (context) {
                        final groupedBookings = _groupBookingsByDate(
                          provider.bookings,
                        );
                        final dateLabels = groupedBookings.keys.toList();

                        // Calculate total items (bookings + separators)
                        int totalItems = 0;
                        for (var bookings in groupedBookings.values) {
                          totalItems += bookings.length + 1; // +1 for separator
                        }

                        return ListView.builder(
                          itemCount: totalItems,
                          itemBuilder: (context, index) {
                            int currentIndex = 0;

                            // Find which date group this index belongs to
                            for (var dateLabel in dateLabels) {
                              final bookingsInGroup =
                                  groupedBookings[dateLabel]!;

                              // Check if this is the separator
                              if (index == currentIndex) {
                                return _buildDateSeparator(dateLabel);
                              }

                              // Check if this is a booking in this group
                              final bookingIndexInGroup =
                                  index - currentIndex - 1;
                              if (bookingIndexInGroup >= 0 &&
                                  bookingIndexInGroup <
                                      bookingsInGroup.length) {
                                final booking =
                                    bookingsInGroup[bookingIndexInGroup];
                                return BookingListItem(
                                  booking: booking,
                                  onTap: () => _showBookingDetail(booking),
                                  onStatusChange: (status) =>
                                      _handleStatusChange(booking, status),
                                  onAssign: (uid) async {
                                    await provider.assignBooking(
                                      booking.id,
                                      uid,
                                    );
                                  },
                                );
                              }

                              currentIndex += bookingsInGroup.length + 1;
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ActionFab(onFilterPressed: _showFilterPanel),
    );
  }

  Widget _buildQuickFilter(
    String label,
    int count,
    bool isSelected,
    VoidCallback onTap, [
    Color? color,
  ]) {
    final filterColor = color ?? Colors.cyan;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? filterColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? filterColor
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? filterColor : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? filterColor.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? filterColor : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
