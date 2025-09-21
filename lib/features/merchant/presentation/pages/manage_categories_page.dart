import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../models/category_unified_model.dart';
import '../../services/category_unified_service.dart';
import 'add_category_page.dart';
import '../widgets/category_card_widget.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final categoryService = context.read<CategoryUnifiedService>();
    await categoryService.loadMerchantCategories('merchant_sample_123', country: 'السعودية');
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
            _buildSearchBar(),
            Expanded(
              child: _buildCategoriesList(),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9A46D7), Color(0xFF7B1FA2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
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
              'إدارة الأقسام',
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
              Icons.settings,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          'أقسام الخدمات',
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
                          'أقسام المنتجات',
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
            _buildStatisticsCard(categoryService),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CategoryCardWidget(
                      category: category,
                      onEdit: () => _editCategory(category),
                      onDelete: () => _deleteCategory(category),
                      onToggleStatus: () => _toggleStatus(category),
                      onToggleFeatured: () => _toggleFeatured(category),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatisticsCard(CategoryUnifiedService categoryService) {
    final stats = categoryService.getCategoryStatistics();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF9A46D7).withOpacity(0.1), Colors.white],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9A46D7).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem(
                'إجمالي الأقسام',
                stats['totalCategories'].toString(),
                Icons.category,
                const Color(0xFF9A46D7),
              ),
              _buildStatItem(
                'الأقسام النشطة',
                stats['activeCategories'].toString(),
                Icons.check_circle,
                const Color(0xFF4CAF50),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                'أقسام مميزة',
                stats['featuredCategories'].toString(),
                Icons.star,
                const Color(0xFFFF9800),
              ),
              _buildStatItem(
                categoryService.currentTab == CategoryType.product ? 'إجمالي المنتجات' : 'إجمالي الخدمات',
                (categoryService.currentTab == CategoryType.product 
                    ? stats['totalProducts'] 
                    : stats['totalServices']).toString(),
                categoryService.currentTab == CategoryType.product ? Icons.inventory_2 : Icons.build,
                const Color(0xFF2196F3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EBEF)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF1D2035),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 12,
                color: Color(0xFF637D92),
              ),
              textAlign: TextAlign.center,
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
                    ? 'لا توجد أقسام منتجات بعد'
                    : 'لا توجد أقسام خدمات بعد',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Color(0xFF1D2035),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                categoryService.currentTab == CategoryType.product 
                    ? 'ابدأ بإضافة أول قسم منتجات لمتجرك'
                    : 'ابدأ بإضافة أول قسم خدمات لمتجرك',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  color: Color(0xFF637D92),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _addCategory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9A46D7), Color(0xFF7B1FA2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9A46D7).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'إضافة قسم جديد',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
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
          Text(
            'حدث خطأ',
            style: const TextStyle(
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

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _addCategory,
      backgroundColor: const Color(0xFF9A46D7),
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

  void _addCategory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCategoryPage(),
      ),
    ).then((_) => _loadData());
  }

  void _editCategory(CategoryUnifiedModel category) {
    // TODO: Navigate to edit category page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة صفحة تعديل القسم قريباً'),
        backgroundColor: Color(0xFF9A46D7),
      ),
    );
  }

  void _deleteCategory(CategoryUnifiedModel category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف القسم',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف قسم "${category.name}"؟\nسيتم حذف جميع المنتجات/الخدمات في هذا القسم.',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                color: Color(0xFF637D92),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                color: Color(0xFFE32B3D),
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final categoryService = context.read<CategoryUnifiedService>();
      final success = await categoryService.deleteCategory(category.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف القسم بنجاح'),
            backgroundColor: Color(0xFF20C9AC),
          ),
        );
      }
    }
  }

  void _toggleStatus(CategoryUnifiedModel category) async {
    final categoryService = context.read<CategoryUnifiedService>();
    final success = await categoryService.toggleCategoryStatus(category.id);
    
    if (success && mounted) {
      final newStatus = category.status == CategoryStatus.active ? 'تم إيقاف' : 'تم تفعيل';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$newStatus القسم بنجاح'),
          backgroundColor: const Color(0xFF20C9AC),
        ),
      );
    }
  }

  void _toggleFeatured(CategoryUnifiedModel category) async {
    final categoryService = context.read<CategoryUnifiedService>();
    final success = await categoryService.toggleFeaturedStatus(category.id);
    
    if (success && mounted) {
      final newStatus = category.isFeatured ? 'تم إزالة القسم من المميزة' : 'تم إضافة القسم للمميزة';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus),
          backgroundColor: const Color(0xFF20C9AC),
        ),
      );
    }
  }
}
