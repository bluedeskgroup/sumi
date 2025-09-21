import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String userId;
  final String userName;
  final String userImage;
  final String email;
  final List<String> subscribers;
  final List<String> subscriptions;

  AppUser({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.email,
    required this.subscribers,
    required this.subscriptions,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'مستخدم سومي',
      userImage: data['userImage'] ?? '',
      email: data['email'] ?? '',
      subscribers: List<String>.from(data['subscribers'] ?? []),
      subscriptions: List<String>.from(data['subscriptions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'email': email,
      'subscribers': subscribers,
      'subscriptions': subscriptions,
    };
  }
} 