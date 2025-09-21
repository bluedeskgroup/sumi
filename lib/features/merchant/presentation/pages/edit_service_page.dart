import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:io';

import '../../models/product_model.dart';
import '../../services/merchant_product_service.dart';

class EditServicePage extends StatefulWidget {
  final ProductModel service;

  const EditServicePage({
    super.key,
    required this.service,
  });

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedProvider;
  String? _selectedCategory;
  String? _allowCoupons;
  
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  final List<String> _providers = [
    'الشركة الرئيسية',
    'مقدم خدمة مستقل',
    'شراكة خارجية',
    'فريق داخلي',
    'أخرى',
  ];

  final List<String> _categories = [
    'خدمات تقنية',
    'خدمات منزلية',
    'خدمات تعليمية',
    'خدمات صحية',
    'خدمات مالية',
    'خدمات استشارية',
    'أخرى',
  ];

  final List<String> _couponOptions = [
    'مسموح',
    'غير مسموح',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController.text = widget.service.name;
    _priceController.text = widget.service.originalPrice.toString();
    _descriptionController.text = widget.service.description;
    
    // Check if category exists in the list, otherwise set to null
    _selectedCategory = widget.service.category.isNotEmpty && _categories.contains(widget.service.category) 
        ? widget.service.category 
        : null;
    
    // Check if provider exists in the list, otherwise set to null
    final serviceProvider = widget.service.tags.isNotEmpty ? widget.service.tags.first : '';
    _selectedProvider = _providers.contains(serviceProvider) ? serviceProvider : null;
    
    _allowCoupons = _couponOptions.first; // Default to allowed
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.take(4).map((xFile) => File(xFile.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في اختيار الصور'),
          backgroundColor: Color(0xFFE32B3D),
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الخدمة'),
          backgroundColor: Color(0xFFE32B3D),
        ),
      );
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال سعر الخدمة'),
          backgroundColor: Color(0xFFE32B3D),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double price = double.parse(_priceController.text.trim());
      
      // Create updated service
      final updatedService = ProductModel(
        id: widget.service.id,
        merchantId: widget.service.merchantId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        images: widget.service.images, // Keep existing images for now
        originalPrice: price,
        discountedPrice: price, // Same as original for now
        color: widget.service.color,
        size: widget.service.size,
        quantity: widget.service.quantity,
        type: widget.service.type,
        status: widget.service.status,
        category: _selectedCategory ?? widget.service.category,
        tags: _selectedProvider != null ? [_selectedProvider!] : widget.service.tags,
        createdAt: widget.service.createdAt,
        updatedAt: DateTime.now(),
        salesRate: widget.service.salesRate,
        soldCount: widget.service.soldCount,
      );

      final productService = context.read<MerchantProductService>();
      final success = await productService.updateProduct(updatedService);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الخدمة بنجاح'),
            backgroundColor: Color(0xFF20C9AC),
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحديث الخدمة'),
            backgroundColor: Color(0xFFE32B3D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يرجى إدخال سعر صحيح'),
            backgroundColor: Color(0xFFE32B3D),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 24),
                    _buildCurrentServiceImage(),
                    const SizedBox(height: 12),
                    _buildServiceDetailsButton(),
                    const SizedBox(height: 24),
                    _buildBasicDataSection(),
                    const SizedBox(height: 28),
                    _buildAdditionalDataSection(),
                    const SizedBox(height: 28),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 14),
      child: Row(
        children: [
          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'تعديل بيانات الخدمات والمنتجات',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF1D2035),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          
          // Back button
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: const Color(0xFFE7EBEF)),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_forward,
                size: 24,
                color: Color(0xFF323F49),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentServiceImage() {
    return Row(
      children: [
        // Service details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'العنوان الاساسي',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Color(0xFFDAE1E7),
                  letterSpacing: 0.2,
                  height: 1.88,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE7EBEF),
                      const Color(0xFFE7EBEF).withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        
        // Current service image
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6FE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: widget.service.images.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    widget.service.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  ),
                )
              : _buildImagePlaceholder(),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6FE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.design_services_outlined,
        size: 24,
        color: Color(0xFF9A46D7),
      ),
    );
  }

  Widget _buildServiceDetailsButton() {
    return Container(
      width: 144,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6FE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          'تفاصيل الخدمات',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF9A46D7),
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildBasicDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Section title
        const Text(
          'البيانات الأساسية',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 17),
        
        // Service name input
        _buildInputField(
          label: 'العنوان الرئيسي',
          controller: _nameController,
          placeholder: 'يتم كتابة اسم الخدمة المقدمة',
        ),
        const SizedBox(height: 14),
        
        // Price input
        _buildInputField(
          label: 'السعر',
          controller: _priceController,
          placeholder: '500 ريال',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        
        // Description input
        _buildInputField(
          label: 'وصف بسيط',
          controller: _descriptionController,
          placeholder: 'اكتب وصف الخدمة هنا...',
          maxLines: 3,
        ),
        const SizedBox(height: 14),
        
        // Service images section
        _buildImageUploadSection(),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Label
        SizedBox(
          width: double.infinity,
          height: 22,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF1D2035),
              height: 1.39,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(height: 8),
        
        // Input field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF1D2035),
              height: 1.5,
            ),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFFE7EBEF),
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Label
        const SizedBox(
          width: double.infinity,
          height: 27,
          child: Text(
            'صور الخدمة',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1D2035),
              height: 1.39,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(height: 8),
        
        // Image upload cards
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
    final bool hasImage = index < _selectedImages.length;
    final bool isLastCard = index == 3 && widget.service.images.isNotEmpty;
    
    return Container(
      width: 90,
      height: 100,
      margin: const EdgeInsets.only(left: 7),
      child: Column(
        children: [
          // Image area
          Expanded(
            child: GestureDetector(
              onTap: _pickImages,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: hasImage || isLastCard ? const Color(0xFFEBEAED) : const Color(0xFFB6B4BA),
                    style: hasImage || isLastCard ? BorderStyle.solid : BorderStyle.values[1], // dashed
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                        ),
                      )
                    : isLastCard
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    widget.service.images.first,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0x1A5542F6),
                                          Color(0xFF9A46D7),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 20,
                                color: Color(0xFF9A46D7),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'تحميل',
                                style: TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Color(0xFF9A46D7),
                                  height: 1.5,
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

  Widget _buildAdditionalDataSection() {
    return Column(
      children: [
        // Separator line
        Container(
          height: 1,
          color: const Color(0xFFE7EBEF),
        ),
        const SizedBox(height: 28),
        
        // Provider selection
        _buildDropdownField(
          label: 'اختيار مقدم الخدمة',
          value: _selectedProvider,
          placeholder: 'حدد مقدم الخدمة',
          items: _providers,
          onChanged: (value) => setState(() => _selectedProvider = value),
        ),
        const SizedBox(height: 14),
        
        // Category selection
        _buildDropdownField(
          label: 'التصنيف',
          value: _selectedCategory,
          placeholder: 'اختر فئة الخدمة',
          items: _categories,
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
        const SizedBox(height: 14),
        
        // Coupons selection
        _buildDropdownField(
          label: 'متاح استخدام كوبونات الخصم',
          value: _allowCoupons,
          placeholder: 'تحديد السماح او منع الاستخدام',
          items: _couponOptions,
          onChanged: (value) => setState(() => _allowCoupons = value),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String placeholder,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Label
        SizedBox(
          width: double.infinity,
          height: 27,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1D2035),
              height: 1.39,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(height: 8),
        
        // Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            hint: Text(
              placeholder,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF1D2035),
                height: 1.5,
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF4A5E6D),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF1D2035),
                    height: 1.5,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel button
        Expanded(
          flex: 2,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFAAB9C5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'الغاء',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFFAAB9C5),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        
        // Save button
        Expanded(
          flex: 5,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF9A46D7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 84,
                ),
              ],
            ),
            child: TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'التالى',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
