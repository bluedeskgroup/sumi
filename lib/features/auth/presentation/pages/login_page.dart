import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumi/features/auth/services/auth_service.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sumi/features/auth/presentation/pages/otp_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:sumi/core/services/user_type_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _phoneNumber = '';
  bool _isSendingCode = false;
  Country _selectedCountry = Country.parse('SA'); // Default to Saudi Arabia

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_phoneNumber.isEmpty) return;

    setState(() {
      _isSendingCode = true;
    });

    AuthService().signInWithPhone(
      phoneNumber: _phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (mounted) {
          setState(() {
            _isSendingCode = false;
          });
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _isSendingCode = false;
          });
          
          String errorMessage = 'حدث خطأ في إرسال رمز التحقق';
          bool showGoogleOption = false;
          
          if (e.code == 'too-many-requests') {
            errorMessage = 'تم تجاوز الحد الأقصى للمحاولات. جرب تسجيل الدخول باستخدام Google';
            showGoogleOption = true;
          } else if (e.code == 'invalid-phone-number') {
            errorMessage = 'رقم الهاتف غير صحيح';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'تم تجاوز الحد اليومي. جرب تسجيل الدخول باستخدام Google غداً';
            showGoogleOption = true;
          } else if (e.message?.contains('blocked') == true) {
            errorMessage = 'تم حظر الهاتف مؤقتاً. جرب تسجيل الدخول باستخدام Google';
            showGoogleOption = true;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 6),
              action: showGoogleOption
                  ? SnackBarAction(
                      label: 'جرب Google',
                      textColor: Colors.white,
                      onPressed: _signInWithGoogle,
                    )
                  : null,
            ),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _isSendingCode = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpPage(
                verificationId: verificationId,
                phoneNumber: _phoneNumber,
                resendToken: resendToken,
              ),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (mounted) {
          setState(() {
            _isSendingCode = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF9A46D7),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                const SizedBox(height: 60),
                
                // Header Text Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'جمالكِ يبدأ هنا! 🌸',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'سجّلي دخولك لحجز أرقى خدمات الجمال والموضة بسهولة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // White Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(26),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 55, 24, 24),
                            child: Column(
                              children: [
                                // Form Section
                                Column(
                                  children: [
                                    // Phone Input Section
                                    _buildPhoneInputSection(),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Login Button
                                    _buildPrimaryButton(),
                                  ],
                                ),
                                
                                const SizedBox(height: 60),
                                
                                // Social Login Section
                                _buildSocialLoginSection(),
                                
                                const SizedBox(height: 40),
                                
                                // Sign Up Button
                                _buildSignUpButton(),
                                
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'رقم الهاتف',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D2035),
            height: 1.39,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Phone Number Input
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '0570151550',
                    hintStyle: TextStyle(
                      color: Color(0xFFE7EBEF),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D2035),
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Format phone number in E.164 format (required by Firebase)
                      // E.164 format: +[country code][subscriber number]
                      // Remove leading zero if present (common in local formats)
                      final cleanedValue = value.startsWith('0') ? value.substring(1) : value;
                      _phoneNumber = '+${_selectedCountry.phoneCode}$cleanedValue';
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Country Picker Section
              GestureDetector(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    favorite: ['SA', 'EG', 'AE', 'KW', 'QA', 'BH', 'OM'],
                    countryListTheme: CountryListThemeData(
                      flagSize: 25,
                      backgroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16, color: Colors.black),
                      bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      inputDecoration: InputDecoration(
                        labelText: 'البحث عن دولة',
                        hintText: 'ابدأ الكتابة للبحث...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF9A46D7).withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF9A46D7)),
                        ),
                      ),
                    ),
                    onSelect: (Country country) {
                      setState(() {
                        _selectedCountry = country;
                      });
                    },
                  );
                },
                child: Row(
                  children: [
                    // Dropdown Icon
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF4A5E6D),
                      size: 16,
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Country Text
                    Text(
                      _getCountryName(_selectedCountry),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D2035),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Country Flag
                    Text(
                      _selectedCountry.flagEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getCountryName(Country country) {
    // Return Arabic names for common countries
    switch (country.countryCode) {
      case 'SA':
        return 'السعودية';
      case 'EG':
        return 'مصر';
      case 'AE':
        return 'الإمارات';
      case 'KW':
        return 'الكويت';
      case 'QA':
        return 'قطر';
      case 'BH':
        return 'البحرين';
      case 'OM':
        return 'عُمان';
      case 'JO':
        return 'الأردن';
      case 'LB':
        return 'لبنان';
      case 'SY':
        return 'سوريا';
      case 'IQ':
        return 'العراق';
      case 'MA':
        return 'المغرب';
      case 'DZ':
        return 'الجزائر';
      case 'TN':
        return 'تونس';
      case 'LY':
        return 'ليبيا';
      case 'SD':
        return 'السودان';
      case 'YE':
        return 'اليمن';
      case 'US':
        return 'أمريكا';
      case 'GB':
        return 'بريطانيا';
      case 'FR':
        return 'فرنسا';
      case 'DE':
        return 'ألمانيا';
      case 'TR':
        return 'تركيا';
      case 'IN':
        return 'الهند';
      case 'PK':
        return 'باكستان';
      case 'BD':
        return 'بنغلاديش';
      default:
        return country.name;
    }
  }

  Widget _buildPrimaryButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF9A46D7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: _phoneNumber.isNotEmpty && !_isSendingCode ? _sendOtp : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSendingCode
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.39,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        const Text(
          'او سجل دخولك باستخدام',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFAAB9C5),
            height: 1.5,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Google Button
        _buildSocialButton(
          'جوجل',
          _buildGoogleIcon(),
          _signInWithGoogle,
        ),
      ],
    );
  }

  Widget _buildSocialButton(String text, Widget icon, VoidCallback onPressed) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D2035),
                height: 1.39,
              ),
            ),
            const SizedBox(width: 12),
            icon,
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      child: Image.asset(
        'assets/images/google.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to a simple Google icon if image is not found
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Column(
      children: [
        // Merchant Login Button (Primary style)
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9A46D7), Color(0xFF7B2CBF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9A46D7).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/merchant-login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.login,
                color: Colors.white,
                size: 18,
              ),
            ),
            label: const Text(
              'دخول التاجر',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // Register as Merchant Button (Secondary style)
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF9A46D7).withOpacity(0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/merchant-registration-figma');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF9A46D7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.store_outlined,
                color: Color(0xFF9A46D7),
                size: 18,
              ),
            ),
            label: const Text(
              'تسجيل كتاجر',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A46D7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Google Sign-In method مع معالجة محسنة للأخطاء
  Future<void> _signInWithGoogle() async {
    bool dialogShown = false;
    
    // دالة مساعدة لإغلاق الـ dialog بأمان
    void _safeCloseDialog() {
      if (mounted && dialogShown) {
        try {
          Navigator.of(context).pop();
          dialogShown = false;
        } catch (e) {
          debugPrint('خطأ في إغلاق dialog: $e');
          // في حالة الفشل، نضبط المتغير على الأقل
          dialogShown = false;
        }
      }
    }
    
    // عرض مؤشر تحميل
    if (mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                ),
                const SizedBox(height: 16),
                Text(
                  'جارٍ تسجيل الدخول مع Google...',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      // آلية الحماية بـ timeout - إغلاق الـ dialog بعد 60 ثانية كحد أقصى
      Timer(const Duration(seconds: 60), () {
        _safeCloseDialog();
      });
    }

    try {
      final user = await AuthService().signInWithGoogle();
      
      // إخفاء مؤشر التحميل
      _safeCloseDialog();
      
      if (user != null && mounted) {
        // حفظ نوع المستخدم كمستخدم عادي
        await UserTypeService.saveUserType(
          UserTypeService.typeUser,
          userData: {
            'email': user.user?.email ?? '',
            'displayName': user.user?.displayName ?? '',
            'photoURL': user.user?.photoURL ?? '',
            'loginMethod': 'google',
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('تم تسجيل الدخول بنجاح باستخدام Google!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم إلغاء تسجيل الدخول'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      // إخفاء مؤشر التحميل في حالة الخطأ
      _safeCloseDialog();
      
      if (mounted) {
        
        // عرض رسالة خطأ مفصلة
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'خطأ في تسجيل الدخول',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tips_and_updates, 
                               color: Colors.blue.shade600, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'نصائح للحل:',
                            style: TextStyle(
                              fontFamily: 'Almarai',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• تأكد من اتصالك بالإنترنت\n'
                        '• أعد تشغيل التطبيق\n'
                        '• تحقق من تحديث Google Play Services\n'
                        '• جرب شبكة إنترنت أخرى',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 11,
                          height: 1.4,
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
                child: Text(
                  'إغلاق',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    color: Colors.grey[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _signInWithGoogle(); // إعادة المحاولة
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A46D7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}

