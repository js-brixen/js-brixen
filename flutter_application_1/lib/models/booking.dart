import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  newBooking('new'),
  contacted('contacted'),
  followUp('follow_up'),
  scheduled('scheduled'),
  closed('closed');

  final String value;
  const BookingStatus(this.value);

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.newBooking,
    );
  }
}

class Booking {
  final String id;
  final String name;
  final String phone;
  final String district;
  final String typeOfWork;
  final String? plotSize;
  final String? budgetRange;
  final String? siteLocation;
  final DateTime? preferredDate;
  final String? preferredTime;
  final String? notes;
  final BookingStatus status;
  final String source;
  final String? relatedServiceId;
  final String? relatedProjectId;
  final String? assignedTo;
  final String priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Customer authentication fields
  final String? customerUid;
  final String? customerEmail;
  final String? customerPhone;

  Booking({
    required this.id,
    required this.name,
    required this.phone,
    required this.district,
    required this.typeOfWork,
    this.plotSize,
    this.budgetRange,
    this.siteLocation,
    this.preferredDate,
    this.preferredTime,
    this.notes,
    required this.status,
    required this.source,
    this.relatedServiceId,
    this.relatedProjectId,
    this.assignedTo,
    this.priority = 'normal',
    required this.createdAt,
    required this.updatedAt,
    this.customerUid,
    this.customerEmail,
    this.customerPhone,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    print(
      'DEBUG BOOKING ${doc.id}: customerPhone=${data['customerPhone']}, customerEmail=${data['customerEmail']}',
    );

    return Booking(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      district: data['district'] ?? '',
      typeOfWork: data['typeOfWork'] ?? '',
      plotSize: data['plotSize'],
      budgetRange: data['budgetRange'],
      siteLocation: data['siteLocation'],
      preferredDate: data['preferredDate'] != null
          ? (data['preferredDate'] as Timestamp).toDate()
          : null,
      preferredTime: data['preferredTime'],
      notes: data['notes'],
      status: BookingStatus.fromString(data['status'] ?? 'new'),
      source: data['source'] ?? 'website',
      relatedServiceId: data['relatedServiceId'],
      relatedProjectId: data['relatedProjectId'],
      assignedTo: data['assignedTo'],
      priority: data['priority'] ?? 'normal',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerUid: data['customerUid']?.toString(),
      customerEmail: data['customerEmail']?.toString(),
      customerPhone: data['customerPhone']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'district': district,
      'typeOfWork': typeOfWork,
      'plotSize': plotSize,
      'budgetRange': budgetRange,
      'siteLocation': siteLocation, // Added siteLocation
      'preferredDate': preferredDate != null
          ? Timestamp.fromDate(preferredDate!)
          : null,
      'preferredTime': preferredTime,
      'notes': notes,
      'status': status.value,
      'source': source,
      'relatedServiceId': relatedServiceId,
      'relatedProjectId': relatedProjectId,
      'assignedTo': assignedTo,
      'priority': priority,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get statusLabel {
    switch (status) {
      case BookingStatus.newBooking:
        return 'New';
      case BookingStatus.contacted:
        return 'Contacted';
      case BookingStatus.followUp:
        return 'Follow Up';
      case BookingStatus.scheduled:
        return 'Scheduled';
      case BookingStatus.closed:
        return 'Closed';
    }
  }

  String get formattedPhone {
    if (phone.length == 10) {
      return '${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }
}
