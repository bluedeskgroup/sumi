import 'package:cloud_firestore/cloud_firestore.dart';

// نموذج إيرادات المبيعات
class SalesRevenue {
  final double currentRevenue;
  final double previousRevenue;
  final double percentage;
  final bool isIncreasing;
  final List<RevenueDataPoint> chartData;
  
  SalesRevenue({
    required this.currentRevenue,
    required this.previousRevenue,
    required this.percentage,
    required this.isIncreasing,
    required this.chartData,
  });
  
  factory SalesRevenue.fromJson(Map<String, dynamic> json) {
    return SalesRevenue(
      currentRevenue: (json['currentRevenue'] as num?)?.toDouble() ?? 0.0,
      previousRevenue: (json['previousRevenue'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      isIncreasing: json['isIncreasing'] as bool? ?? false,
      chartData: (json['chartData'] as List<dynamic>?)
          ?.map((item) => RevenueDataPoint.fromJson(item))
          .toList() ?? [],
    );
  }
}

class RevenueDataPoint {
  final DateTime date;
  final double value;
  
  RevenueDataPoint({
    required this.date,
    required this.value,
  });
  
  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDataPoint(
      date: (json['date'] as Timestamp).toDate(),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// نموذج الإعلانات المدفوعة
class PaidAdvertisement {
  final String id;
  final String productTitle;
  final String productImageUrl;
  final int views;
  final AdStatus status;
  final Timestamp createdAt;
  final Timestamp? expiresAt;
  
  PaidAdvertisement({
    required this.id,
    required this.productTitle,
    required this.productImageUrl,
    required this.views,
    required this.status,
    required this.createdAt,
    this.expiresAt,
  });
  
  factory PaidAdvertisement.fromJson(Map<String, dynamic> json, String docId) {
    return PaidAdvertisement(
      id: docId,
      productTitle: json['productTitle'] as String? ?? '',
      productImageUrl: json['productImageUrl'] as String? ?? '',
      views: json['views'] as int? ?? 0,
      status: AdStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] as String? ?? 'active'),
        orElse: () => AdStatus.active,
      ),
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
      expiresAt: json['expiresAt'] as Timestamp?,
    );
  }
}

enum AdStatus {
  active,    // فعال
  expired,   // انتهى
  paused,    // متوقف
}

// نموذج تعليقات العملاء
class CustomerReview {
  final String id;
  final String customerId;
  final String customerName;
  final String customerImageUrl;
  final String productId;
  final String productTitle;
  final String productVariant;
  final String productImageUrl;
  final int rating;
  final String reviewText;
  final Timestamp createdAt;
  
  CustomerReview({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerImageUrl,
    required this.productId,
    required this.productTitle,
    required this.productVariant,
    required this.productImageUrl,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });
  
  factory CustomerReview.fromJson(Map<String, dynamic> json, String docId) {
    return CustomerReview(
      id: docId,
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerImageUrl: json['customerImageUrl'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productTitle: json['productTitle'] as String? ?? '',
      productVariant: json['productVariant'] as String? ?? '',
      productImageUrl: json['productImageUrl'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      reviewText: json['reviewText'] as String? ?? '',
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

// نموذج الإشعارات
class MerchantNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final Timestamp createdAt;
  
  MerchantNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });
  
  factory MerchantNotification.fromJson(Map<String, dynamic> json, String docId) {
    return MerchantNotification(
      id: docId,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] as String? ?? 'general'),
        orElse: () => NotificationType.general,
      ),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

enum NotificationType {
  order,       // طلب جديد
  review,      // تقييم جديد
  message,     // رسالة جديدة
  general,     // عام
  system,      // نظام
}

// إحصائيات لوحة التاجر
class MerchantDashboardStats {
  final int totalProducts;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;
  final double monthlyRevenue;
  final int unreadNotifications;
  final int unreadMessages;
  final double averageRating;
  final int totalReviews;
  
  MerchantDashboardStats({
    required this.totalProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.unreadNotifications,
    required this.unreadMessages,
    required this.averageRating,
    required this.totalReviews,
  });
  
  factory MerchantDashboardStats.fromJson(Map<String, dynamic> json) {
    return MerchantDashboardStats(
      totalProducts: json['totalProducts'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      unreadNotifications: json['unreadNotifications'] as int? ?? 0,
      unreadMessages: json['unreadMessages'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
    );
  }
}
