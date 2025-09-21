import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductType { product, service }
enum ProductStatus { active, inactive, outOfStock }

class ProductModel {
  final String id;
  final String merchantId;
  final String name;
  final String description;
  final List<String> images;
  final double originalPrice;
  final double discountedPrice;
  final double? discount;
  final String color;
  final String size;
  final int quantity;
  final int soldCount;
  final double salesRate;
  final ProductType type;
  final ProductStatus status;
  final String category;
  final List<String> tags;
  final String country; // الدولة المستهدفة للمنتج/الخدمة
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  ProductModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.description,
    this.images = const [],
    required this.originalPrice,
    required this.discountedPrice,
    this.discount,
    required this.color,
    required this.size,
    this.quantity = 0,
    this.soldCount = 0,
    this.salesRate = 0.0,
    this.type = ProductType.product,
    this.status = ProductStatus.active,
    this.category = '',
    this.tags = const [],
    this.country = 'السعودية', // القيمة الافتراضية
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Getters for formatted values
  String get formattedOriginalPrice => '${originalPrice.toStringAsFixed(0)} ريال';
  String get formattedDiscountedPrice => '${discountedPrice.toStringAsFixed(0)} ريال';
  String get formattedSalesRate => '${salesRate.toStringAsFixed(1)}%';
  String get formattedQuantity => 'الكمية : $quantity';
  String get formattedColor => 'اللون : $color';
  String get formattedSize => 'الحجم : $size';
  
  bool get hasDiscount => discount != null && discount! > 0;
  double get discountPercentage => discount ?? 0.0;
  
  String get typeText => type == ProductType.product ? 'منتج' : 'خدمة';
  String get statusText {
    switch (status) {
      case ProductStatus.active:
        return 'متاح';
      case ProductStatus.inactive:
        return 'غير متاح';
      case ProductStatus.outOfStock:
        return 'نفد المخزون';
    }
  }

  // Factory constructor from Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ProductModel.fromMap(data);
  }

  // Factory constructor from Map
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      merchantId: map['merchantId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      discountedPrice: (map['discountedPrice'] ?? 0.0).toDouble(),
      discount: map['discount']?.toDouble(),
      color: map['color'] ?? '',
      size: map['size'] ?? '',
      quantity: map['quantity'] ?? 0,
      soldCount: map['soldCount'] ?? 0,
      salesRate: (map['salesRate'] ?? 0.0).toDouble(),
      type: ProductType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ProductType.product,
      ),
      status: ProductStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ProductStatus.active,
      ),
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      country: map['country'] ?? 'السعودية',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'description': description,
      'images': images,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discount': discount,
      'color': color,
      'size': size,
      'quantity': quantity,
      'soldCount': soldCount,
      'salesRate': salesRate,
      'type': type.name,
      'status': status.name,
      'category': category,
      'tags': tags,
      'country': country,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  // Copy with method
  ProductModel copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? description,
    List<String>? images,
    double? originalPrice,
    double? discountedPrice,
    double? discount,
    String? color,
    String? size,
    int? quantity,
    int? soldCount,
    double? salesRate,
    ProductType? type,
    ProductStatus? status,
    String? category,
    List<String>? tags,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProductModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      discount: discount ?? this.discount,
      color: color ?? this.color,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      soldCount: soldCount ?? this.soldCount,
      salesRate: salesRate ?? this.salesRate,
      type: type ?? this.type,
      status: status ?? this.status,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, originalPrice: $originalPrice, discountedPrice: $discountedPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Sample data for testing
class ProductSampleData {
  static List<ProductModel> getSampleProducts(String merchantId) {
    return [
      ProductModel(
        id: 'prod_1',
        merchantId: merchantId,
        name: 'نظارات قراءة كيركسن 5 أزواج، نظارات عصرية للسيدات، مفصل زنبركي مع طباعة بنمط',
        description: 'نظارات عالية الجودة مناسبة للقراءة اليومية',
        images: ['assets/images/products/glasses1.png'],
        originalPrice: 490.0,
        discountedPrice: 450.0,
        discount: 8.2,
        color: 'اخضر',
        size: '50 سم',
        quantity: 1,
        soldCount: 156,
        salesRate: 16.0,
        type: ProductType.product,
        status: ProductStatus.active,
        category: 'نظارات',
        tags: ['نظارات', 'قراءة', 'سيدات'],
      ),
      ProductModel(
        id: 'prod_2',
        merchantId: merchantId,
        name: 'نظارات قراءة كيركسن 5 أزواج، نظارات عصرية للسيدات، مفصل زنبركي مع طباعة بنمط',
        description: 'نظارات عالية الجودة مناسبة للقراءة اليومية',
        images: ['assets/images/products/glasses2-6a9524.png'],
        originalPrice: 490.0,
        discountedPrice: 450.0,
        discount: 8.2,
        color: 'اخضر',
        size: '50 سم',
        quantity: 1,
        soldCount: 142,
        salesRate: 16.0,
        type: ProductType.product,
        status: ProductStatus.active,
        category: 'نظارات',
        tags: ['نظارات', 'قراءة', 'سيدات'],
      ),
      ProductModel(
        id: 'prod_3',
        merchantId: merchantId,
        name: 'نظارات قراءة كيركسن 5 أزواج، نظارات عصرية للسيدات، مفصل زنبركي مع طباعة بنمط',
        description: 'نظارات عالية الجودة مناسبة للقراءة اليومية',
        images: ['assets/images/products/glasses1.png'],
        originalPrice: 490.0,
        discountedPrice: 450.0,
        discount: 8.2,
        color: 'اخضر',
        size: '50 سنتي',
        quantity: 1,
        soldCount: 98,
        salesRate: 16.0,
        type: ProductType.product,
        status: ProductStatus.active,
        category: 'نظارات',
        tags: ['نظارات', 'قراءة', 'سيدات'],
      ),
    ];
  }

  static List<ProductModel> getSampleServices(String merchantId) {
    return [
      ProductModel(
        id: 'serv_1',
        merchantId: merchantId,
        name: 'خدمة فحص النظر الشامل',
        description: 'فحص شامل للعينين مع استشارة طبية',
        images: [],
        originalPrice: 200.0,
        discountedPrice: 150.0,
        discount: 25.0,
        color: '',
        size: '30 دقيقة',
        quantity: 0, // Services don't have quantity
        soldCount: 89,
        salesRate: 22.5,
        type: ProductType.service,
        status: ProductStatus.active,
        category: 'فحوصات',
        tags: ['فحص', 'عيون', 'طبي'],
      ),
      ProductModel(
        id: 'serv_2',
        merchantId: merchantId,
        name: 'تركيب عدسات لاصقة',
        description: 'خدمة تركيب وتعليم استخدام العدسات اللاصقة',
        images: [],
        originalPrice: 100.0,
        discountedPrice: 80.0,
        discount: 20.0,
        color: '',
        size: '15 دقيقة',
        quantity: 0,
        soldCount: 45,
        salesRate: 18.9,
        type: ProductType.service,
        status: ProductStatus.active,
        category: 'خدمات',
        tags: ['عدسات', 'تركيب', 'تدريب'],
      ),
    ];
  }
}