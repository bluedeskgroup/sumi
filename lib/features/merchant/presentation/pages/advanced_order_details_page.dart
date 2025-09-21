import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class AdvancedOrderDetailsPage extends StatefulWidget {
  final String orderId;

  const AdvancedOrderDetailsPage({
    super.key,
    required this.orderId,
  });

  @override
  State<AdvancedOrderDetailsPage> createState() => _AdvancedOrderDetailsPageState();
}

class _AdvancedOrderDetailsPageState extends State<AdvancedOrderDetailsPage> {
  bool _showRejectDialog = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Top Navigation
                  _buildTopNavigation(),
                  
                  // Main Content
                  _buildMainContent(),
                ],
              ),
            ),
            
            // Reject Confirmation Dialog
            if (_showRejectDialog) _buildRejectDialog(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          const Text(
            'تفاصيل الطلب',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1D2035),
            ),
          ),
          
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: const Color(0xFFE7EBEF)),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Color(0xFF323F49),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Order Number
          Text(
            'رقم الطلب: #544658468',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 19,
              color: Color(0xFF1AB385),
            ),
            textAlign: TextAlign.right,
          ),
          
          const SizedBox(height: 17),
          
          // Progress Bar
          _buildProgressBar(),
          
          const SizedBox(height: 17),
          
          // Product Items
          _buildProductItem(
            name: 'نظارات قراءة كيركسن 5 أزواج، نظارات عصرية للسيدات، مفصل زنبركي مع طباعة بنمط',
            color: 'اخضر',
            size: '50 سنتي',
            price: '86.00 ريال',
            quantity: '1',
            imageAsset: 'assets/images/order_details/product_image_1.png',
          ),
          
          const SizedBox(height: 16),
          
          _buildProductItem(
            name: 'نظارات قراءة كيركسن 5 أزواج، نظارات عصرية للسيدات، مفصل زنبركي مع طباعة بنمط',
            color: 'اخضر',
            size: '50 سنتي',
            price: '86.00 ريال',
            quantity: '1',
            imageAsset: 'assets/images/order_details/product_image_2_alt.png',
          ),
          
          const SizedBox(height: 17),
          
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFDDE2E4),
          ),
          
          const SizedBox(height: 17),
          
          // Order Summary
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
          
          _buildOrderSummary(),
          
          const SizedBox(height: 17),
          
          // Shipping Information
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
          
          _buildShippingInfo(),
          
          const SizedBox(height: 17),
          
          _buildShippingDetails(),
          
          const SizedBox(height: 17),
          
          // Order Tracking Section
          _buildOrderTrackingSection(),
          
          const SizedBox(height: 17),
          
          // Print Order Button
          _buildPrintOrderButton(),
          
          const SizedBox(height: 32),
        ],
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
        // Product Details (first for RTL)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'اللون : $color',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xCC141414),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'الحجم : $size',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xCC141414),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                      color: Color(0xCC141414),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Product Image (second for RTL)
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
                    Icons.image,
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
          _buildSummaryRow('المجموع الفرعي', '2079 ريال'),
          const SizedBox(height: 15),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 15),
          _buildSummaryRow('التوصيل', '20 ريال'),
          const SizedBox(height: 15),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 15),
          _buildSummaryRow('إجمالي ضريبة القيمة المضافة.', '197 ريال'),
          const SizedBox(height: 15),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1907 ريال',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: Color(0xFF9A46D7),
                ),
              ),
              const Text(
                'إجمالي الطلب',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  color: Color(0xFF141414),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Color(0xFF9A46D7),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            color: Color(0xFF141414),
          ),
        ),
      ],
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      height: 226,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/order_details/map_image-f7a722.png',
              width: double.infinity,
              height: 226,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 226,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.map,
                    color: Colors.grey,
                    size: 50,
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 191,
            top: 106,
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
                size: 12,
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildShippingDetailRow('العميل: مي عمرو السيد'),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          _buildShippingDetailRow('رقم الهاتف: 0570151550'),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          _buildShippingDetailRow('البلد : السعودية'),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          _buildShippingDetailRow('المحافظة : الرياض'),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          _buildShippingDetailRow('رقم المبنى: 16'),
          const SizedBox(height: 22),
          Container(height: 1, color: const Color(0xFFDDE2E4)),
          const SizedBox(height: 22),
          _buildShippingDetailRow('العنوان بالتفاصيل : عنوان كبير وواضح'),
        ],
      ),
    );
  }

  Widget _buildShippingDetailRow(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Ping AR + LT',
        fontWeight: FontWeight.w400,
        fontSize: 16,
        color: Color(0xFF141414),
      ),
      textAlign: TextAlign.right,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Reject Button (first for RTL)
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showRejectDialog = true;
              });
            },
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
        ),
        
        const SizedBox(width: 16),
        
        // Accept Button (second for RTL)
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Accept order logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم قبول الطلب بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF9A46D7),
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
        ),
      ],
    );
  }

  Widget _buildRejectDialog() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showRejectDialog = false;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFFCED7DE),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 7),
                
                // Content
                Column(
                  children: [
                    // Product Image
                    Container(
                      width: 166.8,
                      height: 166.8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEED9),
                        borderRadius: BorderRadius.circular(138),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(23.9),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(119),
                          child: Image.asset(
                            'assets/images/order_details/popup_product_image.png',
                            width: 119,
                            height: 119,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 119,
                                height: 119,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(119),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Title
                    const Text(
                      'تأكيد رفض طلب العميل!',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Color(0xFF2B2F4E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    const Text(
                      'رفض طلبات الشراء المتكررة تعرض حسابك للحظر بالاضافة لخفض تقييم المتجر',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Color(0xFF637D92),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // Action Buttons
                Row(
                  children: [
                    // Cancel Button (first for RTL)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showRejectDialog = false;
                          });
                          // Reject order logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم رفض الطلب'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE32B3D)),
                          ),
                          child: const Center(
                            child: Text(
                              'نعم الغاء الطلب',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFFE32B3D),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 22),
                    
                    // Keep Button (second for RTL)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showRejectDialog = false;
                          });
                        },
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9A46D7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'لا . البقاء',
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 382,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          Container(
            width: 177, // Progress (205/382 * 382 ≈ 177)
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFF1ED29C),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTrackingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'متابعة طلبك',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF9A46D7),
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        
        const SizedBox(height: 38.5),
        
        // Timeline
        _buildTimeline(),
      ],
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        // Step 1: Order Accepted (Completed)
        _buildTimelineStep(
          title: 'تم تنفيذ الطلب',
          buttonText: 'تم قبول الطلب',
          isCompleted: true,
          isActive: false,
          showLine: true,
        ),
        
        const SizedBox(height: 34),
        
        // Step 2: Under Review (Active)
        _buildTimelineStep(
          title: 'جاري مراجعة الطلب',
          buttonText: 'تاكيد انتهاء المرحلة',
          isCompleted: false,
          isActive: true,
          showLine: true,
        ),
        
        const SizedBox(height: 34),
        
        // Step 3: Shipped (Pending)
        _buildTimelineStep(
          title: 'تم شحن الطلب',
          buttonText: 'تاكيد انتهاء المرحلة',
          isCompleted: false,
          isActive: false,
          showLine: true,
        ),
        
        const SizedBox(height: 34),
        
        // Step 4: Delivered (Pending)
        _buildTimelineStep(
          title: 'تم توصيل الطلب بنجاح',
          buttonText: 'في انتظار شركة الشحن',
          isCompleted: false,
          isActive: false,
          showLine: false,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String buttonText,
    required bool isCompleted,
    required bool isActive,
    required bool showLine,
  }) {
    return Stack(
      children: [
        // Dotted Line (positioned behind the circle)
        if (showLine)
          Positioned(
            right: 144, // Position from right to center the line with the circle (377-13-26/2 = ~154)
            top: 41, // Start after the circle
            child: Container(
              width: 1,
              height: 34, // Height matching the spacing between steps
              child: CustomPaint(
                painter: DottedLinePainter(
                  color: isCompleted 
                      ? const Color(0xFF1ED29C) 
                      : const Color(0xFFC4C4C4),
                ),
              ),
            ),
          ),
        
        // Main content
        Container(
          width: 377,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Button
              Container(
                width: 140,
                height: 41,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? const Color(0xFFAAB9C5) 
                      : const Color(0xFF9A46D7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              // Title and Circle
              Row(
                children: [
                  // Circle
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? const Color(0xFF1AB385) 
                          : const Color(0xFFF3F3F3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted 
                            ? const Color(0xFF1AB385) 
                            : const Color(0xFFC4C4C4),
                        width: 1,
                      ),
                    ),
                    child: isCompleted || isActive 
                        ? Container(
                            margin: const EdgeInsets.all(6.88),
                            width: 12.24,
                            height: 12.24,
                            decoration: BoxDecoration(
                              color: isCompleted 
                                  ? const Color(0xFF1AB385) 
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 13),
                  
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xFF2B2F4E),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrintOrderButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('سيتم طباعة الطلب...'),
            backgroundColor: Colors.purple,
          ),
        );
      },
      child: Container(
        width: 382,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text(
            'طباعة الطلب',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF9A46D7),
            ),
          ),
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;
  
  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
