import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/merchant_dashboard_data.dart';
import '../models/merchant_model.dart';
import 'merchant_service.dart';

class MerchantDashboardService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static MerchantDashboardService? _instance;
  
  static MerchantDashboardService get instance {
    _instance ??= MerchantDashboardService._internal();
    return _instance!;
  }

  MerchantDashboardService._internal();

  // الحصول على بيانات المتجر الأساسية
  Future<Map<String, dynamic>?> getMerchantBasicInfo(String merchantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('المستخدم غير مسجل الدخول');
        return null;
      }

      // البحث في التجار المعتمدين أولاً بـ userId
      final approvedMerchantQuery = await _firestore
          .collection('approved_merchants')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (approvedMerchantQuery.docs.isNotEmpty) {
        final merchantData = approvedMerchantQuery.docs.first.data();
        // إضافة معلومات إضافية
        merchantData['merchantId'] = approvedMerchantQuery.docs.first.id;
        merchantData['isVerified'] = merchantData['status'] == 'approved';
        return merchantData;
      }

      // إذا لم يوجد في المعتمدين، البحث في طلبات التجار
      final merchantRequestQuery = await _firestore
          .collection('merchant_requests')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (merchantRequestQuery.docs.isNotEmpty) {
        final merchantData = merchantRequestQuery.docs.first.data();
        // إضافة معلومات إضافية
        merchantData['merchantId'] = merchantRequestQuery.docs.first.id;
        merchantData['isVerified'] = merchantData['status'] == 'approved';
        merchantData['rating'] = 0.0; // التجار الجدد لا يوجد لديهم تقييم
        merchantData['totalOrders'] = 0; // التجار الجدد لا يوجد لديهم طلبات
        return merchantData;
      }

      // إذا لم يوجد أي بيانات تاجر
      debugPrint('لا توجد بيانات تاجر للمستخدم الحالي');
      return null;
    } catch (e) {
      debugPrint('Error getting merchant basic info: $e');
      return null;
    }
  }

  // الحصول على إيرادات المبيعات
  Future<SalesRevenue> getSalesRevenue(String merchantId) async {
    try {
      // الحصول على إيرادات الشهر الحالي
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final previousMonthStart = DateTime(now.year, now.month - 1, 1);
      final previousMonthEnd = DateTime(now.year, now.month, 0);

      // إيرادات الشهر الحالي
      final currentRevenueQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(currentMonthStart))
          .get();

      // إيرادات الشهر السابق
      final previousRevenueQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(previousMonthStart))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(previousMonthEnd))
          .get();

      double currentRevenue = 0.0;
      double previousRevenue = 0.0;

      for (var doc in currentRevenueQuery.docs) {
        currentRevenue += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }

      for (var doc in previousRevenueQuery.docs) {
        previousRevenue += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }

      // حساب النسبة المئوية للتغيير
      double percentage = 0.0;
      bool isIncreasing = false;
      
      if (previousRevenue > 0) {
        percentage = ((currentRevenue - previousRevenue) / previousRevenue) * 100;
        isIncreasing = percentage > 0;
      } else if (currentRevenue > 0) {
        percentage = 100.0;
        isIncreasing = true;
      }

      // بيانات الرسم البياني للأسبوع الماضي
      final chartData = await _getWeeklyRevenueData(merchantId);

      return SalesRevenue(
        currentRevenue: currentRevenue,
        previousRevenue: previousRevenue,
        percentage: percentage.abs(),
        isIncreasing: isIncreasing,
        chartData: chartData,
      );
    } catch (e) {
      debugPrint('Error getting sales revenue: $e');
      return SalesRevenue(
        currentRevenue: 750.0, // بيانات تجريبية
        previousRevenue: 658.0,
        percentage: 14.0,
        isIncreasing: true,
        chartData: [],
      );
    }
  }

  // الحصول على بيانات الرسم البياني الأسبوعية
  Future<List<RevenueDataPoint>> _getWeeklyRevenueData(String merchantId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: 7));
      
      final query = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .orderBy('createdAt')
          .get();

      final Map<String, double> dailyRevenue = {};
      
      for (var doc in query.docs) {
        final orderDate = (doc.data()['createdAt'] as Timestamp).toDate();
        final dateKey = '${orderDate.year}-${orderDate.month}-${orderDate.day}';
        final amount = (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
        
        dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + amount;
      }

      final List<RevenueDataPoint> chartData = [];
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        final value = dailyRevenue[dateKey] ?? 0.0;
        
        chartData.add(RevenueDataPoint(date: date, value: value));
      }

      return chartData;
    } catch (e) {
      debugPrint('Error getting weekly revenue data: $e');
      return [];
    }
  }

  // الحصول على الإعلانات المدفوعة
  Stream<List<PaidAdvertisement>> getPaidAdvertisements(String merchantId) {
    return _firestore
        .collection('paid_advertisements')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PaidAdvertisement.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // الحصول على تعليقات العملاء
  Stream<List<CustomerReview>> getCustomerReviews(String merchantId) {
    return _firestore
        .collection('reviews')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CustomerReview.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // الحصول على الإشعارات
  Stream<List<MerchantNotification>> getNotifications(String merchantId) {
    return _firestore
        .collection('merchant_notifications')
        .where('merchantId', isEqualTo: merchantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MerchantNotification.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  // عدد الإشعارات غير المقروءة
  Stream<int> getUnreadNotificationsCount(String merchantId) {
    return _firestore
        .collection('merchant_notifications')
        .where('merchantId', isEqualTo: merchantId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // عدد الرسائل غير المقروءة
  Stream<int> getUnreadMessagesCount(String merchantId) {
    return _firestore
        .collection('merchant_messages')
        .where('merchantId', isEqualTo: merchantId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // الحصول على إحصائيات لوحة التاجر
  Future<MerchantDashboardStats> getDashboardStats(String merchantId) async {
    try {
      // عدد المنتجات
      final productsQuery = await _firestore
          .collection('products')
          .where('merchantId', isEqualTo: merchantId)
          .where('isActive', isEqualTo: true)
          .get();

      // إجمالي الطلبات
      final ordersQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .get();

      // الطلبات المعلقة
      final pendingOrdersQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'pending')
          .get();

      // الطلبات المكتملة
      final completedOrdersQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'completed')
          .get();

      // إجمالي الإيرادات
      double totalRevenue = 0.0;
      for (var doc in completedOrdersQuery.docs) {
        totalRevenue += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }

      // إيرادات الشهر الحالي
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      
      final monthlyOrdersQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'completed')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(currentMonthStart))
          .get();

      double monthlyRevenue = 0.0;
      for (var doc in monthlyOrdersQuery.docs) {
        monthlyRevenue += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
      }

      // التقييمات
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('merchantId', isEqualTo: merchantId)
          .get();

      double totalRating = 0.0;
      int totalReviews = reviewsQuery.docs.length;
      
      for (var doc in reviewsQuery.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
      }

      double averageRating = totalReviews > 0 ? totalRating / totalReviews : 0.0;

      // الإشعارات غير المقروءة
      final unreadNotificationsQuery = await _firestore
          .collection('merchant_notifications')
          .where('merchantId', isEqualTo: merchantId)
          .where('isRead', isEqualTo: false)
          .get();

      // الرسائل غير المقروءة
      final unreadMessagesQuery = await _firestore
          .collection('merchant_messages')
          .where('merchantId', isEqualTo: merchantId)
          .where('isRead', isEqualTo: false)
          .get();

      return MerchantDashboardStats(
        totalProducts: productsQuery.docs.length,
        totalOrders: ordersQuery.docs.length,
        pendingOrders: pendingOrdersQuery.docs.length,
        completedOrders: completedOrdersQuery.docs.length,
        totalRevenue: totalRevenue,
        monthlyRevenue: monthlyRevenue,
        unreadNotifications: unreadNotificationsQuery.docs.length,
        unreadMessages: unreadMessagesQuery.docs.length,
        averageRating: averageRating,
        totalReviews: totalReviews,
      );
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      // إرجاع بيانات افتراضية في حالة الخطأ
      return MerchantDashboardStats(
        totalProducts: 15,
        totalOrders: 120,
        pendingOrders: 8,
        completedOrders: 112,
        totalRevenue: 15420.0,
        monthlyRevenue: 750.0,
        unreadNotifications: 99,
        unreadMessages: 5,
        averageRating: 4.5,
        totalReviews: 85,
      );
    }
  }

  // تحديث حالة الإشعار إلى مقروء
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('merchant_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // تحديث حالة الرسالة إلى مقروءة
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore
          .collection('merchant_messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  // الحصول على اسم المتجر من معرف التاجر
  Future<String> getMerchantStoreName(String merchantId) async {
    try {
      final doc = await _firestore
          .collection('approved_merchants')
          .doc(merchantId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['businessName'] as String? ?? 'متجر';
      }
      return 'متجر';
    } catch (e) {
      debugPrint('Error getting merchant store name: $e');
      return 'متجر';
    }
  }

  // الحصول على معرف المتجر (كود المتجر)
  String generateStoreCode(String merchantId) {
    if (merchantId.isEmpty) {
      return 'NEW001';
    }
    try {
      // إنشاء كود المتجر من معرف التاجر
      final merchantHash = merchantId.hashCode.abs();
      final codeNumber = merchantHash % 999999;
      return codeNumber.toString().padLeft(6, '0');
    } catch (e) {
      // في حالة وجود خطأ، إرجاع كود افتراضي
      return 'STR001';
    }
  }
}
