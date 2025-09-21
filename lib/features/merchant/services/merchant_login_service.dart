import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/merchant_model.dart';

/// نتيجة عملية تسجيل دخول التاجر
class MerchantLoginResult {
  final bool success;
  final String? errorMessage;
  final MerchantModel? merchant;
  final User? user;

  MerchantLoginResult({
    required this.success,
    this.errorMessage,
    this.merchant,
    this.user,
  });
}

/// خدمة تسجيل دخول التاجر
class MerchantLoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static MerchantLoginService? _instance;
  
  static MerchantLoginService get instance {
    _instance ??= MerchantLoginService._internal();
    return _instance!;
  }

  MerchantLoginService._internal();

  /// تسجيل دخول التاجر بالبريد الإلكتروني وكلمة السر
  Future<MerchantLoginResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // تسجيل الدخول بـ Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user == null) {
        return MerchantLoginResult(
          success: false,
          errorMessage: 'فشل في تسجيل الدخول',
        );
      }

      // التحقق من حالة التاجر
      final merchantResult = await _verifyMerchantStatus(credential.user!);
      return merchantResult;

    } on FirebaseAuthException catch (e) {
      String message = _getAuthErrorMessage(e.code);
      return MerchantLoginResult(
        success: false,
        errorMessage: message,
      );
    } catch (e) {
      return MerchantLoginResult(
        success: false,
        errorMessage: 'حدث خطأ غير متوقع: $e',
      );
    }
  }

  /// تسجيل دخول التاجر برقم الهاتف وكلمة السر
  Future<MerchantLoginResult> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // البحث عن البريد الإلكتروني المرتبط برقم الهاتف
      final email = await _findEmailByPhoneNumber(phoneNumber);
      
      // تسجيل الدخول بالبريد الإلكتروني
      return await signInWithEmail(email: email, password: password);
      
    } catch (e) {
      return MerchantLoginResult(
        success: false,
        errorMessage: 'خطأ في البحث عن الحساب: $e',
      );
    }
  }

  /// التحقق من حالة التاجر والحصول على بياناته
  Future<MerchantLoginResult> _verifyMerchantStatus(User user) async {
    try {
      // البحث عن التاجر في قاعدة البيانات
      final querySnapshot = await _firestore
          .collection('merchant_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // المستخدم ليس مسجل كتاجر
        await _auth.signOut();
        return MerchantLoginResult(
          success: false,
          errorMessage: 'هذا الحساب ليس مسجل كتاجر. يرجى التسجيل كتاجر أولاً.',
        );
      }

      final merchantDoc = querySnapshot.docs.first;
      final merchant = MerchantModel.fromJson({
        'id': merchantDoc.id,
        ...merchantDoc.data(),
      });

      // التحقق من حالة الموافقة
      switch (merchant.status) {
        case MerchantStatus.approved:
          // التاجر مُوافق عليه - نجح تسجيل الدخول
          return MerchantLoginResult(
            success: true,
            merchant: merchant,
            user: user,
          );

        case MerchantStatus.pending:
          await _auth.signOut();
          return MerchantLoginResult(
            success: false,
            errorMessage: 'طلب التاجر قيد المراجعة. يرجى انتظار الموافقة من الإدارة.',
          );

        case MerchantStatus.rejected:
          await _auth.signOut();
          return MerchantLoginResult(
            success: false,
            errorMessage: 'تم رفض طلب التاجر. يرجى التواصل مع الدعم الفني للمزيد من المعلومات.',
          );

        case MerchantStatus.suspended:
          await _auth.signOut();
          return MerchantLoginResult(
            success: false,
            errorMessage: 'حساب التاجر معلق. يرجى التواصل مع الدعم الفني.',
          );

        default:
          await _auth.signOut();
          return MerchantLoginResult(
            success: false,
            errorMessage: 'حالة التاجر غير محددة. يرجى التواصل مع الدعم الفني.',
          );
      }

    } catch (e) {
      await _auth.signOut();
      return MerchantLoginResult(
        success: false,
        errorMessage: 'خطأ في التحقق من حالة التاجر: $e',
      );
    }
  }

  /// البحث عن البريد الإلكتروني المرتبط برقم الهاتف
  Future<String> _findEmailByPhoneNumber(String phoneNumber) async {
    try {
      // تحضير كل الصيغ المحتملة لرقم الهاتف
      final phoneVariations = _getPhoneVariations(phoneNumber);
      
      print('البحث عن رقم الهاتف بالصيغ التالية: $phoneVariations');
      
      // البحث في طلبات التجار المُوافق عليها
      for (final phoneVariation in phoneVariations) {
        final querySnapshot = await _firestore
            .collection('merchant_requests')
            .where('phoneNumber', isEqualTo: phoneVariation)
            .where('status', isEqualTo: 'approved')
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final merchantData = querySnapshot.docs.first.data();
          print('تم العثور على التاجر برقم: $phoneVariation');
          return merchantData['email'] as String;
        }
      }
      
      print('لم يتم العثور على تاجر بأي صيغة من: $phoneVariations');
      throw Exception('لا يوجد تاجر مُوافق عليه بهذا رقم الهاتف.');
      
    } catch (e) {
      print('خطأ في البحث عن رقم الهاتف: $e');
      rethrow;
    }
  }

  /// إنشاء قائمة بكل الصيغ المحتملة لرقم الهاتف
  List<String> _getPhoneVariations(String phoneNumber) {
    final variations = <String>[];
    
    // الرقم كما هو
    variations.add(phoneNumber);
    
    // إزالة كل الرموز غير الرقمية
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    variations.add(digitsOnly);
    
    // إذا كان الرقم يبدأ بـ 966، إنشاء صيغ مختلفة
    if (digitsOnly.startsWith('966')) {
      final localNumber = digitsOnly.substring(3); // 501234567
      variations.add(localNumber);
      variations.add('+966$localNumber');
    }
    // إذا كان الرقم محلي (يبدأ بـ 5 أو 05)
    else if (digitsOnly.startsWith('5') || digitsOnly.startsWith('05')) {
      final localNumber = digitsOnly.startsWith('05') 
          ? digitsOnly.substring(1) // 501234567
          : digitsOnly; // 501234567
      variations.add(localNumber);
      variations.add('966$localNumber');
      variations.add('+966$localNumber');
    }
    
    // إزالة التكرارات
    return variations.toSet().toList();
  }

  /// الحصول على رسالة خطأ مترجمة
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
      case 'wrong-password':
        return 'كلمة السر غير صحيحة.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح.';
      case 'user-disabled':
        return 'هذا الحساب معطل. يرجى التواصل مع الدعم الفني.';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموحة. يرجى المحاولة لاحقاً.';
      case 'operation-not-allowed':
        return 'تسجيل الدخول بالبريد الإلكتروني غير مُفعل.';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صحيحة.';
      case 'account-exists-with-different-credential':
        return 'يوجد حساب بنفس البريد الإلكتروني مع طريقة دخول مختلفة.';
      case 'network-request-failed':
        return 'خطأ في الاتصال بالإنترنت. يرجى المحاولة مرة أخرى.';
      default:
        return 'حدث خطأ في تسجيل الدخول. يرجى المحاولة مرة أخرى.';
    }
  }

  /// تسجيل خروج التاجر
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('خطأ في تسجيل الخروج: $e');
      rethrow;
    }
  }

  /// الحصول على التاجر الحالي
  Future<MerchantModel?> getCurrentMerchant() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final querySnapshot = await _firestore
          .collection('merchant_requests')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final merchantDoc = querySnapshot.docs.first;
      return MerchantModel.fromJson({
        'id': merchantDoc.id,
        ...merchantDoc.data(),
      });

    } catch (e) {
      debugPrint('خطأ في الحصول على التاجر الحالي: $e');
      return null;
    }
  }

  /// التحقق من أن المستخدم الحالي تاجر مُوافق عليه
  Future<bool> isCurrentUserApprovedMerchant() async {
    final merchant = await getCurrentMerchant();
    return merchant?.status == MerchantStatus.approved;
  }

  /// مراقبة حالة تسجيل دخول التاجر
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;
}
