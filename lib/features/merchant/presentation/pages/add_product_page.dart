import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../models/product_model.dart';
import '../../models/country_model.dart';
import '../../services/merchant_product_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  ProductType _selectedType = ProductType.product;
  String _selectedCategory = '';
  CountryModel _selectedCountry = CountryData.defaultCountry;
  bool _allowCoupons = false;
  List<File> _selectedImages = [];
  File? _mainImage;
  
  final ImagePicker _picker = ImagePicker();
  
  int _currentTabIndex = 0; // 0: البيانات الأساسية, 1: تفاصيل المنتجات
  
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _mainImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickProductImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          // Ensure the list has enough space
          while (_selectedImages.length <= index) {
            _selectedImages.add(File(''));
          }
          _selectedImages[index] = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _saveProduct() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final productService = context.read<MerchantProductService>();
    
    List<String> imageUrls = [];
    // In a real app, you would upload images to Firebase Storage here
    // For now, we'll use placeholder URLs
    if (_mainImage != null) {
      imageUrls.add('assets/images/products_page/product_sample_1.png');
    }
    
    final product = ProductModel(
      id: '',
      merchantId: 'merchant_sample_123',
      name: _nameController.text,
      description: _descriptionController.text,
      images: imageUrls.isNotEmpty ? imageUrls : ['assets/images/products_page/product_sample_1.png'],
      originalPrice: double.tryParse(_priceController.text) ?? 0.0,
      discountedPrice: double.tryParse(_priceController.text) ?? 0.0,
      color: '',
      size: '',
      quantity: 10,
      type: _selectedType,
      status: ProductStatus.active,
      category: _selectedCategory.isNotEmpty ? _selectedCategory : 'عام',
      tags: [],
      country: _selectedCountry.nameAr,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      salesRate: 0.0,
      soldCount: 0,
    );

    final success = await productService.addProduct(product);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المنتج بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في إضافة المنتج'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMainImageUpload(),
                      _buildDivider(),
                      _buildTabs(),
                      _buildTabContent(),
                      const SizedBox(height: 20),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE7EBEF)),
              borderRadius: BorderRadius.circular(60),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF323F49),
                size: 20,
              ),
            ),
          ),
          const Text(
            'اضافة منتج أو خدمة',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(width: 55), // Spacer
        ],
      ),
    );
  }

  Widget _buildMainImageUpload() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'العنوان الاساسي',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Color(0xFFDAE1E7),
            ),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            onTap: _pickMainImage,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6FE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: _mainImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        _mainImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFF9A46D7),
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      height: 1,
      color: const Color(0xFFF8F8F8),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          _buildTab('البيانات الأساسية', 0),
          _buildTab('تفاصيل المنتجات', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isActive = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isActive ? const Color(0xFF9A46D7) : const Color(0xFFAAB9C5),
              ),
            ),
          ),
          Container(
            width: index == 0 ? 190 : 192,
            height: 1,
            color: isActive ? const Color(0xFF9A46D7) : const Color(0xFFE7EBEF),
            margin: const EdgeInsets.only(top: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _currentTabIndex == 0 ? _buildBasicDataTab() : _buildProductDetailsTab(),
    );
  }

  Widget _buildBasicDataTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'البيانات الأساسية',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 17),
        _buildInputField(
          'العنوان الرئيسي',
          'يتم كتابة اسم المنتج أو الخدمة',
          _nameController,
        ),
        const SizedBox(height: 14),
        _buildInputField(
          'السعر',
          '500 ريال',
          _priceController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        _buildDescriptionField(),
        const SizedBox(height: 14),
        _buildProductImagesSection(),
      ],
    );
  }

  Widget _buildProductDetailsTab() {
    return Column(
      children: [
        Container(
          height: 1,
          color: const Color(0xFFE7EBEF),
          margin: const EdgeInsets.only(bottom: 28),
        ),
        _buildDropdownField(
          'نوع العنصر',
          'اختر نوع العنصر',
          _selectedType == ProductType.product ? 'منتج' : 'خدمة',
          ['منتج', 'خدمة'],
          (value) {
            setState(() {
              _selectedType = value == 'منتج' ? ProductType.product : ProductType.service;
            });
          },
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          'التصنيف',
          'اختر الفئة',
          _selectedCategory,
          ['إلكترونيات', 'أزياء', 'منزل', 'رياضة', 'كتب', 'صحة وجمال', 'خدمات تقنية', 'استشارات'],
          (value) {
            setState(() {
              _selectedCategory = value ?? '';
            });
          },
        ),
        const SizedBox(height: 14),
        _buildCountryDropdownField(),
        const SizedBox(height: 14),
        _buildDropdownField(
          'متاح استخدام كوبونات الخصم',
          'تحديد السماح او منع الاستخدام',
          _allowCoupons ? 'نعم' : 'لا',
          ['نعم', 'لا'],
          (value) {
            setState(() {
              _allowCoupons = value == 'نعم';
            });
          },
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String placeholder,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFFE7EBEF),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'وصف بسيط',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 4,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
            decoration: const InputDecoration(
              hintText: 'اكتب وصفك هنا...',
              hintStyle: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFFE7EBEF),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'صور المنتج',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL support
            itemCount: 4,
            itemBuilder: (context, index) => _buildImageUploadCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadCard(int index) {
    final hasImage = index < _selectedImages.length && 
                     _selectedImages[index].path.isNotEmpty;
    
    return Container(
      width: 90,
      height: 100,
      margin: const EdgeInsets.only(left: 5),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickProductImage(index),
            child: Container(
              width: 90,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: hasImage ? const Color(0xFFEBEAED) : const Color(0xFFB6B4BA),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Stack(
                        children: [
                          Image.file(
                            _selectedImages[index],
                            width: 90,
                            height: 88,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9A46D7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF9A46D7),
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'تحميل',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Color(0xFF9A46D7),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'الدولة المستهدفة',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF504F54),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<CountryModel>(
            value: _selectedCountry,
            decoration: const InputDecoration(
              hintText: 'اختر الدولة',
              hintStyle: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                color: Color(0xFFB6B4BA),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              color: Color(0xFF1D2035),
            ),
            dropdownColor: Colors.white,
            isExpanded: true,
            items: CountryData.arabCountries.map((CountryModel country) {
              return DropdownMenuItem<CountryModel>(
                value: country,
                child: Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Row(
                    children: [
                      Text(
                        country.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          country.nameAr,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 14,
                            color: Color(0xFF1D2035),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (CountryModel? newValue) {
              setState(() {
                _selectedCountry = newValue ?? CountryData.defaultCountry;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String placeholder,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: value.isEmpty ? null : value,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF1D2035),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF1D2035),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF4A5E6D),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 102,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFAAB9C5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: _currentTabIndex == 0 
                  ? () => Navigator.pop(context)
                  : () {
                      setState(() {
                        _currentTabIndex = 0;
                      });
                    },
              child: Text(
                _currentTabIndex == 0 ? 'الغاء' : 'السابق',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFFAAB9C5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF9A46D7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: _currentTabIndex == 0 ? _nextTab : _saveProduct,
                child: Text(
                  _currentTabIndex == 0 
                      ? 'التالى' 
                      : (_selectedType == ProductType.product ? 'حفظ المنتج' : 'حفظ الخدمة'),
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextTab() {
    if (_currentTabIndex == 0) {
      // التحقق من ملء البيانات الأساسية قبل الانتقال
      if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى ملء البيانات الأساسية أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      setState(() {
        _currentTabIndex = 1;
      });
    }
  }
}
