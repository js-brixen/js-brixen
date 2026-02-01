import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all notifications, ordered by creation date (newest first)
  Stream<List<AppNotification>> streamNotifications({int limit = 50}) {
    return _firestore.collection('notifications').limit(limit).snapshots().map((
      snapshot,
    ) {
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
      // Sort in memory to avoid requiring a Firestore index
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  /// Stream unread notification count
  Stream<int> streamUnreadCount() {
    return _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final unreadDocs = await _firestore
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  /// Get notification by ID
  Future<AppNotification?> getNotification(String notificationId) async {
    final doc = await _firestore
        .collection('notifications')
        .doc(notificationId)
        .get();
    if (!doc.exists) return null;
    return AppNotification.fromFirestore(doc);
  }
}
