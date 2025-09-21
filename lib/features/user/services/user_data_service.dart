import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../merchant/models/merchant_model.dart';

/// خدمة ربط بيانات المستخدم مع المتاجر والمنتجات
class UserDataService {
  static final UserDataService _instance = UserDataService._internal();
  static UserDataService get instance => _instance;
  UserDataService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// الحصول على جميع المتاجر المُوافق عليها
  Future<List<MerchantModel>> getApprovedMerchants() async {
    try {
      final snapshot = await _firestore
          .collection('merchant_requests')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MerchantModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('خطأ في جلب المتاجر: $e');
      return [];
    }
  }

  /// البحث في المتاجر
  Future<List<MerchantModel>> searchMerchants(String query) async {
    try {
      final snapshot = await _firestore
          .collection('merchant_requests')
          .where('status', isEqualTo: 'approved')
          .get();

      final merchants = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MerchantModel.fromJson(data);
      }).toList();

      // تصفية النتائج حسب الاستعلام
      return merchants.where((merchant) {
        return merchant.businessName.toLowerCase().contains(query.toLowerCase()) ||
               merchant.businessType.toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('خطأ في البحث: $e');
      return [];
    }
  }

  /// الحصول على منتجات تاجر معين
  Future<List<Map<String, dynamic>>> getMerchantProducts(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('merchantId', isEqualTo: merchantId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('خطأ في جلب المنتجات: $e');
      return [];
    }
  }

  /// الحصول على خدمات تاجر معين
  Future<List<Map<String, dynamic>>> getMerchantServices(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('merchantId', isEqualTo: merchantId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('خطأ في جلب الخدمات: $e');
      return [];
    }
  }

  /// الحصول على أقسام تاجر معين
  Future<List<Map<String, dynamic>>> getMerchantCategories(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('merchantId', isEqualTo: merchantId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('خطأ في جلب الأقسام: $e');
      return [];
    }
  }

