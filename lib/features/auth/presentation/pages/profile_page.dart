import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumi/features/auth/presentation/pages/auth_gate.dart';
import 'package:sumi/features/auth/presentation/pages/help_center_page.dart';
import 'package:sumi/features/auth/presentation/pages/my_points_page.dart';
import 'package:sumi/features/auth/presentation/pages/share_and_earn_page.dart';
import 'package:sumi/features/auth/presentation/pages/withdrawal_history_page.dart';
import 'package:sumi/features/store/presentation/pages/my_cards_page.dart';
import 'package:sumi/features/auth/services/auth_service.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:sumi/main.dart';
import 'package:sumi/features/auth/presentation/pages/addresses_page.dart';
import 'package:sumi/features/wallet/presentation/pages/wallet_page.dart';
import 'package:sumi/features/story/presentation/pages/story_settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final TextEditingController _deleteConfirmController = TextEditingController();
  
  @override
  void dispose() {
    _deleteConfirmController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final l10n = AppLocalizations.of(context)!;
    // Determine the text direction for manual adjustments if needed
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF9A46D7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top section with profile header
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF9A46D7),
                      Colors.white,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfileImage(user),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.displayName ?? l10n.profile_default_name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.profile_manage_account,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Subscription status card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A46D7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildSubscriptionItem(isRtl, l10n.profile_reward_points, l10n.profile_days_remaining(230), 'assets/images/logo.png')),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withAlpha(51),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(child: _buildSubscriptionItem(isRtl, l10n.profile_subscription_status, l10n.profile_free, null)),
                    ],
                  ),
                ),
              ),
              
              // Profile menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.wallet_outlined,
                      iconBgColor: const Color(0xFFFAF6FE),
                      iconColor: const Color(0xFF9A46D7),
                      title: l10n.profile_transactions,
                      subtitle: l10n.profile_transactions_subtitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const WalletPage()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.credit_card_outlined,
                      iconBgColor: const Color(0xFFFAF6FE),
                      iconColor: const Color(0xFF9A46D7),
                      title: l10n.profile_my_cards,
                      subtitle: l10n.profile_my_cards_subtitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyCardsPage()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.shield_outlined,
                      iconBgColor: const Color(0xFFFAF6FE),
                      iconColor: const Color(0xFF9A46D7),
                      title: l10n.profile_my_points,
                      subtitle: l10n.profile_my_points_subtitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyPointsPage()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.share_outlined,
                      iconBgColor: const Color(0xFFFAF6FE),
                      iconColor: const Color(0xFF9A46D7),
                      title: l10n.profile_share_and_earn,
                      subtitle: l10n.profile_share_and_earn_subtitle,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ShareAndEarnPage()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      iconBgColor: const Color(0xFFFAF6FE),
                      iconColor: const Color(0xFF9A46D7),
                      title: l10n.profile_my_profile,
                      subtitle: l10n.profile_my_profile_subtitle,
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.language_outlined,
                      iconBgColor: const Color(0xFFFAF6FE),
                      iconColor: const Color(0xFF9A46D7),
                      title: l10n.profile_language,
                      subtitle: l10n.profile_language_subtitle,
                      onTap: () => _showLanguageDialog(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      iconBgColor: const Color(0xFFFAF6FE),
                      iconColor: const Color(0xFF9A46D7),
                       title: l10n.helpCenterTitle,
                       subtitle: l10n.contactUs,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HelpCenterPage()),
                        );
                      },
                    ),
                      _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      iconBgColor: const Color(0xFFFAF6FE),
                      iconColor: const Color(0xFF9A46D7),
                      title: l10n.profile_my_addresses,
                      subtitle: l10n.profile_my_addresses_subtitle,
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (context) => const AddressesPage()),
                         );
                       },
                    ),
                    
                    // إعدادات القصص
                    _buildMenuItem(
                      icon: Icons.auto_stories_outlined,
                      iconBgColor: const Color(0xFF9A46D7).withOpacity(0.1),
                      iconColor: const Color(0xFF9A46D7),
                      title: 'إعدادات القصص',
                      subtitle: 'الخصوصية والإشعارات والوضع المظلم',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const StorySettingsPage()),
                        );
                      },
                    ),
                    
                    const Divider(height: 32),
                    // زر حذف الحساب
                    _buildMenuItem(
                      icon: Icons.delete_forever_outlined,
                      iconBgColor: Colors.red.withOpacity(0.1),
                      iconColor: Colors.red.shade700,
                      title: 'حذف الحساب نهائياً',
                      subtitle: 'حذف الحساب وجميع البيانات المرتبطة به',
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                    const SizedBox(height: 16),
                    // زر تسجيل الخروج
                     _buildMenuItem(
                      icon: Icons.logout,
                      iconBgColor: Colors.orange.withOpacity(0.1),
                      iconColor: Colors.orange.shade700,
                      title: l10n.profile_sign_out,
                      subtitle: l10n.profile_sign_out_subtitle,
                      onTap: () async {
                        await _authService.signOut();
                        // Navigate to the AuthGate and remove all previous routes
                        if (mounted) {
                           Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthGate()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', width: 50, height: 50),
                    const SizedBox(width: 32),
                    Image.asset('assets/images/logo.png', width: 50, height: 50),
                    const SizedBox(width: 32),
                    Image.asset('assets/images/logo.png', width: 50, height: 50),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'جميع الحقوق محفوظة | تطبيق سومي Somi',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7991A4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileImage(User? user) {
    final photoURL = user?.photoURL;
    final displayName = user?.displayName ?? 'Sumi';

    return Hero(
      tag: 'profile-image',
      child: CircleAvatar(
        radius: 34,
        backgroundColor: const Color(0xFFAAB9C5),
        child: CircleAvatar(
          radius: 33,
          backgroundImage: (photoURL != null && photoURL.isNotEmpty)
              ? CachedNetworkImageProvider(photoURL)
              : null,
          child: (photoURL == null || photoURL.isEmpty)
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                  style: const TextStyle(fontSize: 32, color: Colors.white),
                )
              : null,
        ),
      ),
    );
  }
  
  Widget _buildSubscriptionItem(bool isRtl, String title, String subtitle, String? imagePath) {
    Widget iconWidget;
    if (imagePath != null) {
      iconWidget = Image.asset(imagePath, width: 24, height: 24,);
    } else {
      iconWidget = const Icon(Icons.shield_outlined, color: Colors.white, size: 20);
    }

    final children = [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis,),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEBD9FB))),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFAF66E6),
          borderRadius: BorderRadius.circular(26),
        ),
        child: iconWidget,
      ),
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: isRtl ? children.reversed.toList() : children,
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2833),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF909AA3),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFC8CED5)),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.dialog_choose_language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.dialog_arabic),
                onTap: () {
                  _changeLanguage(context, 'ar');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text(l10n.dialog_english),
                onTap: () {
                  _changeLanguage(context, 'en');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    MyApp.setLocale(context, Locale(languageCode));
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'تحذير!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هل أنت متأكد من حذف حسابك نهائياً؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سيتم حذف نهائياً:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDeleteItem('• جميع منشوراتك وتعليقاتك'),
                    _buildDeleteItem('• نقاطك وتحدياتك'),
                    _buildDeleteItem('• بيانات الإحالة والأرباح'),
                    _buildDeleteItem('• بطاقاتك ومعاملاتك'),
                    _buildDeleteItem('• جميع البيانات الشخصية'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'هذا الإجراء لا يمكن التراجع عنه!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showConfirmationStep(context);
                },
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text(
                  'حذف نهائياً',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showConfirmationStep(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'تأكيد نهائي',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.red,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_forever,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'اكتب "حذف" لتأكيد حذف حسابك نهائياً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'اكتب: حذف',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                      ),
                    ),
                    controller: _deleteConfirmController,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _deleteConfirmController.clear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: _deleteConfirmController.text == 'حذف'
                      ? () => _performDeleteAccount(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'حذف الحساب',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performDeleteAccount(BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog
    
    // Show info snack bar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'بدء عملية حذف الحساب... قد يتطلب إعادة تسجيل دخول لأغراض الأمان',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Small delay to let the snackbar show
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Colors.red.shade600,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                'جاري حذف الحساب...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'حذف البيانات الشخصية...',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'حذف الحساب من النظام...',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final success = await _authService.deleteUserAccount();
      
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        } catch (navError) {
          debugPrint('Navigator error: $navError');
        }
        
        if (success) {
          // Navigate to AuthGate and remove all routes
          try {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthGate()),
              (Route<dynamic> route) => false,
            );
          } catch (navError) {
            debugPrint('Navigation error after deletion: $navError');
            // Force app restart if navigation fails
            return;
          }
        } else {
          _showErrorDialog(context, 'فشل في حذف الحساب. حاول مرة أخرى.');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        } catch (navError) {
          debugPrint('Navigator error: $navError');
        }
        
        if (e.code == 'requires-recent-login') {
          try {
            _showReLoginDialog(context);
          } catch (dialogError) {
            debugPrint('Dialog error: $dialogError');
          }
        } else {
          try {
            _showErrorDialog(context, e.message ?? 'حدث خطأ أثناء حذف الحساب');
          } catch (dialogError) {
            debugPrint('Dialog error: $dialogError');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
        } catch (navError) {
          debugPrint('Navigator error: $navError');
        }
        try {
          _showErrorDialog(context, 'حدث خطأ غير متوقع: $e');
        } catch (dialogError) {
          debugPrint('Dialog error: $dialogError');
        }
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('خطأ'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('موافق', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReLoginDialog(BuildContext context) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security_outlined,
                color: Colors.orange.shade700,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'مطلوب إعادة تسجيل دخول',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(height: 8),
              const Text(
                'لأغراض الأمان، يتطلب حذف الحساب تسجيل دخول حديث.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'سيتم تسجيل خروجك الآن. بعد إعادة تسجيل الدخول، يمكنك المحاولة مرة أخرى.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text(
              'إلغاء',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade700],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                // Close dialog first
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.of(dialogContext).pop();
                }
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingContext) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                );
                
                // Sign out
                await _authService.signOut();
                
                // Close loading dialog and navigate
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(); // Close loading
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'تسجيل خروج وإعادة دخول',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 