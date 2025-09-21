import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../models/merchant_dashboard_data.dart';
import '../../services/merchant_dashboard_service.dart';
import '../../services/merchant_service.dart';
import 'add_product_page.dart';
import 'manage_categories_page.dart';
import 'add_category_page.dart';


class AdvancedMerchantHomePage extends StatefulWidget {
  final String merchantId;

  const AdvancedMerchantHomePage({
    Key? key,
    required this.merchantId,
  }) : super(key: key);

  @override
  State<AdvancedMerchantHomePage> createState() => _AdvancedMerchantHomePageState();
}

class _AdvancedMerchantHomePageState extends State<AdvancedMerchantHomePage> {
  final ScrollController _scrollController = ScrollController();
  final MerchantDashboardService _dashboardService = MerchantDashboardService.instance;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ar_SA',
    symbol: 'ر.س',
    decimalDigits: 2,
  );

  // متغيرات البيانات
  Map<String, dynamic>? _merchantInfo;
  MerchantDashboardStats? _dashboardStats;
  SalesRevenue? _salesRevenue;
  bool _isLoading = true;
  String? _error;
  bool _showAddMenu = false; // للتوافق مع الكود الموجود


  @override
  void initState() {
    super.initState();
    _loadMerchantData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMerchantData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // تحميل البيانات بشكل متوازي
      final futures = await Future.wait([
        _dashboardService.getMerchantBasicInfo(widget.merchantId),
        _dashboardService.getDashboardStats(widget.merchantId),
        _dashboardService.getSalesRevenue(widget.merchantId),
      ]);

      if (mounted) {
        setState(() {
          _merchantInfo = futures[0] as Map<String, dynamic>?;
          _dashboardStats = futures[1] as MerchantDashboardStats;
          _salesRevenue = futures[2] as SalesRevenue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل البيانات: $e';
          _isLoading = false;
        });
      }
      debugPrint('Error loading merchant data: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadMerchantData();
  }

  void _showComingSoonMessage(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$featureName قريباً...',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF9A46D7),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          // Main Content
          Directionality(
            textDirection: ui.TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // Main Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingScreen()
                    : _error != null
                        ? _buildErrorScreen()
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                child: SingleChildScrollView(
                  controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header Section
                      _buildHeaderSection(),
                      
                                  // Status notification for non-approved merchants
                                  if (_merchantInfo != null && _merchantInfo!['status'] != 'approved')
                                    _buildStatusNotification(),
                      
                      // Quick Actions
                      _buildQuickActions(),
                      
                      const SizedBox(height: 24),
                      
                      // Revenue Chart Widget
                      _buildRevenueChart(),
                      
                      // Paid Advertisements Widget  
                      _buildPaidAdvertisements(),
                      
                      // Customer Reviews Widget
                      _buildCustomerReviews(),
                      
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
          ),
          SizedBox(height: 16),
          Text(
            'جارٍ تحميل بيانات المتجر...',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 16,
              color: Color(0xFF626C83),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEB5757),
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'حدث خطأ غير متوقع',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                color: Color(0xFF626C83),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A46D7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إعادة المحاولة',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                  fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }



  Widget _buildHeaderSection() {
    final storeName = _merchantInfo?['businessName'] as String? ?? 'متجري';
    final realMerchantId = _merchantInfo?['merchantId'] as String? ?? widget.merchantId;
    final storeCode = _dashboardService.generateStoreCode(realMerchantId);
    final profileImageUrl = _merchantInfo?['profileImageUrl'] as String? ?? '';
    final isVerified = _merchantInfo?['isVerified'] as bool? ?? false;
    final merchantStatus = _merchantInfo?['status'] as String? ?? '';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFECECEC), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          
          // Top Row - Store Info and Notifications (RTL Layout)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notifications and Messages (Left side in RTL)
              Row(
                children: [
                  // Notifications with real count
                  _buildNotificationButton(),
                  
                  const SizedBox(width: 18),
                  
                  // Messages with real count
                  _buildMessageButton(),
                ],
              ),
              
              // Store Info and Profile (Right side in RTL)
              Row(
                children: [
                  // Store Info Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1D2035),
                          height: 1.39,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Status message
                      Text(
                        _getStatusMessage(merchantStatus),
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: _getStatusColor(merchantStatus),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: storeCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ كود المتجر'),
                              backgroundColor: Color(0xFF9A46D7),
                            ),
                          );
                        },
                        child: Text(
                          'كود المتجر $storeCode نسخ!',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: Color(0xFF7991A4),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Profile Picture with logo overlay
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(45),
                            border: Border.all(color: Colors.white, width: 1),
                            image: profileImageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(profileImageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.store,
                                  size: 30,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        // Status indicator
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _getStatusColor(merchantStatus),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              _getStatusIcon(merchantStatus),
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMessageButton() {
    return StreamBuilder<int>(
      stream: _dashboardService.getUnreadMessagesCount(widget.merchantId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return GestureDetector(
          onTap: () {
            _showComingSoonMessage('الرسائل');
          },
          child: Container(
                    width: 59,
                    height: 59,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(48),
                    ),
            child: Stack(
              children: [
                const Center(
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 27,
                        color: Color(0xFF92A5B5),
                      ),
                    ),
                if (unreadCount > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEB5757),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    return StreamBuilder<int>(
      stream: _dashboardService.getUnreadNotificationsCount(widget.merchantId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return GestureDetector(
          onTap: () {
            _showComingSoonMessage('الإشعارات');
          },
          child: SizedBox(
                    width: 59,
                    height: 59,
                    child: Stack(
                      children: [
                        Container(
                          width: 59,
                          height: 59,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(48),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.notifications_outlined,
                              size: 27,
                              color: Color(0xFF92A5B5),
                            ),
                          ),
                        ),
                if (unreadCount > 0)
                        Positioned(
                    top: 12,
                    right: 12,
                          child: Container(
                            height: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(minWidth: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEB5757),
                              borderRadius: BorderRadius.circular(8),
                            ),
                      child: Center(
                              child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // RTL order: من اليمين لليسار - ابتداء من إدارة العروض
            _buildQuickActionItem(
              iconPath: 'assets/icons/circle_percentage_figma.png',
              title: 'ادارة العروض',
              onTap: () {
                _showComingSoonMessage('إدارة العروض');
              },
            ),
            
            _buildQuickActionItem(
              iconPath: 'assets/icons/star_alt_figma.png',
              title: 'ادارة التقييمات',
              onTap: () {
                _showComingSoonMessage('إدارة التقييمات');
              },
            ),
            
            _buildQuickActionItem(
              iconPath: 'assets/icons/house_medical_figma.png',
              title: 'أدارة الاقسام',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageCategoriesPage(),
                  ),
                );
              },
            ),
            
            _buildQuickActionItem(
              iconPath: 'assets/icons/wallet_figma.png',
              title: 'ادارة المحفظة',
              onTap: () {
                _showComingSoonMessage('إدارة المحفظة');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Image.asset(
                  iconPath,
                  width: 37,
                  height: 37,
                  color: const Color(0xFF9A46D7),
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF353A62),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_salesRevenue == null) {
      return const SizedBox.shrink();
    }

    final revenue = _salesRevenue!;
    final difference = revenue.currentRevenue - revenue.previousRevenue;
    final formattedRevenue = _currencyFormat.format(revenue.currentRevenue);
    final formattedDifference = _currencyFormat.format(difference.abs());
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F3F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header (RTL Layout)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
            children: [
              const Icon(
                    Icons.archive_outlined,
                size: 18,
                color: Color(0xFF626C83),
              ),
                  const SizedBox(width: 6),
                  const Text(
                    'إيرادات المبيعات',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1D2035),
                    ),
                  ),
                ],
              ),
                  const Icon(
                Icons.more_vert,
                    size: 18,
                    color: Color(0xFF626C83),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Separator
          Container(
            height: 1,
            color: const Color(0xFFF1F3F9),
          ),
          
          const SizedBox(height: 16),
          
          // Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  revenue.isIncreasing
                      ? 'زادت إيراداتك\nالشهر بنحو $formattedDifference'
                      : 'انخفضت إيراداتك\nالشهر بنحو $formattedDifference',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans Arabic',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF626C83),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Percentage Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: revenue.isIncreasing
                          ? const Color(0xFFECFAF2)
                          : const Color(0xFFFFF2F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${revenue.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: revenue.isIncreasing
                                ? const Color(0xFF41C980)
                                : const Color(0xFFEB5757),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          revenue.isIncreasing
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 12,
                          color: revenue.isIncreasing
                              ? const Color(0xFF41C980)
                              : const Color(0xFFEB5757),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Revenue Amount
                  Row(
                    children: [
                      const Text(
                        'ر.س',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF626C83),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        revenue.currentRevenue.toStringAsFixed(0),
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w700,
                          fontSize: 32,
                          color: Color(0xFF1D2035),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Chart Area with real data
          Container(
            height: 123,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: RevenueChartPainter(revenue.chartData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidAdvertisements() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header
          const Text(
            'الأعلانات المدفوعة',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF111317),
            ),
          ),
          
          const SizedBox(height: 4),
          
          StreamBuilder<List<PaidAdvertisement>>(
            stream: _dashboardService.getPaidAdvertisements(widget.merchantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                    ),
                  ),
                );
              }

              final advertisements = snapshot.data ?? [];
              final totalProducts = advertisements.length;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
          Text(
                    'تم شحن ${_formatNumber(totalProducts)} منتج حتى الان',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: const Color(0xFF626C83).withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Product List
                  if (advertisements.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
            children: [
                            Icon(
                              Icons.campaign_outlined,
                              size: 48,
                              color: Color(0xFF9A46D7),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'لا توجد إعلانات مدفوعة حالياً',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 16,
                                color: Color(0xFF626C83),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'ابدأ في إنشاء إعلانات لمنتجاتك لزيادة المبيعات',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 12,
                                color: Color(0xFF9A46D7),
                              ),
                              textAlign: TextAlign.center,
              ),
            ],
          ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        // أول 3 إعلانات فقط
                        ...advertisements.take(3).map((ad) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildProductItemFromData(ad),
                        )).toList(),
          
          const SizedBox(height: 16),
          
          // Show More Button
                        if (advertisements.length > 3)
                          GestureDetector(
                            onTap: () {
                              _showComingSoonMessage('عرض جميع الإعلانات');
                            },
                            child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E6EE)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
                              child: Text(
                                'اظهر المزيد (${advertisements.length - 3})',
                                style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF111317),
              ),
              textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductItemFromData(PaidAdvertisement ad) {
    final statusText = _getAdStatusText(ad.status);
    final statusColor = _getAdStatusColor(ad.status);
    
    return Container(
      height: 109,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          // Product Image (RTL Layout - Right side)
          Container(
            width: 77,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9E9),
              borderRadius: BorderRadius.circular(13),
              image: ad.productImageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(ad.productImageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: ad.productImageUrl.isEmpty
                ? const Icon(
                    Icons.shopping_bag,
                    size: 40,
                    color: Colors.grey,
                  )
                : null,
          ),
          
          const SizedBox(width: 16),
          
          // Product Info (RTL Layout - Left side)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ad.productTitle.isNotEmpty ? ad.productTitle : 'عنوان المنتج',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1D2035),
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'عدد المشاهدات : ${_formatNumber(ad.views)}',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF9A46D7),
                  ),
                  textAlign: TextAlign.right,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'حالة الاعلان : $statusText',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: statusColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAdStatusText(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return 'فعال';
      case AdStatus.expired:
        return 'انتهى الاعلان';
      case AdStatus.paused:
        return 'متوقف';
    }
  }

  Color _getAdStatusColor(AdStatus status) {
    switch (status) {
      case AdStatus.active:
        return const Color(0xFF1ED29C);
      case AdStatus.expired:
        return const Color(0xFFF68801);
      case AdStatus.paused:
        return const Color(0xFF626C83);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF1ED29C); // أخضر
      case 'pending':
        return const Color(0xFFFFBB0D); // أصفر
      case 'rejected':
        return const Color(0xFFEB5757); // أحمر
      case 'suspended':
        return const Color(0xFF626C83); // رمادي
      default:
        return const Color(0xFF9A46D7); // بنفسجي افتراضي
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.close;
      case 'suspended':
        return Icons.pause;
      default:
        return Icons.store;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'approved':
        return 'متجر معتمد ✓';
      case 'pending':
        return 'في انتظار المراجعة...';
      case 'rejected':
        return 'طلب مرفوض';
      case 'suspended':
        return 'حساب معلق';
      default:
        return 'متجر جديد';
    }
  }

  Widget _buildStatusNotification() {
    final status = _merchantInfo?['status'] as String? ?? '';
    if (status == 'approved') return const SizedBox.shrink();

    String title = '';
    String message = '';
    IconData icon = Icons.info;
    Color backgroundColor = const Color(0xFFF0F8FF);
    Color borderColor = const Color(0xFF2196F3);

    switch (status) {
      case 'pending':
        title = 'طلبك قيد المراجعة';
        message = 'نحن نراجع طلب التسجيل الخاص بك. سيتم إشعارك عند اكتمال المراجعة.';
        icon = Icons.access_time;
        backgroundColor = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFFFBB0D);
        break;
      case 'rejected':
        title = 'تم رفض الطلب';
        message = 'نأسف، تم رفض طلب التسجيل. يمكنك تقديم طلب جديد مع مراجعة البيانات.';
        icon = Icons.error_outline;
        backgroundColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFEB5757);
        break;
      case 'suspended':
        title = 'تم تعليق الحساب';
        message = 'تم تعليق حسابك التجاري. يرجى التواصل مع الإدارة للحصول على المزيد من المعلومات.';
        icon = Icons.pause_circle_outline;
        backgroundColor = const Color(0xFFF5F5F5);
        borderColor = const Color(0xFF626C83);
        break;
      default:
        title = 'أكمل تسجيل متجرك';
        message = 'لم يتم العثور على طلب تسجيل. يرجى إكمال عملية تسجيل المتجر للحصول على جميع المميزات.';
        icon = Icons.store_outlined;
        backgroundColor = const Color(0xFFF3E5F5);
        borderColor = const Color(0xFF9A46D7);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: borderColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: borderColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: borderColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem({
    required String title,
    required String views,
    required String status,
    required Color statusColor,
    required IconData image,
  }) {
    return Container(
      height: 109,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 77,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9E9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              image,
              size: 40,
              color: Colors.grey,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1D2035),
                  ),
                  textAlign: TextAlign.right,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  views,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF9A46D7),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
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

  Widget _buildCustomerReviews() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Header
          const Text(
            'تعليقات العملاء ',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1D2035),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Reviews List
          StreamBuilder<List<CustomerReview>>(
            stream: _dashboardService.getCustomerReviews(widget.merchantId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                    ),
                  ),
                );
              }

              final reviews = snapshot.data ?? [];
              
              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 48,
                          color: Color(0xFF9A46D7),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد تعليقات حتى الآن',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 16,
                            color: Color(0xFF626C83),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'عندما يقوم العملاء بتقييم منتجاتك ستظهر هنا',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 12,
                            color: Color(0xFF9A46D7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // أول 3 تعليقات فقط
                  ...reviews.take(3).map((review) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildReviewItemFromData(review),
                  )).toList(),
          
          // Show More Button
                  if (reviews.length > 3)
                    GestureDetector(
                      onTap: () {
                        _showComingSoonMessage('عرض جميع التقييمات');
                      },
                      child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE9ECF2), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
                        child: Text(
                          'عرض المزيد (${reviews.length - 3})',
                          style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF1D2035),
              ),
              textAlign: TextAlign.center,
                        ),
            ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItemFromData(CustomerReview review) {
    final formatter = DateFormat('dd/MM/yyyy', 'ar');
    final formattedDate = formatter.format(review.createdAt.toDate());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Header with date and customer info (RTL Layout)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Customer info (Right side in RTL)
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                    image: review.customerImageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(review.customerImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: review.customerImageUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      review.customerName.isNotEmpty ? review.customerName : 'عميل',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF353A62),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 16,
                          color: index < review.rating 
                              ? const Color(0xFFFFBB0D) 
                              : const Color(0xFFDDDDDD),
                        );
                      }).reversed.toList(),
                    ),
                  ],
                ),
              ],
            ),
            
            // Date (Left side in RTL)
            Text(
              formattedDate,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 10,
                color: Color(0xFFBFBFBF),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 14),
        
        // Product info and review (RTL Layout)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image (RTL Layout - Right side)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(13),
                image: review.productImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(review.productImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: review.productImageUrl.isEmpty
                  ? const Icon(
                      Icons.shopping_bag,
                      size: 30,
                      color: Colors.grey,
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Product Info and Review (Left side)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    review.productTitle.isNotEmpty ? review.productTitle : 'منتج',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1D2035),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  if (review.productVariant.isNotEmpty)
                    Text(
                      review.productVariant,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xFF605F5F),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  
                  const SizedBox(height: 14),
                  
                  Text(
                    review.reviewText.isNotEmpty 
                        ? review.reviewText 
                        : 'تعليق العميل على المنتج',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: Color(0xFF1D2035),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewItem({
    required String date,
    required String customerName,
    required int rating,
    required String productName,
    required String productVariant,
    required String review,
    required IconData customerImage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Header with date and customer info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 10,
                color: Color(0xFFBFBFBF),
              ),
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF353A62),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          size: 16,
                          color: index < rating ? const Color(0xFFFFBB0D) : const Color(0xFFDDDDDD),
                        );
                      }).reversed.toList(),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    customerImage,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 14),
        
        // Product info and review (RTL Layout)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info and Review
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1D2035),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    productVariant,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF605F5F),
                    ),
                    textAlign: TextAlign.right,
                  ),
                  
                  const SizedBox(height: 14),
                  
                  Text(
                    review,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: Color(0xFF1D2035),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Product Image (RTL Layout)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.shopping_bag,
                size: 30,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildAddMenuPopup() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showAddMenu = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.45),
          child: Column(
            children: [
              // Spacer to push content to bottom
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAddMenu = false;
                    });
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              
              // Menu content at bottom
              GestureDetector(
                onTap: () {}, // منع إغلاق القائمة عند الضغط عليها
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 90), // مساحة للشريط السفلي
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 55),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(26),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Directionality(
                    textDirection: ui.TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Close button and title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                              },
                              child: Container(
                                width: 27,
                                height: 27,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFF121212),
                                ),
                              ),
                            ),
                            
                            const Text(
                              'أضافة',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                color: Color(0xFF1D2035),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Menu items
                        Column(
                          children: [
                            _buildAddMenuItem(
                              icon: Icons.shopping_bag,
                              title: 'إضافة منتج جديد',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                // Navigate to add product page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddProductPage(),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildAddMenuItem(
                              icon: Icons.favorite,
                              title: 'إضافة خدمة جديد',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                // Navigate to add service page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddProductPage(),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                                        _buildAddMenuItem(
              icon: Icons.home_repair_service,
              title: 'إضافة قسم جديد',
              onTap: () {
                setState(() {
                  _showAddMenu = false;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCategoryPage(),
                  ),
                );
              },
            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildAddMenuItem(
                              icon: Icons.bar_chart,
                              title: 'إنشاء إعلان جديد',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                _showComingSoonMessage('إنشاء إعلان جديد');
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildAddMenuItem(
                              icon: Icons.local_offer,
                              title: 'إنشاء عرض خصومات',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                _showComingSoonMessage('إنشاء عرض خصومات');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6FE),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                size: 24,
                color: const Color(0xFF9A46D7),
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: Color(0xFF4A5E6D),
                  height: 1.4,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chart Painter for Revenue Chart with real data
class RevenueChartPainter extends CustomPainter {
  final List<RevenueDataPoint> data;

  RevenueChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      _drawEmptyChart(canvas, size);
      return;
    }

    final paint = Paint()
      ..color = const Color(0xFFEEAA43)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Find min and max values for scaling
    final values = data.map((point) => point.value).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    
    // Handle case where all values are the same
    final valueRange = maxValue - minValue;
    final effectiveRange = valueRange == 0 ? 1 : valueRange;

    final points = <Offset>[];
    
    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      final normalizedValue = (data[i].value - minValue) / effectiveRange;
      final y = size.height * (1 - normalizedValue * 0.8); // Use 80% of height
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
    path.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE6E9ED)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

      for (int i = 1; i < data.length; i++) {
        final x = (size.width / (data.length - 1)) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * 0.9),
        gridPaint,
      );
    }

      // Draw point indicator for the last point
      if (points.isNotEmpty) {
    final pointPaint = Paint()
      ..color = const Color(0xFFEEAA43)
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

        final lastPoint = points.last;
        canvas.drawCircle(lastPoint, 6, pointBorderPaint);
        canvas.drawCircle(lastPoint, 6, pointPaint);
      }
    }
  }

  void _drawEmptyChart(Canvas canvas, Size size) {
    // Draw a flat line when no data
    final paint = Paint()
      ..color = const Color(0xFFE6E9ED)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final y = size.height * 0.5;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE6E9ED)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 7; i++) {
      final x = (size.width / 6) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * 0.9),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RevenueChartPainter oldDelegate) {
    return data != oldDelegate.data;
  }
}
