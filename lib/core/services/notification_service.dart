import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // إرسال إشعار للمتابعين عند نشر قصة جديدة
  Future<void> notifyFollowersOfNewStory({
    required String storyId,
    required String authorId,
    required String authorName,
    required String storyPreview,
  }) async {
    try {
      // الحصول على قائمة المتابعين
      final followersSnapshot = await _firestore
          .collection('followers')
          .doc(authorId)
          .get();

      if (!followersSnapshot.exists) return;

      final followers = List<String>.from(
        followersSnapshot.data()?['followers'] ?? [],
      );

      // إنشاء إشعارات للمتابعين
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (final followerId in followers) {
        final notificationRef = _firestore
            .collection('notifications')
            .doc(followerId)
            .collection('user_notifications')
            .doc();

        batch.set(notificationRef, {
          'id': notificationRef.id,
          'type': 'new_story',
          'title': 'قصة جديدة',
          'body': '$authorName نشر قصة جديدة: $storyPreview',
          'authorId': authorId,
          'authorName': authorName,
          'storyId': storyId,
          'isRead': false,
          'createdAt': timestamp,
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error sending story notifications: $e');
    }
  }

  // إرسال إشعار عند التفاعل مع القصة
  Future<void> notifyStoryInteraction({
    required String storyId,
    required String storyAuthorId,
    required String interactionType, // 'like', 'comment', 'share'
    required String interactorId,
    required String interactorName,
  }) async {
    try {
      // لا نرسل إشعار للمؤلف نفسه
      if (storyAuthorId == interactorId) return;

      final notificationRef = _firestore
          .collection('notifications')
          .doc(storyAuthorId)
          .collection('user_notifications')
          .doc();

      String title;
      String body;

      switch (interactionType) {
        case 'like':
          title = 'تفاعل جديد';
          body = '$interactorName أعجب بقصتك';
          break;
        case 'comment':
          title = 'تعليق جديد';
          body = '$interactorName علق على قصتك';
          break;
        case 'share':
          title = 'مشاركة جديدة';
          body = '$interactorName شارك قصتك';
          break;
        default:
          title = 'تفاعل جديد';
          body = '$interactorName تفاعل مع قصتك';
      }

      await notificationRef.set({
        'id': notificationRef.id,
        'type': 'story_interaction',
        'subType': interactionType,
        'title': title,
        'body': body,
        'storyId': storyId,
        'interactorId': interactorId,
        'interactorName': interactorName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending interaction notification: $e');
    }
  }

  // إرسال إشعار عند الرد على القصة
  Future<void> notifyStoryReply({
    required String storyId,
    required String storyAuthorId,
    required String replyText,
    required String senderId,
    required String senderName,
  }) async {
    try {
      if (storyAuthorId == senderId) return;

      final notificationRef = _firestore
          .collection('notifications')
          .doc(storyAuthorId)
          .collection('user_notifications')
          .doc();

      await notificationRef.set({
        'id': notificationRef.id,
        'type': 'story_reply',
        'title': 'رد جديد',
        'body': '$senderName رد على قصتك: ${_truncateText(replyText, 50)}',
        'storyId': storyId,
        'senderId': senderId,
        'senderName': senderName,
        'replyText': replyText,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending reply notification: $e');
    }
  }

  // الحصول على إشعارات المستخدم
  Stream<List<AppNotification>> getUserNotifications() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .doc(currentUserId)
        .collection('user_notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  // تحديد إشعار كمقروء
  Future<void> markAsRead(String notificationId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('user_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // تحديد جميع الإشعارات كمقروءة
  Future<void> markAllAsRead() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('user_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('user_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // حذف جميع الإشعارات
  Future<void> deleteAllNotifications() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .doc(currentUserId)
          .collection('user_notifications')
          .get();

      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // عدد الإشعارات غير المقروءة
  Stream<int> getUnreadCount() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .doc(currentUserId)
        .collection('user_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

// نموذج الإشعار
class AppNotification {
  final String id;
  final String type;
  final String? subType;
  final String title;
  final String body;
  final String? storyId;
  final String? authorId;
  final String? authorName;
  final String? interactorId;
  final String? interactorName;
  final String? senderId;
  final String? senderName;
  final String? replyText;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    this.subType,
    required this.title,
    required this.body,
    this.storyId,
    this.authorId,
    this.authorName,
    this.interactorId,
    this.interactorName,
    this.senderId,
    this.senderName,
    this.replyText,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: data['type'] ?? '',
      subType: data['subType'],
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      storyId: data['storyId'],
      authorId: data['authorId'],
      authorName: data['authorName'],
      interactorId: data['interactorId'],
      interactorName: data['interactorName'],
      senderId: data['senderId'],
      senderName: data['senderName'],
      replyText: data['replyText'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  IconData get icon {
    switch (type) {
      case 'new_story':
        return Icons.auto_stories;
      case 'story_interaction':
        switch (subType) {
          case 'like':
            return Icons.favorite;
          case 'comment':
            return Icons.comment;
          case 'share':
            return Icons.share;
          default:
            return Icons.notifications;
        }
      case 'story_reply':
        return Icons.reply;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'new_story':
        return const Color(0xFF9A46D7);
      case 'story_interaction':
        switch (subType) {
          case 'like':
            return Colors.red;
          case 'comment':
            return Colors.blue;
          case 'share':
            return Colors.green;
          default:
            return const Color(0xFF9A46D7);
        }
      case 'story_reply':
        return Colors.orange;
      default:
        return const Color(0xFF9A46D7);
    }
  }
}
