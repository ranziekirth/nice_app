// lib/models/feedback_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// One user review of the app: a 1-5 star rating plus an optional comment.
///
/// Unlike every other model, feedback is stored in a TOP-LEVEL `feedback`
/// collection (not under users/{uid}) so the admin account can read every
/// user's review in one query.
class FeedbackEntry {
  final String id;
  final String uid;
  final String name;
  final String email;
  final int rating; // 1-5
  final String message;
  final DateTime date;

  const FeedbackEntry({
    this.id = '',
    required this.uid,
    required this.name,
    required this.email,
    required this.rating,
    required this.message,
    required this.date,
  });

  factory FeedbackEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeedbackEntry(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      rating: ((data['rating'] as num?) ?? 5).clamp(1, 5).toInt(),
      message: data['message'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'rating': rating,
        'message': message,
        'date': Timestamp.fromDate(date),
      };
}
