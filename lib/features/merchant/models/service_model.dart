import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceStatus {
  active,
  inactive,
  suspended,
}

enum ServiceType {
  oneTime,
  recurring,
  appointment,
  consultation,
}

class ServiceModel {
  final String id;
  final String merchantId;
  final String name;
  final String description;
  final String category;
  final double price;
  final double? discountPrice;
  final ServiceType type;
  final ServiceStatus status;
  final List<String> imageUrls;
  final List<String> tags;
  final int durationMinutes;
  final bool isOnline;
  final bool isAtLocation;
  final List<String> availableDays;
  final String startTime;
  final String endTime;
  final Map<String, dynamic> requirements;
  final bool isFeature;
  final double averageRating;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.discountPrice,
    required this.type,
    required this.status,
    required this.imageUrls,
    required this.tags,
    required this.durationMinutes,
    this.isOnline = false,
    this.isAtLocation = true,
    required this.availableDays,
    required this.startTime,
    required this.endTime,
    required this.requirements,
    this.isFeature = false,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? '',
      merchantId: json['merchantId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      type: ServiceType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] ?? 'oneTime'),
        orElse: () => ServiceType.oneTime,
      ),
      status: ServiceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'active'),
        orElse: () => ServiceStatus.active,
      ),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      durationMinutes: json['durationMinutes'] ?? 60,
      isOnline: json['isOnline'] ?? false,
      isAtLocation: json['isAtLocation'] ?? true,
      availableDays: List<String>.from(json['availableDays'] ?? []),
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      isFeature: json['isFeature'] ?? false,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
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
      'description': description,
      'category': category,
      'price': price,
      'discountPrice': discountPrice,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'imageUrls': imageUrls,
      'tags': tags,
      'durationMinutes': durationMinutes,
      'isOnline': isOnline,
      'isAtLocation': isAtLocation,
      'availableDays': availableDays,
      'startTime': startTime,
      'endTime': endTime,
      'requirements': requirements,
      'isFeature': isFeature,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? description,
    String? category,
    double? price,
    double? discountPrice,
    ServiceType? type,
    ServiceStatus? status,
    List<String>? imageUrls,
    List<String>? tags,
    int? durationMinutes,
    bool? isOnline,
    bool? isAtLocation,
    List<String>? availableDays,
    String? startTime,
    String? endTime,
    Map<String, dynamic>? requirements,
    bool? isFeature,
    double? averageRating,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      type: type ?? this.type,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      tags: tags ?? this.tags,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isOnline: isOnline ?? this.isOnline,
      isAtLocation: isAtLocation ?? this.isAtLocation,
      availableDays: availableDays ?? this.availableDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      requirements: requirements ?? this.requirements,
      isFeature: isFeature ?? this.isFeature,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  double get displayPrice => discountPrice ?? price;
  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((price - discountPrice!) / price) * 100;
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes دقيقة';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours ساعة';
      } else {
        return '$hours ساعة و $minutes دقيقة';
      }
    }
  }
}
