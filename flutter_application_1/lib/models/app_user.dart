import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPrefs {
  final bool bookingAlerts;
  final bool systemNotifications;

  NotificationPrefs({
    this.bookingAlerts = true,
    this.systemNotifications = true,
  });

  factory NotificationPrefs.fromMap(Map<String, dynamic> map) {
    return NotificationPrefs(
      bookingAlerts: map['bookingAlerts'] ?? true,
      systemNotifications: map['systemNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingAlerts': bookingAlerts,
      'systemNotifications': systemNotifications,
    };
  }

  NotificationPrefs copyWith({bool? bookingAlerts, bool? systemNotifications}) {
    return NotificationPrefs(
      bookingAlerts: bookingAlerts ?? this.bookingAlerts,
      systemNotifications: systemNotifications ?? this.systemNotifications,
    );
  }
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final NotificationPrefs notificationPrefs;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    this.lastLoginAt,
    required this.notificationPrefs,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isActive => status == 'active';
  bool get isDisabled => status == 'disabled';

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'staff',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      notificationPrefs: data['notificationPrefs'] != null
          ? NotificationPrefs.fromMap(data['notificationPrefs'])
          : NotificationPrefs(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'notificationPrefs': notificationPrefs.toMap(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? status,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    NotificationPrefs? notificationPrefs,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    );
  }
}
