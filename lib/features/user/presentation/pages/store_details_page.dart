import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/user_data_service.dart';
import '../../services/user_product_service.dart';
import '../../../merchant/models/merchant_model.dart';
import '../../../merchant/models/product_model.dart';

/// صفحة تفاصيل المتجر للمستخدمين
class StoreDetailsPage extends StatefulWidget {
  final MerchantModel merchant;
  
  const StoreDetailsPage({
    super.key,
    required this.merchant,
  });

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> with TickerProviderStateMixin {
  final UserDataService _userDataService = UserDataService.instance;
  late TabController _tabController;
  
  List<ProductModel> _products = [];
  List<ProductModel> _services = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _userCountry = 'السعودية'; // Default country

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
    _tabController = TabController(length: 3, vsync: this);
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProductService = context.read<UserProductService>();
      
      // Load products for user's country first
      await userProductService.loadProductsForCountry(_userCountry);
      
      // Filter products by this merchant
      final allProducts = userProductService.getProductsByMerchant(widget.merchant.id);
      final allServices = userProductService.getServicesByMerchant(widget.merchant.id);
      final availableCategories = userProductService.getAvailableCategories();

      setState(() {
        _products = allProducts;
        _services = allServices;
        _categories = availableCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات المتجر: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              _buildSliverAppBar(),
            ];
          },
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryPurple))
              : _buildTabContent(),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: primaryPurple,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildStoreHeader(),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Text(
              'المنتجات (${_products.length})',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Tab(
            child: Text(
              'الخدمات (${_services.length})',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Tab(
            child: Text(
              'الأقسام (${_categories.length})',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryPurple,
            primaryPurple.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40), // لإفساح المجال للـ AppBar
            
            Row(
              children: [
                // صورة المتجر
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.merchant.profileImageUrl.isNotEmpty
                        ? Image.network(
                            widget.merchant.profileImageUrl,
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
                        widget.merchant.businessName,
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // نوع النشاط
                      Text(
                        MerchantModel.getBusinessTypeName(widget.merchant.businessType, true),
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // التقييم والموقع
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.merchant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(width: 24),
                          
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 20,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.merchant.city,
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // وصف المتجر
            if (widget.merchant.businessDescription.isNotEmpty)
              Text(
                widget.merchant.businessDescription,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProductsTab(),
        _buildServicesTab(),
        _buildCategoriesTab(),
      ],
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return _buildEmptyState('لا توجد منتجات متاحة', Icons.shopping_bag);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildServicesTab() {
    if (_services.isEmpty) {
      return _buildEmptyState('لا توجد خدمات متاحة', Icons.build);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) {
      return _buildEmptyState('لا توجد أقسام متاحة', Icons.category);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final categoryName = _categories[index];
        return _buildCategoryCard(categoryName);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: grayText,
          ),
          const SizedBox(height: 16),
          Text(
            message,
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

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: grayText,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag,
                        size: 40,
                        color: grayText,
                      ),
              ),
            ),
          ),
          
          // معلومات المنتج
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    '${product.discountedPrice.toStringAsFixed(0)} ر.س',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryPurple,
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

  Widget _buildServiceCard(ProductModel service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // أيقونة الخدمة
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.build,
                color: primaryPurple,
                size: 30,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // معلومات الخدمة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  if (service.description.isNotEmpty)
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        color: grayText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Text(
                        '${service.discountedPrice.toStringAsFixed(0)} ر.س',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryPurple,
                        ),
                      ),
                      
                      if (service.description.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Text(
                          'خدمة',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 12,
                            color: grayText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed duplicate _buildCategoryCard method

  Widget _buildDefaultStoreIcon() {
    return Container(
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.store,
        color: primaryPurple,
        size: 40,
      ),
    );
  }

  Widget _buildCategoryCard(String categoryName) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [primaryPurple.withOpacity(0.1), primaryPurple.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category,
              color: primaryPurple,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              categoryName,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
