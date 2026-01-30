import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../services/firestore_admin_service.dart';

class BookingsProvider with ChangeNotifier {
  final FirestoreAdminService _firestoreService = FirestoreAdminService();

  // State
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  List<String> _selectedStatuses = [];
  String? _searchQuery;
  String? _selectedServiceId;
  String? _selectedProjectId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String? _assignedTo;

  // Stream subscription
  StreamSubscription<List<Booking>>? _bookingsSubscription;
  StreamSubscription<int>? _openLeadsSubscription;

  int _openLeadsCount = 0;

  // Track seen bookings to detect new ones
  final Set<String> _seenBookingIds = {};
  bool _isFirstLoad = true;

  // Getters
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get selectedStatuses => _selectedStatuses;
  String? get searchQuery => _searchQuery;
  int get openLeadsCount => _openLeadsCount;

  BookingsProvider() {
    // Initialize streams
    startListening();
    _listenToOpenLeadsCount();
  }

  /// Start listening to bookings stream
  void startListening() {
    _isLoading = true;
    notifyListeners();

    _bookingsSubscription?.cancel();
    _bookingsSubscription = _firestoreService
        .streamBookings(
          statuses: _selectedStatuses.isEmpty ? null : _selectedStatuses,
          searchQuery: _searchQuery,
          serviceId: _selectedServiceId,
          projectId: _selectedProjectId,
          from: _dateFrom,
          to: _dateTo,
          assignedTo: _assignedTo,
        )
        .listen(
          (bookings) async {
            if (_isFirstLoad) {
              // First load: just mark all existing bookings as seen
              // (don't create notifications for bookings that already existed)
              for (final booking in bookings) {
                _seenBookingIds.add(booking.id);
              }
              _isFirstLoad = false;
            } else {
              // Subsequent updates: create notifications for NEW bookings only
              for (final booking in bookings) {
                if (!_seenBookingIds.contains(booking.id) &&
                    booking.status == BookingStatus.newBooking) {
                  // This is a truly new booking that arrived after app started
                  await _createNotificationForNewBooking(booking);
                  _seenBookingIds.add(booking.id);
                }
              }
            }

            _bookings = bookings;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            _error = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Listen to open leads count
  void _listenToOpenLeadsCount() {
    _openLeadsSubscription?.cancel();
    _openLeadsSubscription = _firestoreService.streamOpenLeadsCount().listen((
      count,
    ) {
      _openLeadsCount = count;
      notifyListeners();
    });
  }

  /// Apply status filter
  void setStatusFilter(List<String> statuses) {
    _selectedStatuses = statuses;
    startListening();
  }

  /// Toggle single status
  void toggleStatus(String status) {
    if (_selectedStatuses.contains(status)) {
      _selectedStatuses.remove(status);
    } else {
      _selectedStatuses.add(status);
    }
    startListening();
  }

  /// Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query?.trim();
    startListening();
  }

  /// Set date range filter
  void setDateRange(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    startListening();
  }

  /// Set service filter
  void setServiceFilter(String? serviceId) {
    _selectedServiceId = serviceId;
    startListening();
  }

  /// Set assigned to filter
  void setAssignedToFilter(String? uid) {
    _assignedTo = uid;
    startListening();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedStatuses = [];
    _searchQuery = null;
    _selectedServiceId = null;
    _selectedProjectId = null;
    _dateFrom = null;
    _dateTo = null;
    _assignedTo = null;
    startListening();
  }

  /// Update booking status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestoreService.updateBookingStatus(bookingId, newStatus);
      // Automatically mark notifications as read if status is changed from 'new'
      if (newStatus != 'new') {
        await _firestoreService.markBookingNotificationsAsRead(bookingId);
      }
      // Stream will auto-update
    } catch (e) {
      _error = 'Failed to update status: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Add internal note
  Future<void> addInternalNote(String bookingId, String text) async {
    try {
      await _firestoreService.addInternalNote(bookingId, text: text);
    } catch (e) {
      _error = 'Failed to add note: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Assign booking
  Future<void> assignBooking(String bookingId, String? staffUid) async {
    try {
      await _firestoreService.assignBooking(bookingId, staffUid);
    } catch (e) {
      _error = 'Failed to assign booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _firestoreService.deleteBooking(bookingId);
    } catch (e) {
      _error = 'Failed to delete booking: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Get bookings count by status
  int getCountByStatus(BookingStatus status) {
    return _bookings.where((b) => b.status == status).length;
  }

  /// Create notification for new booking (free alternative to Cloud Functions)
  Future<void> _createNotificationForNewBooking(Booking booking) async {
    try {
      await _firestoreService.createNotification(
        type: 'new_booking',
        title: 'New Booking Received',
        body:
            '${booking.name} from ${booking.district} - ${booking.typeOfWork}',
        targetId: booking.id,
        targetType: 'booking',
      );
    } catch (e) {
      // Silently fail - don't disrupt the booking flow
      debugPrint('Failed to create notification: $e');
    }
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _openLeadsSubscription?.cancel();
    super.dispose();
  }
}
