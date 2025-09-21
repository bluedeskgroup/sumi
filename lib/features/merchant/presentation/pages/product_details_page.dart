import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import '../../services/product_variant_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _currentTabIndex = 1; // Start with "تفاصيل المنتجات" tab
  
  // New variant form data
  final _variantNameController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedColor = '';
  String _selectedSize = '';
  String _selectedBrand = '';
  File? _variantImage;
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _variantNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final variantService = context.read<ProductVariantService>();
    await variantService.loadProductVariants(widget.product.id);
  }

  Future<void> _pickVariantImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _variantImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _addNewVariant() async {
    if (_variantNameController.text.isEmpty || 
        _quantityController.text.isEmpty ||
        _selectedColor.isEmpty ||
        _selectedSize.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final variantService = context.read<ProductVariantService>();
    
    final variant = ProductVariantModel(
      id: '',
      productId: widget.product.id,
      name: _variantNameController.text,
      imageUrl: _variantImage?.path ?? 'assets/images/products_page/product_sample_1.png',
      quantity: int.tryParse(_quantityController.text) ?? 0,
      color: _selectedColor,
      colorHex: ProductColors.getColorHex(_selectedColor),
      size: _selectedSize,
      price: widget.product.discountedPrice,
      isAvailable: true,
      brand: _selectedBrand.isNotEmpty ? _selectedBrand : 'غير محدد',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await variantService.addVariant(variant);
    
    if (success && mounted) {
      // Clear form
      _variantNameController.clear();
      _quantityController.clear();
      setState(() {
        _selectedColor = '';
        _selectedSize = '';
        _selectedBrand = '';
        _variantImage = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة الاختيار بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في إضافة الاختيار'),
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
              _buildMainImageSection(),
              _buildDivider(),
              _buildTabs(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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

  Widget _buildMainImageSection() {
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6FE),
              borderRadius: BorderRadius.circular(4),
            ),
            child: widget.product.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image,
                          color: Color(0xFF9A46D7),
                          size: 24,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xFF9A46D7),
                    size: 24,
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
        const SizedBox(height: 20),
        _buildInfoCard('اسم المنتج', widget.product.name),
        const SizedBox(height: 16),
        _buildInfoCard('السعر', '${widget.product.discountedPrice.toStringAsFixed(0)} ر.س'),
        const SizedBox(height: 16),
        _buildInfoCard('الوصف', widget.product.description),
        const SizedBox(height: 16),
        _buildInfoCard('التصنيف', widget.product.category),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EBEF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF1D2035),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF504F54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختيارات المنتج المتاحة',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 20),
        _buildExistingVariants(),
        const SizedBox(height: 28),
        _buildAddNewVariantSection(),
        const SizedBox(height: 28),
        _buildBrandSelectionSection(),
        const SizedBox(height: 28),
        _buildAddNewVariantButton(),
      ],
    );
  }

  Widget _buildExistingVariants() {
    return Consumer<ProductVariantService>(
      builder: (context, variantService, child) {
        if (variantService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF9A46D7),
            ),
          );
        }

        if (variantService.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              variantService.errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          );
        }

        final variants = variantService.variants;
        
        if (variants.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE7EBEF)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'لم يتم إضافة اختيارات للمنتج بعد',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  color: Color(0xFFAAB9C5),
                ),
              ),
            ),
          );
        }

        return Column(
          children: variants.map((variant) => _buildVariantCard(variant)).toList(),
        );
      },
    );
  }

  Widget _buildVariantCard(ProductVariantModel variant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEBEAED)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image and name
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBD9FB),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Icon(
                  Icons.image,
                  color: Color(0xFF9A46D7),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  variant.name,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF2E2C34),
                  ),
                ),
              ),
              const Text(
                'صورة الاختيار',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF504F54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity field
              _buildVariantField('الكمية', variant.quantity.toString()),
              // Color field with color sample
              _buildColorField('اللون', variant.color, variant.colorHex),
              // Size field
              _buildVariantField('الحجم', variant.size),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF504F54),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: label == 'الكمية' ? 45 : 96,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBEAED)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFB6B4BA),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorField(String label, String colorName, String colorHex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF504F54),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 55,
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBEAED)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 10,
                top: 15,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const Positioned(
                right: 13,
                top: 13,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF84818A),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddNewVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // New variant image and name
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBEAED)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'صورة الاختيار',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF504F54),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickVariantImage,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBD9FB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: _variantImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.file(
                                _variantImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              color: Color(0xFF9A46D7),
                              size: 16,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _variantNameController,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        color: Color(0xFF2E2C34),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'أسم المنتج',
                        hintStyle: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 14,
                          color: Color(0xFF2E2C34),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Action row with Add button and fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add button
                  Container(
                    width: 144,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9A46D7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: _addNewVariant,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'اضافه',
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Quantity field
                  _buildNewVariantInputField('الكمية', '00', _quantityController, width: 45),
                  // Color field
                  _buildNewVariantDropdownField('اللون', _selectedColor, ProductColors.colorNames, (value) {
                    setState(() {
                      _selectedColor = value ?? '';
                    });
                  }, width: 55),
                  // Size field
                  _buildNewVariantDropdownField('الحجم', _selectedSize, 
                      ProductSizes.getSizesForCategory(widget.product.category), (value) {
                    setState(() {
                      _selectedSize = value ?? '';
                    });
                  }, width: 96),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewVariantInputField(String label, String placeholder, TextEditingController controller, {double width = 96}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF504F54),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: width,
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBEAED)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: label == 'الكمية' ? TextInputType.number : TextInputType.text,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              color: Color(0xFF1D2035),
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                color: Color(0xFFB6B4BA),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewVariantDropdownField(String label, String value, List<String> options, Function(String?) onChanged, {double width = 96}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF504F54),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: width,
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEBEAED)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonFormField<String>(
            value: value.isEmpty ? null : value,
            isExpanded: true,
            isDense: true,
            decoration: const InputDecoration(
              hintText: 'اختيار',
              hintStyle: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                color: Color(0xFFB6B4BA),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    color: Color(0xFF1D2035),
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF84818A),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EBEF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختيار ماركة المنتج',
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
            child: DropdownButtonFormField<String>(
              value: _selectedBrand.isEmpty ? null : _selectedBrand,
              decoration: const InputDecoration(
                hintText: 'حدد العلامة التجارية',
                hintStyle: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  color: Color(0xFF1D2035),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              items: const [
                'أديداس',
                'نايكي',
                'بوما',
                'كيركسن',
                'ريبان',
                'أخرى',
              ].map((String brand) {
                return DropdownMenuItem<String>(
                  value: brand,
                  child: Text(
                    brand,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      color: Color(0xFF1D2035),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBrand = value ?? '';
                });
              },
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF4A5E6D),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewVariantButton() {
    return Container(
      width: double.infinity,
      height: 51,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF9A46D7),
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextButton(
        onPressed: () {
          // Scroll to the add variant section
          setState(() {
            _currentTabIndex = 1;
          });
        },
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: Color(0xFF9A46D7),
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'اضافة اختيار جديد',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF9A46D7),
              ),
            ),
          ],
        ),
      ),
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
                onPressed: _currentTabIndex == 0 ? _nextTab : _saveDetails,
                child: Text(
                  _currentTabIndex == 0 ? 'التالى' : 'حفظ التفاصيل',
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
    setState(() {
      _currentTabIndex = 1;
    });
  }

  void _saveDetails() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ تفاصيل المنتج بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
