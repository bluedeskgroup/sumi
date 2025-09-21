import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/merchant_model.dart';
import '../../services/merchant_service.dart';
import '../../../../helpers/translation_helper.dart';
import '../../../../core/widgets/safe_network_image.dart';
import 'merchant_pending_approval_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class MerchantRegistrationFigmaPage extends StatefulWidget {
  const MerchantRegistrationFigmaPage({super.key});

  @override
  State<MerchantRegistrationFigmaPage> createState() => _MerchantRegistrationFigmaPageState();
}

class _MerchantRegistrationFigmaPageState extends State<MerchantRegistrationFigmaPage> 
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  
  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Controllers for form fields
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController = TextEditingController();

  final TextEditingController _bankAccountNameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  
  // Selected values
  String _selectedCountry = 'السعودية';
  String _selectedCity = 'الرياض';
  Map<String, dynamic> _selectedPhoneCountry = {
    'name': 'السعودية',
    'code': '+966',
    'flag': '🇸🇦',
  };
  String _selectedBusinessSpecialty = 'أدوات التجميل';
  String _selectedActivityType = 'محل تجاري';
  String _selectedStoreType = 'بيع منتجات';
  
  // Images
  File? _logoImage;
  File? _nationalIdImage;
  
  final ImagePicker _picker = ImagePicker();
  final MerchantService _merchantService = MerchantService.instance;

  // قائمة دول العالم مع أكوادها
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

  // تطابق ألوان الفيجما تماماً
  static const Color primaryPurple = Color(0xFF9A46D7);
  static const Color darkPurple = Color(0xFF8534BC);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color greenAccent = Color(0xFF1AB385);
  static const Color primaryText = Color(0xFF1D2035);
  static const Color secondaryText = Color(0xFF7991A4);
  static const Color placeholderText = Color(0xFFCED7DE);
  static const Color grayTextColor = Color(0xFF7991A4);
  static const Color lightGray = Color(0xFFF3F3F3);
  static const Color borderColor = Color(0xFFE7EBEF);
  static const Color inputText = Color(0xFF4A5E6D);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // لا نحتاج _checkExistingRequest هنا لأن StreamBuilder سيتولى الأمر
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();

    _bankAccountNameController.dispose();
    _bankNameController.dispose();
    _ibanController.dispose();
  }



    @override
  Widget build(BuildContext context) {
    // السماح لأي شخص بتسجيل حساب تاجر بدون تسجيل دخول مسبق
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryPurple,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildWhiteCard(),
                    ),
                  ],
                ),
              ),
              _buildHomeIndicator(),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 20), // مسافة محسنة من الأعلى
          // Navigation buttons
          Row(
            children: [
              // Back button (only show if not on first step)
              if (_currentStep > 0)
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: darkPurple,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: _goToPreviousStep,
                      child: Icon(
                        Icons.arrow_back,
                        color: whiteColor,
                        size: 24,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(width: 55), // Placeholder to maintain layout
              
              Spacer(),
              
              // Close button
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: darkPurple,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: whiteColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Title and subtitle
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  child: Text(
                    'أنشئ حساب متجرك الان!',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 1.6,
                      color: whiteColor,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  child: Text(
                    'ابدأ في عرض منتجاتك والوصول إلى المزيد من العملاء سهولة',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      height: 1.5,
                      color: whiteColor,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWhiteCard() {
    return Container(
      width: 430,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          children: [
            _buildProgressIndicator(),
            SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(), 
                  _buildStep3(),
                ],
              ),
            ),
            _buildCreateAccountButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Container(
          width: 382,
          height: 6,
          child: Row(
            children: [
              // Step 1
              Container(
                width: 124.38,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentStep >= 0 ? greenAccent : lightGray,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(width: 4.53),
              // Step 2
              Container(
                width: 124.17,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentStep >= 1 ? greenAccent : lightGray,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(width: 4.66),
              // Step 3
              Container(
                width: 124.17,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentStep >= 2 ? greenAccent : lightGray,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildDropdownField(
              label: 'الدولة',
              value: _selectedCountry,
              items: ['السعودية', 'الإمارات', 'الكويت', 'قطر', 'البحرين', 'عمان'],
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value!;
                });
              },
            ),
            SizedBox(height: 16),
            _buildDropdownField(
              label: 'المدينة',
              value: _selectedCity,
              items: MerchantModel.saudiCities,
              onChanged: (value) {
                setState(() {
                  _selectedCity = value!;
                });
              },
            ),
            SizedBox(height: 16),
            _buildPhoneField(),
            SizedBox(height: 16),
            
            // Email Field
            _buildTextField(
              label: 'ألايميل',
              controller: _emailController,
              placeholder: '*',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            
            // Password Field
            _buildPasswordField(
              label: 'أنشاء كلمة سر المتجر',
              controller: _passwordController,
              placeholder: 'ادخل كلمة السر',
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            SizedBox(height: 16),
            
            // Confirm Password Field
            _buildPasswordField(
              label: 'تاكيد كلمة السر',
              controller: _confirmPasswordController,
              placeholder: 'اعادة ادخل كلمة السر',
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            SizedBox(height: 20), // مسافة إضافية في النهاية
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Store Logo Section
          _buildLogoUploadSection(),
          SizedBox(height: 12),
          
          // Store Name
          _buildTextField(
            label: 'أسم المتجر',
            controller: _businessNameController,
            placeholder: '*متجر الفن والجمال',
          ),
          SizedBox(height: 10),
          
          // Store Specialty
          _buildDropdownField(
            label: 'تخصص المتجر',
            value: _selectedBusinessSpecialty,
            items: ['أدوات التجميل', 'ملابس', 'إلكترونيات', 'طعام ومشروبات', 'أخرى'],
            onChanged: (value) {
              setState(() {
                _selectedBusinessSpecialty = value!;
              });
            },
          ),
          SizedBox(height: 10),
          
          // Activity Type
          _buildDropdownField(
            label: 'نوع النشاط',
            value: _selectedActivityType,
            items: ['محل تجاري', 'مطعم', 'صالون', 'ورشة', 'مكتب', 'أخرى'],
            onChanged: (value) {
              setState(() {
                _selectedActivityType = value!;
              });
            },
          ),
          SizedBox(height: 10),
          
          // Store Type
          _buildDropdownField(
            label: 'نوع المتجر',
            value: _selectedStoreType,
            items: ['بيع منتجات', 'تقديم خدمات', 'كلاهما'],
            onChanged: (value) {
              setState(() {
                _selectedStoreType = value!;
              });
            },
          ),
          SizedBox(height: 10),
          
          // Store Description
          _buildTextField(
            label: 'وصف المتجر',
            controller: _businessDescriptionController,
            placeholder: 'اكتب وصف مختصر للمتجر...',
            maxLines: 3,
          ),
          SizedBox(height: 20), // مسافة إضافية في النهاية للـ scroll
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Bank Account Name
          _buildTextField(
            label: 'اسم الحساب البنك',
            controller: _bankAccountNameController,
            placeholder: 'الزامي',
          ),
          SizedBox(height: 10),
          
          // Bank Name
          _buildTextField(
            label: 'اسم البنك',
            controller: _bankNameController,
            placeholder: 'الزامي',
          ),
          SizedBox(height: 10),
          
          // IBAN
          _buildTextField(
            label: 'رقم الآيبان',
            controller: _ibanController,
            placeholder: 'الزامي',
          ),
          SizedBox(height: 12),
          
          // National ID Image
          _buildImageUploadCard(
            title: 'صورة الهوية الوطنية لمالك النشاط',
            subtitle: 'تحميل صورة الهوية الوطنية',
            image: _nationalIdImage,
            onTap: () => _pickImage(ImageType.nationalId),
          ),
          SizedBox(height: 12),
          
          // Security Notice
          Container(
            width: double.infinity,
            child: Text(
              'نحن نلتزم بأعلى معايير الأمان والسرية لحماية معلوماتك، مع ضمان تقديم تجربة خدمة متميزة تلبي احتياجات مزود الخدمة والمستخدم على حد سواء',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.39,
                color: grayTextColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(height: 20), // مسافة إضافية في النهاية للـ scroll
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.39,
            color: primaryText,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: whiteColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1.5,
              color: primaryText,
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    color: primaryText,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: Icon(Icons.keyboard_arrow_down, color: inputText),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'رقم الهاتف',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.39,
            color: primaryText,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: whiteColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Country flag and code - clickable
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPhoneCountry['flag'],
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(width: 6),
                      Text(
                        _selectedPhoneCountry['code'],
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: primaryText,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, color: inputText, size: 16),
                    ],
                  ),
                ),
              ),
              // Vertical divider
              Container(
                width: 1,
                height: 25,
                color: borderColor,
              ),
              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: primaryText, // لون أكثر وضوحاً
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '501234567',
                    hintStyle: TextStyle(
                      color: secondaryText, // لون أفضل للنص المساعد
                      fontWeight: FontWeight.w400,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          'مالك المتجر ولن يظهر للعملاء',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.39,
            color: secondaryText,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 1.39,
            color: primaryText,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: whiteColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textDirection: keyboardType == TextInputType.emailAddress ? TextDirection.ltr : TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1.5,
              color: primaryText,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: placeholder,
              hintStyle: TextStyle(
                color: placeholderText,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            textAlign: keyboardType == TextInputType.emailAddress ? TextAlign.left : TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 1.39,
            color: primaryText,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: whiteColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: primaryText,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: placeholderText,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              prefixIcon: Icon(Icons.lock_outline, color: inputText, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: inputText,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton(
        onPressed: _isLoading ? null : _handleNextStep,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: whiteColor,
                  ),
                )
              : Text(
                  _currentStep == _totalSteps - 1 ? 'أنشاء الحساب' : 'التالي',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.39,
                    color: whiteColor,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHomeIndicator() {
    return Container(
      height: 34,
      width: 430,
      child: Center(
        child: Container(
          width: 148,
          height: 5,
          decoration: BoxDecoration(
            color: Color(0xFFAAB9C5),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }

  void _handleNextStep() {
    if (_currentStep < _totalSteps - 1) {
      // تحقق من الخطوة الحالية قبل الانتقال
      if (!_validateCurrentStep()) {
        return;
      }
      
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // الخطوة الأولى
        if (_phoneController.text.trim().isEmpty ||
            _emailController.text.trim().isEmpty ||
            _passwordController.text.trim().isEmpty ||
            _confirmPasswordController.text.trim().isEmpty) {
          _showErrorSnackBar('يرجى ملء جميع البيانات المطلوبة');
          return false;
        }
        
        if (_passwordController.text != _confirmPasswordController.text) {
          _showErrorSnackBar('كلمتا السر غير متطابقتان');
          return false;
        }
        
        if (_passwordController.text.length < 6) {
          _showErrorSnackBar('كلمة السر يجب أن تكون 6 أحرف على الأقل');
          return false;
        }
        
        // تحقق من صحة الإيميل
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
          _showErrorSnackBar('يرجى إدخال بريد إلكتروني صحيح');
          return false;
        }
        break;
        
      case 1: // الخطوة الثانية
        if (_businessNameController.text.trim().isEmpty) {
          _showErrorSnackBar('يرجى إدخال اسم المتجر');
          return false;
        }
        break;
        
      case 2: // الخطوة الثالثة
        if (_bankAccountNameController.text.trim().isEmpty ||
            _bankNameController.text.trim().isEmpty ||
            _ibanController.text.trim().isEmpty) {
          _showErrorSnackBar('يرجى ملء جميع البيانات المطلوبة');
          return false;
        }
        break;
    }
    return true;
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    // Validate the final step before submitting
    if (!_validateCurrentStep()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      // إذا لم يكن هناك مستخدم مسجل، أنشئ حساب جديد
      if (user == null) {
        try {
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          user = credential.user;
          
          if (user == null) {
            throw Exception('فشل في إنشاء الحساب');
          }
        } catch (e) {
          if (e.toString().contains('email-already-in-use')) {
            // إذا كان الإيميل مستخدم، جرب تسجيل الدخول
            try {
              final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );
              user = credential.user;
            } catch (loginError) {
              throw Exception('البريد الإلكتروني مستخدم مسبقاً مع كلمة سر مختلفة');
            }
          } else if (e.toString().contains('weak-password')) {
            throw Exception('كلمة السر ضعيفة، يجب أن تكون 6 أحرف على الأقل');
          } else if (e.toString().contains('invalid-email')) {
            throw Exception('البريد الإلكتروني غير صحيح');
          } else {
            throw Exception('حدث خطأ في إنشاء الحساب: ${e.toString()}');
          }
        }
      }

      // Upload images first
      String profileImageUrl = '';
      String nationalIdUrl = '';

      if (_logoImage != null) {
        profileImageUrl = await _uploadImage(_logoImage!, 'merchant_logos/${user!.uid}_logo');
      }
      
      if (_nationalIdImage != null) {
        nationalIdUrl = await _uploadImage(_nationalIdImage!, 'national_ids/${user!.uid}_national_id');
      }

      // Create merchant model
      final merchant = MerchantModel(
        id: '',
        userId: user!.uid,
        fullName: _businessNameController.text.trim(), // Use business name as full name
        email: _emailController.text.trim(),
        phoneNumber: '${_selectedPhoneCountry['code']}${_phoneController.text.trim()}',
        nationalId: '', // Will be filled later by admin or in future updates
        businessName: _businessNameController.text.trim(),
        businessDescription: 'تخصص: $_selectedBusinessSpecialty, نوع النشاط: $_selectedActivityType, نوع المتجر: $_selectedStoreType',
        businessType: BusinessType.retail,
        businessAddress: '$_selectedCity, $_selectedCountry',
        city: _selectedCity,
        commercialRegistration: '',
        taxNumber: '',
        bankName: _bankNameController.text.trim(),
        accountNumber: '',
        iban: _ibanController.text.trim(),
        accountHolderName: _bankAccountNameController.text.trim(),
        productCategories: [_selectedBusinessSpecialty],
        serviceTypes: [_selectedActivityType],
        estimatedMonthlyRevenue: '',
        profileImageUrl: profileImageUrl,
        businessLicenseUrl: '',
        nationalIdImageUrl: nationalIdUrl,
        bankStatementUrl: '',
        productImagesUrls: [],
        status: MerchantStatus.pending,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // Submit merchant request
      final requestId = await _merchantService.submitMerchantRequest(merchant);

      // Navigate to pending approval page instead of showing dialog
      _navigateToPendingApproval(requestId);
      
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء إرسال الطلب: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }



  Future<String> _uploadImage(File imageFile, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref.putFile(imageFile);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  void _navigateToPendingApproval(String requestId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تم إرسال الطلب بنجاح!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'رقم الطلب: ${requestId.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MerchantPendingApprovalPage(
              merchantId: requestId,
              showBackButton: false,
            ),
          ),
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Almarai', color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }





  // Logo Upload Section for Step 2
  Widget _buildLogoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Title and subtitle
        Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: double.infinity,
                child: Text(
                  'شعار المتجر',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.6,
                    color: primaryText,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ),
              SizedBox(height: 6),
              Container(
                width: double.infinity,
                child: Text(
                  'يرجى اضافة شعار المتجر بجودة عالية',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w400,
                    fontSize: 8,
                    height: 1.6,
                    color: primaryPurple,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        // Logo upload circle
        Container(
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _pickImage(ImageType.logo),
              child: Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: Color(0xFFFAF6FE),
                  border: Border.all(color: primaryPurple, width: 1),
                  borderRadius: BorderRadius.circular(253),
                ),
                child: _logoImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(253),
                        child: Image.file(
                          _logoImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          child: Icon(
                            Icons.add,
                            color: primaryPurple,
                            size: 20,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Image Upload Card for Step 3
  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.39,
              color: primaryText,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 382,
            height: 100,
            decoration: BoxDecoration(
              color: whiteColor,
              border: Border.all(
                color: Color(0xFFB6B4BA),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 27,
                        height: 27,
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          color: primaryPurple,
                          size: 20,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            height: 1.5,
                            color: primaryPurple,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // Pick Image method
  Future<void> _pickImage(ImageType type) async {
    try {
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          switch (type) {
            case ImageType.logo:
              _logoImage = File(pickedFile.path);
              break;

            case ImageType.nationalId:
              _nationalIdImage = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      _showErrorDialog('خطأ في تحميل الصورة: $e');
    }
  }

  // Image Source Dialog
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اختر مصدر الصورة'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Text('الكاميرا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Text('المعرض'),
          ),
        ],
      ),
    );
  }

  // Error Dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  // Country Picker Dialog with Search
  void _showCountryPicker() {
    String searchQuery = '';
    List<Map<String, dynamic>> filteredCountries = List.from(_worldCountries);

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              'اختر الدولة',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
            content: Container(
              width: double.maxFinite,
              height: 450,
              child: Column(
                children: [
                  // Search field
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        color: primaryText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن الدولة...',
                        hintStyle: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          color: secondaryText,
                        ),
                        prefixIcon: Icon(Icons.search, color: secondaryText),
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
                            style: TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            country['name'],
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w500,
                              color: primaryText,
                            ),
                          ),
                          subtitle: Text(
                            country['code'],
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                              color: secondaryText,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedPhoneCountry = country;
                            });
                            Navigator.pop(context);
                          },
                          selected: _selectedPhoneCountry['code'] == country['code'],
                          selectedTileColor: primaryPurple.withOpacity(0.1),
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
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    color: primaryPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ImageType {
  logo,
  nationalId,
}
