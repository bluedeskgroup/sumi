import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/package_model.dart';

class PackageService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static PackageService? _instance;
  
  static PackageService get instance {
    _instance ??= PackageService._internal();
    return _instance!;
  }

  PackageService._internal();

  // الحصول على باقات التاجر
  Future<List<PackageModel>> getMerchantPackages(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('packages')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PackageModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting merchant packages: $e');
      return [];
    }
  }

  // الحصول على باقة بالـ ID
  Future<PackageModel?> getPackage(String packageId) async {
    try {
      final docSnapshot = await _firestore
          .collection('packages')
          .doc(packageId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return PackageModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting package: $e');
      return null;
    }
  }

  // إضافة باقة جديدة
  Future<String?> addPackage(PackageModel package, List<File> images) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      // رفع الصور
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final imageUrl = await _uploadPackageImage(images[i], user.uid, 'package_${DateTime.now().millisecondsSinceEpoch}_$i');
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      }

      // إضافة الباقة مع الصور
      final packageData = package.copyWith(
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toJson();

      packageData.remove('id'); // إزالة الـ ID لأن Firestore سيولده

      final docRef = await _firestore.collection('packages').add(packageData);
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding package: $e');
      return null;
    }
  }

  // تحديث باقة
  Future<bool> updatePackage(PackageModel package, {List<File>? newImages}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      List<String> imageUrls = List.from(package.imageUrls);

      // رفع الصور الجديدة إذا تم تمريرها
      if (newImages != null && newImages.isNotEmpty) {
        for (int i = 0; i < newImages.length; i++) {
          final imageUrl = await _uploadPackageImage(newImages[i], user.uid, 'package_${package.id}_${DateTime.now().millisecondsSinceEpoch}_$i');
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }
      }

      final packageData = package.copyWith(
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      ).toJson();

      packageData.remove('id'); // إزالة الـ ID لأنه ليس جزءاً من البيانات

      await _firestore.collection('packages').doc(package.id).update(packageData);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating package: $e');
      return false;
    }
  }

  // حذف باقة
  Future<bool> deletePackage(String packageId) async {
    try {
      // حذف الباقة من Firestore
      await _firestore.collection('packages').doc(packageId).delete();
      
      // TODO: حذف الصور من Storage
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting package: $e');
      return false;
    }
  }

  // البحث في الباقات
  Future<List<PackageModel>> searchPackages(String query, {String? merchantId, String? category}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore.collection('packages');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      final querySnapshot = await queryRef.get();

      List<PackageModel> packages = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PackageModel.fromJson(data);
      }).toList();

      // فلترة النتائج بناء على النص
      if (query.isNotEmpty) {
        packages = packages.where((package) =>
            package.name.toLowerCase().contains(query.toLowerCase()) ||
            package.description.toLowerCase().contains(query.toLowerCase()) ||
            package.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      }

      return packages;
    } catch (e) {
      debugPrint('Error searching packages: $e');
      return [];
    }
  }

  // الحصول على الباقات المميزة
  Future<List<PackageModel>> getFeaturedPackages({String? merchantId}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore
          .collection('packages')
          .where('isFeature', isEqualTo: true)
          .where('status', isEqualTo: 'active');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      final querySnapshot = await queryRef.limit(10).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PackageModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting featured packages: $e');
      return [];
    }
  }

  // الحصول على باقات بفئة معينة
  Future<List<PackageModel>> getPackagesByCategory(String category, {String? merchantId}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore
          .collection('packages')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      final querySnapshot = await queryRef.orderBy('updatedAt', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PackageModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting packages by category: $e');
      return [];
    }
  }

  // تغيير حالة الباقة
  Future<bool> updatePackageStatus(String packageId, PackageStatus status) async {
    try {
      await _firestore.collection('packages').doc(packageId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating package status: $e');
      return false;
    }
  }

  // تحديث الكمية المتاحة
  Future<bool> updateAvailableQuantity(String packageId, int newQuantity) async {
    try {
      await _firestore.collection('packages').doc(packageId).update({
        'availableQuantity': newQuantity,
        'updatedAt': Timestamp.now(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating available quantity: $e');
      return false;
    }
  }

  // Stream للباقات في الوقت الفعلي
  Stream<List<PackageModel>> streamMerchantPackages(String merchantId) {
    return _firestore
        .collection('packages')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return PackageModel.fromJson(data);
            }).toList());
  }

  // رفع صورة الباقة
  Future<String?> _uploadPackageImage(File image, String userId, String imageName) async {
    try {
      final ref = _storage.ref().child('packages/$userId/$imageName.jpg');
      final uploadTask = await ref.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading package image: $e');
      return null;
    }
  }

  // حذف صورة الباقة
  Future<bool> deletePackageImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting package image: $e');
      return false;
    }
  }
}
