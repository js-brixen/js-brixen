import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newBooking('new_booking'),
  bookingNotFollowedUp('booking_not_followed_up'),
  viewSpike('view_spike'),
  systemAlert('system_alert');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.systemAlert,
    );
  }

  String get label {
    switch (this) {
      case NotificationType.newBooking:
        return 'New Booking';
      case NotificationType.bookingNotFollowedUp:
        return 'Follow-up Required';
      case NotificationType.viewSpike:
        return 'High Interest';
      case NotificationType.systemAlert:
        return 'System Alert';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? targetId;
  final String? targetType;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    this.targetType,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppNotification(
      id: doc.id,
      type: NotificationType.fromString(data['type'] ?? 'system_alert'),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      targetId: data['targetId'],
      targetType: data['targetType'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'title': title,
      'body': body,
      'targetId': targetId,
      'targetType': targetType,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? targetId,
    String? targetType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
