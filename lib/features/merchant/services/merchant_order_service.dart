import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';

class MerchantOrderService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static MerchantOrderService? _instance;
  
  static MerchantOrderService get instance {
    _instance ??= MerchantOrderService._internal();
    return _instance!;
  }

  MerchantOrderService._internal();

  // الحصول على معرف التاجر الحالي
  Future<String?> _getCurrentMerchantId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // البحث في التجار المعتمدين
      final merchantQuery = await _firestore
          .collection('approved_merchants')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (merchantQuery.docs.isNotEmpty) {
        return merchantQuery.docs.first.id;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting current merchant ID: $e');
      return null;
    }
  }

  // الحصول على جميع الطلبات للتاجر
  Stream<List<OrderModel>> getAllOrders() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield [];
        return;
      }

      final merchantId = await _getCurrentMerchantId();
      if (merchantId == null) {
        yield [];
        return;
      }

      yield* _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return OrderModel.fromJson(doc.data(), doc.id);
        }).toList();
      });
    });
  }

  // الحصول على الطلبات حسب الحالة
  Stream<List<OrderModel>> getOrdersByStatus(OrderStatus status) {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield [];
        return;
      }

      final merchantId = await _getCurrentMerchantId();
      if (merchantId == null) {
        yield [];
        return;
      }

      yield* _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return OrderModel.fromJson(doc.data(), doc.id);
        }).toList();
      });
    });
  }

  // الحصول على طلب محدد
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      
      if (doc.exists) {
        return OrderModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }

  // تحديث حالة الطلب
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // إضافة طوابع زمنية حسب الحالة
      switch (newStatus) {
        case OrderStatus.confirmed:
          updateData['confirmedAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.delivered:
          updateData['deliveredAt'] = FieldValue.serverTimestamp();
          break;
        case OrderStatus.cancelled:
          updateData['cancelledAt'] = FieldValue.serverTimestamp();
          break;
        default:
          break;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);

      // إرسال إشعار للعميل
      await _sendOrderStatusNotification(orderId, newStatus);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  // إلغاء الطلب
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'cancelReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // إرسال إشعار للعميل
      await _sendOrderCancellationNotification(orderId, reason);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  // الحصول على إحصائيات الطلبات
  Future<Map<String, int>> getOrdersStatistics() async {
    try {
      final merchantId = await _getCurrentMerchantId();
      if (merchantId == null) {
        return {
          'total': 0,
          'pending': 0,
          'confirmed': 0,
          'preparing': 0,
          'ready': 0,
          'shipped': 0,
          'delivered': 0,
          'cancelled': 0,
        };
      }

      final ordersQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .get();

      final stats = <String, int>{
        'total': ordersQuery.docs.length,
        'pending': 0,
        'confirmed': 0,
        'preparing': 0,
        'ready': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0,
      };

      for (final doc in ordersQuery.docs) {
        final status = doc.data()['status'] as String? ?? 'pending';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting orders statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'preparing': 0,
        'ready': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0,
      };
    }
  }

  // الحصول على الطلبات الجديدة (آخر 24 ساعة)
  Stream<List<OrderModel>> getNewOrders() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield [];
        return;
      }

      final merchantId = await _getCurrentMerchantId();
      if (merchantId == null) {
        yield [];
        return;
      }

      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      yield* _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return OrderModel.fromJson(doc.data(), doc.id);
        }).toList();
      });
    });
  }

  // البحث في الطلبات
  Future<List<OrderModel>> searchOrders(String query) async {
    try {
      final merchantId = await _getCurrentMerchantId();
      if (merchantId == null) return [];

      // البحث في رقم الطلب أو اسم العميل
      final ordersQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .get();

      final filteredOrders = <OrderModel>[];
      
      for (final doc in ordersQuery.docs) {
        final order = OrderModel.fromJson(doc.data(), doc.id);
        
        // البحث في رقم الطلب أو اسم العميل أو اسم المنتج
        if (order.orderNumber.toLowerCase().contains(query.toLowerCase()) ||
            order.customer.name.toLowerCase().contains(query.toLowerCase()) ||
            order.items.any((item) => 
                item.productName.toLowerCase().contains(query.toLowerCase()))) {
          filteredOrders.add(order);
        }
      }

      return filteredOrders;
    } catch (e) {
      debugPrint('Error searching orders: $e');
      return [];
    }
  }

  // إرسال إشعار تغيير حالة الطلب للعميل
  Future<void> _sendOrderStatusNotification(String orderId, OrderStatus status) async {
    try {
      final order = await getOrder(orderId);
      if (order == null) return;

      String title = 'تحديث حالة الطلب';
      String body = 'تم تحديث حالة طلبك ${order.orderNumber} إلى: ${order.statusDisplayText}';

      await _firestore.collection('notifications').add({
        'userId': order.customer.userId,
        'title': title,
        'body': body,
        'type': 'order_status',
        'orderId': orderId,
        'status': status.toString().split('.').last,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending order status notification: $e');
    }
  }

  // إرسال إشعار إلغاء الطلب للعميل
  Future<void> _sendOrderCancellationNotification(String orderId, String reason) async {
    try {
      final order = await getOrder(orderId);
      if (order == null) return;

      String title = 'تم إلغاء الطلب';
      String body = 'تم إلغاء طلبك ${order.orderNumber}. السبب: $reason';

      await _firestore.collection('notifications').add({
        'userId': order.customer.userId,
        'title': title,
        'body': body,
        'type': 'order_cancelled',
        'orderId': orderId,
        'cancelReason': reason,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending order cancellation notification: $e');
    }
  }

  // تحديث معلومات التوصيل
  Future<bool> updateDeliveryInfo(String orderId, DeliveryInfo deliveryInfo) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'deliveryInfo': deliveryInfo.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating delivery info: $e');
      return false;
    }
  }

  // الحصول على الطلبات المتأخرة
  Future<List<OrderModel>> getOverdueOrders() async {
    try {
      final merchantId = await _getCurrentMerchantId();
      if (merchantId == null) return [];

      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));

      final ordersQuery = await _firestore
          .collection('orders')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('createdAt', isLessThan: Timestamp.fromDate(twoDaysAgo))
          .get();

      return ordersQuery.docs.map((doc) {
        return OrderModel.fromJson(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting overdue orders: $e');
      return [];
    }
  }
}
