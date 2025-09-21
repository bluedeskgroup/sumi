import 'package:flutter/material.dart';
import 'package:sumi/l10n/app_localizations.dart';

class PaymentMethodsModal extends StatefulWidget {
  final int selectedMethod;
  const PaymentMethodsModal({super.key, required this.selectedMethod});

  @override
  State<PaymentMethodsModal> createState() => _PaymentMethodsModalState();
}

class _PaymentMethodsModalState extends State<PaymentMethodsModal> {
  int selectedMethod = 0;

  @override
  void initState() {
    super.initState();
    selectedMethod = widget.selectedMethod;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

    return Container(
      width: 430, // Exact Figma frame width
      height: 932, // Exact Figma frame height
      child: Stack(
        children: [
          // Background Overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1D2035).withOpacity(0.45), // Exact opacity from Figma
            ),
          ),
          
          // Modal Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: 430,
              height: 571.2, // Exact height from Figma
              decoration: const BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    width: 60,
                    height: 6,
                    margin: const EdgeInsets.only(top: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7EBEF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // Header
                  _buildHeader(context, isArabic),
                  
                  // Payment Methods List
                  Expanded(
                    child: _buildPaymentMethodsList(isArabic),
                  ),
                  
                  // Bottom Buttons
                  _buildBottomButtons(context, isArabic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic) {
    return Container(
      width: 382, // Exact width from Figma
      height: 39, // Exact height from Figma
      margin: const EdgeInsets.only(top: 18, left: 24, right: 24),
      child: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // Title
          Container(
            width: 250, // Exact width from Figma
            height: 39, // Exact height from Figma
            child: Text(
              'اختر طريقة الدفع',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B2F4E),
                height: 7.5, // Exact line height from Figma
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(width: 13), // Gap from Figma
          
          // Close Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 24,
              height: 24,
              child: Icon(
                Icons.close,
                size: 20,
                color: const Color(0xFF637D92),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList(bool isArabic) {
    return Container(
      width: 382, // Exact width from Figma
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 26.5), // Gap from header
          
          // Credit Card Method
          _buildPaymentMethod(
            0,
            '•••• •••• •••• 4679',
            'assets/images/payment/card_icon.png',
            isSelected: selectedMethod == 0,
            isArabic: isArabic,
          ),
          
          const SizedBox(height: 14), // Gap from Figma
          
          // Apple Pay Method
          _buildPaymentMethod(
            1,
            'Apple Pay',
            'assets/images/payment/apple_pay_icon.png',
            isSelected: selectedMethod == 1,
            isArabic: isArabic,
          ),
          
          const SizedBox(height: 14), // Gap from Figma
          
          // Cash on Delivery Method
          _buildPaymentMethod(
            2,
            'الدفع عند الاستلام',
            null, // No icon for cash on delivery
            isSelected: selectedMethod == 2,
            isArabic: isArabic,
            showCashIcon: true,
          ),
          
          const SizedBox(height: 14), // Gap from Figma
          
          // Mada Method
          _buildPaymentMethod(
            3,
            'مدي',
            null, // Will use custom Mada logo
            isSelected: selectedMethod == 3,
            isArabic: isArabic,
            showMadaLogo: true,
          ),
          
          const SizedBox(height: 14), // Gap from Figma
          
          // STC Pay Method
          _buildPaymentMethod(
            4,
            'STC Pay',
            null, // Will use custom STC logo
            isSelected: selectedMethod == 4,
            isArabic: isArabic,
            showSTCLogo: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(
    int index,
    String title,
    String? iconPath, {
    required bool isSelected,
    required bool isArabic,
    bool showCashIcon = false,
    bool showMadaLogo = false,
    bool showSTCLogo = false,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = index;
        });
      },
      child: Container(
        height: 72, // Exact height from Figma
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF6FE) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFFEEEEEE),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
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
                  color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFFE7EBEF),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 11.67,
                        height: 11.67,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF9A46D7),
                        ),
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 16), // Gap from Figma
            
            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D2035),
                  height: 1.6,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),
            
            const SizedBox(width: 16), // Gap from Figma
            
            // Icon/Logo
            Container(
              width: 29,
              height: 29,
              child: _buildPaymentIcon(
                iconPath, 
                showCashIcon: showCashIcon,
                showMadaLogo: showMadaLogo,
                showSTCLogo: showSTCLogo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentIcon(
    String? iconPath, {
    bool showCashIcon = false,
    bool showMadaLogo = false,
    bool showSTCLogo = false,
  }) {
    if (iconPath != null) {
      return ClipOval(
        child: Image.asset(
          iconPath,
          width: 29,
          height: 29,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 29,
              height: 29,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF0F0F0),
              ),
              child: const Icon(
                Icons.image_not_supported,
                size: 16,
                color: Color(0xFF637D92),
              ),
            );
          },
        ),
      );
    } else if (showCashIcon) {
      return Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.money,
          size: 20,
          color: Color(0xFF27AE60),
        ),
      );
    } else if (showMadaLogo) {
      return Container(
        width: 58.98,
        height: 20.26,
        child: _buildMadaLogo(),
      );
    } else if (showSTCLogo) {
      return Container(
        width: 57.63,
        height: 16.94,
        child: _buildSTCLogo(),
      );
    }
    
    return Container(
      width: 29,
      height: 29,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF0F0F0),
      ),
      child: const Icon(
        Icons.payment,
        size: 16,
        color: Color(0xFF637D92),
      ),
    );
  }

  Widget _buildMadaLogo() {
    return Stack(
      children: [
        // Green section
        Positioned(
          left: 0,
          bottom: 0,
          child: Container(
            width: 24.95,
            height: 8.56,
            color: const Color(0xFF84B740),
          ),
        ),
        // Blue section
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 24.95,
            height: 8.57,
            color: const Color(0xFF259BD6),
          ),
        ),
        // Text "مدي"
        Positioned(
          right: 0,
          child: Container(
            width: 30,
            height: 20.26,
            child: const Text(
              'مدي',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSTCLogo() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // STC text with colors
          Container(
            child: Row(
              children: [
                Text(
                  'S',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF02AA7C),
                  ),
                ),
                Text(
                  'T',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF02AA7C),
                  ),
                ),
                Text(
                  'C',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF502C84),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'pay',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF1D2035),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, bool isArabic) {
    return Container(
      width: 382, // Exact width from Figma
      height: 60, // Exact height from Figma
      margin: const EdgeInsets.only(bottom: 30, left: 24, right: 24),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Confirm Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(selectedMethod);
              },
              child: Container(
                height: 60, // Exact button height from Figma
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'تاكيد',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFFFF),
                      height: 1.39,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 22), // Gap from Figma
          
          // Add New Card Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(-1); // Return -1 for add new card
              },
              child: Container(
                height: 60, // Exact button height from Figma
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF9A46D7), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'اضافة بطاقة جديدة',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A46D7),
                      height: 0.02, // Exact line height from Figma
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
}

// Function to show the modal
void showPaymentMethodsModal(BuildContext context, int currentMethod, Function(int) onMethodSelected) {
  showDialog(
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => PaymentMethodsModal(selectedMethod: currentMethod),
  ).then((result) {
    if (result != null && result != -1) {
      onMethodSelected(result);
    } else if (result == -1) {
      // Handle add new card - could navigate to card form
      onMethodSelected(0); // Default to card for now
    }
  });
}
