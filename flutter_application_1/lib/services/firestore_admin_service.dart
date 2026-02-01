import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking.dart';
import '../models/internal_note.dart';
import '../models/project.dart';
import '../models/service.dart';

class FirestoreAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream bookings with filters
  Stream<List<Booking>> streamBookings({
    List<String>? statuses,
    String? searchQuery,
    String? serviceId,
    String? projectId,
    DateTime? from,
    DateTime? to,
    int limit = 50,
    String? assignedTo,
  }) {
    Query query = _firestore.collection('bookings');

    // Apply filters
    if (statuses != null && statuses.isNotEmpty) {
      query = query.where('status', whereIn: statuses);
    }

    if (serviceId != null) {
      query = query.where('relatedServiceId', isEqualTo: serviceId);
    }

    if (projectId != null) {
      query = query.where('relatedProjectId', isEqualTo: projectId);
    }

    if (assignedTo != null) {
      query = query.where('assignedTo', isEqualTo: assignedTo);
    }

    if (from != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(from),
      );
    }

    if (to != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(to),
      );
    }

    // Order and limit
    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      var bookings = snapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();

      // Client-side search filter (for name/phone)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        bookings = bookings.where((booking) {
          return booking.name.toLowerCase().contains(lowerQuery) ||
              booking.phone.contains(searchQuery);
        }).toList();
      }

      return bookings;
    });
  }

  // Stream open leads count
  Stream<int> streamOpenLeadsCount() {
    return _firestore
        .collection('bookings')
        .where('status', whereNotIn: ['closed'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Count bookings created today
  Future<int> countBookingsToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection('bookings')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('status', isEqualTo: 'new')
        .get();

    return snapshot.docs.length;
  }

  // ========== DASHBOARD METHODS ==========

  /// Stream bookings created today (real-time)
  Stream<List<Booking>> streamBookingsToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('bookings')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList(),
        );
  }

  /// Stream the most viewed project
  Stream<Project?> streamMostViewedProject() {
    return _firestore
        .collection('projects')
        .where('status', isEqualTo: 'live')
        .orderBy('views', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Project.fromFirestore(snapshot.docs.first);
        });
  }

  /// Get service request counts (aggregated from bookings)
  Future<Map<String, int>> getServiceRequestCounts({int days = 30}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('bookings')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .get();

    // Aggregate counts by typeOfWork
    final Map<String, int> counts = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final typeOfWork = data['typeOfWork'] as String?;
      if (typeOfWork != null && typeOfWork.isNotEmpty) {
        counts[typeOfWork] = (counts[typeOfWork] ?? 0) + 1;
      }
    }

    return counts;
  }

  // Update booking status
  Future<void> updateBookingStatus(
    String bookingId,
    String newStatus, {
    String? changedByUid,
  }) async {
    final batch = _firestore.batch();

    // Update booking document
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add audit entry
    final auditRef = bookingRef.collection('audit').doc();
    batch.set(auditRef, {
      'action': 'status_changed',
      'newValue': newStatus,
      'actorUid': changedByUid ?? _auth.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Add internal note
  Future<void> addInternalNote(
    String bookingId, {
    required String text,
    String? authorUid,
    String? authorName,
  }) async {
    final user = _auth.currentUser;

    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('internalNotes')
        .add({
          'text': text,
          'authorUid': authorUid ?? user?.uid ?? 'unknown',
          'authorName': authorName ?? user?.email ?? 'Admin',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // Stream internal notes for a booking
  Stream<List<InternalNote>> streamInternalNotes(String bookingId) {
    return _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('internalNotes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InternalNote.fromFirestore(doc))
              .toList(),
        );
  }

  // Delete an internal note
  Future<void> deleteInternalNote(String bookingId, String noteId) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('internalNotes')
        .doc(noteId)
        .delete();
  }

  // Assign booking to staff
  Future<void> assignBooking(String bookingId, String? staffUid) async {
    final batch = _firestore.batch();

    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'assignedTo': staffUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Add audit entry
    final auditRef = bookingRef.collection('audit').doc();
    batch.set(auditRef, {
      'action': 'assigned',
      'newValue': staffUid ?? 'unassigned',
      'actorUid': _auth.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Attach file (Cloudinary URL)
  Future<void> attachFile(
    String bookingId, {
    required String url,
    required String filename,
    String? uploadedBy,
  }) async {
    await _firestore
        .collection('bookings')
        .doc(bookingId)
        .collection('attachments')
        .add({
          'url': url,
          'filename': filename,
          'uploadedBy': uploadedBy ?? _auth.currentUser?.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // Create booking from admin
  Future<String> createBookingFromAdmin(
    Map<String, dynamic> bookingData,
  ) async {
    bookingData['status'] = 'new';
    bookingData['source'] = 'admin_app';
    bookingData['createdAt'] = FieldValue.serverTimestamp();
    bookingData['updatedAt'] = FieldValue.serverTimestamp();

    final docRef = await _firestore.collection('bookings').add(bookingData);
    return docRef.id;
  }

  // Delete booking (admin only)
  Future<void> deleteBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).delete();
  }

  // ========== PROJECTS MANAGEMENT ==========

  Stream<List<Project>> streamProjects({
    String? status,
    String? type,
    bool? featuredOnly,
    String? searchQuery,
    int limit = 50,
  }) {
    Query query = _firestore.collection('projects');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    if (featuredOnly == true) {
      query = query.where('isFeatured', isEqualTo: true);
    }

    // Removed orderBy to avoid composite index requirement
    // Will sort client-side in the provider
    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      var projects = snapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList();

      // Sort client-side by createdAt descending (newest first)
      projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        projects = projects.where((project) {
          return project.title.toLowerCase().contains(lowerQuery) ||
              project.district.toLowerCase().contains(lowerQuery) ||
              project.summary.toLowerCase().contains(lowerQuery) ||
              project.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
      }

      return projects;
    });
  }

  Future<Project?> getProject(String projectId) async {
    final doc = await _firestore.collection('projects').doc(projectId).get();
    if (!doc.exists) return null;
    return Project.fromFirestore(doc);
  }

  Future<String> createProject(Map<String, dynamic> projectData) async {
    projectData['createdAt'] = FieldValue.serverTimestamp();
    projectData['updatedAt'] = FieldValue.serverTimestamp();
    projectData['views'] = 0;
    projectData['bookingConversions'] = 0;

    final docRef = await _firestore.collection('projects').add(projectData);
    return docRef.id;
  }

  Future<void> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('projects').doc(projectId).update(updates);
  }

  Future<void> deleteProject(String projectId) async {
    await _firestore.collection('projects').doc(projectId).delete();
  }

  Future<void> toggleProjectStatus(String projectId, String newStatus) async {
    await _firestore.collection('projects').doc(projectId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleFeatured(String projectId, bool isFeatured) async {
    await _firestore.collection('projects').doc(projectId).update({
      'isFeatured': isFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementProjectViews(String projectId) async {
    await _firestore.collection('projects').doc(projectId).update({
      'views': FieldValue.increment(1),
    });
  }

  Future<void> trackProjectConversion(String projectId) async {
    await _firestore.collection('projects').doc(projectId).update({
      'bookingConversions': FieldValue.increment(1),
    });
  }

  // ========== SERVICES MANAGEMENT ==========

  Stream<List<Service>> streamServices({
    String? status,
    String? searchQuery,
    int limit = 50,
  }) {
    Query query = _firestore.collection('services');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      var services = snapshot.docs
          .map((doc) => Service.fromFirestore(doc))
          .toList();

      // Sort client-side by createdAt descending (newest first)
      services.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        services = services.where((service) {
          return service.title.toLowerCase().contains(lowerQuery) ||
              service.shortDescription.toLowerCase().contains(lowerQuery) ||
              service.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
        }).toList();
      }

      return services;
    });
  }

  Future<Service?> getService(String serviceId) async {
    final doc = await _firestore.collection('services').doc(serviceId).get();
    if (!doc.exists) return null;
    return Service.fromFirestore(doc);
  }

  Future<String> createService(Map<String, dynamic> serviceData) async {
    serviceData['createdAt'] = FieldValue.serverTimestamp();
    serviceData['updatedAt'] = FieldValue.serverTimestamp();
    serviceData['views'] = 0;
    serviceData['bookingConversions'] = 0;

    final docRef = await _firestore.collection('services').add(serviceData);
    return docRef.id;
  }

  Future<void> updateService(
    String serviceId,
    Map<String, dynamic> updates,
  ) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('services').doc(serviceId).update(updates);
  }

  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  Future<void> toggleServiceStatus(String serviceId, String newStatus) async {
    await _firestore.collection('services').doc(serviceId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> incrementServiceViews(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'views': FieldValue.increment(1),
    });
  }

  Future<void> trackServiceConversion(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'bookingConversions': FieldValue.increment(1),
    });
  }

  // ========== NOTIFICATIONS ==========

  /// Create a notification (free alternative to Cloud Functions)
  Future<void> createNotification({
    required String type,
    required String title,
    required String body,
    String? targetId,
    String? targetType,
  }) async {
    await _firestore.collection('notifications').add({
      'type': type,
      'title': title,
      'body': body,
      'targetId': targetId,
      'targetType': targetType,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark notifications for a specific booking as read
  Future<void> markBookingNotificationsAsRead(String bookingId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('targetId', isEqualTo: bookingId)
        .where('targetType', isEqualTo: 'booking')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    if (snapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // Bulk delete all bookings
  Future<void> deleteAllBookings() async {
    final querySnapshot = await _firestore.collection('bookings').get();
    final batch = _firestore.batch();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Bulk delete all projects
  Future<void> deleteAllProjects() async {
    final querySnapshot = await _firestore.collection('projects').get();
    final batch = _firestore.batch();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Bulk delete all services
  Future<void> deleteAllServices() async {
    final querySnapshot = await _firestore.collection('services').get();
    final batch = _firestore.batch();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Bulk delete all notifications
  Future<void> deleteAllNotifications() async {
    final querySnapshot = await _firestore.collection('notifications').get();
    final batch = _firestore.batch();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Clear all analytics data
  Future<void> clearAnalytics() async {
    final querySnapshot = await _firestore.collection('analytics').get();
    final batch = _firestore.batch();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ========== APP SETTINGS ==========

  Stream<DocumentSnapshot> streamAppSettings() {
    return _firestore.collection('appSettings').doc('general').snapshots();
  }

  Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    await _firestore
        .collection('appSettings')
        .doc('general')
        .set(settings, SetOptions(merge: true));
  }
}
