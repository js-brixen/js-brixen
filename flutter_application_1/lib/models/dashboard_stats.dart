import 'project.dart';

/// Dashboard statistics model
class DashboardStats {
  final int newBookingsToday;
  final int newBookingsYesterday;
  final int totalOpenLeads;
  final int openLeadsYesterday;
  final Project? mostViewedProject;
  final int mostViewedProjectViews;
  final String? mostRequestedService;
  final int mostRequestedServiceCount;
  final DateTime calculatedAt;

  DashboardStats({
    required this.newBookingsToday,
    this.newBookingsYesterday = 0,
    required this.totalOpenLeads,
    this.openLeadsYesterday = 0,
    this.mostViewedProject,
    this.mostViewedProjectViews = 0,
    this.mostRequestedService,
    this.mostRequestedServiceCount = 0,
    required this.calculatedAt,
  });

  /// Trend for new bookings (compared to yesterday)
  int get newBookingsTrend => newBookingsToday - newBookingsYesterday;

  /// Trend for open leads (compared to yesterday)
  int get openLeadsTrend => totalOpenLeads - openLeadsYesterday;

  /// Formatted trend string for new bookings
  String get newBookingsTrendText {
    if (newBookingsTrend > 0) {
      return '+$newBookingsTrend from yesterday';
    } else if (newBookingsTrend < 0) {
      return '${newBookingsTrend} from yesterday';
    }
    return 'Same as yesterday';
  }

  /// Formatted trend string for open leads
  String get openLeadsTrendText {
    if (openLeadsTrend > 0) {
      return '+$openLeadsTrend from yesterday';
    } else if (openLeadsTrend < 0) {
      return '${openLeadsTrend} from yesterday';
    }
    return 'No change';
  }

  /// Check if data is fresh (less than 5 minutes old)
  bool get isFresh {
    final now = DateTime.now();
    final difference = now.difference(calculatedAt);
    return difference.inMinutes < 5;
  }

  /// Time since last calculation
  String get timeSinceCalculation {
    final now = DateTime.now();
    final difference = now.difference(calculatedAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    }
  }

  DashboardStats copyWith({
    int? newBookingsToday,
    int? newBookingsYesterday,
    int? totalOpenLeads,
    int? openLeadsYesterday,
    Project? mostViewedProject,
    int? mostViewedProjectViews,
    String? mostRequestedService,
    int? mostRequestedServiceCount,
    DateTime? calculatedAt,
  }) {
    return DashboardStats(
      newBookingsToday: newBookingsToday ?? this.newBookingsToday,
      newBookingsYesterday: newBookingsYesterday ?? this.newBookingsYesterday,
      totalOpenLeads: totalOpenLeads ?? this.totalOpenLeads,
      openLeadsYesterday: openLeadsYesterday ?? this.openLeadsYesterday,
      mostViewedProject: mostViewedProject ?? this.mostViewedProject,
      mostViewedProjectViews:
          mostViewedProjectViews ?? this.mostViewedProjectViews,
      mostRequestedService: mostRequestedService ?? this.mostRequestedService,
      mostRequestedServiceCount:
          mostRequestedServiceCount ?? this.mostRequestedServiceCount,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  /// Create empty stats
  factory DashboardStats.empty() {
    return DashboardStats(
      newBookingsToday: 0,
      newBookingsYesterday: 0,
      totalOpenLeads: 0,
      openLeadsYesterday: 0,
      mostViewedProject: null,
      mostViewedProjectViews: 0,
      mostRequestedService: null,
      mostRequestedServiceCount: 0,
      calculatedAt: DateTime.now(),
    );
  }
}
