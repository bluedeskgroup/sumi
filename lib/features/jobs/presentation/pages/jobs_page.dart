import 'package:flutter/material.dart';
import 'package:sumi/features/jobs/models/job_model.dart';
import 'package:sumi/features/jobs/services/jobs_service.dart';
import 'package:sumi/features/jobs/presentation/pages/job_details_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final JobsService _jobsService = JobsService();
  final TextEditingController _searchController = TextEditingController();
  
  List<JobModel> _allJobs = [];
  List<JobModel> _filteredJobs = [];
  bool _isLoading = true;
  String _selectedCategory = '';
  String _selectedLocation = '';
  String _selectedJobType = '';

  List<String> get _categories {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return isRTL 
      ? ['الكل', 'تقنية المعلومات', 'التسويق', 'المبيعات', 'الموارد البشرية', 'التصميم', 'المحاسبة', 'الهندسة', 'الطب', 'التعليم', 'أخرى']
      : ['All', 'Information Technology', 'Marketing', 'Sales', 'Human Resources', 'Design', 'Accounting', 'Engineering', 'Medicine', 'Education', 'Other'];
  }
  
  List<String> get _locations {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return isRTL 
      ? ['الكل', 'القاهرة', 'الإسكندرية', 'الجيزة', 'الدقهلية', 'الشرقية', 'البحيرة', 'أسوان', 'الأقصر', 'أخرى']
      : ['All', 'Cairo', 'Alexandria', 'Giza', 'Dakahlia', 'Sharqia', 'Beheira', 'Aswan', 'Luxor', 'Other'];
  }
  
  List<String> get _jobTypes {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return isRTL 
      ? ['الكل', 'دوام كامل', 'دوام جزئي', 'تدريب', 'عمل حر', 'عقد مؤقت']
      : ['All', 'Full Time', 'Part Time', 'Internship', 'Freelance', 'Contract'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelectedValues();
      _loadJobs();
    });
    _searchController.addListener(_filterJobs);
  }

  void _initializeSelectedValues() {
    setState(() {
      _selectedCategory = _categories[0];
      _selectedLocation = _locations[0];
      _selectedJobType = _jobTypes[0];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    
    try {
      final jobs = await _jobsService.getActiveJobs(limit: 50);
      setState(() {
        _allJobs = jobs;
        _filteredJobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الوظائف: $e')),
      );
    }
  }

  void _filterJobs() {
    setState(() {
      _filteredJobs = _allJobs.where((job) {
        // تصفية بالبحث
        final query = _searchController.text.toLowerCase();
        final matchesSearch = query.isEmpty ||
            job.title.toLowerCase().contains(query) ||
            job.companyName.toLowerCase().contains(query) ||
            job.description.toLowerCase().contains(query);

        // تصفية بالفئة
        final matchesCategory = _selectedCategory == _categories[0] ||
            job.category == _selectedCategory;

        // تصفية بالموقع
        final matchesLocation = _selectedLocation == _locations[0] ||
            job.location == _selectedLocation;

        // تصفية بنوع الوظيفة
        final matchesJobType = _selectedJobType == _jobTypes[0] ||
            job.jobType == _selectedJobType;

        return matchesSearch && matchesCategory && matchesLocation && matchesJobType;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = _categories[0];
      _selectedLocation = _locations[0];
      _selectedJobType = _jobTypes[0];
      _searchController.clear();
    });
    _filterJobs();
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
                Color(0xFF6B73FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF667EEA),
                blurRadius: 20,
                offset: Offset(0, 10),
                spreadRadius: -5,
              ),
            ],
          ),
          child: AppBar(
            title: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  isRTL ? 'الوظائف الشاغرة' : 'Job Vacancies',
                  style: const TextStyle(
                    fontFamily: 'Almarai',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isRTL ? 'اكتشف فرص العمل المثالية' : 'Discover Perfect Job Opportunities',
                  style: TextStyle(
                    fontFamily: 'Almarai',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  isRTL ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                  size: 20,
                ),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8, left: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  color: Colors.white,
                  onPressed: _loadJobs,
                  tooltip: isRTL ? 'تحديث' : 'Refresh',
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // شريط البحث والفلترة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                  Color(0xFF6B73FF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  children: [
                    // شريط البحث
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            const Color(0xFFF8FAFC),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 15,
                            offset: const Offset(0, -5),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textDirection: Directionality.of(context),
                        style: const TextStyle(
                          fontFamily: 'Almarai',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: isRTL ? '🔍 البحث في الوظائف...' : '🔍 Search jobs...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontFamily: 'Almarai',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? Container(
                                  margin: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    color: Colors.grey[600],
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterJobs();
                                    },
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF667EEA), 
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // فلاتر
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Directionality(
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              isRTL ? 'الفئة' : 'Category',
                              _selectedCategory,
                              _categories,
                              (value) {
                                setState(() => _selectedCategory = value);
                                _filterJobs();
                              },
                              isRTL,
                            ),
                            const SizedBox(width: 12),
                            _buildFilterChip(
                              isRTL ? 'الموقع' : 'Location',
                              _selectedLocation,
                              _locations,
                              (value) {
                                setState(() => _selectedLocation = value);
                                _filterJobs();
                              },
                              isRTL,
                            ),
                            const SizedBox(width: 12),
                            _buildFilterChip(
                              isRTL ? 'نوع الوظيفة' : 'Job Type',
                              _selectedJobType,
                              _jobTypes,
                              (value) {
                                setState(() => _selectedJobType = value);
                                _filterJobs();
                              },
                              isRTL,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFEF4444).withOpacity(0.1),
                                    const Color(0xFFF97316).withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _resetFilters,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh_rounded,
                                          size: 20,
                                          color: const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isRTL ? 'إعادة تعيين' : 'Reset',
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            fontFamily: 'Almarai',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
          
          // عدد النتائج
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667EEA).withOpacity(0.15),
                        const Color(0xFF764BA2).withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.work_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isRTL 
                          ? 'النتائج: ${_filteredJobs.length} وظيفة'
                          : 'Results: ${_filteredJobs.length} jobs',
                        style: const TextStyle(
                          color: Color(0xFF667EEA),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_filteredJobs.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isRTL ? 'وظائف متاحة' : 'Available',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Almarai',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
          
          // قائمة الوظائف
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _filteredJobs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadJobs,
                        child: AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredJobs.length,
                            itemBuilder: (context, index) {
                              final job = _filteredJobs[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildJobCard(job, isRTL),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    ValueChanged<String> onSelected,
    bool isRTL,
  ) {
    final isSelected = selectedValue != options[0];
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.filter_list_rounded,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isRTL ? 'اختر $label' : 'Select $label',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Almarai',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.map((option) {
                        final isOptionSelected = option == selectedValue;
                        return Container(
                          decoration: BoxDecoration(
                            color: isOptionSelected ? const Color(0xFF6366F1) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isOptionSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                onSelected(option);
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: isOptionSelected ? Colors.white : const Color(0xFF475569),
                                    fontWeight: isOptionSelected ? FontWeight.w600 : FontWeight.normal,
                                    fontFamily: 'Almarai',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label: $selectedValue',
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Almarai',
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(JobModel job, bool isRTL) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFFBFCFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: job.isFeatured 
              ? const Color(0xFF667EEA).withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: job.isFeatured ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: job.isFeatured 
                ? const Color(0xFF667EEA).withOpacity(0.15)
                : Colors.black.withOpacity(0.08),
            blurRadius: job.isFeatured ? 20 : 15,
            offset: const Offset(0, 5),
            spreadRadius: job.isFeatured ? 0 : -2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsPage(job: job),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: job.isFeatured 
                            ? [
                                const Color(0xFFFFD700),
                                const Color(0xFFFF8C00),
                                const Color(0xFFFF6B47),
                              ]
                            : [
                                const Color(0xFF667EEA),
                                const Color(0xFF764BA2),
                                const Color(0xFF6B73FF),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: job.isFeatured 
                              ? const Color(0xFFFFD700).withOpacity(0.4)
                              : const Color(0xFF667EEA).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.business_center_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        if (job.isFeatured)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFD700),
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Almarai',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (job.isFeatured)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFF8C00),
                                      Color(0xFFFF6B47),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isRTL ? '⭐ مميز' : '⭐ Featured',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Almarai',
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF64748B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.business_rounded,
                                color: const Color(0xFF64748B),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                job.companyName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF64748B),
                                  fontFamily: 'Almarai',
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // تفاصيل إضافية
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildModernInfoChip(
                    Icons.location_on_rounded, 
                    job.location, 
                    const [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  _buildModernInfoChip(
                    Icons.schedule_rounded, 
                    job.jobType, 
                    const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                  ),
                  _buildModernInfoChip(
                    Icons.category_rounded, 
                    job.category, 
                    const [Color(0xFF8B5CF6), Color(0xA855F7)],
                  ),
                  if (job.salaryMin != null || job.salaryMax != null)
                    _buildModernInfoChip(
                      Icons.payments_rounded, 
                      job.getSalaryRange(), 
                      const [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // وصف مختصر
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  job.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                    height: 1.5,
                    fontFamily: 'Almarai',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // معلومات إضافية
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.people_rounded,
                        size: 16,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRTL ? '${job.applicationsCount} متقدم' : '${job.applicationsCount} applicants',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Almarai',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTimeAgo(job.publishedAt, isRTL),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Almarai',
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
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Almarai',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoChip(IconData icon, String text, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors[0].withOpacity(0.15),
            gradientColors[1].withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors[0].withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon, 
              size: 14, 
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: gradientColors[0],
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Almarai',
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime publishedAt, bool isRTL) {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    
    if (difference.inDays > 0) {
      return isRTL 
        ? 'منذ ${difference.inDays} يوم'
        : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return isRTL 
        ? 'منذ ${difference.inHours} ساعة'
        : '${difference.inHours} hours ago';
    } else {
      return isRTL 
        ? 'منذ ${difference.inMinutes} دقيقة'
        : '${difference.inMinutes} minutes ago';
    }
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 150,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
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
                      Container(
                        width: 80,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 60,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 70,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                    Color(0xFF6B73FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(70),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.work_off_outlined,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isRTL ? 'لا توجد وظائف' : 'No Jobs Found',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontFamily: 'Almarai',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRTL 
                ? 'لم نجد أي وظائف تطابق معايير البحث الخاصة بك.\nجرب تعديل الفلاتر أو البحث عن شيء آخر.'
                : 'We couldn\'t find any jobs matching your search criteria.\nTry adjusting your filters or search for something else.',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.5,
                fontFamily: 'Almarai',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                    Color(0xFF6B73FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _resetFilters,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded, 
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isRTL ? 'إعادة تعيين الفلاتر' : 'Reset Filters',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Almarai',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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
}

