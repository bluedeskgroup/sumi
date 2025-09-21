import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:sumi/features/store/presentation/pages/payment_methods_modal.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int selectedPaymentMethod = 0; // 0 = Card, 1 = Other
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  @override
  void dispose() {
    cardHolderController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  String _getPaymentMethodText() {
    switch (selectedPaymentMethod) {
      case 0:
        return 'بطاقة ائتمان/خصم';
      case 1:
        return 'Apple Pay';
      case 2:
        return 'الدفع عند الاستلام';
      case 3:
        return 'مدي';
      case 4:
        return 'STC Pay';
      default:
        return 'طريقة دفع أخرى';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 60), // Space for status bar
                  _buildMainContent(context, isArabic),
                  const SizedBox(height: 117), // Space for bottom buttons
                ],
              ),
            ),
            
            // Fixed Bottom Buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomButtons(context, isArabic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isArabic) {
    return Container(
      width: 430, // Exact Figma frame width
      child: Column(
        children: [
          // Header Section
          _buildHeader(context, isArabic),
          
          const SizedBox(height: 16), // Gap from Figma
          
          // Credit Card Icon Circle
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6FE),
              borderRadius: BorderRadius.circular(61),
            ),
            child: Center(
              child: Container(
                width: 57,
                height: 57,
                child: Icon(
                  Icons.credit_card_outlined,
                  size: 42.75,
                  color: const Color(0xFF9A46D7),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16), // Gap from Figma
          
          // Payment Form
          Container(
            width: 382, // Exact width from Figma
            child: _buildPaymentForm(isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic) {
    return Container(
      width: 430,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // Check Icon
          Container(
            width: 24,
            height: 24,
            child: Icon(
              Icons.check,
              size: 16,
              color: Colors.transparent, // Transparent as shown in Figma
            ),
          ),
          
          const SizedBox(width: 127), // Gap from Figma
          
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: const Color(0xFFE7EBEF), width: 1),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  child: Icon(
                    isArabic ? Icons.arrow_forward : Icons.arrow_back,
                    size: 12,
                    color: const Color(0xFF323F49),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm(bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Payment Methods Title
        Container(
          width: 382,
          child: Text(
            'معلومات الدفع',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D2035),
              height: 1.78,
              letterSpacing: -0.022,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        
        const SizedBox(height: 16), // Gap from Figma
        
        // Payment Method Options
        _buildPaymentMethodOption(
          0,
          Icons.credit_card,
          'بطاقة ائتمان/خصم',
          isSelected: selectedPaymentMethod == 0,
          isArabic: isArabic,
        ),
        
        const SizedBox(height: 16), // Gap from Figma
        
        GestureDetector(
          onTap: () {
            showPaymentMethodsModal(context, selectedPaymentMethod, (newMethod) {
              setState(() {
                selectedPaymentMethod = newMethod;
              });
            });
          },
          child: _buildPaymentMethodOption(
            1,
            Icons.account_balance_wallet,
            _getPaymentMethodText(),
            isSelected: selectedPaymentMethod != 0,
            isArabic: isArabic,
          ),
        ),
        
        const SizedBox(height: 16), // Gap from Figma
        
        // Card Details Title
        Container(
          width: 382,
          child: Text(
            'بيانات البطاقة',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D2035),
              height: 1.78,
              letterSpacing: -0.022,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        
        const SizedBox(height: 16), // Gap from Figma
        
        // Card Form Fields - Only show for credit card
        if (selectedPaymentMethod == 0) _buildCardForm(isArabic),
      ],
    );
  }

  Widget _buildPaymentMethodOption(int index, IconData icon, String title, {required bool isSelected, required bool isArabic}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = index;
        });
      },
      child: Container(
        width: 382, // Exact width from Figma
        height: 52, // Exact height from Figma
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF6FE) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFFCBCBCB),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Radio Button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFFCBCBCB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF9A46D7),
                        ),
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 12), // Gap from Figma
            
            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D2035),
                  height: 1.57,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
            
            const SizedBox(width: 12), // Gap from Figma
            
            // Icon
            if (index == 0) Container(
              width: 24,
              height: 24,
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFF637D92),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm(bool isArabic) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFCBCBCB), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Card Holder Name
          _buildFormField(
            'اسم حامل البطاقة',
            cardHolderController,
            TextInputType.text,
            isArabic,
          ),
          
          const SizedBox(height: 16), // Gap from Figma
          
          // Card Number
          _buildFormField(
            'رقم البطاقة',
            cardNumberController,
            TextInputType.number,
            isArabic,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CardNumberInputFormatter(),
            ],
          ),
          
          const SizedBox(height: 16), // Gap from Figma
          
          // Expiry and CVV Row
          Row(
            textDirection: TextDirection.rtl,
            children: [
              // CVV
              Expanded(
                child: _buildFormField(
                  'CVV',
                  cvvController,
                  TextInputType.number,
                  isArabic,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
              ),
              
              const SizedBox(width: 12), // Gap from Figma
              
              // Expiry Date
              Expanded(
                child: _buildFormField(
                  'تاريخ الانتهاء',
                  expiryController,
                  TextInputType.number,
                  isArabic,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ExpiryDateInputFormatter(),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16), // Gap from Figma
        ],
      ),
    );
  }

  Widget _buildFormField(
    String title,
    TextEditingController controller,
    TextInputType keyboardType,
    bool isArabic, {
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Field Title
        Container(
          width: double.infinity,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3E3E59),
              height: 1.57,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        
        const SizedBox(height: 8), // Gap from Figma
        
        // Input Field
        Container(
          height: 46, // Exact height from Figma
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFCBCBCB), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              hintStyle: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCBCBCB),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF1D2035),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, bool isArabic) {
    return Container(
      width: 430, // Exact frame width from Figma
      height: 117, // Exact frame height from Figma
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), // Exact padding from Figma
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 60,
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Add Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Handle add payment method
                _handleAddPayment(context);
              },
              child: Container(
                height: 60, // Exact button height from Figma
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'اضافة',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFFFFF),
                      height: 1.39,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 22), // Gap from Figma
          
          // Cancel Button
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 60, // Exact button height from Figma
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFAAB9C5), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'الغاء',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFAAB9C5),
                      height: 1.39,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddPayment(BuildContext context) {
    if (selectedPaymentMethod == 0) {
      // Validate card form
      if (cardHolderController.text.isEmpty ||
          cardNumberController.text.isEmpty ||
          expiryController.text.isEmpty ||
          cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى ملء جميع البيانات المطلوبة'),
            backgroundColor: Color(0xFFE74C3C),
          ),
        );
        return;
      }
    }

    // Show success message and go back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إضافة طريقة الدفع بنجاح'),
        backgroundColor: Color(0xFF27AE60),
      ),
    );
    
    Navigator.of(context).pop(true); // Return true to indicate success
  }
}

// Custom Input Formatters
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
