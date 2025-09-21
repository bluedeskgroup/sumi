import 'package:flutter/material.dart';
import '../models/merchant_payment_methods.dart';
import '../services/merchant_payment_service.dart';

class MerchantPaymentSetupWizard extends StatefulWidget {
  final String merchantId;
  final VoidCallback? onSetupComplete;
  
  const MerchantPaymentSetupWizard({
    super.key,
    required this.merchantId,
    this.onSetupComplete,
  });

  @override
  State<MerchantPaymentSetupWizard> createState() => _MerchantPaymentSetupWizardState();
}

class _MerchantPaymentSetupWizardState extends State<MerchantPaymentSetupWizard> {
  final MerchantPaymentService _paymentService = MerchantPaymentService();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // قائمة وسائل الدفع المختارة
  final Map<PaymentMethodType, bool> _selectedMethods = {};
  
  // إعدادات تفصيلية
  bool _requireMinimumOrder = false;
  double _minimumOrderAmount = 0.0;
  bool _enableAutomaticPayments = true;
  
  final TextEditingController _minimumAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  void _initializeDefaults() {
    // تعيين وسائل الدفع الافتراضية كمفعلة
    _selectedMethods[PaymentMethodType.appWallet] = true;
    _selectedMethods[PaymentMethodType.cashOnDelivery] = true;
    _selectedMethods[PaymentMethodType.visa] = true;
    _selectedMethods[PaymentMethodType.stcPay] = true;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF6B46C1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'إعداد وسائل الدفع',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stepper(
                      currentStep: _currentStep,
                      onStepTapped: (step) => setState(() => _currentStep = step),
                      controlsBuilder: (context, details) => _buildControls(details),
                      steps: [
                        Step(
                          title: const Text('اختيار وسائل الدفع'),
                          content: _buildPaymentMethodsSelection(),
                          isActive: _currentStep == 0,
                        ),
                        Step(
                          title: const Text('الإعدادات التفصيلية'),
                          content: _buildAdvancedSettings(),
                          isActive: _currentStep == 1,
                        ),
                        Step(
                          title: const Text('المراجعة والتأكيد'),
                          content: _buildReviewStep(),
                          isActive: _currentStep == 2,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsSelection() {
    final availablePaymentTypes = PaymentMethodType.values;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر وسائل الدفع التي تريد قبولها:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...availablePaymentTypes.map((paymentType) {
          final isSelected = _selectedMethods[paymentType] ?? false;
          
          return CheckboxListTile(
            title: Text(paymentType.displayNameArabic),
            subtitle: Text(_getPaymentMethodDescription(paymentType)),
            value: isSelected,
            onChanged: (value) {
              setState(() {
                _selectedMethods[paymentType] = value ?? false;
              });
            },
            secondary: Icon(_getPaymentMethodIcon(paymentType)),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إعدادات إضافية:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        SwitchListTile(
          title: const Text('تفعيل الحد الأدنى للطلب'),
          subtitle: const Text('اشتراط حد أدنى لقيمة الطلب'),
          value: _requireMinimumOrder,
          onChanged: (value) {
            setState(() => _requireMinimumOrder = value);
          },
        ),
        
        if (_requireMinimumOrder) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _minimumAmountController,
            decoration: const InputDecoration(
              labelText: 'الحد الأدنى للطلب (ر.س)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _minimumOrderAmount = double.tryParse(value) ?? 0.0;
            },
          ),
        ],
        
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('تفعيل الدفع التلقائي'),
          subtitle: const Text('قبول المدفوعات تلقائياً دون مراجعة'),
          value: _enableAutomaticPayments,
          onChanged: (value) {
            setState(() => _enableAutomaticPayments = value);
          },
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final selectedCount = _selectedMethods.values.where((v) => v).length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مراجعة الإعدادات:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('وسائل الدفع المختارة: $selectedCount'),
                const SizedBox(height: 8),
                ..._selectedMethods.entries
                    .where((entry) => entry.value)
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(_getPaymentMethodIcon(entry.key), size: 16),
                              const SizedBox(width: 8),
                              Text(entry.key.displayNameArabic),
                            ],
                          ),
                        ))
                    .toList(),
                
                if (_requireMinimumOrder) ...[
                  const Divider(),
                  Text('الحد الأدنى للطلب: ${_minimumOrderAmount.toStringAsFixed(2)} ر.س'),
                ],
                
                const Divider(),
                Text('الدفع التلقائي: ${_enableAutomaticPayments ? 'مفعل' : 'غير مفعل'}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (details.stepIndex < 2)
            ElevatedButton(
              onPressed: () => setState(() => _currentStep++),
              child: const Text('التالي'),
            ),
          
          if (details.stepIndex == 2)
            ElevatedButton(
              onPressed: _setupPaymentMethods,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
              ),
              child: const Text('إنهاء الإعداد'),
            ),
          
          const SizedBox(width: 8),
          
          if (details.stepIndex > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('السابق'),
            ),
        ],
      ),
    );
  }

  Future<void> _setupPaymentMethods() async {
    setState(() => _isLoading = true);
    
    try {
      // إنشاء قائمة الطرق المختارة
      final selectedPaymentMethods = <MerchantPaymentMethod>[];
      
      _selectedMethods.forEach((type, isSelected) {
        if (isSelected) {
          selectedPaymentMethods.add(
            MerchantPaymentMethod(
              type: type,
              isEnabled: true,
              isAutomatic: _enableAutomaticPayments,
              updatedAt: DateTime.now(),
            ),
          );
        }
      });

      // إنشاء إعدادات الدفع
      final paymentSettings = MerchantPaymentSettings(
        merchantId: widget.merchantId,
        paymentMethods: selectedPaymentMethods,
        requireMinimumOrder: _requireMinimumOrder,
        minimumOrderAmount: _minimumOrderAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ الإعدادات
      await _paymentService.updateMerchantPaymentSettings(paymentSettings);
      
      // ربط الإعدادات بالتاجر
      await _paymentService.linkPaymentSettingsToMerchant(widget.merchantId);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إعداد وسائل الدفع بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSetupComplete?.call();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إعداد وسائل الدفع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getPaymentMethodDescription(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.visa:
      case PaymentMethodType.mastercard:
      case PaymentMethodType.americanExpress:
        return 'بطاقة ائتمانية/مدينة';
      case PaymentMethodType.stcPay:
      case PaymentMethodType.urPay:
        return 'محفظة رقمية سعودية';
      case PaymentMethodType.vodafoneCash:
        return 'محفظة رقمية مصرية - تحويل تلقائي';
      case PaymentMethodType.etisalatCash:
        return 'محفظة رقمية مصرية - تحويل تلقائي';
      case PaymentMethodType.orangeCash:
        return 'محفظة رقمية مصرية - تحويل تلقائي';
      case PaymentMethodType.applePay:
      case PaymentMethodType.samsungPay:
        return 'دفع عبر الهاتف';
      case PaymentMethodType.appWallet:
        return 'محفظة التطبيق (موصى به)';
      case PaymentMethodType.cashOnDelivery:
        return 'دفع نقدي عند التسليم';
      case PaymentMethodType.paypal:
        return 'محفظة رقمية عالمية - تحويل تلقائي';
      case PaymentMethodType.bankTransfer:
        return 'تحويل بنكي مباشر';
    }
  }

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
}
