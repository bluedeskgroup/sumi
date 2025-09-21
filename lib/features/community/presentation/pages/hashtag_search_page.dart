import 'package:flutter/material.dart';
import 'package:sumi/features/community/models/hashtag_model.dart';
import 'package:sumi/features/community/presentation/pages/hashtag_posts_page.dart';
import 'package:sumi/features/community/services/hashtag_service.dart';
import 'package:sumi/l10n/app_localizations.dart';

class HashtagSearchPage extends StatefulWidget {
  const HashtagSearchPage({super.key});

  @override
  State<HashtagSearchPage> createState() => _HashtagSearchPageState();
}

class _HashtagSearchPageState extends State<HashtagSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final HashtagService _hashtagService = HashtagService();
  
  List<HashtagModel> _searchResults = [];
  List<HashtagModel> _trendingHashtags = [];
  bool _isLoading = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingHashtags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingHashtags() async {
    try {
      final hashtags = await _hashtagService.getTrendingHashtags(limit: 20);
      if (mounted) {
        setState(() {
          _trendingHashtags = hashtags;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _searchHashtags(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add # if not present
      final searchQuery = query.startsWith('#') ? query : '#$query';
      final results = await _hashtagService.searchHashtags(searchQuery);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showResults = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showResults = true;
          _searchResults = [];
        });
      }
    }
  }

  void _navigateToHashtag(String hashtag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HashtagPostsPage(hashtag: hashtag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = localizations.localeName == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'البحث في الهاشتاغات' : 'Search Hashtags',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isArabic ? 'ابحث عن هاشتاغ...' : 'Search for hashtag...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1AB385)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _searchHashtags('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFF1AB385)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFF1AB385), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                onChanged: (value) {
                  setState(() {});
                  _searchHashtags(value);
                },
              ),
            ),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1AB385)),
                      ),
                    )
                  : _showResults
                      ? _buildSearchResults(isArabic)
                      : _buildTrendingSection(isArabic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isArabic) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لم يتم العثور على نتائج' : 'No results found',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic 
                  ? 'جرب البحث بكلمات مختلفة'
                  : 'Try searching with different words',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final hashtag = _searchResults[index];
        return _buildHashtagTile(hashtag, isArabic);
      },
    );
  }

  Widget _buildTrendingSection(bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Color(0xFF1AB385),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'الهاشتاغات الرائجة' : 'Trending Hashtags',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1AB385),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_trendingHashtags.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Icon(
                    Icons.tag,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا توجد هاشتاغات رائجة حالياً' : 'No trending hashtags yet',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ...(_trendingHashtags.map((hashtag) => _buildHashtagTile(hashtag, isArabic)).toList()),
        ],
      ),
    );
  }

  Widget _buildHashtagTile(HashtagModel hashtag, bool isArabic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1AB385).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.tag,
            color: Color(0xFF1AB385),
            size: 20,
          ),
        ),
        title: Text(
          hashtag.tag,
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1AB385),
          ),
        ),
        subtitle: Text(
          isArabic 
              ? '${hashtag.count} منشور'
              : '${hashtag.count} posts',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
          color: const Color(0xFF1AB385),
          size: 16,
        ),
        onTap: () => _navigateToHashtag(hashtag.tag),
      ),
    );
  }
}