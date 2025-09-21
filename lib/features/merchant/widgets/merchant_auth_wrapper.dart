import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/merchant_auth_service.dart';
import '../services/merchant_notification_service.dart';
import '../presentation/pages/merchant_pending_approval_page.dart';
import '../presentation/pages/main_merchant_page.dart';
import '../models/merchant_model.dart';

/// Widget wrapper للتحقق من حالة التاجر وتوجيهه للصفحة المناسبة
class MerchantAuthWrapper extends StatefulWidget {
  /// الصفحة التي سيتم عرضها إذا كان المستخدم مصرح له بالوصول
  final Widget homeWidget;
  
  /// صفحة تسجيل الدخول إذا لم يكن المستخدم مسجل دخول
  final Widget? loginWidget;

  const MerchantAuthWrapper({
    super.key,
    required this.homeWidget,
    this.loginWidget,
  });

  @override
  State<MerchantAuthWrapper> createState() => _MerchantAuthWrapperState();
}

class _MerchantAuthWrapperState extends State<MerchantAuthWrapper> {
  final MerchantAuthService _merchantAuthService = MerchantAuthService.instance;
  final MerchantNotificationService _notificationService = MerchantNotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, authSnapshot) {
        // إذا كان يتم تحميل حالة المصادقة
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // إذا لم يكن المستخدم مسجل دخول
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return widget.loginWidget ?? _buildLoginRequired();
        }

        final user = authSnapshot.data!;

        // مراقبة الإشعارات للتغييرات الفورية
        return StreamBuilder<MerchantStatusChange?>(
          stream: _notificationService.watchMerchantStatus(),
          builder: (context, notificationSnapshot) {
            // إظهار إشعار إذا تغيرت الحالة
            if (notificationSnapshot.hasData && notificationSnapshot.data != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _notificationService.showStatusChangeNotification(
                  context,
                  notificationSnapshot.data!,
                );
                
                // تسجيل الإشعار
                _notificationService.logNotification(user.uid, notificationSnapshot.data!);
              });
            }

            // مراقبة حالة التاجر في الوقت الفعلي
            return StreamBuilder<MerchantAuthResult>(
              stream: _merchantAuthService.watchMerchantStatus(user),
              builder: (context, merchantSnapshot) {
                // إذا كان يتم تحميل حالة التاجر
                if (merchantSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // إذا حدث خطأ في التحقق
                if (merchantSnapshot.hasError || !merchantSnapshot.hasData) {
                  return _buildErrorWidget(merchantSnapshot.error?.toString());
                }

                final merchantResult = merchantSnapshot.data!;

                // توجيه المستخدم حسب حالته
                switch (merchantResult.status) {
                  case MerchantAuthStatus.merchantPending:
                    // التاجر في انتظار الموافقة - مع مراقبة التحديثات الفورية
                    return MerchantPendingApprovalPage(
                      merchantId: merchantResult.merchant?.id,
                      showBackButton: true,
                    );

                  case MerchantAuthStatus.merchantRejected:
                    // التاجر مرفوض
                    return _buildRejectedWidget(merchantResult.merchant!);

                  case MerchantAuthStatus.merchantSuspended:
                    // التاجر معلق
                    return _buildSuspendedWidget(merchantResult.merchant!);

                  case MerchantAuthStatus.merchantApproved:
                    // التاجر مقبول - توجيهه لصفحة التاجر الخاصة
                    return MainMerchantPage(merchantId: merchantResult.merchant!.id);

                  case MerchantAuthStatus.notMerchant:
                    // مستخدم عادي - يمكنه الوصول للتطبيق العادي
                    return widget.homeWidget;

                  case MerchantAuthStatus.error:
                  default:
                    return _buildErrorWidget(merchantResult.errorMessage);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoginRequired() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'تسجيل الدخول مطلوب',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'يرجى تسجيل الدخول للوصول لهذه الصفحة',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // الانتقال لصفحة تسجيل الدخول
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('تسجيل الدخول', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedWidget(MerchantModel merchant) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'تم رفض طلب التسجيل',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'نأسف لإبلاغك بأنه تم رفض طلب تسجيلك كتاجر',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (merchant.statusReason != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'سبب الرفض:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        merchant.statusReason!,
                        style: TextStyle(color: Colors.red[800]),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // إمكانية إعادة التقديم (يمكن تفعيلها لاحقاً)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يمكنك إعادة التقديم بعد تصحيح البيانات المطلوبة'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة التقديم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // الانتقال للصفحة الرئيسية كمستخدم عادي
                        Navigator.of(context).pushReplacementNamed('/home');
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('الانتقال للصفحة الرئيسية'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF667EEA)),
                        foregroundColor: const Color(0xFF667EEA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _signOut(),
                    icon: const Icon(Icons.logout, color: Colors.grey),
                    label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuspendedWidget(MerchantModel merchant) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_circle_filled,
                  size: 60,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'تم تعليق حسابك التجاري',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'تم تعليق حسابك التجاري مؤقتاً. يرجى التواصل مع الإدارة لمعرفة التفاصيل',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              if (merchant.statusReason != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'السبب:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        merchant.statusReason!,
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showContactSupportDialog();
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('تواصل مع الدعم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => _signOut(),
                    icon: const Icon(Icons.logout, color: Colors.grey),
                    label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String? errorMessage) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 80,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'حدث خطأ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // إعادة تحميل الصفحة
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تواصل مع الدعم'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('يمكنك التواصل معنا عبر الطرق التالية:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green),
                SizedBox(width: 12),
                Expanded(child: Text('الهاتف: 01234567890')),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(child: Text('البريد: support@yourapp.com')),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(child: Text('أوقات العمل: 9 صباحاً - 5 مساءً')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تسجيل الخروج: $e')),
      );
    }
  }
}
