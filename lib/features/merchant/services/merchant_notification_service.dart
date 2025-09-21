import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/merchant_model.dart';

class MerchantNotificationService {
  static final MerchantNotificationService _instance = MerchantNotificationService._internal();
  factory MerchantNotificationService() => _instance;
  MerchantNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<DocumentSnapshot>? _statusStream;

  /// مراقبة حالة التاجر في الوقت الفعلي
  Stream<MerchantStatusChange?> watchMerchantStatus() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    MerchantStatus? lastStatus;

    // مراقبة طلبات التجار
    await for (final snapshot in _firestore
        .collection('merchant_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()) {
      
      if (snapshot.docs.isEmpty) continue;

      final doc = snapshot.docs.first;
      final merchant = MerchantModel.fromJson({
        'id': doc.id,
        ...doc.data(),
      });

      // إذا تغيرت الحالة
      if (lastStatus != null && lastStatus != merchant.status) {
        yield MerchantStatusChange(
          previousStatus: lastStatus,
          currentStatus: merchant.status,
          merchant: merchant,
        );
      }

      lastStatus = merchant.status;

      // إذا تمت الموافقة، تحقق من approved_merchants أيضاً
      if (merchant.status == MerchantStatus.approved) {
        await for (final approvedSnapshot in _firestore
            .collection('approved_merchants')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .snapshots()) {
          
          if (approvedSnapshot.docs.isNotEmpty) {
            final approvedDoc = approvedSnapshot.docs.first;
            final approvedMerchant = MerchantModel.fromJson({
              'id': approvedDoc.id,
              ...approvedDoc.data(),
            });

            if (lastStatus != approvedMerchant.status) {
              yield MerchantStatusChange(
                previousStatus: lastStatus ?? MerchantStatus.pending,
                currentStatus: approvedMerchant.status,
                merchant: approvedMerchant,
              );
            }

            lastStatus = approvedMerchant.status;
          }
          break; // خروج من الـ loop الداخلي
        }
      }
    }
  }

  /// عرض إشعار فوري للمستخدم
  void showStatusChangeNotification(
    BuildContext context,
    MerchantStatusChange change,
  ) {
    switch (change.currentStatus) {
      case MerchantStatus.approved:
        _showApprovedNotification(context, change.merchant);
        break;
      case MerchantStatus.rejected:
        _showRejectedNotification(context, change.merchant);
        break;
      case MerchantStatus.suspended:
        _showSuspendedNotification(context, change.merchant);
        break;
      default:
        break;
    }
  }

  void _showApprovedNotification(BuildContext context, MerchantModel merchant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1AB385),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎉 مبروك!',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF1D2035),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'تم قبول حسابك في سومي',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D2035),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'مرحباً بك ${merchant.businessName}\nيمكنك الآن إدارة متجرك والبدء في البيع',
              style: const TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14,
                color: Color(0xFF7991A4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF9A46D7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // إغلاق الـ dialog
                // التوجيه سيتم تلقائياً عبر MerchantAuthWrapper
              },
              child: const Text(
                'ابدأ إدارة متجرك',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectedNotification(BuildContext context, MerchantModel merchant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEB5757),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.cancel,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'طلب مرفوض',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF1D2035),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'عذراً، تم رفض طلب التاجر',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 16,
                color: Color(0xFF7991A4),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (merchant.statusReason?.isNotEmpty ?? false)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سبب الرفض:',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1D2035),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      merchant.statusReason!,
                      style: const TextStyle(
                        fontFamily: 'Almarai',
                        fontSize: 14,
                        color: Color(0xFF7991A4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF9A46D7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuspendedNotification(BuildContext context, MerchantModel merchant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF2994A),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.pause_circle,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'حساب معلق',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF1D2035),
              ),
            ),
          ],
        ),
        content: const Text(
          'تم تعليق حسابك التجاري مؤقتاً. يرجى التواصل مع الدعم الفني لمزيد من المعلومات.',
          style: TextStyle(
            fontFamily: 'Almarai',
            fontSize: 14,
            color: Color(0xFF7991A4),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF9A46D7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'تواصل مع الدعم',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// تسجيل الإشعار في قاعدة البيانات
  Future<void> logNotification(String userId, MerchantStatusChange change) async {
    try {
      await _firestore.collection('merchant_notifications').add({
        'userId': userId,
        'previousStatus': change.previousStatus.toString().split('.').last,
        'currentStatus': change.currentStatus.toString().split('.').last,
        'merchantId': change.merchant.id,
        'businessName': change.merchant.businessName,
        'timestamp': Timestamp.now(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error logging notification: $e');
    }
  }
}

class MerchantStatusChange {
  final MerchantStatus previousStatus;
  final MerchantStatus currentStatus;
  final MerchantModel merchant;

  MerchantStatusChange({
    required this.previousStatus,
    required this.currentStatus,
    required this.merchant,
  });
}
