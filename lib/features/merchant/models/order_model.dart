import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,     // في انتظار الموافقة
  confirmed,   // مؤكد
  preparing,   // قيد التحضير
  ready,       // جاهز للتسليم
  shipped,     // تم الشحن
  delivered,   // تم التسليم
  cancelled,   // ملغي
  returned,    // مرتجع
}

enum PaymentStatus {
  pending,     // في انتظار الدفع
  paid,        // مدفوع
  failed,      // فشل في الدفع
  refunded,    // مسترد
}

enum DeliveryType {
  pickup,      // استلام من المحل
  delivery,    // توصيل
  shipping,    // شحن
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;
  final Map<String, dynamic>? customization;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
    this.customization,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      productPrice: (json['productPrice'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      selectedColor: json['selectedColor'],
      selectedSize: json['selectedSize'],
      customization: json['customization'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
      'customization': customization,
    };
  }

  double get totalPrice => productPrice * quantity;
}

class DeliveryInfo {
  final DeliveryType type;
  final String address;
  final String? city;
  final String? phone;
  final String? notes;
  final double? deliveryFee;
  final DateTime? expectedDeliveryTime;

  DeliveryInfo({
    required this.type,
    required this.address,
    this.city,
    this.phone,
    this.notes,
    this.deliveryFee,
    this.expectedDeliveryTime,
  });

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      type: DeliveryType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DeliveryType.pickup,
      ),
      address: json['address'] ?? '',
      city: json['city'],
      phone: json['phone'],
      notes: json['notes'],
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      expectedDeliveryTime: json['expectedDeliveryTime'] != null
          ? (json['expectedDeliveryTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'address': address,
      'city': city,
      'phone': phone,
      'notes': notes,
      'deliveryFee': deliveryFee,
      'expectedDeliveryTime': expectedDeliveryTime != null
          ? Timestamp.fromDate(expectedDeliveryTime!)
          : null,
    };
  }
}

class CustomerInfo {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;

  CustomerInfo({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
    };
  }
}

class OrderModel {
  final String id;
  final String merchantId;
  final CustomerInfo customer;
  final List<OrderItem> items;
  final double subtotal;
  final double? tax;
  final double? deliveryFee;
  final double? discount;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final String paymentMethod;
  final DeliveryInfo deliveryInfo;
  final String? notes;
  final String? cancelReason;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final Map<String, dynamic>? metadata;

  OrderModel({
    required this.id,
    required this.merchantId,
    required this.customer,
    required this.items,
    required this.subtotal,
    this.tax,
    this.deliveryFee,
    this.discount,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.deliveryInfo,
    this.notes,
    this.cancelReason,
    required this.createdAt,
    this.confirmedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.metadata,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, String id) {
    return OrderModel(
      id: id,
      merchantId: json['merchantId'] ?? '',
      customer: CustomerInfo.fromJson(json['customer'] ?? {}),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: json['paymentMethod'] ?? '',
      deliveryInfo: DeliveryInfo.fromJson(json['deliveryInfo'] ?? {}),
      notes: json['notes'],
      cancelReason: json['cancelReason'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (json['confirmedAt'] as Timestamp?)?.toDate(),
      deliveredAt: (json['deliveredAt'] as Timestamp?)?.toDate(),
      cancelledAt: (json['cancelledAt'] as Timestamp?)?.toDate(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'customer': customer.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'deliveryInfo': deliveryInfo.toJson(),
      'notes': notes,
      'cancelReason': cancelReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'metadata': metadata,
    };
  }

  // Helper methods
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isPreparing => status == OrderStatus.preparing;
  bool get isReady => status == OrderStatus.ready;
  bool get isShipped => status == OrderStatus.shipped;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get isReturned => status == OrderStatus.returned;
  
  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get isPaymentPending => paymentStatus == PaymentStatus.pending;
  
  String get orderNumber => '#${id.substring(0, 8).toUpperCase()}';
  
  String get statusDisplayText {
    switch (status) {
      case OrderStatus.pending:
        return 'في انتظار الموافقة';
      case OrderStatus.confirmed:
        return 'مؤكد';
      case OrderStatus.preparing:
        return 'قيد التحضير';
      case OrderStatus.ready:
        return 'جاهز للتسليم';
      case OrderStatus.shipped:
        return 'تم الشحن';
      case OrderStatus.delivered:
        return 'تم التسليم';
      case OrderStatus.cancelled:
        return 'ملغي';
      case OrderStatus.returned:
        return 'مرتجع';
    }
  }
  
  String get paymentStatusDisplayText {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'في انتظار الدفع';
      case PaymentStatus.paid:
        return 'مدفوع';
      case PaymentStatus.failed:
        return 'فشل في الدفع';
      case PaymentStatus.refunded:
        return 'مسترد';
    }
  }
}
