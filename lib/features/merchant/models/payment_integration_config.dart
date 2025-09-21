import 'package:cloud_firestore/cloud_firestore.dart';
import 'merchant_payment_methods.dart';

/// تكوين التكامل لوسائل الدفع المختلفة
class PaymentIntegrationConfig {
  static const String defaultMobileWalletNumber = '01010576801';
  static const String defaultPayPalEmail = 'amirtallalkamal@gmail.com';
  
  // معلومات التكامل الثابتة لكل وسيلة دفع
  static final Map<PaymentMethodType, PaymentProviderConfig> _providerConfigs = {
    // المحافظ المصرية
    PaymentMethodType.vodafoneCash: PaymentProviderConfig(
      providerName: 'فودافون كاش',
      receiverInfo: defaultMobileWalletNumber,
      isAutomatic: true,
      transferMessage: 'تحويل من تطبيق سومي - طلب رقم',
    ),
    PaymentMethodType.etisalatCash: PaymentProviderConfig(
      providerName: 'اتصالات كاش', 
      receiverInfo: defaultMobileWalletNumber,
      isAutomatic: true,
      transferMessage: 'تحويل من تطبيق سومي - طلب رقم',
    ),
    PaymentMethodType.orangeCash: PaymentProviderConfig(
      providerName: 'أورانج كاش',
      receiverInfo: defaultMobileWalletNumber,
      isAutomatic: true,
      transferMessage: 'تحويل من تطبيق سومي - طلب رقم',
    ),
    
    // PayPal
    PaymentMethodType.paypal: PaymentProviderConfig(
      providerName: 'PayPal',
      receiverInfo: defaultPayPalEmail,
      isAutomatic: true,
      transferMessage: 'Payment from Sumi App - Order #',
    ),
    
    // البطاقات الائتمانية
    PaymentMethodType.visa: PaymentProviderConfig(
      providerName: 'Visa',
      receiverInfo: 'visa_merchant_account',
      isAutomatic: true,
      transferMessage: 'Sumi App Purchase',
    ),
    PaymentMethodType.mastercard: PaymentProviderConfig(
      providerName: 'Mastercard',
      receiverInfo: 'mastercard_merchant_account',
      isAutomatic: true,
      transferMessage: 'Sumi App Purchase',
    ),
  };

  /// الحصول على تكوين مقدم الخدمة
  static PaymentProviderConfig? getProviderConfig(PaymentMethodType paymentType) {
    return _providerConfigs[paymentType];
  }

  /// التحقق من كون وسيلة الدفع تدعم التحويل التلقائي
  static bool isAutomaticPaymentSupported(PaymentMethodType paymentType) {
    return _providerConfigs[paymentType]?.isAutomatic ?? false;
  }

  /// الحصول على رسالة التحويل المناسبة
  static String getTransferMessage(PaymentMethodType paymentType, String orderId) {
    final config = _providerConfigs[paymentType];
    if (config == null) return 'Payment from Sumi App';
    
    return '${config.transferMessage}$orderId';
  }

  /// تحديث معلومات المتلقي (في حالة الحاجة لتخصيص)
  static void updateReceiverInfo(PaymentMethodType paymentType, String newReceiverInfo) {
    final config = _providerConfigs[paymentType];
    if (config != null) {
      _providerConfigs[paymentType] = config.copyWith(receiverInfo: newReceiverInfo);
    }
  }
}

/// نموذج تكوين مقدم الخدمة
class PaymentProviderConfig {
  final String providerName;
  final String receiverInfo; // رقم المحفظة أو البريد الإلكتروني
  final bool isAutomatic;
  final String transferMessage;
  final Map<String, dynamic> additionalSettings;

  const PaymentProviderConfig({
    required this.providerName,
    required this.receiverInfo,
    required this.isAutomatic,
    required this.transferMessage,
    this.additionalSettings = const {},
  });

  PaymentProviderConfig copyWith({
    String? providerName,
    String? receiverInfo,
    bool? isAutomatic,
    String? transferMessage,
    Map<String, dynamic>? additionalSettings,
  }) {
    return PaymentProviderConfig(
      providerName: providerName ?? this.providerName,
      receiverInfo: receiverInfo ?? this.receiverInfo,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      transferMessage: transferMessage ?? this.transferMessage,
      additionalSettings: additionalSettings ?? this.additionalSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'providerName': providerName,
      'receiverInfo': receiverInfo,
      'isAutomatic': isAutomatic,
      'transferMessage': transferMessage,
      'additionalSettings': additionalSettings,
    };
  }

