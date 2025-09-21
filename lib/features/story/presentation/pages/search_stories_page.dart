import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:sumi/features/story/presentation/pages/enhanced_story_viewer_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class SearchStoriesPage extends StatefulWidget {
  const SearchStoriesPage({super.key});

  @override
  State<SearchStoriesPage> createState() => _SearchStoriesPageState();
}

class _SearchStoriesPageState extends State<SearchStoriesPage>
    with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final TextEditingController _searchController = TextEditingController();

  List<Story> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;
  String _lastQuery = '';
  String _selectedFilter = 'الكل';
  String _selectedTimeFilter = 'الكل';

  late AnimationController _searchControllerAnim;

  @override
  void initState() {
    super.initState();
    _searchControllerAnim = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchControllerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'البحث في القصص...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontFamily: 'Ping AR + LT',
            ),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(
                _isSearching ? Icons.clear : Icons.search,
                color: const Color(0xFF9A46D7),
              ),
              onPressed: _isSearching ? _clearSearch : _performSearch,
            ),
          ),
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Ping AR + LT',
            fontSize: 16,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
          onChanged: (value) {
            if (value.isEmpty && _isSearching) {
              _clearSearch();
            }
          },
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF9A46D7)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Advanced filters when searching
          if (_isSearching) _buildAdvancedFilters(),

          // Search suggestions when not searching
          if (!_isSearching) Expanded(child: _buildSearchSuggestions()),

          // Search results
          if (_isSearching) Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اقتراحات البحث',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                fontFamily: 'Ping AR + LT',
              ),
            ),
            const SizedBox(height: 16),

            // Popular search terms
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'أحمد',
                'فاطمة',
                'محمد',
                'علي',
                'خالد',
                'نور',
                'سارة',
                'عمر',
                'لينا',
                'يوسف',
              ].map((name) => _buildSuggestionChip(name)).toList(),
            ),

            const SizedBox(height: 24),

            // Recent searches
            Text(
              'عمليات البحث الأخيرة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontFamily: 'Ping AR + LT',
              ),
            ),
            const SizedBox(height: 12),

            _buildRecentSearchItem('أحمد محمد'),
            _buildRecentSearchItem('فاطمة علي'),
            _buildRecentSearchItem('محمد خالد'),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
        _performSearch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF9A46D7).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF9A46D7).withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9A46D7),
            fontFamily: 'Ping AR + LT',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String text) {
    return ListTile(
      leading: const Icon(
        Icons.history,
        color: Colors.grey,
      ),
      title: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Ping AR + LT',
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 18),
        onPressed: () {
          // Remove from recent searches
        },
      ),
      onTap: () {
        _searchController.text = text;
        _performSearch();
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontFamily: 'Ping AR + LT',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب كلمات بحث مختلفة',
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

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final story = _searchResults[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildStoryResultCard(story),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryResultCard(Story story) {
    final latestItem = story.items.first;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewStory(story),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: story.userImage.isNotEmpty
                    ? CachedNetworkImageProvider(story.userImage)
                    : null,
                child: story.userImage.isEmpty
                    ? Text(
                        story.userName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ping AR + LT',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${story.items.length} قصة • ${timeago.format(latestItem.timestamp, locale: 'ar')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Ping AR + LT',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Story thumbnails
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: story.items.length > 3 ? 3 : story.items.length,
                        itemBuilder: (context, index) {
                          final item = story.items[index];
                          return Container(
                            width: 35,
                            height: 35,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: item.mediaUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.error,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF9A46D7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _lastQuery = query;
    });

    // Add to search history
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10);
      }
    }

    final results = await _storyService.searchStories(query);

    if (mounted) {
      setState(() {
        _searchResults = _filterResults(results);
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchResults.clear();
      _searchController.clear();
      _lastQuery = '';
      _selectedFilter = 'الكل';
      _selectedTimeFilter = 'الكل';
    });
  }

  void _viewStory(Story story) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedStoryViewerPage(
          stories: [story],
          initialStoryIndex: 0,
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Type filter
          Expanded(
            child: _buildFilterDropdown(
              value: _selectedFilter,
              items: const ['الكل', 'صور', 'فيديوهات', 'استطلاعات'],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                  _searchResults = _filterResults(_searchResults);
                });
              },
              label: 'النوع',
            ),
          ),
          const SizedBox(width: 12),

          // Time filter
          Expanded(
            child: _buildFilterDropdown(
              value: _selectedTimeFilter,
              items: const ['الكل', 'اليوم', 'الأسبوع', 'الشهر'],
              onChanged: (value) {
                setState(() {
                  _selectedTimeFilter = value!;
                  _searchResults = _filterResults(_searchResults);
                });
              },
              label: 'الوقت',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  List<Story> _filterResults(List<Story> results) {
    return results.where((story) {
      // Filter by type
      if (_selectedFilter != 'الكل') {
        final hasMatchingItem = story.items.any((item) {
          switch (_selectedFilter) {
            case 'صور':
              return item.mediaType == StoryMediaType.image;
            case 'فيديوهات':
              return item.mediaType == StoryMediaType.video;
            case 'استطلاعات':
              return item.poll != null;
            default:
              return true;
          }
        });
        if (!hasMatchingItem) return false;
      }

      // Filter by time
      if (_selectedTimeFilter != 'الكل') {
        final latestItem = story.items.first;
        final now = DateTime.now();
        final storyTime = latestItem.timestamp;

        switch (_selectedTimeFilter) {
          case 'اليوم':
            if (!storyTime.isAfter(now.subtract(const Duration(days: 1)))) return false;
            break;
          case 'الأسبوع':
            if (!storyTime.isAfter(now.subtract(const Duration(days: 7)))) return false;
            break;
          case 'الشهر':
            if (!storyTime.isAfter(now.subtract(const Duration(days: 30)))) return false;
            break;
        }
      }

      return true;
    }).toList();
  }

  void _searchFromHistory(String query) {
    _searchController.text = query;
    _performSearch();
  }

  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
  }
}
