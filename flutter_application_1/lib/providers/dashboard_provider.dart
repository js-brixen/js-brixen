import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/dashboard_stats.dart';
import '../models/project.dart';
import '../services/firestore_admin_service.dart';

class DashboardProvider with ChangeNotifier {
  final FirestoreAdminService _firestoreService = FirestoreAdminService();

  // State
  DashboardStats _stats = DashboardStats.empty();
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions
  StreamSubscription<List<Booking>>? _todayBookingsSubscription;
  StreamSubscription<int>? _openLeadsSubscription;
  StreamSubscription<Project?>? _mostViewedProjectSubscription;

  // Cache for service counts (updated less frequently)
  Map<String, int> _serviceRequestCounts = {};
  DateTime? _lastServiceCountsUpdate;

  // Getters
  DashboardStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DashboardProvider() {
    _initializeStreams();
  }

  /// Initialize all real-time streams
  void _initializeStreams() {
    _isLoading = true;
    notifyListeners();

    // Stream today's bookings
    _todayBookingsSubscription?.cancel();
    _todayBookingsSubscription = _firestoreService.streamBookingsToday().listen(
      (bookings) {
        _stats = _stats.copyWith(
          newBookingsToday: bookings.length,
          calculatedAt: DateTime.now(),
        );
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load today\'s bookings: $error';
        _isLoading = false;
        notifyListeners();
      },
    );

    // Stream open leads count
    _openLeadsSubscription?.cancel();
    _openLeadsSubscription = _firestoreService.streamOpenLeadsCount().listen(
      (count) {
        _stats = _stats.copyWith(
          totalOpenLeads: count,
          calculatedAt: DateTime.now(),
        );
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load open leads: $error';
        notifyListeners();
      },
    );

    // Stream most viewed project
    _mostViewedProjectSubscription?.cancel();
    _mostViewedProjectSubscription = _firestoreService
        .streamMostViewedProject()
        .listen(
          (project) {
            _stats = _stats.copyWith(
              mostViewedProject: project,
              mostViewedProjectViews: project?.views ?? 0,
              calculatedAt: DateTime.now(),
            );
            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to load most viewed project: $error';
            notifyListeners();
          },
        );

    // Load service request counts (not real-time, updated on refresh)
    _loadServiceRequestCounts();
  }

  /// Load service request counts (last 30 days)
  Future<void> _loadServiceRequestCounts() async {
    try {
      // Only update if cache is stale (older than 5 minutes)
      if (_lastServiceCountsUpdate != null) {
        final difference = DateTime.now().difference(_lastServiceCountsUpdate!);
        if (difference.inMinutes < 5) {
          return; // Use cached data
        }
      }

      _serviceRequestCounts = await _firestoreService.getServiceRequestCounts(
        days: 30,
      );
      _lastServiceCountsUpdate = DateTime.now();

      // Find the most requested service
      if (_serviceRequestCounts.isNotEmpty) {
        final sortedEntries = _serviceRequestCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topEntry = sortedEntries.first;
        _stats = _stats.copyWith(
          mostRequestedService: topEntry.key,
          mostRequestedServiceCount: topEntry.value,
          calculatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load service request counts: $e');
      // Don't set error here, it's not critical
    }
  }

  /// Manual refresh of all dashboard data
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Force reload service counts
      _lastServiceCountsUpdate = null;
      await _loadServiceRequestCounts();

      // Streams will auto-update
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh dashboard: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get count for a specific service
  int getServiceCount(String serviceName) {
    return _serviceRequestCounts[serviceName] ?? 0;
  }

  /// Get all service counts
  Map<String, int> get serviceRequestCounts => _serviceRequestCounts;

  @override
  void dispose() {
    _todayBookingsSubscription?.cancel();
    _openLeadsSubscription?.cancel();
    _mostViewedProjectSubscription?.cancel();
    super.dispose();
  }
}
