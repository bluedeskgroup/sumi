import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/merchant_model.dart';

enum MerchantAuthStatus {
  notMerchant,           // ليس تاجر
  merchantPending,       // تاجر قيد المراجعة
  merchantApproved,      // تاجر مقبول
  merchantRejected,      // تاجر مرفوض
  merchantSuspended,     // تاجر معلق
  error,                 // خطأ في التحقق
}

class MerchantAuthResult {
  final MerchantAuthStatus status;
  final MerchantModel? merchant;
  final String? errorMessage;

  MerchantAuthResult({
    required this.status,
    this.merchant,
    this.errorMessage,
  });
}

class MerchantAuthService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static MerchantAuthService? _instance;
  
  static MerchantAuthService get instance {
    _instance ??= MerchantAuthService._internal();
    return _instance!;
  }

  MerchantAuthService._internal();

  /// التحقق من حالة المستخدم كتاجر
  Future<MerchantAuthResult> checkMerchantStatus([User? user]) async {
    try {
      user ??= _auth.currentUser;
      if (user == null) {
        return MerchantAuthResult(
          status: MerchantAuthStatus.error,
          errorMessage: 'المستخدم غير مسجل الدخول',
        );
      }

      // البحث في طلبات التجار
      final merchantRequestQuery = await _firestore
          .collection('merchant_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (merchantRequestQuery.docs.isNotEmpty) {
        final merchantData = merchantRequestQuery.docs.first.data();
        final merchant = MerchantModel.fromJson({
          'id': merchantRequestQuery.docs.first.id,
          ...merchantData,
        });

        switch (merchant.status) {
          case MerchantStatus.pending:
            return MerchantAuthResult(
              status: MerchantAuthStatus.merchantPending,
              merchant: merchant,
            );
          case MerchantStatus.approved:
            return MerchantAuthResult(
              status: MerchantAuthStatus.merchantApproved,
              merchant: merchant,
            );
          case MerchantStatus.rejected:
            return MerchantAuthResult(
              status: MerchantAuthStatus.merchantRejected,
              merchant: merchant,
            );
          case MerchantStatus.suspended:
            return MerchantAuthResult(
              status: MerchantAuthStatus.merchantSuspended,
              merchant: merchant,
            );
        }
      }

      // إذا لم يوجد طلب تاجر، فهو مستخدم عادي
      return MerchantAuthResult(status: MerchantAuthStatus.notMerchant);

    } catch (e) {
      debugPrint('Error checking merchant status: $e');
      return MerchantAuthResult(
        status: MerchantAuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// التحقق من إمكانية الوصول للحساب
  Future<bool> canAccessAccount([User? user]) async {
    final result = await checkMerchantStatus(user);
    return result.status == MerchantAuthStatus.notMerchant ||
           result.status == MerchantAuthStatus.merchantApproved;
  }

  /// الحصول على الصفحة المناسبة بناءً على حالة التاجر
  Future<Widget> getAppropriateHomeWidget([User? user]) async {
    final result = await checkMerchantStatus(user);
    
    switch (result.status) {
      case MerchantAuthStatus.merchantPending:
        // إرجاع صفحة انتظار الموافقة
        return _buildPendingApprovalPage(result.merchant!);
      
      case MerchantAuthStatus.merchantRejected:
        // إرجاع صفحة الرفض مع إمكانية إعادة التقديم
        return _buildRejectedPage(result.merchant!);
      
      case MerchantAuthStatus.merchantSuspended:
        // إرجاع صفحة التعليق
        return _buildSuspendedPage(result.merchant!);
      
      case MerchantAuthStatus.merchantApproved:
      case MerchantAuthStatus.notMerchant:
        // الانتقال للصفحة الرئيسية العادية
        return _buildNormalHomePage();
      
      case MerchantAuthStatus.error:
      default:
        return _buildErrorPage(result.errorMessage);
    }
  }

  Widget _buildPendingApprovalPage(MerchantModel merchant) {
    // يتم استيراد هذا من الملف الذي أنشأناه
    return const Center(child: Text('Pending Approval - سيتم تنفيذه لاحقاً'));
  }

  Widget _buildRejectedPage(MerchantModel merchant) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cancel,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'تم رفض طلب التسجيل',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (merchant.statusReason != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'سبب الرفض:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(merchant.statusReason!),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // إمكانية إعادة التقديم أو الانتقال للصفحة الرئيسية
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('الانتقال للصفحة الرئيسية', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuspendedPage(MerchantModel merchant) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pause_circle_filled,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                'تم تعليق حسابك التجاري',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'تم تعليق حسابك التجاري مؤقتاً. يرجى التواصل مع الإدارة لمعرفة التفاصيل.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (merchant.statusReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'السبب:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(merchant.statusReason!),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // فتح صفحة التواصل مع الدعم
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text('تواصل مع الدعم'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNormalHomePage() {
    return const Scaffold(
      body: Center(
        child: Text('الصفحة الرئيسية - سيتم ربطها مع الصفحة الفعلية'),
      ),
    );
  }

  Widget _buildErrorPage(String? errorMessage) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'حدث خطأ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // إعادة المحاولة
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// مراقبة حالة التاجر في الوقت الفعلي
  Stream<MerchantAuthResult> watchMerchantStatus([User? user]) {
    user ??= _auth.currentUser;
    
    if (user == null) {
      return Stream.value(MerchantAuthResult(
        status: MerchantAuthStatus.error,
        errorMessage: 'المستخدم غير مسجل الدخول',
      ));
    }

    return _firestore
        .collection('merchant_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      try {
        if (snapshot.docs.isEmpty) {
          return MerchantAuthResult(status: MerchantAuthStatus.notMerchant);
        }

        final doc = snapshot.docs.first;
        final merchant = MerchantModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });

        MerchantAuthStatus status;
        switch (merchant.status) {
          case MerchantStatus.pending:
            status = MerchantAuthStatus.merchantPending;
            break;
          case MerchantStatus.approved:
            status = MerchantAuthStatus.merchantApproved;
            break;
          case MerchantStatus.rejected:
            status = MerchantAuthStatus.merchantRejected;
            break;
          case MerchantStatus.suspended:
            status = MerchantAuthStatus.merchantSuspended;
            break;
        }

        return MerchantAuthResult(
          status: status,
          merchant: merchant,
        );
      } catch (e) {
        return MerchantAuthResult(
          status: MerchantAuthStatus.error,
          errorMessage: e.toString(),
        );
      }
    });
  }

  /// تحديث بيانات المستخدم بعد الموافقة
  Future<void> updateUserAfterApproval(String userId, String merchantId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isMerchant': true,
        'merchantId': merchantId,
        'merchantStatus': 'approved',
        'updatedAt': Timestamp.now(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user after approval: $e');
      rethrow;
    }
  }

  /// تحديث بيانات المستخدم بعد الرفض أو التعليق
  Future<void> updateUserAfterRejectionOrSuspension(String userId, String status) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isMerchant': false,
        'merchantStatus': status,
        'updatedAt': Timestamp.now(),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user after rejection/suspension: $e');
      rethrow;
    }
  }
}
