import 'package:cloud_firestore/cloud_firestore.dart';

class FeatureFlag {
  final String id;
  final String name;
  final bool isEnabled;

  FeatureFlag({
    required this.id,
    required this.name,
    required this.isEnabled,
  });

  factory FeatureFlag.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FeatureFlag(
      id: doc.id,
      name: data['name'] ?? '',
      isEnabled: data['isEnabled'] ?? false,
    );
  }
} 