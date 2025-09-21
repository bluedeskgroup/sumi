import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/merchant_payment_methods.dart';
import '../../services/merchant_payment_service.dart';

class PaymentMethodsSettingsPage extends StatefulWidget {
  const PaymentMethodsSettingsPage({super.key});

  @override
  State<PaymentMethodsSettingsPage> createState() => _PaymentMethodsSettingsPageState();
}

class _PaymentMethodsSettingsPageState extends State<PaymentMethodsSettingsPage> {
  final MerchantPaymentService _paymentService = MerchantPaymentService();
  
  MerchantPaymentSettings? _paymentSettings;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // إعدادات الحد الأدنى للطلب
  bool _requireMinimumOrder = false;
  final TextEditingController _minimumAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentSettings();
  }

  @override
  void dispose() {
    _minimumAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _paymentService.getCurrentMerchantPaymentSettings();
      
      if (settings != null) {
        setState(() {
          _paymentSettings = settings;
          _requireMinimumOrder = settings.requireMinimumOrder;
          _minimumAmountController.text = 
              settings.minimumOrderAmount?.toString() ?? '';
        });
      } else {
        // إنشاء إعدادات افتراضية
        // الحصول على معرف التاجر الحالي من FirebaseAuth مباشرة
        final auth = FirebaseAuth.instance;
        if (auth.currentUser != null) {
          await _paymentService.createDefaultPaymentSettings(auth.currentUser!.uid);
          await _loadPaymentSettings();
          return;
        }
      }
    } catch (e) {
      print('Error loading payment settings: $e');
      _showErrorSnackBar('فشل في تحميل إعدادات الدفع');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _updatePaymentMethod(
    PaymentMethodType type,
    bool isEnabled, {
    bool? isAutomatic,
  }) async {
    if (_paymentSettings == null) return;

    setState(() => _isSaving = true);

    try {
      final success = await _paymentService.updatePaymentMethod(
        _paymentSettings!.merchantId,
        type,
        isEnabled,
        isAutomatic: isAutomatic,
      );

      if (success) {
        await _loadPaymentSettings();
        _showSuccessSnackBar('تم تحديث إعدادات الدفع بنجاح');
      } else {
        _showErrorSnackBar('فشل في تحديث إعدادات الدفع');
      }
    } catch (e) {
      print('Error updating payment method: $e');
      _showErrorSnackBar('حدث خطأ أثناء التحديث');
    }

    setState(() => _isSaving = false);
  }

  Future<void> _updateMinimumOrderSettings() async {
    if (_paymentSettings == null) return;

    setState(() => _isSaving = true);

    try {
      double? minimumAmount;
      if (_requireMinimumOrder && _minimumAmountController.text.isNotEmpty) {
        minimumAmount = double.tryParse(_minimumAmountController.text);
        if (minimumAmount == null || minimumAmount <= 0) {
          _showErrorSnackBar('يرجى إدخال قيمة صحيحة للحد الأدنى للطلب');
          setState(() => _isSaving = false);
          return;
        }
      }

      final success = await _paymentService.updateMinimumOrderSettings(
        _paymentSettings!.merchantId,
        requireMinimumOrder: _requireMinimumOrder,
        minimumOrderAmount: _requireMinimumOrder ? minimumAmount : null,
      );

      if (success) {
        await _loadPaymentSettings();
        _showSuccessSnackBar('تم تحديث إعدادات الحد الأدنى للطلب');
      } else {
        _showErrorSnackBar('فشل في تحديث إعدادات الحد الأدنى');
      }
    } catch (e) {
      print('Error updating minimum order settings: $e');
      _showErrorSnackBar('حدث خطأ أثناء التحديث');
    }

    setState(() => _isSaving = false);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('وسائل الدفع'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0.5,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _paymentSettings == null
                ? _buildErrorState()
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildStatsCard(),
                        _buildMinimumOrderSection(),
                        _buildPaymentMethodsSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'فشل في تحميل إعدادات الدفع',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPaymentSettings,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final enabledCount = _paymentSettings?.enabledPaymentMethods.length ?? 0;
    final totalCount = _paymentSettings?.paymentMethods.length ?? 0;
    final automaticCount = _paymentSettings?.automaticPaymentMethods.length ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'إحصائيات وسائل الدفع',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'المفعلة',
                  '$enabledCount',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'التلقائية',
                  '$automaticCount',
                  Colors.blue,
                  Icons.flash_on,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'الإجمالي',
                  '$totalCount',
                  Colors.orange,
                  Icons.payment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimumOrderSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'الحد الأدنى للطلب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('تطبيق حد أدنى للطلب'),
            subtitle: const Text('تحديد أقل مبلغ مطلوب لإتمام الطلب'),
            value: _requireMinimumOrder,
            onChanged: (value) {
              setState(() => _requireMinimumOrder = value);
              _updateMinimumOrderSettings();
            },
          ),
          if (_requireMinimumOrder) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _minimumAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              decoration: const InputDecoration(
                labelText: 'الحد الأدنى (ريال سعودي)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              onChanged: (value) => _updateMinimumOrderSettings(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    if (_paymentSettings == null) return const SizedBox.shrink();

    final methodsByCategory = _paymentSettings!.methodsByCategory;
    final allMethods = _paymentSettings!.paymentMethods;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'وسائل الدفع المتاحة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...PaymentMethodCategory.values.map((category) {
            final categoryMethods = allMethods.where((method) {
              switch (category) {
                case PaymentMethodCategory.creditCards:
                  return [
                    PaymentMethodType.visa,
                    PaymentMethodType.mastercard,
                    PaymentMethodType.americanExpress,
                  ].contains(method.type);
                case PaymentMethodCategory.digitalWallets:
                  return [
                    PaymentMethodType.stcPay,
                    PaymentMethodType.urPay,
                    PaymentMethodType.vodafoneCash,
                    PaymentMethodType.etisalatCash,
                    PaymentMethodType.orangeCash,
                    PaymentMethodType.applePay,
                    PaymentMethodType.samsungPay,
                    PaymentMethodType.paypal,
                    PaymentMethodType.appWallet,
                  ].contains(method.type);
                case PaymentMethodCategory.cash:
                  return method.type == PaymentMethodType.cashOnDelivery;
                case PaymentMethodCategory.bankTransfer:
                  return method.type == PaymentMethodType.bankTransfer;
              }
            }).toList();

            if (categoryMethods.isEmpty) return const SizedBox.shrink();

            return _buildCategorySection(category, categoryMethods);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    PaymentMethodCategory category,
    List<MerchantPaymentMethod> methods,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        ...methods.map((method) => _buildPaymentMethodTile(method)),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildPaymentMethodTile(MerchantPaymentMethod method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: method.isEnabled 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getPaymentMethodIcon(method.type),
              color: method.isEnabled 
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.type.displayNameArabic,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: method.isEnabled ? Colors.black : Colors.grey[600],
                  ),
                ),
                if (method.isEnabled) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: method.isAutomatic 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          method.isAutomatic ? 'تلقائي' : 'يدوي',
                          style: TextStyle(
                            fontSize: 12,
                            color: method.isAutomatic ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: method.isEnabled,
                onChanged: _isSaving 
                    ? null 
                    : (value) => _updatePaymentMethod(method.type, value),
              ),
              if (method.isEnabled && !method.isAutomatic)
                GestureDetector(
                  onTap: _isSaving 
                      ? null 
                      : () => _updatePaymentMethod(
                            method.type, 
                            method.isEnabled,
                            isAutomatic: true,
                          ),
                  child: Text(
                    'جعله تلقائي',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              if (method.isEnabled && method.isAutomatic)
                GestureDetector(
                  onTap: _isSaving 
                      ? null 
                      : () => _updatePaymentMethod(
                            method.type, 
                            method.isEnabled,
                            isAutomatic: false,
                          ),
                  child: Text(
                    'جعله يدوي',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(PaymentMethodCategory category) {
    switch (category) {
      case PaymentMethodCategory.creditCards:
        return Icons.credit_card;
      case PaymentMethodCategory.digitalWallets:
        return Icons.account_balance_wallet;
      case PaymentMethodCategory.cash:
        return Icons.local_atm;
      case PaymentMethodCategory.bankTransfer:
        return Icons.account_balance;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.visa:
      case PaymentMethodType.mastercard:
      case PaymentMethodType.americanExpress:
        return Icons.credit_card;
      case PaymentMethodType.stcPay:
      case PaymentMethodType.urPay:
      case PaymentMethodType.vodafoneCash:
      case PaymentMethodType.etisalatCash:
      case PaymentMethodType.orangeCash:
      case PaymentMethodType.applePay:
      case PaymentMethodType.samsungPay:
      case PaymentMethodType.paypal:
        return Icons.phone_android;
      case PaymentMethodType.appWallet:
        return Icons.account_balance_wallet;
      case PaymentMethodType.cashOnDelivery:
        return Icons.local_atm;
      case PaymentMethodType.bankTransfer:
        return Icons.account_balance;
    }
  }
}
