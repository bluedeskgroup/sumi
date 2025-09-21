import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/merchant_model.dart';
import '../../services/merchant_service.dart';
import '../../services/merchant_notification_service.dart';
import '../../services/merchant_auth_service.dart';

class MerchantPendingApprovalPage extends StatefulWidget {
  final String? merchantId;
  final bool showBackButton;

  const MerchantPendingApprovalPage({
    super.key,
    this.merchantId,
    this.showBackButton = false,
  });

  @override
  State<MerchantPendingApprovalPage> createState() => _MerchantPendingApprovalPageState();
}

class _MerchantPendingApprovalPageState extends State<MerchantPendingApprovalPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  
  final MerchantService _merchantService = MerchantService.instance;
  final MerchantAuthService _merchantAuthService = MerchantAuthService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  MerchantModel? _merchant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // إعداد الرسوم المتحركة
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    
    _loadMerchantData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _loadMerchantData() async {
    try {
      final merchant = await _merchantService.getCurrentUserMerchantRequest();
      if (mounted) {
        setState(() {
          _merchant = merchant;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showBackButton
          ? AppBar(
              title: const Text('حالة الطلب'),
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            )
          : null,
      body: _buildAutoRefreshBody(),
    );
  }

  Widget _buildAutoRefreshBody() {
    final user = _auth.currentUser;
    
    // إذا لم يكن هناك مستخدم مسجل دخول
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // مراقبة حالة التاجر في الوقت الفعلي
    return StreamBuilder<MerchantAuthResult>(
      stream: _merchantAuthService.watchMerchantStatus(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.hasData) {
          final result = snapshot.data!;
          
          // إذا تغيرت الحالة من pending لأي حالة أخرى
          if (result.status != MerchantAuthStatus.merchantPending) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _handleStatusChange(result);
            });
          }
          
          // تحديث بيانات التاجر
          if (result.merchant != null) {
            _merchant = result.merchant;
          }
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildAnimatedIcon(),
                  const SizedBox(height: 40),
                  _buildStatusCard(),
                  const SizedBox(height: 32),
                  _buildInfoCard(),
                  const SizedBox(height: 32),
                  _buildNextStepsCard(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'حدث خطأ في تحميل البيانات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadMerchantData();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // دائرة متحركة خارجية
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
            
            // أيقونة دوارة في الوسط
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value * 2.0 * 3.14159,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hourglass_empty,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'جارى مراجعة حسابك',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'قيد المراجعة',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تم استلام طلب التسجيل الخاص بك بنجاح',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'فريق المراجعة يقوم حالياً بدراسة طلبك والتأكد من صحة البيانات المقدمة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_merchant != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'رقم الطلب:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _copyToClipboard(_merchant!.id.substring(0, 8).toUpperCase()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _merchant!.id.substring(0, 8).toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'تاريخ التقديم:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  _formatDate(_merchant!.createdAt),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              const Text(
                'معلومات مهمة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('⏱️', 'مدة المراجعة: 2-3 أيام عمل'),
          _buildInfoRow('📧', 'ستصلك رسالة عبر الإيميل عند اتخاذ القرار'),
          _buildInfoRow('📱', 'يمكنك متابعة حالة الطلب من التطبيق'),
          _buildInfoRow('🔒', 'لا يمكن الوصول للحساب حتى تتم الموافقة'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              const Text(
                'الخطوات القادمة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepRow('1', 'مراجعة البيانات المقدمة', true),
          _buildStepRow('2', 'التحقق من صحة الوثائق', false),
          _buildStepRow('3', 'الموافقة النهائية', false),
          _buildStepRow('4', 'تفعيل الحساب وإرسال التأكيد', false),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String text, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.green[800] : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _refreshStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('تحديث الحالة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.support_agent),
                label: const Text('تواصل معنا'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF667EEA)),
                  foregroundColor: const Color(0xFF667EEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (widget.showBackButton) ...[
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل خروج'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ رقم الطلب'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _refreshStatus() async {
    setState(() {
      _isLoading = true;
    });

    await _loadMerchantData();

    if (_merchant?.status == MerchantStatus.approved) {
      // إذا تم قبول التاجر، الانتقال للصفحة الرئيسية
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تهانينا! تم قبول طلبك'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      // هنا يمكن الانتقال للصفحة الرئيسية
      Navigator.of(context).pushReplacementNamed('/home');
    } else if (_merchant?.status == MerchantStatus.rejected) {
      // إذا تم رفض التاجر
      _showRejectionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا يوجد تحديث جديد'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            const Text('تم رفض الطلب'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نأسف لإبلاغك بأنه تم رفض طلب تسجيلك كتاجر.',
              style: TextStyle(fontSize: 16),
            ),
            if (_merchant?.statusReason != null) ...[
              const SizedBox(height: 16),
              const Text(
                'السبب:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(_merchant!.statusReason!),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تواصل معنا'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('يمكنك التواصل معنا عبر:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.green),
                SizedBox(width: 8),
                Text('01234567890'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 8),
                Text('support@yourapp.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.chat, color: Colors.orange),
                SizedBox(width: 8),
                Text('الدردشة المباشرة'),
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

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleStatusChange(MerchantAuthResult result) {
    switch (result.status) {
      case MerchantAuthStatus.merchantApproved:
        _showApprovedDialog();
        break;
      case MerchantAuthStatus.merchantRejected:
        _showRejectionDialog();
        break;
      case MerchantAuthStatus.merchantSuspended:
        _showSuspendedDialog();
        break;
      default:
        break;
    }
  }

  void _showApprovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('تم قبول الطلب'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تهانينا! تم قبول طلب تسجيلك كتاجر بنجاح.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'يمكنك الآن الوصول لحسابك التجاري والبدء في إدارة متجرك.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // الانتقال للصفحة الرئيسية للتاجر
              Navigator.of(context).pushReplacementNamed('/merchant-home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('بدء العمل'),
          ),
        ],
      ),
    );
  }

  void _showSuspendedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.pause_circle, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            const Text('تم تعليق الحساب'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تم تعليق حسابك التجاري مؤقتاً.',
              style: TextStyle(fontSize: 16),
            ),
            if (_merchant?.statusReason != null) ...[
              const SizedBox(height: 16),
              const Text(
                'السبب:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(_merchant!.statusReason!),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
