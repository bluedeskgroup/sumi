import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumi/features/store/models/cart_item_model.dart';
import 'package:sumi/features/store/presentation/pages/checkout_stepper_page.dart';
import 'package:sumi/features/store/presentation/pages/payment_page.dart';
import 'package:sumi/features/store/services/cart_service.dart';
import 'package:sumi/features/auth/services/address_service.dart';
import 'package:sumi/features/auth/models/address_model.dart';
import 'package:sumi/features/auth/presentation/pages/addresses_page.dart';
import 'package:sumi/l10n/app_localizations.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: cartService.items.isEmpty
            ? _buildEmptyCart(context, isArabic)
            : Stack(
                children: [
                  // Main Content
                  SingleChildScrollView(
      child: Column(
        children: [
                        const SizedBox(height: 68), // Space for header
                        _buildMainContent(context, cartService, isArabic),
                        const SizedBox(height: 96), // Space for bottom bar
                      ],
                    ),
                  ),
                  
                  // Fixed Header
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildHeader(context, isArabic),
                  ),
                  
                  // Fixed Bottom Bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomSection(context, cartService, isArabic),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic) {
    return Container(
      height: 68,
      width: 430,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.only(left: 97, top: 6),
        child: Row(
          children: [
            // Back Button - Exact Figma positioning (x: 97, y: 68)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
      child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
          color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: const Color(0xFFE7EBEF), width: 1),
                ),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    child: Icon(
                      isArabic ? Icons.arrow_forward : Icons.arrow_back,
                      size: 12,
                      color: const Color(0xFF323F49),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 18), // Gap from Figma
            
            // Title - Exact Figma positioning
            Container(
              width: 236,
              child: Text(
                isArabic ? 'عربتي' : 'My Cart',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D2035),
                  height: 1.6,
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isArabic) {
    return Column(
      children: [
        _buildHeader(context, isArabic),
        Expanded(
          child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                const Icon(
                  Icons.shopping_cart_outlined, 
                  size: 100, 
                  color: Color(0xFFDAE1E7),
                ),
          const SizedBox(height: 20),
                Text(
                  isArabic ? 'سلتك فارغة!' : 'Your cart is empty!',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF637D92),
                  ),
                ),
          const SizedBox(height: 20),
                ElevatedButton.icon(
            icon: const Icon(Icons.store_outlined),
                  label: Text(isArabic ? 'ابدأ التسوق' : 'Start Shopping'),
            onPressed: () {
                    if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A46D7),
                    foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, CartService cart, bool isArabic) {
    return Container(
      width: 430, // Exact Figma frame width
      child: Column(
        children: [
          const SizedBox(height: 64), // Space from header (132 - 68 = 64)
          
          // Main Content Container - Exact Figma positioning (y: 132)
          Container(
            width: 430,
            padding: const EdgeInsets.symmetric(horizontal: 24), // Exact padding from Figma
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Address Section
                  _buildAddressSection(context, isArabic),
                  
                  // Cart Items
                  ...cart.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildCartItem(item, index, cart.items.length - 1, isArabic);
                  }).toList(),
                  
                  // Coupon Section
                  _buildCouponSection(isArabic),
                  
                  const SizedBox(height: 24), // Gap before summary
                  
                  // Summary Section
                  _buildSummarySection(cart, isArabic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, bool isArabic) {
    return StreamBuilder<List<AddressModel>>(
      stream: AddressService().streamAddresses(),
      builder: (context, snapshot) {
        final addresses = snapshot.data ?? [];
        AddressModel? defaultAddress;
        
        if (addresses.isNotEmpty) {
          // First try to find default address
          try {
            defaultAddress = addresses.firstWhere((addr) => addr.isDefault);
          } catch (e) {
            // If no default address, use the first one
            defaultAddress = addresses.first;
          }
        }
        
        return Container(
          width: 382, // Exact Figma width
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFCBCBCB), width: 1),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              // Map Pin Icon
              Container(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: const Color(0xFF637D92),
                ),
              ),
              const SizedBox(width: 10), // Gap from Figma
              
              // Address Text
              Expanded(
                child: Text(
                  defaultAddress != null
                      ? 'العنوان : ${defaultAddress.addressLine1}, ${defaultAddress.city}'
                      : snapshot.connectionState == ConnectionState.waiting
                          ? 'العنوان : جاري التحميل...'
                          : 'العنوان : لم يتم إضافة عنوان بعد',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: defaultAddress != null 
                        ? const Color(0xFF637D92)
                        : const Color(0xFF9A46D7), // Purple for no address to encourage adding
                    height: 1.6,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(width: 10), // Gap from Figma
              
              // Edit Address Button
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressesPage(),
                    ),
                  );
                  // StreamBuilder will automatically update when address changes
                },
                child: Text(
                  defaultAddress != null ? 'تعديل العنوان' : 'إضافة عنوان',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9A46D7),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item, int index, int lastIndex, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16), // Exact padding from Figma
      decoration: BoxDecoration(
        border: index < lastIndex ? const Border(
          bottom: BorderSide(color: Color(0xFFCBCBCB), width: 1),
        ) : null,
      ),
        child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Product Image - Exact Figma dimensions
          Container(
            width: 77,
            height: 102,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: item.product.imageUrls.isNotEmpty 
                ? Image.network(
                item.product.imageUrls.first,
                fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF6F6F6),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFF637D92),
                        size: 32,
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFF6F6F6),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Color(0xFF637D92),
                      size: 32,
                    ),
                  ),
            ),
          ),
          
          const SizedBox(width: 16), // Exact gap from Figma
          
          // Product Details
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Product Name
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF121212),
                    height: 1.57,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                
                const SizedBox(height: 8), // Gap from Figma
                
                // Product Attributes
                Text(
                  'المقاس: 2XL، اللون: أخضر',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF605F5F),
                    height: 1.67,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
                
                const SizedBox(height: 8), // Gap from Figma
                
                // Price and Controls Row
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity Controls
                    _buildQuantityControls(item),
                    
                    // Price and Delete
                    Row(
                      textDirection: TextDirection.rtl,
                children: [
                        // Price
                  Text(
                          '${(item.product.price * item.quantity).toStringAsFixed(2)} ريال',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9A46D7),
                            height: 1.57,
                          ),
                        ),
                        
                        const SizedBox(width: 8), // Gap from Figma
                        
                        // Delete Icon
                        Consumer<CartService>(
                          builder: (context, cart, child) {
                            return GestureDetector(
                              onTap: () => cart.removeFromCart(item),
      child: Container(
                                width: 20,
                                height: 20,
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: const Color(0xFF605F5F),
                                ),
                              ),
                            );
                          },
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
    );
  }

  Widget _buildQuantityControls(CartItem item) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
    return Container(
          width: 80, // Exact Figma width
          height: 32, // Exact Figma height
      decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFCBCBCB), width: 1),
            borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
              // Minus Button
              GestureDetector(
                onTap: () => cart.updateQuantity(item, item.quantity - 1),
                child: Container(
                  width: 16,
                  height: 16,
                  child: Icon(
                    Icons.remove,
                    size: 9.33, // Exact icon size from Figma
                    color: const Color(0xFF121212),
                  ),
                ),
              ),
              
              // Quantity Text
          Text(
            '${item.quantity}',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF121212),
                  height: 1.67,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Plus Button
              GestureDetector(
                onTap: () => cart.updateQuantity(item, item.quantity + 1),
                child: Container(
                  width: 16,
                  height: 16,
                  child: Icon(
                    Icons.add,
                    size: 10.08, // Exact icon size from Figma
                    color: const Color(0xFF121212),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponSection(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Apply Button - Exact Figma dimensions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF9A46D7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'تطبيق',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.75,
                letterSpacing: -0.025,
              ),
            ),
          ),
          
          const SizedBox(width: 12), // Exact gap from Figma
          
          // Input Field - Exact Figma dimensions
          Expanded(
            child: Container(
              height: 46, // Exact height from Figma
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDAE1E7), width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
      decoration: InputDecoration(
                    hintText: 'كوبون الخصم',
                    hintStyle: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFDAE1E7),
                      height: 1.57,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1D2035),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(CartService cart, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Coupon Applied
          _buildSummaryRow(
            'A4C0',
            '-8.00 ريال [إزالة]',
            hasIcon: true,
            valueColor: const Color(0xFF1BA97F),
            height: 46,
          ),
          
          // Shipping
          _buildSummaryRow(
            'الشحن',
            'مجاني',
            height: 46,
          ),
          
          // Subtotal
          _buildSummaryRow(
            'المجموع الفرعي',
            '${cart.totalPrice.toStringAsFixed(2)} ريال',
            height: 46,
          ),
          
          // Total
          Container(
            height: 46, // Exact height from Figma
        child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
          children: [
                // Total Label
                Text(
                  'الإجمالي',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2035),
                    height: 1.625,
                  ),
                  textAlign: TextAlign.right,
                ),
                
                // Total Amount
                  Text(
                  '${(cart.totalPrice - 8.0).toStringAsFixed(2)} ريال',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2035),
                    height: 1.625,
                  ),
                  textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool hasIcon = false, Color? valueColor, double height = 46}) {
    return Container(
      height: height, // Exact height from Figma
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEAEAEA), width: 1),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            textDirection: TextDirection.rtl,
        children: [
        Text(
          title,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1D2035),
                  height: 1.57,
                ),
                textAlign: TextAlign.right,
              ),
              if (hasIcon) ...[
                const SizedBox(width: 8), // Gap from Figma
                Container(
                  width: 20, // Exact icon size from Figma
                  height: 20,
                  child: Icon(
                    Icons.local_offer_outlined,
                    size: 16,
                    color: const Color(0xFF1D2035),
                  ),
                ),
              ],
            ],
          ),
          
          // Value
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1D2035),
              height: 1.57,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, CartService cart, bool isArabic) {
    return Container(
      width: 430, // Exact frame width from Figma
      height: 96, // Exact frame height from Figma
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), // Exact padding from Figma
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 60,
          ),
        ],
      ),
        child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentPage()),
          );
        },
        child: Container(
          width: 382, // Exact button width from Figma
          height: 55, // Exact button height from Figma
          decoration: BoxDecoration(
            color: const Color(0xFF9A46D7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              'الدفع',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF),
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 