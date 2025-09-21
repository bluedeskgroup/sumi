import 'package:flutter/material.dart';
import 'package:sumi/features/community/models/hashtag_model.dart';
import 'package:sumi/features/community/presentation/pages/hashtag_posts_page.dart';
import 'package:sumi/features/community/services/hashtag_service.dart';
import 'package:sumi/l10n/app_localizations.dart';

class TrendingHashtagsWidget extends StatefulWidget {
  const TrendingHashtagsWidget({super.key});

  @override
  State<TrendingHashtagsWidget> createState() => _TrendingHashtagsWidgetState();
}

class _TrendingHashtagsWidgetState extends State<TrendingHashtagsWidget> {
  final HashtagService _hashtagService = HashtagService();
  List<HashtagModel> _trendingHashtags = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingHashtags();
  }

  Future<void> _loadTrendingHashtags() async {
    try {
      final hashtags = await _hashtagService.getTrendingHashtags(limit: 8);
      if (mounted) {
        setState(() {
          _trendingHashtags = hashtags;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1AB385)),
          ),
        ),
      );
    }

    if (_trendingHashtags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F7FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1AB385).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Color(0xFF1AB385),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'الهاشتاغات الرائجة' : 'Trending Hashtags',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1AB385),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.whatshot,
                color: Colors.orange[600],
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingHashtags.map((hashtag) {
              final isPopular = hashtag.count > 5;
              
              return GestureDetector(
                onTap: () => _navigateToHashtag(hashtag.tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPopular 
                        ? const Color(0xFF1AB385) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1AB385),
                      width: isPopular ? 0 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1AB385).withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hashtag.tag,
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPopular ? Colors.white : const Color(0xFF1AB385),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isPopular 
                              ? Colors.white.withOpacity(0.3) 
                              : const Color(0xFF1AB385).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hashtag.count.toString(),
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPopular ? Colors.white : const Color(0xFF1AB385),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}