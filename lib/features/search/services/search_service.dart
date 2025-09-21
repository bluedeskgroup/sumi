import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/search/models/search_result_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<SearchResult>> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Split the user's query into individual words, sanitize them, and convert to lower case.
    final searchTerms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
        
    if (searchTerms.isEmpty) {
      return [];
    }

    // Firestore 'array-contains-any' can handle up to 10 items in the list.
    final limitedSearchTerms =
        searchTerms.length > 10 ? searchTerms.sublist(0, 10) : searchTerms;

    // Search for users
    final usersFuture = _firestore
        .collection('users')
        .where('searchKeywords', arrayContainsAny: limitedSearchTerms)
        .get();

    // Search for posts
    final postsFuture = _firestore
        .collection('posts')
        .where('searchKeywords', arrayContainsAny: limitedSearchTerms)
        .get();

    // Search for products
    final productsFuture = _firestore
        .collection('products')
        .where('searchKeywords', arrayContainsAny: limitedSearchTerms)
        .get();

    // Search for service providers
    final serviceProvidersFuture = _firestore
        .collection('serviceProviders')
        .where('searchKeywords', arrayContainsAny: limitedSearchTerms)
        .get();


    final results = await Future.wait([usersFuture, postsFuture, productsFuture, serviceProvidersFuture]);
    final List<SearchResult> searchResults = [];

    // Use a Set to avoid duplicate results if a document matches multiple search terms.
    final Set<String> processedIds = {};

    // Process user results
    final userDocs = (results[0] as QuerySnapshot).docs;
    for (var doc in userDocs) {
      if (processedIds.add(doc.id)) {
        final data = doc.data() as Map<String, dynamic>;
        searchResults.add(SearchResult(
          id: doc.id,
          title: data['userName'] ?? 'اسم غير معروف',
          imageUrl: data['userImage'],
          type: SearchResultType.user,
          originalDocument: doc,
        ));
      }
    }

    // Process post results
    final postDocs = (results[1] as QuerySnapshot).docs;
    for (var doc in postDocs) {
      if (processedIds.add(doc.id)) {
        final data = doc.data() as Map<String, dynamic>;
        searchResults.add(SearchResult(
          id: doc.id,
          title: data['content'] ?? 'محتوى غير متوفر',
          subtitle: data['userName'] ?? 'مستخدم غير معروف',
          imageUrl: data['userImage'],
          type: SearchResultType.post,
          originalDocument: doc,
        ));
      }
    }
    
    // Process product results
    final productDocs = (results[2] as QuerySnapshot).docs;
    for (var doc in productDocs) {
      if (processedIds.add(doc.id)) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrls = List<String>.from(data['imageUrls'] ?? []);
        searchResults.add(SearchResult(
          id: doc.id,
          title: data['name'] ?? 'منتج غير معروف',
          subtitle: data['category'] ?? 'فئة غير معروفة',
          imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
          type: SearchResultType.product,
          originalDocument: doc,
        ));
      }
    }

    // Process service provider results
    final serviceProviderDocs = (results[3] as QuerySnapshot).docs;
    for (var doc in serviceProviderDocs) {
      if (processedIds.add(doc.id)) {
        final data = doc.data() as Map<String, dynamic>;
        searchResults.add(SearchResult(
          id: doc.id,
          title: data['name'] ?? 'مقدم خدمة غير معروف',
          subtitle: data['category'] ?? 'فئة غير معروفة',
          imageUrl: data['imageUrl'],
          type: SearchResultType.serviceProvider,
          originalDocument: doc,
        ));
      }
    }

    return searchResults;
  }
} 