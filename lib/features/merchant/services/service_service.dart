import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/service_model.dart';

class ServiceService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static ServiceService? _instance;
  
  static ServiceService get instance {
    _instance ??= ServiceService._internal();
    return _instance!;
  }

  ServiceService._internal();

  // الحصول على خدمات التاجر
  Future<List<ServiceModel>> getMerchantServices(String merchantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('services')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting merchant services: $e');
      return [];
    }
  }

  // الحصول على خدمة بالـ ID
  Future<ServiceModel?> getService(String serviceId) async {
    try {
      final docSnapshot = await _firestore
          .collection('services')
          .doc(serviceId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        data['id'] = docSnapshot.id;
        return ServiceModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting service: $e');
      return null;
    }
  }

  // إضافة خدمة جديدة
  Future<String?> addService(ServiceModel service, List<File> images) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      // رفع الصور
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final imageUrl = await _uploadServiceImage(images[i], user.uid, 'service_${DateTime.now().millisecondsSinceEpoch}_$i');
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      }

      // إضافة الخدمة مع الصور
      final serviceData = service.copyWith(
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toJson();

      serviceData.remove('id'); // إزالة الـ ID لأن Firestore سيولده

      final docRef = await _firestore.collection('services').add(serviceData);
      
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding service: $e');
      return null;
    }
  }

  // تحديث خدمة
  Future<bool> updateService(ServiceModel service, {List<File>? newImages}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      List<String> imageUrls = List.from(service.imageUrls);

      // رفع الصور الجديدة إذا تم تمريرها
      if (newImages != null && newImages.isNotEmpty) {
        for (int i = 0; i < newImages.length; i++) {
          final imageUrl = await _uploadServiceImage(newImages[i], user.uid, 'service_${service.id}_${DateTime.now().millisecondsSinceEpoch}_$i');
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }
      }

      final serviceData = service.copyWith(
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      ).toJson();

      serviceData.remove('id'); // إزالة الـ ID لأنه ليس جزءاً من البيانات

      await _firestore.collection('services').doc(service.id).update(serviceData);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating service: $e');
      return false;
    }
  }

  // حذف خدمة
  Future<bool> deleteService(String serviceId) async {
    try {
      // حذف الخدمة من Firestore
      await _firestore.collection('services').doc(serviceId).delete();
      
      // TODO: حذف الصور من Storage
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting service: $e');
      return false;
    }
  }

  // البحث في الخدمات
  Future<List<ServiceModel>> searchServices(String query, {String? merchantId, String? category}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore.collection('services');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      if (category != null && category.isNotEmpty) {
        queryRef = queryRef.where('category', isEqualTo: category);
      }

      final querySnapshot = await queryRef.get();

      List<ServiceModel> services = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data);
      }).toList();

      // فلترة النتائج بناء على النص
      if (query.isNotEmpty) {
        services = services.where((service) =>
            service.name.toLowerCase().contains(query.toLowerCase()) ||
            service.description.toLowerCase().contains(query.toLowerCase()) ||
            service.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
        ).toList();
      }

      return services;
    } catch (e) {
      debugPrint('Error searching services: $e');
      return [];
    }
  }

  // الحصول على الخدمات المميزة
  Future<List<ServiceModel>> getFeaturedServices({String? merchantId}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore
          .collection('services')
          .where('isFeature', isEqualTo: true)
          .where('status', isEqualTo: 'active');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      final querySnapshot = await queryRef.limit(10).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting featured services: $e');
      return [];
    }
  }

  // الحصول على خدمات بفئة معينة
  Future<List<ServiceModel>> getServicesByCategory(String category, {String? merchantId}) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore
          .collection('services')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active');

      if (merchantId != null) {
        queryRef = queryRef.where('merchantId', isEqualTo: merchantId);
      }

      final querySnapshot = await queryRef.orderBy('updatedAt', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ServiceModel.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting services by category: $e');
      return [];
    }
  }

  // تغيير حالة الخدمة
  Future<bool> updateServiceStatus(String serviceId, ServiceStatus status) async {
    try {
      await _firestore.collection('services').doc(serviceId).update({
        'status': status.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating service status: $e');
      return false;
    }
  }

  // Stream للخدمات في الوقت الفعلي
  Stream<List<ServiceModel>> streamMerchantServices(String merchantId) {
    return _firestore
        .collection('services')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ServiceModel.fromJson(data);
            }).toList());
  }

  // رفع صورة الخدمة
  Future<String?> _uploadServiceImage(File image, String userId, String imageName) async {
    try {
      final ref = _storage.ref().child('services/$userId/$imageName.jpg');
      final uploadTask = await ref.putFile(image);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading service image: $e');
      return null;
    }
  }

  // حذف صورة الخدمة
  Future<bool> deleteServiceImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting service image: $e');
      return false;
    }
  }
}
