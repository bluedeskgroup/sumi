import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/merchant_model.dart';
import '../../services/merchant_service.dart';

/// الصفحة الرئيسية المتقدمة للتاجر بعد إكمال جميع المهام
class MerchantHomeAdvancedPage extends StatefulWidget {
  final MerchantModel merchant;
  
  const MerchantHomeAdvancedPage({
    super.key,
    required this.merchant,
  });

  @override
  State<MerchantHomeAdvancedPage> createState() => _MerchantHomeAdvancedPageState();
}

class _MerchantHomeAdvancedPageState extends State<MerchantHomeAdvancedPage> {
  int _selectedIndex = 0;
  final MerchantService _merchantService = MerchantService.instance;

  // ألوان الفيجما
  static const Color primaryPurple = Color(0xFF9A46D7);
  static const Color primaryText = Color(0xFF1D2035);
  static const Color secondaryText = Color(0xFF353A62);
  static const Color grayText = Color(0xFF626C83);
  static const Color lightGray = Color(0xFFF8F8F8);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color successGreen = Color(0xFF1ED29C);
  static const Color warningOrange = Color(0xFFFEAA43);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header العلوي
              _buildTopNavigation(),
              
              // المحتوى الرئيسي
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildHomeContent(),
                    _buildProductsContent(),
                    _buildOrdersContent(), 
                    _buildMoreContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: whiteColor,
        border: Border(
          bottom: BorderSide(color: Color(0xFFECECEC), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // معلومات المتجر
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(45),
                  border: Border.all(color: whiteColor, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: widget.merchant.profileImageUrl.isNotEmpty
                      ? Image.network(
                          widget.merchant.profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultLogo(),
                        )
                      : _buildDefaultLogo(),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.merchant.businessName,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'كود المتجر ${widget.merchant.id.substring(0, 7)}',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF7991A4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // الإشعارات
          Row(
            children: [
              _buildNotificationButton(Icons.chat_bubble, null),
              const SizedBox(width: 12),
              _buildNotificationButton(Icons.notifications, '99'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // تقرير المبيعات
          _buildSalesReportCard(),
          
          const SizedBox(height: 16),
          
          // قائمة الإعلانات المدفوعة
          _buildPaidAdsCard(),
          
          const SizedBox(height: 16),
          
          // تعليقات العملاء
          _buildCustomerReviewsCard(),
          
          const SizedBox(height: 16),
          
          // أزرار الإدارة
          _buildManagementButtons(),
        ],
      ),
    );
  }

  Widget _buildSalesReportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.archive_outlined, size: 18, color: grayText),
                  const SizedBox(width: 6),
                  const Text(
                    'إيرادات المبيعات',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.more_vert, size: 18, color: grayText),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F3F9), height: 1),
          const SizedBox(height: 16),
          
          // الإحصائيات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المؤشر
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFAF2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_upward, size: 12, color: Color(0xFF41C980)),
                        Text(
                          '10%',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF41C980),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // المبلغ
                  const Row(
                    children: [
                      Text(
                        'ر.س',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: grayText,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '750,00',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: primaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Text(
                'انخفضت إيراداتك\nالشهر بنحو 908 ريال',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans Arabic',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: grayText,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // الرسم البياني (مبسط)
          _buildSimpleChart(),
        ],
      ),
    );
  }

  Widget _buildSimpleChart() {
    return Container(
      height: 120,
      child: CustomPaint(
        painter: SimpleChartPainter(),
        child: Container(),
      ),
    );
  }

  Widget _buildPaidAdsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الأعلانات المدفوعة',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111317),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تم شحن 1M منتج حتى الان',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: grayText.withOpacity(0.8),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // قائمة المنتجات
          _buildProductList(),
          
          const SizedBox(height: 16),
          
          // زر المزيد
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E6EE)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'اظهر المزيد (113)',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111317),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Column(
      children: [
        _buildProductItem(
          'عنوان او اسم المنتج المعروض',
          'عدد المشاهدات : 2800 الف',
          'حالة الاعلان : فعال',
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildProductItem(
          'عنوان او اسم المنتج المعروض',
          'عدد المشاهدات : 2800 الف',
          'حالة الاعلان : أنتهي الاعلان',
          warningOrange,
        ),
        const SizedBox(height: 12),
        _buildProductItem(
          'عنوان او اسم المنتج المعروض',
          'عدد المشاهدات : 2800 الف',
          'حالة الاعلان : فعال',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildProductItem(String title, String views, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 77,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9E9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          ),
          
          const SizedBox(width: 16),
          
          // معلومات المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  views,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReviewsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تعليقات العملاء',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // تعليق العميل
          _buildCustomerReview(),
          
          const SizedBox(height: 24),
          
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          
          const SizedBox(height: 24),
          
          _buildCustomerReview(),
          
          const SizedBox(height: 24),
          
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          
          const SizedBox(height: 24),
          
          _buildCustomerReview(),
          
          const SizedBox(height: 24),
          
          // زر عرض المزيد
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE9ECF2), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'عرض المزيد',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: primaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // هيدر التقييم
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '25/5/2023',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFFBFBFBF),
              ),
            ),
            Row(
              children: [
                Row(
                  children: [
                    // النجوم
                    Row(
                      children: List.generate(5, (index) => Icon(
                        Icons.star,
                        size: 16,
                        color: index == 0 ? const Color(0xFFDDDDDD) : const Color(0xFFFFBB0D),
                      )),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'دنيا خالد',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // صورة العميل
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE9E9E9),
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 14),
        
        // المنتج المقيم
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.image, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عنوان او اسم المنتج المعروض',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'المقاس: 2XL، اللون: أخضر',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF605F5F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 14),
        
        // نص التقييم
        const Text(
          'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد النص..',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: primaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildManagementButton('ادارة العروض', Icons.percent, () {}),
        const SizedBox(width: 24),
        _buildManagementButton('ادارة التقييمات', Icons.star, () {}),
        const SizedBox(width: 24),
        _buildManagementButton('أدارة الاقسام', Icons.home, () {}),
        const SizedBox(width: 24),
        _buildManagementButton('ادارة المحفظة', Icons.wallet, () {}),
      ],
    );
  }

  Widget _buildManagementButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 37, color: primaryPurple),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(IconData icon, String? badge) {
    return Container(
      width: 59,
      height: 59,
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(48),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              size: 27,
              color: grayText,
            ),
          ),
          if (badge != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFEB5757),
                  borderRadius: BorderRadius.circular(500),
                ),
                child: Center(
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: whiteColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      color: const Color(0xFF000000).withOpacity(0.2),
      child: const Center(
        child: Icon(
          Icons.store,
          color: whiteColor,
          size: 30,
        ),
      ),
    );
  }

  // محتوى الصفحات الأخرى
  Widget _buildProductsContent() {
    return const Center(
      child: Text(
        'صفحة المنتجات المتقدمة',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildOrdersContent() {
    return const Center(
      child: Text(
        'صفحة الطلبات المتقدمة', 
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildMoreContent() {
    return const Center(
      child: Text(
        'المزيد المتقدم',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return SafeArea(
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: const BoxDecoration(
          color: Color(0xFF141936),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F171717),
              offset: Offset(0, 4),
              blurRadius: 31.7,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.grid_view, 'المزيد', 3),
            _buildNavItem(Icons.store, 'المنتجات', 1),
            _buildAddButton(),
            _buildNavItem(Icons.inbox, 'الطلبات', 2),
            _buildNavItem(Icons.home, 'الرئيسية', 0),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? primaryPurple : const Color(0xFFAAB9C5),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? primaryPurple : const Color(0xFFC9CEDC),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Icon(
        Icons.add,
        size: 24,
        color: whiteColor,
      ),
    );
  }
}

/// رسم بياني بسيط للمبيعات
class SimpleChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFEAA43)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.8);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    path.lineTo(size.width * 0.8, size.height * 0.6);
    path.lineTo(size.width, size.height * 0.4);

    canvas.drawPath(path, paint);

    // نقطة مميزة
    final pointPaint = Paint()
      ..color = const Color(0xFFFEAA43)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.3), 
      6, 
      pointPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
