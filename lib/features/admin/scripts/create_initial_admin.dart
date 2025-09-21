import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_model.dart';

/// سكريبت لإنشاء الأدمن الأولي
/// يتم تشغيله مرة واحدة فقط لإنشاء الحساب الرئيسي
class InitialAdminCreator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إنشاء الأدمن الأولي (السوبر أدمن)
  static Future<void> createInitialAdmin({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('بدء إنشاء الأدمن الأولي...');

      // التحقق من عدم وجود أدمن مسبقاً
      final existingAdmins = await _firestore.collection('admins').get();
      if (existingAdmins.docs.isNotEmpty) {
        print('يوجد أدمن مسبقاً في النظام. لا يمكن إنشاء أدمن جديد.');
        return;
      }

      // إنشاء حساب في Firebase Auth
      print('إنشاء حساب Firebase Auth...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('فشل في إنشاء حساب Firebase Auth');
      }

      // إنشاء مستند الأدمن
      print('إنشاء مستند الأدمن...');
      final admin = AdminModel(
        id: credential.user!.uid,
        email: email,
        fullName: fullName,
        role: AdminRole.superAdmin,
        permissions: AdminPermission.values, // جميع الصلاحيات
        isActive: true,
        createdAt: Timestamp.now(),
        lastLoginAt: Timestamp.now(),
      );

      await _firestore.collection('admins').doc(admin.id).set(admin.toJson());

      // تحديث displayName في Firebase Auth
      await credential.user!.updateDisplayName(fullName);

      print('تم إنشاء الأدمن الأولي بنجاح!');
      print('البريد الإلكتروني: $email');
      print('الاسم: $fullName');
      print('معرف المستخدم: ${credential.user!.uid}');

      // تسجيل خروج الأدمن المنشأ حديثاً
      await _auth.signOut();

    } catch (e) {
      print('خطأ في إنشاء الأدمن الأولي: $e');
      rethrow;
    }
  }

  /// إنشاء قواعد الأمان الأساسية للأدمن
  static Map<String, dynamic> getFirestoreSecurityRules() {
    return {
      'rules_version': '2',
      'service': 'cloud.firestore',
      'match': {
        '/databases/{database}/documents': {
          // قواعد مجموعة الأدمن
          'match /admins/{adminId}': {
            'allow': ['read', 'write'],
            'if': 'request.auth != null && request.auth.uid == adminId'
          },
          
          // قواعد طلبات التجار - الأدمن فقط
          'match /merchant_requests/{merchantId}': {
            'allow': ['read', 'write'],
            'if': 'request.auth != null'
          },
          
          // قواعد سجلات العمليات الإدارية
          'match /admin_logs/{logId}': {
            'allow': ['read', 'write'],
            'if': 'request.auth != null && request.auth.uid in get(/databases/\$(database)/documents/admins/\$(request.auth.uid)).data.keys'
          },
        }
      }
    };
  }

  /// مثال لاستخدام السكريبت
  static Future<void> runInitialSetup() async {
    try {
      await createInitialAdmin(
        email: 'admin@sumi.com',
        password: 'Admin123!',
        fullName: 'مدير النظام',
      );
    } catch (e) {
      print('خطأ في الإعداد الأولي: $e');
    }
  }
}
