import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/product_model.dart';

class MerchantProductService extends ChangeNotifier {
  static final MerchantProductService _instance = MerchantProductService._internal();
  static MerchantProductService get instance => _instance;
  MerchantProductService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ProductModel> _products = [];
  List<ProductModel> _services = [];
  List<ProductModel> _filteredProducts = [];
  List<ProductModel> _filteredServices = [];
  bool _isLoading = false;
  String _errorMessage = '';
  ProductType _currentTab = ProductType.product;
  String _searchQuery = '';

  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get services => _services;
  List<ProductModel> get filteredProducts => _filteredProducts;
  List<ProductModel> get filteredServices => _filteredServices;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  ProductType get currentTab => _currentTab;
  String get searchQuery => _searchQuery;

  List<ProductModel> get currentItems => 
      _currentTab == ProductType.product ? _filteredProducts : _filteredServices;

  // Collection references
  CollectionReference get _productsCollection => 
      _firestore.collection('merchant_products');

  /// Load merchant products and services
  Future<void> loadMerchantProducts(String merchantId) async {
    try {
      // Don't set loading state during build
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _isLoading = true;
        _errorMessage = '';
        notifyListeners();
      });
      
      // Use a simpler query without orderBy to avoid index requirement
      final querySnapshot = await _productsCollection
          .where('merchantId', isEqualTo: merchantId)
          .get();

      final List<ProductModel> allItems = querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      // Sort items locally by updatedAt in descending order
      allItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      _products = allItems.where((item) => item.type == ProductType.product).toList();
      _services = allItems.where((item) => item.type == ProductType.service).toList();

      // If no products exist, create sample data
      if (_products.isEmpty && _services.isEmpty) {
        try {
          await _createSampleData(merchantId);
        } catch (e) {
          debugPrint('Failed to create sample data in Firestore: $e');
          // Continue with local sample data even if Firebase save fails
        }
        // Set sample data locally for immediate display
        _products = ProductSampleData.getSampleProducts(merchantId);
        _services = ProductSampleData.getSampleServices(merchantId);
      }

      _applySearchFilter();
      _isLoading = false;
      // Schedule notification after the current frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحميل المنتجات: $e';
      debugPrint('Error loading merchant products: $e');
      // Schedule notification after the current frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Create sample data for testing
  Future<void> _createSampleData(String merchantId) async {
    try {
      final batch = _firestore.batch();

      // Add sample products
      final sampleProducts = ProductSampleData.getSampleProducts(merchantId);
      for (final product in sampleProducts) {
        final docRef = _productsCollection.doc();
        batch.set(docRef, product.copyWith(id: docRef.id).toMap());
      }

      // Add sample services
      final sampleServices = ProductSampleData.getSampleServices(merchantId);
      for (final service in sampleServices) {
        final docRef = _productsCollection.doc();
        batch.set(docRef, service.copyWith(id: docRef.id).toMap());
      }

      await batch.commit();
      debugPrint('Sample product data created successfully');
    } catch (e) {
      debugPrint('Error creating sample product data: $e');
    }
  }

  /// Add new product or service
  Future<bool> addProduct(ProductModel product) async {
    try {
      _isLoading = true;

      final docRef = _productsCollection.doc();
      final productWithId = product.copyWith(
        id: docRef.id,
        updatedAt: DateTime.now(),
      );

      await docRef.set(productWithId.toMap());

      if (product.type == ProductType.product) {
        _products.insert(0, productWithId);
      } else {
        _services.insert(0, productWithId);
      }

      _applySearchFilter();
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في إضافة المنتج: $e';
      debugPrint('Error adding product: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Update existing product
  Future<bool> updateProduct(ProductModel product) async {
    try {
      _isLoading = true;

      final updatedProduct = product.copyWith(updatedAt: DateTime.now());
      await _productsCollection.doc(product.id).update(updatedProduct.toMap());

      final targetList = product.type == ProductType.product ? _products : _services;
      final index = targetList.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        targetList[index] = updatedProduct;
      }

      _applySearchFilter();
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحديث المنتج: $e';
      debugPrint('Error updating product: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String productId, ProductType type) async {
    try {
      _isLoading = true;

      await _productsCollection.doc(productId).delete();

      final targetList = type == ProductType.product ? _products : _services;
      targetList.removeWhere((product) => product.id == productId);

      _applySearchFilter();
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في حذف المنتج: $e';
      debugPrint('Error deleting product: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Update product status
  Future<bool> updateProductStatus(String productId, ProductType type, ProductStatus status) async {
    try {
      await _productsCollection.doc(productId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final targetList = type == ProductType.product ? _products : _services;
      final index = targetList.indexWhere((p) => p.id == productId);
      if (index != -1) {
        targetList[index] = targetList[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
      }

      _applySearchFilter();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'فشل في تحديث حالة المنتج: $e';
      debugPrint('Error updating product status: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Update product quantity
  Future<bool> updateProductQuantity(String productId, int newQuantity) async {
    try {
      await _productsCollection.doc(productId).update({
        'quantity': newQuantity,
        'status': newQuantity > 0 ? ProductStatus.active.name : ProductStatus.outOfStock.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          quantity: newQuantity,
          status: newQuantity > 0 ? ProductStatus.active : ProductStatus.outOfStock,
          updatedAt: DateTime.now(),
        );
      }

      _applySearchFilter();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'فشل في تحديث كمية المنتج: $e';
      debugPrint('Error updating product quantity: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Get product statistics
  Map<String, dynamic> getProductStatistics() {
    final totalProducts = _products.length;
    final totalServices = _services.length;
    final activeProducts = _products.where((p) => p.status == ProductStatus.active).length;
    final activeServices = _services.where((s) => s.status == ProductStatus.active).length;
    final outOfStockProducts = _products.where((p) => p.status == ProductStatus.outOfStock).length;

    final totalSales = [..._products, ..._services]
        .fold<double>(0, (sum, item) => sum + (item.discountedPrice * item.soldCount));

    final totalSoldItems = [..._products, ..._services]
        .fold<int>(0, (sum, item) => sum + item.soldCount);

    final averageSalesRate = [..._products, ..._services].isNotEmpty
        ? [..._products, ..._services]
            .fold<double>(0, (sum, item) => sum + item.salesRate) / 
          [..._products, ..._services].length
        : 0.0;

    return {
      'totalProducts': totalProducts,
      'totalServices': totalServices,
      'activeProducts': activeProducts,
      'activeServices': activeServices,
      'outOfStockProducts': outOfStockProducts,
      'totalSales': totalSales,
      'totalSoldItems': totalSoldItems,
      'averageSalesRate': averageSalesRate,
    };
  }

  /// Search products and services
  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    _applySearchFilter();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Apply search filter
  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
      _filteredServices = List.from(_services);
    } else {
      _filteredProducts = _products.where((product) =>
          product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery) ||
          product.category.toLowerCase().contains(_searchQuery) ||
          product.color.toLowerCase().contains(_searchQuery)
      ).toList();

      _filteredServices = _services.where((service) =>
          service.name.toLowerCase().contains(_searchQuery) ||
          service.description.toLowerCase().contains(_searchQuery) ||
          service.category.toLowerCase().contains(_searchQuery)
      ).toList();
    }
  }

  /// Switch between products and services tab
  void switchTab(ProductType tab) {
    _currentTab = tab;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Refresh data
  Future<void> refresh(String merchantId) async {
    await loadMerchantProducts(merchantId);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
