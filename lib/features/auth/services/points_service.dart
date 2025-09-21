import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/auth/models/challenge_model.dart';
import 'package:rxdart/rxdart.dart';

class PointsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _currentUser => _auth.currentUser;

  // Stream for the user's total points
  Stream<int> get userPointsStream {
    if (_currentUser == null) return Stream.value(0);
    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['points'] ?? 0);
  }

  // Stream for all available challenges
  Stream<List<Challenge>> get challengesStream {
    return _firestore.collection('challenges').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Challenge.fromMap(doc.id, doc.data())).toList());
  }

  // Stream for the user's completed challenges
  Stream<List<UserChallenge>> get userChallengesStream {
     if (_currentUser == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('userChallenges')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserChallenge.fromMap(doc.data())).toList());
  }

  // Combine challenges with user's completion status
  Stream<List<Map<String, dynamic>>> get combinedChallengesStream {
    return Rx.combineLatest2(
      challengesStream,
      userChallengesStream,
      (List<Challenge> challenges, List<UserChallenge> userChallenges) {
        return challenges.map((challenge) {
          final userChallenge = userChallenges.firstWhere(
            (uc) => uc.challengeId == challenge.id,
            orElse: () => UserChallenge(challengeId: challenge.id, isCompleted: false),
          );
          return {
            'challenge': challenge,
            'isCompleted': userChallenge.isCompleted,
          };
        }).toList();
      },
    );
  }

  // Method to complete a challenge and award points
  Future<void> completeChallenge(Challenge challenge) async {
    if (_currentUser == null) return;

    final batch = _firestore.batch();
    
    // Mark challenge as completed
    final userChallengeRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('userChallenges')
        .doc(challenge.id);
    
    batch.set(userChallengeRef, {
      'challengeId': challenge.id,
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Add points to user's total
    final userRef = _firestore.collection('users').doc(_currentUser!.uid);
    batch.update(userRef, {
      'points': FieldValue.increment(challenge.reward),
    });

    // Create a points transaction record
    final transactionRef = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('pointsTransactions')
        .doc();
    
    batch.set(transactionRef, {
      'points': challenge.reward,
      'description': 'Challenge completed: ${challenge.title}',
      'type': 'challenge',
      'challengeId': challenge.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Method to create sample challenges (for testing)
  Future<void> createSampleChallenges() async {
    final challengesRef = _firestore.collection('challenges');
    
    final sampleChallenges = [
      {
        'title': 'تنفيذ اول طلب شراء من متاجر سومي المميزة',
        'description': 'قم بشراء أول منتج من المتجر لتحصل على النقاط',
        'reward': 500,
        'imagePath': 'assets/images/challenges/challenge_1.png',
      },
      {
        'title': 'أكمل بيانات ملفك الشخصي',
        'description': 'أضف صورة شخصية واملأ جميع البيانات المطلوبة',
        'reward': 300,
        'imagePath': 'assets/images/challenges/challenge_2.png',
      },
      {
        'title': 'شارك التطبيق مع 3 أصدقاء',
        'description': 'ادع أصدقاءك لاستخدام تطبيق سومي',
        'reward': 750,
        'imagePath': 'assets/images/challenges/challenge_1.png',
      },
      {
        'title': 'اكتب تقييم للتطبيق',
        'description': 'قيم تجربتك مع التطبيق في متجر التطبيقات',
        'reward': 200,
        'imagePath': 'assets/images/challenges/challenge_2.png',
      },
    ];

    for (int i = 0; i < sampleChallenges.length; i++) {
      await challengesRef.doc('challenge_${i + 1}').set(sampleChallenges[i]);
    }
  }

  // Method to initialize user points (for testing)
  Future<void> initializeUserPoints({int points = 2160}) async {
    if (_currentUser == null) return;
    
    await _firestore.collection('users').doc(_currentUser!.uid).set({
      'points': points,
      'email': _currentUser!.email,
      'displayName': _currentUser!.displayName,
    }, SetOptions(merge: true));
  }

  // Method to mark a challenge as completed (for testing)
  Future<void> markChallengeCompleted(String challengeId) async {
    if (_currentUser == null) return;

    await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('userChallenges')
        .doc(challengeId)
        .set({
      'challengeId': challengeId,
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
} 