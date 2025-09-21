import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoryType { product, service }
enum CategoryStatus { active, inactive }

class CategoryUnifiedModel {
  final String id;
  final String merchantId;
  final String name;
  final String nameEn;
  final String description;
  final String iconUrl;
  final String imageUrl;
  final CategoryType type;
  final CategoryStatus status;
  final String country; // الدولة المستهدفة
  final int sortOrder;
  final List<String> tags;
  final int productCount; // عدد المنتجات في هذا القسم
  final int serviceCount; // عدد الخدمات في هذا القسم
  final bool isFeatured; // قسم مميز
  final String color; // لون القسم
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryUnifiedModel({
    required this.id,
    required this.merchantId,
    required this.name,
    this.nameEn = '',
    this.description = '',
    this.iconUrl = '',
    this.imageUrl = '',
    this.type = CategoryType.product,
    this.status = CategoryStatus.active,
    this.country = 'السعودية',
    this.sortOrder = 0,
    this.tags = const [],
    this.productCount = 0,
    this.serviceCount = 0,
    this.isFeatured = false,
    this.color = '#9A46D7',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor from Firestore document
  factory CategoryUnifiedModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return CategoryUnifiedModel.fromMap(data);
  }

  // Factory constructor from Map
  factory CategoryUnifiedModel.fromMap(Map<String, dynamic> map) {
    return CategoryUnifiedModel(
      id: map['id'] ?? '',
      merchantId: map['merchantId'] ?? '',
      name: map['name'] ?? '',
      nameEn: map['nameEn'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.product,
      ),
      status: CategoryStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CategoryStatus.active,
      ),
      country: map['country'] ?? 'السعودية',
      sortOrder: map['sortOrder'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      productCount: map['productCount'] ?? 0,
      serviceCount: map['serviceCount'] ?? 0,
      isFeatured: map['isFeatured'] ?? false,
      color: map['color'] ?? '#9A46D7',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchantId': merchantId,
      'name': name,
      'nameEn': nameEn,
      'description': description,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'type': type.name,
      'status': status.name,
      'country': country,
      'sortOrder': sortOrder,
      'tags': tags,
      'productCount': productCount,
      'serviceCount': serviceCount,
      'isFeatured': isFeatured,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method
  CategoryUnifiedModel copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? nameEn,
    String? description,
    String? iconUrl,
    String? imageUrl,
    CategoryType? type,
    CategoryStatus? status,
    String? country,
    int? sortOrder,
    List<String>? tags,
    int? productCount,
    int? serviceCount,
    bool? isFeatured,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryUnifiedModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      country: country ?? this.country,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      productCount: productCount ?? this.productCount,
      serviceCount: serviceCount ?? this.serviceCount,
      isFeatured: isFeatured ?? this.isFeatured,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CategoryUnifiedModel(id: $id, name: $name, type: $type, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryUnifiedModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Getters for formatted values
  String get formattedType => type == CategoryType.product ? 'منتجات' : 'خدمات';
  String get formattedStatus => status == CategoryStatus.active ? 'نشط' : 'غير نشط';
  String get formattedCount => type == CategoryType.product ? '$productCount منتج' : '$serviceCount خدمة';
  bool get hasItems => (type == CategoryType.product ? productCount : serviceCount) > 0;
}

// Sample data for testing
class CategorySampleData {
  static List<CategoryUnifiedModel> getSampleCategories(String merchantId, String country) {
    return [
      // أقسام المنتجات
      CategoryUnifiedModel(
        id: 'cat_electronics',
        merchantId: merchantId,
        name: 'إلكترونيات',
        nameEn: 'Electronics',
        description: 'أجهزة إلكترونية ومعدات تقنية',
        iconUrl: 'assets/icons/electronics.png',
        imageUrl: 'assets/images/categories/electronics.jpg',
        type: CategoryType.product,
        status: CategoryStatus.active,
        country: country,
        sortOrder: 1,
        tags: ['إلكترونيات', 'تقنية', 'أجهزة'],
        productCount: 25,
        isFeatured: true,
        color: '#2196F3',
      ),
      CategoryUnifiedModel(
        id: 'cat_fashion',
        merchantId: merchantId,
        name: 'أزياء',
        nameEn: 'Fashion',
        description: 'ملابس وإكسسوارات للرجال والنساء',
        iconUrl: 'assets/icons/fashion.png',
        imageUrl: 'assets/images/categories/fashion.jpg',
        type: CategoryType.product,
        status: CategoryStatus.active,
        country: country,
        sortOrder: 2,
        tags: ['ملابس', 'أزياء', 'إكسسوارات'],
        productCount: 18,
        isFeatured: true,
        color: '#E91E63',
      ),
      CategoryUnifiedModel(
        id: 'cat_home',
        merchantId: merchantId,
        name: 'منزل وحديقة',
        nameEn: 'Home & Garden',
        description: 'أدوات منزلية ونباتات وديكور',
        iconUrl: 'assets/icons/home.png',
        imageUrl: 'assets/images/categories/home.jpg',
        type: CategoryType.product,
        status: CategoryStatus.active,
        country: country,
        sortOrder: 3,
        tags: ['منزل', 'ديكور', 'حديقة'],
        productCount: 32,
        color: '#4CAF50',
      ),
      CategoryUnifiedModel(
        id: 'cat_health',
        merchantId: merchantId,
        name: 'صحة وجمال',
        nameEn: 'Health & Beauty',
        description: 'منتجات العناية والجمال والصحة',
        iconUrl: 'assets/icons/health.png',
        imageUrl: 'assets/images/categories/health.jpg',
        type: CategoryType.product,
        status: CategoryStatus.active,
        country: country,
        sortOrder: 4,
        tags: ['صحة', 'جمال', 'عناية'],
        productCount: 15,
        color: '#FF9800',
      ),

      // أقسام الخدمات
      CategoryUnifiedModel(
        id: 'cat_tech_services',
        merchantId: merchantId,
        name: 'خدمات تقنية',
        nameEn: 'Tech Services',
        description: 'برمجة وتطوير وتقنية المعلومات',
        iconUrl: 'assets/icons/tech_services.png',
        imageUrl: 'assets/images/categories/tech_services.jpg',
        type: CategoryType.service,
        status: CategoryStatus.active,
        country: country,
        sortOrder: 5,
        tags: ['برمجة', 'تطوير', 'تقنية'],
        serviceCount: 12,
        isFeatured: true,
        color: '#9C27B0',
      ),
      CategoryUnifiedModel(
        id: 'cat_consulting',
        merchantId: merchantId,
        name: 'استشارات',
        nameEn: 'Consulting',
        description: 'استشارات قانونية ومالية وإدارية',
        iconUrl: 'assets/icons/consulting.png',
        imageUrl: 'assets/images/categories/consulting.jpg',
        type: CategoryType.service,
        status: CategoryStatus.active,
        country: country,
        sortOrder: 6,
        tags: ['استشارات', 'قانونية', 'مالية'],
        serviceCount: 8,
        color: '#795548',
      ),
      CategoryUnifiedModel(
        id: 'cat_delivery',
        merchantId: merchantId,
        name: 'خدمات توصيل',
        nameEn: 'Delivery Services',
        description: 'توصيل وشحن ونقل',
        iconUrl: 'assets/icons/delivery.png',
        imageUrl: 'assets/images/categories/delivery.jpg',
        type: CategoryType.service,
        status: CategoryStatus.active,
        country: country,
        sortOrder: 7,
        tags: ['توصيل', 'شحن', 'نقل'],
        serviceCount: 5,
        color: '#607D8B',
      ),
      CategoryUnifiedModel(
        id: 'cat_education',
        merchantId: merchantId,
        name: 'تعليم وتدريب',
        nameEn: 'Education & Training',
        description: 'دورات تدريبية وتعليمية',
        iconUrl: 'assets/icons/education.png',
        imageUrl: 'assets/images/categories/education.jpg',
        type: CategoryType.service,
        status: CategoryStatus.active,
        country: country,
        sortOrder: 8,
        tags: ['تعليم', 'تدريب', 'دورات'],
        serviceCount: 20,
        isFeatured: true,
        color: '#FF5722',
      ),
    ];
  }

  // Get categories by type
  static List<CategoryUnifiedModel> getCategoriesByType(String merchantId, String country, CategoryType type) {
    return getSampleCategories(merchantId, country)
        .where((category) => category.type == type)
        .toList();
  }

  // Get featured categories
  static List<CategoryUnifiedModel> getFeaturedCategories(String merchantId, String country) {
    return getSampleCategories(merchantId, country)
        .where((category) => category.isFeatured)
        .toList();
  }
}
