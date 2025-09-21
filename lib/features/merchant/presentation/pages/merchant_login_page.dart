import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/merchant_auth_service.dart';
import '../../services/merchant_login_service.dart';
import '../../widgets/merchant_auth_wrapper.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../core/services/user_type_service.dart';

/// صفحة تسجيل دخول التاجر
class MerchantLoginPage extends StatefulWidget {
  const MerchantLoginPage({super.key});

  @override
  State<MerchantLoginPage> createState() => _MerchantLoginPageState();
}

class _MerchantLoginPageState extends State<MerchantLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final MerchantLoginService _merchantLoginService = MerchantLoginService.instance;

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isEmailMode = true; // true للبريد الإلكتروني، false لرقم الهاتف
  
  // نفس قائمة الدول من صفحة التسجيل
  Map<String, dynamic> _selectedPhoneCountry = {
    'name': 'السعودية',
    'code': '+966',
    'flag': '🇸🇦',
  };

  static final List<Map<String, dynamic>> _worldCountries = [
    {'name': 'السعودية', 'code': '+966', 'flag': '🇸🇦'},
    {'name': 'الإمارات', 'code': '+971', 'flag': '🇦🇪'},
    {'name': 'الكويت', 'code': '+965', 'flag': '🇰🇼'},
    {'name': 'قطر', 'code': '+974', 'flag': '🇶🇦'},
    {'name': 'البحرين', 'code': '+973', 'flag': '🇧🇭'},
    {'name': 'عمان', 'code': '+968', 'flag': '🇴🇲'},
    {'name': 'الأردن', 'code': '+962', 'flag': '🇯🇴'},
    {'name': 'لبنان', 'code': '+961', 'flag': '🇱🇧'},
    {'name': 'سوريا', 'code': '+963', 'flag': '🇸🇾'},
    {'name': 'العراق', 'code': '+964', 'flag': '🇮🇶'},
    {'name': 'مصر', 'code': '+20', 'flag': '🇪🇬'},
    {'name': 'المغرب', 'code': '+212', 'flag': '🇲🇦'},
    {'name': 'الجزائر', 'code': '+213', 'flag': '🇩🇿'},
    {'name': 'تونس', 'code': '+216', 'flag': '🇹🇳'},
    {'name': 'ليبيا', 'code': '+218', 'flag': '🇱🇾'},
    {'name': 'السودان', 'code': '+249', 'flag': '🇸🇩'},
    {'name': 'فلسطين', 'code': '+970', 'flag': '🇵🇸'},
    {'name': 'اليمن', 'code': '+967', 'flag': '🇾🇪'},
    {'name': 'تركيا', 'code': '+90', 'flag': '🇹🇷'},
    {'name': 'إيران', 'code': '+98', 'flag': '🇮🇷'},
    {'name': 'الولايات المتحدة', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'كندا', 'code': '+1', 'flag': '🇨🇦'},
    {'name': 'المملكة المتحدة', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'ألمانيا', 'code': '+49', 'flag': '🇩🇪'},
    {'name': 'فرنسا', 'code': '+33', 'flag': '🇫🇷'},
    {'name': 'إيطاليا', 'code': '+39', 'flag': '🇮🇹'},
    {'name': 'إسبانيا', 'code': '+34', 'flag': '🇪🇸'},
    {'name': 'روسيا', 'code': '+7', 'flag': '🇷🇺'},
    {'name': 'الصين', 'code': '+86', 'flag': '🇨🇳'},
    {'name': 'اليابان', 'code': '+81', 'flag': '🇯🇵'},
    {'name': 'كوريا الجنوبية', 'code': '+82', 'flag': '🇰🇷'},
    {'name': 'الهند', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'باكستان', 'code': '+92', 'flag': '🇵🇰'},
    {'name': 'بنغلاديش', 'code': '+880', 'flag': '🇧🇩'},
    {'name': 'إندونيسيا', 'code': '+62', 'flag': '🇮🇩'},
    {'name': 'ماليزيا', 'code': '+60', 'flag': '🇲🇾'},
    {'name': 'تايلاند', 'code': '+66', 'flag': '🇹🇭'},
    {'name': 'سنغافورة', 'code': '+65', 'flag': '🇸🇬'},
    {'name': 'الفلبين', 'code': '+63', 'flag': '🇵🇭'},
    {'name': 'أستراليا', 'code': '+61', 'flag': '🇦🇺'},
    {'name': 'نيوزيلندا', 'code': '+64', 'flag': '🇳🇿'},
    {'name': 'البرازيل', 'code': '+55', 'flag': '🇧🇷'},
    {'name': 'الأرجنتين', 'code': '+54', 'flag': '🇦🇷'},
    {'name': 'المكسيك', 'code': '+52', 'flag': '🇲🇽'},
    {'name': 'جنوب أفريقيا', 'code': '+27', 'flag': '🇿🇦'},
    {'name': 'نيجيريا', 'code': '+234', 'flag': '🇳🇬'},
    {'name': 'كينيا', 'code': '+254', 'flag': '🇰🇪'},
    {'name': 'إثيوبيا', 'code': '+251', 'flag': '🇪🇹'},
  ];

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تسجيل دخول التاجر',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF9A46D7),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // أيقونة وترحيب
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9A46D7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 40,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'مرحباً بك',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'سجل دخولك لإدارة متجرك',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // نموذج تسجيل الدخول
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اختيار طريقة تسجيل الدخول
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isEmailMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isEmailMode ? const Color(0xFF9A46D7) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'البريد الإلكتروني',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isEmailMode ? Colors.white : Colors.grey[600],
                                    fontWeight: _isEmailMode ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isEmailMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isEmailMode ? const Color(0xFF9A46D7) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'رقم الهاتف',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !_isEmailMode ? Colors.white : Colors.grey[600],
                                    fontWeight: !_isEmailMode ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // حقل البريد الإلكتروني أو رقم الهاتف
                    Text(
                      _isEmailMode ? 'البريد الإلكتروني' : 'رقم الهاتف',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isEmailMode ? _buildEmailField() : _buildPhoneField(),
                    
                    const SizedBox(height: 20),
                    
                    // حقل كلمة السر
                    const Text(
                      'كلمة السر',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'ادخل كلمة السر',
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: Color(0xFF9CA3AF),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF9CA3AF),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF9A46D7)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال كلمة السر';
                        }
                        if (value.length < 6) {
                          return 'كلمة السر يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9A46D7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // روابط إضافية
                    Center(
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              // إعادة توجيه للتسجيل كتاجر
                              Navigator.pushNamed(context, '/merchant-registration');
                            },
                            child: const Text(
                              'ليس لديك حساب؟ سجل كتاجر',
                              style: TextStyle(
                                color: Color(0xFF9A46D7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          
                          TextButton(
                            onPressed: () {
                              // إعادة توجيه لتسجيل دخول المستخدم العادي
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'تسجيل دخول كمستخدم عادي',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                decoration: TextDecoration.underline,
                              ),
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
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final input = _emailPhoneController.text.trim();
      final password = _passwordController.text.trim();
      
      // تسجيل الدخول باستخدام الخدمة الجديدة
      final result = _isEmailMode
          ? await _merchantLoginService.signInWithEmail(
              email: input,
              password: password,
            )
          : await _merchantLoginService.signInWithPhone(
              phoneNumber: '${_selectedPhoneCountry['code']}$input',
              password: password,
            );

      if (!result.success) {
        _showErrorDialog('خطأ في تسجيل الدخول', result.errorMessage ?? 'حدث خطأ غير متوقع');
        return;
      }

      // حفظ نوع المستخدم كتاجر
      await UserTypeService.saveUserType(
        UserTypeService.typeMerchant,
        userData: {
          'phoneNumber': _isEmailMode ? input : '${_selectedPhoneCountry['code']}$input',
          'email': _isEmailMode ? input : '',
          'loginMethod': _isEmailMode ? 'email' : 'phone',
        },
      );

      // إذا نجح تسجيل الدخول، انتقل لصفحة التاجر
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantAuthWrapper(
              homeWidget: Container(), // لن يستخدم لأنه سيتم توجيهه لصفحة التاجر
            ),
          ),
        );
      }
      
    } catch (e) {
      _showErrorDialog('خطأ', 'حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailPhoneController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'ادخل بريدك الإلكتروني',
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Color(0xFF9CA3AF),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9A46D7)),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال البريد الإلكتروني';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'البريد الإلكتروني غير صحيح';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Country flag and code - clickable
          GestureDetector(
            onTap: _showCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPhoneCountry['flag'],
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedPhoneCountry['code'],
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 16),
                ],
              ),
            ),
          ),
          // Vertical divider
          Container(
            width: 1,
            height: 25,
            color: Colors.grey[300],
          ),
          // Phone number input
          Expanded(
            child: TextFormField(
              controller: _emailPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF374151),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '501234567',
                hintStyle: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              ),
              textAlign: TextAlign.left,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال رقم الهاتف';
                }
                if (!RegExp(r'^[0-9]{8,10}$').hasMatch(value.replaceAll(' ', ''))) {
                  return 'رقم الهاتف غير صحيح';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    String searchQuery = '';
    List<Map<String, dynamic>> filteredCountries = List.from(_worldCountries);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text(
              'اختر الدولة',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            content: Container(
              width: double.maxFinite,
              height: 450,
              child: Column(
                children: [
                  // Search field
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        color: Color(0xFF374151),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن الدولة...',
                        hintStyle: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          color: Color(0xFF9CA3AF),
                        ),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                          filteredCountries = _worldCountries.where((country) {
                            return country['name'].toLowerCase().contains(value.toLowerCase()) ||
                                   country['code'].contains(value);
                          }).toList();
                        });
                      },
                    ),
                  ),
                  // Countries list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = filteredCountries[index];
                        return ListTile(
                          leading: Text(
                            country['flag'],
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            country['name'],
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                          subtitle: Text(
                            country['code'],
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedPhoneCountry = country;
                            });
                            Navigator.pop(context);
                          },
                          selected: _selectedPhoneCountry['code'] == country['code'],
                          selectedTileColor: const Color(0xFF9A46D7).withOpacity(0.1),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    color: Color(0xFF9A46D7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
