import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/auth/models/referral_model.dart';
import 'package:flutter/services.dart';
import 'package:sumi/core/services/dynamic_levels_service.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DynamicLevelsService _levelsService = DynamicLevelsService();

  User? get _currentUser => _auth.currentUser;

  // Generate unique referral code
  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Initialize user referral data
  Future<void> initializeUserReferral() async {
    if (_currentUser == null) return;

    final userDoc = await _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .get();

    if (!userDoc.exists || userDoc.data()?['referralCode'] == null) {
      String referralCode;
      bool isUnique = false;

      // Generate unique referral code
      do {
        referralCode = _generateReferralCode();
        final existingCode = await _firestore
            .collection('users')
            .where('referralCode', isEqualTo: referralCode)
            .get();
        isUnique = existingCode.docs.isEmpty;
      } while (!isUnique);

      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'referralCode': referralCode,
        'currentBalance': 0.0,
        'totalEarnings': 0.0,
        'referralsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Initialize referral stats collection
      await _firestore
          .collection('referralStats')
          .doc(_currentUser!.uid)
          .set({
        'currentBalance': 0.0,
        'totalEarnings': 0.0,
        'referralsCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get user referral stats
  Stream<ReferralStats> getReferralStatsStream() {
    if (_currentUser == null) {
      return Stream.value(ReferralStats.initial(''));
    }

    return _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return ReferralStats.initial('');
      }

      final data = snapshot.data()!;
      final referralCode = data['referralCode'] ?? '';
      
      return ReferralStats.fromMap(data, referralCode);
    });
  }

  // Get referral transactions
  Stream<List<ReferralTransaction>> getReferralTransactionsStream() {
    if (_currentUser == null) return Stream.value([]);

    return _firestore
        .collection('referralTransactions')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReferralTransaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get withdrawal records
  Stream<List<WithdrawalRecord>> getWithdrawalRecordsStream() {
    if (_currentUser == null) {
      print('getWithdrawalRecordsStream: No current user');
      return Stream.value([]);
    }

    print('getWithdrawalRecordsStream: Current user ID: ${_currentUser!.uid}');
    
    return _firestore
        .collection('withdrawalRecords')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print('getWithdrawalRecordsStream: Got ${snapshot.docs.length} withdrawal records');
          
          return snapshot.docs.map((doc) {
            try {
              print('Processing withdrawal doc ${doc.id}: ${doc.data()}');
              return WithdrawalRecord.fromMap(doc.id, doc.data());
            } catch (e) {
              print('Error processing withdrawal record ${doc.id}: $e');
              rethrow;
            }
          }).toList();
        });
  }

  // Process referral signup (called when someone signs up with a referral code)
  Future<void> processReferralSignup(String referralCode, String newUserName, {String? newUserId}) async {
    try {
      // Find the referrer
      final referrerQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (referrerQuery.docs.isEmpty) return;

      final referrerDoc = referrerQuery.docs.first;
      final referrerId = referrerDoc.id;
      final referrerData = referrerDoc.data();

      // Calculate current level and commission using dynamic levels
      final currentReferrals = referrerData['referralsCount'] ?? 0;
      await _levelsService.initializeLevels(); // Ensure levels are loaded
      
      final currentLevel = _levelsService.getUserLevel(currentReferrals);
      if (currentLevel == null) {
        print('No level found for user with $currentReferrals referrals');
        return;
      }

      // Commission amount based on level percentage
      final baseAmount = 50.0; // Base commission amount
      final commissionAmount = baseAmount * (currentLevel.percentage / 100);

      // Use batch to ensure atomicity
      final batch = _firestore.batch();

      // Update referrer stats
      batch.update(_firestore.collection('users').doc(referrerId), {
        'currentBalance': FieldValue.increment(commissionAmount),
        'totalEarnings': FieldValue.increment(commissionAmount),
        'referralsCount': FieldValue.increment(1),
      });

      // Add transaction record
      final transactionRef = _firestore.collection('referralTransactions').doc();
      batch.set(transactionRef, ReferralTransaction(
        id: transactionRef.id,
        type: 'referral_signup',
        description: 'سجل صديقك $newUserName من خلال الكود',
        amount: commissionAmount,
        timestamp: DateTime.now(),
        relatedUserName: newUserName,
      ).toMap()..['userId'] = referrerId);

      await batch.commit();

      // Track successful referral for analytics
      await _trackSuccessfulReferral(referrerId, newUserId ?? '', referralCode, commissionAmount);

      // Show gift notification if it's a significant amount
      if (commissionAmount >= 50) {
        _scheduleGiftNotification(referrerId, commissionAmount);
      }
    } catch (e) {
      print('Error processing referral signup: $e');
    }
  }

  // Schedule gift notification (can be expanded to use push notifications)
  Future<void> _scheduleGiftNotification(String userId, double amount) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'gift_received',
        'title': 'كسبت ${amount.toInt()} نقطة هدية!',
        'message': 'حصلت على ${amount.toInt()} نقطة في نقاط المكافآت لديك مقابل تسجيل صديقك من خلال رمز الدعوه الخاص بيك',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error scheduling gift notification: $e');
    }
  }



  // Copy referral code to clipboard
  Future<void> copyReferralCode(String referralCode) async {
    await Clipboard.setData(ClipboardData(text: referralCode));
  }

  // Get gift notifications stream (includes admin bonuses and promotional gifts)
  Stream<List<Map<String, dynamic>>> getGiftNotificationsStream() {
    if (_currentUser == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: _currentUser!.uid)
        .where('type', whereIn: ['gift_received', 'admin_bonus', 'promotional_gift'])
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'type': data['type'] ?? '',
                'title': data['title'] ?? '',
                'message': data['message'] ?? '',
                'amount': data['amount'] ?? 0,
                'isRead': data['isRead'] ?? false,
                'createdAt': data['createdAt'],
              };
            }).toList());
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Create sample data for testing
  Future<void> createSampleReferralData() async {
    if (_currentUser == null) return;

    try {
      // Create sample stats
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'referralCode': 'F5C993',
        'currentBalance': 590.0,
        'totalEarnings': 450.0,
        'referralsCount': 7,
      }, SetOptions(merge: true));

      // Create sample transactions matching Figma design
      final baseDate = DateTime(2024, 3, 15, 2, 24); // March 15, 2024 at 02:24
      final transactions = [
        {
          'type': 'points_used',
          'description': 'استخدام فى حجز موعد مع خبير',
          'amount': -466.0,
          'timestamp': Timestamp.fromDate(baseDate),
          'userId': _currentUser!.uid,
        },
        {
          'type': 'referral_signup',
          'description': 'سجل صديقك محمود رمضان من خلال الكود',
          'amount': 466.0,
          'timestamp': Timestamp.fromDate(baseDate.subtract(Duration(hours: 3))),
          'userId': _currentUser!.uid,
          'relatedUserName': 'محمود رمضان',
        },
        {
          'type': 'points_used',
          'description': 'استخدام فى حجز موعد مع خبير',
          'amount': -466.0,
          'timestamp': Timestamp.fromDate(baseDate.subtract(Duration(days: 1))),
          'userId': _currentUser!.uid,
        },
        {
          'type': 'points_used',
          'description': 'استخدام فى حجز موعد مع خبير',
          'amount': -466.0,
          'timestamp': Timestamp.fromDate(baseDate.subtract(Duration(days: 2))),
          'userId': _currentUser!.uid,
        },
        {
          'type': 'referral_signup',
          'description': 'سجل صديقك فاطمة علي من خلال الكود',
          'amount': 466.0,
          'timestamp': Timestamp.fromDate(baseDate.subtract(Duration(days: 5))),
          'userId': _currentUser!.uid,
          'relatedUserName': 'فاطمة علي',
        },
        {
          'type': 'referral_signup',
          'description': 'سجل صديقك أحمد محمد من خلال الكود',
          'amount': 466.0,
          'timestamp': Timestamp.fromDate(baseDate.subtract(Duration(days: 8))),
          'userId': _currentUser!.uid,
          'relatedUserName': 'أحمد محمد',
        },
      ];

      for (final transaction in transactions) {
        await _firestore.collection('referralTransactions').add(transaction);
      }

    } catch (e) {
      print('Error creating sample referral data: $e');
    }
  }

  // Get sharing analytics for a user
  Stream<List<Map<String, dynamic>>> getSharingEventsStream() {
    if (_currentUser == null) return Stream.value([]);

    return _firestore
        .collection('sharingEvents')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'platform': doc.data()['platform'] ?? '',
                  'referralCode': doc.data()['referralCode'] ?? '',
                  'timestamp': doc.data()['timestamp'],
                })
            .toList());
  }

  // Track successful referral for detailed analytics
  Future<void> _trackSuccessfulReferral(String referrerId, String newUserId, String referralCode, double commissionAmount) async {
    try {
      await _firestore.collection('referralTracking').add({
        'referrerId': referrerId,
        'newUserId': newUserId,
        'referralCode': referralCode,
        'commissionAmount': commissionAmount,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'completed',
        'type': 'signup_referral'
      });

      // Update referral success rate statistics
      await _updateReferralStats(referrerId);
    } catch (e) {
      print('Error tracking successful referral: $e');
    }
  }

  // Update referral statistics for better tracking
  Future<void> _updateReferralStats(String userId) async {
    try {
      final userStatsRef = _firestore.collection('userReferralStats').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final userStatsSnapshot = await transaction.get(userStatsRef);
        
        if (userStatsSnapshot.exists) {
          final data = userStatsSnapshot.data()!;
          transaction.update(userStatsRef, {
            'totalSuccessfulReferrals': FieldValue.increment(1),
            'lastReferralDate': FieldValue.serverTimestamp(),
            'totalShares': data['totalShares'] ?? 0,
            'conversionRate': _calculateConversionRate(
              (data['totalShares'] ?? 0).toInt(), 
              ((data['totalSuccessfulReferrals'] ?? 0) + 1).toInt()
            ),
          });
        } else {
          transaction.set(userStatsRef, {
            'userId': userId,
            'totalSuccessfulReferrals': 1,
            'totalShares': 0,
            'conversionRate': 0.0,
            'firstReferralDate': FieldValue.serverTimestamp(),
            'lastReferralDate': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Error updating referral stats: $e');
    }
  }

  // Calculate conversion rate (successful referrals / total shares)
  double _calculateConversionRate(int totalShares, int successfulReferrals) {
    if (totalShares == 0) return 0.0;
    return (successfulReferrals / totalShares * 100);
  }

  // Enhanced tracking for sharing events
  Future<void> trackSharingEvent(String platform, String referralCode) async {
    try {
      if (_currentUser == null) return;

      // Track sharing event
      await _firestore.collection('sharingEvents').add({
        'userId': _currentUser!.uid,
        'platform': platform,
        'referralCode': referralCode,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user sharing stats
      await _updateSharingStats(_currentUser!.uid, platform);

      print('Sharing event tracked: $platform');
    } catch (e) {
      print('Error tracking sharing event: $e');
    }
  }

  // Update sharing statistics
  Future<void> _updateSharingStats(String userId, String platform) async {
    try {
      final userStatsRef = _firestore.collection('userReferralStats').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final userStatsSnapshot = await transaction.get(userStatsRef);
        
        if (userStatsSnapshot.exists) {
          final data = userStatsSnapshot.data()!;
          final totalShares = ((data['totalShares'] ?? 0) + 1).toInt();
          final successfulReferrals = (data['totalSuccessfulReferrals'] ?? 0).toInt();
          
          transaction.update(userStatsRef, {
            'totalShares': FieldValue.increment(1),
            'lastShareDate': FieldValue.serverTimestamp(),
            'conversionRate': _calculateConversionRate(totalShares, successfulReferrals),
            'platforms': FieldValue.arrayUnion([platform]),
          });
        } else {
          transaction.set(userStatsRef, {
            'userId': userId,
            'totalShares': 1,
            'totalSuccessfulReferrals': 0,
            'conversionRate': 0.0,
            'lastShareDate': FieldValue.serverTimestamp(),
            'platforms': [platform],
          });
        }
      });
    } catch (e) {
      print('Error updating sharing stats: $e');
    }
  }

  // Get detailed referral analytics for admin
  Stream<Map<String, dynamic>> getReferralAnalyticsStream() {
    if (_currentUser == null) return Stream.value({});

    return _firestore
        .collection('userReferralStats')
        .doc(_currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return {
          'totalShares': 0,
          'totalSuccessfulReferrals': 0,
          'conversionRate': 0.0,
          'platforms': <String>[],
        };
      }
      return snapshot.data()!;
    });
  }

  // Initialize referral with tracking system
  Future<void> initializeUserReferralWithTracking() async {
    await initializeUserReferral();
    
    if (_currentUser != null) {
      // Initialize tracking stats if they don't exist
      final statsDoc = await _firestore
          .collection('userReferralStats')
          .doc(_currentUser!.uid)
          .get();
      
      if (!statsDoc.exists) {
        await _firestore.collection('userReferralStats').doc(_currentUser!.uid).set({
          'userId': _currentUser!.uid,
          'totalShares': 0,
          'totalSuccessfulReferrals': 0,
          'conversionRate': 0.0,
          'platforms': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Get user's saved account numbers
  Future<List<String>> getSavedAccountNumbers() async {
    if (_currentUser == null) return [];
    
    try {
      final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final savedAccounts = List<String>.from(data['savedAccountNumbers'] ?? []);
        return savedAccounts;
      }
      return [];
    } catch (e) {
      print('Error getting saved account numbers: $e');
      return [];
    }
  }

  // Save account number to user's saved list
  Future<void> saveAccountNumber(String accountNumber) async {
    if (_currentUser == null || accountNumber.trim().isEmpty) return;
    
    try {
      final savedAccounts = await getSavedAccountNumbers();
      if (!savedAccounts.contains(accountNumber.trim())) {
        savedAccounts.add(accountNumber.trim());
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'savedAccountNumbers': savedAccounts,
        });
      }
    } catch (e) {
      print('Error saving account number: $e');
    }
  }

  // Get referral system settings from admin
  Future<Map<String, dynamic>> getReferralSettings() async {
    try {
      print('Fetching referral settings from Firestore...');
      final doc = await _firestore.collection('settings').doc('referralSystem').get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        print('Settings found: $data');
        return data;
      } else {
        print('No settings document found, creating default settings...');
        // Create default settings in Firestore
        final defaultSettings = {
          'minimumWithdrawal': 100.0,
          'bronzePercentage': 3,
          'silverPercentage': 4,
          'goldPercentage': 7,
          'silverThreshold': 20,
          'goldThreshold': 50,
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('settings').doc('referralSystem').set(defaultSettings);
        print('Default settings created: $defaultSettings');
        return defaultSettings;
      }
    } catch (e) {
      print('Error getting referral settings: $e');
      return {
        'minimumWithdrawal': 100.0,
        'bronzePercentage': 3,
        'silverPercentage': 4,
        'goldPercentage': 7,
        'silverThreshold': 20,
        'goldThreshold': 50,
      };
    }
  }

  // Get real-time stream of referral settings
  Stream<Map<String, dynamic>> getReferralSettingsStream() {
    return _firestore.collection('settings').doc('referralSystem').snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() ?? {};
        print('Settings stream update: $data');
        return data;
      } else {
        print('Settings stream: No document found, returning defaults');
        return {
          'minimumWithdrawal': 100.0,
          'bronzePercentage': 3,
          'silverPercentage': 4,
          'goldPercentage': 7,
          'silverThreshold': 20,
          'goldThreshold': 50,
        };
      }
    });
  }

  // Request withdrawal with account number saving
  Future<bool> requestWithdrawal(double amount, String accountNumber) async {
    if (_currentUser == null) {
      print('requestWithdrawal: No current user');
      return false;
    }

    print('requestWithdrawal: Requesting withdrawal for ${_currentUser!.uid}, amount: $amount, account: $accountNumber');

    try {
      final batch = _firestore.batch();

      // Deduct amount from user balance
      batch.update(_firestore.collection('users').doc(_currentUser!.uid), {
        'currentBalance': FieldValue.increment(-amount),
      });

      // Create withdrawal record
      final withdrawalRef = _firestore.collection('withdrawalRecords').doc();
      print('requestWithdrawal: Creating withdrawal record with ID: ${withdrawalRef.id}');
      
      batch.set(withdrawalRef, {
        'userId': _currentUser!.uid,
        'amount': amount,
        'accountNumber': accountNumber,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Add transaction record
      final transactionRef = _firestore.collection('referralTransactions').doc();
      batch.set(transactionRef, {
        'userId': _currentUser!.uid,
        'type': 'withdrawal_request',
        'description': 'طلب سحب رصيد - $accountNumber',
        'amount': -amount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print('requestWithdrawal: Batch committed successfully');
      
      // Save account number for future use
      await saveAccountNumber(accountNumber);
      
      return true;
    } catch (e) {
      print('Error requesting withdrawal: $e');
      return false;
    }
  }
}