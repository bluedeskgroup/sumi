import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/category_unified_model.dart';
import '../models/product_model.dart';

class CategoryUnifiedService extends ChangeNotifier {
  static final CategoryUnifiedService _instance = CategoryUnifiedService._internal();
  static CategoryUnifiedService get instance => _instance;
  CategoryUnifiedService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CategoryUnifiedModel> _categories = [];
  List<CategoryUnifiedModel> _filteredCategories = [];
  bool _isLoading = false;
  String _errorMessage = '';
  CategoryType _currentTab = CategoryType.product;
  String _searchQuery = '';

  // Getters
  List<CategoryUnifiedModel> get categories => _categories;
  List<CategoryUnifiedModel> get filteredCategories => _filteredCategories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  CategoryType get currentTab => _currentTab;
  String get searchQuery => _searchQuery;

  List<CategoryUnifiedModel> get currentCategories => 
      _filteredCategories.where((cat) => cat.type == _currentTab).toList();

  // Collection reference
  CollectionReference get _categoriesCollection => 
      _firestore.collection('merchant_categories');

  /// Load merchant categories
  Future<void> loadMerchantCategories(String merchantId, {String? country}) async {
    try {
      _setLoadingState(true);

      Query query = _categoriesCollection
          .where('merchantId', isEqualTo: merchantId);
      
      if (country != null) {
        query = query.where('country', isEqualTo: country);
      }

      final querySnapshot = await query.get();

      final List<CategoryUnifiedModel> allCategories = querySnapshot.docs
          .map((doc) => CategoryUnifiedModel.fromFirestore(doc))
          .toList();

      // Sort by sortOrder
      allCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      _categories = allCategories;

      // If no categories exist, create sample data
      if (_categories.isEmpty) {
        await _createSampleData(merchantId, country ?? 'السعودية');
        _categories = CategorySampleData.getSampleCategories(merchantId, country ?? 'السعودية');
      }

      // Update product/service counts
      await _updateCategoryCounts(merchantId);

      _applyFilters();
      _setLoadingState(false);

    } catch (e) {
      debugPrint('Error loading merchant categories: $e');
      _errorMessage = 'حدث خطأ في تحميل الأقسام: $e';
      _setLoadingState(false);
      
      // Fallback to sample data
      _categories = CategorySampleData.getSampleCategories(merchantId, country ?? 'السعودية');
      _applyFilters();
    }
  }

  /// Load categories for user (public categories)
  Future<void> loadCategoriesForUser(String country) async {
    try {
      _setLoadingState(true);

      final querySnapshot = await _categoriesCollection
          .where('country', isEqualTo: country)
          .where('status', isEqualTo: 'active')
          .get();

      final List<CategoryUnifiedModel> allCategories = querySnapshot.docs
          .map((doc) => CategoryUnifiedModel.fromFirestore(doc))
          .toList();

      // Sort by sortOrder and featured first
      allCategories.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });

