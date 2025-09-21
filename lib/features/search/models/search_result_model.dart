enum SearchResultType {
  user,
  post,
  product,
  serviceProvider,
}

class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final SearchResultType type;
  final dynamic originalDocument;

  SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.type,
    required this.originalDocument,
  });
} 