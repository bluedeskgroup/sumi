import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/store/models/card_model.dart';

class CardsService {
  static final CardsService _instance = CardsService._internal();
  CardsService._internal();
  factory CardsService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  // استرجاع جميع البطاقات المتاحة
  Stream<List<CardModel>> getAvailableCardsStream() {
    return _firestore
        .collection('cards')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CardModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // استرجاع بطاقة واحدة
  Future<CardModel?> getCard(String cardId) async {
    try {
      final doc = await _firestore.collection('cards').doc(cardId).get();
      if (doc.exists) {
        return CardModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting card: $e');
      return null;
    }
  }

  // استرجاع بطاقات المستخدم الحالي
  Stream<List<UserCard>> getUserCardsStream() {
    if (_currentUser == null) return Stream.value([]);

    return _firestore
        .collection('userCards')
        .where('userId', isEqualTo: _currentUser!.uid)
        .where('isActive', isEqualTo: true)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserCard.fromMap(doc.id, doc.data()))
            .toList());
  }

  // استرجاع طلبات البطاقات للمستخدم الحالي
  Stream<List<UserCardRequest>> getUserCardRequestsStream() {
    if (_currentUser == null) return Stream.value([]);

    return _firestore
        .collection('cardRequests')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserCardRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  // طلب بطاقة جديدة
  Future<bool> requestCard(String cardId) async {
    if (_currentUser == null) {
      print('No current user');
      return false;
    }

    try {
      // التحقق من وجود طلب مسبق لنفس البطاقة
      final existingRequest = await _firestore
          .collection('cardRequests')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('cardId', isEqualTo: cardId)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      if (existingRequest.docs.isNotEmpty) {
        print('Card already requested or approved');
        return false;
      }

      // التحقق من وجود البطاقة للمستخدم بالفعل
      final existingCard = await _firestore
          .collection('userCards')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('cardId', isEqualTo: cardId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingCard.docs.isNotEmpty) {
        print('User already has this card');
        return false;
      }

      // إنشاء طلب البطاقة
      final request = UserCardRequest(
        id: '',
        userId: _currentUser!.uid,
        cardId: cardId,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      await _firestore.collection('cardRequests').add(request.toMap());
      print('Card request created successfully');
      return true;
    } catch (e) {
      print('Error requesting card: $e');
      return false;
    }
  }

  // التحقق من حالة طلب بطاقة معينة
  Future<String?> getCardRequestStatus(String cardId) async {
    if (_currentUser == null) return null;

    try {
      final query = await _firestore
          .collection('cardRequests')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('cardId', isEqualTo: cardId)
          .orderBy('requestedAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['status'];
      }
      return null;
    } catch (e) {
      print('Error getting card request status: $e');
      return null;
    }
  }

  // التحقق من امتلاك المستخدم لبطاقة معينة
  Future<bool> userHasCard(String cardId) async {
    if (_currentUser == null) return false;

    try {
      final query = await _firestore
          .collection('userCards')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('cardId', isEqualTo: cardId)
          .where('isActive', isEqualTo: true)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user card: $e');
      return false;
    }
  }

  // استرجاع تفاصيل البطاقة مع حالة المستخدم
  Future<Map<String, dynamic>> getCardWithUserStatus(String cardId) async {
    try {
      final card = await getCard(cardId);
      if (card == null) {
        return {'card': null, 'userHasCard': false, 'requestStatus': null};
      }

      final userHasCard = await this.userHasCard(cardId);
      final requestStatus = await getCardRequestStatus(cardId);

      return {
        'card': card,
        'userHasCard': userHasCard,
        'requestStatus': requestStatus,
      };
    } catch (e) {
      print('Error getting card with user status: $e');
      return {'card': null, 'userHasCard': false, 'requestStatus': null};
    }
  }

  // إلغاء طلب بطاقة (إذا كان معلق)
  Future<bool> cancelCardRequest(String requestId) async {
    if (_currentUser == null) return false;

    try {
      final requestDoc = await _firestore
          .collection('cardRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        print('Request not found');
        return false;
      }

      final requestData = requestDoc.data()!;
      
      // التحقق من أن الطلب خاص بالمستخدم الحالي وأنه معلق
      if (requestData['userId'] != _currentUser!.uid || 
          requestData['status'] != 'pending') {
        print('Cannot cancel this request');
        return false;
      }

      await _firestore
          .collection('cardRequests')
          .doc(requestId)
          .delete();

      print('Card request cancelled successfully');
      return true;
    } catch (e) {
      print('Error cancelling card request: $e');
      return false;
    }
  }

  // استرجاع إحصائيات البطاقات للمستخدم
  Future<Map<String, int>> getUserCardStats() async {
    if (_currentUser == null) {
      return {'totalCards': 0, 'activeCards': 0, 'pendingRequests': 0};
    }

    try {
      // البطاقات النشطة
      final activeCards = await _firestore
          .collection('userCards')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('isActive', isEqualTo: true)
          .get();

      // الطلبات المعلقة
      final pendingRequests = await _firestore
          .collection('cardRequests')
          .where('userId', isEqualTo: _currentUser!.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      return {
        'totalCards': activeCards.docs.length,
        'activeCards': activeCards.docs.where((doc) {
          final card = UserCard.fromMap(doc.id, doc.data());
          return card.isValid;
        }).length,
        'pendingRequests': pendingRequests.docs.length,
      };
    } catch (e) {
      print('Error getting user card stats: $e');
      return {'totalCards': 0, 'activeCards': 0, 'pendingRequests': 0};
    }
  }
}