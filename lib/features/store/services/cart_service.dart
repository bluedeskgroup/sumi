import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumi/features/store/models/cart_item_model.dart';
import 'package:sumi/features/store/models/product_model.dart';

class CartService with ChangeNotifier {
  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() {
    return _instance;
  }
  CartService._internal();

  final List<CartItem> _items = [];
  bool _isInitialized = false;

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('cart_ids') ?? [];
      final quantities = prefs.getStringList('cart_quantities') ?? [];
      if (ids.length == quantities.length) {
        // Can't reconstruct full Product objects here without a repository.
        // We will keep persistence minimal until product reload is designed.
        // For now, just clear any stale storage.
        if (ids.isNotEmpty) {
          await prefs.remove('cart_ids');
          await prefs.remove('cart_quantities');
        }
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = _items.map((e) => e.product.id).toList();
      final quantities = _items.map((e) => e.quantity.toString()).toList();
      await prefs.setStringList('cart_ids', ids);
      await prefs.setStringList('cart_quantities', quantities);
    } catch (_) {}
  }

  void addCartItemAtIndex(int index, CartItem item) {
    _items.insert(index, item);
    notifyListeners();
    _persist();
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    await _ensureInitialized();
    // Check if the product is already in the cart
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      // If it exists, update the quantity
      _items[index].quantity += quantity;
    } else {
      // If not, add it as a new item
      _items.add(CartItem(product: product, quantity: quantity));
    }
    
    // Notify listeners that the cart has changed
    notifyListeners();
    _persist();
  }

  void removeFromCart(CartItem cartItem) {
    _items.remove(cartItem);
    notifyListeners();
    _persist();
  }

  void updateQuantity(CartItem cartItem, int newQuantity) {
    final index = _items.indexOf(cartItem);
    if (index != -1) {
      if (newQuantity > 0) {
        _items[index].quantity = newQuantity;
      } else {
        // If quantity is 0 or less, remove the item
        _items.removeAt(index);
      }
      notifyListeners();
      _persist();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  // الحصول على قائمة التجار في السلة
  List<String> get merchantIds {
    return _items.map((item) => item.product.merchantId).toSet().toList();
  }

  // تجميع المنتجات حسب التاجر
  Map<String, List<CartItem>> get itemsByMerchant {
    final Map<String, List<CartItem>> result = {};
    for (final item in _items) {
      result.putIfAbsent(item.product.merchantId, () => []).add(item);
    }
    return result;
  }

  // الحصول على إجمالي المبلغ لتاجر معين
  double getTotalForMerchant(String merchantId) {
    return _items
        .where((item) => item.product.merchantId == merchantId)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }
} 