import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final String specialty;
  final double rating;
  final String imageUrl;
  final String location;
  final int reviewCount;
  final List<String> searchKeywords;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.specialty,
    required this.rating,
    required this.imageUrl,
    required this.location,
    this.reviewCount = 0,
    this.searchKeywords = const [],
  });

  factory ServiceProvider.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ServiceProvider(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      specialty: data['specialty'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      reviewCount: data['reviewCount'] ?? 0,
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'specialty': specialty,
      'rating': rating,
      'imageUrl': imageUrl,
      'location': location,
      'reviewCount': reviewCount,
      'searchKeywords': searchKeywords,
    };
  }
} 