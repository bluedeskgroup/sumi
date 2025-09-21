import 'package:cloud_firestore/cloud_firestore.dart';

class PointsTransaction {
  final String id;
  final int points;
  final String description;
  final DateTime createdAt;
  final String type; // e.g., 'challenge', 'redeem'

  PointsTransaction({
    required this.id,
    required this.points,
    required this.description,
    required this.createdAt,
    required this.type,
  });

  factory PointsTransaction.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PointsTransaction(
      id: doc.id,
      points: data['points'] ?? 0,
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: data['type'] ?? '',
    );
  }
} 