  factory PaymentProviderConfig.fromJson(Map<String, dynamic> json) {
    return PaymentProviderConfig(
      providerName: json['providerName'] as String,
      receiverInfo: json['receiverInfo'] as String,
      isAutomatic: json['isAutomatic'] as bool,
      transferMessage: json['transferMessage'] as String,
      additionalSettings: json['additionalSettings'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// نموذج معاملة الدفع
class PaymentTransaction {
  final String id;
  final String orderId;
  final PaymentMethodType paymentMethod;
  final double amount;
  final String currency;
  final PaymentTransactionStatus status;
  final String? transactionReference;
  final String? providerTransactionId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.paymentMethod,
    required this.amount,
    this.currency = 'EGP',
    required this.status,
    this.transactionReference,
    this.providerTransactionId,
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'paymentMethod': paymentMethod.value,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'transactionReference': transactionReference,
      'providerTransactionId': providerTransactionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'failureReason': failureReason,
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      paymentMethod: PaymentMethodType.fromValue(json['paymentMethod'] as String),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'EGP',
      status: PaymentTransactionStatus.values.byName(json['status'] as String),
      transactionReference: json['transactionReference'] as String?,
      providerTransactionId: json['providerTransactionId'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      completedAt: json['completedAt'] != null 
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      failureReason: json['failureReason'] as String?,
    );
  }
}

/// حالات معاملة الدفع
enum PaymentTransactionStatus {
  pending,    // في الانتظار
  processing, // قيد المعالجة
  completed,  // مكتملة
  failed,     // فشلت
  cancelled,  // ملغية
  refunded,   // مسترد
}

/// خدمة محاكاة وسائل الدفع للاختبار
class PaymentSimulatorService {
  static final PaymentSimulatorService _instance = PaymentSimulatorService._internal();
  factory PaymentSimulatorService() => _instance;
  PaymentSimulatorService._internal();

  /// محاكاة معالجة دفع فودافون كاش
  Future<PaymentTransaction> processVodafoneCashPayment({
    required String orderId,
    required double amount,
  }) async {
    // محاكاة تأخير المعالجة
    await Future.delayed(const Duration(seconds: 2));
    
    // محاكاة نجاح الدفع 90% من الوقت
    final isSuccessful = DateTime.now().millisecond % 10 != 0;
    
    return PaymentTransaction(
      id: 'vf_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      paymentMethod: PaymentMethodType.vodafoneCash,
      amount: amount,
      status: isSuccessful ? PaymentTransactionStatus.completed : PaymentTransactionStatus.failed,
      transactionReference: 'VF${DateTime.now().millisecondsSinceEpoch}',
      providerTransactionId: 'VF_TXN_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: isSuccessful ? DateTime.now() : null,
      failureReason: isSuccessful ? null : 'رصيد المحفظة غير كافٍ',
    );
  }

  /// محاكاة معالجة دفع اتصالات كاش
  Future<PaymentTransaction> processEtisalatCashPayment({
    required String orderId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final isSuccessful = DateTime.now().millisecond % 10 != 0;
    
    return PaymentTransaction(
      id: 'et_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      paymentMethod: PaymentMethodType.etisalatCash,
      amount: amount,
      status: isSuccessful ? PaymentTransactionStatus.completed : PaymentTransactionStatus.failed,
      transactionReference: 'ET${DateTime.now().millisecondsSinceEpoch}',
      providerTransactionId: 'ET_TXN_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: isSuccessful ? DateTime.now() : null,
      failureReason: isSuccessful ? null : 'خطأ في اتصال الشبكة',
    );
  }

  /// محاكاة معالجة دفع أورانج كاش
  Future<PaymentTransaction> processOrangeCashPayment({
    required String orderId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final isSuccessful = DateTime.now().millisecond % 10 != 0;
    
    return PaymentTransaction(
      id: 'or_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      paymentMethod: PaymentMethodType.orangeCash,
      amount: amount,
      status: isSuccessful ? PaymentTransactionStatus.completed : PaymentTransactionStatus.failed,
      transactionReference: 'OR${DateTime.now().millisecondsSinceEpoch}',
      providerTransactionId: 'OR_TXN_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: isSuccessful ? DateTime.now() : null,
      failureReason: isSuccessful ? null : 'رقم المحفظة غير صحيح',
    );
  }

  /// محاكاة معالجة دفع PayPal
  Future<PaymentTransaction> processPayPalPayment({
    required String orderId,
    required double amount,
  }) async {
    await Future.delayed(const Duration(seconds: 3));
    
    final isSuccessful = DateTime.now().millisecond % 10 != 0;
    
    return PaymentTransaction(
      id: 'pp_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      paymentMethod: PaymentMethodType.paypal,
      amount: amount,
      status: isSuccessful ? PaymentTransactionStatus.completed : PaymentTransactionStatus.failed,
      transactionReference: 'PP${DateTime.now().millisecondsSinceEpoch}',
      providerTransactionId: 'PP_TXN_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: isSuccessful ? DateTime.now() : null,
      failureReason: isSuccessful ? null : 'PayPal account verification failed',
    );
  }

  /// محاكاة معالجة دفع بطاقة ائتمانية
  Future<PaymentTransaction> processCreditCardPayment({
    required String orderId,
    required double amount,
    required PaymentMethodType cardType,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    await Future.delayed(const Duration(seconds: 4));
    
    final isSuccessful = DateTime.now().millisecond % 15 != 0; // نجاح أعلى للبطاقات
    
    return PaymentTransaction(
      id: '${cardType.value}_${DateTime.now().millisecondsSinceEpoch}',
      orderId: orderId,
      paymentMethod: cardType,
      amount: amount,
      status: isSuccessful ? PaymentTransactionStatus.completed : PaymentTransactionStatus.failed,
      transactionReference: 'CC${DateTime.now().millisecondsSinceEpoch}',
      providerTransactionId: 'CC_TXN_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: isSuccessful ? DateTime.now() : null,
      failureReason: isSuccessful ? null : 'Card declined by issuing bank',
    );
  }
}
