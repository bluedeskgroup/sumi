import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethodType {
  // بطاقات ائتمانية
  visa('فيزا', 'visa'),
  mastercard('ماستر كارد', 'mastercard'),
  americanExpress('أمريكان إكسبرس', 'amex'),
  
  // محافظ رقمية محلية السعودية
  stcPay('STC Pay', 'stc_pay'),
  urPay('urPay', 'urpay'),
  applePay('Apple Pay', 'apple_pay'),
  samsungPay('Samsung Pay', 'samsung_pay'),
  
  // محافظ رقمية مصرية
  vodafoneCash('فودافون كاش', 'vodafone_cash'),
  etisalatCash('اتصالات كاش', 'etisalat_cash'),
  orangeCash('أورانج كاش', 'orange_cash'),
  
  // محافظ رقمية دولية
  paypal('PayPal', 'paypal'),
  
  // محفظة المنصة
  appWallet('محفظة التطبيق', 'app_wallet'),
  
  // دفع نقدي
  cashOnDelivery('الدفع عند الاستلام', 'cash_on_delivery'),
  
  // تحويل بنكي
  bankTransfer('تحويل بنكي', 'bank_transfer');

  const PaymentMethodType(this.displayNameArabic, this.value);
  
  final String displayNameArabic;
  final String value;
  
  static PaymentMethodType fromValue(String value) {
    return PaymentMethodType.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethodType.appWallet,
    );
  }
}

enum PaymentMethodCategory {
  creditCards('بطاقات ائتمانية'),
  digitalWallets('محافظ رقمية'),
  cash('نقدي'),
  bankTransfer('تحويل بنكي');

  const PaymentMethodCategory(this.displayName);
  final String displayName;
}

class MerchantPaymentMethod {
  final PaymentMethodType type;
  final bool isEnabled;
  final bool isAutomatic; // إذا كان الدفع تلقائي أم يحتاج موافقة
  final Map<String, dynamic>? configuration; // إعدادات إضافية لكل وسيلة دفع
  final DateTime updatedAt;

  const MerchantPaymentMethod({
    required this.type,
    required this.isEnabled,
    this.isAutomatic = true,
    this.configuration,
    required this.updatedAt,
  });

  factory MerchantPaymentMethod.fromMap(Map<String, dynamic> map) {
    return MerchantPaymentMethod(
      type: PaymentMethodType.fromValue(map['type']),
      isEnabled: map['isEnabled'] ?? false,
      isAutomatic: map['isAutomatic'] ?? true,
      configuration: map['configuration'],
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'isEnabled': isEnabled,
      'isAutomatic': isAutomatic,
      'configuration': configuration,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MerchantPaymentMethod copyWith({
    PaymentMethodType? type,
    bool? isEnabled,
    bool? isAutomatic,
    Map<String, dynamic>? configuration,
    DateTime? updatedAt,
  }) {
    return MerchantPaymentMethod(
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      configuration: configuration ?? this.configuration,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MerchantPaymentSettings {
  final String merchantId;
  final List<MerchantPaymentMethod> paymentMethods;
  final bool requireMinimumOrder; // هل يتطلب حد أدنى للطلب
  final double? minimumOrderAmount; // الحد الأدنى للطلب
  final Map<String, dynamic>? generalSettings; // إعدادات عامة
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantPaymentSettings({
    required this.merchantId,
    required this.paymentMethods,
    this.requireMinimumOrder = false,
    this.minimumOrderAmount,
    this.generalSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  // الحصول على وسائل الدفع المفعلة فقط
  List<MerchantPaymentMethod> get enabledPaymentMethods {
    return paymentMethods.where((method) => method.isEnabled).toList();
  }

  // الحصول على وسائل الدفع التلقائية المفعلة
  List<MerchantPaymentMethod> get automaticPaymentMethods {
    return paymentMethods
        .where((method) => method.isEnabled && method.isAutomatic)
        .toList();
  }

  // تجميع وسائل الدفع حسب النوع
  Map<PaymentMethodCategory, List<MerchantPaymentMethod>> get methodsByCategory {
    final Map<PaymentMethodCategory, List<MerchantPaymentMethod>> result = {};
    
    for (final method in enabledPaymentMethods) {
      PaymentMethodCategory category;
      switch (method.type) {
        case PaymentMethodType.visa:
        case PaymentMethodType.mastercard:
        case PaymentMethodType.americanExpress:
          category = PaymentMethodCategory.creditCards;
          break;
        case PaymentMethodType.stcPay:
        case PaymentMethodType.urPay:
        case PaymentMethodType.vodafoneCash:
        case PaymentMethodType.etisalatCash:
        case PaymentMethodType.orangeCash:
        case PaymentMethodType.applePay:
        case PaymentMethodType.samsungPay:
        case PaymentMethodType.paypal:
        case PaymentMethodType.appWallet:
          category = PaymentMethodCategory.digitalWallets;
          break;
        case PaymentMethodType.cashOnDelivery:
          category = PaymentMethodCategory.cash;
          break;
        case PaymentMethodType.bankTransfer:
          category = PaymentMethodCategory.bankTransfer;
          break;
      }
      
      result.putIfAbsent(category, () => []).add(method);
    }
    
    return result;
  }

  factory MerchantPaymentSettings.fromMap(Map<String, dynamic> map) {
    return MerchantPaymentSettings(
      merchantId: map['merchantId'],
      paymentMethods: (map['paymentMethods'] as List<dynamic>?)
          ?.map((method) => MerchantPaymentMethod.fromMap(method))
          .toList() ?? [],
      requireMinimumOrder: map['requireMinimumOrder'] ?? false,
      minimumOrderAmount: map['minimumOrderAmount']?.toDouble(),
      generalSettings: map['generalSettings'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'paymentMethods': paymentMethods.map((method) => method.toMap()).toList(),
      'requireMinimumOrder': requireMinimumOrder,
      'minimumOrderAmount': minimumOrderAmount,
      'generalSettings': generalSettings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MerchantPaymentSettings copyWith({
    String? merchantId,
    List<MerchantPaymentMethod>? paymentMethods,
    bool? requireMinimumOrder,
    double? minimumOrderAmount,
    Map<String, dynamic>? generalSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MerchantPaymentSettings(
      merchantId: merchantId ?? this.merchantId,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      requireMinimumOrder: requireMinimumOrder ?? this.requireMinimumOrder,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      generalSettings: generalSettings ?? this.generalSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // إنشاء إعدادات افتراضية للتاجر الجديد
  static MerchantPaymentSettings createDefault(String merchantId) {
    return MerchantPaymentSettings(
      merchantId: merchantId,
      paymentMethods: [
        // تفعيل محفظة التطبيق والدفع عند الاستلام افتراضياً
        MerchantPaymentMethod(
          type: PaymentMethodType.appWallet,
          isEnabled: true,
          isAutomatic: true,
          updatedAt: DateTime.now(),
        ),
        MerchantPaymentMethod(
          type: PaymentMethodType.cashOnDelivery,
          isEnabled: true,
          isAutomatic: false, // يحتاج تأكيد من التاجر
          updatedAt: DateTime.now(),
        ),
        // باقي الوسائل معطلة افتراضياً
        ...PaymentMethodType.values
            .where((type) => type != PaymentMethodType.appWallet && 
                           type != PaymentMethodType.cashOnDelivery)
            .map((type) => MerchantPaymentMethod(
                  type: type,
                  isEnabled: false,
                  isAutomatic: true,
                  updatedAt: DateTime.now(),
                )),
      ],
      requireMinimumOrder: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