  /// الحصول على جميع المنتجات (من جميع المتاجر)
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final products = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // إضافة معلومات التاجر
        final merchantInfo = await getMerchantInfo(data['merchantId']);
        if (merchantInfo != null) {
          data['merchantName'] = merchantInfo['businessName'];
          data['merchantImage'] = merchantInfo['profileImageUrl'];
          products.add(data);
        }
      }

      return products;
    } catch (e) {
      print('خطأ في جلب جميع المنتجات: $e');
      return [];
    }
  }

  /// الحصول على معلومات تاجر بـ ID
  Future<Map<String, dynamic>?> getMerchantInfo(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('merchant_requests')
          .where('id', isEqualTo: merchantId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('خطأ في جلب معلومات التاجر: $e');
      return null;
    }
  }

  /// إضافة منتج للسلة
  Future<bool> addToCart({
    required String productId,
    required String merchantId,
    int quantity = 1,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('cart').add({
        'userId': user.uid,
        'productId': productId,
        'merchantId': merchantId,
        'quantity': quantity,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('خطأ في إضافة المنتج للسلة: $e');
      return false;
    }
  }

  /// الحصول على عناصر السلة
  Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('cart')
          .where('userId', isEqualTo: user.uid)
          .get();

      final cartItems = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // جلب تفاصيل المنتج
        final productDoc = await _firestore
            .collection('products')
            .doc(data['productId'])
            .get();

        if (productDoc.exists) {
          data['product'] = productDoc.data();
          
          // جلب معلومات التاجر
          final merchantInfo = await getMerchantInfo(data['merchantId']);
          if (merchantInfo != null) {
            data['merchant'] = merchantInfo;
          }
          
          cartItems.add(data);
        }
      }

      return cartItems;
    } catch (e) {
      print('خطأ في جلب عناصر السلة: $e');
      return [];
    }
  }

  /// إنشاء طلب جديد
  Future<bool> createOrder({
    required List<String> cartItemIds,
    required double totalAmount,
    required String deliveryAddress,
    String? phone,
    String? notes,
    String paymentMethod = 'cash',
    String deliveryType = 'delivery',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // جلب بيانات المستخدم
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // جلب عناصر السلة
      final cartItems = await getCartItems();
      final orderItems = cartItems
          .where((item) => cartItemIds.contains(item['id']))
          .toList();

      if (orderItems.isEmpty) return false;

      // تجميع الطلبات حسب التاجر
      final Map<String, List<Map<String, dynamic>>> ordersByMerchant = {};
      
      for (final item in orderItems) {
        final merchantId = item['merchantId'] as String;
        if (!ordersByMerchant.containsKey(merchantId)) {
          ordersByMerchant[merchantId] = [];
        }
        ordersByMerchant[merchantId]!.add(item);
      }

      // إنشاء طلب منفصل لكل تاجر
      for (final merchantId in ordersByMerchant.keys) {
        final merchantItems = ordersByMerchant[merchantId]!;
        final merchantSubtotal = merchantItems.fold<double>(
          0.0,
          (sum, item) => sum + ((item['product']['price'] as num).toDouble() * (item['quantity'] as int)),
        );

        final orderData = {
          // معرف التاجر
          'merchantId': merchantId,
          
          // معلومات العميل
          'customer': {
            'userId': user.uid,
            'name': userData['name'] ?? user.displayName ?? 'مستخدم',
            'email': userData['email'] ?? user.email ?? '',
            'phone': phone ?? userData['phone'] ?? '',
            'profileImage': userData['profileImage'],
          },
          
          // عناصر الطلب
          'items': merchantItems.map((item) => {
            'productId': item['productId'],
            'productName': item['product']['name'],
            'productImage': (item['product']['imageUrls'] as List?)?.isNotEmpty == true 
                ? item['product']['imageUrls'][0] 
                : '',
            'productPrice': (item['product']['price'] as num).toDouble(),
            'quantity': item['quantity'],
            'selectedColor': item['selectedColor'],
            'selectedSize': item['selectedSize'],
            'customization': item['customization'],
          }).toList(),
          
          // المبالغ
          'subtotal': merchantSubtotal,
          'tax': merchantSubtotal * 0.15, // ضريبة القيمة المضافة 15%
          'deliveryFee': deliveryType == 'delivery' ? 15.0 : 0.0,
          'discount': 0.0,
          'totalAmount': merchantSubtotal + (merchantSubtotal * 0.15) + (deliveryType == 'delivery' ? 15.0 : 0.0),
          
          // حالة الطلب والدفع
          'status': 'pending',
          'paymentStatus': 'pending',
          'paymentMethod': paymentMethod,
          
          // معلومات التوصيل
          'deliveryInfo': {
            'type': deliveryType,
            'address': deliveryAddress,
            'phone': phone ?? userData['phone'] ?? '',
            'notes': notes,
            'deliveryFee': deliveryType == 'delivery' ? 15.0 : 0.0,
          },
          
          // ملاحظات
          'notes': notes,
          
          // الطوابع الزمنية
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // إضافة الطلب إلى قاعدة البيانات
        await _firestore.collection('orders').add(orderData);
      }

      // حذف العناصر من السلة
      for (final itemId in cartItemIds) {
        await _firestore.collection('cart').doc(itemId).delete();
      }

      return true;
    } catch (e) {
      print('خطأ في إنشاء الطلب: $e');
      return false;
    }
  }

  /// الحصول على طلبات المستخدم
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  /// إضافة تقييم لمنتج
  Future<bool> addReview({
    required String productId,
    required String merchantId,
    required int rating,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('reviews').add({
        'userId': user.uid,
        'productId': productId,
        'merchantId': merchantId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('خطأ في إضافة التقييم: $e');
      return false;
    }
  }

  /// الحصول على تقييمات منتج
  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('خطأ في جلب التقييمات: $e');
      return [];
    }
  }

  /// إضافة تاجر للمفضلة
  Future<bool> addMerchantToFavorites(String merchantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore.collection('favorites').add({
        'userId': user.uid,
        'merchantId': merchantId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('خطأ في إضافة التاجر للمفضلة: $e');
      return false;
    }
  }

  /// إزالة تاجر من المفضلة
  Future<bool> removeMerchantFromFavorites(String merchantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('merchantId', isEqualTo: merchantId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('خطأ في إزالة التاجر من المفضلة: $e');
      return false;
    }
  }

  /// الحصول على المتاجر المفضلة
  Future<List<MerchantModel>> getFavoriteMerchants() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final favSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .get();

      final merchantIds = favSnapshot.docs
          .map((doc) => doc.data()['merchantId'] as String)
          .toList();

      if (merchantIds.isEmpty) return [];

      final merchants = <MerchantModel>[];
      for (final merchantId in merchantIds) {
        final merchantInfo = await getMerchantInfo(merchantId);
        if (merchantInfo != null) {
          merchantInfo['id'] = merchantId;
          merchants.add(MerchantModel.fromJson(merchantInfo));
        }
      }

      return merchants;
    } catch (e) {
      print('خطأ في جلب المتاجر المفضلة: $e');
      return [];
    }
  }

  /// فحص إذا كان التاجر في المفضلة
  Future<bool> isMerchantFavorite(String merchantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: user.uid)
          .where('merchantId', isEqualTo: merchantId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('خطأ في فحص المفضلة: $e');
      return false;
    }
  }
}
