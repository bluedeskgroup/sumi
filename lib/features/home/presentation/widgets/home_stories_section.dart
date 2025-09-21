import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:sumi/features/video/services/advanced_video_cache_service.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/presentation/pages/enhanced_create_story_page.dart';
import 'package:sumi/features/story/presentation/pages/enhanced_my_stories_page.dart';
import 'package:sumi/features/story/presentation/pages/enhanced_story_viewer_page.dart';
import 'package:sumi/features/story/presentation/pages/bookmarked_stories_page.dart';
import 'package:sumi/features/story/presentation/pages/search_stories_page.dart';
import 'package:sumi/features/story/presentation/pages/story_settings_page.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:sumi/core/widgets/shimmer_loading.dart';
import 'package:sumi/core/widgets/animated_page_route.dart';
import 'package:sumi/core/services/preferences_service.dart';
import 'package:sumi/features/search/presentation/delegates/custom_search_delegate.dart';
import 'package:sumi/l10n/app_localizations.dart';

class HomeStoriesSection extends StatefulWidget {
  const HomeStoriesSection({super.key});

  @override
  State<HomeStoriesSection> createState() => _HomeStoriesSectionState();
}

class _HomeStoriesSectionState extends State<HomeStoriesSection> 
    with AutomaticKeepAliveClientMixin {
  final StoryService _storyService = StoryService();
  final AdvancedVideoCacheService _advancedCache = AdvancedVideoCacheService();
  
  // Cache للتحسين من الأداء
  List<Story>? _cachedStories;
  DateTime? _lastCacheTime;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  @override
  bool get wantKeepAlive => true; // احتفظ بالحالة عند التنقل

  bool _shouldRefreshCache() {
    if (_cachedStories == null || _lastCacheTime == null) return true;
    return DateTime.now().difference(_lastCacheTime!) > _cacheTimeout;
  }

  int _distinctViewCount(Story story) {
    final set = <String>{};
    for (final item in story.items) {
      set.addAll(item.viewedBy);
    }
    // Exclude author from view count display
    set.remove(story.userId);
    return set.length;
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}أ';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب للـ AutomaticKeepAliveClientMixin

    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 360;
    final bool isMedium = screenWidth >= 360 && screenWidth < 400;
    final double cardWidth = isSmall ? 100 : (isMedium ? 110 : 118);
    final double cardHeight = cardWidth * (168.0 / 118.0);

    return SizedBox(
      height: cardHeight,
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: StreamBuilder<List<Story>>(
          stream: _storyService.getStories(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // أثناء التحميل: أعرض بطاقة "قصتي" فقط
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMyStoryItem(context, cardWidth, cardHeight),
                ],
              );
            }

            if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
              // لا توجد قصص للمستخدمين: أعرض بطاقة "قصتي" فقط (بدون بيانات وهمية)
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMyStoryItem(context, cardWidth, cardHeight),
                ],
              );
            }

            final allStories = snapshot.data!;
            // Warm video thumbnails in background
            _precacheStoryThumbnails(allStories);
            final otherStories = allStories
                .where((s) => s.userId != _storyService.currentUserId)
                .toList()
              ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

            if (otherStories.isEmpty) {
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMyStoryItem(context, cardWidth, cardHeight),
                ],
              );
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: otherStories.length + 1, // +1 لبطاقة "قصتي"
              itemBuilder: (context, index) {
                // أول عنصر: "قصتي" (إن وجد) أو زر إضافة قصة
                if (index == 0) {
                  return _buildMyStoryItem(context, cardWidth, cardHeight);
                }

                final story = otherStories[index - 1];
                return Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  child: _buildStoryCard(
                    context,
                    story,
                    otherStories,
                    cardWidth,
                    cardHeight,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoriesHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          children: [
            Text(
              isArabic ? 'القصص' : 'Stories',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Ping AR + LT',
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuSelection(context, value),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'search',
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF9A46D7)),
                      const SizedBox(width: 12),
                      Text(
                        isArabic ? 'البحث في القصص' : 'Search Stories',
                        style: const TextStyle(fontFamily: 'Ping AR + LT'),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'bookmarks',
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark, color: Color(0xFF9A46D7)),
                      const SizedBox(width: 12),
                      Text(
                        isArabic ? 'القصص المحفوظة' : 'Saved Stories',
                        style: const TextStyle(fontFamily: 'Ping AR + LT'),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Color(0xFF9A46D7)),
                      const SizedBox(width: 12),
                      Text(
                        isArabic ? 'إعدادات القصص' : 'Story Settings',
                        style: const TextStyle(fontFamily: 'Ping AR + LT'),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF9A46D7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'search':
        context.pushAnimated(
          const SearchStoriesPage(),
          transition: PageTransitionType.slideFromRight,
        );
        break;
      case 'bookmarks':
        context.pushAnimated(
          const BookmarkedStoriesPage(),
          transition: PageTransitionType.slideFromRight,
        );
        break;
      case 'settings':
        context.pushAnimated(
          const StorySettingsPage(),
          transition: PageTransitionType.slideFromBottom,
        );
        break;
    }
  }

  Widget _buildLoadingState(BuildContext context, double cardWidth, double cardHeight) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(4, (index) => Padding(
            padding: const EdgeInsetsDirectional.only(start: 12),
            child: SizedBox(width: cardWidth, height: cardHeight, child: const StoryShimmer()),
          )),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, double cardWidth, double cardHeight) {
    // في حالة الخطأ، نعرض القصص الثابتة كما هي
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStaticStoryCard('assets/images/figma/story_1.png', cardWidth, cardHeight),
            const SizedBox(width: 12),
            _buildStaticStoryCard('assets/images/figma/story_2.png', cardWidth, cardHeight),
            const SizedBox(width: 12),
            _buildStaticStoryCard('assets/images/figma/story_3.png', cardWidth, cardHeight),
            const SizedBox(width: 12),
            _buildStaticStoryCard('assets/images/figma/story_4.png', cardWidth, cardHeight),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStoryItem(BuildContext context, double cardWidth, double cardHeight) {
    return StreamBuilder<List<Story>>(
      stream: _storyService.getMyStories(),
      builder: (context, snapshot) {
        final myStories = snapshot.data ?? [];
        final hasMyStories = myStories.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (hasMyStories) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EnhancedMyStoriesPage(),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EnhancedCreateStoryPage(),
                ),
              );
            }
          },
          child: hasMyStories
              ? _buildMyStoryPreview(context, myStories.first, cardWidth, cardHeight)
              : _buildAddStoryCard(context, cardWidth, cardHeight),
        );
      },
    );
  }

  Widget _buildMyStoryPreview(BuildContext context, Story story, double cardWidth, double cardHeight) {
    final previewUrl = story.items.isNotEmpty
        ? story.items.first.mediaUrl
        : ''; // No fallback - show placeholder if empty
    
    final isVideo = story.items.isNotEmpty && 
        story.items.first.mediaType == StoryMediaType.video;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9A46D7).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
            child: _buildStoryPreview(previewUrl, isVideo),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          // Play icon for videos
          if (isVideo)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          // Story info (hide public views count per request)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox.shrink(),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // "My Story" indicator
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF9A46D7).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'قصتي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ping AR + LT',
                ),
              ),
            ),
          ),
          // Add more stories button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF9A46D7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryCard(BuildContext context, double cardWidth, double cardHeight) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9A46D7).withOpacity(0.1),
            const Color(0xFF9A46D7).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF9A46D7).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9A46D7).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: cardWidth * (56.0/118.0),
            height: cardWidth * (56.0/118.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9A46D7), Color(0xFF7B1FA2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9A46D7).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final isArabic = l10n.localeName == 'ar';
              
              return Text(
                isArabic ? 'إضافة قصة' : 'Add Story',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9A46D7),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ping AR + LT',
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final isArabic = l10n.localeName == 'ar';
              
              return Text(
                isArabic ? 'شارك لحظاتك' : 'Share your moments',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontFamily: 'Ping AR + LT',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, Story story, List<Story> allStories, double cardWidth, double cardHeight) {
    final hasUnseenItems = story.items
        .any((item) => !item.hasUserSeen(_storyService.currentUserId ?? ''));
    final isVideo = story.items.isNotEmpty && 
        story.items.first.mediaType == StoryMediaType.video;
    
    final String previewUrl = story.items.isNotEmpty
        ? story.items.first.mediaUrl
        : ''; // No fallback - show placeholder if empty

    return GestureDetector(
      onTap: () {
        final userStories = allStories
            .where((s) => s.userId != _storyService.currentUserId)
            .toList();
        final initialIndex = userStories.indexOf(story);
        if (initialIndex != -1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EnhancedStoryViewerPage(
                stories: userStories,
                initialStoryIndex: initialIndex,
              ),
            ),
          );
        }
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
          border: hasUnseenItems
              ? Border.all(color: const Color(0xFF9A46D7), width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
              child: _buildStoryPreview(previewUrl, isVideo),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            if (isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            // Story owner info (hide public views count per request)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Unseen indicator
            if (hasUnseenItems)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9A46D7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryPreview(String previewUrl, bool isVideo) {
    // Note: sizes are passed via parent containers; keep image fill
    // إذا كان الـ URL فارغ، عرض placeholder
    if (previewUrl.isEmpty) {
      return _buildEmptyStoryPreview();
    }
    
    if (isVideo) {
      // للفيديوهات: استخراج thumbnail مع كاش متقدم
      return FutureBuilder<Uint8List?>(
        future: _advancedCache.getThumbnail(previewUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingPreview();
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            );
          }

          return CachedNetworkImage(
            imageUrl: previewUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildLoadingPreview(),
            errorWidget: (context, url, error) => _buildErrorPreview(),
            memCacheWidth: 300,
            memCacheHeight: 420,
            filterQuality: FilterQuality.medium,
          );
        },
      );
    } else {
      // للصور: استخدام الصورة الأصلية مباشرة
      return CachedNetworkImage(
        imageUrl: previewUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingPreview(),
        errorWidget: (context, url, error) => _buildErrorPreview(),
        memCacheWidth: 300,
        memCacheHeight: 420,
        filterQuality: FilterQuality.medium,
      );
    }
  }

  Widget _buildEmptyStoryPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF9A46D7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9A46D7).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 40,
            color: Color(0xFF9A46D7),
          ),
          SizedBox(height: 8),
          Text(
            'لا توجد صورة',
            style: TextStyle(
              color: Color(0xFF9A46D7),
              fontSize: 12,
              fontFamily: 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Precaching helper
  void _precacheStoryThumbnails(List<Story> stories) {
    for (final s in stories) {
      if (s.items.isNotEmpty && s.items.first.mediaType == StoryMediaType.video) {
        _advancedCache.precacheThumbnail(s.items.first.mediaUrl);
      }
    }
  }

  Widget _buildLoadingPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9A46D7),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildErrorPreview() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'خطأ في التحميل',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontFamily: 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStaticStoryCard(String imagePath, double cardWidth, double cardHeight) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPreview();
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardWidth * (21.0/118.0)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          // No fake counts on static fallback
        ],
      ),
    );
  }

  void _showQuickSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _QuickSearchContent(),
        ),
      ),
    );
  }
}

