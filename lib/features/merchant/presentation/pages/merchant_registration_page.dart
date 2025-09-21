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
import 'merchant_pending_approval_page.dart';
import '../../../auth/presentation/pages/login_page.dart';

class MerchantRegistrationPage extends StatefulWidget {
  const MerchantRegistrationPage({super.key});

  @override
  State<MerchantRegistrationPage> createState() => _MerchantRegistrationPageState();
}

class _MerchantRegistrationPageState extends State<MerchantRegistrationPage> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isLoading = false;
  bool _checkingAuth = true;
  
  // Controllers for form fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessDescriptionController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _commercialRegistrationController = TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  final TextEditingController _accountHolderNameController = TextEditingController();
  
  // Selected values
  BusinessType _selectedBusinessType = BusinessType.retail;
  String _selectedCity = 'الرياض';
  List<String> _selectedProductCategories = [];
  List<String> _selectedServiceTypes = [];
  String _selectedRevenue = 'أقل من 10,000 ريال';
  
  // Images
  File? _profileImage;
  File? _businessLicenseImage;
  File? _nationalIdImage;
  File? _bankStatementImage;
  List<File> _productImages = [];
  
  final ImagePicker _picker = ImagePicker();
  final MerchantService _merchantService = MerchantService.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _commercialRegistrationController.dispose();
    _taxNumberController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    _accountHolderNameController.dispose();
  }

  Future<void> _checkExistingRequest() async {
    try {
      // التحقق من حالة تسجيل الدخول أولاً
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // المستخدم غير مسجل دخول، توجيهه لصفحة تسجيل الدخول
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يجب تسجيل الدخول أولاً لتسجيل حساب تاجر'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(); // العودة للصفحة السابقة
        }
        return;
      }

      // التحقق من وجود طلب سابق
      final existingRequest = await _merchantService.getCurrentUserMerchantRequest();
      if (existingRequest != null && mounted) {
        // إذا كان الطلب قيد المراجعة أو معتمد، انقل للصفحة المناسبة
        if (existingRequest.status == MerchantStatus.pending) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MerchantPendingApprovalPage(
                merchantId: existingRequest.id,
                showBackButton: true,
              ),
            ),
          );
          return;
        } else if (existingRequest.status == MerchantStatus.approved) {
          // التاجر معتمد، انقل للصفحة الرئيسية
          Navigator.of(context).pushReplacementNamed('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('مرحباً بك! حسابك التجاري معتمد'),
              backgroundColor: Colors.green,
            ),
          );
          return;
        }
        // إذا كان مرفوض أو معلق، اعرض الـ dialog
        _showExistingRequestDialog(existingRequest);
      }
    } catch (e) {
      debugPrint('Error in _checkExistingRequest: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في التحقق من البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showExistingRequestDialog(MerchantModel merchant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'طلب موجود مسبقاً',
          style: TextStyle(fontFamily: 'Almarai', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'لديك طلب تسجيل تاجر ${MerchantModel.getStatusName(merchant.status, true)} مسبقاً.\n\nحالة الطلب: ${MerchantModel.getStatusName(merchant.status, true)}\nتاريخ التقديم: ${_formatDate(merchant.createdAt)}',
          style: const TextStyle(fontFamily: 'Almarai'),
        ),
        actions: [
          if (merchant.status == MerchantStatus.rejected) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadExistingData(merchant);
              },
              child: const Text('تعديل الطلب', style: TextStyle(fontFamily: 'Almarai')),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('العودة', style: TextStyle(fontFamily: 'Almarai')),
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
    _taxNumberController.text = merchant.taxNumber;
    _bankNameController.text = merchant.bankName;
    _accountNumberController.text = merchant.accountNumber;
    _ibanController.text = merchant.iban;
    _accountHolderNameController.text = merchant.accountHolderName;
    
    setState(() {
      _selectedBusinessType = merchant.businessType;
      _selectedCity = merchant.city;
      _selectedProductCategories = List.from(merchant.productCategories);
      _selectedServiceTypes = List.from(merchant.serviceTypes);
      _selectedRevenue = merchant.estimatedMonthlyRevenue;
    });
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // التحقق الفوري من حالة تسجيل الدخول
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // أثناء التحميل
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF667EEA)),
                  SizedBox(height: 16),
                  Text(
                    'جارٍ التحقق من حالة تسجيل الدخول...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // إذا لم يكن مسجل دخول
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          debugPrint('MerchantRegistrationPage: User is not logged in');
          return _buildLoginRequiredScreen();
        }

        debugPrint('MerchantRegistrationPage: User is logged in - ${authSnapshot.data?.uid}');

        // المستخدم مسجل دخول، عرض صفحة التسجيل
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPersonalInfoStep(),
                      _buildBusinessInfoStep(),
                      _buildFinancialInfoStep(),
                      _buildProductsServicesStep(),
                      _buildDocumentsStep(),
                    ],
                  ),
                ),
                _buildNavigationButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginRequiredScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('تسجيل حساب تاجر'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة القفل
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 60,
                color: Colors.orange[600],
              ),
            ),
            const SizedBox(height: 32),
            
            // العنوان الرئيسي
            const Text(
              'يجب تسجيل الدخول أولاً',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // النص التوضيحي
            Text(
              'لتتمكن من تسجيل حساب تاجر، يجب أن يكون لديك حساب مستخدم في التطبيق أولاً.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            // معلومات إضافية
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'كيفية التسجيل كتاجر:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStepRow('1', 'سجل دخول أو إنشاء حساب مستخدم'),
                  _buildStepRow('2', 'اذهب لقسم تسجيل التاجر'),
                  _buildStepRow('3', 'املأ بيانات العمل والوثائق'),
                  _buildStepRow('4', 'انتظر موافقة الإدارة'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // الأزرار
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // إغلاق الصفحة الحالية والذهاب لتسجيل الدخول
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('تسجيل الدخول'),
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('العودة للخلف'),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
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
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تسجيل تاجر جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Almarai',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المرحلة ${_currentStep + 1} من $_totalSteps',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: 'Almarai',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : isCurrent
                                  ? const Color(0xFF667EEA)
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF667EEA) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          color: isCompleted || isCurrent ? Colors.white : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStepTitle(index),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? const Color(0xFF667EEA) : Colors.grey[600],
                          fontFamily: 'Almarai',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'البيانات\nالشخصية';
      case 1:
        return 'بيانات\nالعمل';
      case 2:
        return 'البيانات\nالمالية';
      case 3:
        return 'المنتجات\nوالخدمات';
      case 4:
        return 'المستندات\nالمطلوبة';
      default:
        return '';
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('البيانات الشخصية', 'يرجى إدخال بياناتك الشخصية بدقة'),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _fullNameController,
              label: 'الاسم الكامل',
              hint: 'أدخل اسمك الثلاثي أو الرباعي',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _emailController,
              label: 'البريد الإلكتروني',
              hint: 'example@email.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'البريد الإلكتروني غير صحيح';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _phoneController,
              label: 'رقم الهاتف',
              hint: '01xxxxxxxxx',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.length < 10) {
                  return 'رقم الهاتف غير صحيح';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildTextField(
              controller: _nationalIdController,
              label: 'رقم الهوية',
              hint: '12345678901234',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(14),
              ],
              validator: (value) {
                if (value == null || value.length != 14) {
                  return 'رقم الهوية يجب أن يكون 14 رقم';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('بيانات العمل التجاري', 'معلومات عن نشاطك التجاري'),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _businessNameController,
            label: 'اسم العمل التجاري',
            hint: 'أدخل اسم متجرك أو شركتك',
            icon: Icons.business,
            validator: (value) {
              if (value == null || value.trim().length < 3) {
                return 'اسم العمل يجب أن يكون 3 أحرف على الأقل';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildDropdownField<BusinessType>(
            value: _selectedBusinessType,
            label: 'نوع النشاط التجاري',
            icon: Icons.category,
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
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _businessDescriptionController,
            label: 'وصف النشاط التجاري',
            hint: 'اشرح نوع المنتجات أو الخدمات التي تقدمها',
            icon: Icons.description,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().length < 10) {
                return 'الوصف يجب أن يكون 10 أحرف على الأقل';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _businessAddressController,
            label: 'عنوان العمل',
            hint: 'العنوان التفصيلي لمكان العمل',
            icon: Icons.location_on,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().length < 10) {
                return 'العنوان يجب أن يكون واضح ومفصل';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildDropdownField<String>(
            value: _selectedCity,
            label: 'المحافظة',
            icon: Icons.location_city,
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
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _commercialRegistrationController,
            label: 'رقم السجل التجاري (اختياري)',
            hint: 'إذا كان متوفراً',
            icon: Icons.receipt_long,
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _taxNumberController,
            label: 'الرقم الضريبي (اختياري)',
            hint: 'إذا كان متوفراً',
            icon: Icons.receipt,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('البيانات المالية', 'معلومات حسابك البنكي لتحويل الأرباح'),
          const SizedBox(height: 20),
          
          _buildTextField(
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
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _accountNumberController,
            label: 'رقم الحساب',
            hint: 'رقم حسابك البنكي',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'رقم الحساب غير صحيح';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _ibanController,
            label: 'رقم الآيبان (IBAN)',
            hint: 'EG38XXXXXXXXXXXXXXXXXXXXXXX',
            icon: Icons.account_balance_wallet,
            validator: (value) {
              if (value == null || value.length < 15) {
                return 'رقم الآيبان غير صحيح';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
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
          
          const SizedBox(height: 16),
          
          _buildDropdownField<String>(
            value: _selectedRevenue,
            label: 'الإيرادات الشهرية المتوقعة',
            icon: Icons.monetization_on,
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
    );
  }

  Widget _buildProductsServicesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('المنتجات والخدمات', 'حدد ما تقدمه من منتجات أو خدمات'),
          const SizedBox(height: 20),
          
          _buildMultiSelectSection(
            title: 'فئات المنتجات',
            subtitle: 'اختر فئات المنتجات التي تبيعها',
            icon: Icons.inventory,
            items: MerchantModel.availableProductCategories,
            selectedItems: _selectedProductCategories,
            onSelectionChanged: (selected) {
              setState(() {
                _selectedProductCategories = selected;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          _buildMultiSelectSection(
            title: 'أنواع الخدمات',
            subtitle: 'اختر أنواع الخدمات التي تقدمها',
            icon: Icons.design_services,
            items: ServiceCategory.serviceTypes,
            selectedItems: _selectedServiceTypes,
            onSelectionChanged: (selected) {
              setState(() {
                _selectedServiceTypes = selected;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('المستندات المطلوبة', 'قم برفع الصور والمستندات المطلوبة'),
          const SizedBox(height: 20),
          
          _buildImageUploadCard(
            title: 'صورة شخصية',
            subtitle: 'صورة واضحة لوجهك',
            icon: Icons.person,
            image: _profileImage,
            onTap: () => _pickImage('profile'),
            isRequired: true,
          ),
          
          const SizedBox(height: 16),
          
          _buildImageUploadCard(
            title: 'صورة الهوية',
            subtitle: 'صورة واضحة لبطاقة الهوية',
            icon: Icons.credit_card,
            image: _nationalIdImage,
            onTap: () => _pickImage('nationalId'),
            isRequired: true,
          ),
          
          const SizedBox(height: 16),
          
          _buildImageUploadCard(
            title: 'الترخيص التجاري',
            subtitle: 'صورة الترخيص أو السجل التجاري (إن وجد)',
            icon: Icons.receipt_long,
            image: _businessLicenseImage,
            onTap: () => _pickImage('businessLicense'),
            isRequired: false,
          ),
          
          const SizedBox(height: 16),
          
          _buildImageUploadCard(
            title: 'كشف حساب بنكي',
            subtitle: 'صورة من كشف الحساب البنكي',
            icon: Icons.account_balance,
            image: _bankStatementImage,
            onTap: () => _pickImage('bankStatement'),
            isRequired: true,
          ),
          
          const SizedBox(height: 16),
          
          _buildMultipleImageUploadCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Almarai',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontFamily: 'Almarai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      style: const TextStyle(fontFamily: 'Almarai'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(fontFamily: 'Almarai'),
        hintStyle: const TextStyle(fontFamily: 'Almarai'),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(fontFamily: 'Almarai'),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelectSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onSelectionChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF667EEA)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Almarai',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = selectedItems.contains(item);
              return FilterChip(
                label: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF667EEA),
                    fontFamily: 'Almarai',
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF667EEA),
                backgroundColor: Colors.grey[100],
                checkmarkColor: Colors.white,
                onSelected: (selected) {
                  final newSelection = List<String>.from(selectedItems);
                  if (selected) {
                    newSelection.add(item);
                  } else {
                    newSelection.remove(item);
                  }
                  onSelectionChanged(newSelection);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? const Color(0xFF10B981) : (isRequired ? Colors.red[300]! : Colors.grey[300]!),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: image != null 
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                image != null ? Icons.check_circle : icon,
                color: image != null ? const Color(0xFF10B981) : const Color(0xFF667EEA),
                size: 24,
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
                          fontFamily: 'Almarai',
                        ),
                      ),
                      if (isRequired) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Almarai',
                    ),
                  ),
                  if (image != null)
                    Text(
                      'تم الرفع بنجاح',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              image != null ? Icons.edit : Icons.upload,
              color: const Color(0xFF667EEA),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleImageUploadCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _productImages.isNotEmpty ? const Color(0xFF10B981) : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _productImages.isNotEmpty ? Icons.check_circle : Icons.photo_library,
                  color: _productImages.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF667EEA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'صور المنتجات (اختياري)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    Text(
                      'أضف صور لبعض منتجاتك (حتى 5 صور)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Almarai',
                      ),
                    ),
                    if (_productImages.isNotEmpty)
                      Text(
                        'تم رفع ${_productImages.length} صور',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickMultipleImages(),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text(
                    'إضافة صور',
                    style: TextStyle(fontFamily: 'Almarai'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (_productImages.isNotEmpty) ...[
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _productImages.clear()),
                  icon: const Icon(Icons.clear),
                  label: const Text(
                    'مسح الكل',
                    style: TextStyle(fontFamily: 'Almarai'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
          if (_productImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _productImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _productImages[index],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _productImages.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  'السابق',
                  style: TextStyle(fontFamily: 'Almarai'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[700],
                  minimumSize: const Size(0, 50),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : (_currentStep == _totalSteps - 1 ? _submitForm : _nextStep),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_currentStep == _totalSteps - 1 ? Icons.send : Icons.arrow_forward),
              label: Text(
                _currentStep == _totalSteps - 1 ? 'إرسال الطلب' : 'التالي',
                style: const TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 50),
              ),
            ),
          ),
        ],
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
      );
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = [];
      
      // يمكن اختيار حتى 5 صور
      for (int i = 0; i < 5 - _productImages.length; i++) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (image != null) {
          images.add(image);
          
          // السؤال عن إضافة صورة أخرى
          if (i < 4 - _productImages.length) {
            final bool? addMore = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('إضافة صورة أخرى؟'),
                content: Text('تم اختيار ${images.length} صور. هل تريد إضافة صورة أخرى؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('لا'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('نعم'),
                  ),
                ],
              ),
            );
            
            if (addMore != true) break;
          }
        } else {
          break; // المستخدم ألغى اختيار الصورة
        }
      }

      if (images.isNotEmpty) {
        setState(() {
          _productImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصور: $e')),
      );
    }
  }

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
          _showErrorSnackBar('اسم العمل يجب أن يكون 3 أحرف على الأقل');
          return false;
        }
        if (_businessDescriptionController.text.trim().length < 10) {
          _showErrorSnackBar('وصف العمل يجب أن يكون 10 أحرف على الأقل');
          return false;
        }
        if (_businessAddressController.text.trim().length < 10) {
          _showErrorSnackBar('عنوان العمل يجب أن يكون واضح ومفصل');
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
        if (_selectedProductCategories.isEmpty && _selectedServiceTypes.isEmpty) {
          _showErrorSnackBar('يجب اختيار فئة واحدة على الأقل من المنتجات أو الخدمات');
          return false;
        }
        return true;
      case 4:
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Almarai'),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('يجب تسجيل الدخول أولاً لإكمال عملية التسجيل');
        // توجيه المستخدم لصفحة تسجيل الدخول
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
        return;
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
      List<String> productImagesUrls = [];

      // رفع الصور المطلوبة
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

      // رفع صور المنتجات
      if (_productImages.isNotEmpty) {
        productImagesUrls = await _merchantService.uploadProductImages(
          _productImages,
          user.uid,
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
        taxNumber: _taxNumberController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        iban: _ibanController.text.trim(),
        accountHolderName: _accountHolderNameController.text.trim(),
        productCategories: _selectedProductCategories,
        serviceTypes: _selectedServiceTypes,
        estimatedMonthlyRevenue: _selectedRevenue,
        profileImageUrl: profileImageUrl,
        businessLicenseUrl: businessLicenseUrl,
        nationalIdImageUrl: nationalIdImageUrl,
        bankStatementUrl: bankStatementUrl,
        productImagesUrls: productImagesUrls,
        status: MerchantStatus.pending,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // التحقق من صحة البيانات
      final validationErrors = _merchantService.validateMerchantData(merchant);
      if (validationErrors.isNotEmpty) {
        _showErrorSnackBar(validationErrors.values.first);
        return;
      }

      // إرسال الطلب
      final requestId = await _merchantService.submitMerchantRequest(merchant);

      // الانتقال لصفحة انتظار الموافقة
      _navigateToPendingApproval(requestId);

    } catch (e) {
      _showErrorSnackBar('حدث خطأ أثناء إرسال الطلب: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPendingApproval(String requestId) {
    // إظهار رسالة نجاح سريعة
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

    // الانتقال لصفحة انتظار الموافقة بعد تأخير قصير
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

  void _showSuccessDialog(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تم إرسال الطلب بنجاح!',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'شكراً لك على تقديم طلب التسجيل كتاجر.',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'رقم الطلب:',
                        style: TextStyle(
                          fontFamily: 'Almarai',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    requestId.substring(0, 8).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• سيتم مراجعة طلبك خلال 2-3 أيام عمل\n• ستصلك رسالة تأكيد على الهاتف والإيميل\n• يمكنك متابعة حالة الطلب من التطبيق\n• في حالة الموافقة ستتمكن من إضافة منتجاتك',
              style: TextStyle(
                fontFamily: 'Almarai',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // إغلاق الحوار
                Navigator.pop(context); // العودة للصفحة السابقة
              },
              icon: const Icon(Icons.home),
              label: const Text(
                'العودة للرئيسية',
                style: TextStyle(
                  fontFamily: 'Almarai',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
