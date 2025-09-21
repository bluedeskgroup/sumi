import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../../merchant/models/product_model.dart';

class UserProductService extends ChangeNotifier {
  static final UserProductService _instance = UserProductService._internal();
  static UserProductService get instance => _instance;
  UserProductService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _allServices = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _filteredServices = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _userCountry = 'السعودية'; // Default country
  String _searchQuery = '';
  String _selectedCategory = '';

  // Getters
  List<ProductModel> get allProducts => _allProducts;
  List<ProductModel> get allServices => _allServices;
  List<ProductModel> get filteredProducts => _filteredProducts;
  List<ProductModel> get filteredServices => _filteredServices;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get userCountry => _userCountry;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Collection reference
  CollectionReference get _productsCollection => 
      _firestore.collection('merchant_products');

  /// Set user country
  void setUserCountry(String country) {
    _userCountry = country;
    _applyFilters();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Load all products and services available for user's country
  Future<void> loadProductsForCountry(String userCountry) async {
    try {
      _setLoadingState(true);
      _userCountry = userCountry;

      // Query products for user's country
      final querySnapshot = await _productsCollection
          .where('country', isEqualTo: userCountry)
          .where('status', isEqualTo: 'active') // Only active products
          .get();

      final products = <ProductModel>[];
      final services = <ProductModel>[];

      for (var doc in querySnapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);
          
          if (product.type == ProductType.product) {
            products.add(product);
          } else {
            services.add(product);
          }
        } catch (e) {
          debugPrint('Error parsing product ${doc.id}: $e');
        }
      }

      // Sort by creation date (newest first)
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      services.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _allProducts = products;
      _allServices = services;
      
      _applyFilters();
      _setLoadingState(false);

    } catch (e) {
      debugPrint('Error loading products for country: $e');
      _errorMessage = 'حدث خطأ في تحميل المنتجات: $e';
      _setLoadingState(false);
      
      // Fallback to sample data if Firebase fails
      _loadSampleData();
    }
  }

  /// Search products and services
  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _applyFilters();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Apply search and category filters
  void _applyFilters() {
    _filteredProducts = _allProducts.where((product) {
      // Check search query
      bool matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery) ||
          product.color.toLowerCase().contains(_searchQuery);

      // Check category filter
      bool matchesCategory = _selectedCategory.isEmpty ||
          product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    _filteredServices = _allServices.where((service) {
      // Check search query
      bool matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery) ||
          service.description.toLowerCase().contains(_searchQuery) ||
          service.category.toLowerCase().contains(_searchQuery);

      // Check category filter
      bool matchesCategory = _selectedCategory.isEmpty ||
          service.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
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

  /// Load sample data as fallback
  void _loadSampleData() {
    try {
      // Create sample products for user's country
      _allProducts = [
        ProductModel(
          id: 'sample_prod_1',
          merchantId: 'merchant_sample_123',
          name: 'نظارات قراءة عصرية للسيدات',
          description: 'نظارات عالية الجودة مناسبة للقراءة اليومية',
          images: ['assets/images/products/glasses1.png'],
          originalPrice: 490.0,
          discountedPrice: 450.0,
          discount: 8.2,
          color: 'اخضر',
          size: '50 سم',
          quantity: 10,
          soldCount: 156,
          salesRate: 16.0,
          type: ProductType.product,
          status: ProductStatus.active,
          category: 'نظارات',
          tags: ['نظارات', 'قراءة', 'سيدات'],
          country: _userCountry,
        ),
        ProductModel(
          id: 'sample_prod_2',
          merchantId: 'merchant_sample_123',
          name: 'سماعات بلوتوث لاسلكية',
          description: 'سماعات عالية الجودة مع تقنية إلغاء الضوضاء',
          images: ['assets/images/products/glasses2-6a9524.png'],
          originalPrice: 299.0,
          discountedPrice: 249.0,
          discount: 16.7,
          color: 'أسود',
          size: 'واحد',
          quantity: 25,
          soldCount: 89,
          salesRate: 12.5,
          type: ProductType.product,
          status: ProductStatus.active,
          category: 'إلكترونيات',
          tags: ['سماعات', 'بلوتوث', 'لاسلكي'],
          country: _userCountry,
        ),
      ];

      _allServices = [
        ProductModel(
          id: 'sample_serv_1',
          merchantId: 'merchant_sample_456',
          name: 'خدمة التوصيل السريع',
          description: 'خدمة توصيل سريعة وموثوقة لجميع أنحاء المدينة',
          images: ['assets/images/services/delivery.png'],
          originalPrice: 25.0,
          discountedPrice: 20.0,
          discount: 20.0,
          color: '',
          size: '',
          quantity: 100,
          soldCount: 245,
          salesRate: 24.8,
          type: ProductType.service,
          status: ProductStatus.active,
          category: 'خدمات توصيل',
          tags: ['توصيل', 'سريع', 'موثوق'],
          country: _userCountry,
        ),
      ];

      _applyFilters();
      _setLoadingState(false);

    } catch (e) {
      debugPrint('Error loading sample data: $e');
    }
  }

  /// Get available categories for current country
  List<String> getAvailableCategories() {
    Set<String> categories = {};
    
    for (var product in _allProducts) {
      if (product.category.isNotEmpty) {
        categories.add(product.category);
      }
    }
    
    for (var service in _allServices) {
      if (service.category.isNotEmpty) {
        categories.add(service.category);
      }
    }
    
    return categories.toList()..sort();
  }

  /// Get products by merchant ID
  List<ProductModel> getProductsByMerchant(String merchantId) {
    return _filteredProducts.where((product) => 
        product.merchantId == merchantId).toList();
  }

  /// Get services by merchant ID
  List<ProductModel> getServicesByMerchant(String merchantId) {
    return _filteredServices.where((service) => 
        service.merchantId == merchantId).toList();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadProductsForCountry(_userCountry);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
