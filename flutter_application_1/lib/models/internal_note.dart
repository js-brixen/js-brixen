import 'package:cloud_firestore/cloud_firestore.dart';

class InternalNote {
  final String id;
  final String text;
  final String authorUid;
  final String authorName;
  final DateTime createdAt;

  InternalNote({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorName,
    required this.createdAt,
  });

  factory InternalNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return InternalNote(
      id: doc.id,
      text: data['text'] ?? '',
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'authorUid': authorUid,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
