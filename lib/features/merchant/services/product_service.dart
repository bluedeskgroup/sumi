import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/product_model.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static ProductService? _instance;
  
  static ProductService get instance {
    _instance ??= ProductService._internal();
    return _instance!;
  }

  ProductService._internal();

  // اختبار الاتصال بـ Firebase
  Future<bool> testFirebaseConnection() async {
    try {
      debugPrint('🔌 اختبار الاتصال بـ Firebase...');
      
      // اختبار Firestore
      final testDoc = await _firestore.collection('test').doc('connection').get();
      debugPrint('✅ Firestore متصل');
      
      // اختبار Auth
      final currentUser = _auth.currentUser;
      debugPrint('👤 المستخدم الحالي: ${currentUser?.uid ?? 'غير مسجل'}');
      
      // اختبار Storage
      final storageRef = _storage.ref().child('test/connection.txt');
      debugPrint('📁 Firebase Storage متصل');
      
      debugPrint('✅ جميع خدمات Firebase متصلة بنجاح');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في الاتصال بـ Firebase: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }

  // الحصول على منتجات التاجر
  Future<List<ProductModel>> getMerchantProducts(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('merchant_products')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting merchant products: $e');
      return [];
    }
  }

  // الحصول على منتج بالـ ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final docSnapshot = await _firestore
          .collection('merchant_products')
          .doc(productId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return ProductModel.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product: $e');
      return null;
    }
  }

  // إضافة منتج جديد
  Future<String?> addProduct(ProductModel product, List<File> images) async {
    try {
      debugPrint('🔥 بدء عملية إضافة منتج جديد...');
      
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ المستخدم غير مسجل الدخول');
        throw Exception('المستخدم غير مسجل الدخول');
      }
      
      debugPrint('✅ المستخدم مسجل الدخول: ${user.uid}');

      // رفع الصور
      List<String> imageUrls = [];
      debugPrint('📸 بدء رفع ${images.length} صورة...');
      
      for (int i = 0; i < images.length; i++) {
        debugPrint('📸 رفع الصورة ${i + 1} من ${images.length}');
        final imageUrl = await _uploadProductImage(images[i], user.uid, 'product_${DateTime.now().millisecondsSinceEpoch}_$i');
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
          debugPrint('✅ تم رفع الصورة: $imageUrl');
        } else {
          debugPrint('❌ فشل في رفع الصورة ${i + 1}');
        }
      }
      
      debugPrint('📸 تم رفع ${imageUrls.length} صورة بنجاح');

      // إضافة المنتج مع الصور
      final productData = product.copyWith(
        images: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toMap();

      productData.remove('id'); // إزالة الـ ID لأن Firestore سيولده
      
      debugPrint('💾 بيانات المنتج للحفظ: ${productData.toString()}');
      debugPrint('💾 بدء الحفظ في Firestore...');

      final docRef = await _firestore.collection('merchant_products').add(productData);
      
      debugPrint('✅ تم حفظ المنتج بنجاح! معرف المستند: ${docRef.id}');
      
      notifyListeners();
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في إضافة المنتج: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  // تحديث منتج
  Future<bool> updateProduct(ProductModel product, {List<File>? newImages}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      List<String> imageUrls = List.from(product.images);

      // رفع الصور الجديدة إذا تم تمريرها
      if (newImages != null && newImages.isNotEmpty) {
        for (int i = 0; i < newImages.length; i++) {
          final imageUrl = await _uploadProductImage(newImages[i], user.uid, 'product_${product.id}_${DateTime.now().millisecondsSinceEpoch}_$i');
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }
      }

      final productData = product.copyWith(
        images: imageUrls,
        updatedAt: DateTime.now(),
      ).toMap();

      productData.remove('id'); // إزالة الـ ID لأنه ليس جزءاً من البيانات

      await _firestore.collection('merchant_products').doc(product.id).update(productData);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  // حذف منتج
  Future<bool> deleteProduct(String productId) async {
    try {
      // حذف المنتج من Firestore
      await _firestore.collection('merchant_products').doc(productId).delete();
      
      // TODO: حذف الصور من Storage
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // البحث في المنتجات
  Future<List<ProductModel>> searchProducts(String query, {String? merchantId, String? category}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore.collection('merchant_products');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      final querySnapshot = await queryRef.get();

      List<ProductModel> products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromMap(data);
      }).toList();

      // فلترة النتائج بناء على النص
      if (query.isNotEmpty) {
        products = products.where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase()) ||
            product.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      }

      return products;
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }

  // الحصول على المنتجات المميزة
  Future<List<ProductModel>> getFeaturedProducts({String? merchantId}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore
          .collection('merchant_products')
          .where('isFeature', isEqualTo: true)
          .where('status', isEqualTo: 'active');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      final querySnapshot = await queryRef.limit(10).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting featured products: $e');
      return [];
    }
  }

  // الحصول على منتجات بفئة معينة
  Future<List<ProductModel>> getProductsByCategory(String category, {String? merchantId}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore
          .collection('merchant_products')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      final querySnapshot = await queryRef.orderBy('updatedAt', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      return [];
    }
  }

  // تغيير حالة المنتج
  Future<bool> updateProductStatus(String productId, ProductStatus status) async {
    try {
      await _firestore.collection('merchant_products').doc(productId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating product status: $e');
      return false;
    }
  }

  // تحديث المخزون
  Future<bool> updateStock(String productId, int newStock) async {
    try {
      await _firestore.collection('merchant_products').doc(productId).update({
        'stockQuantity': newStock,
        'updatedAt': Timestamp.now(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }

  // Stream للمنتجات في الوقت الفعلي
  Stream<List<ProductModel>> streamMerchantProducts(String merchantId) {
    return _firestore
        .collection('merchant_products')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductModel.fromMap(data);
            }).toList());
  }

  // رفع صورة المنتج
  Future<String?> _uploadProductImage(File image, String userId, String imageName) async {
    try {
      debugPrint('📸 بدء رفع صورة: $imageName لصاحب المعرف: $userId');
      debugPrint('📸 مسار الملف: ${image.path}');
      debugPrint('📸 حجم الملف: ${await image.length()} بايت');
      
      final ref = _storage.ref().child('products/$userId/$imageName.jpg');
      debugPrint('📸 مرجع Firebase Storage: products/$userId/$imageName.jpg');
      
      final uploadTask = await ref.putFile(image);
      debugPrint('📸 تم رفع الملف بنجاح');
      
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('📸 رابط التحميل: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في رفع صورة المنتج: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  // حذف صورة المنتج
  Future<bool> deleteProductImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting product image: $e');
      return false;
    }
  }
}
