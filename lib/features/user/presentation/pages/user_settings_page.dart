import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../../merchant/models/country_model.dart';
import '../../services/user_product_service.dart';

class UserSettingsPage extends StatefulWidget {
  const UserSettingsPage({super.key});

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  CountryModel _selectedCountry = CountryData.defaultCountry;

  @override
  void initState() {
    super.initState();
    _loadUserCountry();
  }

  void _loadUserCountry() {
    final userProductService = context.read<UserProductService>();
    final currentCountry = userProductService.userCountry;
    
    final country = CountryData.getCountryByName(currentCountry);
    if (country != null) {
      setState(() {
        _selectedCountry = country;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'الإعدادات',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1D2035),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF1D2035),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSectionTitle('تفضيلات التسوق'),
              const SizedBox(height: 20),
              _buildCountrySelection(),
              const SizedBox(height: 40),
              _buildSectionTitle('حول التطبيق'),
              const SizedBox(height: 20),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Ping AR + LT',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Color(0xFF1D2035),
      ),
    );
  }

  Widget _buildCountrySelection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'اختر دولتك',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيتم عرض المنتجات والخدمات المتاحة في دولتك فقط',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF637D92),
            ),
          ),
          const SizedBox(height: 16),
          _buildCountryDropdown(),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EBEF)),
        borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 12),
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
          if (newValue != null) {
            setState(() {
              _selectedCountry = newValue;
            });
            _updateUserCountry(newValue);
          }
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF9A46D7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9A46D7).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ملاحظة مهمة',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1D2035),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'عند تغيير الدولة، سيتم تحديث قائمة المنتجات والخدمات لتعرض فقط ما هو متاح في الدولة المختارة. قد يستغرق التحديث بضع ثوان.',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF637D92),
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  void _updateUserCountry(CountryModel country) async {
    try {
      final userProductService = context.read<UserProductService>();
      userProductService.setUserCountry(country.nameAr);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث دولتك إلى ${country.nameAr}',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF20C9AC),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ في تحديث الدولة: $e',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFFE32B3D),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
