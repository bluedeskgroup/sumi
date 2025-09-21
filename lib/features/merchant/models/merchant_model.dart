import 'package:cloud_firestore/cloud_firestore.dart';

enum MerchantStatus {
  pending,     // في انتظار المراجعة
  approved,    // مقبول
  rejected,    // مرفوض
  suspended,   // معلق
}

enum BusinessType {
  retail,      // بيع بالتجزئة
  wholesale,   // بيع بالجملة
  services,    // خدمات
  restaurant,  // مطعم
  fashion,     // أزياء
  electronics, // إلكترونيات
  health,      // صحة وجمال
  home,        // منزل وحديقة
  sports,      // رياضة
  education,   // تعليم
  other,       // أخرى
}

class MerchantModel {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String nationalId;
  
  // بيانات الأعمال
  final String businessName;
  final String businessDescription;
  final BusinessType businessType;
  final String businessAddress;
  final String city;
  final String commercialRegistration;
  final String taxNumber;
  
  // بيانات بنكية
  final String bankName;
  final String accountNumber;
  final String iban;
  final String accountHolderName;
  
  // المنتجات والخدمات
  final List<String> productCategories;
  final List<String> serviceTypes;
  final String estimatedMonthlyRevenue;
  
  // ملفات مرفقة
  final String profileImageUrl;
  final String businessLicenseUrl;
  final String nationalIdImageUrl;
  final String bankStatementUrl;
  final List<String> productImagesUrls;
  
  // حالة الطلب
  final MerchantStatus status;
  final String? statusReason;
  final String? adminNotes;
  final String? reviewedBy;
  final Timestamp? reviewedAt;
  
  // الطوابع الزمنية
  final Timestamp createdAt;
  final Timestamp updatedAt;
  
  // إحصائيات
  final int totalProducts;
  final int totalOrders;
  final double rating;
  final bool isActive;
  
  // وسائل الدفع المفضلة (معرف إعدادات الدفع)
  final String? paymentSettingsId;

  MerchantModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.nationalId,
    required this.businessName,
    required this.businessDescription,
    required this.businessType,
    required this.businessAddress,
    required this.city,
    required this.commercialRegistration,
    required this.taxNumber,
    required this.bankName,
    required this.accountNumber,
    required this.iban,
    required this.accountHolderName,
    required this.productCategories,
    required this.serviceTypes,
    required this.estimatedMonthlyRevenue,
    required this.profileImageUrl,
    required this.businessLicenseUrl,
    required this.nationalIdImageUrl,
    required this.bankStatementUrl,
    required this.productImagesUrls,
    required this.status,
    this.statusReason,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.rating = 0.0,
    this.isActive = true,
    this.paymentSettingsId,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      nationalId: json['nationalId'] as String,
      businessName: json['businessName'] as String,
      businessDescription: json['businessDescription'] as String,
      businessType: BusinessType.values.firstWhere(
        (e) => e.toString() == 'BusinessType.${json['businessType']}',
        orElse: () => BusinessType.other,
      ),
      businessAddress: json['businessAddress'] as String,
      city: json['city'] as String,
      commercialRegistration: json['commercialRegistration'] as String,
      taxNumber: json['taxNumber'] as String,
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      iban: json['iban'] as String,
      accountHolderName: json['accountHolderName'] as String,
      productCategories: List<String>.from(json['productCategories'] ?? []),
      serviceTypes: List<String>.from(json['serviceTypes'] ?? []),
      estimatedMonthlyRevenue: json['estimatedMonthlyRevenue'] as String,
      profileImageUrl: json['profileImageUrl'] as String? ?? '',
      businessLicenseUrl: json['businessLicenseUrl'] as String? ?? '',
      nationalIdImageUrl: json['nationalIdImageUrl'] as String? ?? '',
      bankStatementUrl: json['bankStatementUrl'] as String? ?? '',
      productImagesUrls: List<String>.from(json['productImagesUrls'] ?? []),
      status: MerchantStatus.values.firstWhere(
        (e) => e.toString() == 'MerchantStatus.${json['status']}',
        orElse: () => MerchantStatus.pending,
      ),
      statusReason: json['statusReason'] as String?,
      adminNotes: json['adminNotes'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] as Timestamp?,
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
      totalProducts: json['totalProducts'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      paymentSettingsId: json['paymentSettingsId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'nationalId': nationalId,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'businessType': businessType.toString().split('.').last,
      'businessAddress': businessAddress,
      'city': city,
      'commercialRegistration': commercialRegistration,
      'taxNumber': taxNumber,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'iban': iban,
      'accountHolderName': accountHolderName,
      'productCategories': productCategories,
      'serviceTypes': serviceTypes,
      'estimatedMonthlyRevenue': estimatedMonthlyRevenue,
      'profileImageUrl': profileImageUrl,
      'businessLicenseUrl': businessLicenseUrl,
      'nationalIdImageUrl': nationalIdImageUrl,
      'bankStatementUrl': bankStatementUrl,
      'productImagesUrls': productImagesUrls,
      'status': status.toString().split('.').last,
      'statusReason': statusReason,
      'adminNotes': adminNotes,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'totalProducts': totalProducts,
      'totalOrders': totalOrders,
      'rating': rating,
      'isActive': isActive,
      'paymentSettingsId': paymentSettingsId,
    };
  }

  MerchantModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? nationalId,
    String? businessName,
    String? businessDescription,
    BusinessType? businessType,
    String? businessAddress,
    String? city,
    String? commercialRegistration,
    String? taxNumber,
    String? bankName,
    String? accountNumber,
    String? iban,
    String? accountHolderName,
    List<String>? productCategories,
    List<String>? serviceTypes,
    String? estimatedMonthlyRevenue,
    String? profileImageUrl,
    String? businessLicenseUrl,
    String? nationalIdImageUrl,
    String? bankStatementUrl,
    List<String>? productImagesUrls,
    MerchantStatus? status,
    String? statusReason,
    String? adminNotes,
    String? reviewedBy,
    Timestamp? reviewedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? totalProducts,
    int? totalOrders,
    double? rating,
    bool? isActive,
    String? paymentSettingsId,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId ?? this.nationalId,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessType: businessType ?? this.businessType,
      businessAddress: businessAddress ?? this.businessAddress,
      city: city ?? this.city,
      commercialRegistration: commercialRegistration ?? this.commercialRegistration,
      taxNumber: taxNumber ?? this.taxNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      productCategories: productCategories ?? this.productCategories,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      estimatedMonthlyRevenue: estimatedMonthlyRevenue ?? this.estimatedMonthlyRevenue,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      businessLicenseUrl: businessLicenseUrl ?? this.businessLicenseUrl,
      nationalIdImageUrl: nationalIdImageUrl ?? this.nationalIdImageUrl,
      bankStatementUrl: bankStatementUrl ?? this.bankStatementUrl,
      productImagesUrls: productImagesUrls ?? this.productImagesUrls,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      adminNotes: adminNotes ?? this.adminNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalProducts: totalProducts ?? this.totalProducts,
      totalOrders: totalOrders ?? this.totalOrders,
      rating: rating ?? this.rating,
      isActive: isActive ?? this.isActive,
      paymentSettingsId: paymentSettingsId ?? this.paymentSettingsId,
    );
  }

  // مساعدات للحصول على النصوص المترجمة
  static String getBusinessTypeName(BusinessType type, bool isArabic) {
    switch (type) {
      case BusinessType.retail:
        return isArabic ? 'بيع بالتجزئة' : 'Retail';
      case BusinessType.wholesale:
        return isArabic ? 'بيع بالجملة' : 'Wholesale';
      case BusinessType.services:
        return isArabic ? 'خدمات' : 'Services';
      case BusinessType.restaurant:
        return isArabic ? 'مطعم' : 'Restaurant';
      case BusinessType.fashion:
        return isArabic ? 'أزياء' : 'Fashion';
      case BusinessType.electronics:
        return isArabic ? 'إلكترونيات' : 'Electronics';
      case BusinessType.health:
        return isArabic ? 'صحة وجمال' : 'Health & Beauty';
      case BusinessType.home:
        return isArabic ? 'منزل وحديقة' : 'Home & Garden';
      case BusinessType.sports:
        return isArabic ? 'رياضة' : 'Sports';
      case BusinessType.education:
        return isArabic ? 'تعليم' : 'Education';
      case BusinessType.other:
        return isArabic ? 'أخرى' : 'Other';
    }
  }

  static String getStatusName(MerchantStatus status, bool isArabic) {
    switch (status) {
      case MerchantStatus.pending:
        return isArabic ? 'في انتظار المراجعة' : 'Pending Review';
      case MerchantStatus.approved:
        return isArabic ? 'مقبول' : 'Approved';
      case MerchantStatus.rejected:
        return isArabic ? 'مرفوض' : 'Rejected';
      case MerchantStatus.suspended:
        return isArabic ? 'معلق' : 'Suspended';
    }
  }

  // قائمة المدن السعودية الرئيسية
  static List<String> get saudiCities => [
    'الرياض',
    'جدة',
    'مكة المكرمة',
    'المدينة المنورة',
    'الدمام',
    'الخبر',
    'الظهران',
    'القطيف',
    'الجبيل',
    'تبوك',
    'بريدة',
    'عنيزة',
    'الطائف',
    'حائل',
    'أبها',
    'خميس مشيط',
    'النماص',
    'جازان',
    'صامطة',
    'نجران',
    'شرورة',
    'عرعر',
    'سكاكا',
    'طريف',
    'القريات',
    'الباحة',
    'المجمعة',
    'الزلفي',
    'الرس',
    'الخرج',
    'وادي الدواسر',
    'الأفلاج',
    'بيشة',
    'الليث',
    'رابغ',
    'ينبع',
    'الوجه',
    'ضباء',
    'املج',
    'القنفذة',
    'الحوية',
    'تثليث',
    'محايل عسير',
    'تنومة',
    'رجال ألمع',
    'أحد رفيدة',
    'الداير',
    'فرسان',
    'صبيا',
    'أبو عريش',
    'الدرب',
    'العارضة',
    'بلجرشي',
    'المندق',
    'العقيق',
    'قلوة',
    'الحناكية',
    'المهد',
    'الصويدرة',
    'الغاط',
    'رماح',
    'مرات',
    'الدوادمي',
    'البكيرية',
    'الشماسية',
    'رياض الخبراء',
    'الهفوف',
    'المبرز',
    'بقيق',
    'العديد',
    'رأس تنورة',
    'الخفجي',
    'حفر الباطن',
    'قرية العليا',
    'النعيرية',
    'الأحساء',
    'أخرى',
  ];

  // فئات المنتجات
  static List<String> get availableProductCategories => [
    'إلكترونيات',
    'أزياء ومجوهرات',
    'منزل وحديقة',
    'صحة وجمال',
    'رياضة وأنشطة خارجية',
    'ألعاب وهوايات',
    'كتب ووسائط',
    'سيارات ومواصلات',
    'عقارات',
    'خدمات مهنية',
    'تعليم وتدريب',
    'سفر وسياحة',
    'طعام ومشروبات',
    'فنون وحرف يدوية',
    'خدمات منزلية',
    'أخرى',
  ];
}

// فئات الخدمات
class ServiceCategory {
  static List<String> get serviceTypes => [
    'خدمات تقنية',
    'تصميم وإبداع',
    'استشارات',
    'خدمات منزلية',
    'صيانة وإصلاح',
    'خدمات نقل',
    'خدمات طبية',
    'خدمات تعليمية',
    'خدمات قانونية',
    'خدمات مالية',
    'خدمات تسويقية',
    'خدمات أعمال',
    'خدمات شخصية',
    'خدمات رياضية',
    'خدمات سياحية',
    'أخرى',
  ];
}
