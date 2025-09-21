import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumi/features/store/services/cart_service.dart';
import 'package:sumi/features/store/presentation/pages/cart_page.dart';
import 'package:sumi/features/store/models/product_model.dart';
import 'package:sumi/l10n/app_localizations.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentImageIndex = 0;
  String _selectedColor = 'Teal';
  String _selectedSize = 'S';
  int _quantity = 1;
  bool _isFavorite = false;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  final List<String> _availableColors = ['Teal', 'Purple', 'Red', 'Black'];
  final List<String> _availableSizes = ['S', 'M', 'L', 'XL', '2XL'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildProductImageSection(isArabic),
                  _buildProductDetailsSection(isArabic),
                  if (_selectedTabIndex == 0) _buildReviewsSection(isArabic),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomActionBar(isArabic),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProductImageSection(bool isArabic) {
    return Container(
      height: 408,
      width: double.infinity,
      color: const Color(0xFFF6F6F6),
      child: Stack(
        children: [
          // Main Product Image
          Center(
            child: Container(
              width: 351,
              height: 243,
              margin: const EdgeInsets.only(top: 130),
              child: widget.product.imageUrls.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrls.first,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/figma/product_shoe_image.png',
                          fit: BoxFit.contain,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/images/figma/product_shoe_image.png',
                      fit: BoxFit.contain,
                    ),
            ),
          ),

          // Action Buttons - Heart & Share (RTL aware)
          Positioned(
            top: 74,
            left: isArabic ? null : 24,
            right: isArabic ? 24 : null,
            child: Column(
              children: [
                _buildActionButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  onTap: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 16),
                _buildCartIcon(isArabic),
              ],
            ),
          ),

          // Back Button (RTL aware)
          Positioned(
            top: 74,
            left: isArabic ? 24 : null,
            right: isArabic ? null : 24,
            child: _buildActionButton(
              icon: isArabic ? Icons.arrow_forward : Icons.arrow_back,
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ),

          // Image Counter (RTL aware)
          Positioned(
            bottom: 74,
            left: isArabic ? 24 : null,
            right: isArabic ? null : 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF9A46D7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isArabic ? '12 / 1' : '1 / 12',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(60),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 24,
          color: const Color(0xFF4A5E6D),
        ),
      ),
    );
  }

  Widget _buildCartIcon(bool isArabic) {
    return Consumer<CartService>(
      builder: (context, cart, _) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: 24,
                  color: Color(0xFF4A5E6D),
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
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductDetailsSection(bool isArabic) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          // Tab Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTabHeaders(isArabic),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          // Product Info Content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _selectedTabIndex == 0 
                ? Column(
                    crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      _buildMainProductInfo(isArabic),
                      const SizedBox(height: 24),
                      _buildColorSelection(isArabic),
                      const SizedBox(height: 24),
                      _buildSizeSelection(isArabic),
                      const SizedBox(height: 24),
                      _buildStockAndGuide(isArabic),
                      const SizedBox(height: 24),
                      _buildAboutProduct(isArabic),
                      const SizedBox(height: 24),
                      _buildStoreInfo(isArabic),
                      const SizedBox(height: 24),
                    ],
                  )
                : _buildSpecificationsContent(isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeaders(bool isArabic) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        children: [
          // Overview Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                });
              },
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      isArabic ? 'نظرة عامة' : 'Overview',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _selectedTabIndex == 0 ? const Color(0xFF9A46D7) : const Color(0xFFC2CDD6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: 1,
                    color: _selectedTabIndex == 0 ? const Color(0xFF9A46D7) : const Color(0xFFE7EBEF),
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
          
          // Specifications Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      isArabic ? 'المواصفات' : 'Specifications',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _selectedTabIndex == 1 ? const Color(0xFF9A46D7) : const Color(0xFFC2CDD6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: 1,
                    color: _selectedTabIndex == 1 ? const Color(0xFF9A46D7) : const Color(0xFFE7EBEF),
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainProductInfo(bool isArabic) {
    return Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          child: Text(
            isArabic ? 'عنوان او اسم المنتج المعروض' : widget.product.name,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D2035),
              height: 1.46,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                isArabic ? '86.00 ريال' : '\$86.00',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9A46D7),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? '104.00 ريال' : '\$104.00',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFA7A7A7),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Rating (RTL aware)
        Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Container(
                    margin: EdgeInsets.only(
                      left: isArabic ? 0 : 2,
                      right: isArabic ? 2 : 0,
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 20,
                      color: Color(0xFFED7E14),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? '23 التقييم' : '23 reviews',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFAAB9C5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection(bool isArabic) {
    return Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'اللون:' : 'Color:',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A5E6D),
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Teal (Active)
              _buildColorOption('Teal', const Color(0xFF20C997), true),
              const SizedBox(width: 12),
              _buildColorOption('Purple', const Color(0xFFAF83F8), false),
              const SizedBox(width: 12),
              _buildColorOption('Red', const Color(0xFFE25563), false),
              const SizedBox(width: 12),
              _buildColorOption('Black', const Color(0xFF121212), false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(String colorName, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = colorName;
        });
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: const Color(0xFF121212), width: 1) : null,
        ),
        child: Container(
          margin: isSelected ? const EdgeInsets.all(4) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSelection(bool isArabic) {
    return Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'الحجم' : 'Size',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A5E6D),
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildSizeOption('S', true), // Active
              const SizedBox(width: 16),
              _buildSizeOption('M', false),
              const SizedBox(width: 16),
              _buildSizeOption('L', false),
              const SizedBox(width: 16),
              _buildSizeOption('XL', false),
              const SizedBox(width: 16),
              _buildSizeOption('2XL', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSizeOption(String size, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSize = size;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAF6FE) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFFCBCBCB),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            size,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isSelected ? const Color(0xFF9A46D7) : const Color(0xFF121212),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockAndGuide(bool isArabic) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 12,
                color: Color(0xFF121212),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? '673 منتج فى المخزن' : '673 products in stock',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A5E6D),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.straighten_outlined,
                size: 12,
                color: Color(0xFF121212),
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'دليل المقاسات' : 'Size Guide',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A5E6D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutProduct(bool isArabic) {
    return Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'حول المنتج' : 'About Product',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D2035),
          ),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        
        const SizedBox(height: 20),
        
        // Quality Guarantee
        _buildFeatureRow(
          icon: Icons.verified,
          text: isArabic ? 'ضمان الرضا بنسبة 100%' : '100% Satisfaction Guarantee',
          isArabic: isArabic,
        ),
        
        const SizedBox(height: 12),
        
        // Best Selling
        _buildFeatureRow(
          icon: Icons.emoji_events,
          text: isArabic ? 'المنتج الأكثر مبيعًا' : 'Best Selling Product',
          isArabic: isArabic,
        ),
        
        const SizedBox(height: 12),
        
        // Store Info
        _buildStoreInfo(isArabic),
      ],
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String text,
    required bool isArabic,
  }) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF1AB385),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1D2035),
              ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo(bool isArabic) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              shape: BoxShape.circle,
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/product_details_v2/adidas_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'متجر الفن والجمال' : 'Art & Beauty Store',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D2035),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'متجر موثوق به! معدل تقييم مرتفع' : 'Trusted store! High rating',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFAAB9C5),
                      ),
                    ),
                    const SizedBox(width: 4),
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
                            size: 7,
                            color: Color(0xFFFEAA43),
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            '5.0',
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsContent(bool isArabic) {
    return Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        
        // Main heading
        Container(
          width: double.infinity,
          child: Text(
            isArabic ? 'عنوان اساسي لوصف المنتج' : 'Main Product Description',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D2035),
              letterSpacing: -0.2,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
        
        const SizedBox(height: 14),
        
        // Main description
        Container(
          width: double.infinity,
          child: Text(
            isArabic 
                ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص هذا النص هو مثال لنص يمكن أن يستبدل في ..'
                : 'This text is an example of text that can be replaced in the same space, this text has been generated this text is an example of text that can be replaced in ..',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4A5E6D),
              height: 1.375,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Sub heading
        Container(
          width: double.infinity,
          child: Text(
            isArabic ? 'عنوان فرعي لوصف المنتج' : 'Sub Product Description',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D2035),
              letterSpacing: -0.2,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
        
        const SizedBox(height: 14),
        
        // Features list
        Container(
          width: double.infinity,
          child: Text(
            isArabic 
                ? '''• يساعد على تهدئة وحماية البشرة المتشققة والمتشققة والمتشققة يلطف العلامات المرئية لتهيج البشرة الجافة والبشرة الحساسة وفر راحة يومية للبشرة الجافة إلى شديدة الجفاف

• يحمي من آثار الجفاف الناتجة عن الرياح والبرودة

• استعادة راحة البشرة وترطيبها

• ملمس مغذي للغاية ولمسة نهائية غير دهنية.

• يلطف العلامات المرئية لتهيج البشرة الجافة والبشرة الحساسة'''
                : '''• Helps soothe and protect cracked, chapped and damaged skin soothes visible signs of irritation for dry and sensitive skin provides daily comfort for dry to severely dry skin

• Protects from the drying effects of wind and cold

• Restores skin comfort and hydration

• Very nourishing texture and non-greasy finish.

• Soothes visible signs of irritation for dry and sensitive skin''',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF4A5E6D),
              height: 1.5625,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildReviewsSection(bool isArabic) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildReviewChart(isArabic),
          const SizedBox(height: 20),
          _buildReviewsList(isArabic),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewChart(bool isArabic) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Left side - Rating Chart
        Container(
          width: 172,
          height: 225,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              // Overall Rating Circle
              Container(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    // Background Circle
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.1),
                          width: 4,
                        ),
                      ),
                    ),
                    // Progress Circle
                    Container(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: 0.9, // 4.5/5
                        strokeWidth: 5,
                        backgroundColor: const Color(0xFFF8F8F8),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
                      ),
                    ),
                    // Rating Number
                    Center(
                      child: Text(
                        '4.5',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return const Icon(
                    Icons.star,
                    size: 11,
                    color: Color(0xFFFFC107),
                  );
                }),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                isArabic ? '4220 تقييمًا و 241 تعليقًا' : '4220 ratings & 241 comments',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF353A62),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 27),
        
        // Right side - Rating Breakdown
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'تقييمات العملاء' : 'Customer Reviews',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2F4E),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Rating bars
              _buildRatingBar(5, isArabic ? '4.7 الف' : '4.7k', 0.8),
              const SizedBox(height: 14),
              _buildRatingBar(4, isArabic ? '3.5 الف' : '3.5k', 0.6),
              const SizedBox(height: 14),
              _buildRatingBar(3, isArabic ? '2.1 الف' : '2.1k', 0.4),
              const SizedBox(height: 14),
              _buildRatingBar(2, isArabic ? '2.1 الف' : '2.1k', 0.3),
              const SizedBox(height: 14),
              _buildRatingBar(1, isArabic ? '1.0 الف' : '1.0k', 0.1),
              
              const SizedBox(height: 20),
              
              // Add Review Button
              Container(
                width: 183,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    isArabic ? 'أضف مراجعتك' : 'Add your review',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

  Widget _buildRatingBar(int starCount, String count, double progress) {
    return Row(
      children: [
        Text(
          starCount.toString(),
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF353A62),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.star_outline,
          size: 16,
          color: Color(0xFFE7EBEF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          count,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF353A62),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsList(bool isArabic) {
    return Column(
      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Review Cards
        _buildReviewCard(
          name: 'سارة محمد',
          rating: 5.0,
          review: 'النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص ..',
          isArabic: isArabic,
          isVerified: true,
          likeCount: 1400,
          dislikeCount: 260,
        ),
        
        _buildReviewCard(
          name: 'سارة محمد',
          rating: 5.0,
          review: 'النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص ..',
          isArabic: isArabic,
          isVerified: true,
          likeCount: 1400,
          dislikeCount: 260,
        ),
        
        const SizedBox(height: 10),
        
        // Load More Button
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBD9FB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isArabic ? 'تحميل المزيد' : 'Load More',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9A46D7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String name,
    required double rating,
    required String review,
    required bool isArabic,
    required bool isVerified,
    required int likeCount,
    required int dislikeCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(bottom: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7EBEF), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/product_details_v2/user_avatar_1.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/figma/profile_user_06.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDFAF2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              isArabic ? 'طلبية مؤكدة' : 'Verified Purchase',
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1AB385),
                              ),
                            ),
                          ),
                        const SizedBox(width: 2),
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D2035),
                          ),
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.floor() ? Icons.star : Icons.star_border,
                          size: 16,
                          color: const Color(0xFFFEAA43),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            review,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF323F49),
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
          
          const SizedBox(height: 12),
          
          // Review Images
          Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: List.generate(3, (index) {
              return Container(
                width: 81,
                height: 81,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E3E3),
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 12),
          
          // Like/Dislike Buttons (RTL aware)
          Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              children: [
                // First Button (Like in Arabic, Dislike in English)
                Row(
                  children: [
                    Text(
                      isArabic ? 'اعجبني' : 'Dislike',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isArabic ? const Color(0xFF12D18E) : const Color(0xFFC7C7C7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isArabic ? Icons.thumb_up_outlined : Icons.thumb_down_outlined,
                      size: 20,
                      color: isArabic ? const Color(0xFF12D18E) : const Color(0xFFC7C7C7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (isArabic ? likeCount : dislikeCount).toString(),
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFC7C7C7),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 29),
                
                Container(
                  width: 1,
                  height: 20,
                  color: const Color(0xFFF4F4F4),
                ),
                
                const SizedBox(width: 29),
                
                // Second Button (Dislike in Arabic, Like in English)
                Row(
                  children: [
                    Text(
                      isArabic ? 'لم يعجبني' : 'Like',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isArabic ? const Color(0xFFC7C7C7) : const Color(0xFF12D18E),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isArabic ? Icons.thumb_down_outlined : Icons.thumb_up_outlined,
                      size: 20,
                      color: isArabic ? const Color(0xFFC7C7C7) : const Color(0xFF12D18E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      (isArabic ? dislikeCount : likeCount).toString(),
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFC7C7C7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isArabic) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 60,
          ),
        ],
      ),
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          children: [
            // Quantity Selector
            Container(
              width: 132,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                        });
                      }
                    },
                    child: const Icon(
                      Icons.remove,
                      size: 20,
                      color: Color(0xFF1D2035),
                    ),
                  ),
                  Text(
                    _quantity.toString(),
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2035),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _quantity++;
                      });
                    },
                    child: const Icon(
                      Icons.add,
                      size: 20,
                      color: Color(0xFF1D2035),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Add to Cart Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final cart = Provider.of<CartService>(context, listen: false);
                  cart.addToCart(widget.product, quantity: _quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تمت إضافة ${widget.product.name} إلى السلة بنجاح!'
                            : '${widget.product.name} added to cart!',
                      ),
                      action: SnackBarAction(
                        label: isArabic ? 'عرض السلة' : 'View Cart',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartPage()),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A46D7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      isArabic ? 'أضف للسلة' : 'Add to Cart',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
