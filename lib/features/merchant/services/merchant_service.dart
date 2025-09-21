import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/merchant_model.dart';

class MerchantService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static MerchantService? _instance;
  
  static MerchantService get instance {
    _instance ??= MerchantService._internal();
    return _instance!;
  }

  MerchantService._internal();

  // تحقق من وجود طلب تاجر للمستخدم الحالي
  Future<MerchantModel?> getCurrentUserMerchantRequest() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('merchant_requests')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        return MerchantModel.fromJson({
          'id': doc.docs.first.id,
          ...doc.docs.first.data(),
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error getting merchant request: $e');
      return null;
    }
  }

  // تقديم طلب تسجيل تاجر
  Future<String> submitMerchantRequest(MerchantModel merchant) async {
    try {
      final docRef = await _firestore.collection('merchant_requests').add(merchant.toJson());
      
      // إرسال إشعار للأدمن
      await _sendAdminNotification(
        'طلب تاجر جديد',
        'تم تقديم طلب تسجيل تاجر جديد من ${merchant.fullName}',
        docRef.id,
      );

      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting merchant request: $e');
      rethrow;
    }
  }

  // تحديث طلب التاجر
  Future<void> updateMerchantRequest(String id, MerchantModel merchant) async {
    try {
      await _firestore.collection('merchant_requests').doc(id).update(
        merchant.copyWith(
          updatedAt: Timestamp.now(),
        ).toJson(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating merchant request: $e');
      rethrow;
    }
  }

  // رفع الملفات إلى Firebase Storage
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  // رفع صورة واحدة
  Future<String> uploadMerchantImage(File imageFile, String merchantId, String imageType) async {
    final path = 'merchant_documents/$merchantId/$imageType/${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadFile(imageFile, path);
  }

  // رفع عدة صور للمنتجات
  Future<List<String>> uploadProductImages(List<File> imageFiles, String merchantId) async {
    final List<String> urls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final path = 'merchant_documents/$merchantId/products/product_$i${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await uploadFile(imageFiles[i], path);
      urls.add(url);
    }
    
    return urls;
  }

  // الحصول على جميع طلبات التجار (للأدمن)
  Stream<List<MerchantModel>> getAllMerchantRequests() {
    return _firestore
        .collection('merchant_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MerchantModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // الحصول على طلبات التجار بحسب الحالة
  Stream<List<MerchantModel>> getMerchantRequestsByStatus(MerchantStatus status) {
    return _firestore
        .collection('merchant_requests')
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MerchantModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // الحصول على طلب تاجر محدد
  Future<MerchantModel?> getMerchantRequest(String id) async {
    try {
      final doc = await _firestore.collection('merchant_requests').doc(id).get();
      
      if (doc.exists) {
        return MerchantModel.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      debugPrint('Error getting merchant request: $e');
      return null;
    }
  }

  // الموافقة على طلب التاجر (للأدمن)
  Future<void> approveMerchantRequest(String id, String adminId, {String? notes}) async {
    try {
      final merchant = await getMerchantRequest(id);
      if (merchant == null) throw Exception('لم يتم العثور على طلب التاجر');

      // تحديث حالة الطلب
      await _firestore.collection('merchant_requests').doc(id).update({
        'status': MerchantStatus.approved.toString().split('.').last,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        'adminNotes': notes,
        'updatedAt': Timestamp.now(),
      });

      // إضافة التاجر إلى مجموعة التجار المعتمدين
      await _firestore.collection('approved_merchants').doc(id).set(merchant.copyWith(
        status: MerchantStatus.approved,
        reviewedBy: adminId,
        reviewedAt: Timestamp.now(),
        adminNotes: notes,
        updatedAt: Timestamp.now(),
      ).toJson());

      // تحديث بيانات المستخدم لإضافة صفة التاجر
      await _firestore.collection('users').doc(merchant.userId).update({
        'isMerchant': true,
        'merchantId': id,
        'merchantStatus': 'approved',
        'updatedAt': Timestamp.now(),
      });

      // إرسال إشعار للتاجر
      await _sendMerchantNotification(
        merchant.userId,
        'تهانينا! تم قبول طلب التسجيل',
        'تم الموافقة على طلب تسجيلك كتاجر. يمكنك الآن البدء في إضافة منتجاتك.',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error approving merchant request: $e');
      rethrow;
    }
  }

  // رفض طلب التاجر (للأدمن)
  Future<void> rejectMerchantRequest(String id, String adminId, String reason) async {
    try {
      final merchant = await getMerchantRequest(id);
      if (merchant == null) throw Exception('لم يتم العثور على طلب التاجر');

      await _firestore.collection('merchant_requests').doc(id).update({
        'status': MerchantStatus.rejected.toString().split('.').last,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        'statusReason': reason,
        'updatedAt': Timestamp.now(),
      });

      // إرسال إشعار للتاجر
      await _sendMerchantNotification(
        merchant.userId,
        'تم رفض طلب التسجيل',
        'نأسف لإبلاغك بأنه تم رفض طلب تسجيلك كتاجر. السبب: $reason',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting merchant request: $e');
      rethrow;
    }
  }

  // تعليق تاجر (للأدمن)
  Future<void> suspendMerchant(String id, String adminId, String reason) async {
    try {
      await _firestore.collection('merchant_requests').doc(id).update({
        'status': MerchantStatus.suspended.toString().split('.').last,
        'reviewedBy': adminId,
        'reviewedAt': Timestamp.now(),
        'statusReason': reason,
        'updatedAt': Timestamp.now(),
      });

      // تحديث في جدول التجار المعتمدين
      await _firestore.collection('approved_merchants').doc(id).update({
        'status': MerchantStatus.suspended.toString().split('.').last,
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });

      final merchant = await getMerchantRequest(id);
      if (merchant != null) {
        // تحديث بيانات المستخدم
        await _firestore.collection('users').doc(merchant.userId).update({
          'merchantStatus': 'suspended',
          'updatedAt': Timestamp.now(),
        });

        // إرسال إشعار للتاجر
        await _sendMerchantNotification(
          merchant.userId,
          'تم تعليق حسابك التجاري',
          'تم تعليق حسابك التجاري. السبب: $reason. يرجى التواصل مع الإدارة.',
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error suspending merchant: $e');
      rethrow;
    }
  }

  // الحصول على التجار المعتمدين
  Stream<List<MerchantModel>> getApprovedMerchants() {
    return _firestore
        .collection('approved_merchants')
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MerchantModel.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  // البحث في التجار
  Future<List<MerchantModel>> searchMerchants(String query) async {
    try {
      // البحث في اسم التاجر
      final nameResults = await _firestore
          .collection('approved_merchants')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // البحث في اسم العمل
      final businessResults = await _firestore
          .collection('approved_merchants')
          .where('businessName', isGreaterThanOrEqualTo: query)
          .where('businessName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final Set<String> seenIds = {};
      final List<MerchantModel> results = [];

      // جمع النتائج وتجنب التكرار
      for (var doc in [...nameResults.docs, ...businessResults.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          results.add(MerchantModel.fromJson({
            'id': doc.id,
            ...doc.data(),
          }));
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching merchants: $e');
      return [];
    }
  }

  // إحصائيات التجار
  Future<Map<String, int>> getMerchantStats() async {
    try {
      final pending = await _firestore
          .collection('merchant_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      final approved = await _firestore
          .collection('approved_merchants')
          .where('status', isEqualTo: 'approved')
          .get();

      final rejected = await _firestore
          .collection('merchant_requests')
          .where('status', isEqualTo: 'rejected')
          .get();

      final suspended = await _firestore
          .collection('merchant_requests')
          .where('status', isEqualTo: 'suspended')
          .get();

      return {
        'pending': pending.docs.length,
        'approved': approved.docs.length,
        'rejected': rejected.docs.length,
        'suspended': suspended.docs.length,
        'total': pending.docs.length + approved.docs.length + rejected.docs.length + suspended.docs.length,
      };
    } catch (e) {
      debugPrint('Error getting merchant stats: $e');
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'suspended': 0,
        'total': 0,
      };
    }
  }

  // إرسال إشعار للأدمن
  Future<void> _sendAdminNotification(String title, String body, String merchantId) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'title': title,
        'body': body,
        'type': 'merchant_request',
        'merchantId': merchantId,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error sending admin notification: $e');
    }
  }

  // إرسال إشعار للتاجر
  Future<void> _sendMerchantNotification(String userId, String title, String body) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': 'merchant_status',
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error sending merchant notification: $e');
    }
  }

  // تحقق من صحة البيانات
  Map<String, String> validateMerchantData(MerchantModel merchant) {
    final Map<String, String> errors = {};

    // التحقق من البيانات الأساسية
    if (merchant.fullName.trim().length < 3) {
      errors['fullName'] = 'الاسم يجب أن يكون 3 أحرف على الأقل';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(merchant.email)) {
      errors['email'] = 'البريد الإلكتروني غير صحيح';
    }

    if (merchant.phoneNumber.length < 10) {
      errors['phoneNumber'] = 'رقم الهاتف غير صحيح';
    }

    if (merchant.nationalId.length != 14) {
      errors['nationalId'] = 'رقم الهوية يجب أن يكون 14 رقم';
    }

    // التحقق من بيانات العمل
    if (merchant.businessName.trim().length < 3) {
      errors['businessName'] = 'اسم العمل يجب أن يكون 3 أحرف على الأقل';
    }

    if (merchant.businessDescription.trim().length < 10) {
      errors['businessDescription'] = 'وصف العمل يجب أن يكون 10 أحرف على الأقل';
    }

    if (merchant.businessAddress.trim().length < 10) {
      errors['businessAddress'] = 'عنوان العمل يجب أن يكون واضح ومفصل';
    }

    // التحقق من البيانات المالية
    if (merchant.bankName.trim().isEmpty) {
      errors['bankName'] = 'اسم البنك مطلوب';
    }

    if (merchant.accountNumber.length < 8) {
      errors['accountNumber'] = 'رقم الحساب غير صحيح';
    }

    if (merchant.iban.length < 15) {
      errors['iban'] = 'رقم الآيبان غير صحيح';
    }

    return errors;
  }

  // التحقق من وجود تاجر بنفس البيانات
  Future<bool> checkDuplicateMerchant(String nationalId, String email) async {
    try {
      final nationalIdCheck = await _firestore
          .collection('merchant_requests')
          .where('nationalId', isEqualTo: nationalId)
          .limit(1)
          .get();

      final emailCheck = await _firestore
          .collection('merchant_requests')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return nationalIdCheck.docs.isNotEmpty || emailCheck.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking duplicate merchant: $e');
      return false;
    }
  }
}
