import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/auth/models/support_ticket_model.dart';
import 'package:sumi/features/auth/models/ticket_message_model.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createSupportTicket(String subject, String message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ticketRef = _firestore.collection('supportTickets').doc();
    final messageRef = ticketRef.collection('messages').doc();

    final newTicket = SupportTicket(
      id: ticketRef.id,
      userId: user.uid,
      subject: subject,
      status: 'open',
      createdAt: DateTime.now(),
    );

    final newMessage = TicketMessage(
      id: messageRef.id,
      senderId: user.uid,
      message: message,
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(ticketRef, {
        'userId': newTicket.userId,
        'subject': newTicket.subject,
        'status': newTicket.status,
        'createdAt': newTicket.createdAt,
      });
      transaction.set(messageRef, {
        'senderId': newMessage.senderId,
        'message': newMessage.message,
        'createdAt': newMessage.createdAt,
      });
    });
  }

  Stream<List<SupportTicket>> getSupportTickets() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('supportTickets')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SupportTicket(
          id: doc.id,
          userId: data['userId'],
          subject: data['subject'],
          status: data['status'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          lastUpdatedAt: data['lastUpdatedAt'] != null
              ? (data['lastUpdatedAt'] as Timestamp).toDate()
              : null,
          adminTyping: data['adminTyping'] ?? false,
        );
      }).toList();
    });
  }

  Stream<List<TicketMessage>> getTicketMessages(String ticketId) {
    return _firestore
        .collection('supportTickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TicketMessage(
          id: doc.id,
          senderId: data['senderId'],
          message: data['message'],
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
    });
  }

  Stream<SupportTicket> getTicketStream(String ticketId) {
    return _firestore
        .collection('supportTickets')
        .doc(ticketId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data()!;
      return SupportTicket(
        id: snapshot.id,
        userId: data['userId'],
        subject: data['subject'],
        status: data['status'],
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        lastUpdatedAt: data['lastUpdatedAt'] != null
            ? (data['lastUpdatedAt'] as Timestamp).toDate()
            : null,
        adminTyping: data['adminTyping'] ?? false,
      );
    });
  }

  Future<void> sendMessage(String ticketId, String message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final messageRef = _firestore
        .collection('supportTickets')
        .doc(ticketId)
        .collection('messages')
        .doc();

    final newMessage = TicketMessage(
      id: messageRef.id,
      senderId: user.uid,
      message: message,
      createdAt: DateTime.now(),
    );

    await messageRef.set({
      'senderId': newMessage.senderId,
      'message': newMessage.message,
      'createdAt': newMessage.createdAt,
      'isRead': newMessage.isRead,
    });

    await _firestore
        .collection('supportTickets')
        .doc(ticketId)
        .update({'lastUpdatedAt': DateTime.now()});
  }

  Future<void> markMessageAsRead(String ticketId, String messageId) async {
    await _firestore
        .collection('supportTickets')
        .doc(ticketId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  Future<void> closeTicket(String ticketId) async {
    await _firestore
        .collection('supportTickets')
        .doc(ticketId)
        .update({'status': 'closed'});
  }
} 