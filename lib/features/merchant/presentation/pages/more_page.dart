import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/merchant_service.dart';
import '../../services/merchant_dashboard_service.dart';
import '../../services/merchant_login_service.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/presentation/pages/auth_gate.dart';
import '../../../auth/presentation/pages/help_center_page.dart';
import 'add_product_page.dart';
import 'manage_categories_page.dart';
import 'payment_methods_settings_page.dart';
import 'payment_integration_test_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final MerchantService _merchantService = MerchantService.instance;
  final MerchantDashboardService _dashboardService = MerchantDashboardService.instance;
  final MerchantLoginService _merchantLoginService = MerchantLoginService.instance;
  final AuthService _authService = AuthService();
  
  Map<String, dynamic>? _merchantData;
  bool _isLoading = true;
  String _merchantId = 'merchant_sample_123'; // يجب الحصول على معرف التاجر الحقيقي

  @override
  void initState() {
    super.initState();
    _getCurrentMerchantId();
    _loadMerchantData();
  }

  Future<void> _getCurrentMerchantId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _merchantId = user.uid;
      }
    } catch (e) {
      debugPrint('Error getting current merchant ID: $e');
    }
  }

  Future<void> _loadMerchantData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // تحميل البيانات الحقيقية من نفس مصدر الصفحة الرئيسية
      final merchantInfo = await _dashboardService.getMerchantBasicInfo(_merchantId);
      
      if (mounted) {
        setState(() {
          _merchantData = {
            'name': merchantInfo?['businessName'] ?? 'متجر الإلكترونيات المتقدمة',
            'code': _dashboardService.generateStoreCode(_merchantId),
            'rating': 4.3,
            'logo': merchantInfo?['profileImageUrl'], // الصورة الحقيقية
            'description': merchantInfo?['businessDescription'] ?? 
                'وصف بسيط عن المتجر هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى..',
            'subscriptionType': 'الباقة المتقدمة',
            'renewalDate': '2025/04/22',
            'isVerified': merchantInfo?['isVerified'] ?? false,
            'status': merchantInfo?['status'] ?? 'pending',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading merchant data: $e');
      // في حالة الخطأ، استخدم بيانات تجريبية
      if (mounted) {
        setState(() {
          _merchantData = {
            'name': 'متجر الإلكترونيات المتقدمة',
            'code': '115415',
            'rating': 4.3,
            'logo': null,
            'description': 'وصف بسيط عن المتجر هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى..',
            'subscriptionType': 'الباقة المتقدمة',
            'renewalDate': '2025/04/22',
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildMerchantProfile(),
                _buildSettingsSection(),
                _buildMoreSettingsSection(),
                _buildLogoutSection(),
                _buildFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }











  Widget _buildMerchantProfile() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 34, 24, 0),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9A46D7),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 34, 24, 0),
      child: Column(
        children: [
          // Store profile section
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    // Store logo
                    Container(
                      width: 72,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE1E1E1),
                      ),
                      child: ClipOval(
                        child: _merchantData?['logo'] != null
                            ? Image.network(
                                _merchantData!['logo'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 36,
                                  );
                                },
                              )
                            : Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _merchantData?['name'] ?? 'متجر الإلكترونيات المتقدمة',
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D2035),
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFEED9),
                                  borderRadius: BorderRadius.circular(48),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${_merchantData?['rating']?.toStringAsFixed(1) ?? '4.3'}',
                                      style: TextStyle(
                                        fontFamily: 'Ping AR + LT',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF313131),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.star,
                                      color: Color(0xFFFEAA43),
                                      size: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'كود المتجر : ${_merchantData?['code'] ?? '115415'}',
                                style: TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFAAB9C5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  _merchantData?['description'] ?? 
                  'وصف بسيط عن المتجر هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى..',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A5E6D),
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 18),
                // Subscription info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF9A46D7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Premium icon
                      Container(
                        width: 45,
                        height: 45,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Color(0xFFAF66E6),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'إشتراك المتجر',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _merchantData?['subscriptionType'] ?? 'الباقة المتقدمة',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEBD9FB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'تاريخ التجديد',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _merchantData?['renewalDate'] ?? '2025/04/22',
                              style: TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEBD9FB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // First row - 3 items only to prevent overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSettingsCard(
                icon: Icons.credit_card,
                title: 'وسائل الدفع',
                onTap: () => _navigateToPaymentMethods(),
              ),
              _buildSettingsCard(
                icon: Icons.bug_report,
                title: 'اختبار نظام الدفع',
                onTap: () => _navigateToPaymentTest(),
              ),
              _buildSettingsCard(
                icon: Icons.local_shipping,
                title: 'شركات الشحن',
                onTap: () => _showComingSoon('شركات الشحن'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Second row - 3 items to prevent overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSettingsCard(
                icon: Icons.location_on,
                title: 'إدارة العناوين',
                onTap: () => _showComingSoon('إدارة العناوين'),
              ),
              _buildSettingsCard(
                icon: Icons.shield,
                title: 'بيانات المتجر',
                onTap: () => _showComingSoon('بيانات المتجر'),
              ),
              _buildSettingsCard(
                icon: Icons.business_center,
                title: 'خدمات التاجر',
                onTap: () => _showComingSoon('خدمات التاجر'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Third row - 3 items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSettingsCard(
                icon: Icons.star_rate,
                title: 'إدارة التقييمات',
                onTap: () => _showComingSoon('إدارة التقييمات'),
              ),
              _buildSettingsCard(
                icon: Icons.people,
                title: 'أدارة الموظفين',
                onTap: () => _showComingSoon('أدارة الموظفين'),
              ),
              _buildSettingsCard(
                icon: Icons.account_balance_wallet,
                title: 'إدارة المحفظة',
                onTap: () => _showComingSoon('إدارة المحفظة'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Color(0xFFFAF6FE),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: Color(0xFF9A46D7),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF353A62),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSettingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'المزيد من الاعدادات',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsMenuItem(
            icon: Icons.person,
            title: 'الملف الشخصي',
            subtitle: 'تعديل البيانات - الدخول وكلمة السر - اللغة',
            backgroundColor: Color(0xFFF8F8F8),
            onTap: () => _showComingSoon('الملف الشخصي'),
          ),
          _buildSettingsMenuItem(
            icon: Icons.rocket_launch_outlined,
            title: 'خدمات سومي',
            subtitle: 'من نحن - وكلائنا',
            backgroundColor: Color(0xFFFFEED9),
            onTap: () => _showComingSoon('خدمات سومي'),
          ),
          _buildSettingsMenuItem(
            icon: Icons.verified_user,
            title: 'مركز المبدعين',
            subtitle: 'مساحة مخصصة لصناع المحتوى والمؤثرين بالمجتمع',
            backgroundColor: Color(0xFFF8F8F8),
            onTap: () => _showComingSoon('مركز المبدعين'),
          ),
          _buildSettingsMenuItem(
            icon: Icons.lightbulb_outline,
            title: 'الإقتراحات',
            subtitle: ' شاركنا أفكارك وساعد في تطوير مجتمع سومي',
            backgroundColor: Color(0xFFF8F8F8),
            onTap: () => _showComingSoon('الإقتراحات'),
          ),
          _buildSettingsMenuItem(
            icon: Icons.help_center_outlined,
            title: 'مركز المساعدة',
            subtitle: 'الأسئلة الشائعة - سياسة الخصوصية - الشروط والأحكام',
            backgroundColor: Color(0xFFF8F8F8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpCenterPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(
              Icons.chevron_right,
              color: Color(0xFFC6C8CB),
              size: 16,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2035),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9DA2A7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(48),
              ),
              child: Icon(
                icon,
                color: Color(0xFF7991A4),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: GestureDetector(
        onTap: _logout,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'تسجيل الخروج ',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD01B2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'سوف يتطلب منك تسجيل معلومات الدخول مرة أخري',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7991A4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFFADCDF),
                borderRadius: BorderRadius.circular(48),
              ),
              child: Icon(
                Icons.exit_to_app,
                color: Color(0xFFD01B2D),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 29, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 55.04,
                height: 61.16,
                decoration: BoxDecoration(
                  color: Color(0xFFE1E1E1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 32),
              Container(
                width: 90.52,
                height: 61.16,
                decoration: BoxDecoration(
                  color: Color(0xFFE1E1E1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 32),
              Container(
                width: 43.42,
                height: 61.16,
                decoration: BoxDecoration(
                  color: Color(0xFFE1E1E1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 29),
          Text(
            'جميع الحقوق محفوظة | تطبيق سومي Somi ',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7991A4),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ميزة "$feature" ستكون متاحة قريباً',
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

  void _logout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout,
                color: Color(0xFFE32B3D),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1D2035),
                ),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج من حساب التاجر؟\nسيتم إعادة توجيهك إلى صفحة تسجيل الدخول.',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              color: Color(0xFF637D92),
            ),
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF637D92),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE32B3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () async {
                  // إغلاق الحوار أولاً
                  Navigator.pop(dialogContext);
                  
                  // عرض مؤشر التحميل
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingContext) => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                      ),
                    ),
                  );
                  
                  try {
                    // تسجيل الخروج من جميع الخدمات
                    await _authService.signOut();
                    await _merchantLoginService.signOut();
                    
                    // إغلاق مؤشر التحميل
                    if (mounted) {
                      Navigator.pop(context);
                      
                      // الانتقال إلى صفحة تسجيل الدخول
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const AuthGate()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  } catch (e) {
                    // إغلاق مؤشر التحميل في حالة الخطأ
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'حدث خطأ أثناء تسجيل الخروج. يرجى المحاولة مرة أخرى.',
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                            ),
                          ),
                          backgroundColor: Color(0xFFE32B3D),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPaymentMethods() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentMethodsSettingsPage(),
      ),
    );
  }

  void _navigateToPaymentTest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentIntegrationTestPage(),
      ),
    );
  }
}