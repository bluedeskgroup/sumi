import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/merchant_model.dart';
import '../../services/merchant_completion_service.dart';

/// صفحة إدارة بيانات المتجر الشاملة
class MerchantStoreManagementPage extends StatefulWidget {
  final MerchantModel merchant;
  
  const MerchantStoreManagementPage({
    super.key,
    required this.merchant,
  });

  @override
  State<MerchantStoreManagementPage> createState() => _MerchantStoreManagementPageState();
}

class _MerchantStoreManagementPageState extends State<MerchantStoreManagementPage> {
  final MerchantCompletionService _completionService = MerchantCompletionService.instance;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.merchant.businessName);
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController(text: widget.merchant.phoneNumber);
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('إدارة المتجر'),
        backgroundColor: const Color(0xFF9A46D7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات أساسية
            _buildSectionCard(
              'المعلومات الأساسية',
              [
                _buildTextField(
                  controller: _businessNameController,
                  label: 'اسم المتجر',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال اسم المتجر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'وصف المتجر',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال وصف المتجر';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // معلومات الاتصال
            _buildSectionCard(
              'معلومات الاتصال',
              [
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  keyboardType: TextInputType.phone,
                  enabled: false, // لا يمكن تعديل رقم الهاتف
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'العنوان',
                  maxLines: 2,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // زر الحفظ
            ElevatedButton(
              onPressed: _saveStoreInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A46D7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'حفظ التغييرات',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      style: TextStyle(
        fontFamily: 'Ping AR + LT',
        fontSize: 16,
        color: enabled ? const Color(0xFF1D2035) : Colors.grey,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Ping AR + LT',
          color: Color(0xFF626C83),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E6EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E6EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF9A46D7), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Future<void> _saveStoreInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _completionService.updateStoreInfo(
        merchantId: widget.merchant.id,
        businessName: _businessNameController.text.trim(),
        description: _descriptionController.text.trim(),
        profileImageUrl: widget.merchant.profileImageUrl,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ معلومات المتجر بنجاح!'),
            backgroundColor: Color(0xFF1ED29C),
          ),
        );
        Navigator.pop(context, true); // إرجاع true للإشارة إلى نجاح العملية
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في حفظ البيانات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
