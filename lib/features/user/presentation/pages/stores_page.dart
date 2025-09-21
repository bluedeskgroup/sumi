import 'package:flutter/material.dart';
import '../../services/user_data_service.dart';
import '../../../merchant/models/merchant_model.dart';
import 'store_details_page.dart';

/// صفحة عرض المتاجر للمستخدمين
class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  final UserDataService _userDataService = UserDataService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<MerchantModel> _merchants = [];
  List<MerchantModel> _filteredMerchants = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // ألوان التطبيق
  static const Color primaryPurple = Color(0xFF9A46D7);
  static const Color primaryText = Color(0xFF1D2035);
  static const Color secondaryText = Color(0xFF4A5E6D);
  static const Color grayText = Color(0xFF92A5B5);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color whiteColor = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMerchants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final merchants = await _userDataService.getApprovedMerchants();
      setState(() {
        _merchants = merchants;
        _filteredMerchants = merchants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل المتاجر: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterMerchants(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredMerchants = _merchants;
      } else {
        _filteredMerchants = _merchants.where((merchant) {
          return merchant.businessName.toLowerCase().contains(query.toLowerCase()) ||
                 merchant.businessType.toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'المتاجر',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // شريط البحث
            _buildSearchBar(),
            
            // قائمة المتاجر
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryPurple))
                  : _buildMerchantsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: whiteColor,
      child: TextField(
        controller: _searchController,
        onChanged: _filterMerchants,
        style: const TextStyle(
          fontFamily: 'Ping AR + LT',
          fontSize: 16,
          color: primaryText,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن المتاجر...',
          hintStyle: const TextStyle(
            fontFamily: 'Ping AR + LT',
            color: grayText,
          ),
          prefixIcon: const Icon(Icons.search, color: grayText),
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
            borderSide: const BorderSide(color: primaryPurple, width: 2),
          ),
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMerchantsList() {
    if (_filteredMerchants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.store : Icons.search_off,
              size: 64,
              color: grayText,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'لا توجد متاجر متاحة حالياً'
                  : 'لا توجد نتائج للبحث "$_searchQuery"',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                color: grayText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMerchants,
      color: primaryPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredMerchants.length,
        itemBuilder: (context, index) {
          final merchant = _filteredMerchants[index];
          return _buildMerchantCard(merchant);
        },
      ),
    );
  }

  Widget _buildMerchantCard(MerchantModel merchant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoreDetailsPage(merchant: merchant),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // صورة المتجر
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: backgroundColor,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: merchant.profileImageUrl.isNotEmpty
                      ? Image.network(
                          merchant.profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultStoreIcon(),
                        )
                      : _buildDefaultStoreIcon(),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // معلومات المتجر
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المتجر
                    Text(
                      merchant.businessName,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // نوع النشاط
                    Text(
                      MerchantModel.getBusinessTypeName(merchant.businessType, true),
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryText,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // المدينة والتقييم
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: grayText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          merchant.city,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 12,
                            color: grayText,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // التقييم
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              merchant.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // أيقونة المفضلة
              IconButton(
                onPressed: () => _toggleFavorite(merchant),
                icon: Icon(
                  Icons.favorite_border, // سيتم تحديثها لاحقاً للتحقق من الحالة
                  color: grayText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultStoreIcon() {
    return Container(
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.store,
        color: primaryPurple,
        size: 40,
      ),
    );
  }

  void _toggleFavorite(MerchantModel merchant) async {
    try {
      // يمكن إضافة منطق المفضلة هنا لاحقاً
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة ${merchant.businessName} للمفضلة'),
          backgroundColor: primaryPurple,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إضافة المفضلة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
