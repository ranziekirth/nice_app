// lib/models/tenant.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Tenant {
  final String id;
  final String name;
  final String room;

  const Tenant({
    required this.id,
    required this.name,
    required this.room,
  });

  factory Tenant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Tenant(
      id: doc.id,
      name: data['name'] as String? ?? '',
      room: data['room'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'room': room,
      };
}
