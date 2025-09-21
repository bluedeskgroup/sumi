import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/product_variant_model.dart';

class ProductVariantService extends ChangeNotifier {
  static final ProductVariantService _instance = ProductVariantService._internal();
  static ProductVariantService get instance => _instance;
  ProductVariantService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  List<ProductVariantModel> _variants = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  List<ProductVariantModel> _filteredVariants = [];

  // Getters
  List<ProductVariantModel> get variants => _filteredVariants;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  // Collection reference
  CollectionReference get _variantsCollection => 
      _firestore.collection('product_variants');

  /// Load variants for a specific product
  Future<void> loadProductVariants(String productId) async {
    try {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _isLoading = true;
        _errorMessage = '';
        notifyListeners();
      });

      final querySnapshot = await _variantsCollection
          .where('productId', isEqualTo: productId)
          .get();

      _variants = querySnapshot.docs
          .map((doc) => ProductVariantModel.fromFirestore(doc))
          .toList();

      // Sort by creation date
      _variants.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // If no variants exist, create sample data
      if (_variants.isEmpty) {
        try {
          await _createSampleVariants(productId);
        } catch (e) {
          debugPrint('Failed to create sample variants: $e');
        }
        // Set sample data locally for immediate display
        _variants = ProductVariantSampleData.getSampleVariants(productId);
      }

      _applySearchFilter();
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحميل اختيارات المنتج: $e';
      debugPrint('Error loading product variants: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Add new variant
  Future<bool> addVariant(ProductVariantModel variant) async {
    try {
      _isLoading = true;

      final docRef = _variantsCollection.doc();
      final variantWithId = variant.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(variantWithId.toMap());

      // Update local state
      _variants.insert(0, variantWithId);
      _applySearchFilter();
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في إضافة الاختيار: $e';
      debugPrint('Error adding variant: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Update existing variant
  Future<bool> updateVariant(ProductVariantModel variant) async {
    try {
      _isLoading = true;

      final updatedVariant = variant.copyWith(updatedAt: DateTime.now());
      await _variantsCollection.doc(variant.id).update(updatedVariant.toMap());

      // Update local state
      final index = _variants.indexWhere((v) => v.id == variant.id);
      if (index != -1) {
        _variants[index] = updatedVariant;
      }

      _applySearchFilter();
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في تحديث الاختيار: $e';
      debugPrint('Error updating variant: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Delete variant
  Future<bool> deleteVariant(String variantId) async {
    try {
      _isLoading = true;

      await _variantsCollection.doc(variantId).delete();

      // Update local state
      _variants.removeWhere((variant) => variant.id == variantId);

      _applySearchFilter();
      _isLoading = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'فشل في حذف الاختيار: $e';
      debugPrint('Error deleting variant: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Update variant availability
  Future<bool> updateVariantAvailability(String variantId, bool isAvailable) async {
    try {
      await _variantsCollection.doc(variantId).update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local state
      final index = _variants.indexWhere((v) => v.id == variantId);
      if (index != -1) {
        _variants[index] = _variants[index].copyWith(
          isAvailable: isAvailable,
          updatedAt: DateTime.now(),
        );
      }

      _applySearchFilter();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'فشل في تحديث حالة الاختيار: $e';
      debugPrint('Error updating variant availability: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Update variant quantity
  Future<bool> updateVariantQuantity(String variantId, int quantity) async {
    try {
      await _variantsCollection.doc(variantId).update({
        'quantity': quantity,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update local state
      final index = _variants.indexWhere((v) => v.id == variantId);
      if (index != -1) {
        _variants[index] = _variants[index].copyWith(
          quantity: quantity,
          updatedAt: DateTime.now(),
        );
      }

      _applySearchFilter();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return true;
    } catch (e) {
      _errorMessage = 'فشل في تحديث كمية الاختيار: $e';
      debugPrint('Error updating variant quantity: $e');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return false;
    }
  }

  /// Create sample variants for testing
  Future<void> _createSampleVariants(String productId) async {
    try {
      final batch = _firestore.batch();
      final sampleVariants = ProductVariantSampleData.getSampleVariants(productId);

      for (final variant in sampleVariants) {
        final docRef = _variantsCollection.doc();
        final variantWithId = variant.copyWith(id: docRef.id);
        batch.set(docRef, variantWithId.toMap());
      }

      await batch.commit();
      debugPrint('Sample variant data created successfully');
    } catch (e) {
      debugPrint('Error creating sample variants: $e');
      rethrow;
    }
  }

  /// Search variants
  void searchVariants(String query) {
    _searchQuery = query.toLowerCase();
    _applySearchFilter();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Apply search filter
  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredVariants = List.from(_variants);
    } else {
      _filteredVariants = _variants.where((variant) =>
          variant.name.toLowerCase().contains(_searchQuery) ||
          variant.color.toLowerCase().contains(_searchQuery) ||
          variant.size.toLowerCase().contains(_searchQuery) ||
          variant.brand.toLowerCase().contains(_searchQuery)
      ).toList();
    }
  }

  /// Get variant statistics
  Map<String, dynamic> getVariantStatistics() {
    final totalVariants = _variants.length;
    final availableVariants = _variants.where((v) => v.isAvailable).length;
    final inStockVariants = _variants.where((v) => v.isInStock).length;
    final outOfStockVariants = _variants.where((v) => v.quantity == 0).length;
    final totalQuantity = _variants.fold<int>(0, (sum, v) => sum + v.quantity);

    return {
      'totalVariants': totalVariants,
      'availableVariants': availableVariants,
      'inStockVariants': inStockVariants,
      'outOfStockVariants': outOfStockVariants,
      'totalQuantity': totalQuantity,
      'averagePrice': totalVariants > 0 
          ? _variants.fold<double>(0, (sum, v) => sum + v.price) / totalVariants
          : 0.0,
    };
  }

  /// Clear error message
  void clearError() {
    _errorMessage = '';
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Refresh data
  Future<void> refresh(String productId) async {
    await loadProductVariants(productId);
  }
}
