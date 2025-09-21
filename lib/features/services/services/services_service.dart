import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/services/models/review_model.dart';
import 'package:sumi/features/services/models/service_provider_model.dart';
import 'package:sumi/features/store/models/category_model.dart';

class ServicesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // This is a static method to provide the list of categories for the UI.
  // In a real-world scenario, this might come from a remote config or a dedicated collection.
  static List<Map<String, String>> getServiceCategories() {
    return [
      {
        'name': 'صالونات التجميل',
        'icon': 'assets/images/services/beauty_salons.png',
        'id': 'beauty_salons'
      },
      {
        'name': 'مراكز التجميل',
        'icon': 'assets/images/services/beauty_centers.png',
        'id': 'beauty_centers'
      },
      {
        'name': 'الخياطة النسائية',
        'icon': 'assets/images/services/tailoring_fashion.png',
        'id': 'tailoring_fashion'
      },
      {
        'name': 'الحنايات',
        'icon': 'assets/images/services/makeup_artists.png', // Placeholder icon
        'id': 'henna_artists'
      },
      {
        'name': 'خدمات منزلية',
        'icon': 'assets/images/services/event_coordinators.png', // Placeholder icon
        'id': 'home_services'
      },
      {
        'name': 'الكوش والزهور',
        'icon': 'assets/images/services/wedding_photographers.png', // Placeholder icon
        'id': 'wedding_services'
      },
      {
        'id': 'event_coordinators',
        'name': 'منظمو الفعاليات',
        'icon': 'assets/images/services/event_coordinators.png'
      },
    ];
  }
  
  // جلب أقسام الخدمات النشطة
  Stream<List<Category>> getDynamicServiceCategories() {
    return _firestore
        .collection('categories')
        .where('type', isEqualTo: 'service')
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();
    });
  }

  // Async version to simulate a network call if needed in the future
  static Future<List<Map<String, String>>> getServiceCategoriesAsync() async {
    // For now, it returns the static list after a short delay
    await Future.delayed(const Duration(milliseconds: 300));
    return getServiceCategories();
  }

  Future<List<ServiceProvider>> getProvidersByCategory(String categoryId) async {
    try {
      final querySnapshot = await _firestore
          .collection('serviceProviders')
          .where('category', isEqualTo: categoryId)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceProvider.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getProviderPortfolio(String providerId, {int limit = 9, DocumentSnapshot? lastDoc}) async {
    try {
      Query query = _firestore
          .collection('serviceProviders')
          .doc(providerId)
          .collection('portfolio')
          .orderBy(FieldPath.documentId) // Order by document ID for consistent pagination
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();

      final imageUrls = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((data) => data['imageUrl'] != null)
          .map((data) => data['imageUrl'] as String)
          .toList();
      
      final newLastDoc = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      return {
        'imageUrls': imageUrls,
        'lastDoc': newLastDoc,
      };

    } catch (e) {
      return {'imageUrls': [], 'lastDoc': null};
    }
  }

  Future<List<Review>> getProviderReviews(String providerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('serviceProviders')
          .doc(providerId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addReview({
    required String providerId,
    required String userId,
    required String userName,
    required String? userImageUrl,
    required double rating,
    required String comment,
  }) async {
    final providerRef = _firestore.collection('serviceProviders').doc(providerId);
    final reviewCollection = providerRef.collection('reviews');

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Create the new review object
        final newReview = Review(
          id: '', // Firestore generates this
          userId: userId,
          userName: userName,
          userAvatarUrl: userImageUrl ?? 'https://via.placeholder.com/150',
          rating: rating,
          comment: comment,
          createdAt: Timestamp.now(),
        );

        // 2. Add the new review
        transaction.set(reviewCollection.doc(), newReview.toFirestore());

        // 3. Get the current provider data
        final providerSnapshot = await transaction.get(providerRef);
        if (!providerSnapshot.exists) {
          throw Exception("Provider not found!");
        }

        // 4. Calculate the new average rating
        final providerData = providerSnapshot.data() as Map<String, dynamic>;
        final currentRating = (providerData['rating'] ?? 0.0).toDouble();
        final reviewCount = providerData['reviewCount'] ?? 0;

        final newReviewCount = reviewCount + 1;
        final newAverageRating =
            ((currentRating * reviewCount) + rating) / newReviewCount;

        // 5. Update the provider's rating
        transaction.update(providerRef, {
          'rating': newAverageRating,
          'reviewCount': newReviewCount,
        });
      });
    } catch (e) {
      rethrow;
    }
  }
} 