import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/category_model.dart';

class CategoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static CategoryService? _instance;
  
  static CategoryService get instance {
    _instance ??= CategoryService._internal();
    return _instance!;
  }

  CategoryService._internal();

  // الحصول على أقسام التاجر
  Future<List<CategoryModel>> getMerchantCategories(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('sortOrder', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CategoryModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting merchant categories: $e');
      return [];
    }
  }

  // الحصول على قسم بالـ ID
  Future<CategoryModel?> getCategory(String categoryId) async {
    try {
      final docSnapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return CategoryModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting category: $e');
      return null;
    }
  }

  // إضافة قسم جديد
  Future<String?> addCategory(CategoryModel category, {File? iconImage, File? coverImage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      String iconUrl = category.iconUrl;
      String imageUrl = category.imageUrl;

      // رفع أيقونة القسم
      if (iconImage != null) {
        final uploadedIconUrl = await _uploadCategoryImage(iconImage, user.uid, 'icon_${DateTime.now().millisecondsSinceEpoch}');
        if (uploadedIconUrl != null) {
          iconUrl = uploadedIconUrl;
        }
      }

      // رفع صورة القسم
      if (coverImage != null) {
        final uploadedImageUrl = await _uploadCategoryImage(coverImage, user.uid, 'cover_${DateTime.now().millisecondsSinceEpoch}');
        if (uploadedImageUrl != null) {
          imageUrl = uploadedImageUrl;
        }
      }

      // إضافة القسم مع الصور
      final categoryData = category.copyWith(
        iconUrl: iconUrl,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toJson();

      categoryData.remove('id'); // إزالة الـ ID لأن Firestore سيولده

      final docRef = await _firestore.collection('categories').add(categoryData);
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding category: $e');
      return null;
    }
  }

  // تحديث قسم
  Future<bool> updateCategory(CategoryModel category, {File? newIcon, File? newImage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      String iconUrl = category.iconUrl;
      String imageUrl = category.imageUrl;

      // رفع الأيقونة الجديدة إذا تم تمريرها
      if (newIcon != null) {
        final uploadedIconUrl = await _uploadCategoryImage(newIcon, user.uid, 'icon_${category.id}_${DateTime.now().millisecondsSinceEpoch}');
        if (uploadedIconUrl != null) {
          iconUrl = uploadedIconUrl;
        }
      }

      // رفع الصورة الجديدة إذا تم تمريرها
      if (newImage != null) {
        final uploadedImageUrl = await _uploadCategoryImage(newImage, user.uid, 'cover_${category.id}_${DateTime.now().millisecondsSinceEpoch}');
        if (uploadedImageUrl != null) {
          imageUrl = uploadedImageUrl;
        }
      }

      final categoryData = category.copyWith(
        iconUrl: iconUrl,
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      ).toJson();

      categoryData.remove('id'); // إزالة الـ ID لأنه ليس جزءاً من البيانات

      await _firestore.collection('categories').doc(category.id).update(categoryData);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      return false;
    }
  }

  // حذف قسم
  Future<bool> deleteCategory(String categoryId) async {
    try {
      // حذف القسم من Firestore
      await _firestore.collection('categories').doc(categoryId).delete();
      
      // TODO: حذف الصور من Storage
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      return false;
    }
  }

  // تغيير حالة القسم
  Future<bool> updateCategoryStatus(String categoryId, CategoryStatus status) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating category status: $e');
      return false;
    }
  }

  // تحديث ترتيب الأقسام
  Future<bool> updateCategoriesOrder(List<CategoryModel> categories) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < categories.length; i++) {
        final categoryRef = _firestore.collection('categories').doc(categories[i].id);
        batch.update(categoryRef, {
          'sortOrder': i,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating categories order: $e');
      return false;
    }
  }

  // الحصول على الأقسام النشطة فقط
  Future<List<CategoryModel>> getActiveCategories(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'active')
          .orderBy('sortOrder', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CategoryModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting active categories: $e');
      return [];
    }
  }

  // Stream للأقسام في الوقت الفعلي
  Stream<List<CategoryModel>> streamMerchantCategories(String merchantId) {
    return _firestore
        .collection('categories')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('sortOrder', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return CategoryModel.fromJson(data);
            }).toList());
  }

  // رفع صورة القسم
  Future<String?> _uploadCategoryImage(File image, String userId, String imageName) async {
    try {
      final ref = _storage.ref().child('categories/$userId/$imageName.jpg');
      final uploadTask = await ref.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading category image: $e');
      return null;
    }
  }

  // حذف صورة القسم
  Future<bool> deleteCategoryImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting category image: $e');
      return false;
    }
  }
}
