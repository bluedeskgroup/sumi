import 'package:flutter/material.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/pages/post_detail_page.dart';
import 'package:sumi/features/search/models/search_result_model.dart';
import 'package:sumi/features/search/services/search_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sumi/features/services/models/service_provider_model.dart';
import 'package:sumi/features/services/presentation/pages/service_provider_profile_page.dart';
import 'package:sumi/features/store/models/product_model.dart';
import 'package:sumi/features/store/presentation/pages/product_detail_page.dart';


class CustomSearchDelegate extends SearchDelegate {
  final SearchService _searchService = SearchService();

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Actions for app bar
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // Leading icon on the left of the app bar
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('ابحث عن منشورات أو مستخدمين'),
      );
    }

    return FutureBuilder<List<SearchResult>>(
      future: _searchService.searchAll(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ أثناء البحث.'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لم يتم العثور على نتائج.'));
        }

        final results = snapshot.data!;

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildResultTile(context, result);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // For simplicity, we can show results directly as suggestions.
    // For a better UX, you might want to show suggestions differently.
    return buildResults(context);
  }

  Widget _buildResultTile(BuildContext context, SearchResult result) {
    IconData icon;
    switch(result.type) {
      case SearchResultType.user:
        icon = Icons.person;
        break;
      case SearchResultType.post:
        icon = Icons.article;
        break;
      case SearchResultType.product:
        icon = Icons.store;
        break;
      case SearchResultType.serviceProvider:
        icon = Icons.design_services;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: result.imageUrl != null
            ? CachedNetworkImageProvider(result.imageUrl!)
            : null,
        child: result.imageUrl == null ? Icon(icon) : null,
      ),
      title: Text(result.title),
      subtitle: result.subtitle != null ? Text(result.subtitle!) : null,
      onTap: () {
        // Handle navigation
        if (result.type == SearchResultType.post) {
          final post = Post.fromFirestore(result.originalDocument);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostDetailPage(
                post: post,
                heroTagPrefix: 'search_page_',
              ),
            ),
          );
        } else if (result.type == SearchResultType.user) {
          // Navigate to user profile page
        } else if (result.type == SearchResultType.product) {
          final product = Product.fromFirestore(result.originalDocument);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(product: product),
            ),
          );
        } else if (result.type == SearchResultType.serviceProvider) {
          final provider = ServiceProvider.fromFirestore(result.originalDocument);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ServiceProviderProfilePage(provider: provider),
            ),
          );
        }
      },
    );
  }
} 