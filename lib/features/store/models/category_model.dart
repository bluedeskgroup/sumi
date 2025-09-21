import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryType {
  product,
  service,
}

class Category {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isActive;
  final int displayOrder;
  final CategoryType type;
  final String? parentId;
  final Timestamp? createdAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.isActive = true,
    this.displayOrder = 0,
    required this.type,
    this.parentId,
    this.createdAt,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      displayOrder: (data['displayOrder'] ?? 0).toInt(),
      type: _getCategoryTypeFromString(data['type'] ?? 'product'),
      parentId: data['parentId'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'displayOrder': displayOrder,
      'type': type.toString().split('.').last,
      'parentId': parentId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
  
  static CategoryType _getCategoryTypeFromString(String typeStr) {
    switch (typeStr) {
      case 'service':
        return CategoryType.service;
      case 'product':
      default:
        return CategoryType.product;
    }
  }
  
  Category copyWith({
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
    int? displayOrder,
    CategoryType? type,
    String? parentId,
    Timestamp? createdAt,
  }) {
    return Category(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 