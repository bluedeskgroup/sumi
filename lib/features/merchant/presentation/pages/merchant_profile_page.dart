import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/merchant_model.dart';
import '../../services/merchant_service.dart';

class MerchantProfilePage extends StatefulWidget {
  final MerchantModel merchant;

  const MerchantProfilePage({
    super.key,
    required this.merchant,
  });

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final MerchantService _merchantService = MerchantService.instance;

  // Controllers
  late TextEditingController _fullNameController;
  late TextEditingController _businessNameController;
  late TextEditingController _businessDescriptionController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _businessAddressController;
  late TextEditingController _cityController;

  File? _profileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(text: widget.merchant.fullName);
    _businessNameController = TextEditingController(text: widget.merchant.businessName);
    _businessDescriptionController = TextEditingController(text: widget.merchant.businessDescription);
    _phoneNumberController = TextEditingController(text: widget.merchant.phoneNumber);
    _emailController = TextEditingController(text: widget.merchant.email);
    _businessAddressController = TextEditingController(text: widget.merchant.businessAddress);
    _cityController = TextEditingController(text: widget.merchant.city);
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
            'إدارة الملف الشخصي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.orange),
              onPressed: _saveProfile,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileImageSection(),
                const SizedBox(height: 24),
                _buildPersonalInfoSection(),
                const SizedBox(height: 24),
                _buildBusinessInfoSection(),
                const SizedBox(height: 24),
                _buildContactInfoSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
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
        children: [
          const Text(
            'الصورة الشخصية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (widget.merchant.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.merchant.profileImageUrl)
                          : null) as ImageProvider?,
                  child: _profileImage == null && widget.merchant.profileImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
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
            'المعلومات الشخصية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _fullNameController,
            decoration: InputDecoration(
              labelText: 'الاسم الكامل',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال الاسم الكامل';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _phoneNumberController,
            decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            enabled: false, // رقم الهاتف لا يمكن تغييره
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال البريد الإلكتروني';
              }
              if (!value.contains('@')) {
                return 'يرجى إدخال بريد إلكتروني صحيح';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
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
            'معلومات النشاط التجاري',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _businessNameController,
            decoration: InputDecoration(
              labelText: 'اسم النشاط التجاري',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال اسم النشاط التجاري';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _businessDescriptionController,
            decoration: InputDecoration(
              labelText: 'وصف النشاط التجاري',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال وصف النشاط التجاري';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection() {
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
            'معلومات الاتصال والموقع',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _businessAddressController,
            decoration: InputDecoration(
              labelText: 'عنوان النشاط التجاري',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.location_on),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال عنوان النشاط التجاري';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: 'المدينة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.location_city),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال المدينة';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
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
                'حفظ التغييرات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: تنفيذ حفظ البيانات في الخدمة
      // هذا مثال مبسط - يجب تنفيذ الخدمة الفعلية
      
      await Future.delayed(const Duration(seconds: 1)); // محاكاة العملية
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ البيانات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في حفظ البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _businessAddressController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
