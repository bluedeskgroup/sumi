import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sumi/features/services/models/review_model.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final List<String> imageUrls;
  final List<int> colors; // Stored as integer ARGB values
  final List<String> sizes;
  final List<Review> reviews;
  final String category;
  final String merchantId;
  final String merchantName;
  final Timestamp createdAt;
  final int stock;
  final List<String> searchKeywords;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.imageUrls,
    this.colors = const [],
    this.sizes = const [],
    this.reviews = const [],
    required this.category,
    required this.merchantId,
    required this.merchantName,
    required this.createdAt,
    this.stock = 1,
    this.searchKeywords = const [],
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // The 'reviews' field is likely a list of sub-collection documents,
    // which need to be fetched separately. For now, we'll initialize it as empty.
    // A proper implementation would fetch this data from a sub-collection.

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      oldPrice: (data['oldPrice'])?.toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      colors: List<int>.from(data['colors'] ?? []),
      sizes: List<String>.from(data['sizes'] ?? []),
      reviews: [], // Placeholder
      category: data['category'] ?? '',
      merchantId: data['merchantId'] ?? '',
      merchantName: data['merchantName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      stock: data['stock'] ?? 1,
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'oldPrice': oldPrice,
      'imageUrls': imageUrls,
      'colors': colors,
      'sizes': sizes,
      // Reviews are typically stored as a sub-collection, not a field.
      'category': category,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'createdAt': createdAt,
      'stock': stock,
      'searchKeywords': searchKeywords,
    };
  }
} 