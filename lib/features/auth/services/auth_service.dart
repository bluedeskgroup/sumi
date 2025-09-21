import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sumi/core/services/user_type_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Configure Firebase Auth settings for production
  void _configureFirebaseAuth() {
    // Enable reCAPTCHA fallback for production
    if (!kDebugMode) {
      _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: true,
      );
    }
  }

  // Stream for auth state changes
  Stream<User?> get user => _auth.authStateChanges();
  
  // التحقق من حالة تسجيل الدخول
  bool get isUserLoggedIn => _auth.currentUser != null;
  
  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;
  
  // إعادة تحميل بيانات المستخدم
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }

  // Sign in with Google مع معالجة أخطاء الشبكة
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // التحقق من توفر Google Play Services أولاً
      debugPrint('Checking Google Play Services availability...');
      
      // محاولة التأكد من الاتصال
      try {
        await _googleSignIn.signOut(); // إنهاء أي جلسة سابقة
      } catch (e) {
        debugPrint('Warning: Could not sign out previous session: $e');
      }
      
      // التحقق من حالة الخدمة
      final bool isAvailable = await _googleSignIn.isSignedIn();
      debugPrint('Google Sign-in service available: $isAvailable');
      
      // محاولة تسجيل الدخول مع timeout
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn()
          .timeout(const Duration(seconds: 30), onTimeout: () {
        debugPrint('Google sign-in timed out after 30 seconds');
        throw Exception('انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.');
      });
      
      if (googleUser == null) {
        debugPrint('User canceled Google sign-in');
        return null;
      }

      debugPrint('Google user obtained: ${googleUser.email}');
      
      // الحصول على بيانات الاعتماد مع timeout
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication
          .timeout(const Duration(seconds: 30), onTimeout: () {
        debugPrint('Google authentication timed out');
        throw Exception('انتهت مهلة الحصول على بيانات الاعتماد.');
      });

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('Failed to get Google auth tokens');
        throw Exception('فشل في الحصول على رموز الوصول من Google.');
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Attempting Firebase auth with Google credential');
      
      // محاولة تسجيل الدخول في Firebase مع timeout
      final userCredential = await _auth.signInWithCredential(credential)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        debugPrint('Firebase auth timed out');
        throw Exception('انتهت مهلة الاتصال بخوادم Firebase.');
      });
      
      // إنشاء ملف المستخدم في Firestore إذا كان مستخدم جديد
      if (userCredential.user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        debugPrint('Creating new user profile');
        try {
          await CommunityService().createUserProfile(userCredential.user!)
              .timeout(const Duration(seconds: 15));
        } catch (e) {
          debugPrint('Warning: Could not create user profile: $e');
          // يمكن المتابعة حتى لو فشل إنشاء الملف الشخصي
        }
      }

      debugPrint('Google sign-in successful');
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error during Google sign-in: ${e.code} - ${e.message}');
      
      // معالجة أخطاء محددة
      switch (e.code) {
        case 'network-request-failed':
          throw Exception('خطأ في الشبكة. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.');
        case 'too-many-requests':
          throw Exception('تم رفض الطلب بسبب كثرة المحاولات. انتظر قليلاً وحاول مرة أخرى.');
        case 'user-disabled':
          throw Exception('تم تعطيل هذا الحساب. اتصل بالدعم الفني.');
        default:
          throw Exception('خطأ في المصادقة: ${e.message}');
      }
      
    } on Exception catch (e) {
      debugPrint('Custom exception during Google sign-in: $e');
      rethrow;
    } catch (e) {
      debugPrint('General error during Google sign-in: $e');
      
      // معالجة أخطاء الشبكة الشائعة
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') || 
          errorString.contains('internet') ||
          errorString.contains('connection') ||
          errorString.contains('timeout') ||
          errorString.contains('unavailable')) {
        throw Exception('مشكلة في الاتصال بالإنترنت. تحقق من:\n' +
            '• الاتصال بالإنترنت\n' +
            '• إعدادات الشبكة\n' +
            '• خدمات Google Play');
      } else if (errorString.contains('7:') || errorString.contains('network_error')) {
        throw Exception('خطأ في خدمات Google Play. تحقق من:\n' +
            '• تحديث Google Play Services\n' +
            '• إعادة تشغيل التطبيق\n' +
            '• الاتصال بالإنترنت');
      } else {
        throw Exception('حدث خطأ غير متوقع. حاول مرة أخرى.');
      }
    }
  }

  // Phone Number Sign In
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
    int? forceResendingToken, // إضافة resend token للإرسال مرة أخرى
  }) async {
    try {
      // Configure Firebase Auth for production environment
      _configureFirebaseAuth();
      
      debugPrint('Attempting phone verification for: $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 120), // الحد الأقصى المسموح من Firebase
        verificationCompleted: verificationCompleted,
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.code} - ${e.message}');
          
          // Handle specific errors related to SMS blocking
          if (e.code == 'unknown' || e.message?.contains('18002') == true || e.message?.contains('17010') == true) {
            // SMS service blocked - provide alternative
            verificationFailed(FirebaseAuthException(
              code: 'sms-blocked',
              message: 'خدمة SMS مؤقتاً غير متاحة. يرجى المحاولة لاحقاً أو استخدام Google Sign-in.',
            ));
          } else {
            verificationFailed(e);
          }
        },
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        forceResendingToken: forceResendingToken, // استخدام resend token
      );
    } catch (e) {
      debugPrint('General error in phone verification: $e');
      verificationFailed(FirebaseAuthException(
        code: 'phone-verification-error',
        message: 'حدث خطأ في التحقق من الهاتف. يرجى المحاولة لاحقاً.',
      ));
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      // مسح نوع المستخدم المحفوظ محلياً
      await UserTypeService.clearUserType();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Delete user account and all associated data
  Future<bool> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No user to delete');
        return false;
      }

      final userId = user.uid;
      debugPrint('Starting account deletion for user: $userId');

      // حذف بيانات المستخدم من Firestore
      await _deleteUserDataFromFirestore(userId);

      // حذف الحساب من Firebase Auth
      await user.delete();
      
      // تسجيل الخروج من Google إذا كان مسجل دخول
      await _googleSignIn.signOut();
      
      debugPrint('Account deletion completed successfully');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error during account deletion: ${e.code} - ${e.message}');
      
      // إذا كان المطلوب إعادة تسجيل دخول حديث
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: 'requires-recent-login',
          message: 'يتطلب حذف الحساب تسجيل دخول حديث. يرجى تسجيل الخروج وإعادة تسجيل الدخول ثم المحاولة مرة أخرى.',
        );
      }
      return false;
    } catch (e) {
      debugPrint('General error during account deletion: $e');
      return false;
    }
  }

  // حذف جميع بيانات المستخدم من Firestore
  Future<void> _deleteUserDataFromFirestore(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // حذف ملف المستخدم الأساسي
      batch.delete(firestore.collection('users').doc(userId));

      // حذف منشورات المستخدم
      final postsSnapshot = await firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in postsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // حذف تعليقات المستخدم
      final commentsSnapshot = await firestore
          .collectionGroup('comments')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // حذف بيانات النقاط والتحديات
      final userChallengesRef = firestore.collection('users').doc(userId).collection('userChallenges');
      final userChallengesSnapshot = await userChallengesRef.get();
      for (var doc in userChallengesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // حذف معاملات النقاط
      final pointsTransactionsRef = firestore.collection('users').doc(userId).collection('pointsTransactions');
      final pointsTransactionsSnapshot = await pointsTransactionsRef.get();
      for (var doc in pointsTransactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // حذف بيانات الإحالة
      final referralTransactionsSnapshot = await firestore
          .collection('referralTransactions')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in referralTransactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // حذف طلبات السحب
      final withdrawalRequestsSnapshot = await firestore
          .collection('withdrawalRecords')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in withdrawalRequestsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // حذف بطاقات المستخدم
      final userCardsSnapshot = await firestore
          .collection('userCards')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in userCardsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // تنفيذ جميع عمليات الحذف
      await batch.commit();
      debugPrint('User data deleted from Firestore successfully');
    } catch (e) {
      debugPrint('Error deleting user data from Firestore: $e');
      throw e;
    }
  }

  // Phone Number Sign In is more complex and will be added
  // It requires UI for entering the phone number and then the OTP.
  // We will handle this in the UI logic that calls this service.
} 