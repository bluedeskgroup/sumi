import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../models/product_model.dart';
import '../../services/merchant_product_service.dart';
import 'add_product_page.dart';
import 'product_details_page.dart';
import 'edit_product_page.dart';
import 'edit_service_page.dart';
import '../widgets/delete_confirmation_dialog.dart';
import 'manage_categories_page.dart';

class MerchantProductsPage extends StatefulWidget {
  const MerchantProductsPage({super.key});

  @override
  State<MerchantProductsPage> createState() => _MerchantProductsPageState();
}

class _MerchantProductsPageState extends State<MerchantProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Defer loading data until after the build is complete
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final productService = context.read<MerchantProductService>();
    // For demo purposes, using a sample merchant ID
    await productService.loadMerchantProducts('merchant_sample_123');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            _buildTabs(),
            Expanded(
              child: _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageCategoriesPage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A46D7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF9A46D7).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category,
                        size: 16,
                        color: Color(0xFF9A46D7),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'إدارة الأقسام',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF9A46D7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'أدارة المنتجات والخدمات',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: Color(0xFF1D2035),
                  height: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Search button
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _showSearchDialog,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE7EBEF)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFFAAB9C5),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'بحث',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFFCED7DE),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        
        // Add product/service button
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: _showAddProductDialog,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF9A46D7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 84,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'أضافة منتج او خدمه',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Consumer<MerchantProductService>(
        builder: (context, productService, child) {
          return Row(
            children: [
              // Services tab
              Expanded(
                child: GestureDetector(
                  onTap: () => productService.switchTab(ProductType.service),
                  child: Container(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'الخدمات',
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: productService.currentTab == ProductType.service
                                  ? const Color(0xFF9A46D7)
                                  : const Color(0xFFC2CDD6),
                              letterSpacing: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: productService.currentTab == ProductType.service
                              ? const Color(0xFF9A46D7)
                              : const Color(0xFFE7EBEF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Products tab
              Expanded(
                child: GestureDetector(
                  onTap: () => productService.switchTab(ProductType.product),
                  child: Container(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'المنتجات',
                            style: TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: productService.currentTab == ProductType.product
                                  ? const Color(0xFF9A46D7)
                                  : const Color(0xFFC2CDD6),
                              letterSpacing: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: productService.currentTab == ProductType.product
                              ? const Color(0xFF9A46D7)
                              : const Color(0xFFE7EBEF),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductList() {
    return Consumer<MerchantProductService>(
      builder: (context, productService, child) {
        if (productService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF9A46D7),
            ),
          );
        }

        if (productService.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  productService.errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final items = productService.currentItems;
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  productService.currentTab == ProductType.product
                      ? Icons.shopping_bag_outlined
                      : Icons.room_service_outlined,
                  size: 64,
                  color: const Color(0xFFAAB9C5),
                ),
                const SizedBox(height: 16),
                Text(
                  productService.currentTab == ProductType.product
                      ? 'لا توجد منتجات'
                      : 'لا توجد خدمات',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 18,
                    color: Color(0xFFAAB9C5),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 17, 24, 20),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => _buildProductSeparator(),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildProductCard(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Column(
      children: [
        // Main product row
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(product: product),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product details section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFF141414),
                        height: 1.85,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    
                    // Sales rate with background color
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF20C9AC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up,
                                size: 10,
                                color: Color(0xFF20C9AC),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.formattedSalesRate,
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: Color(0xFF2E2C34),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'معدل البيع : ',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Color(0xFF1D2035),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Color with right alignment
                    if (product.color.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(width: 10), // Spacer
                          Text(
                            product.formattedColor,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: Color(0xFF1D2035),
                            ),
                          ),
                        ],
                      ),
                    
                    if (product.color.isNotEmpty) const SizedBox(height: 10),
                    
                    // Size with right alignment
                    if (product.size.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(width: 10), // Spacer
                          Text(
                            product.formattedSize,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: Color(0xFF1D2035),
                            ),
                          ),
                        ],
                      ),
                    
                    if (product.size.isNotEmpty) const SizedBox(height: 10),
                    
                    // Quantity (for products only)
                    if (product.type == ProductType.product)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            product.formattedQuantity,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: Color(0xFF1D2035),
                            ),
                          ),
                        ],
                      ),
                    
                    if (product.type == ProductType.product) const SizedBox(height: 10),
                    
                    // Price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Discounted price
                        Text(
                          'بعد : ${product.formattedDiscountedPrice}',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF9A46D7),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Original price with strikethrough
                        Text(
                          'السعر قبل الخصم : ${product.formattedOriginalPrice}',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Color(0xFF1D2035),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Product image
              Container(
                width: 69,
                height: 69,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(product.type);
                          },
                        ),
                      )
                    : _buildPlaceholderImage(product.type),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Action buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Delete button
            Expanded(
              child: Container(
                height: 42,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFADCDF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(product),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Color(0xFFE32B3D),
                  ),
                  label: Text(
                    product.type == ProductType.product ? 'حذف المنتج' : 'حذف الخدمة',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFFE32B3D),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Edit button
            Expanded(
              child: Container(
                height: 42,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6FE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextButton.icon(
                  onPressed: () => _editProduct(product),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Color(0xFF9A46D7),
                  ),
                  label: Text(
                    product.type == ProductType.product ? 'تعديل المنتج' : 'تعديل الخدمة',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF9A46D7),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage(ProductType type) {
    return Container(
      width: 69,
      height: 69,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        type == ProductType.product ? Icons.shopping_bag : Icons.room_service,
        size: 30,
        color: const Color(0xFF9A46D7),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('البحث في المنتجات'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'اكتب كلمة البحث...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            context.read<MerchantProductService>().searchProducts(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              context.read<MerchantProductService>().searchProducts('');
              Navigator.pop(context);
            },
            child: const Text('مسح'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 17),
      child: Column(
        children: [
          // Main separator line
          Container(
            height: 1,
            color: const Color(0xFFDDE2E4),
          ),
          const SizedBox(height: 8),
          // Progress indicator with colored sections
          Row(
            children: [
              // Colored progress section
              Container(
                width: 135.5,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFF1ED29C),
                  borderRadius: BorderRadius.circular(4.5),
                ),
              ),
              const SizedBox(width: 5),
              // Remaining section
              Expanded(
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EBEF),
                    borderRadius: BorderRadius.circular(4.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(ProductModel product) async {
    final result = await DeleteConfirmationDialog.show(
      context: context,
      itemName: product.name,
      isService: product.type == ProductType.service,
    );

    if (result == true) {
      _deleteProduct(product);
    }
  }

  void _deleteProduct(ProductModel product) async {
    final productService = context.read<MerchantProductService>();
    final success = await productService.deleteProduct(product.id, product.type);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف ${product.type == ProductType.product ? 'المنتج' : 'الخدمة'} بنجاح'),
          backgroundColor: const Color(0xFF20C9AC),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في حذف ${product.type == ProductType.product ? 'المنتج' : 'الخدمة'}'),
          backgroundColor: const Color(0xFFE32B3D),
        ),
      );
    }
  }

  void _editProduct(ProductModel product) {
    if (product.type == ProductType.product) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProductPage(product: product),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditServicePage(service: product),
        ),
      );
    }
  }

  void _showAddProductDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    );
  }
}
