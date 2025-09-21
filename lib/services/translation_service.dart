import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/translation_model.dart';

class TranslationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static TranslationService? _instance;
  
  static TranslationService get instance {
    _instance ??= TranslationService._internal();
    return _instance!;
  }

  TranslationService._internal() {
    // لا نحمل الترجمات مباشرة في الـ constructor
    // سيتم تحميلها لاحقاً عبر initializeDefaultTranslations
  }

  final Map<String, TranslationModel> _translations = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Map<String, TranslationModel> get translations => Map.unmodifiable(_translations);

  // تحميل جميع الترجمات
  Future<void> _loadTranslations() async {
    if (_isLoading) return; // تجنب التحميل المتكرر
    
    _isLoading = true;
    notifyListeners();

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('translations')
          .where('isActive', isEqualTo: true)
          .limit(50) // حد أقصى لتجنب التحميل الثقيل
          .get();

      _translations.clear();
      for (var doc in snapshot.docs) {
        final translation = TranslationModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
        _translations[translation.key] = translation;
      }
    } catch (e) {
      debugPrint('Error loading translations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // استمع للتغييرات في الوقت الفعلي
  void _listenToTranslations() {
    _firestore
        .collection('translations')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final translation = TranslationModel.fromJson({
          ...change.doc.data() as Map<String, dynamic>,
          'id': change.doc.id,
        });

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            _translations[translation.key] = translation;
            break;
          case DocumentChangeType.removed:
            _translations.remove(translation.key);
            break;
        }
      }
      notifyListeners();
    });
  }

  // الحصول على نص مترجم
  String getText(String key, {bool isArabic = true, String? fallback}) {
    final translation = _translations[key];
    if (translation != null) {
      return isArabic ? translation.arabicText : translation.englishText;
    }
    return fallback ?? key;
  }

  // إضافة ترجمة جديدة
  Future<String> addTranslation(TranslationModel translation) async {
    try {
      final docRef = await _firestore.collection('translations').add(translation.toJson());
      _translations[translation.key] = translation.copyWith(id: docRef.id);
      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding translation: $e');
      rethrow;
    }
  }

  // تحديث ترجمة
  Future<void> updateTranslation(String id, TranslationModel translation) async {
    try {
      await _firestore.collection('translations').doc(id).update(
        translation.copyWith(
          updatedAt: Timestamp.now(),
        ).toJson(),
      );
    } catch (e) {
      debugPrint('Error updating translation: $e');
      rethrow;
    }
  }

  // حذف ترجمة
  Future<void> deleteTranslation(String id) async {
    try {
      await _firestore.collection('translations').doc(id).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error deleting translation: $e');
      rethrow;
    }
  }

  // البحث في الترجمات
  List<TranslationModel> searchTranslations(String query) {
    if (query.trim().isEmpty) {
      return translations.values.toList();
    }

    final lowerQuery = query.toLowerCase();
    return translations.values.where((translation) {
      return translation.key.toLowerCase().contains(lowerQuery) ||
          translation.arabicText.toLowerCase().contains(lowerQuery) ||
          translation.englishText.toLowerCase().contains(lowerQuery) ||
          translation.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // الحصول على ترجمات بحسب الفئة
  List<TranslationModel> getTranslationsByCategory(String category) {
    return translations.values
        .where((translation) => translation.category == category)
        .toList();
  }

  // تهيئة الترجمات الأساسية - محسنة للأداء
  Future<void> initializeDefaultTranslations() async {
    try {
      // تحميل الترجمات من Firebase أولاً
      if (_translations.isEmpty && !_isLoading) {
        await _loadTranslations();
        _listenToTranslations(); // بدء الاستماع بعد التحميل الأول
      }
      
      // إذا فشل تحميل الترجمات من Firebase، استخدم الافتراضية
      if (_translations.isEmpty) {
        await _initializeLocalTranslations();
      }
    } catch (e) {
      debugPrint('Error initializing translations: $e');
      // في حالة فشل Firebase، استخدم الترجمات المحلية
      await _initializeLocalTranslations();
    }
  }

  // تهيئة الترجمات المحلية كبديل
  Future<void> _initializeLocalTranslations() async {
    final defaultTranslations = [
      // العامة - General
      TranslationModel(
        id: '', key: 'app_name', arabicText: 'سومي', englishText: 'Sumi',
        category: TranslationCategory.general, description: 'اسم التطبيق',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'welcome', arabicText: 'مرحباً', englishText: 'Welcome',
        category: TranslationCategory.general, description: 'كلمة ترحيب',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'loading', arabicText: 'جاري التحميل...', englishText: 'Loading...',
        category: TranslationCategory.general, description: 'رسالة التحميل',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'error', arabicText: 'خطأ', englishText: 'Error',
        category: TranslationCategory.general, description: 'كلمة خطأ',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'success', arabicText: 'نجح', englishText: 'Success',
        category: TranslationCategory.general, description: 'كلمة نجح',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'no_internet', arabicText: 'لا يوجد اتصال بالإنترنت', englishText: 'No internet connection',
        category: TranslationCategory.errors, description: 'رسالة عدم وجود انترنت',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // الأزرار - Buttons
      TranslationModel(
        id: '', key: 'save', arabicText: 'حفظ', englishText: 'Save',
        category: TranslationCategory.buttons, description: 'زر الحفظ',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'cancel', arabicText: 'إلغاء', englishText: 'Cancel',
        category: TranslationCategory.buttons, description: 'زر الإلغاء',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'edit', arabicText: 'تعديل', englishText: 'Edit',
        category: TranslationCategory.buttons, description: 'زر التعديل',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'delete', arabicText: 'حذف', englishText: 'Delete',
        category: TranslationCategory.buttons, description: 'زر الحذف',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'search', arabicText: 'بحث', englishText: 'Search',
        category: TranslationCategory.buttons, description: 'زر البحث',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'add', arabicText: 'إضافة', englishText: 'Add',
        category: TranslationCategory.buttons, description: 'زر الإضافة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'update', arabicText: 'تحديث', englishText: 'Update',
        category: TranslationCategory.buttons, description: 'زر التحديث',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'submit', arabicText: 'إرسال', englishText: 'Submit',
        category: TranslationCategory.buttons, description: 'زر الإرسال',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'confirm', arabicText: 'تأكيد', englishText: 'Confirm',
        category: TranslationCategory.buttons, description: 'زر التأكيد',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'back', arabicText: 'رجوع', englishText: 'Back',
        category: TranslationCategory.buttons, description: 'زر الرجوع',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'next', arabicText: 'التالي', englishText: 'Next',
        category: TranslationCategory.buttons, description: 'زر التالي',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'finish', arabicText: 'إنهاء', englishText: 'Finish',
        category: TranslationCategory.buttons, description: 'زر الإنهاء',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'close', arabicText: 'إغلاق', englishText: 'Close',
        category: TranslationCategory.buttons, description: 'زر الإغلاق',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'refresh', arabicText: 'تحديث', englishText: 'Refresh',
        category: TranslationCategory.buttons, description: 'زر التحديث',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'retry', arabicText: 'إعادة المحاولة', englishText: 'Retry',
        category: TranslationCategory.buttons, description: 'زر إعادة المحاولة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // التنقل - Navigation
      TranslationModel(
        id: '', key: 'home', arabicText: 'الرئيسية', englishText: 'Home',
        category: TranslationCategory.navigation, description: 'الصفحة الرئيسية',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'profile', arabicText: 'الملف الشخصي', englishText: 'Profile',
        category: TranslationCategory.navigation, description: 'الملف الشخصي',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'settings', arabicText: 'الإعدادات', englishText: 'Settings',
        category: TranslationCategory.navigation, description: 'الإعدادات',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'notifications', arabicText: 'الإشعارات', englishText: 'Notifications',
        category: TranslationCategory.navigation, description: 'الإشعارات',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'menu', arabicText: 'القائمة', englishText: 'Menu',
        category: TranslationCategory.navigation, description: 'القائمة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // الوظائف - Jobs
      TranslationModel(
        id: '', key: 'job_vacancies', arabicText: 'الوظائف الشاغرة', englishText: 'Job Vacancies',
        category: TranslationCategory.jobs, description: 'عنوان قسم الوظائف',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'no_jobs_available', arabicText: 'لا توجد وظائف متاحة حالياً', englishText: 'No jobs available currently',
        category: TranslationCategory.jobs, description: 'رسالة عدم وجود وظائف',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'apply_now', arabicText: 'تقدم الآن', englishText: 'Apply Now',
        category: TranslationCategory.jobs, description: 'زر التقدم للوظيفة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'job_details', arabicText: 'تفاصيل الوظيفة', englishText: 'Job Details',
        category: TranslationCategory.jobs, description: 'عنوان تفاصيل الوظيفة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'job_title', arabicText: 'المسمى الوظيفي', englishText: 'Job Title',
        category: TranslationCategory.jobs, description: 'المسمى الوظيفي',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'company_name', arabicText: 'اسم الشركة', englishText: 'Company Name',
        category: TranslationCategory.jobs, description: 'اسم الشركة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'job_location', arabicText: 'موقع العمل', englishText: 'Job Location',
        category: TranslationCategory.jobs, description: 'موقع العمل',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'job_type', arabicText: 'نوع الوظيفة', englishText: 'Job Type',
        category: TranslationCategory.jobs, description: 'نوع الوظيفة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'full_time', arabicText: 'دوام كامل', englishText: 'Full Time',
        category: TranslationCategory.jobs, description: 'دوام كامل',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'part_time', arabicText: 'دوام جزئي', englishText: 'Part Time',
        category: TranslationCategory.jobs, description: 'دوام جزئي',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'internship', arabicText: 'تدريب', englishText: 'Internship',
        category: TranslationCategory.jobs, description: 'تدريب',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'freelance', arabicText: 'عمل حر', englishText: 'Freelance',
        category: TranslationCategory.jobs, description: 'عمل حر',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'salary_range', arabicText: 'نطاق الراتب', englishText: 'Salary Range',
        category: TranslationCategory.jobs, description: 'نطاق الراتب',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'job_description', arabicText: 'وصف الوظيفة', englishText: 'Job Description',
        category: TranslationCategory.jobs, description: 'وصف الوظيفة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'job_requirements', arabicText: 'متطلبات الوظيفة', englishText: 'Job Requirements',
        category: TranslationCategory.jobs, description: 'متطلبات الوظيفة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'responsibilities', arabicText: 'المسؤوليات', englishText: 'Responsibilities',
        category: TranslationCategory.jobs, description: 'المسؤوليات',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'benefits', arabicText: 'المزايا', englishText: 'Benefits',
        category: TranslationCategory.jobs, description: 'المزايا',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'application_submitted', arabicText: 'تم تقديم الطلب بنجاح', englishText: 'Application submitted successfully',
        category: TranslationCategory.jobs, description: 'رسالة نجاح تقديم الطلب',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'featured_job', arabicText: 'وظيفة مميزة', englishText: 'Featured Job',
        category: TranslationCategory.jobs, description: 'وظيفة مميزة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // المصادقة - Authentication
      TranslationModel(
        id: '', key: 'login', arabicText: 'تسجيل الدخول', englishText: 'Login',
        category: TranslationCategory.auth, description: 'تسجيل الدخول',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'register', arabicText: 'تسجيل جديد', englishText: 'Register',
        category: TranslationCategory.auth, description: 'تسجيل جديد',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'logout', arabicText: 'تسجيل الخروج', englishText: 'Logout',
        category: TranslationCategory.auth, description: 'تسجيل الخروج',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'email', arabicText: 'البريد الإلكتروني', englishText: 'Email',
        category: TranslationCategory.auth, description: 'البريد الإلكتروني',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'password', arabicText: 'كلمة المرور', englishText: 'Password',
        category: TranslationCategory.auth, description: 'كلمة المرور',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'forgot_password', arabicText: 'نسيت كلمة المرور؟', englishText: 'Forgot Password?',
        category: TranslationCategory.auth, description: 'نسيت كلمة المرور',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'reset_password', arabicText: 'إعادة تعيين كلمة المرور', englishText: 'Reset Password',
        category: TranslationCategory.auth, description: 'إعادة تعيين كلمة المرور',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // الملف الشخصي - Profile
      TranslationModel(
        id: '', key: 'full_name', arabicText: 'الاسم الكامل', englishText: 'Full Name',
        category: TranslationCategory.profile, description: 'الاسم الكامل',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'phone_number', arabicText: 'رقم الهاتف', englishText: 'Phone Number',
        category: TranslationCategory.profile, description: 'رقم الهاتف',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'date_of_birth', arabicText: 'تاريخ الميلاد', englishText: 'Date of Birth',
        category: TranslationCategory.profile, description: 'تاريخ الميلاد',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'address', arabicText: 'العنوان', englishText: 'Address',
        category: TranslationCategory.profile, description: 'العنوان',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'edit_profile', arabicText: 'تعديل الملف الشخصي', englishText: 'Edit Profile',
        category: TranslationCategory.profile, description: 'تعديل الملف الشخصي',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // النماذج - Forms
      TranslationModel(
        id: '', key: 'required_field', arabicText: 'هذا الحقل مطلوب', englishText: 'This field is required',
        category: TranslationCategory.forms, description: 'رسالة الحقل المطلوب',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'invalid_email', arabicText: 'البريد الإلكتروني غير صحيح', englishText: 'Invalid email',
        category: TranslationCategory.forms, description: 'رسالة البريد الإلكتروني غير صحيح',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'password_too_short', arabicText: 'كلمة المرور قصيرة جداً', englishText: 'Password too short',
        category: TranslationCategory.forms, description: 'رسالة كلمة المرور قصيرة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // الرسائل - Messages
      TranslationModel(
        id: '', key: 'operation_successful', arabicText: 'تمت العملية بنجاح', englishText: 'Operation successful',
        category: TranslationCategory.messages, description: 'رسالة نجاح العملية',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'operation_failed', arabicText: 'فشلت العملية', englishText: 'Operation failed',
        category: TranslationCategory.messages, description: 'رسالة فشل العملية',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'please_wait', arabicText: 'يرجى الانتظار...', englishText: 'Please wait...',
        category: TranslationCategory.messages, description: 'رسالة يرجى الانتظار',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'no_data_found', arabicText: 'لا توجد بيانات', englishText: 'No data found',
        category: TranslationCategory.messages, description: 'رسالة عدم وجود بيانات',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // الأخطاء - Errors
      TranslationModel(
        id: '', key: 'network_error', arabicText: 'خطأ في الشبكة', englishText: 'Network error',
        category: TranslationCategory.errors, description: 'خطأ في الشبكة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'server_error', arabicText: 'خطأ في الخادم', englishText: 'Server error',
        category: TranslationCategory.errors, description: 'خطأ في الخادم',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'unknown_error', arabicText: 'خطأ غير معروف', englishText: 'Unknown error',
        category: TranslationCategory.errors, description: 'خطأ غير معروف',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // لوحة التحكم - Admin
      TranslationModel(
        id: '', key: 'dashboard', arabicText: 'لوحة التحكم', englishText: 'Dashboard',
        category: TranslationCategory.admin, description: 'لوحة التحكم',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'manage_users', arabicText: 'إدارة المستخدمين', englishText: 'Manage Users',
        category: TranslationCategory.admin, description: 'إدارة المستخدمين',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'manage_jobs', arabicText: 'إدارة الوظائف', englishText: 'Manage Jobs',
        category: TranslationCategory.admin, description: 'إدارة الوظائف',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'manage_translations', arabicText: 'إدارة الترجمات', englishText: 'Manage Translations',
        category: TranslationCategory.admin, description: 'إدارة الترجمات',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),

      // التجار - Merchants
      TranslationModel(
        id: '', key: 'register_as_merchant', arabicText: 'تسجيل كتاجر', englishText: 'Register as Merchant',
        category: TranslationCategory.general, description: 'تسجيل كتاجر',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'merchant_registration', arabicText: 'تسجيل تاجر جديد', englishText: 'Merchant Registration',
        category: TranslationCategory.general, description: 'تسجيل تاجر جديد',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'personal_information', arabicText: 'البيانات الشخصية', englishText: 'Personal Information',
        category: TranslationCategory.forms, description: 'البيانات الشخصية',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'business_information', arabicText: 'بيانات العمل التجاري', englishText: 'Business Information',
        category: TranslationCategory.forms, description: 'بيانات العمل التجاري',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'financial_information', arabicText: 'البيانات المالية', englishText: 'Financial Information',
        category: TranslationCategory.forms, description: 'البيانات المالية',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'products_services', arabicText: 'المنتجات والخدمات', englishText: 'Products & Services',
        category: TranslationCategory.forms, description: 'المنتجات والخدمات',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'required_documents', arabicText: 'المستندات المطلوبة', englishText: 'Required Documents',
        category: TranslationCategory.forms, description: 'المستندات المطلوبة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'business_name', arabicText: 'اسم العمل التجاري', englishText: 'Business Name',
        category: TranslationCategory.forms, description: 'اسم العمل التجاري',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'business_type', arabicText: 'نوع النشاط التجاري', englishText: 'Business Type',
        category: TranslationCategory.forms, description: 'نوع النشاط التجاري',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'business_description', arabicText: 'وصف النشاط التجاري', englishText: 'Business Description',
        category: TranslationCategory.forms, description: 'وصف النشاط التجاري',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'business_address', arabicText: 'عنوان العمل', englishText: 'Business Address',
        category: TranslationCategory.forms, description: 'عنوان العمل',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'commercial_registration', arabicText: 'رقم السجل التجاري', englishText: 'Commercial Registration',
        category: TranslationCategory.forms, description: 'رقم السجل التجاري',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'tax_number', arabicText: 'الرقم الضريبي', englishText: 'Tax Number',
        category: TranslationCategory.forms, description: 'الرقم الضريبي',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'bank_name', arabicText: 'اسم البنك', englishText: 'Bank Name',
        category: TranslationCategory.forms, description: 'اسم البنك',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'account_number', arabicText: 'رقم الحساب', englishText: 'Account Number',
        category: TranslationCategory.forms, description: 'رقم الحساب',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'iban_number', arabicText: 'رقم الآيبان', englishText: 'IBAN Number',
        category: TranslationCategory.forms, description: 'رقم الآيبان',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'account_holder_name', arabicText: 'اسم صاحب الحساب', englishText: 'Account Holder Name',
        category: TranslationCategory.forms, description: 'اسم صاحب الحساب',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'national_id', arabicText: 'رقم الهوية', englishText: 'National ID',
        category: TranslationCategory.forms, description: 'رقم الهوية',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'profile_image', arabicText: 'صورة شخصية', englishText: 'Profile Image',
        category: TranslationCategory.forms, description: 'صورة شخصية',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'business_license', arabicText: 'الترخيص التجاري', englishText: 'Business License',
        category: TranslationCategory.forms, description: 'الترخيص التجاري',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'national_id_image', arabicText: 'صورة الهوية', englishText: 'National ID Image',
        category: TranslationCategory.forms, description: 'صورة الهوية',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'bank_statement', arabicText: 'كشف حساب بنكي', englishText: 'Bank Statement',
        category: TranslationCategory.forms, description: 'كشف حساب بنكي',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'product_images', arabicText: 'صور المنتجات', englishText: 'Product Images',
        category: TranslationCategory.forms, description: 'صور المنتجات',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'monthly_revenue', arabicText: 'الإيرادات الشهرية المتوقعة', englishText: 'Expected Monthly Revenue',
        category: TranslationCategory.forms, description: 'الإيرادات الشهرية المتوقعة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'merchant_pending', arabicText: 'في انتظار المراجعة', englishText: 'Pending Review',
        category: TranslationCategory.general, description: 'في انتظار المراجعة',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'merchant_approved', arabicText: 'مقبول', englishText: 'Approved',
        category: TranslationCategory.general, description: 'مقبول',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'merchant_rejected', arabicText: 'مرفوض', englishText: 'Rejected',
        category: TranslationCategory.general, description: 'مرفوض',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'merchant_suspended', arabicText: 'معلق', englishText: 'Suspended',
        category: TranslationCategory.general, description: 'معلق',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'submit_request', arabicText: 'إرسال الطلب', englishText: 'Submit Request',
        category: TranslationCategory.buttons, description: 'إرسال الطلب',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
      TranslationModel(
        id: '', key: 'request_submitted_successfully', arabicText: 'تم إرسال الطلب بنجاح!', englishText: 'Request submitted successfully!',
        category: TranslationCategory.messages, description: 'تم إرسال الطلب بنجاح',
        createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
      ),
    ];

    for (final translation in defaultTranslations) {
      // تحقق من عدم وجود الترجمة مسبقاً
      final existing = await _firestore
          .collection('translations')
          .where('key', isEqualTo: translation.key)
          .get();

      if (existing.docs.isEmpty) {
        await addTranslation(translation);
      }
    }
  }

  // إحصائيات الترجمات
  Map<String, int> getTranslationStats() {
    final stats = <String, int>{};
    
    for (final category in TranslationCategory.allCategories) {
      stats[category] = getTranslationsByCategory(category).length;
    }
    
    stats['total'] = translations.length;
    return stats;
  }

  // تصدير الترجمات كـ JSON
  Map<String, dynamic> exportTranslations() {
    final exported = <String, dynamic>{};
    
    for (final translation in translations.values) {
      exported[translation.key] = {
        'ar': translation.arabicText,
        'en': translation.englishText,
        'category': translation.category,
        'description': translation.description,
      };
    }
    
    return exported;
  }
}

// مساعد للوصول السهل للترجمات
class T {
  static final TranslationService _service = TranslationService.instance;

  static String get(String key, {bool isArabic = true, String? fallback}) {
    return _service.getText(key, isArabic: isArabic, fallback: fallback);
  }

  // اختصارات شائعة
  static String get save => get('save');
  static String get cancel => get('cancel');
  static String get edit => get('edit');
  static String get delete => get('delete');
  static String get search => get('search');
  static String get welcome => get('welcome');
  static String get appName => get('app_name');
  static String get jobVacancies => get('job_vacancies');
  static String get noJobsAvailable => get('no_jobs_available');
}