      _categories = allCategories;
      _applyFilters();
      _setLoadingState(false);

    } catch (e) {
      debugPrint('Error loading categories for user: $e');
      _errorMessage = 'حدث خطأ في تحميل الأقسام';
      _setLoadingState(false);
    }
  }

  /// Add new category
  Future<bool> addCategory(CategoryUnifiedModel category) async {
    try {
      _setLoadingState(true);

      final docRef = _categoriesCollection.doc();
      final categoryWithId = category.copyWith(
        id: docRef.id,
        updatedAt: DateTime.now(),
      );

      await docRef.set(categoryWithId.toMap());

      _categories.insert(0, categoryWithId);
      _applyFilters();
      _setLoadingState(false);

      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      debugPrint('Error adding category: $e');
      _errorMessage = 'فشل في إضافة القسم: $e';
      _setLoadingState(false);
      return false;
    }
  }

  /// Update category
  Future<bool> updateCategory(CategoryUnifiedModel category) async {
    try {
      _setLoadingState(true);

      final updatedCategory = category.copyWith(updatedAt: DateTime.now());
      await _categoriesCollection.doc(category.id).update(updatedCategory.toMap());

      final index = _categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        _applyFilters();
      }

      _setLoadingState(false);

      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      debugPrint('Error updating category: $e');
      _errorMessage = 'فشل في تحديث القسم: $e';
      _setLoadingState(false);
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      _setLoadingState(true);

      await _categoriesCollection.doc(categoryId).delete();

      _categories.removeWhere((cat) => cat.id == categoryId);
      _applyFilters();
      _setLoadingState(false);

      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      _errorMessage = 'فشل في حذف القسم: $e';
      _setLoadingState(false);
      return false;
    }
  }

  /// Toggle category status
  Future<bool> toggleCategoryStatus(String categoryId) async {
    try {
      final category = _categories.firstWhere((cat) => cat.id == categoryId);
      final newStatus = category.status == CategoryStatus.active 
          ? CategoryStatus.inactive 
          : CategoryStatus.active;

      return await updateCategory(category.copyWith(status: newStatus));
    } catch (e) {
      debugPrint('Error toggling category status: $e');
      return false;
    }
  }

  /// Toggle featured status
  Future<bool> toggleFeaturedStatus(String categoryId) async {
    try {
      final category = _categories.firstWhere((cat) => cat.id == categoryId);
      return await updateCategory(category.copyWith(isFeatured: !category.isFeatured));
    } catch (e) {
      debugPrint('Error toggling featured status: $e');
      return false;
    }
  }

  /// Update categories order
  Future<bool> updateCategoriesOrder(List<CategoryUnifiedModel> categories) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < categories.length; i++) {
        final categoryRef = _categoriesCollection.doc(categories[i].id);
        final updatedCategory = categories[i].copyWith(
          sortOrder: i,
          updatedAt: DateTime.now(),
        );
        batch.update(categoryRef, updatedCategory.toMap());
      }

      await batch.commit();

      // Update local state
      _categories = categories;
      _applyFilters();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      return true;
    } catch (e) {
      debugPrint('Error updating categories order: $e');
      return false;
    }
  }

  /// Search categories
  void searchCategories(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Switch between product and service categories
  void switchTab(CategoryType tab) {
    _currentTab = tab;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Get categories by type
  List<CategoryUnifiedModel> getCategoriesByType(CategoryType type) {
    return _categories.where((cat) => cat.type == type && cat.status == CategoryStatus.active).toList();
  }

  /// Get featured categories
  List<CategoryUnifiedModel> getFeaturedCategories() {
    return _categories.where((cat) => cat.isFeatured && cat.status == CategoryStatus.active).toList();
  }

  /// Get category by ID
  CategoryUnifiedModel? getCategoryById(String categoryId) {
    try {
      return _categories.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Apply search filter
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredCategories = List.from(_categories);
    } else {
      _filteredCategories = _categories.where((category) =>
          category.name.toLowerCase().contains(_searchQuery) ||
          category.nameEn.toLowerCase().contains(_searchQuery) ||
          category.description.toLowerCase().contains(_searchQuery) ||
          category.tags.any((tag) => tag.toLowerCase().contains(_searchQuery))
      ).toList();
    }
  }

  /// Set loading state
  void _setLoadingState(bool loading) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _isLoading = loading;
      if (loading) {
        _errorMessage = '';
      }
      notifyListeners();
    });
  }

  /// Update category counts based on products/services
  Future<void> _updateCategoryCounts(String merchantId) async {
    try {
      final productsSnapshot = await _firestore
          .collection('merchant_products')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'active')
          .get();

      // Count products and services by category
      Map<String, Map<String, int>> categoryCounts = {};

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? '';
        final type = data['type'] ?? 'product';

        if (category.isNotEmpty) {
          categoryCounts[category] ??= {'product': 0, 'service': 0};
          categoryCounts[category]![type] = (categoryCounts[category]![type] ?? 0) + 1;
        }
      }

      // Update categories with counts
      for (int i = 0; i < _categories.length; i++) {
        final categoryName = _categories[i].name;
        final counts = categoryCounts[categoryName];
        if (counts != null) {
          _categories[i] = _categories[i].copyWith(
            productCount: counts['product'] ?? 0,
            serviceCount: counts['service'] ?? 0,
          );
        }
      }

    } catch (e) {
      debugPrint('Error updating category counts: $e');
    }
  }

  /// Create sample data
  Future<void> _createSampleData(String merchantId, String country) async {
    try {
      final sampleCategories = CategorySampleData.getSampleCategories(merchantId, country);
      
      final batch = _firestore.batch();
      for (var category in sampleCategories) {
        final docRef = _categoriesCollection.doc(category.id);
        batch.set(docRef, category.toMap());
      }
      
      await batch.commit();
      debugPrint('Sample category data created successfully');
    } catch (e) {
      debugPrint('Error creating sample category data: $e');
    }
  }

  /// Upload category image
  Future<String?> uploadCategoryImage(XFile imageFile, String categoryId) async {
    try {
      // This would implement image upload to Firebase Storage
      // For now, return a placeholder URL
      return 'https://via.placeholder.com/300x200?text=${categoryId}';
    } catch (e) {
      debugPrint('Error uploading category image: $e');
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Refresh categories
  Future<void> refresh(String merchantId, {String? country}) async {
    await loadMerchantCategories(merchantId, country: country);
  }

  /// Get category statistics
  Map<String, dynamic> getCategoryStatistics() {
    final totalCategories = _categories.length;
    final activeCategories = _categories.where((cat) => cat.status == CategoryStatus.active).length;
    final featuredCategories = _categories.where((cat) => cat.isFeatured).length;
    final productCategories = _categories.where((cat) => cat.type == CategoryType.product).length;
    final serviceCategories = _categories.where((cat) => cat.type == CategoryType.service).length;
    final totalProducts = _categories.fold(0, (sum, cat) => sum + cat.productCount);
    final totalServices = _categories.fold(0, (sum, cat) => sum + cat.serviceCount);

    return {
      'totalCategories': totalCategories,
      'activeCategories': activeCategories,
      'featuredCategories': featuredCategories,
      'productCategories': productCategories,
      'serviceCategories': serviceCategories,
      'totalProducts': totalProducts,
      'totalServices': totalServices,
    };
  }
}
