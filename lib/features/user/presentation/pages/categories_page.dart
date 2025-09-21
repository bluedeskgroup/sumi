import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../../merchant/models/category_unified_model.dart';
import '../../../merchant/services/category_unified_service.dart';
import '../../services/user_product_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _userCountry = 'السعودية';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userProductService = context.read<UserProductService>();
    _userCountry = userProductService.userCountry;
    
    final categoryService = context.read<CategoryUnifiedService>();
    await categoryService.loadCategoriesForUser(_userCountry);
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
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: _buildCategoriesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9A46D7), Color(0xFF7B1FA2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'تصفح الأقسام',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _userCountry,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Text(
                'اكتشف المنتجات والخدمات القريبة منك',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7EBEF)),
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'البحث في الأقسام...',
            hintStyle: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              color: Color(0xFFB6B4BA),
            ),
            prefixIcon: Icon(
              Icons.search,
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
          onChanged: (value) {
            context.read<CategoryUnifiedService>().searchCategories(value);
          },
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Consumer<CategoryUnifiedService>(
        builder: (context, categoryService, child) {
          return Row(
            children: [
              // Services tab
              Expanded(
                child: GestureDetector(
                  onTap: () => categoryService.switchTab(CategoryType.service),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: categoryService.currentTab == CategoryType.service
                          ? const Color(0xFF9A46D7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryService.currentTab == CategoryType.service
                            ? const Color(0xFF9A46D7)
                            : const Color(0xFFE7EBEF),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build,
                          size: 18,
                          color: categoryService.currentTab == CategoryType.service
                              ? Colors.white
                              : const Color(0xFF637D92),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'خدمات',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: categoryService.currentTab == CategoryType.service
                                ? Colors.white
                                : const Color(0xFF637D92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Products tab
              Expanded(
                child: GestureDetector(
                  onTap: () => categoryService.switchTab(CategoryType.product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: categoryService.currentTab == CategoryType.product
                          ? const Color(0xFF9A46D7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: categoryService.currentTab == CategoryType.product
                            ? const Color(0xFF9A46D7)
                            : const Color(0xFFE7EBEF),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 18,
                          color: categoryService.currentTab == CategoryType.product
                              ? Colors.white
                              : const Color(0xFF637D92),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'منتجات',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: categoryService.currentTab == CategoryType.product
                                ? Colors.white
                                : const Color(0xFF637D92),
                          ),
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

  Widget _buildCategoriesList() {
    return Consumer<CategoryUnifiedService>(
      builder: (context, categoryService, child) {
        if (categoryService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF9A46D7),
            ),
          );
        }

        if (categoryService.errorMessage.isNotEmpty) {
          return _buildErrorState(categoryService.errorMessage);
        }

        final categories = categoryService.currentCategories;

        if (categories.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            _buildFeaturedSection(categoryService.getFeaturedCategories()),
            const SizedBox(height: 16),
            Expanded(
              child: _buildAllCategoriesGrid(categories),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedSection(List<CategoryUnifiedModel> featuredCategories) {
    if (featuredCategories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  // Show all featured categories
                },
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    color: Color(0xFF9A46D7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Color(0xFFFF9800),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'الأقسام المميزة',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1D2035),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: featuredCategories.length,
            itemBuilder: (context, index) {
              final category = featuredCategories[index];
              return Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildFeaturedCategoryCard(category),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCategoryCard(CategoryUnifiedModel category) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(int.parse(category.color.replaceFirst('#', '0xFF'))).withOpacity(0.8),
              Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.type == CategoryType.product ? Icons.inventory_2 : Icons.build,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              category.formattedCount,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCategoriesGrid(List<CategoryUnifiedModel> categories) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(CategoryUnifiedModel category) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category),
      child: Container(
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
          children: [
            // Header with color
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  category.type == CategoryType.product ? Icons.inventory_2 : Icons.build,
                  size: 32,
                  color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1D2035),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.formattedCount,
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 12,
                          color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _buildEmptyState() {
    return Consumer<CategoryUnifiedService>(
      builder: (context, categoryService, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  categoryService.currentTab == CategoryType.product 
                      ? Icons.inventory_2 
                      : Icons.build,
                  size: 48,
                  color: const Color(0xFF9A46D7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                categoryService.currentTab == CategoryType.product 
                    ? 'لا توجد أقسام منتجات متاحة'
                    : 'لا توجد أقسام خدمات متاحة',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Color(0xFF1D2035),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'جاري العمل على إضافة المزيد من الأقسام في منطقتك',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  color: Color(0xFF637D92),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Color(0xFFE32B3D),
          ),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              color: Color(0xFF637D92),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF9A46D7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCategory(CategoryUnifiedModel category) {
    // TODO: Navigate to category products/services page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم عرض ${category.name} قريباً'),
        backgroundColor: const Color(0xFF9A46D7),
      ),
    );
  }
}
