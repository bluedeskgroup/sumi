import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final int likes;
  final int dislikes;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
    this.likes = 0,
    this.dislikes = 0,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'مستخدم غير معروف',
      userAvatarUrl: data['userAvatarUrl'] ?? 'https://via.placeholder.com/150', // Placeholder
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'likes': likes,
      'dislikes': dislikes,
      'createdAt': createdAt,
    };
  }
} 