import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج لاختيارات المنتج (Product Variants)
class ProductVariantModel {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final int quantity;
  final String color;
  final String colorHex; // كود اللون الهيكس
  final String size;
  final double price;
  final bool isAvailable;
  final String brand;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductVariantModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.color,
    required this.colorHex,
    required this.size,
    required this.price,
    required this.isAvailable,
    required this.brand,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor from Firestore document
  factory ProductVariantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ProductVariantModel.fromMap(data);
  }

  /// Factory constructor from Map
  factory ProductVariantModel.fromMap(Map<String, dynamic> map) {
    return ProductVariantModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      quantity: map['quantity'] ?? 0,
      color: map['color'] ?? '',
      colorHex: map['colorHex'] ?? '#000000',
      size: map['size'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      brand: map['brand'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'color': color,
      'colorHex': colorHex,
      'size': size,
      'price': price,
      'isAvailable': isAvailable,
      'brand': brand,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with modifications
  ProductVariantModel copyWith({
    String? id,
    String? productId,
    String? name,
    String? imageUrl,
    int? quantity,
    String? color,
    String? colorHex,
    String? size,
    double? price,
    bool? isAvailable,
    String? brand,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariantModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      color: color ?? this.color,
      colorHex: colorHex ?? this.colorHex,
      size: size ?? this.size,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
      brand: brand ?? this.brand,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Format price as string
  String get formattedPrice => '${price.toStringAsFixed(0)} ر.س';

  /// Check if variant is in stock
  bool get isInStock => quantity > 0 && isAvailable;

  /// Get stock status text
  String get stockStatus {
    if (!isAvailable) return 'غير متاح';
    if (quantity == 0) return 'نفد المخزون';
    if (quantity <= 5) return 'كمية قليلة ($quantity)';
    return 'متوفر ($quantity)';
  }

  @override
  String toString() {
    return 'ProductVariantModel{id: $id, name: $name, color: $color, size: $size, quantity: $quantity}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariantModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// ألوان شائعة مع أكواد هيكس
class ProductColors {
  static const Map<String, String> colors = {
    'أحمر': '#E53E3E',
    'أزرق': '#3182CE',
    'أخضر': '#38A169',
    'أصفر': '#D69E2E',
    'أسود': '#1A202C',
    'أبيض': '#FFFFFF',
    'رمادي': '#4A5568',
    'بني': '#8B4513',
    'وردي': '#ED64A6',
    'بنفسجي': '#9F7AEA',
    'برتقالي': '#DD6B20',
    'تركواز': '#319795',
  };

  static String getColorHex(String colorName) {
    return colors[colorName] ?? '#000000';
  }

  static List<String> get colorNames => colors.keys.toList();
}

/// أحجام شائعة للمنتجات
class ProductSizes {
  static const List<String> clothingSizes = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'
  ];

  static const List<String> shoeSizes = [
    '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46'
  ];

  static const List<String> generalSizes = [
    'صغير', 'متوسط', 'كبير', 'كبير جداً'
  ];

  static List<String> getSizesForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'أزياء':
      case 'ملابس':
        return clothingSizes;
      case 'أحذية':
        return shoeSizes;
      default:
        return generalSizes;
    }
  }
}

/// بيانات تجريبية لاختيارات المنتجات
class ProductVariantSampleData {
  static List<ProductVariantModel> getSampleVariants(String productId) {
    return [
      ProductVariantModel(
        id: 'variant_1',
        productId: productId,
        name: 'نظارات قراءة - أزرق',
        imageUrl: 'assets/images/products/glasses1.png',
        quantity: 10,
        color: 'أزرق',
        colorHex: '#3182CE',
        size: 'M',
        price: 450.0,
        isAvailable: true,
        brand: 'كيركسن',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
      ProductVariantModel(
        id: 'variant_2',
        productId: productId,
        name: 'نظارات قراءة - أحمر',
        imageUrl: 'assets/images/products/glasses2-6a9524.png',
        quantity: 5,
        color: 'أحمر',
        colorHex: '#E53E3E',
        size: 'L',
        price: 450.0,
        isAvailable: true,
        brand: 'كيركسن',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
      ProductVariantModel(
        id: 'variant_3',
        productId: productId,
        name: 'نظارات قراءة - أسود',
        imageUrl: 'assets/images/products/glasses1.png',
        quantity: 0,
        color: 'أسود',
        colorHex: '#1A202C',
        size: 'S',
        price: 450.0,
        isAvailable: true,
        brand: 'كيركسن',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
