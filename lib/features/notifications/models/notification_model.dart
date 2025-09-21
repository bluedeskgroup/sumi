import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newFollower,
  newLike,
  newComment,
  // Future types can be added here, e.g., newReview, orderUpdate
}

class AppNotification {
  final String id;
  final String recipientId; // The user who receives the notification
  final String senderId;    // The user who triggered the notification
  final String senderName;
  final String? senderImageUrl;
  final NotificationType type;
  final String referenceId;   // ID of the relevant object (post, user, etc.)
  final String? contentSnippet; // A small piece of content, like the comment text
  final bool isRead;
  final Timestamp createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    this.senderImageUrl,
    required this.type,
    required this.referenceId,
    this.contentSnippet,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderImageUrl: data['senderImageUrl'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.newComment, // Default fallback
      ),
      referenceId: data['referenceId'] ?? '',
      contentSnippet: data['contentSnippet'],
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'senderImageUrl': senderImageUrl,
      'type': type.name,
      'referenceId': referenceId,
      'contentSnippet': contentSnippet,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
} 