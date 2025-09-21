import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/widgets/post_card.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:sumi/features/video/presentation/pages/video_player_page.dart';
import 'package:sumi/features/video/presentation/widgets/video_thumbnail.dart';
import 'package:sumi/features/video/services/video_cache_service.dart';
import 'package:sumi/features/video/services/video_search_service.dart';
import 'package:sumi/features/video/services/advanced_video_cache_service.dart';
import 'package:sumi/features/video/widgets/enhanced_video_card.dart';

import 'package:sumi/features/community/presentation/pages/post_detail_page.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with AutomaticKeepAliveClientMixin {
  final CommunityService _communityService = CommunityService();
  final ScrollController _scrollController = ScrollController();
  final VideoCacheService _cacheService = VideoCacheService();
  final VideoSearchService _searchService = VideoSearchService();
  final AdvancedVideoCacheService _advancedCacheService = AdvancedVideoCacheService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<Post> _allVideoPosts = []; // قائمة تحتوي على كل الفيديوهات
  List<Post> _displayVideoPosts = []; // قائمة الفيديوهات المعروضة بعد الفلترة
  
  // للتصفية وتقسيم الصفحات
  String _currentFilter = 'latest';
  DocumentSnapshot? _lastDocument;
  bool _hasMoreVideos = true;
  
  // للبحث
  bool _isSearchMode = false;
  String _searchQuery = '';
  VideoSearchCriteria _searchCriteria = VideoSearchCriteria();
  List<String> _searchSuggestions = [];
  
  // خيارات التصفية
  final List<Map<String, String>> _filterOptions = [
    {'key': 'all', 'arabicName': 'الكل', 'englishName': 'All'},
    {'key': 'latest', 'arabicName': 'الأحدث', 'englishName': 'Latest'},
    {'key': 'popular', 'arabicName': 'الأكثر إعجابًا', 'englishName': 'Most Liked'},
    {'key': 'trending', 'arabicName': 'الرائجة', 'englishName': 'Trending'},
  ];

  @override
  bool get wantKeepAlive => true; // للاحتفاظ بحالة الصفحة عند التنقل بين علامات التبويب

  @override
  void initState() {
    super.initState();
    _initializeServices();
    
    // إضافة مستمع للتمرير لتحميل المزيد من الفيديوهات عند الوصول لنهاية القائمة
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeServices() async {
    // تهيئة خدمات التخزين المؤقت
    await _cacheService.initialize();
    await _advancedCacheService.initialize();
    // تحميل الفيديوهات
    _loadVideoPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0 && !_isLoadingMore && _hasMoreVideos) {
        // وصلنا لنهاية القائمة، قم بتحميل المزيد من الفيديوهات
        _loadMoreVideos();
      }
    }
  }

  Future<void> _loadVideoPosts() async {
    setState(() {
      _isLoading = true;
      _lastDocument = null;
      _hasMoreVideos = true;
       _allVideoPosts = [];
       _displayVideoPosts = [];
    });

    try {
      final result = await _communityService.getPostsWithPagination(
        limit: 10,
        startAfter: null,
        category: 'video',
      );
      
      if (mounted) {
        setState(() {
          _allVideoPosts = result.posts;
          _lastDocument = result.lastDocument;
          _hasMoreVideos = result.hasMore;
          _applyFilter(); // تطبيق الفلتر الأولي
          _isLoading = false;
        });
        
        // بدء cache للفيديوهات والصور المصغرة في الخلفية
        _precacheVideosInBackground(result.posts);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.loadVideosFailed)),
          );
        }
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMoreVideos || _lastDocument == null) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _communityService.getPostsWithPagination(
        limit: 10,
        startAfter: _lastDocument,
        category: 'video',
      );
      
      if (mounted) {
        setState(() {
          _allVideoPosts.addAll(result.posts);
          _applyFilter(); // إعادة تطبيق الفلتر بعد إضافة المزيد
          _lastDocument = result.lastDocument;
          _hasMoreVideos = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        final localizations = AppLocalizations.of(context);
        if (localizations != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.loadVideosFailed)),
          );
        }
      }
    }
  }

  void _filterVideos(String filter) {
    if (_currentFilter == filter) return;
    
    setState(() {
      _currentFilter = filter;
      _applyFilter();
    });
  }

  void _applyFilter() {
    List<Post> filteredPosts = List.from(_allVideoPosts);
    switch (_currentFilter) {
      case 'popular':
        filteredPosts.sort((a, b) => b.likes.length.compareTo(a.likes.length));
        break;
      case 'trending':
      // منطق بسيط للرائج: يجمع بين الإعجابات والتعليقات
        filteredPosts.sort((a, b) => (b.likes.length + b.commentCount).compareTo(a.likes.length + a.commentCount));
        break;
      case 'latest':
      default:
        filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    setState(() {
      _displayVideoPosts = filteredPosts;
    });
  }

  Future<void> _refreshData() async {
    _currentFilter = 'latest';
    await _loadVideoPosts();
  }
  
  void _onPostDeleted(String postId) {
    setState(() {
      _allVideoPosts.removeWhere((post) => post.id == postId);
      _displayVideoPosts.removeWhere((post) => post.id == postId);
    });
  }

  /// تفعيل وضع البحث
  void _activateSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
  }

  /// إلغاء وضع البحث
  void _deactivateSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchQuery = '';
      _searchController.clear();
      _searchSuggestions = [];
    });
    _loadVideoPosts(); // إعادة تحميل الفيديوهات العادية
  }

  /// تنفيذ البحث
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _deactivateSearchMode();
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      final criteria = _searchCriteria.copyWith(query: query);
      final searchResult = await _searchService.searchVideos(
        criteria: criteria,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _displayVideoPosts = searchResult.videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في البحث: $e')),
        );
      }
    }
  }

  /// جلب اقتراحات البحث
  Future<void> _fetchSearchSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }

    try {
      final suggestions = await _searchService.getSearchSuggestions(query);
      if (mounted) {
        setState(() {
          _searchSuggestions = suggestions;
        });
      }
    } catch (e) {
      // تجاهل أخطاء الاقتراحات
    }
  }

  /// تطبيق فلتر بحث سريع
  void _applyQuickFilter(VideoSearchCriteria criteria) {
    setState(() {
      _searchCriteria = criteria;
      _isSearchMode = true;
    });
    _performSearch(_searchQuery.isEmpty ? '*' : _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    if (localizations == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              backgroundColor: Colors.white,
              elevation: 0.5,
              expandedHeight: _isSearchMode ? 90.0 : 60.0,
              title: _isSearchMode ? null : Text(
                localizations.videosPageTitle,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              actions: [
                if (!_isSearchMode)
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: _activateSearchMode,
                  ),
              ],
              flexibleSpace: _isSearchMode ? _buildSearchHeader() : null,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(_isSearchMode ? 80.0 : 40.0),
                child: Column(
                  children: [
                    if (_isSearchMode) _buildSearchBar(),
                    if (!_isSearchMode) _buildFilterOptions(theme),
                    if (_isSearchMode) _buildQuickFilters(),
                  ],
                ),
              ),
            ),
            _isLoading
                ? _buildShimmerLoading()
                : _displayVideoPosts.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library_outlined, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                localizations.noVideosAvailable,
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          )
                        ),
                      )
                    : _buildVideosList(),
            
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              
            if (!_hasMoreVideos && _displayVideoPosts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      localizations.noMorePosts,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterOptions(ThemeData theme) {
    return Container(
      height: 40,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = option['key'] == _currentFilter;
          final displayName = Localizations.localeOf(context).languageCode == 'ar' 
              ? option['arabicName']!
              : option['englishName']!;
              
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ChoiceChip(
              label: Text(displayName),
              selected: isSelected,
              onSelected: (_) => _filterVideos(option['key']!),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600
              ),
              backgroundColor: Colors.grey[100],
              selectedColor: theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                  color: isSelected ? theme.primaryColor : Colors.grey[300]!,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
            ),
          );
        },
      ),
    );
  }

  SliverList _buildVideosList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: EnhancedVideoCard(
              post: _displayVideoPosts[index],
              onDeleted: () => _onPostDeleted(_displayVideoPosts[index].id),
              showStats: true,
            ),
          );
        },
        childCount: _displayVideoPosts.length,
      ),
    );
  }



  Widget _buildShimmerLoading() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail placeholder
                  Container(
                    height: 210,
                    color: Colors.white,
                  ),
                  // Title and metadata placeholder
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(radius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 16, width: double.infinity, color: Colors.white),
                              const SizedBox(height: 8),
                              Container(height: 14, width: 200, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: 5, // Number of shimmer items to show
      ),
    );
  }

  /// تنسيق عدد المشاهدات بطريقة قابلة للقراءة
  String _formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}k';
    } else {
      return viewCount.toString();
    }
  }

  /// بناء رأس البحث
  Widget _buildSearchHeader() {
    return FlexibleSpaceBar(
      background: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(top: 40),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: _deactivateSearchMode,
            ),
            const Expanded(
              child: Text(
                'البحث في الفيديوهات',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء شريط البحث
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              _fetchSearchSuggestions(value);
            },
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: 'ابحث عن فيديوهات...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _deactivateSearchMode();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          if (_searchSuggestions.isNotEmpty)
            Container(
              height: 40,
              margin: const EdgeInsets.only(top: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _searchSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _searchSuggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(suggestion),
                      onPressed: () {
                        _searchController.text = suggestion;
                        _performSearch(suggestion);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// بناء الفلاتر السريعة
  Widget _buildQuickFilters() {
    final quickFilters = VideoSearchService.getQuickFilters();
    final filterNames = ['الأحدث', 'عالي الجودة', 'قصير', 'هذا الأسبوع', 'الأكثر مشاهدة'];

    return Container(
      height: 35,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: quickFilters.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ActionChip(
              label: Text(filterNames[index]),
              onPressed: () => _applyQuickFilter(quickFilters[index]),
              backgroundColor: Colors.blue[50],
              labelStyle: TextStyle(color: Colors.blue[700]),
            ),
          );
        },
      ),
    );
  }

  /// بدء cache للفيديوهات والصور المصغرة في الخلفية
  void _precacheVideosInBackground(List<Post> posts) {
    // تشغيل cache في background thread
    Future.microtask(() async {
      for (final post in posts) {
        if (post.type == PostType.video && post.mediaUrls.isNotEmpty) {
          try {
            // cache الصور المصغرة أولاً (أسرع)
            _advancedCacheService.precacheThumbnail(post.mediaUrls.first);
            
            // الانتظار قليلاً بين كل عملية لتجنب overload
            await Future.delayed(const Duration(milliseconds: 100));
            
            // cache الفيديو إذا كان في أول 3 فيديوهات (الأولوية للمحتوى المرئي)
            final index = posts.indexOf(post);
            if (index < 3) {
              _advancedCacheService.precacheVideo(post.mediaUrls.first);
            }
          } catch (e) {
            debugPrint('Error precaching video ${post.id}: $e');
          }
        }
      }
    });
  }

  /// cache الفيديوهات عند الحاجة
  Future<void> _smartCacheOnDemand(Post post) async {
    if (post.type == PostType.video && post.mediaUrls.isNotEmpty) {
      try {
        // تحميل سريع للصورة المصغرة
        await _advancedCacheService.getThumbnail(post.mediaUrls.first);
        
        // حفظ metadata للفيديو
        final metadata = VideoMetadata(
          url: post.mediaUrls.first,
          duration: post.videoDurationSeconds != null 
              ? Duration(seconds: post.videoDurationSeconds!) 
              : null,
          cachedAt: DateTime.now(),
        );
        await _advancedCacheService.saveVideoMetadata(post.mediaUrls.first, metadata);
        
      } catch (e) {
        debugPrint('Error smart caching for ${post.id}: $e');
      }
    }
  }
} 