import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:provider/provider.dart';
import 'package:sumi/features/store/presentation/pages/order_confirmation_page.dart';
import 'package:sumi/features/store/services/cart_service.dart';
import 'package:sumi/features/auth/services/address_service.dart';
import 'package:sumi/features/wallet/services/wallet_service.dart';
import 'package:sumi/features/merchant/services/merchant_payment_service.dart';
import 'package:sumi/features/merchant/models/merchant_payment_methods.dart';
import 'package:sumi/features/merchant/models/payment_integration_config.dart';

class CheckoutStepperPage extends StatefulWidget {
  const CheckoutStepperPage({super.key});

  @override
  State<CheckoutStepperPage> createState() => _CheckoutStepperPageState();
}

class _CheckoutStepperPageState extends State<CheckoutStepperPage> {
  int _currentStep = 0;
  final _shippingFormKey = GlobalKey<FormState>();

  // Shipping details
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Payment details
  String _cardNumber = '';
  String _expiryDate = '';
  String _cardHolderName = '';
  String _cvvCode = '';
  final _paymentFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الطلب'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ExpansionPanelList(
          elevation: 0,
          expandedHeaderPadding: const EdgeInsets.symmetric(vertical: 8),
          expansionCallback: (int index, bool isExpanded) {
            // Only allow expanding sequentially
            if (index == 0 || _shippingFormKey.currentState!.validate()) {
              setState(() {
                _currentStep = isExpanded ? -1 : index; // Toggle panel
              });
            }
          },
          animationDuration: const Duration(milliseconds: 500),
          children: [
            _buildShippingPanel(context),
            _buildPaymentPanel(context),
            _buildSummaryPanel(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  ExpansionPanel _buildShippingPanel(BuildContext context) {
    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return _buildPanelHeader(context, 'عنوان الشحن', Icons.local_shipping_outlined, 0);
      },
      body: _buildShippingSection(),
      isExpanded: _currentStep == 0,
      canTapOnHeader: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  ExpansionPanel _buildPaymentPanel(BuildContext context) {
    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return _buildPanelHeader(context, 'طريقة الدفع', Icons.payment_outlined, 1);
      },
      body: _buildPaymentSection(),
      isExpanded: _currentStep == 1,
      canTapOnHeader: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
  
  ExpansionPanel _buildSummaryPanel(BuildContext context) {
    return ExpansionPanel(
      headerBuilder: (BuildContext context, bool isExpanded) {
        return _buildPanelHeader(context, 'ملخص الطلب', Icons.receipt_long_outlined, 2);
      },
      body: _buildConfirmSection(),
      isExpanded: _currentStep == 2,
      canTapOnHeader: true,
       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  ListTile _buildPanelHeader(BuildContext context, String title, IconData icon, int stepIndex) {
    final isCompleted = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;
    return ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle : icon,
        color: isCompleted ? Colors.green : (isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          color: isCurrent ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  Widget _buildShippingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Form(
        key: _shippingFormKey,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final addresses = await AddressService().getAddressesOnce();
                  if (!mounted) return;
                  if (addresses.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا توجد عناوين محفوظة')),
                    );
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: addresses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final a = addresses[i];
                          final line = '${a.addressLine1}${a.addressLine2 != null ? ', ' + a.addressLine2! : ''}, ${a.city}, ${a.country}';
                          return ListTile(
                            leading: Icon(a.isDefault ? Icons.star : Icons.location_on_outlined, color: a.isDefault ? Colors.amber : null),
                            title: Text(a.fullName),
                            subtitle: Text(line),
                            onTap: () {
                              setState(() {
                                _nameController.text = a.fullName;
                                _addressController.text = line;
                                _phoneController.text = a.phoneNumber;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  );
                },
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('اختيار عنوان محفوظ'),
              ),
            ),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
              validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              validator: (value) => value!.isEmpty ? 'الحقل مطلوب' : null,
            ),
            const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('متابعة إلى الدفع'),
                onPressed: () async {
                  // إذا كان المستخدم لديه عنوان افتراضي، املأ الحقول تلقائياً أولاً
                  if (_nameController.text.isEmpty && _addressController.text.isEmpty && _phoneController.text.isEmpty) {
                    final def = await AddressService().getDefaultAddress();
                    if (def != null) {
                      setState(() {
                        _nameController.text = def.fullName;
                        _addressController.text = '${def.addressLine1}${def.addressLine2 != null ? ', ' + def.addressLine2! : ''}, ${def.city}, ${def.country}';
                        _phoneController.text = def.phoneNumber;
                      });
                    }
                  }
                  if (_shippingFormKey.currentState!.validate()) {
                    setState(() => _currentStep = 1);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    final cart = Provider.of<CartService>(context);
    final merchantIds = cart.merchantIds;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (merchantIds.isNotEmpty) ...[
            const Text(
              'وسائل الدفع المتاحة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // عرض وسائل الدفع لكل التجار
            FutureBuilder<Map<String, List<MerchantPaymentMethod>>>(
              future: _getAvailablePaymentMethods(merchantIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return _buildDefaultPaymentOptions();
                }

                final merchantPaymentMethods = snapshot.data!;
                final commonPaymentMethods = _findCommonPaymentMethods(merchantPaymentMethods);

                if (commonPaymentMethods.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد وسائل دفع مشتركة بين التجار في السلة',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildPaymentMethodsList(commonPaymentMethods),
                    if (commonPaymentMethods.any((method) => 
                        method.type == PaymentMethodType.visa || 
                        method.type == PaymentMethodType.mastercard)) ...[
                      const SizedBox(height: 16),
                      _buildCreditCardForm(),
                    ],
                  ],
                );
              },
            ),
          ] else
            _buildDefaultPaymentOptions(),
        ],
      ),
    );
  }

  // الحصول على وسائل الدفع المتاحة لكل التجار
  Future<Map<String, List<MerchantPaymentMethod>>> _getAvailablePaymentMethods(List<String> merchantIds) async {
    final paymentService = MerchantPaymentService();
    final result = <String, List<MerchantPaymentMethod>>{};

    for (final merchantId in merchantIds) {
      final methods = await paymentService.getEnabledPaymentMethods(merchantId);
      if (methods.isNotEmpty) {
        result[merchantId] = methods;
      }
    }

    return result;
  }

  // إيجاد وسائل الدفع المشتركة بين جميع التجار
  List<MerchantPaymentMethod> _findCommonPaymentMethods(Map<String, List<MerchantPaymentMethod>> merchantPaymentMethods) {
    if (merchantPaymentMethods.isEmpty) return [];
    
    // أخذ أول تاجر كمرجع
    final firstMerchant = merchantPaymentMethods.values.first;
    final commonMethods = <MerchantPaymentMethod>[];

    for (final method in firstMerchant) {
      // التحقق إذا كانت وسيلة الدفع متوفرة عند جميع التجار
      final isCommon = merchantPaymentMethods.values.every((merchantMethods) =>
          merchantMethods.any((m) => m.type == method.type && m.isEnabled));

      if (isCommon) {
        commonMethods.add(method);
      }
    }

    return commonMethods;
  }

  // بناء قائمة وسائل الدفع
  Widget _buildPaymentMethodsList(List<MerchantPaymentMethod> paymentMethods) {
    return Column(
      children: paymentMethods.map((method) => _buildPaymentMethodTile(method)).toList(),
    );
  }

  // بناء عنصر وسيلة دفع واحدة
  Widget _buildPaymentMethodTile(MerchantPaymentMethod method) {
    final cart = Provider.of<CartService>(context, listen: false);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E9EC)),
        color: Colors.white,
      ),
      child: ListTile(
        leading: Icon(_getPaymentMethodIcon(method.type)),
        title: Text(method.type.displayNameArabic),
        subtitle: method.isAutomatic ? const Text('دفع تلقائي') : const Text('يحتاج موافقة التاجر'),
        trailing: _buildPaymentButton(method, cart),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // بناء زر الدفع حسب نوع وسيلة الدفع
  Widget _buildPaymentButton(MerchantPaymentMethod method, CartService cart) {
    switch (method.type) {
      case PaymentMethodType.appWallet:
        return _buildWalletPaymentButton(cart);
      case PaymentMethodType.cashOnDelivery:
        return _buildCashOnDeliveryButton();
      case PaymentMethodType.visa:
      case PaymentMethodType.mastercard:
      case PaymentMethodType.americanExpress:
        return _buildCreditCardButton();
      case PaymentMethodType.vodafoneCash:
      case PaymentMethodType.etisalatCash:
      case PaymentMethodType.orangeCash:
        return _buildMobileWalletButton(method.type, cart);
      case PaymentMethodType.paypal:
        return _buildPayPalButton(cart);
      default:
        return _buildGenericPaymentButton(method.type.displayNameArabic);
    }
  }

  // زر الدفع بالمحفظة
  Widget _buildWalletPaymentButton(CartService cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<double>(
                  future: WalletService().getBalance(),
                  builder: (context, snapshot) {
            final balance = snapshot.data ?? 0;
            return Text(
              '${balance.toStringAsFixed(2)} ر.س',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            );
          },
        ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: () => _payWithWallet(cart),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 32),
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: const Text('ادفع بالمحفظة'),
        ),
      ],
    );
  }

  // زر الدفع عند الاستلام
  Widget _buildCashOnDeliveryButton() {
    return FilledButton(
      onPressed: () {
        setState(() => _currentStep = 2);
      },
      style: FilledButton.styleFrom(
        minimumSize: const Size(100, 32),
        textStyle: const TextStyle(fontSize: 12),
        backgroundColor: Colors.green,
      ),
      child: const Text('اختر هذه الطريقة'),
    );
  }

  // زر الدفع بالبطاقة الائتمانية المحسن
  Widget _buildCreditCardButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'معالجة آمنة وتلقائية',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: () => _processCreditCardPayment(),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 32),
            textStyle: const TextStyle(fontSize: 12),
            backgroundColor: const Color(0xFF1565C0),
          ),
          child: const Text('ادفع بالبطاقة'),
        ),
      ],
    );
  }

  // زر دفع المحافظ المصرية
  Widget _buildMobileWalletButton(PaymentMethodType walletType, CartService cart) {
    Color buttonColor;
    String walletName;
    
    switch (walletType) {
      case PaymentMethodType.vodafoneCash:
        buttonColor = Colors.red;
        walletName = 'فودافون كاش';
        break;
      case PaymentMethodType.etisalatCash:
        buttonColor = Colors.green;
        walletName = 'اتصالات كاش';
        break;
      case PaymentMethodType.orangeCash:
        buttonColor = Colors.orange;
        walletName = 'أورانج كاش';
        break;
      default:
        buttonColor = Colors.blue;
        walletName = walletType.displayNameArabic;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'تحويل تلقائي على: 01010576801',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        FilledButton(
          onPressed: () => _payWithMobileWallet(walletType, cart),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 32),
            textStyle: const TextStyle(fontSize: 12),
            backgroundColor: buttonColor,
          ),
          child: Text('ادفع بـ$walletName'),
        ),
      ],
    );
  }

  // زر دفع PayPal
  Widget _buildPayPalButton(CartService cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'تحويل تلقائي على: amirtallalkamal@gmail.com',
          style: TextStyle(fontSize: 10, color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
                FilledButton(
          onPressed: () => _payWithPayPal(cart),
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 32),
            textStyle: const TextStyle(fontSize: 12),
            backgroundColor: const Color(0xFF003087),
          ),
          child: const Text('ادفع بـPayPal'),
        ),
      ],
    );
  }

  // زر عام لوسائل الدفع الأخرى
  Widget _buildGenericPaymentButton(String methodName) {
    return FilledButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('سيتم تفعيل $methodName قريباً')),
        );
      },
      style: FilledButton.styleFrom(
        minimumSize: const Size(100, 32),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: const Text('اختر'),
    );
  }

  // دفع بالمحفظة
  Future<void> _payWithWallet(CartService cart) async {
    final total = cart.totalPrice;
                    final balance = await WalletService().getBalance();
    
                    if (balance >= total) {
                      await WalletService().debit(amount: total, title: 'شراء منتجات');
                      if (mounted) setState(() => _currentStep = 2);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('الرصيد غير كافٍ. المتاح: ${balance.toStringAsFixed(2)} ر.س'),
          ),
        );
      }
    }
  }

  // دفع بالمحافظ المصرية
  Future<void> _payWithMobileWallet(PaymentMethodType walletType, CartService cart) async {
    final total = cart.totalPrice;
    final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

    // إظهار dialog للمعالجة
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('جاري المعالجة عبر ${walletType.displayNameArabic}...'),
            const SizedBox(height: 8),
            const Text(
              'سيتم تحويل المبلغ تلقائياً على الرقم 01010576801',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      // محاكاة معالجة الدفع
      await Future.delayed(const Duration(seconds: 3));
      
      // محاكاة نجاح الدفع
      final isSuccess = DateTime.now().millisecond % 10 != 0;
      
      if (mounted) {
        Navigator.of(context).pop(); // إغلاق dialog المعالجة
        
        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم الدفع بنجاح عبر ${walletType.displayNameArabic}!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _currentStep = 2);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ فشل الدفع عبر ${walletType.displayNameArabic}. يرجى المحاولة مرة أخرى.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في المعالجة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // دفع بـ PayPal
  Future<void> _payWithPayPal(CartService cart) async {
    final total = cart.totalPrice;
    final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

    // إظهار dialog للمعالجة
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('جاري المعالجة عبر PayPal...'),
            const SizedBox(height: 8),
            const Text(
              'سيتم تحويل المبلغ على: amirtallalkamal@gmail.com',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(seconds: 4));
      
      final isSuccess = DateTime.now().millisecond % 8 != 0; // نجاح أعلى لـ PayPal
      
      if (mounted) {
        Navigator.of(context).pop();
        
        if (isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم الدفع بنجاح عبر PayPal!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() => _currentStep = 2);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ فشل الدفع عبر PayPal. يرجى التحقق من حسابك.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في PayPal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // معالجة دفع البطاقة الائتمانية المحسن
  Future<void> _processCreditCardPayment() async {
    // التحقق من وجود بيانات البطاقة
    if (_cardNumber.isEmpty || _expiryDate.isEmpty || _cardHolderName.isEmpty || _cvvCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء بيانات البطاقة أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cart = Provider.of<CartService>(context, listen: false);
    final total = cart.totalPrice;
    final orderId = 'ORDER_${DateTime.now().millisecondsSinceEpoch}';

    // إظهار dialog للمعالجة
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('جاري معالجة الدفع...'),
            const SizedBox(height: 8),
            Text(
              'المبلغ: ${total.toStringAsFixed(2)} ر.س',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'البطاقة: **** **** **** ${_cardNumber.length > 4 ? _cardNumber.substring(_cardNumber.length - 4) : _cardNumber}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      // محاكاة معالجة البطاقة الائتمانية (تستغرق وقت أطول)
      await Future.delayed(const Duration(seconds: 5));
      
      // محاكاة نجاح عالي للبطاقات الائتمانية (95%)
      final isSuccess = DateTime.now().millisecond % 20 != 0;
      
      if (mounted) {
        Navigator.of(context).pop(); // إغلاق dialog المعالجة
        
        if (isSuccess) {
          // إنشاء رقم مرجعي للمعاملة
          final transactionRef = 'CC${DateTime.now().millisecondsSinceEpoch}';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✅ تم الدفع بنجاح!'),
                  Text('رقم المرجع: $transactionRef'),
                  Text('المبلغ: ${total.toStringAsFixed(2)} ر.س'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          setState(() => _currentStep = 2);
        } else {
          // أسباب مختلفة للرفض
          final failureReasons = [
            'تم رفض البطاقة من البنك المصدر',
            'رصيد البطاقة غير كافٍ',
            'البطاقة منتهية الصلاحية',
            'كود الحماية غير صحيح',
            'البطاقة محظورة للمعاملات الإلكترونية',
          ];
          final reason = failureReasons[DateTime.now().millisecond % failureReasons.length];
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('❌ فشل في معالجة الدفع'),
                  Text('السبب: $reason'),
                  const Text('يرجى التحقق من بيانات البطاقة والمحاولة مرة أخرى'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 7),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في معالجة البطاقة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // أيقونات وسائل الدفع
  IconData _getPaymentMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.visa:
      case PaymentMethodType.mastercard:
      case PaymentMethodType.americanExpress:
        return Icons.credit_card;
      case PaymentMethodType.appWallet:
        return Icons.account_balance_wallet;
      case PaymentMethodType.cashOnDelivery:
        return Icons.local_atm;
      case PaymentMethodType.stcPay:
      case PaymentMethodType.urPay:
        return Icons.phone_android;
      case PaymentMethodType.vodafoneCash:
        return Icons.smartphone_outlined;
      case PaymentMethodType.etisalatCash:
        return Icons.phone_iphone;
      case PaymentMethodType.orangeCash:
        return Icons.mobile_friendly;
      case PaymentMethodType.applePay:
        return Icons.apple;
      case PaymentMethodType.samsungPay:
        return Icons.smartphone;
      case PaymentMethodType.paypal:
        return Icons.paypal;
      case PaymentMethodType.bankTransfer:
        return Icons.account_balance;
    }
  }

  // نموذج البطاقة الائتمانية
  Widget _buildCreditCardForm() {
    return Column(
      children: [
          CreditCardWidget(
            cardNumber: _cardNumber,
            expiryDate: _expiryDate,
            cardHolderName: _cardHolderName,
            cvvCode: _cvvCode,
            showBackView: false,
            onCreditCardWidgetChange: (brand) {},
            chipColor: Colors.amber,
            cardBgColor: Theme.of(context).colorScheme.primary,
          ),
          CreditCardForm(
            formKey: _paymentFormKey,
            cardNumber: _cardNumber,
            expiryDate: _expiryDate,
            cardHolderName: _cardHolderName,
            cvvCode: _cvvCode,
            onCreditCardModelChange: (model) {
              setState(() {
                _cardNumber = model.cardNumber;
                _expiryDate = model.expiryDate;
                _cardHolderName = model.cardHolderName;
                _cvvCode = model.cvvCode;
              });
            },
            inputConfiguration: const InputConfiguration(
              cardNumberDecoration: InputDecoration(labelText: 'رقم البطاقة', hintText: 'xxxx xxxx xxxx xxxx'),
              expiryDateDecoration: InputDecoration(labelText: 'تاريخ الانتهاء', hintText: 'MM/YY'),
              cvvCodeDecoration: InputDecoration(labelText: 'CVV', hintText: 'xxx'),
              cardHolderDecoration: InputDecoration(labelText: 'اسم حامل البطاقة'),
            ),
          ),
           const SizedBox(height: 16),
           ElevatedButton(
              child: const Text('متابعة إلى الملخص'),
              onPressed: () {
                 if (_paymentFormKey.currentState!.validate()) {
                  setState(() => _currentStep = 2);
                 }
              },
            ),
        ],
    );
  }

  // بناء خيارات الدفع الافتراضية (عندما لا توجد إعدادات من التجار)
  Widget _buildDefaultPaymentOptions() {
    final cart = Provider.of<CartService>(context, listen: false);
    
    return Column(
      children: [
        const Text(
          'وسائل الدفع الافتراضية',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // محفظة التطبيق (دائماً متاحة)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E9EC)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Color(0xFF9A46D7)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('محفظة التطبيق'),
              ),
              _buildWalletPaymentButton(cart),
            ],
          ),
        ),
        // الدفع عند الاستلام (دائماً متاح)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E9EC)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.local_atm, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('الدفع عند الاستلام'),
              ),
              _buildCashOnDeliveryButton(),
            ],
          ),
        ),
        
        // المحافظ المصرية الافتراضية
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E9EC)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.smartphone_outlined, color: Colors.red),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('فودافون كاش'),
              ),
              _buildMobileWalletButton(PaymentMethodType.vodafoneCash, cart),
            ],
          ),
        ),
        
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E9EC)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_iphone, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('اتصالات كاش'),
              ),
              _buildMobileWalletButton(PaymentMethodType.etisalatCash, cart),
            ],
          ),
        ),
        
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E9EC)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.mobile_friendly, color: Colors.orange),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('أورانج كاش'),
              ),
              _buildMobileWalletButton(PaymentMethodType.orangeCash, cart),
            ],
          ),
        ),
        
        // PayPal افتراضي
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E9EC)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.paypal, color: Color(0xFF003087)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('PayPal'),
              ),
              _buildPayPalButton(cart),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmSection() {
    final cart = context.watch<CartService>();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المنتجات (${cart.items.length})', style: theme.textTheme.bodyLarge),
              Text('${cart.totalPrice.toStringAsFixed(2)} ر.س', style: theme.textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الشحن', style: theme.textTheme.bodyLarge),
              Text('مجاني', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.green)),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الإجمالي', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text('${cart.totalPrice.toStringAsFixed(2)} ر.س', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final cart = context.watch<CartService>();
    // The button is only active in the summary step.
    final bool canSubmit = _currentStep == 2 &&
                           _shippingFormKey.currentState?.validate() == true &&
                           _paymentFormKey.currentState?.validate() == true;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: FilledButton.icon(
          icon: const Icon(Icons.lock_outline),
          label: Text('تأكيد الطلب والدفع (${cart.totalPrice.toStringAsFixed(2)} ر.س)'),
          onPressed: canSubmit ? _submitOrder : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  void _submitOrder() async {
    // Final validation check
    if (_shippingFormKey.currentState!.validate() && _paymentFormKey.currentState!.validate()) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()));

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Provider.of<CartService>(context, listen: false).clearCart();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OrderConfirmationPage()),
          (route) => false,
        );
      }
    }
  }
} 