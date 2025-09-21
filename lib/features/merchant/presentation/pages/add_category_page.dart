import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../../models/category_unified_model.dart';
import '../../models/country_model.dart';
import '../../services/category_unified_service.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _nameController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  CategoryType _selectedType = CategoryType.product;
  CountryModel _selectedCountry = CountryData.defaultCountry;
  bool _isFeatured = false;
  String _selectedColor = '#9A46D7';
  File? _selectedImage;
  File? _selectedIcon;
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _colorOptions = [
    '#9A46D7', '#2196F3', '#4CAF50', '#FF9800', 
    '#E91E63', '#9C27B0', '#795548', '#607D8B',
    '#F44336', '#CDDC39', '#00BCD4', '#FF5722'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool isIcon = false}) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isIcon) {
            _selectedIcon = File(image.path);
          } else {
            _selectedImage = File(image.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم القسم'),
          backgroundColor: Color(0xFFE32B3D),
        ),
      );
      return;
    }

    final categoryService = context.read<CategoryUnifiedService>();
    
    final category = CategoryUnifiedModel(
      id: '', // Will be set by Firestore
      merchantId: 'merchant_sample_123', // Should be dynamic in real app
      name: _nameController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      description: _descriptionController.text.trim(),
      iconUrl: _selectedIcon?.path ?? '',
      imageUrl: _selectedImage?.path ?? '',
      type: _selectedType,
      status: CategoryStatus.active,
      country: _selectedCountry.nameAr,
      sortOrder: 0,
      tags: _tags,
      isFeatured: _isFeatured,
      color: _selectedColor,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await categoryService.addCategory(category);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة القسم بنجاح'),
          backgroundColor: Color(0xFF20C9AC),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في إضافة القسم'),
          backgroundColor: Color(0xFFE32B3D),
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
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildForm(),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9A46D7), Color(0xFF7B1FA2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'إضافة قسم جديد',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildImageSection(),
        const SizedBox(height: 24),
        _buildBasicInfoSection(),
        const SizedBox(height: 24),
        _buildTypeAndCountrySection(),
        const SizedBox(height: 24),
        _buildColorSection(),
        const SizedBox(height: 24),
        _buildTagsSection(),
        const SizedBox(height: 24),
        _buildFeaturedSection(),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'صور القسم',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Main image
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(isIcon: false),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE7EBEF)),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 32,
                                    color: Color(0xFFB6B4BA),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'صورة القسم',
                                    style: TextStyle(
                                      fontFamily: 'Ping AR + LT',
                                      fontSize: 12,
                                      color: Color(0xFFB6B4BA),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Icon
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(isIcon: true),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE7EBEF)),
                        ),
                        child: _selectedIcon != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedIcon!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.apps,
                                    size: 32,
                                    color: Color(0xFFB6B4BA),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'أيقونة القسم',
                                    style: TextStyle(
                                      fontFamily: 'Ping AR + LT',
                                      fontSize: 12,
                                      color: Color(0xFFB6B4BA),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildInputField(
          'اسم القسم',
          'اكتب اسم القسم بالعربية',
          _nameController,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          'اسم القسم بالإنجليزية',
          'اكتب اسم القسم بالإنجليزية (اختياري)',
          _nameEnController,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          'وصف القسم',
          'اكتب وصفاً مختصراً للقسم',
          _descriptionController,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTypeAndCountrySection() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeDropdown(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCountryDropdown(),
        ),
      ],
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'نوع القسم',
          style: TextStyle(
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
          child: DropdownButtonFormField<CategoryType>(
            value: _selectedType,
            decoration: const InputDecoration(
              hintText: 'اختر النوع',
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
            items: [
              DropdownMenuItem(
                value: CategoryType.product,
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: Color(0xFF9A46D7), size: 20),
                    const SizedBox(width: 8),
                    const Text('منتجات'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: CategoryType.service,
                child: Row(
                  children: [
                    Icon(Icons.build, color: Color(0xFF9A46D7), size: 20),
                    const SizedBox(width: 8),
                    const Text('خدمات'),
                  ],
                ),
              ),
            ],
            onChanged: (CategoryType? newValue) {
              setState(() {
                _selectedType = newValue ?? CategoryType.product;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'الدولة المستهدفة',
          style: TextStyle(
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
                child: Row(
                  children: [
                    Text(country.flag, style: const TextStyle(fontSize: 16)),
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

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'لون القسم',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Color(0xFF504F54),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected 
                      ? Border.all(color: const Color(0xFF1D2035), width: 3)
                      : null,
                  boxShadow: isSelected 
                      ? [BoxShadow(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'الكلمات المفتاحية',
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE7EBEF)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'أضف كلمة مفتاحية',
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
                  onSubmitted: (_) => _addTag(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addTag,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF9A46D7).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        color: Color(0xFF9A46D7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturedSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EBEF)),
      ),
      child: Row(
        children: [
          Switch(
            value: _isFeatured,
            onChanged: (value) {
              setState(() {
                _isFeatured = value;
              });
            },
            activeColor: const Color(0xFF9A46D7),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'قسم مميز',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1D2035),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'سيظهر هذا القسم في القائمة المميزة للمستخدمين',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    color: Color(0xFF637D92),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (required)
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF504F54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EBEF)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                color: Color(0xFFB6B4BA),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              color: Color(0xFF1D2035),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'إلغاء',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF637D92),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _saveCategory,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9A46D7), Color(0xFF7B1FA2)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9A46D7).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'حفظ القسم',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
