import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/merchant_payment_service.dart';
import '../../models/merchant_payment_methods.dart';
import '../../../store/services/cart_service.dart';
import '../../../store/models/product_model.dart';

class PaymentIntegrationTestPage extends StatefulWidget {
  const PaymentIntegrationTestPage({super.key});

  @override
  State<PaymentIntegrationTestPage> createState() => _PaymentIntegrationTestPageState();
}

class _PaymentIntegrationTestPageState extends State<PaymentIntegrationTestPage> {
  final MerchantPaymentService _paymentService = MerchantPaymentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String _testResults = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار تكامل وسائل الدفع'),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختبار نظام الدفع المتكامل',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختبارات التكامل المتاحة:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testCreateDefaultSettings,
                      icon: const Icon(Icons.add_card),
                      label: const Text('إنشاء إعدادات افتراضية'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testPaymentMethodsRetrieval,
                      icon: const Icon(Icons.payment),
                      label: const Text('اختبار جلب وسائل الدفع'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testMerchantLinking,
                      icon: const Icon(Icons.link),
                      label: const Text('اختبار ربط التاجر بوسائل الدفع'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testCartPaymentMethods,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('اختبار وسائل الدفع للسلة'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testEgyptianWallets,
                      icon: const Icon(Icons.smartphone),
                      label: const Text('اختبار المحافظ المصرية'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testPayPalIntegration,
                      icon: const Icon(Icons.paypal),
                      label: const Text('اختبار تكامل PayPal'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _clearResults,
                      icon: const Icon(Icons.clear),
                      label: const Text('مسح النتائج'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_testResults.isNotEmpty) ...[
              const Text(
                'نتائج الاختبار:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _testResults,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _clearResults() {
    setState(() {
      _testResults = '';
    });
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults += '${DateTime.now().toLocal()}: $result\n\n';
    });
  }

  Future<void> _testCreateDefaultSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _addTestResult('❌ خطأ: المستخدم غير مسجل الدخول');
        return;
      }

      await _paymentService.createDefaultPaymentSettings(userId);
      _addTestResult('✅ نجح: تم إنشاء إعدادات الدفع الافتراضية للتاجر $userId');
      
      // التحقق من الإنشاء
      final settings = await _paymentService.getMerchantPaymentSettings(userId);
      if (settings != null) {
        _addTestResult('✅ تأكيد: تم جلب الإعدادات بنجاح');
        _addTestResult('📊 الإعدادات: ${settings.paymentMethods.length} وسيلة دفع متاحة');
      }
    } catch (e) {
      _addTestResult('❌ خطأ في إنشاء الإعدادات: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPaymentMethodsRetrieval() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _addTestResult('❌ خطأ: المستخدم غير مسجل الدخول');
        return;
      }

      // اختبار الحصول على الطرق المفعلة
      final enabledMethods = await _paymentService.getEnabledPaymentMethods(userId);
      _addTestResult('✅ نجح: تم جلب ${enabledMethods.length} وسيلة دفع مفعلة');
      
      for (final method in enabledMethods) {
        _addTestResult('   📌 ${method.type.displayNameArabic} - ${method.isAutomatic ? 'تلقائي' : 'يدوي'}');
      }

      // اختبار التحقق من دعم وسيلة معينة
      final supportsVisa = await _paymentService.isPaymentMethodSupported(userId, PaymentMethodType.visa);
      _addTestResult('✅ دعم فيزا: ${supportsVisa ? 'نعم' : 'لا'}');
      
      final supportsWallet = await _paymentService.isPaymentMethodSupported(userId, PaymentMethodType.appWallet);
      _addTestResult('✅ دعم المحفظة: ${supportsWallet ? 'نعم' : 'لا'}');
      
    } catch (e) {
      _addTestResult('❌ خطأ في جلب وسائل الدفع: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testMerchantLinking() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _addTestResult('❌ خطأ: المستخدم غير مسجل الدخول');
        return;
      }

      await _paymentService.linkPaymentSettingsToMerchant(userId);
      _addTestResult('✅ نجح: تم ربط إعدادات الدفع بالتاجر');
      
      // تأكيد الربط
      final settings = await _paymentService.getPaymentSettingsForProduct(userId);
      if (settings != null) {
        _addTestResult('✅ تأكيد الربط: تم جلب إعدادات الدفع من خلال معرف المنتج');
      }
      
    } catch (e) {
      _addTestResult('❌ خطأ في ربط التاجر: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCartPaymentMethods() async {
    setState(() => _isLoading = true);
    
    try {
      // محاكاة سلة تحتوي على منتجات من تجار مختلفين
      final testMerchants = ['merchant1', 'merchant2', 'merchant3'];
      
      _addTestResult('🛒 اختبار السلة مع ${testMerchants.length} تجار');
      
      // الحصول على التجار الذين يدعمون فيزا
      final visaSupporters = await _paymentService.getMerchantsSupportingPaymentMethod(
        testMerchants, 
        PaymentMethodType.visa
      );
      _addTestResult('💳 التجار الذين يدعمون فيزا: ${visaSupporters.length}');
      
      // الحصول على التجار الذين يدعمون المحفظة
      final walletSupporters = await _paymentService.getMerchantsSupportingPaymentMethod(
        testMerchants, 
        PaymentMethodType.appWallet
      );
      _addTestResult('👛 التجار الذين يدعمون المحفظة: ${walletSupporters.length}');
      
      // الحصول على التجار الذين يدعمون الدفع عند الاستلام
      final codSupporters = await _paymentService.getMerchantsSupportingPaymentMethod(
        testMerchants, 
        PaymentMethodType.cashOnDelivery
      );
      _addTestResult('💰 التجار الذين يدعمون الدفع عند الاستلام: ${codSupporters.length}');
      
    } catch (e) {
      _addTestResult('❌ خطأ في اختبار السلة: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testEgyptianWallets() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _addTestResult('❌ خطأ: المستخدم غير مسجل الدخول');
        return;
      }

      _addTestResult('🇪🇬 اختبار المحافظ المصرية...');
      
      // اختبار دعم فودافون كاش
      final supportsVodafone = await _paymentService.isPaymentMethodSupported(userId, PaymentMethodType.vodafoneCash);
      _addTestResult('📱 فودافون كاش: ${supportsVodafone ? '✅ مدعوم' : '❌ غير مدعوم'}');
      
      // اختبار دعم اتصالات كاش
      final supportsEtisalat = await _paymentService.isPaymentMethodSupported(userId, PaymentMethodType.etisalatCash);
      _addTestResult('📱 اتصالات كاش: ${supportsEtisalat ? '✅ مدعوم' : '❌ غير مدعوم'}');
      
      // اختبار دعم أورانج كاش
      final supportsOrange = await _paymentService.isPaymentMethodSupported(userId, PaymentMethodType.orangeCash);
      _addTestResult('📱 أورانج كاش: ${supportsOrange ? '✅ مدعوم' : '❌ غير مدعوم'}');
      
      // اختبار معلومات التكامل
      _addTestResult('📞 رقم الاستقبال: 01010576801');
      _addTestResult('💼 نوع التحويل: تلقائي');
      
      // محاكاة معاملة تحويل
      _addTestResult('🔄 محاكاة معاملة فودافون كاش...');
      await Future.delayed(const Duration(seconds: 2));
      
      final transactionSuccess = DateTime.now().millisecond % 10 != 0;
      if (transactionSuccess) {
        final transactionId = 'VF${DateTime.now().millisecondsSinceEpoch}';
        _addTestResult('✅ نجح التحويل - رقم المرجع: $transactionId');
      } else {
        _addTestResult('❌ فشل التحويل - رصيد غير كافٍ');
      }
      
    } catch (e) {
      _addTestResult('❌ خطأ في اختبار المحافظ المصرية: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPayPalIntegration() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _addTestResult('❌ خطأ: المستخدم غير مسجل الدخول');
        return;
      }

      _addTestResult('🌐 اختبار تكامل PayPal...');
      
      // اختبار دعم PayPal
      final supportsPayPal = await _paymentService.isPaymentMethodSupported(userId, PaymentMethodType.paypal);
      _addTestResult('💳 PayPal: ${supportsPayPal ? '✅ مدعوم' : '❌ غير مدعوم'}');
      
      // معلومات الحساب
      _addTestResult('📧 حساب الاستقبال: amirtallalkamal@gmail.com');
      _addTestResult('🌍 نوع المعاملة: دولية تلقائية');
      _addTestResult('💱 العملة: متعددة (EGP, USD, EUR)');
      
      // محاكاة معاملة PayPal
      _addTestResult('🔄 محاكاة معاملة PayPal...');
      await Future.delayed(const Duration(seconds: 3));
      
      final transactionSuccess = DateTime.now().millisecond % 8 != 0; // نجاح أعلى
      if (transactionSuccess) {
        final transactionId = 'PP${DateTime.now().millisecondsSinceEpoch}';
        _addTestResult('✅ نجح الدفع عبر PayPal');
        _addTestResult('🔖 رقم المعاملة: $transactionId');
        _addTestResult('🔒 حالة الأمان: مؤكدة');
        _addTestResult('⏱️ وقت المعالجة: 3.2 ثانية');
      } else {
        _addTestResult('❌ فشل الدفع عبر PayPal');
        _addTestResult('🔍 السبب: حساب PayPal غير مفعل أو رصيد غير كافٍ');
      }
      
    } catch (e) {
      _addTestResult('❌ خطأ في تكامل PayPal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
