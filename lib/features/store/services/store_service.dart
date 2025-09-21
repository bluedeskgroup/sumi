import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/store/models/category_model.dart';
import 'package:sumi/features/store/models/product_model.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // A method to fetch all products from the 'products' collection
  Future<List<Product>> getProducts({int? limit}) async {
    try {
      Query query = _firestore
          .collection('products')
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // A method to fetch a single product by its ID
  Future<Product?> getProductById(String productId) async {
    try {
      final docSnapshot = await _firestore.collection('products').doc(productId).get();
      if (docSnapshot.exists) {
        return Product.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // A method to fetch all categories from the 'categories' collection
  Stream<List<Category>> getCategories() {
    return _firestore
        .collection('categories')
        .where('type', isEqualTo: 'product')
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();
    });
  }

  // A method to fetch products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: categoryId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
 