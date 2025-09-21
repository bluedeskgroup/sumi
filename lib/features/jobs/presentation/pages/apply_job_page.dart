import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/jobs/models/job_model.dart';
import 'package:sumi/features/jobs/models/job_application_model.dart';
import 'package:sumi/features/jobs/services/jobs_service.dart';

class ApplyJobPage extends StatefulWidget {
  final JobModel job;

  const ApplyJobPage({super.key, required this.job});

  @override
  State<ApplyJobPage> createState() => _ApplyJobPageState();
}

class _ApplyJobPageState extends State<ApplyJobPage> {
  final _formKey = GlobalKey<FormState>();
  final JobsService _jobsService = JobsService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();
  final _educationController = TextEditingController();
  final _currentJobController = TextEditingController();
  final _skillsController = TextEditingController();
  
  int _experienceYears = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    _educationController.dispose();
    _currentJobController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل');
      }

      final skills = _skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList();

      final application = JobApplicationModel(
        id: '', // سيتم إنشاؤه تلقائياً
        jobId: widget.job.id,
        applicantId: user.uid,
        applicantName: _nameController.text.trim(),
        applicantEmail: _emailController.text.trim(),
        applicantPhone: _phoneController.text.trim(),
        applicantImageUrl: user.photoURL,
        coverLetter: _coverLetterController.text.trim(),
        skills: skills,
        experienceYears: _experienceYears,
        education: _educationController.text.trim(),
        currentJobTitle: _currentJobController.text.trim(),
        appliedAt: DateTime.now(),
      );

      final applicationId = await _jobsService.applyToJob(application);

      if (applicationId != null) {
        Navigator.pop(context, true);
      } else {
        throw Exception('فشل في تقديم الطلب');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تقديم الطلب: $e'),
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
          'التقديم للوظيفة',
          style: TextStyle(fontFamily: 'Almarai'),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // معلومات الوظيفة
          Container(
            width: double.infinity,
            color: Theme.of(context).primaryColor,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: Theme.of(context).primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.job.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Almarai',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.job.companyName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // النموذج
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المعلومات الشخصية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // الاسم
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الاسم مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // البريد الإلكتروني
                    TextFormField(
                      controller: _emailController,
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
                      controller: _phoneController,
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
                    
                    const Text(
                      'المعلومات المهنية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // المؤهل التعليمي
                    TextFormField(
                      controller: _educationController,
                      decoration: InputDecoration(
                        labelText: 'المؤهل التعليمي',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'مثال: بكالوريوس هندسة حاسوب',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // الوظيفة الحالية
                    TextFormField(
                      controller: _currentJobController,
                      decoration: InputDecoration(
                        labelText: 'الوظيفة الحالية',
                        prefixIcon: const Icon(Icons.work_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'مثال: مطور تطبيقات',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // سنوات الخبرة
                    Row(
                      children: [
                        const Icon(Icons.timeline, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text(
                          'سنوات الخبرة:',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _experienceYears.toDouble(),
                            min: 0,
                            max: 20,
                            divisions: 20,
                            label: '$_experienceYears سنة',
                            onChanged: (value) {
                              setState(() {
                                _experienceYears = value.round();
                              });
                            },
                          ),
                        ),
                        Text(
                          '$_experienceYears سنة',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // المهارات
                    TextFormField(
                      controller: _skillsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'المهارات',
                        prefixIcon: const Icon(Icons.star_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'أدخل المهارات مفصولة بفاصلة\nمثال: Flutter, Dart, Firebase',
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'رسالة التقديم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // رسالة التقديم
                    TextFormField(
                      controller: _coverLetterController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'رسالة التقديم',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 100),
                          child: Icon(Icons.message_outlined),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'اكتب رسالة تعبر عن اهتمامك بالوظيفة وما يجعلك مناسباً لها...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // زر التقديم
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitApplication,
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
                                    'جارٍ التقديم...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            : const Text(
                                'تقديم الطلب',
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
                              'سيتم إرسال طلبك إلى صاحب العمل وستحصل على رد خلال 3-5 أيام عمل.',
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
          ),
        ],
      ),
    );
  }
}
