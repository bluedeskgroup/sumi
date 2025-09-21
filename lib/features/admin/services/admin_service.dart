import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_model.dart';
import '../../merchant/models/merchant_model.dart';

class AdminService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static AdminService? _instance;
  AdminModel? _currentAdmin;

  // مفاتيح SharedPreferences
  static const String _isAdminLoggedInKey = 'admin_logged_in';
  static const String _adminDataKey = 'admin_data';

  static AdminService get instance {
    _instance ??= AdminService._internal();
    return _instance!;
  }

  AdminService._internal() {
    _initializeAdminSession();
  }

  /// تهيئة جلسة الأدمن من SharedPreferences
  Future<void> _initializeAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isAdminLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        final adminDataJson = prefs.getString(_adminDataKey);
        if (adminDataJson != null) {
          // التحقق من أن Firebase Auth مازال مسجل دخول
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            // استرجاع بيانات الأدمن من Firestore للتأكد من صحتها
            final adminDoc = await _firestore
                .collection('admins')
                .doc(currentUser.uid)
                .get();
                
            if (adminDoc.exists) {
              _currentAdmin = AdminModel.fromJson({
                'id': adminDoc.id,
                ...adminDoc.data()!,
              });
              notifyListeners();
            } else {
              // الأدمن غير موجود في قاعدة البيانات، مسح الجلسة
              await _clearAdminSession();
            }
          } else {
            // Firebase Auth غير مسجل دخول، مسح الجلسة
            await _clearAdminSession();
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ في تهيئة جلسة الأدمن: $e');
      await _clearAdminSession();
    }
  }

  /// حفظ جلسة الأدمن
  Future<void> _saveAdminSession(AdminModel admin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isAdminLoggedInKey, true);
      await prefs.setString(_adminDataKey, admin.id);
    } catch (e) {
      debugPrint('خطأ في حفظ جلسة الأدمن: $e');
    }
  }

  /// مسح جلسة الأدمن
  Future<void> _clearAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isAdminLoggedInKey);
      await prefs.remove(_adminDataKey);
      _currentAdmin = null;
      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في مسح جلسة الأدمن: $e');
    }
  }

  AdminModel? get currentAdmin => _currentAdmin;
  bool get isLoggedIn => _currentAdmin != null;

  /// تسجيل دخول الأدمن
  Future<bool> loginAdmin(String email, String password) async {
    try {
      // تسجيل دخول Firebase
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) return false;

      // التحقق من وجود الأدمن في قاعدة البيانات
      final adminDoc = await _firestore
          .collection('admins')
          .doc(credential.user!.uid)
          .get();

      if (!adminDoc.exists) {
        await _auth.signOut();
        return false;
      }

      // تحديث آخر تسجيل دخول
      await _firestore.collection('admins').doc(credential.user!.uid).update({
        'lastLoginAt': Timestamp.now(),
      });

      _currentAdmin = AdminModel.fromJson({
        'id': adminDoc.id,
        ...adminDoc.data()!,
      });

      // حفظ الجلسة في SharedPreferences
      await _saveAdminSession(_currentAdmin!);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('خطأ في تسجيل دخول الأدمن: $e');
      return false;
    }
  }

  /// تسجيل خروج الأدمن
  Future<void> logoutAdmin() async {
    await _auth.signOut();
    await _clearAdminSession();
  }

  /// إنشاء أدمن جديد (للسوبر أدمن فقط)
  Future<String> createAdmin({
    required String email,
    required String password,
    required String fullName,
    required AdminRole role,
    required List<AdminPermission> permissions,
  }) async {
    if (_currentAdmin?.role != AdminRole.superAdmin) {
      throw Exception('ليس لديك صلاحية لإنشاء أدمن جديد');
    }

    try {
      // إنشاء حساب في Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // إنشاء مستند الأدمن
      final admin = AdminModel(
        id: credential.user!.uid,
        email: email,
        fullName: fullName,
        role: role,
        permissions: permissions,
        isActive: true,
        createdAt: Timestamp.now(),
        lastLoginAt: Timestamp.now(),
        createdBy: _currentAdmin!.id,
      );

      await _firestore.collection('admins').doc(admin.id).set(admin.toJson());

      return admin.id;
    } catch (e) {
      debugPrint('خطأ في إنشاء الأدمن: $e');
      rethrow;
    }
  }

  /// الحصول على إحصائيات لوحة التحكم
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // إحصائيات التجار
      final pendingMerchants = await _firestore
          .collection('merchant_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      final approvedMerchants = await _firestore
          .collection('merchant_requests')
          .where('status', isEqualTo: 'approved')
          .get();

      final rejectedMerchants = await _firestore
          .collection('merchant_requests')
          .where('status', isEqualTo: 'rejected')
          .get();

      // إحصائيات المستخدمين
      final usersSnapshot = await _firestore.collection('users').get();
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .get();

      // إحصائيات المنتجات (إذا كانت موجودة)
      final productsSnapshot = await _firestore.collection('products').get();

      // إحصائيات الطلبات (إذا كانت موجودة)
      final ordersSnapshot = await _firestore.collection('orders').get();

      return {
        'merchants': {
          'pending': pendingMerchants.docs.length,
          'approved': approvedMerchants.docs.length,
          'rejected': rejectedMerchants.docs.length,
          'total': pendingMerchants.docs.length + 
                   approvedMerchants.docs.length + 
                   rejectedMerchants.docs.length,
        },
        'users': {
          'total': usersSnapshot.docs.length,
          'active': activeUsersSnapshot.docs.length,
        },
        'products': {
          'total': productsSnapshot.docs.length,
        },
        'orders': {
          'total': ordersSnapshot.docs.length,
        },
      };
    } catch (e) {
      debugPrint('خطأ في جلب إحصائيات لوحة التحكم: $e');
      return {};
    }
  }

  /// الحصول على طلبات التجار
  Stream<List<MerchantModel>> getMerchantRequests({MerchantStatus? status}) {
    Query query = _firestore.collection('merchant_requests');
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MerchantModel.fromJson({
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }))
            .toList());
  }

  /// الموافقة على طلب التاجر
  Future<void> approveMerchantRequest(String merchantId, String notes) async {
    if (!_currentAdmin!.hasPermission(AdminPermission.manageMerchants)) {
      throw Exception('ليس لديك صلاحية لإدارة التجار');
    }

    try {
      await _firestore.collection('merchant_requests').doc(merchantId).update({
        'status': MerchantStatus.approved.toString().split('.').last,
        'reviewedBy': _currentAdmin!.id,
        'reviewedAt': Timestamp.now(),
        'adminNotes': notes,
        'updatedAt': Timestamp.now(),
      });

      // إضافة سجل للعملية
      await _addActionLog('approve_merchant', merchantId, notes);
    } catch (e) {
      debugPrint('خطأ في الموافقة على طلب التاجر: $e');
      rethrow;
    }
  }

  /// رفض طلب التاجر
  Future<void> rejectMerchantRequest(String merchantId, String reason) async {
    if (!_currentAdmin!.hasPermission(AdminPermission.manageMerchants)) {
      throw Exception('ليس لديك صلاحية لإدارة التجار');
    }

    try {
      await _firestore.collection('merchant_requests').doc(merchantId).update({
        'status': MerchantStatus.rejected.toString().split('.').last,
        'reviewedBy': _currentAdmin!.id,
        'reviewedAt': Timestamp.now(),
        'statusReason': reason,
        'updatedAt': Timestamp.now(),
      });

      // إضافة سجل للعملية
      await _addActionLog('reject_merchant', merchantId, reason);
    } catch (e) {
      debugPrint('خطأ في رفض طلب التاجر: $e');
      rethrow;
    }
  }

  /// تعليق حساب التاجر
  Future<void> suspendMerchant(String merchantId, String reason) async {
    if (!_currentAdmin!.hasPermission(AdminPermission.manageMerchants)) {
      throw Exception('ليس لديك صلاحية لإدارة التجار');
    }

    try {
      await _firestore.collection('merchant_requests').doc(merchantId).update({
        'status': MerchantStatus.suspended.toString().split('.').last,
        'reviewedBy': _currentAdmin!.id,
        'reviewedAt': Timestamp.now(),
        'statusReason': reason,
        'updatedAt': Timestamp.now(),
      });

      // إضافة سجل للعملية
      await _addActionLog('suspend_merchant', merchantId, reason);
    } catch (e) {
      debugPrint('خطأ في تعليق حساب التاجر: $e');
      rethrow;
    }
  }

  /// إضافة سجل للعمليات الإدارية
  Future<void> _addActionLog(String action, String targetId, String notes) async {
    try {
      await _firestore.collection('admin_logs').add({
        'adminId': _currentAdmin!.id,
        'adminName': _currentAdmin!.fullName,
        'action': action,
        'targetId': targetId,
        'notes': notes,
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('خطأ في إضافة سجل العملية: $e');
    }
  }

  /// الحصول على سجل العمليات الإدارية
  Stream<List<Map<String, dynamic>>> getAdminLogs({int limit = 50}) {
    return _firestore
        .collection('admin_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// التحقق من صلاحية الأدمن الحالي
  bool hasPermission(AdminPermission permission) {
    return _currentAdmin?.hasPermission(permission) ?? false;
  }

  /// الحصول على بيانات تاجر محدد
  Future<MerchantModel?> getMerchantById(String merchantId) async {
    try {
      final doc = await _firestore
          .collection('merchant_requests')
          .doc(merchantId)
          .get();

      if (!doc.exists) return null;

      return MerchantModel.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('خطأ في جلب بيانات التاجر: $e');
      return null;
    }
  }
}
