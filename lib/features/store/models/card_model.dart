import 'package:cloud_firestore/cloud_firestore.dart';

class CardModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final List<String> features;
  final double price;
  final bool isFree;
  final bool isActive;
  final Map<String, dynamic> cardDesign; // لحفظ الألوان والتصميم
  final DateTime createdAt;
  final DateTime? updatedAt;

  CardModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.features,
    required this.price,
    required this.isFree,
    required this.isActive,
    required this.cardDesign,
    required this.createdAt,
    this.updatedAt,
  });

  factory CardModel.fromMap(String id, Map<String, dynamic> data) {
    return CardModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      features: List<String>.from(data['features'] ?? []),
      price: (data['price'] ?? 0.0).toDouble(),
      isFree: data['isFree'] ?? true,
      isActive: data['isActive'] ?? true,
      cardDesign: Map<String, dynamic>.from(data['cardDesign'] ?? {}),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'features': features,
      'price': price,
      'isFree': isFree,
      'isActive': isActive,
      'cardDesign': cardDesign,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  CardModel copy({
    String? title,
    String? description,
    String? imageUrl,
    List<String>? features,
    double? price,
    bool? isFree,
    bool? isActive,
    Map<String, dynamic>? cardDesign,
    DateTime? updatedAt,
  }) {
    return CardModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      features: features ?? this.features,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      isActive: isActive ?? this.isActive,
      cardDesign: cardDesign ?? this.cardDesign,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class UserCardRequest {
  final String id;
  final String userId;
  final String cardId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedBy; // Admin user ID

  UserCardRequest({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.status,
    this.rejectionReason,
    required this.requestedAt,
    this.processedAt,
    this.processedBy,
  });

  factory UserCardRequest.fromMap(String id, Map<String, dynamic> data) {
    return UserCardRequest(
      id: id,
      userId: data['userId'] ?? '',
      cardId: data['cardId'] ?? '',
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      requestedAt: data['requestedAt'] != null 
          ? (data['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      processedAt: data['processedAt'] != null 
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      processedBy: data['processedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'cardId': cardId,
      'status': status,
      'rejectionReason': rejectionReason,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'processedBy': processedBy,
    };
  }
}

class UserCard {
  final String id;
  final String userId;
  final String cardId;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic>? customData; // بيانات إضافية خاصة بالمستخدم

  UserCard({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.issuedAt,
    this.expiresAt,
    required this.isActive,
    this.customData,
  });

  factory UserCard.fromMap(String id, Map<String, dynamic> data) {
    return UserCard(
      id: id,
      userId: data['userId'] ?? '',
      cardId: data['cardId'] ?? '',
      issuedAt: data['issuedAt'] != null 
          ? (data['issuedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      customData: data['customData'] != null 
          ? Map<String, dynamic>.from(data['customData'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'cardId': cardId,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'customData': customData,
    };
  }

  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  bool get isValid {
    return isActive && !isExpired;
  }
}