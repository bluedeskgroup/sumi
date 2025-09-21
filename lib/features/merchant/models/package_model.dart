import 'package:cloud_firestore/cloud_firestore.dart';

enum PackageStatus {
  active,
  inactive,
  limited,
}

enum PackageType {
  product,
  service,
  mixed,
}

class PackageItem {
  final String id;
  final String name;
  final String type; // 'product' or 'service'
  final int quantity;
  final double originalPrice;

  PackageItem({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.originalPrice,
  });

  factory PackageItem.fromJson(Map<String, dynamic> json) {
    return PackageItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'product',
      quantity: json['quantity'] ?? 1,
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'quantity': quantity,
      'originalPrice': originalPrice,
    };
  }
}

class PackageModel {
  final String id;
  final String merchantId;
  final String name;
  final String description;
  final String category;
  final double price;
  final double originalPrice;
  final PackageType type;
  final PackageStatus status;
  final List<String> imageUrls;
  final List<String> tags;
  final List<PackageItem> items;
  final int validityDays;
  final int maxUses;
  final bool isLimited;
  final int availableQuantity;
  final Map<String, dynamic> terms;
  final bool isFeature;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? validUntil;

  PackageModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.type,
    required this.status,
    required this.imageUrls,
    required this.tags,
    required this.items,
    this.validityDays = 365,
    this.maxUses = 1,
    this.isLimited = false,
    this.availableQuantity = 0,
    required this.terms,
    this.isFeature = false,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
    this.validUntil,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] ?? '',
      merchantId: json['merchantId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      type: PackageType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] ?? 'mixed'),
        orElse: () => PackageType.mixed,
      ),
      status: PackageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'active'),
        orElse: () => PackageStatus.active,
      ),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => PackageItem.fromJson(item))
              .toList() ??
          [],
      validityDays: json['validityDays'] ?? 365,
      maxUses: json['maxUses'] ?? 1,
      isLimited: json['isLimited'] ?? false,
      availableQuantity: json['availableQuantity'] ?? 0,
      terms: Map<String, dynamic>.from(json['terms'] ?? {}),
      isFeature: json['isFeature'] ?? false,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      validUntil: json['validUntil'] is Timestamp
          ? (json['validUntil'] as Timestamp).toDate()
          : (json['validUntil'] != null
              ? DateTime.tryParse(json['validUntil'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'originalPrice': originalPrice,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'imageUrls': imageUrls,
      'tags': tags,
      'items': items.map((item) => item.toJson()).toList(),
      'validityDays': validityDays,
      'maxUses': maxUses,
      'isLimited': isLimited,
      'availableQuantity': availableQuantity,
      'terms': terms,
      'isFeature': isFeature,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
    };
  }

  PackageModel copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? description,
    String? category,
    double? price,
    double? originalPrice,
    PackageType? type,
    PackageStatus? status,
    List<String>? imageUrls,
    List<String>? tags,
    List<PackageItem>? items,
    int? validityDays,
    int? maxUses,
    bool? isLimited,
    int? availableQuantity,
    Map<String, dynamic>? terms,
    bool? isFeature,
    double? averageRating,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? validUntil,
  }) {
    return PackageModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      type: type ?? this.type,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      items: items ?? this.items,
      validityDays: validityDays ?? this.validityDays,
      maxUses: maxUses ?? this.maxUses,
      isLimited: isLimited ?? this.isLimited,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      terms: terms ?? this.terms,
      isFeature: isFeature ?? this.isFeature,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  double get discountAmount => originalPrice - price;
  double get discountPercentage {
    if (originalPrice <= 0) return 0.0;
    return (discountAmount / originalPrice) * 100;
  }

  bool get isAvailable {
    if (status != PackageStatus.active) return false;
    if (validUntil != null && validUntil!.isBefore(DateTime.now())) return false;
    if (isLimited && availableQuantity <= 0) return false;
    return true;
  }

  String get formattedValidity {
    if (validityDays < 30) {
      return '$validityDays يوم';
    } else if (validityDays < 365) {
      final months = validityDays ~/ 30;
      return '$months شهر';
    } else {
      final years = validityDays ~/ 365;
      return '$years سنة';
    }
  }
}
