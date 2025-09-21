import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';

class ProductManagementPage extends StatefulWidget {
  final String merchantId;

  const ProductManagementPage({
    super.key,
    required this.merchantId,
  });

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ProductService _productService = ProductService.instance;
  final CategoryService _categoryService = CategoryService.instance;
  
  List<ProductModel> _products = [];
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
      final products = await _productService.getMerchantProducts(widget.merchantId);
      final categories = await _categoryService.getMerchantCategories(widget.merchantId);
      
      setState(() {
        _products = products;
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
            'إدارة المنتجات',
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
              Tab(text: 'جميع المنتجات'),
              Tab(text: 'إضافة منتج'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.wifi, color: Colors.orange),
              onPressed: _testConnection,
              tooltip: 'اختبار الاتصال',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _loadData,
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsList(),
            _buildAddProductForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Column(
      children: [
        // شريط البحث والفلاتر
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              // شريط البحث
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'البحث في المنتجات...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // فلتر الفئات
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
        
        // قائمة المنتجات
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildFilteredProductsList(),
        ),
      ],
    );
  }

  Widget _buildFilteredProductsList() {
    List<ProductModel> filteredProducts = _products.where((product) {
      bool matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesCategory = _selectedCategory == null ||
          product.category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty && _selectedCategory == null
                  ? 'لا توجد منتجات بعد'
                  : 'لا توجد منتجات تطابق البحث',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على تبويب "إضافة منتج" لإضافة منتجك الأول',
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
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
    );
  }

  Widget _buildProductCard(ProductModel product) {
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
          // صورة المنتج
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
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
                        Icons.image,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          
          // تفاصيل المنتج
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(product.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // السعر والمخزون
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
                        '${product.discountedPrice.toStringAsFixed(0)} ر.س',
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
                        color: product.quantity > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'المخزون: ${product.quantity}',
                        style: TextStyle(
                          color: product.quantity > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // أزرار الإجراءات
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editProduct(product),
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
                        onPressed: () => _toggleProductStatus(product),
                        icon: Icon(
                          product.status == ProductStatus.active
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(
                          product.status == ProductStatus.active
                              ? 'إيقاف'
                              : 'تفعيل',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: product.status == ProductStatus.active
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

  Widget _buildStatusBadge(ProductStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case ProductStatus.active:
        color = Colors.green;
        text = 'نشط';
        break;
      case ProductStatus.inactive:
        color = Colors.grey;
        text = 'غير نشط';
        break;
      case ProductStatus.outOfStock:
        color = Colors.red;
        text = 'نفد المخزون';
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

  Widget _buildAddProductForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AddProductForm(
        merchantId: widget.merchantId,
        categories: _categories,
        onProductAdded: () {
          _loadData();
          _tabController.animateTo(0);
        },
      ),
    );
  }

  void _editProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(
          product: product,
          categories: _categories,
          onProductUpdated: _loadData,
        ),
      ),
    );
  }

  void _toggleProductStatus(ProductModel product) async {
    final newStatus = product.status == ProductStatus.active
        ? ProductStatus.inactive
        : ProductStatus.active;
    
    final success = await _productService.updateProductStatus(product.id, newStatus);
    
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == ProductStatus.active
                ? 'تم تفعيل المنتج بنجاح'
                : 'تم إيقاف المنتج بنجاح',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorSnackBar('فشل في تحديث حالة المنتج');
    }
  }

  Future<void> _testConnection() async {
    print('🔌 بدء اختبار الاتصال...');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري اختبار الاتصال بـ Firebase...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    final isConnected = await _productService.testFirebaseConnection();
    
    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ الاتصال بـ Firebase يعمل بشكل طبيعي'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ فشل الاتصال بـ Firebase'),
          backgroundColor: Colors.red,
        ),
      );
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

// نموذج إضافة منتج
class AddProductForm extends StatefulWidget {
  final String merchantId;
  final List<CategoryModel> categories;
  final VoidCallback onProductAdded;

  const AddProductForm({
    super.key,
    required this.merchantId,
    required this.categories,
    required this.onProductAdded,
  });

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService.instance;
  
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _tagsController = TextEditingController();
  
  String? _selectedCategory;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isFeatured = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصور
          _buildImageSection(),
          const SizedBox(height: 24),
          
          // المعلومات الأساسية
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          
          // التسعير والمخزون
          _buildPricingSection(),
          const SizedBox(height: 24),
          
          // إعدادات إضافية
          _buildAdditionalSettings(),
          const SizedBox(height: 32),
          
          // أزرار الحفظ والاختبار
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
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
                          'إضافة المنتج',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _testSimpleSave,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'اختبار',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
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
            'صور المنتج',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // معاينة الصور المختارة
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
          
