import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/jobs/models/job_model.dart';
import 'package:sumi/features/jobs/models/job_application_model.dart';
import 'package:sumi/features/jobs/services/jobs_service.dart';
import 'package:sumi/features/jobs/presentation/pages/apply_job_page.dart';
import 'package:intl/intl.dart';

class JobDetailsPage extends StatefulWidget {
  final JobModel job;

  const JobDetailsPage({super.key, required this.job});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  final JobsService _jobsService = JobsService();
  bool _hasApplied = false;
  bool _isCheckingApplication = true;

  @override
  void initState() {
    super.initState();
    _checkIfApplied();
  }

  Future<void> _checkIfApplied() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isCheckingApplication = false);
      return;
    }

    try {
      final applications = await _jobsService.getUserApplications(user.uid);
      final hasApplied = applications.any((app) => app.jobId == widget.job.id);
      
      setState(() {
        _hasApplied = hasApplied;
        _isCheckingApplication = false;
      });
    } catch (e) {
      setState(() => _isCheckingApplication = false);
    }
  }

  Future<void> _applyToJob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyJobPage(job: widget.job),
      ),
    );

    if (result == true) {
      setState(() => _hasApplied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تقديم طلبك بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareJob() {
    // يمكن إضافة مشاركة الوظيفة هنا
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم إضافة ميزة المشاركة قريباً')),
    );
  }

  void _saveJob() {
    // يمكن إضافة حفظ الوظيفة هنا
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم إضافة ميزة الحفظ قريباً')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar مخصص
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareJob,
                tooltip: 'مشاركة',
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: _saveJob,
                tooltip: 'حفظ',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          
          // محتوى الصفحة
          SliverToBoxAdapter(
            child: Column(
              children: [
                // معلومات الوظيفة الرئيسية
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // أيقونة الشركة والعنوان
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.business,
                                color: Theme.of(context).primaryColor,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.job.isFeatured)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'وظيفة مميزة',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    widget.job.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Almarai',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.job.companyName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontFamily: 'Almarai',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // معلومات سريعة
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickInfo(
                                      Icons.location_on_outlined,
                                      'الموقع',
                                      widget.job.location,
                                      Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildQuickInfo(
                                      Icons.work_outline,
                                      'نوع العمل',
                                      widget.job.jobType,
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickInfo(
                                      Icons.category_outlined,
                                      'الفئة',
                                      widget.job.category,
                                      Colors.purple,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildQuickInfo(
                                      Icons.attach_money,
                                      'الراتب',
                                      widget.job.getSalaryRange(),
                                      Colors.orange,
                                    ),
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
                
                const SizedBox(height: 16),
                
                // وصف الوظيفة
                _buildSection(
                  'وصف الوظيفة',
                  Icons.description_outlined,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.description,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // المتطلبات
                if (widget.job.requirements.isNotEmpty)
                  _buildSection(
                    'المتطلبات',
                    Icons.checklist_outlined,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.job.requirements.map((requirement) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  requirement,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // المزايا
                if (widget.job.benefits.isNotEmpty)
                  _buildSection(
                    'المزايا',
                    Icons.star_border_outlined,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.job.benefits.map((benefit) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // معلومات إضافية
                _buildSection(
                  'معلومات إضافية',
                  Icons.info_outline,
                  Column(
                    children: [
                      _buildInfoRow('تاريخ النشر', DateFormat('dd/MM/yyyy').format(widget.job.publishedAt)),
                      if (widget.job.expiresAt != null)
                        _buildInfoRow('تاريخ الانتهاء', DateFormat('dd/MM/yyyy').format(widget.job.expiresAt!)),
                      _buildInfoRow('عدد المتقدمين', '${widget.job.applicationsCount} متقدم'),
                      _buildInfoRow('الناشر', widget.job.publisherName),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100), // مساحة للـ floating button
              ],
            ),
          ),
        ],
      ),
      
      // زر التقديم
      floatingActionButton: _isCheckingApplication
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _hasApplied
              ? FloatingActionButton.extended(
                  onPressed: null,
                  icon: const Icon(Icons.check),
                  label: const Text('تم التقديم'),
                  backgroundColor: Colors.green,
                )
              : FloatingActionButton.extended(
                  onPressed: _applyToJob,
                  icon: const Icon(Icons.send),
                  label: const Text('قدم الآن'),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Almarai',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
