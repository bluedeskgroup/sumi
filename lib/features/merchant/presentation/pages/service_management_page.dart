import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/service_model.dart';
import '../../models/category_model.dart';
import '../../services/service_service.dart';
import '../../services/category_service.dart';

class ServiceManagementPage extends StatefulWidget {
  final String merchantId;

  const ServiceManagementPage({
    super.key,
    required this.merchantId,
  });

  @override
  State<ServiceManagementPage> createState() => _ServiceManagementPageState();
}

class _ServiceManagementPageState extends State<ServiceManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ServiceService _serviceService = ServiceService.instance;
  final CategoryService _categoryService = CategoryService.instance;
  
  List<ServiceModel> _services = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final services = await _serviceService.getMerchantServices(widget.merchantId);
      final categories = await _categoryService.getMerchantCategories(widget.merchantId);
      
      setState(() {
        _services = services;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('فشل في تحميل البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'إدارة الخدمات',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(text: 'جميع الخدمات'),
              Tab(text: 'إضافة خدمة'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _loadData,
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServicesList(),
            _buildAddServiceForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    return Column(
      children: [
        // شريط البحث والفلاتر
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'البحث في الخدمات...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'الفئة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('جميع الفئات')),
                  ..._categories.map((category) => DropdownMenuItem(
                    value: category.name,
                    child: Text(category.name),
                  )),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildFilteredServicesList(),
        ),
      ],
    );
  }

  Widget _buildFilteredServicesList() {
    List<ServiceModel> filteredServices = _services.where((service) {
      bool matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesCategory = _selectedCategory == null ||
          service.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.miscellaneous_services_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _selectedCategory == null
                  ? 'لا توجد خدمات بعد'
                  : 'لا توجد خدمات تطابق البحث',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على تبويب "إضافة خدمة" لإضافة خدمتك الأولى',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) => _buildServiceCard(filteredServices[index]),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // صورة الخدمة
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: service.imageUrls.isNotEmpty
                  ? Image.network(
                      service.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.miscellaneous_services,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          
          // تفاصيل الخدمة
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildServiceStatusBadge(service.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  service.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // السعر والمدة
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${service.displayPrice.toStringAsFixed(0)} ر.س',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.formattedDuration,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // نوع الخدمة ومكان التقديم
                Row(
                  children: [
                    _buildServiceTypeBadge(service.type),
                    const SizedBox(width: 8),
                    if (service.isOnline)
                      _buildInfoBadge('أونلاين', Colors.green),
                    if (service.isAtLocation)
                      _buildInfoBadge('في الموقع', Colors.purple),
                  ],
                ),
                const SizedBox(height: 16),
                
                // أزرار الإجراءات
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editService(service),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('تعديل'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleServiceStatus(service),
                        icon: Icon(
                          service.status == ServiceStatus.active
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(
                          service.status == ServiceStatus.active
                              ? 'إيقاف'
                              : 'تفعيل',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: service.status == ServiceStatus.active
                              ? Colors.orange
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatusBadge(ServiceStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case ServiceStatus.active:
        color = Colors.green;
        text = 'نشط';
        break;
      case ServiceStatus.inactive:
        color = Colors.grey;
        text = 'غير نشط';
        break;
      case ServiceStatus.suspended:
        color = Colors.red;
        text = 'معلق';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildServiceTypeBadge(ServiceType type) {
    String text;
    Color color = Colors.blue;
    
    switch (type) {
      case ServiceType.oneTime:
        text = 'لمرة واحدة';
        break;
      case ServiceType.recurring:
        text = 'متكررة';
        color = Colors.purple;
        break;
      case ServiceType.appointment:
        text = 'بموعد';
        color = Colors.orange;
        break;
      case ServiceType.consultation:
        text = 'استشارة';
        color = Colors.teal;
        break;
    }
    
    return _buildInfoBadge(text, color);
  }

  Widget _buildInfoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAddServiceForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AddServiceForm(
        merchantId: widget.merchantId,
        categories: _categories,
        onServiceAdded: () {
          _loadData();
          _tabController.animateTo(0);
        },
      ),
    );
  }

  void _editService(ServiceModel service) {
    // TODO: تنفيذ صفحة تعديل الخدمة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('صفحة تعديل الخدمة قيد التطوير'),
      ),
    );
  }

  void _toggleServiceStatus(ServiceModel service) async {
    final newStatus = service.status == ServiceStatus.active
        ? ServiceStatus.inactive
        : ServiceStatus.active;
    
    final success = await _serviceService.updateServiceStatus(service.id, newStatus);
    
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == ServiceStatus.active
                ? 'تم تفعيل الخدمة بنجاح'
                : 'تم إيقاف الخدمة بنجاح',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorSnackBar('فشل في تحديث حالة الخدمة');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// نموذج إضافة خدمة
class AddServiceForm extends StatefulWidget {
  final String merchantId;
  final List<CategoryModel> categories;
  final VoidCallback onServiceAdded;

  const AddServiceForm({
    super.key,
    required this.merchantId,
    required this.categories,
    required this.onServiceAdded,
  });

  @override
  State<AddServiceForm> createState() => _AddServiceFormState();
}

class _AddServiceFormState extends State<AddServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final ServiceService _serviceService = ServiceService.instance;
  
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _durationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String? _selectedCategory;
  ServiceType _selectedType = ServiceType.oneTime;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isFeatured = false;
  bool _isOnline = false;
  bool _isAtLocation = true;
  List<String> _selectedDays = [];

  final List<String> _weekDays = [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 
    'الخميس', 'الجمعة', 'السبت'
  ];

  @override
  void initState() {
    super.initState();
    _durationController.text = '60';
    _startTimeController.text = '09:00';
    _endTimeController.text = '17:00';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          const SizedBox(height: 24),
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildServiceDetailsSection(),
          const SizedBox(height: 24),
          _buildPricingSection(),
          const SizedBox(height: 24),
          _buildAvailabilitySection(),
          const SizedBox(height: 24),
          _buildAdditionalSettings(),
          const SizedBox(height: 32),
          
          // زر الحفظ
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveService,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'إضافة الخدمة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
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
          const Text(
            'صور الخدمة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(left: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImages.removeAt(index);
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
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
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('إضافة صور'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
          const Text(
            'المعلومات الأساسية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'اسم الخدمة *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال اسم الخدمة';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'وصف الخدمة *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال وصف الخدمة';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'الفئة *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: widget.categories.map((category) => DropdownMenuItem(
              value: category.name,
              child: Text(category.name),
            )).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى اختيار الفئة';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'الكلمات المفتاحية (مفصولة بفواصل)',
              hintText: 'مثال: استشارة, تصميم, تطوير',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsSection() {
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
          const Text(
            'تفاصيل الخدمة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<ServiceType>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'نوع الخدمة *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(value: ServiceType.oneTime, child: Text('لمرة واحدة')),
              DropdownMenuItem(value: ServiceType.recurring, child: Text('متكررة')),
              DropdownMenuItem(value: ServiceType.appointment, child: Text('بموعد')),
              DropdownMenuItem(value: ServiceType.consultation, child: Text('استشارة')),
            ],
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _durationController,
            decoration: InputDecoration(
              labelText: 'مدة الخدمة (بالدقائق) *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال مدة الخدمة';
              }
              if (int.tryParse(value) == null) {
                return 'يرجى إدخال رقم صحيح';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // طريقة التقديم
          const Text(
            'طريقة تقديم الخدمة:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('أونلاين'),
            value: _isOnline,
            onChanged: (value) => setState(() => _isOnline = value ?? false),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
          CheckboxListTile(
            title: const Text('في الموقع'),
            value: _isAtLocation,
            onChanged: (value) => setState(() => _isAtLocation = value ?? false),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
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
          const Text(
            'التسعير',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'السعر (ر.س) *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال السعر';
                    }
                    if (double.tryParse(value) == null) {
                      return 'يرجى إدخال رقم صحيح';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _discountPriceController,
                  decoration: InputDecoration(
                    labelText: 'سعر الخصم (ر.س)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
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
          const Text(
            'أوقات العمل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _startTimeController,
                  decoration: InputDecoration(
                    labelText: 'وقت البداية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _endTimeController,
                  decoration: InputDecoration(
                    labelText: 'وقت النهاية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text(
            'أيام العمل:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _weekDays.map((day) => FilterChip(
              label: Text(day),
              selected: _selectedDays.contains(day),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day);
                  } else {
                    _selectedDays.remove(day);
                  }
                });
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSettings() {
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
          const Text(
            'إعدادات إضافية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('خدمة مميزة'),
            subtitle: const Text('ستظهر في قسم الخدمات المميزة'),
            value: _isFeatured,
            onChanged: (value) => setState(() => _isFeatured = value ?? false),
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صورة واحدة على الأقل للخدمة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isOnline && !_isAtLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار طريقة واحدة على الأقل لتقديم الخدمة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final service = ServiceModel(
        id: '',
        merchantId: widget.merchantId,
        name: _nameController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        price: double.parse(_priceController.text),
        discountPrice: _discountPriceController.text.isNotEmpty
            ? double.parse(_discountPriceController.text)
            : null,
        type: _selectedType,
        status: ServiceStatus.active,
        imageUrls: [],
        tags: tags,
        durationMinutes: int.parse(_durationController.text),
        isOnline: _isOnline,
        isAtLocation: _isAtLocation,
        availableDays: _selectedDays,
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        requirements: {},
        isFeature: _isFeatured,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final serviceId = await _serviceService.addService(service, _selectedImages);

      if (serviceId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الخدمة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        
        _clearForm();
        widget.onServiceAdded();
      } else {
        throw Exception('فشل في إضافة الخدمة');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إضافة الخدمة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _discountPriceController.clear();
    _durationController.text = '60';
    _startTimeController.text = '09:00';
    _endTimeController.text = '17:00';
    _tagsController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedType = ServiceType.oneTime;
      _selectedImages.clear();
      _isFeatured = false;
      _isOnline = false;
      _isAtLocation = true;
      _selectedDays.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _durationController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
