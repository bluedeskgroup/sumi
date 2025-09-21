import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:sumi/features/story/presentation/pages/enhanced_story_viewer_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class BookmarkedStoriesPage extends StatefulWidget {
  const BookmarkedStoriesPage({super.key});

  @override
  State<BookmarkedStoriesPage> createState() => _BookmarkedStoriesPageState();
}

class _BookmarkedStoriesPageState extends State<BookmarkedStoriesPage>
    with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  late AnimationController _fabController;

  List<Map<String, dynamic>> _allBookmarks = [];
  List<Map<String, dynamic>> _filteredBookmarks = [];
  String _searchQuery = '';
  String _selectedFilter = 'الكل';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'القصص المحفوظة',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.bold,
            color: Color(0xFF9A46D7),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF9A46D7)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            color: const Color(0xFF9A46D7),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _storyService.getBookmarkedStories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          _allBookmarks = snapshot.data!;
          _filterBookmarks();

          return Column(
            children: [
              // Search bar when active
              if (_isSearching) _buildSearchBar(),

              // Filter chips
              _buildFilterChips(),

              // Bookmarks list
              Expanded(
                child: _filteredBookmarks.isEmpty
                    ? _buildNoResultsState()
                    : AnimationLimiter(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBookmarks.length,
                          itemBuilder: (context, index) {
                            final bookmark = _filteredBookmarks[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildBookmarkCard(bookmark),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: const Color(0xFF9A46D7),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد قصص محفوظة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontFamily: 'Ping AR + LT',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك حفظ القصص المفضلة لديك هنا',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(Map<String, dynamic> bookmark) {
    return FutureBuilder<Story?>(
      future: _getStoryById(bookmark['storyId']),
      builder: (context, storySnapshot) {
        if (!storySnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final story = storySnapshot.data!;
        final storyItem = story.items.firstWhere(
          (item) => item.id == bookmark['storyItemId'],
          orElse: () => story.items.first,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _viewBookmarkedStory(story, storyItem),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Story preview
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9A46D7),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: storyItem.mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.error,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Story info
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
                          timeago.format(storyItem.timestamp, locale: 'ar'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'Ping AR + LT',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              storyItem.mediaType == StoryMediaType.video
                                  ? Icons.videocam
                                  : Icons.photo,
                              size: 16,
                              color: const Color(0xFF9A46D7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              storyItem.mediaType == StoryMediaType.video
                                  ? 'فيديو'
                                  : 'صورة',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9A46D7),
                                fontFamily: 'Ping AR + LT',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Remove bookmark button
                  IconButton(
                    icon: const Icon(
                      Icons.bookmark,
                      color: Color(0xFF9A46D7),
                    ),
                    onPressed: () => _removeBookmark(bookmark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Story?> _getStoryById(String storyId) async {
    try {
      return await _storyService.getStoryById(storyId);
    } catch (e) {
      return null;
    }
  }

  void _viewBookmarkedStory(Story story, StoryItem storyItem) {
    final storyIndex = story.items.indexOf(storyItem);
    if (storyIndex != -1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EnhancedStoryViewerPage(
            stories: [story],
            initialStoryIndex: 0,
          ),
        ),
      );
    }
  }

  void _removeBookmark(Map<String, dynamic> bookmark) async {
    final success = await _storyService.bookmarkStory(
      bookmark['storyId'],
      bookmark['storyItemId'],
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إزالة القصة من المحفوظة',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _filterBookmarks();
      }
    });
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterBookmarks();
          });
        },
        decoration: InputDecoration(
          hintText: 'البحث في القصص المحفوظة...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontFamily: 'Ping AR + LT',
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF9A46D7),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          fontFamily: 'Ping AR + LT',
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('الكل', 'الكل'),
          const SizedBox(width: 8),
          _buildFilterChip('صور', 'image'),
          const SizedBox(width: 8),
          _buildFilterChip('فيديوهات', 'video'),
          const SizedBox(width: 8),
          _buildFilterChip('استطلاعات', 'poll'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF9A46D7),
          fontFamily: 'Ping AR + LT',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'الكل';
          _filterBookmarks();
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF9A46D7),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildNoResultsState() {
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
            'جرب تغيير معايير البحث أو الفلترة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _filterBookmarks() {
    _filteredBookmarks = _allBookmarks.where((bookmark) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        // We'll filter based on story data when available
        // For now, we'll return all bookmarks
      }

      // Filter by type
      if (_selectedFilter != 'الكل') {
        // We'll need to get story data to filter by type
        // For now, return all
      }

      return true;
    }).toList();
  }

  void _clearAllBookmarks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'مسح جميع القصص المحفوظة',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        content: const Text(
          'هل أنت متأكد من مسح جميع القصص المحفوظة؟',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'مسح',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement clear all bookmarks
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم مسح جميع القصص المحفوظة',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
