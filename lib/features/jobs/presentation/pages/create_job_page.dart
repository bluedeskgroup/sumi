import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/jobs/models/job_model.dart';
import 'package:sumi/features/jobs/services/jobs_service.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final JobsService _jobsService = JobsService();
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _companyController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();
  
  String _selectedCategory = 'تقنية المعلومات';
  String _selectedLocation = 'القاهرة';
  String _selectedJobType = 'دوام كامل';
  String _selectedCurrency = 'ج.م';
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'تقنية المعلومات', 'التسويق', 'المبيعات', 'الموارد البشرية', 
    'التصميم', 'المحاسبة', 'الهندسة', 'الطب', 'التعليم', 'أخرى'
  ];
  
  final List<String> _locations = [
    'القاهرة', 'الإسكندرية', 'الجيزة', 'الدقهلية', 'الشرقية', 
    'البحيرة', 'أسوان', 'الأقصر', 'أخرى'
  ];
  
  final List<String> _jobTypes = [
    'دوام كامل', 'دوام جزئي', 'تدريب', 'عمل حر', 'عقد مؤقت'
  ];

  final List<String> _currencies = ['ج.م', 'ريال', 'درهم', 'دولار'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _companyController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _contactEmailController.text = user.email ?? '';
    }
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar'),
    );
    
    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل');
      }

      final requirements = _requirementsController.text
          .split('\n')
          .map((req) => req.trim())
          .where((req) => req.isNotEmpty)
          .toList();

      final benefits = _benefitsController.text
          .split('\n')
          .map((benefit) => benefit.trim())
          .where((benefit) => benefit.isNotEmpty)
          .toList();

      final job = JobModel(
        id: '', // سيتم إنشاؤه تلقائياً
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        companyName: _companyController.text.trim(),
        location: _selectedLocation,
        jobType: _selectedJobType,
        category: _selectedCategory,
        salaryMin: _salaryMinController.text.isNotEmpty 
            ? double.tryParse(_salaryMinController.text) 
            : null,
        salaryMax: _salaryMaxController.text.isNotEmpty 
            ? double.tryParse(_salaryMaxController.text) 
            : null,
        salaryCurrency: _selectedCurrency,
        requirements: requirements,
        benefits: benefits,
        contactEmail: _contactEmailController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
        publisherId: user.uid,
        publisherName: user.displayName ?? 'مستخدم',
        publisherImageUrl: user.photoURL ?? '',
        publishedAt: DateTime.now(),
        expiresAt: _expiryDate,
        isActive: true,
        isFeatured: false,
      );

      final jobId = await _jobsService.createJob(job);

      if (jobId != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نشر الوظيفة بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('فشل في نشر الوظيفة');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في نشر الوظيفة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'نشر وظيفة جديدة',
          style: TextStyle(fontFamily: 'Almarai'),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات الوظيفة الأساسية
              _buildSectionTitle('معلومات الوظيفة الأساسية'),
              const SizedBox(height: 16),
              
              // عنوان الوظيفة
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الوظيفة *',
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'مثال: مطور تطبيقات Flutter',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'عنوان الوظيفة مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // اسم الشركة
              TextFormField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: 'اسم الشركة *',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'اسم الشركة مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // وصف الوظيفة
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'وصف الوظيفة *',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 120),
                    child: Icon(Icons.description_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'اكتب وصفاً مفصلاً للوظيفة والمهام المطلوبة...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'وصف الوظيفة مطلوب';
                  }
                  if (value.length < 50) {
                    return 'يجب أن يكون الوصف 50 حرف على الأقل';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // تفاصيل الوظيفة
              _buildSectionTitle('تفاصيل الوظيفة'),
              const SizedBox(height: 16),
              
              // الفئة والموقع
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'الفئة *',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _categories.map((category) => 
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: InputDecoration(
                        labelText: 'الموقع *',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _locations.map((location) => 
                        DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        setState(() => _selectedLocation = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // نوع الوظيفة
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                decoration: InputDecoration(
                  labelText: 'نوع الوظيفة *',
                  prefixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _jobTypes.map((type) => 
                  DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                ).toList(),
                onChanged: (value) {
                  setState(() => _selectedJobType = value!);
                },
              ),
              
              const SizedBox(height: 24),
              
              // الراتب
              _buildSectionTitle('الراتب (اختياري)'),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'الحد الأدنى',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salaryMaxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'الحد الأقصى',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'العملة',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _currencies.map((currency) => 
                        DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        ),
                      ).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCurrency = value!);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // المتطلبات
              _buildSectionTitle('المتطلبات'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _requirementsController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'المتطلبات',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 120),
                    child: Icon(Icons.checklist_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'اكتب كل متطلب في سطر منفصل:\n• خبرة 3 سنوات في Flutter\n• إجادة اللغة الإنجليزية\n• القدرة على العمل ضمن فريق',
                  alignLabelWithHint: true,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // المزايا
              _buildSectionTitle('المزايا'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _benefitsController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'المزايا',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.star_border_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: 'اكتب كل ميزة في سطر منفصل:\n• تأمين صحي شامل\n• مرونة في أوقات العمل\n• فرص تطوير مهني',
                  alignLabelWithHint: true,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // معلومات التواصل
              _buildSectionTitle('معلومات التواصل'),
              const SizedBox(height: 16),
              
              // البريد الإلكتروني
              TextFormField(
                controller: _contactEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'البريد الإلكتروني *',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'البريد الإلكتروني مطلوب';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // رقم الهاتف
              TextFormField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف *',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'رقم الهاتف مطلوب';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // تاريخ انتهاء الإعلان
              _buildSectionTitle('تاريخ انتهاء الإعلان (اختياري)'),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: _selectExpiryDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined),
                      const SizedBox(width: 12),
                      Text(
                        _expiryDate != null
                            ? 'ينتهي في: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                            : 'اختر تاريخ انتهاء الإعلان',
                        style: TextStyle(
                          color: _expiryDate != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (_expiryDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() => _expiryDate = null);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // زر النشر
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'جارٍ النشر...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : const Text(
                          'نشر الوظيفة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // ملاحظة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'سيتم مراجعة الوظيفة من قبل الإدارة قبل النشر. ستظهر خلال 24 ساعة من التقديم.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Almarai',
      ),
    );
  }
}
