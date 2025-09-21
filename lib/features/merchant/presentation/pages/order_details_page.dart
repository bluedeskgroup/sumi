import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: const Color(0xFFE7EBEF)),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF323F49),
                size: 18,
              ),
            ),
          ),
          title: const Text(
            'تفاصيل الطلب',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1D2035),
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                        // Product Items
                        _buildProductItem(
                          name: 'نظارات قراءة كيركسن 5 أزواج، نظارات عصرية للسيدات، مفصل زنبركي مع طباعة بنمط',
                          color: 'أخضر',
                          size: '50 سنتي',
                          price: '86.00 ريال',
                          quantity: '1',
                          imageAsset: 'assets/images/products/glasses1.png',
                        ),
                        const SizedBox(height: 17),
                        
                        _buildProductItem(
                          name: 'نظارات قراءة كيركسن 5 أزواج، نظارات عصرية للسيدات، مفصل زنبركي مع طباعة بنمط',
                          color: 'أخضر',
                          size: '50 سنتي',
                          price: '86.00 ريال',
                          quantity: '1',
                          imageAsset: 'assets/images/products/glasses2-6a9524.png',
                        ),
                        const SizedBox(height: 17),
                        
                        // Divider
                        Container(
                          height: 1,
                          color: const Color(0xFFDDE2E4),
                        ),
                        const SizedBox(height: 17),
                        
                        // Order Summary Title
                        const Text(
                          'ملخص الطلب',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            color: Color(0xFF141414),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 17),
                        
                        // Order Summary
                        _buildOrderSummary(),
                        const SizedBox(height: 17),
                        
                        // Shipping Info Title
                        const Text(
                          'معلومات الشحن',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w500,
                            fontSize: 24,
                            color: Color(0xFF141414),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 17),
                        
                        // Map
                        _buildMapSection(),
                        const SizedBox(height: 17),
                        
                        // Shipping Details
                        _buildShippingDetails(),
                        const SizedBox(height: 17),
                        
                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildProductItem({
    required String name,
    required String color,
    required String size,
    required String price,
    required String quantity,
    required String imageAsset,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Product Name
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF141414),
                  height: 1.71,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              
              // Color
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'اللون : $color',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0x80141414),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Size
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'الحجم : $size',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0x80141414),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Price and Quantity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      color: Color(0xFF9A46D7),
                    ),
                  ),
                  Text(
                    'الكمية: $quantity',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0x80141414),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        
        // Product Image
        Container(
          width: 69,
          height: 69,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imageAsset,
              width: 69,
              height: 69,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 69,
                  height: 69,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.visibility_rounded,
                    color: Colors.grey,
                    size: 30,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE2E4)),
      ),
      child: Column(
        children: [
          // Subtotal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المجموع الفرعي',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF141414),
                ),
              ),
              const Text(
                '2079 ريال',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF9A46D7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Divider
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 15),
          
          // Delivery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'التوصيل',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF141414),
                ),
              ),
              const Text(
                '20 ريال',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF9A46D7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Divider
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 15),
          
          // VAT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي ضريبة القيمة المضافة.',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF141414),
                ),
              ),
              const Text(
                '197 ريال',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF9A46D7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Final Divider (thicker)
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 15),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي الطلب',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: Color(0xFF141414),
                ),
              ),
              const Text(
                '1907 ريال',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: Color(0xFF9A46D7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      width: double.infinity,
      height: 226,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Map image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/products/map_location-f7a722.png',
              width: double.infinity,
              height: 226,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 226,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.blue[100],
                  ),
                  child: const Center(
                    child: Text(
                      'خريطة الموقع',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Location pin
          Positioned(
            top: 106,
            right: 191,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFF9A46D7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE2E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer
          const Text(
            'العميل: مي عمرو السيد',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF141414),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          
          // Phone
          const Text(
            'رقم الهاتف: 0570151550',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF141414),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          
          // Country
          const Text(
            'البلد : السعودية',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF141414),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          
          // Province
          const Text(
            'المحافظة : الرياض',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF141414),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          
          // Building Number
          const Text(
            'رقم المبنى: 16',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF141414),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          
          // Detailed Address
          const Text(
            'العنوان بالتفاصيل : عنوان كبير وواضح',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF141414),
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Reject Button
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFADCDF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'رفض',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFFE84E5D),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Accept Button
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1AB385),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'موافقة',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
