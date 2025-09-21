import 'package:flutter/material.dart';
import 'package:sumi/features/store/models/product_model.dart';
import 'package:sumi/features/store/services/store_service.dart';
import 'package:sumi/features/auth/services/address_service.dart';
import 'package:sumi/features/auth/models/address_model.dart';
import 'package:sumi/features/auth/presentation/pages/addresses_page.dart';
import 'package:sumi/features/store/presentation/pages/product_details_page.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sumi/features/store/services/cart_service.dart';
import 'package:sumi/features/store/presentation/pages/cart_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final StoreService _storeService = StoreService();
  final AddressService _addressService = AddressService();
  String _selectedCategory = 'الكل';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAddressModal = false;
  bool _hasAddress = false;
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _checkUserAddress();
  }

  Future<void> _checkUserAddress() async {
    if (!mounted) return;
    setState(() {
      _isLoadingAddress = true;
    });
    
    try {
      final addresses = await _addressService.getAddressesOnce();
      if (!mounted) return;
      setState(() {
        _hasAddress = addresses.isNotEmpty;
        _showAddressModal = !_hasAddress;
        _isLoadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasAddress = false;
        _showAddressModal = true;
        _isLoadingAddress = false;
      });
    }
  }

  final List<Map<String, String>> _categories = [
    {'name': 'الكل', 'image': ''},
    {'name': 'جاكت', 'image': 'assets/images/figma/jacket_category.png'},
    {'name': 'حذاء', 'image': 'assets/images/figma/shoes_category.png'},
    {'name': 'شنط', 'image': 'assets/images/figma/bags_category.png'},
    {'name': 'ملابس', 'image': 'assets/images/figma/clothes_category.png'},
    {'name': 'إكسسوارات', 'image': 'assets/images/figma/accessories_category.png'},
    {'name': 'إلكترونيات', 'image': 'assets/images/figma/electronics_category.png'},
  ];

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty && (_selectedCategory == 'الكل' || _selectedCategory == 'All')) {
      return products;
    }
    
    return products.where((product) {
      final matchesSearch = _searchQuery.isEmpty || 
          product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery) ||
          product.searchKeywords.any((keyword) => keyword.toLowerCase().contains(_searchQuery));
      
      final matchesCategory = _selectedCategory == 'الكل' || _selectedCategory == 'All' || 
          product.category.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          _getCategoryMapping(_selectedCategory).toLowerCase() == product.category.toLowerCase();
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  String _getCategoryMapping(String category) {
    final categoryMap = {
      'جواكت': 'jacket',
      'أحذية': 'shoes',
      'شنط': 'bags',
      'ملابس': 'clothes',
      'Jackets': 'jacket',
      'Shoes': 'shoes', 
      'Bags': 'bags',
      'Clothes': 'clothes',
    };
    return categoryMap[category] ?? category;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(isArabic),
                  _buildTopBanner(isArabic),
                  _buildCategorySection(isArabic),
                  _buildFeaturedProducts(isArabic),
                  _buildBestDiscounts(isArabic),
                ],
              ),
            ),
          ),
          
          // Address Modal
          if (_showAddressModal && !_isLoadingAddress)
            _buildAddressModal(context, isArabic),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isArabic) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // أيقونة السلة مع شارة عدد العناصر
          Consumer<CartService>(
            builder: (context, cart, _) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6FE),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_outlined,
                        size: 28,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                    if (cart.itemCount > 0)
                      Positioned(
                        top: -2,
                        right: isArabic ? null : -2,
                        left: isArabic ? -2 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          child: Center(
                            child: Text(
                              cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          
          // شريط البحث (وسط)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(33),
                border: Border.all(color: const Color(0xFFE7EBEF)),
              ),
              child: Row(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D2035),
                      ),
                      decoration: InputDecoration(
                        hintText: isArabic ? 'ابحث عن المنتجات' : 'Search for products',
                        hintStyle: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFCED7DE),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(
                      Icons.search,
                      size: 20,
                      color: const Color(0xFF4A5E6D),
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


  Widget _buildTopBanner(bool isArabic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFAF66E6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // محتوى البانر
          Positioned(
            right: isArabic ? 24 : null,
            left: isArabic ? null : 24,
            top: 23,
            child: Column(
              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'أفضل عروض حجز مقدمه.' : 'Best booking offers in advance.',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic ? 'عنوان فرعي للعرض' : 'Subtitle for the offer',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFC590F0),
                  ),
                ),
              ],
            ),
          ),
          
          // نقاط التنقل
          Positioned(
            bottom: 22,
            right: isArabic ? 24 : null,
            left: isArabic ? null : 24,
            child: Row(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (index) {
                return Container(
                  width: 4,
                  height: 4,
                  margin: EdgeInsets.only(
                    left: isArabic ? 0 : 2,
                    right: isArabic ? 2 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: index == 3 ? Colors.white : const Color(0xFF8534BC),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // عنوان القسم مع زر "عرض المزيد"
          Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'تسوق حسب احتياجاتك!' : 'Shop according to your needs!',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic ? 'عرض المزيد' : 'View More',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9A46D7),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // قائمة الفئات
          Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: isArabic ? [
              // الترتيب للعربية (من اليمين لليسار)
              _buildCategoryItem('الكل', '', isArabic),
              _buildCategoryItem('جواكت', 'assets/images/figma/jacket_category.png', isArabic),
              _buildCategoryItem('أحذية', 'assets/images/figma/shoes_category.png', isArabic),
              _buildCategoryItem('شنط', 'assets/images/figma/bags_category.png', isArabic),
            ] : [
              // الترتيب للإنجليزية (من اليسار لليمين)
              _buildCategoryItem('All', '', isArabic),
              _buildCategoryItem('Jackets', 'assets/images/figma/jacket_category.png', isArabic),
              _buildCategoryItem('Shoes', 'assets/images/figma/shoes_category.png', isArabic),
              _buildCategoryItem('Bags', 'assets/images/figma/bags_category.png', isArabic),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String name, String imagePath, bool isArabic) {
    final isSelected = _selectedCategory == name || (_selectedCategory == 'الكل' && name == 'الكل');
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = name;
        });
      },
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF9A46D7).withOpacity(0.1) : const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(18),
              border: isSelected ? Border.all(color: const Color(0xFF9A46D7), width: 2) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: imagePath.isNotEmpty 
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF9A46D7).withOpacity(0.3),
                              const Color(0xFFBDBDBD),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.category,
                          size: 32,
                          color: Colors.white70,
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF9A46D7).withOpacity(0.3),
                          const Color(0xFFBDBDBD),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.apps,
                      size: 32,
                      color: Colors.white70,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFF353A62),
            ),
            textAlign: TextAlign.center,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // عنوان القسم مع زر "عرض المزيد"
          Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'منتجات مميزة' : 'Featured Products',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isArabic ? 'عرض المزيد' : 'View More',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9A46D7),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // شبكة المنتجات المميزة
          FutureBuilder<List<Product>>(
            future: _storeService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                    ),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(height: 200);
              }

              final filteredProducts = _filterProducts(snapshot.data!);
              final products = filteredProducts.take(4).toList();
              
              return SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  reverse: isArabic,
                  padding: EdgeInsets.zero,
                  itemCount: products.length > 4 ? 4 : products.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 11),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 171,
                      child: _buildFigmaProductCard(products[index], isArabic),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBestDiscounts(bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // عنوان القسم
          Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'أفضل الخصومات' : 'Best Discounts',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          
          // شبكة منتجات الخصومات
          FutureBuilder<List<Product>>(
            future: _storeService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 400,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                    ),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(height: 400);
              }

              final filteredProducts = _filterProducts(snapshot.data!);
              final products = filteredProducts.take(6).toList();
              
              if (products.isEmpty) {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Text(
                    isArabic ? 'لا توجد منتجات متطابقة' : 'No matching products',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      color: Color(0xFF637D92),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              return Column(
                children: [
                  // الصف الأول
                  Row(
                    children: [
                      Flexible(
                        child: _buildDiscountProductCard(products[0], isArabic),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: _buildDiscountProductCard(products.length > 1 ? products[1] : products[0], isArabic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // الصف الثاني
                  Row(
                    children: [
                      Flexible(
                        child: _buildDiscountProductCard(products.length > 2 ? products[2] : products[0], isArabic),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: _buildDiscountProductCard(products.length > 3 ? products[3] : products[0], isArabic),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountProductCard(Product product, bool isArabic) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        height: 273,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFF6F6F6)),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // صورة المنتج
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF6F6F6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                  child: Image.network(
                    product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF9A46D7).withOpacity(0.3),
                              const Color(0xFFBDBDBD),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 40,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // شارة "مميز" أو "جديد"
                if (product.reviews.length > 10)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFEBB69), Color(0xFFF68801)],
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(11),
                          bottomLeft: Radius.circular(11),
                        ),
                      ),
                      child: Text(
                        isArabic ? 'مميز' : 'Featured',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    top: 11,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27CD81),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isArabic ? 'جديد' : 'New',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // تفاصيل المنتج
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // اسم المنتج
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF353A62),
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 6),
                
                // التقييم والفئة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.category,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF727880),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEED9),
                        borderRadius: BorderRadius.circular(48),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 10,
                            color: Color(0xFFFEAA43),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '4.3',
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // السعر
                Text(
                  '${product.price.toStringAsFixed(0)} ر.س',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A46D7),
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(bool isArabic) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: isArabic,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['name']!;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFFE7EBEF),
                        width: 2,
                      ),
                    ),
                    child: category['image']!.isEmpty
                        ? Icon(
                            Icons.apps,
                            size: 28,
                            color: isSelected ? Colors.white : const Color(0xFF9A46D7),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              category['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.category,
                                  size: 28,
                                  color: isSelected ? Colors.white : const Color(0xFF9A46D7),
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name']!,
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFF637D92),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid(bool isArabic) {
    return Expanded(
            child: FutureBuilder<List<Product>>(
        future: _storeService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
              ),
            );
          }
          
                if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'حدث خطأ في تحميل المنتجات' : 'Error loading products',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      color: Color(0xFF637D92),
                    ),
                  ),
                ],
              ),
            );
          }
          
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا توجد منتجات' : 'No products available',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      color: Color(0xFF637D92),
                    ),
                  ),
                ],
              ),
            );
          }

          List<Product> filteredProducts = snapshot.data!;
          
          // تطبيق فلتر البحث
          if (_searchQuery.isNotEmpty) {
            filteredProducts = filteredProducts
                .where((product) =>
                    product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    product.description.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }
          
          // تطبيق فلتر الفئة
          if (_selectedCategory != 'الكل') {
            filteredProducts = filteredProducts
                .where((product) => product.category.contains(_selectedCategory))
                .toList();
          }

          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا توجد نتائج للبحث' : 'No search results',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      color: Color(0xFF637D92),
                    ),
                  ),
                ],
              ),
            );
          }

                return GridView.builder(
            padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
              childAspectRatio: 0.75,
                  ),
            itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
              return _buildFigmaProductCard(filteredProducts[index], isArabic);
                  },
                );
              },
      ),
    );
  }

  Widget _buildFigmaProductCard(Product product, bool isArabic) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF9A46D7).withOpacity(0.3),
                              const Color(0xFFBDBDBD),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 40,
                            color: Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // شارة الخصم
                if (product.oldPrice != null && product.oldPrice! > product.price)
                  Positioned(
                    top: 8,
                    right: isArabic ? null : 8,
                    left: isArabic ? 8 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE32B3D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(((product.oldPrice! - product.price) / product.oldPrice!) * 100).round()}%',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                
                // أيقونة القلب
                Positioned(
                  top: 8,
                  right: isArabic ? 8 : null,
                  left: isArabic ? null : 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Color(0xFF637D92),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // تفاصيل المنتج
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // اسم المنتج
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2035),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // الوصف
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF637D92),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // السعر والتقييم
                  Row(
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // التقييم (يسار في LTR، يمين في RTL)
                      Row(
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFFAA43),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.reviews.isNotEmpty 
                                ? (product.reviews.map((r) => r.rating).reduce((a, b) => a + b) / product.reviews.length).toStringAsFixed(1)
                                : '4.5',
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D2035),
                            ),
                          ),
                        ],
                      ),
                      
                      // السعر (يمين في LTR، يسار في RTL)
                      Column(
                        crossAxisAlignment: isArabic ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          Text(
                            isArabic ? '${product.price.toStringAsFixed(0)} ريال' : '\$${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9A46D7),
                            ),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          if (product.oldPrice != null && product.oldPrice! > product.price)
                            Text(
                              isArabic ? '${product.oldPrice!.toStringAsFixed(0)} ريال' : '\$${product.oldPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF637D92),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressModal(BuildContext context, bool isArabic) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1D2035).withOpacity(0.5),
      child: Center(
        child: Container(
          width: 382,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFF8F7F8),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAddressModal = false;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFF292D32),
                        ),
                      ),
                    ),
                    
                    // Title
                    Expanded(
                      child: Text(
                        isArabic ? 'إضافة عنوان جديد' : 'Add New Address',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D0C0D),
                        ),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ),
                    
                    const SizedBox(width: 44), // For balance
                  ],
                ),
              ),
              
              // Content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  children: [
                    // Icon and Text Section
                    Column(
                      children: [
                        // Location Icon Container
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF6FE),
                            borderRadius: BorderRadius.circular(750),
                          ),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 24,
                                color: Color(0xFF9A46D7),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Title & Subtitle
                        Column(
                          children: [
                            Text(
                              isArabic ? 'ليس لديك أي عنوان مضاف' : 'You don\'t have any address added',
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D0C0D),
                              ),
                              textAlign: TextAlign.center,
                              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              isArabic ? 'أضف عنوانك، وابدأ التسوق!' : 'Add your address and start shopping!',
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFAAB9C5),
                              ),
                              textAlign: TextAlign.center,
                              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Add Address Button
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddressesPage(),
                          ),
                        ).then((_) {
                          // Re-check address after returning from addresses page
                          _checkUserAddress();
                        });
                      },
                      child: Container(
                        width: 210,
                        height: 59,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9A46D7),
                          borderRadius: BorderRadius.circular(39),
                        ),
                        child: Center(
                          child: Text(
                            isArabic ? 'إضافة عنوان جديد' : 'Add New Address',
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
