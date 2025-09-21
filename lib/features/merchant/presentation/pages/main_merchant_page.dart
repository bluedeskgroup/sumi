import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'advanced_merchant_home_page.dart';
import 'merchant_orders_page.dart';
import 'merchant_products_page.dart';
import 'add_product_page.dart';
import 'more_page.dart';

class MainMerchantPage extends StatefulWidget {
  final String merchantId;
  
  const MainMerchantPage({
    super.key,
    required this.merchantId,
  });

  @override
  State<MainMerchantPage> createState() => _MainMerchantPageState();
}

class _MainMerchantPageState extends State<MainMerchantPage> {
  int _currentIndex = 0;
  bool _showAddMenu = false;
  
  // Cache the pages to avoid rebuilding
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    
    // Initialize pages once
    _pages = [
      AdvancedMerchantHomePage(merchantId: widget.merchantId),
      const MerchantOrdersPage(),
      const MerchantProductsPage(),
      const MorePage(),
    ];
  }

  void _navigateToPage(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
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
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        body: Stack(
          children: [
            // Main content using IndexedStack for better performance
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            
            // Add Menu Popup
            if (_showAddMenu) _buildAddMenuPopup(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: _buildBottomNavigation(),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF141936),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 31.7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Home (الرئيسية) - Right side in RTL
              _buildNavItem(
                icon: Icons.home,
                label: 'الرئيسية',
                isActive: _currentIndex == 0,
                onTap: () => _navigateToPage(0),
              ),
              
              // Orders (الطلبات)
              _buildNavItem(
                icon: Icons.inbox_outlined,
                label: 'الطلبات',
                isActive: _currentIndex == 1,
                onTap: () => _navigateToPage(1),
              ),
              
              // Center Add Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showAddMenu = true;
                  });
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A46D7),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Products (المنتجات)
              _buildNavItem(
                icon: Icons.storefront,
                label: 'المنتجات',
                isActive: _currentIndex == 2,
                onTap: () => _navigateToPage(2),
              ),
              
              // More (المزيد) - Left side in RTL
              _buildNavItem(
                icon: Icons.grid_3x3,
                label: 'المزيد',
                isActive: _currentIndex == 3,
                onTap: () => _navigateToPage(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? Colors.white : const Color(0xFF626C83),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: isActive ? Colors.white : const Color(0xFF626C83),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMenuPopup() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showAddMenu = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Stack(
            children: [
              Positioned(
                bottom: 110, // Above bottom navigation
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAddMenuItem(
                              iconPath: 'assets/icons/user_plus_figma.png',
                              title: 'إضافة عميل',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                // Add customer logic
                              },
                            ),
                            _buildAddMenuItem(
                              iconPath: 'assets/icons/plus_square_figma.png',
                              title: 'إضافة منتج',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddProductPage(),
                                  ),
                                );
                              },
                            ),
                            _buildAddMenuItem(
                              iconPath: 'assets/icons/tag_figma.png',
                              title: 'إنشاء عرض',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                // Create offer logic
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAddMenuItem(
                              iconPath: 'assets/icons/receipt_figma.png',
                              title: 'إنشاء فاتورة',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                // Create invoice logic
                              },
                            ),
                            _buildAddMenuItem(
                              iconPath: 'assets/icons/megaphone_figma.png',
                              title: 'إنشاء إعلان',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                // Create ad logic
                              },
                            ),
                            _buildAddMenuItem(
                              iconPath: 'assets/icons/chat_circle_figma.png',
                              title: 'دردشة جديدة',
                              onTap: () {
                                setState(() {
                                  _showAddMenu = false;
                                });
                                // New chat logic
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMenuItem({
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 28,
                height: 28,
                color: const Color(0xFF9A46D7),
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.add_circle_outline,
                    size: 28,
                    color: Color(0xFF9A46D7),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFF1D2035),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
