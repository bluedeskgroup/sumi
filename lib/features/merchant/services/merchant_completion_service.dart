import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/merchant_model.dart';

/// خدمة تتبع إكمال المهام للتاجر
class MerchantCompletionService {
  static final MerchantCompletionService _instance = MerchantCompletionService._internal();
  static MerchantCompletionService get instance => _instance;
  MerchantCompletionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// فحص حالة إكمال جميع المهام للتاجر
  Future<Map<String, bool>> checkTaskCompletion(String merchantId) async {
    try {
      final results = await Future.wait([
        _checkStoreInfoCompleted(merchantId),
        _checkCategoriesCompleted(merchantId),
        _checkProductsCompleted(merchantId),
        _checkPackagesCompleted(merchantId),
      ]);

      return {
        'store_info': results[0],
        'categories': results[1],
        'products': results[2],
        'packages': results[3],
      };
    } catch (e) {
      print('خطأ في فحص إكمال المهام: $e');
      return {
        'store_info': false,
        'categories': false,
        'products': false,
        'packages': false,
      };
    }
  }

  /// فحص إكمال معلومات المتجر
  Future<bool> _checkStoreInfoCompleted(String merchantId) async {
    try {
      final doc = await _firestore.collection('merchant_requests')
          .where('id', isEqualTo: merchantId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        return data['businessName'] != null && 
               data['businessName'].toString().isNotEmpty &&
               data['description'] != null && 
               data['description'].toString().isNotEmpty &&
               data['profileImageUrl'] != null && 
               data['profileImageUrl'].toString().isNotEmpty;
      }
      return false;
    } catch (e) {
      print('خطأ في فحص معلومات المتجر: $e');
      return false;
    }
  }

  /// فحص إكمال الأقسام
  Future<bool> _checkCategoriesCompleted(String merchantId) async {
    try {
      final categories = await _firestore.collection('categories')
          .where('merchantId', isEqualTo: merchantId)
          .get();
      return categories.docs.isNotEmpty;
    } catch (e) {
      print('خطأ في فحص الأقسام: $e');
      return false;
    }
  }

  /// فحص إكمال المنتجات
  Future<bool> _checkProductsCompleted(String merchantId) async {
    try {
      final products = await _firestore.collection('products')
          .where('merchantId', isEqualTo: merchantId)
          .get();
      return products.docs.isNotEmpty;
    } catch (e) {
      print('خطأ في فحص المنتجات: $e');
      return false;
    }
  }

  /// فحص إكمال الباقات
  Future<bool> _checkPackagesCompleted(String merchantId) async {
    try {
      final packages = await _firestore.collection('merchant_packages')
          .where('merchantId', isEqualTo: merchantId)
          .get();
      return packages.docs.isNotEmpty;
    } catch (e) {
      print('خطأ في فحص الباقات: $e');
      return false;
    }
  }

  /// تحديث معلومات المتجر
  Future<bool> updateStoreInfo({
    required String merchantId,
    required String businessName,
    required String description,
    required String profileImageUrl,
  }) async {
    try {
      await _firestore.collection('merchant_requests')
          .where('id', isEqualTo: merchantId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.first.reference.update({
            'businessName': businessName,
            'description': description,
            'profileImageUrl': profileImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث معلومات المتجر: $e');
      return false;
    }
  }

  /// إضافة قسم جديد
  Future<bool> addCategory({
    required String merchantId,
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    try {
      await _firestore.collection('categories').add({
        'merchantId': merchantId,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في إضافة القسم: $e');
      return false;
    }
  }

  /// إضافة منتج جديد
  Future<bool> addProduct({
    required String merchantId,
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required List<String> imageUrls,
    required int quantity,
  }) async {
    try {
      await _firestore.collection('products').add({
        'merchantId': merchantId,
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'imageUrls': imageUrls,
        'quantity': quantity,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في إضافة المنتج: $e');
      return false;
    }
  }

  /// إضافة خدمة جديدة
  Future<bool> addService({
    required String merchantId,
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required List<String> imageUrls,
    required String duration,
  }) async {
    try {
      await _firestore.collection('services').add({
        'merchantId': merchantId,
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'imageUrls': imageUrls,
        'duration': duration,
        'isActive': true,
        'type': 'service',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في إضافة الخدمة: $e');
      return false;
    }
  }

  /// إضافة باقة جديدة
  Future<bool> addPackage({
    required String merchantId,
    required String name,
    required String description,
    required double price,
    required List<String> features,
  }) async {
    try {
      await _firestore.collection('merchant_packages').add({
        'merchantId': merchantId,
        'name': name,
        'description': description,
        'price': price,
        'features': features,
        'isActive': true,
        'subscribedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في إضافة الباقة: $e');
      return false;
    }
  }

  /// فحص إكمال جميع المهام
  Future<bool> isAllTasksCompleted(String merchantId) async {
    final completion = await checkTaskCompletion(merchantId);
    return completion.values.every((completed) => completed);
  }

  /// الحصول على نسبة الإكمال
  Future<double> getCompletionPercentage(String merchantId) async {
    final completion = await checkTaskCompletion(merchantId);
    final completedCount = completion.values.where((completed) => completed).length;
    return completedCount / completion.length;
  }
}
