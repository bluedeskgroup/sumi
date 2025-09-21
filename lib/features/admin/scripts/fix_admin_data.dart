import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// سكريبت لإصلاح بيانات الأدمن في Firestore
class AdminDataFixer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إصلاح بيانات الأدمن الموجودة
  static Future<void> fixAdminData(String adminEmail) async {
    try {
      print('بدء إصلاح بيانات الأدمن...');

      // البحث عن الأدمن بالبريد الإلكتروني
      final adminsQuery = await _firestore
          .collection('admins')
          .where('email', isEqualTo: adminEmail)
          .get();

      if (adminsQuery.docs.isEmpty) {
        print('لم يتم العثور على أدمن بهذا البريد الإلكتروني');
        return;
      }

      final adminDoc = adminsQuery.docs.first;
      final adminData = adminDoc.data();

      print('تم العثور على الأدمن: ${adminData['fullName']}');

      // إصلاح بيانات permissions إذا كانت String
      if (adminData['permissions'] is String) {
        print('إصلاح صلاحيات الأدمن...');
        
        final List<String> correctPermissions = [
          'manageMerchants',
          'manageUsers', 
          'manageContent',
          'viewAnalytics',
          'manageSettings',
          'manageNotifications'
        ];

        await adminDoc.reference.update({
          'permissions': correctPermissions,
          'updatedAt': Timestamp.now(),
        });

        print('تم إصلاح صلاحيات الأدمن بنجاح!');
      } else {
        print('صلاحيات الأدمن محفوظة بطريقة صحيحة');
      }

      // التأكد من وجود جميع البيانات المطلوبة
      final Map<String, dynamic> updates = {};

      if (!adminData.containsKey('createdAt') || adminData['createdAt'] == null) {
        updates['createdAt'] = Timestamp.now();
      }

      if (!adminData.containsKey('lastLoginAt') || adminData['lastLoginAt'] == null) {
        updates['lastLoginAt'] = Timestamp.now();
      }

      if (!adminData.containsKey('isActive')) {
        updates['isActive'] = true;
      }

      if (!adminData.containsKey('role') || adminData['role'] == null) {
        updates['role'] = 'superAdmin';
      }

      if (updates.isNotEmpty) {
        await adminDoc.reference.update(updates);
        print('تم تحديث البيانات الناقصة');
      }

      print('تم إصلاح بيانات الأدمن بنجاح!');
      print('يمكنك الآن تسجيل الدخول بـ:');
      print('Email: $adminEmail');
      print('Password: [كلمة المرور التي وضعتها في Firebase Auth]');

    } catch (e) {
      print('خطأ في إصلاح بيانات الأدمن: $e');
    }
  }

  /// إنشاء أدمن جديد مع البيانات الصحيحة
  static Future<void> createCorrectAdmin({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('إنشاء أدمن جديد...');

      // إنشاء حساب في Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // إنشاء مستند الأدمن بالطريقة الصحيحة
      await _firestore.collection('admins').doc(userId).set({
        'id': userId,
        'email': email,
        'fullName': fullName,
        'role': 'superAdmin',
        'permissions': [
          'manageMerchants',
          'manageUsers',
          'manageContent', 
          'viewAnalytics',
          'manageSettings',
          'manageNotifications'
        ],
        'isActive': true,
        'createdAt': Timestamp.now(),
        'lastLoginAt': Timestamp.now(),
      });

      print('تم إنشاء الأدمن بنجاح!');
      print('Email: $email');
      print('Password: $password');
      print('UID: $userId');

      // تسجيل خروج بعد الإنشاء
      await _auth.signOut();

    } catch (e) {
      print('خطأ في إنشاء الأدمن: $e');
    }
  }

  /// طباعة الطريقة الصحيحة لحفظ بيانات الأدمن
  static void printCorrectFormat() {
    print('');
    print('=== الطريقة الصحيحة لحفظ بيانات الأدمن في Firestore ===');
    print('');
    print('1. اذهب لـ Firebase Console');
    print('2. اضغط على Firestore Database');
    print('3. ابحث عن collection "admins"');
    print('4. اضغط على مستند الأدمن');
    print('5. تأكد من أن البيانات تبدو كما يلي:');
    print('');
    print('{');
    print('  "id": "UID_من_Firebase_Auth",');
    print('  "email": "admin@sumi.com",');
    print('  "fullName": "مدير النظام",');
    print('  "role": "superAdmin",');
    print('  "permissions": [');
    print('    "manageMerchants",');
    print('    "manageUsers",');
    print('    "manageContent",');
    print('    "viewAnalytics",');
    print('    "manageSettings",');
    print('    "manageNotifications"');
    print('  ],');
    print('  "isActive": true,');
    print('  "createdAt": "Timestamp",');
    print('  "lastLoginAt": "Timestamp"');
    print('}');
    print('');
    print('المهم: permissions لازم تكون Array وليس String!');
    print('');
  }
}
