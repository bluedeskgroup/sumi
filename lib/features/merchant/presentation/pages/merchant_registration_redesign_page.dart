import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/merchant_model.dart';
import '../../services/merchant_service.dart';
import '../../../../helpers/translation_helper.dart';
import '../../../../core/widgets/safe_network_image.dart';

class MerchantRegistrationRedesignPage extends StatefulWidget {
  const MerchantRegistrationRedesignPage({super.key});

  @override
  State<MerchantRegistrationRedesignPage> createState() => _MerchantRegistrationRedesignPageState();
}

class _MerchantRegistrationRedesignPageState extends State<MerchantRegistrationRedesignPage> 
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentStep = 0;
  final int _totalSteps = 4; // تقليل عدد الخطوات لتحسين التجربة
  bool _isLoading = false;
  
  // Controllers for form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _commercialRegistrationController = TextEditingController();
  
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _accountHolderNameController = TextEditingController();
  
  // Selected values
  BusinessType _selectedBusinessType = BusinessType.retail;
  String _selectedCity = 'الرياض';
  List<String> _selectedProductCategories = [];
  String _selectedRevenue = 'أقل من 10,000 ريال';
  
  // Images
  File? _profileImage;
  File? _businessLicenseImage;
  File? _nationalIdImage;
  File? _bankStatementImage;
  List<File> _productImages = [];
  
  final ImagePicker _picker = ImagePicker();
  final MerchantService _merchantService = MerchantService.instance;

  // Colors from Figma design
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color secondaryColor = Color(0xFF8B5CF6); // Purple
  static const Color accentColor = Color(0xFF06B6D4); // Cyan
  static const Color backgroundColor = Color(0xFFF8FAFC); // Light gray
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textPrimaryColor = Color(0xFF1E293B); // Dark slate
  static const Color textSecondaryColor = Color(0xFF64748B); // Slate
  static const Color successColor = Color(0xFF10B981); // Emerald
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _checkExistingRequest();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _commercialRegistrationController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    _accountHolderNameController.dispose();
  }

  Future<void> _checkExistingRequest() async {
    final existingRequest = await _merchantService.getCurrentUserMerchantRequest();
    if (existingRequest != null && mounted) {
      _showExistingRequestDialog(existingRequest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildModernHeader(),
                _buildStylishProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPersonalInfoStep(),
                      _buildBusinessInfoStep(),
                      _buildFinancialInfoStep(),
                      _buildDocumentsStep(),
                    ],
                  ),
                ),
                _buildModernNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Bar Space
          Container(height: 15),
          
          // Header Content
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'انضم كتاجر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStepLabel(_currentStep),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Logo or Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStylishProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress Steps
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              final isNext = index > _currentStep;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: index < _totalSteps - 1 ? 8 : 0),
                  child: Column(
                    children: [
                      // Step Circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          gradient: isCompleted
                              ? const LinearGradient(colors: [successColor, Color(0xFF059669)])
                              : isCurrent
                                  ? LinearGradient(colors: [primaryColor, secondaryColor])
                                  : null,
                          color: isNext ? Colors.grey[200] : null,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isCurrent ? primaryColor : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isCompleted || isCurrent
                              ? [
                                  BoxShadow(
                                    color: (isCompleted ? successColor : primaryColor).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : _getStepIcon(index),
                          color: isNext ? Colors.grey[400] : Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Step Label
                      Text(
                        _getShortStepTitle(index),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent ? primaryColor : textSecondaryColor,
                          fontFamily: 'Almarai',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          // Animated Progress Bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentStep + 1) / _totalSteps,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepCard(
              title: 'البيانات الشخصية',
              subtitle: 'المعلومات الأساسية عنك',
              icon: Icons.person_outline_rounded,
              children: [
                _buildModernTextField(
                  controller: _fullNameController,
                  label: 'الاسم الكامل',
                  hint: 'أدخل اسمك كما هو في الهوية',
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  hint: '05xxxxxxxx',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.length < 10) {
                      return 'رقم الهاتف غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  controller: _nationalIdController,
                  label: 'رقم الهوية الوطنية',
                  hint: '1234567890',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.length != 10) {
                      return 'رقم الهوية يجب أن يكون 10 أرقام';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          _buildStepCard(
            title: 'معلومات النشاط التجاري',
            subtitle: 'تفاصيل عملك ونشاطك',
            icon: Icons.business_outlined,
            children: [
              _buildModernTextField(
                controller: _businessNameController,
                label: 'اسم النشاط التجاري',
                hint: 'أدخل اسم متجرك أو شركتك',
                icon: Icons.storefront_outlined,
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'اسم النشاط يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildModernDropdown<BusinessType>(
                value: _selectedBusinessType,
                label: 'نوع النشاط التجاري',
                icon: Icons.category_outlined,
                items: BusinessType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      MerchantModel.getBusinessTypeName(type, true),
                      style: const TextStyle(fontFamily: 'Almarai'),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBusinessType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _businessDescriptionController,
                label: 'وصف النشاط',
                hint: 'اشرح نوع المنتجات أو الخدمات التي تقدمها',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'الوصف يجب أن يكون 10 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _businessAddressController,
                label: 'عنوان النشاط',
                hint: 'العنوان التفصيلي لمكان العمل',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'العنوان يجب أن يكون واضح ومفصل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildModernDropdown<String>(
                value: _selectedCity,
                label: 'المدينة',
                icon: Icons.location_city_outlined,
                items: MerchantModel.saudiCities.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city, style: const TextStyle(fontFamily: 'Almarai')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value!;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          _buildStepCard(
            title: 'المعلومات المالية',
            subtitle: 'بيانات حسابك البنكي',
            icon: Icons.account_balance_outlined,
            children: [
              _buildModernTextField(
                controller: _bankNameController,
                label: 'اسم البنك',
                hint: 'مثل: البنك الأهلي السعودي',
                icon: Icons.account_balance,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اسم البنك مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _accountNumberController,
                label: 'رقم الحساب',
                hint: 'رقم حسابك البنكي',
                icon: Icons.credit_card_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'رقم الحساب غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _ibanController,
                label: 'رقم الآيبان (IBAN)',
                hint: 'SA01XXXXXXXXXXXXXXXX',
                icon: Icons.account_balance_wallet_outlined,
                validator: (value) {
                  if (value == null || value.length < 15) {
                    return 'رقم الآيبان غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _accountHolderNameController,
                label: 'اسم صاحب الحساب',
                hint: 'كما هو مسجل في البنك',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اسم صاحب الحساب مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildModernDropdown<String>(
                value: _selectedRevenue,
                label: 'الإيرادات الشهرية المتوقعة',
                icon: Icons.monetization_on_outlined,
                items: [
                  'أقل من 10,000 ريال',
                  '10,000 - 25,000 ريال',
                  '25,000 - 50,000 ريال',
                  '50,000 - 100,000 ريال',
                  'أكثر من 100,000 ريال',
                ].map((revenue) {
                  return DropdownMenuItem(
                    value: revenue,
                    child: Text(revenue, style: const TextStyle(fontFamily: 'Almarai')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRevenue = value!;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          _buildStepCard(
            title: 'المستندات المطلوبة',
            subtitle: 'قم برفع الصور والمستندات',
            icon: Icons.upload_file_outlined,
            children: [
              _buildModernImageUploadCard(
                title: 'الصورة الشخصية',
                subtitle: 'صورة واضحة وحديثة',
                icon: Icons.person_outline_rounded,
                image: _profileImage,
                onTap: () => _pickImage('profile'),
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildModernImageUploadCard(
                title: 'صورة الهوية الوطنية',
                subtitle: 'صورة واضحة للوجهين',
                icon: Icons.credit_card_outlined,
                image: _nationalIdImage,
                onTap: () => _pickImage('nationalId'),
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildModernImageUploadCard(
                title: 'الترخيص التجاري',
                subtitle: 'إن وجد (اختياري)',
                icon: Icons.receipt_long_outlined,
                image: _businessLicenseImage,
                onTap: () => _pickImage('businessLicense'),
                isRequired: false,
              ),
              const SizedBox(height: 16),
              _buildModernImageUploadCard(
                title: 'كشف حساب بنكي',
                subtitle: 'صورة حديثة من البنك',
                icon: Icons.account_balance_outlined,
                image: _bankStatementImage,
                onTap: () => _pickImage('bankStatement'),
                isRequired: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                          fontFamily: 'Almarai',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondaryColor,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        color: Colors.grey[50],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: 'Almarai',
          fontSize: 16,
          color: textPrimaryColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          labelStyle: TextStyle(
            fontFamily: 'Almarai',
            color: textSecondaryColor,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Almarai',
            color: textSecondaryColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        color: Colors.grey[50],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          labelStyle: TextStyle(
            fontFamily: 'Almarai',
            color: textSecondaryColor,
            fontSize: 14,
          ),
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: cardColor,
        style: const TextStyle(
          fontFamily: 'Almarai',
          fontSize: 16,
          color: textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildModernImageUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    final bool hasImage = image != null;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? successColor
                : isRequired
                    ? errorColor.withOpacity(0.3)
                    : Colors.grey[300]!,
            width: 2,
          ),
          color: hasImage
              ? successColor.withOpacity(0.05)
              : isRequired
                  ? errorColor.withOpacity(0.02)
                  : Colors.grey[50],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: hasImage
                    ? const LinearGradient(colors: [successColor, Color(0xFF059669)])
                    : LinearGradient(colors: [primaryColor, secondaryColor]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                hasImage ? Icons.check_circle_outline : icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                          fontFamily: 'Almarai',
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(color: errorColor, fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                      fontFamily: 'Almarai',
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(height: 4),
                    Text(
                      'تم الرفع بنجاح ✓',
                      style: TextStyle(
                        fontSize: 12,
                        color: successColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              hasImage ? Icons.edit_outlined : Icons.upload_outlined,
              color: hasImage ? successColor : primaryColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _previousStep,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    label: const Text(
                      'السابق',
                      style: TextStyle(
                        fontFamily: 'Almarai',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: textSecondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : (_currentStep == _totalSteps - 1 ? _submitForm : _nextStep),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _currentStep == _totalSteps - 1
                              ? Icons.send_rounded
                              : Icons.arrow_forward_ios_rounded,
                          size: 18,
                        ),
                  label: Text(
                    _currentStep == _totalSteps - 1 ? 'إرسال الطلب' : 'التالي',
                    style: const TextStyle(
                      fontFamily: 'Almarai',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  String _getStepLabel(int step) {
    switch (step) {
      case 0:
        return 'الخطوة 1 من 4 - البيانات الشخصية';
      case 1:
        return 'الخطوة 2 من 4 - معلومات النشاط';
      case 2:
        return 'الخطوة 3 من 4 - المعلومات المالية';
      case 3:
        return 'الخطوة 4 من 4 - المستندات';
      default:
        return '';
    }
  }

  String _getShortStepTitle(int step) {
    switch (step) {
      case 0:
        return 'البيانات\nالشخصية';
      case 1:
        return 'معلومات\nالنشاط';
      case 2:
        return 'المعلومات\nالمالية';
      case 3:
        return 'المستندات';
      default:
        return '';
    }
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.person_outline_rounded;
      case 1:
        return Icons.business_outlined;
      case 2:
        return Icons.account_balance_outlined;
      case 3:
        return Icons.upload_file_outlined;
      default:
        return Icons.circle;
    }
  }

  // Navigation Methods
  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        if (_businessNameController.text.trim().length < 3) {
          _showErrorSnackBar('اسم النشاط يجب أن يكون 3 أحرف على الأقل');
          return false;
        }
        if (_businessDescriptionController.text.trim().length < 10) {
          _showErrorSnackBar('وصف النشاط يجب أن يكون 10 أحرف على الأقل');
          return false;
        }
        if (_businessAddressController.text.trim().length < 10) {
          _showErrorSnackBar('عنوان النشاط يجب أن يكون واضح ومفصل');
          return false;
        }
        return true;
      case 2:
        if (_bankNameController.text.trim().isEmpty) {
          _showErrorSnackBar('اسم البنك مطلوب');
          return false;
        }
        if (_accountNumberController.text.length < 8) {
          _showErrorSnackBar('رقم الحساب غير صحيح');
          return false;
        }
        if (_ibanController.text.length < 15) {
          _showErrorSnackBar('رقم الآيبان غير صحيح');
          return false;
        }
        if (_accountHolderNameController.text.trim().isEmpty) {
          _showErrorSnackBar('اسم صاحب الحساب مطلوب');
          return false;
        }
        return true;
      case 3:
        if (_profileImage == null) {
          _showErrorSnackBar('الصورة الشخصية مطلوبة');
          return false;
        }
        if (_nationalIdImage == null) {
          _showErrorSnackBar('صورة الهوية مطلوبة');
          return false;
        }
        if (_bankStatementImage == null) {
          _showErrorSnackBar('كشف الحساب البنكي مطلوب');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (type) {
            case 'profile':
              _profileImage = File(image.path);
              break;
            case 'nationalId':
              _nationalIdImage = File(image.path);
              break;
            case 'businessLicense':
              _businessLicenseImage = File(image.path);
              break;
            case 'bankStatement':
              _bankStatementImage = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // التحقق من وجود تاجر بنفس البيانات
      final isDuplicate = await _merchantService.checkDuplicateMerchant(
        _nationalIdController.text,
        _emailController.text,
      );

      if (isDuplicate) {
        _showErrorSnackBar('يوجد تاجر مسجل بنفس رقم الهوية أو البريد الإلكتروني');
        return;
      }

      // رفع الصور
      String profileImageUrl = '';
      String nationalIdImageUrl = '';
      String businessLicenseUrl = '';
      String bankStatementUrl = '';

      if (_profileImage != null) {
        profileImageUrl = await _merchantService.uploadMerchantImage(
          _profileImage!,
          user.uid,
          'profile',
        );
      }

      if (_nationalIdImage != null) {
        nationalIdImageUrl = await _merchantService.uploadMerchantImage(
          _nationalIdImage!,
          user.uid,
          'national_id',
        );
      }

      if (_businessLicenseImage != null) {
        businessLicenseUrl = await _merchantService.uploadMerchantImage(
          _businessLicenseImage!,
          user.uid,
          'business_license',
        );
      }

      if (_bankStatementImage != null) {
        bankStatementUrl = await _merchantService.uploadMerchantImage(
          _bankStatementImage!,
          user.uid,
          'bank_statement',
        );
      }

      // إنشاء نموذج التاجر
      final merchant = MerchantModel(
        id: '',
        userId: user.uid,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        businessName: _businessNameController.text.trim(),
        businessDescription: _businessDescriptionController.text.trim(),
        businessType: _selectedBusinessType,
        businessAddress: _businessAddressController.text.trim(),
        city: _selectedCity,
        commercialRegistration: _commercialRegistrationController.text.trim(),
        taxNumber: '',
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        iban: _ibanController.text.trim(),
        accountHolderName: _accountHolderNameController.text.trim(),
        productCategories: _selectedProductCategories,
        serviceTypes: [],
        estimatedMonthlyRevenue: _selectedRevenue,
        profileImageUrl: profileImageUrl,
        businessLicenseUrl: businessLicenseUrl,
        nationalIdImageUrl: nationalIdImageUrl,
        bankStatementUrl: bankStatementUrl,
        productImagesUrls: [],
        status: MerchantStatus.pending,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // إرسال الطلب
      final requestId = await _merchantService.submitMerchantRequest(merchant);

      // عرض رسالة النجاح
      _showSuccessDialog(requestId);
    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء إرسال الطلب: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Almarai', color: Colors.white),
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [successColor, Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'تم إرسال الطلب بنجاح!',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
                fontSize: 22,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: successColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: successColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'رقم الطلب:',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    requestId.substring(0, 8).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: successColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '• سيتم مراجعة طلبك خلال 2-3 أيام عمل\n• ستصلك رسالة تأكيد على الهاتف والإيميل\n• يمكنك متابعة حالة الطلب من التطبيق',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14,
                height: 1.6,
                color: textSecondaryColor,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              label: const Text(
                'العودة للرئيسية',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExistingRequestDialog(MerchantModel merchant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'طلب موجود مسبقاً',
          style: TextStyle(
            fontFamily: 'Almarai',
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        content: Text(
          'لديك طلب تسجيل تاجر مسبقاً.\n\nحالة الطلب: ${MerchantModel.getStatusName(merchant.status, true)}\nتاريخ التقديم: ${_formatDate(merchant.createdAt)}',
          style: const TextStyle(
            fontFamily: 'Almarai',
            color: textSecondaryColor,
          ),
        ),
        actions: [
          if (merchant.status == MerchantStatus.rejected) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadExistingData(merchant);
              },
              child: const Text(
                'تعديل الطلب',
                style: TextStyle(fontFamily: 'Almarai', color: primaryColor),
              ),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'العودة',
              style: TextStyle(fontFamily: 'Almarai', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _loadExistingData(MerchantModel merchant) {
    _fullNameController.text = merchant.fullName;
    _emailController.text = merchant.email;
    _phoneController.text = merchant.phoneNumber;
    _nationalIdController.text = merchant.nationalId;
    _businessNameController.text = merchant.businessName;
    _businessDescriptionController.text = merchant.businessDescription;
    _businessAddressController.text = merchant.businessAddress;
    _commercialRegistrationController.text = merchant.commercialRegistration;
    _bankNameController.text = merchant.bankName;
    _accountNumberController.text = merchant.accountNumber;
    _ibanController.text = merchant.iban;
    _accountHolderNameController.text = merchant.accountHolderName;
    
    setState(() {
      _selectedBusinessType = merchant.businessType;
      _selectedCity = merchant.city;
      _selectedProductCategories = List.from(merchant.productCategories);
      _selectedRevenue = merchant.estimatedMonthlyRevenue;
    });
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
