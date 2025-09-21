import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryStatus {
  active,
  inactive,
}

class CategoryModel {
  final String id;
  final String merchantId;
  final String name;
  final String nameEn;
  final String description;
  final String iconUrl;
  final String imageUrl;
  final CategoryStatus status;
  final int sortOrder;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.merchantId,
    required this.name,
    this.nameEn = '',
    this.description = '',
    this.iconUrl = '',
    this.imageUrl = '',
    required this.status,
    this.sortOrder = 0,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      merchantId: json['merchantId'] ?? '',
      name: json['name'] ?? '',
      nameEn: json['nameEn'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      status: CategoryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'active'),
        orElse: () => CategoryStatus.active,
      ),
      sortOrder: json['sortOrder'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'nameEn': nameEn,
      'description': description,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
      'sortOrder': sortOrder,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? nameEn,
    String? description,
    String? iconUrl,
    String? imageUrl,
    CategoryStatus? status,
    int? sortOrder,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
