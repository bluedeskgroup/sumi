import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/merchant/models/merchant_model.dart';

/// خدمة إدارة نوع المستخدم (تاجر أم مستخدم عادي)
class UserTypeService {
  static const String _userTypeKey = 'user_type';
  static const String _userDataKey = 'user_data';
  
  /// أنواع المستخدمين
  static const String typeUser = 'user';
  static const String typeMerchant = 'merchant';
  static const String typeAdmin = 'admin';

  /// حفظ نوع المستخدم
  static Future<void> saveUserType(String userType, {Map<String, dynamic>? userData}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userTypeKey, userType);
      
      if (userData != null) {
        final userDataJson = userData.map((key, value) => MapEntry(key, value.toString()));
        await prefs.setString(_userDataKey, userDataJson.toString());
      }
      
      print('تم حفظ نوع المستخدم: $userType');
    } catch (e) {
      print('خطأ في حفظ نوع المستخدم: $e');
    }
  }

  /// الحصول على نوع المستخدم المحفوظ
  static Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userTypeKey);
    } catch (e) {
      print('خطأ في استرجاع نوع المستخدم: $e');
      return null;
    }
  }

  /// فحص إذا كان المستخدم تاجر
  static Future<bool> isMerchant() async {
    final userType = await getUserType();
    return userType == typeMerchant;
  }

  /// فحص إذا كان المستخدم عادي
  static Future<bool> isUser() async {
    final userType = await getUserType();
    return userType == typeUser;
  }

  /// فحص إذا كان المستخدم أدمن
  static Future<bool> isAdmin() async {
    final userType = await getUserType();
    return userType == typeAdmin;
  }

  /// مسح نوع المستخدم (عند تسجيل الخروج)
  static Future<void> clearUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userTypeKey);
      await prefs.remove(_userDataKey);
      print('تم مسح نوع المستخدم');
    } catch (e) {
      print('خطأ في مسح نوع المستخدم: $e');
    }
  }

  /// الحصول على بيانات المستخدم المحفوظة
  static Future<String?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userDataKey);
    } catch (e) {
      print('خطأ في استرجاع بيانات المستخدم: $e');
      return null;
    }
  }

  /// جلب بيانات التاجر من Firestore
  static Future<MerchantModel?> getMerchantData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('لا يوجد مستخدم مسجل دخول');
        return null;
      }

      // البحث في التجار المعتمدين أولاً
      final approvedDoc = await FirebaseFirestore.instance
          .collection('approved_merchants')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (approvedDoc.docs.isNotEmpty) {
        final merchantData = approvedDoc.docs.first.data();
        merchantData['id'] = approvedDoc.docs.first.id;
        print('تم العثور على بيانات التاجر المعتمد');
        return MerchantModel.fromJson(merchantData);
      }

      // إذا لم نجد في التجار المعتمدين، ابحث في طلبات التجار
      final requestDoc = await FirebaseFirestore.instance
          .collection('merchant_requests')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (requestDoc.docs.isNotEmpty) {
        final merchantData = requestDoc.docs.first.data();
        merchantData['id'] = requestDoc.docs.first.id;
        print('تم العثور على طلب التاجر');
        return MerchantModel.fromJson(merchantData);
      }

      print('لم يتم العثور على بيانات التاجر');
      return null;
    } catch (e) {
      print('خطأ في جلب بيانات التاجر: $e');
      return null;
    }
  }
}