          // زر إضافة صور
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
          
          // اسم المنتج
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'اسم المنتج *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال اسم المنتج';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // الوصف
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'وصف المنتج *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال وصف المنتج';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // الفئة
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
          
          // الكلمات المفتاحية
          TextFormField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'الكلمات المفتاحية (مفصولة بفواصل)',
              hintText: 'مثال: إلكترونيات, هواتف, أندرويد',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
            'التسعير والمخزون',
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
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _stockController,
            decoration: InputDecoration(
              labelText: 'كمية المخزون *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كمية المخزون';
              }
              if (int.tryParse(value) == null) {
                return 'يرجى إدخال رقم صحيح';
              }
              return null;
            },
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
            title: const Text('منتج مميز'),
            subtitle: const Text('سيظهر في قسم المنتجات المميزة'),
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

  Future<void> _saveProduct() async {
    print('🚀 بدء عملية حفظ المنتج...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ فشل في التحقق من صحة النموذج');
      return;
    }
    
    if (_selectedImages.isEmpty) {
      print('❌ لا توجد صور مختارة');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إضافة صورة واحدة على الأقل للمنتج'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ التحقق من البيانات مكتمل');
    print('📸 عدد الصور المختارة: ${_selectedImages.length}');
    print('🏪 معرف التاجر: ${widget.merchantId}');

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      print('🏷️ الكلمات المفتاحية: $tags');

      final product = ProductModel(
        id: '',
        merchantId: widget.merchantId,
        name: _nameController.text,
        description: _descriptionController.text,
        images: [],
        originalPrice: double.parse(_priceController.text),
        discountedPrice: _discountPriceController.text.isNotEmpty
            ? double.parse(_discountPriceController.text)
            : double.parse(_priceController.text),
        color: '',
        size: '',
        quantity: int.parse(_stockController.text),
        type: ProductType.product,
        status: ProductStatus.active,
        category: _selectedCategory!,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📦 بيانات المنتج المُنشأ:');
      print('   الاسم: ${product.name}');
      print('   الوصف: ${product.description}');
      print('   الفئة: ${product.category}');
      print('   السعر: ${product.originalPrice}');
      print('   المخزون: ${product.quantity}');
      print('   النوع: ${product.type}');

      print('🔥 استدعاء خدمة إضافة المنتج...');
      final productId = await _productService.addProduct(product, _selectedImages);
      print('🔥 نتيجة الخدمة: $productId');

      if (productId != null) {
        print('✅ تم إضافة المنتج بنجاح! معرف المنتج: $productId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المنتج بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        
        _clearForm();
        widget.onProductAdded();
      } else {
        print('❌ فشل في إضافة المنتج - productId = null');
        throw Exception('فشل في إضافة المنتج');
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في حفظ المنتج: $e');
      print('❌ Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إضافة المنتج: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSimpleSave() async {
    print('🧪 بدء الاختبار البسيط بدون صور...');
    
    setState(() => _isLoading = true);

    try {
      // إنشاء منتج اختبار بسيط بدون صور
      final testProduct = ProductModel(
        id: '',
        merchantId: widget.merchantId,
        name: 'منتج اختبار ${DateTime.now().millisecondsSinceEpoch}',
        description: 'وصف منتج اختبار',
        images: [], // بدون صور
        originalPrice: 10.0,
        discountedPrice: 10.0,
        color: '',
        size: '',
        quantity: 1,
        type: ProductType.product,
        status: ProductStatus.active,
        category: 'اختبار',
        tags: ['اختبار'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('🧪 محاولة حفظ منتج اختبار بدون صور...');
      final productId = await _productService.addProduct(testProduct, []); // بدون صور

      if (productId != null) {
        print('✅ نجح الاختبار! معرف المنتج: $productId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ نجح الاختبار! تم إنشاء منتج برقم: $productId'),
            backgroundColor: Colors.green,
          ),
        );
        
        // حذف المنتج التجريبي
        await _productService.deleteProduct(productId);
        print('🗑️ تم حذف المنتج التجريبي');
        
      } else {
        print('❌ فشل الاختبار البسيط');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل الاختبار البسيط'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في الاختبار البسيط: $e');
      print('❌ Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ في الاختبار: $e'),
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
    _stockController.clear();
    _tagsController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedImages.clear();
      _isFeatured = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}

// صفحة تعديل المنتج (مبسطة)
class EditProductPage extends StatelessWidget {
  final ProductModel product;
  final List<CategoryModel> categories;
  final VoidCallback onProductUpdated;

  const EditProductPage({
    super.key,
    required this.product,
    required this.categories,
    required this.onProductUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تعديل المنتج'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'صفحة تعديل المنتج\n(قيد التطوير)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
