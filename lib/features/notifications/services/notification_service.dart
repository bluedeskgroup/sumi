import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/notifications/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Stream to get real-time notifications for the logged-in user
  Stream<List<AppNotification>> getNotifications() {
    if (_currentUserId == null) {
      return Stream.value([]); // Return an empty stream if user is not logged in
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50) // To avoid loading too many notifications at once
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  // Stream to get the count of unread notifications
  Stream<int> getUnreadNotificationCount() {
    if (_currentUserId == null) {
      return Stream.value(0);
    }
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark a specific notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    final querySnapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
} 