class _QuickSearchContent extends StatefulWidget {
  @override
  State<_QuickSearchContent> createState() => _QuickSearchContentState();
}

class _QuickSearchContentState extends State<_QuickSearchContent> {
  final TextEditingController _searchController = TextEditingController();
  final PreferencesService _prefs = PreferencesService();
  List<String> _suggestions = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSearchHistory() {
    setState(() {
      _searchHistory = _prefs.getSearchHistory();
    });
  }

  void _loadSuggestions() {
    // اقتراحات ثابتة للبحث
    _suggestions = [
      'قصص جديدة',
      'فيديوهات مضحكة',
      'وصفات طبخ',
      'نصائح جمال',
      'سفر ومغامرات',
      'تقنية ومعلومات',
      'رياضة وصحة',
      'موضة وأزياء',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9A46D7).withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF9A46D7)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'البحث السريع في القصص',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        
        // Search Field
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن قصة...',
              hintStyle: const TextStyle(fontFamily: 'Ping AR + LT'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF9A46D7)),
              ),
            ),
            style: const TextStyle(fontFamily: 'Ping AR + LT'),
            onChanged: (value) {
              setState(() {
                _isSearching = value.isNotEmpty;
              });
            },
            onSubmitted: _performSearch,
          ),
        ),
        
        // Quick Actions
        if (!_isSearching) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildQuickAction('القصص المحفوظة', Icons.bookmark, () {
                  Navigator.pop(context);
                  context.pushAnimated(const BookmarkedStoriesPage());
                }),
                const SizedBox(width: 12),
                _buildQuickAction('قصصي', Icons.person, () {
                  Navigator.pop(context);
                  context.pushAnimated(const EnhancedMyStoriesPage());
                }),
                const SizedBox(width: 12),
                _buildQuickAction('بحث متقدم', Icons.tune, () {
                  Navigator.pop(context);
                  context.pushAnimated(const SearchStoriesPage());
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Content based on search state
        Expanded(
          child: _isSearching ? _buildSearchSuggestions() : _buildSearchHistory(),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    final query = _searchController.text.toLowerCase();
    final filteredSuggestions = _suggestions
        .where((suggestion) => suggestion.toLowerCase().contains(query))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Color(0xFF9A46D7)),
          title: Text(
            suggestion,
            style: const TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          onTap: () => _performSearch(suggestion),
        );
      },
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد تاريخ بحث',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Ping AR + LT',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ البحث لترى تاريخ البحث هنا',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'البحثات الأخيرة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ping AR + LT',
                ),
              ),
              TextButton(
                onPressed: () {
                  _prefs.clearSearchHistory();
                  _loadSearchHistory();
                },
                child: const Text(
                  'مسح الكل',
                  style: TextStyle(
                    color: Color(0xFF9A46D7),
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(
                  query,
                  style: const TextStyle(fontFamily: 'Ping AR + LT'),
                ),
                trailing: IconButton(
                  onPressed: () {
                    _prefs.removeFromSearchHistory(query);
                    _loadSearchHistory();
                  },
                  icon: const Icon(Icons.close, size: 16),
                ),
                onTap: () => _performSearch(query),
              );
            },
          ),
        ),
      ],
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    // حفظ في تاريخ البحث
    _prefs.addToSearchHistory(query.trim());
    
    // إغلاق البحث السريع والانتقال للبحث الرئيسي
    Navigator.pop(context);
    showSearch(context: context, delegate: CustomSearchDelegate());
  }

  Widget _buildQuickAction(String title, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF9A46D7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF9A46D7)),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Ping AR + LT',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
