import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project.dart';
import '../models/service.dart';
import '../models/booking.dart';

class DataPoint {
  final String label;
  final double value;
  final DateTime? date;

  DataPoint({required this.label, required this.value, this.date});
}

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get project analytics summary
  Future<Map<String, dynamic>> getProjectAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    Query query = _firestore.collection('projects');

    if (from != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: from);
    }
    if (to != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: to);
    }

    final snapshot = await query.get();
    final projects = snapshot.docs
        .map((doc) => Project.fromFirestore(doc))
        .toList();

    int totalViews = 0;
    int totalConversions = 0;

    for (final project in projects) {
      totalViews += project.views;
      totalConversions += project.bookingConversions;
    }

    return {
      'totalProjects': projects.length,
      'totalViews': totalViews,
      'totalConversions': totalConversions,
      'conversionRate': totalViews > 0
          ? (totalConversions / totalViews * 100)
          : 0.0,
      'projects': projects,
    };
  }

  /// Stream top projects by views
  Stream<List<Project>> streamTopProjects({int limit = 5}) {
    return _firestore
        .collection('projects')
        .where('status', isEqualTo: 'live')
        .orderBy('views', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList(),
        );
  }

  /// Get service analytics summary
  Future<Map<String, dynamic>> getServiceAnalytics({
    DateTime? from,
    DateTime? to,
  }) async {
    Query query = _firestore.collection('services');

    if (from != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: from);
    }
    if (to != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: to);
    }

    final snapshot = await query.get();
    final services = snapshot.docs
        .map((doc) => Service.fromFirestore(doc))
        .toList();

    int totalViews = 0;
    int totalConversions = 0;

    for (final service in services) {
      totalViews += service.views;
      totalConversions += service.bookingConversions;
    }

    return {
      'totalServices': services.length,
      'totalViews': totalViews,
      'totalConversions': totalConversions,
      'conversionRate': totalViews > 0
          ? (totalConversions / totalViews * 100)
          : 0.0,
      'services': services,
    };
  }

  /// Get bookings per service
  Future<Map<String, int>> getBookingsPerService() async {
    final snapshot = await _firestore.collection('bookings').get();
    final bookings = snapshot.docs
        .map((doc) => Booking.fromFirestore(doc))
        .toList();

    final Map<String, int> result = {};

    for (final booking in bookings) {
      if (booking.relatedServiceId != null) {
        result[booking.relatedServiceId!] =
            (result[booking.relatedServiceId!] ?? 0) + 1;
      }
    }

    return result;
  }

  /// Get bookings per project
  Future<Map<String, int>> getBookingsPerProject() async {
    final snapshot = await _firestore.collection('bookings').get();
    final bookings = snapshot.docs
        .map((doc) => Booking.fromFirestore(doc))
        .toList();

    final Map<String, int> result = {};

    for (final booking in bookings) {
      if (booking.relatedProjectId != null) {
        result[booking.relatedProjectId!] =
            (result[booking.relatedProjectId!] ?? 0) + 1;
      }
    }

    return result;
  }

  /// Get peak enquiry periods (bookings grouped by hour of day)
  Future<List<DataPoint>> getPeakEnquiryPeriods() async {
    final snapshot = await _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();

    final bookings = snapshot.docs
        .map((doc) => Booking.fromFirestore(doc))
        .toList();

    final Map<int, int> hourCounts = {};

    for (final booking in bookings) {
      final hour = booking.createdAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    return hourCounts.entries
        .map(
          (entry) => DataPoint(
            label: '${entry.key}:00',
            value: entry.value.toDouble(),
          ),
        )
        .toList()
      ..sort(
        (a, b) => int.parse(
          a.label.split(':')[0],
        ).compareTo(int.parse(b.label.split(':')[0])),
      );
  }

  /// Get weekly trend for projects or services
  Future<List<DataPoint>> getWeeklyTrend(String type) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final collection = type == 'projects' ? 'projects' : 'services';

    final snapshot = await _firestore
        .collection(collection)
        .where('createdAt', isGreaterThanOrEqualTo: sevenDaysAgo)
        .get();

    final Map<String, int> dayCounts = {};

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.month}/${date.day}';
      dayCounts[key] = 0;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final key = '${createdAt.month}/${createdAt.day}';
        dayCounts[key] = (dayCounts[key] ?? 0) + 1;
      }
    }

    return dayCounts.entries
        .map(
          (entry) => DataPoint(label: entry.key, value: entry.value.toDouble()),
        )
        .toList();
  }

  /// Get monthly trend for projects or services
  Future<List<DataPoint>> getMonthlyTrend(String type) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final collection = type == 'projects' ? 'projects' : 'services';

    final snapshot = await _firestore
        .collection(collection)
        .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
        .get();

    final Map<String, int> weekCounts = {};

    for (int i = 0; i < 4; i++) {
      weekCounts['Week ${i + 1}'] = 0;
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final daysDiff = now.difference(createdAt).inDays;
        final weekNum = (daysDiff / 7).floor();
        if (weekNum < 4) {
          final key = 'Week ${4 - weekNum}';
          weekCounts[key] = (weekCounts[key] ?? 0) + 1;
        }
      }
    }

    return weekCounts.entries
        .map(
          (entry) => DataPoint(label: entry.key, value: entry.value.toDouble()),
        )
        .toList();
  }

  /// Get total bookings count
  Future<int> getTotalBookings({DateTime? from, DateTime? to}) async {
    Query query = _firestore.collection('bookings');

    if (from != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: from);
    }
    if (to != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: to);
    }

    final snapshot = await query.get();
    return snapshot.docs.length;
  }

  /// Get bookings by status
  Future<Map<String, int>> getBookingsByStatus() async {
    final snapshot = await _firestore.collection('bookings').get();
    final bookings = snapshot.docs
        .map((doc) => Booking.fromFirestore(doc))
        .toList();

    final Map<String, int> result = {};

    for (final booking in bookings) {
      final status = booking.status.value;
      result[status] = (result[status] ?? 0) + 1;
    }

    return result;
  }

  /// Get bookings grouped by district/location
  Future<Map<String, int>> getBookingsByDistrict({
    DateTime? from,
    DateTime? to,
  }) async {
    Query query = _firestore.collection('bookings');

    if (from != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: from);
    }
    if (to != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: to);
    }

    final snapshot = await query.get();
    final bookings = snapshot.docs
        .map((doc) => Booking.fromFirestore(doc))
        .toList();

    final Map<String, int> result = {};

    for (final booking in bookings) {
      final district = booking.district.trim();
      if (district.isNotEmpty) {
        result[district] = (result[district] ?? 0) + 1;
      }
    }

    return result;
  }

  /// Get total views (projects + services) grouped by district
  Future<Map<String, int>> getViewsByDistrict({
    DateTime? from,
    DateTime? to,
  }) async {
    final Map<String, int> result = {};

    // Get project views by district
    Query projectQuery = _firestore.collection('projects');
    if (from != null) {
      projectQuery = projectQuery.where(
        'createdAt',
        isGreaterThanOrEqualTo: from,
      );
    }
    if (to != null) {
      projectQuery = projectQuery.where('createdAt', isLessThanOrEqualTo: to);
    }

    final projectSnapshot = await projectQuery.get();
    final projects = projectSnapshot.docs
        .map((doc) => Project.fromFirestore(doc))
        .toList();

    for (final project in projects) {
      final district = project.district.trim();
      if (district.isNotEmpty && project.views > 0) {
        result[district] = (result[district] ?? 0) + project.views;
      }
    }

    // Note: Services don't have district field, only projects do
    // If you want service views by something else, add logic here

    return result;
  }
}
