import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/merchant_payment_methods.dart';

class MerchantPaymentService {
  static final MerchantPaymentService _instance = MerchantPaymentService._internal();
  factory MerchantPaymentService() => _instance;
  MerchantPaymentService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentMerchantId => _auth.currentUser?.uid;

  // مجموعة إعدادات الدفع للتجار
  CollectionReference<Map<String, dynamic>> get _paymentSettingsCollection =>
      _db.collection('merchant_payment_settings');

  // الحصول على إعدادات الدفع لتاجر معين
  Future<MerchantPaymentSettings?> getMerchantPaymentSettings(String merchantId) async {
    try {
      final doc = await _paymentSettingsCollection.doc(merchantId).get();
      if (doc.exists && doc.data() != null) {
        return MerchantPaymentSettings.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting merchant payment settings: $e');
      return null;
    }
  }

  // الحصول على إعدادات الدفع للتاجر الحالي
  Future<MerchantPaymentSettings?> getCurrentMerchantPaymentSettings() async {
    if (_currentMerchantId == null) return null;
    return getMerchantPaymentSettings(_currentMerchantId!);
  }

  // مراقبة تغييرات إعدادات الدفع للتاجر
  Stream<MerchantPaymentSettings?> watchMerchantPaymentSettings(String merchantId) {
    return _paymentSettingsCollection
        .doc(merchantId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return MerchantPaymentSettings.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // مراقبة إعدادات الدفع للتاجر الحالي
  Stream<MerchantPaymentSettings?> watchCurrentMerchantPaymentSettings() {
    if (_currentMerchantId == null) return Stream.value(null);
    return watchMerchantPaymentSettings(_currentMerchantId!);
  }

  // حفظ أو تحديث إعدادات الدفع للتاجر
  Future<bool> updateMerchantPaymentSettings(MerchantPaymentSettings settings) async {
    try {
      await _paymentSettingsCollection
          .doc(settings.merchantId)
          .set(settings.copyWith(updatedAt: DateTime.now()).toMap());
      return true;
    } catch (e) {
      print('Error updating merchant payment settings: $e');
      return false;
    }
  }

  // إنشاء إعدادات دفع افتراضية لتاجر جديد
  Future<bool> createDefaultPaymentSettings(String merchantId) async {
    try {
      final defaultSettings = MerchantPaymentSettings.createDefault(merchantId);
      await _paymentSettingsCollection
          .doc(merchantId)
          .set(defaultSettings.toMap());
      return true;
    } catch (e) {
      print('Error creating default payment settings: $e');
      return false;
    }
  }

  // تحديث وسيلة دفع واحدة
  Future<bool> updatePaymentMethod(
    String merchantId,
    PaymentMethodType type,
    bool isEnabled, {
    bool? isAutomatic,
    Map<String, dynamic>? configuration,
  }) async {
    try {
      final settings = await getMerchantPaymentSettings(merchantId);
      if (settings == null) {
        // إنشاء إعدادات جديدة إذا لم تكن موجودة
        await createDefaultPaymentSettings(merchantId);
        return updatePaymentMethod(merchantId, type, isEnabled, 
            isAutomatic: isAutomatic, configuration: configuration);
      }

      // البحث عن وسيلة الدفع وتحديثها
      final updatedMethods = settings.paymentMethods.map((method) {
        if (method.type == type) {
          return method.copyWith(
            isEnabled: isEnabled,
            isAutomatic: isAutomatic,
            configuration: configuration,
            updatedAt: DateTime.now(),
          );
        }
        return method;
      }).toList();

      final updatedSettings = settings.copyWith(
        paymentMethods: updatedMethods,
        updatedAt: DateTime.now(),
      );

      return await updateMerchantPaymentSettings(updatedSettings);
    } catch (e) {
      print('Error updating payment method: $e');
      return false;
    }
  }

  // تفعيل/تعطيل جميع وسائل الدفع
  Future<bool> toggleAllPaymentMethods(String merchantId, bool enableAll) async {
    try {
      final settings = await getMerchantPaymentSettings(merchantId);
      if (settings == null) return false;

      final updatedMethods = settings.paymentMethods.map((method) =>
          method.copyWith(
            isEnabled: enableAll,
            updatedAt: DateTime.now(),
          )).toList();

      final updatedSettings = settings.copyWith(
        paymentMethods: updatedMethods,
        updatedAt: DateTime.now(),
      );

      return await updateMerchantPaymentSettings(updatedSettings);
    } catch (e) {
      print('Error toggling all payment methods: $e');
      return false;
    }
  }

  // الحصول على وسائل الدفع المفعلة لتاجر معين (للاستخدام في صفحة الدفع)
  Future<List<MerchantPaymentMethod>> getEnabledPaymentMethods(String merchantId) async {
    final settings = await getMerchantPaymentSettings(merchantId);
    return settings?.enabledPaymentMethods ?? [];
  }

  // الحصول على وسائل الدفع التلقائية المفعلة
  Future<List<MerchantPaymentMethod>> getAutomaticPaymentMethods(String merchantId) async {
    final settings = await getMerchantPaymentSettings(merchantId);
    return settings?.automaticPaymentMethods ?? [];
  }

  // التحقق من أن التاجر يقبل وسيلة دفع معينة
  Future<bool> doesMerchantAcceptPaymentMethod(
    String merchantId,
    PaymentMethodType type,
  ) async {
    final enabledMethods = await getEnabledPaymentMethods(merchantId);
    return enabledMethods.any((method) => method.type == type);
  }

  // الحصول على إعدادات وسيلة دفع معينة
  Future<MerchantPaymentMethod?> getPaymentMethodSettings(
    String merchantId,
    PaymentMethodType type,
  ) async {
    final settings = await getMerchantPaymentSettings(merchantId);
    if (settings == null) return null;
    
    return settings.paymentMethods.firstWhere(
      (method) => method.type == type,
      orElse: () => MerchantPaymentMethod(
        type: type,
        isEnabled: false,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // تحديث الحد الأدنى للطلب
  Future<bool> updateMinimumOrderSettings(
    String merchantId, {
    required bool requireMinimumOrder,
    double? minimumOrderAmount,
  }) async {
    try {
      final settings = await getMerchantPaymentSettings(merchantId);
      if (settings == null) {
        await createDefaultPaymentSettings(merchantId);
        return updateMinimumOrderSettings(
          merchantId,
          requireMinimumOrder: requireMinimumOrder,
          minimumOrderAmount: minimumOrderAmount,
        );
      }

      final updatedSettings = settings.copyWith(
        requireMinimumOrder: requireMinimumOrder,
        minimumOrderAmount: minimumOrderAmount,
        updatedAt: DateTime.now(),
      );

      return await updateMerchantPaymentSettings(updatedSettings);
    } catch (e) {
      print('Error updating minimum order settings: $e');
      return false;
    }
  }

  // الحصول على إحصائيات وسائل الدفع للتاجر
  Future<Map<String, dynamic>> getPaymentMethodsStats(String merchantId) async {
    final settings = await getMerchantPaymentSettings(merchantId);
    if (settings == null) {
      return {
        'totalMethods': 0,
        'enabledMethods': 0,
        'automaticMethods': 0,
        'categories': <String, int>{},
      };
    }

    final enabledMethods = settings.enabledPaymentMethods;
    final automaticMethods = settings.automaticPaymentMethods;
    final categories = <String, int>{};

    for (final method in enabledMethods) {
      final category = _getPaymentMethodCategory(method.type);
      categories[category] = (categories[category] ?? 0) + 1;
    }

    return {
      'totalMethods': settings.paymentMethods.length,
      'enabledMethods': enabledMethods.length,
      'automaticMethods': automaticMethods.length,
      'categories': categories,
    };
  }

  String _getPaymentMethodCategory(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.visa:
      case PaymentMethodType.mastercard:
      case PaymentMethodType.americanExpress:
        return 'بطاقات ائتمانية';
      case PaymentMethodType.stcPay:
      case PaymentMethodType.urPay:
      case PaymentMethodType.vodafoneCash:
      case PaymentMethodType.etisalatCash:
      case PaymentMethodType.orangeCash:
      case PaymentMethodType.applePay:
      case PaymentMethodType.samsungPay:
      case PaymentMethodType.paypal:
      case PaymentMethodType.appWallet:
        return 'محافظ رقمية';
      case PaymentMethodType.cashOnDelivery:
        return 'نقدي';
      case PaymentMethodType.bankTransfer:
        return 'تحويل بنكي';
    }
  }

  // حذف إعدادات الدفع لتاجر
  Future<bool> deleteMerchantPaymentSettings(String merchantId) async {
    try {
      await _paymentSettingsCollection.doc(merchantId).delete();
      return true;
    } catch (e) {
      print('Error deleting merchant payment settings: $e');
      return false;
    }
  }

  // ربط إعدادات الدفع بالتاجر في نموذج المرشانت
  Future<void> linkPaymentSettingsToMerchant(String merchantId) async {
    try {
      // التأكد من وجود إعدادات دفع للتاجر
      final paymentSettings = await getMerchantPaymentSettings(merchantId);
      if (paymentSettings == null) {
        await createDefaultPaymentSettings(merchantId);
      }
      
      // تحديث نموذج التاجر لربط معرف إعدادات الدفع
      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(merchantId)
          .update({'paymentSettingsId': merchantId});
    } catch (e) {
      throw Exception('فشل في ربط إعدادات الدفع بالتاجر: $e');
    }
  }

  // الحصول على إعدادات الدفع للمنتج (من خلال معرف التاجر)
  Future<MerchantPaymentSettings?> getPaymentSettingsForProduct(String productMerchantId) async {
    return getMerchantPaymentSettings(productMerchantId);
  }

  // التحقق من دعم وسيلة دفع معينة لتاجر
  Future<bool> isPaymentMethodSupported(String merchantId, PaymentMethodType paymentMethod) async {
    final methods = await getEnabledPaymentMethods(merchantId);
    return methods.any((method) => method.type == paymentMethod && method.isEnabled);
  }

  // الحصول على جميع التجار الذين يدعمون وسيلة دفع معينة
  Future<List<String>> getMerchantsSupportingPaymentMethod(List<String> merchantIds, PaymentMethodType paymentMethod) async {
    final supportedMerchants = <String>[];
    
    for (final merchantId in merchantIds) {
      final isSupported = await isPaymentMethodSupported(merchantId, paymentMethod);
      if (isSupported) {
        supportedMerchants.add(merchantId);
      }
    }
    
    return supportedMerchants;
  }
}
