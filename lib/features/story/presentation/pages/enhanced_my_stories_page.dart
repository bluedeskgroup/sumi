import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sumi/features/auth/models/user_model.dart';
import 'package:sumi/features/auth/services/user_service.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/presentation/pages/enhanced_create_story_page.dart';
import 'package:sumi/features/story/presentation/pages/enhanced_story_viewer_page.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class EnhancedMyStoriesPage extends StatefulWidget {
  const EnhancedMyStoriesPage({super.key});

  @override
  State<EnhancedMyStoriesPage> createState() => _EnhancedMyStoriesPageState();
}

class _EnhancedMyStoriesPageState extends State<EnhancedMyStoriesPage>
    with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  late AnimationController _fabController;
  late AnimationController _headerController;
  
  bool _showStats = false;
  String _selectedFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerController.forward();
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF9A46D7),
                Color(0xFFF8F9FA),
              ],
              stops: [0.0, 0.3],
            ),
          ),
          child: StreamBuilder<List<Story>>(
            stream: _storyService.getMyStories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }
              
              if (snapshot.hasError) {
                return _buildErrorState();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final story = snapshot.data!.first;
              final filteredItems = _filterStoryItems(story.items);

              return Column(
                children: [
                  _buildHeader(story),
                  _buildFilterTabs(),
                  if (_showStats) _buildStatsOverview(story),
                  Expanded(
                    child: _buildStoriesGrid(story, filteredItems),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'قصصي',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Ping AR + LT',
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _showStats ? Icons.grid_view : Icons.analytics,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () {
            setState(() {
              _showStats = !_showStats;
            });
            HapticFeedback.selectionClick();
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF9A46D7),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل قصصك...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontFamily: 'Ping AR + LT',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'حدث خطأ في تحميل القصص',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontFamily: 'Ping AR + LT',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تحقق من اتصال الإنترنت وحاول مرة أخرى',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A46D7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _headerController,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 80,
                  color: Color(0xFF9A46D7),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _headerController,
                curve: Curves.easeOutCubic,
              )),
              child: Column(
                children: [
                  const Text(
                    'لا توجد قصص نشطة',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9A46D7),
                      fontFamily: 'Ping AR + LT',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ابدأ بإنشاء قصتك الأولى\nوشاركها مع أصدقائك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                      fontFamily: 'Ping AR + LT',
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9A46D7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF9A46D7).withOpacity(0.3),
                    ),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 24),
                    label: const Text(
                      'إنشاء قصة جديدة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Ping AR + LT',
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EnhancedCreateStoryPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Story story) {
    final totalViews = story.items.fold<int>(0, (sum, item) => sum + item.viewCount);
    final totalReactions = story.items.fold<int>(0, (sum, item) => sum + item.reactions.length);
    final totalShares = story.items.fold<int>(0, (sum, item) => sum + item.shareCount);

    return FadeTransition(
      opacity: _headerController,
      child: Container(
        margin: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A46D7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9A46D7).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: story.userImage.isNotEmpty
                        ? CachedNetworkImageProvider(story.userImage)
                        : null,
                    child: story.userImage.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'Ping AR + LT',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${story.items.length} قصة نشطة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Ping AR + LT',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9A46D7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Color(0xFF9A46D7),
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.visibility_outlined,
                    label: 'المشاهدات',
                    value: totalViews.toString(),
                    color: const Color(0xFF3498DB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.favorite_border,
                    label: 'الإعجابات',
                    value: totalReactions.toString(),
                    color: const Color(0xFFE74C3C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.share_outlined,
                    label: 'المشاركات',
                    value: totalShares.toString(),
                    color: const Color(0xFF2ECC71),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Ping AR + LT',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Ping AR + LT',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['الكل', 'صور', 'فيديوهات', 'استطلاعات'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF9A46D7) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : Colors.grey.withOpacity(0.3),
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: const Color(0xFF9A46D7).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(Story story) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليلات مفصلة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontFamily: 'Ping AR + LT',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailedStat(
                  'متوسط المشاهدات',
                  _calculateAverageViews(story).toString(),
                  Icons.trending_up,
                  const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDetailedStat(
                  'معدل التفاعل',
                  '${_calculateEngagementRate(story).toStringAsFixed(1)}%',
                  Icons.favorite,
                  const Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesGrid(Story story, List<StoryItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد قصص بهذا التصنيف',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 9 / 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _EnhancedStoryCard(
                  story: story,
                  storyItem: item,
                  onTap: () => _viewStory(story, index),
                  onDelete: () => _deleteStoryItem(story, item),
                  onShare: () => _shareStory(item),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabController,
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EnhancedCreateStoryPage(),
          ),
        ),
        backgroundColor: const Color(0xFF9A46D7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'قصة جديدة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Ping AR + LT',
          ),
        ),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  List<StoryItem> _filterStoryItems(List<StoryItem> items) {
    switch (_selectedFilter) {
      case 'صور':
        return items.where((item) => item.mediaType == StoryMediaType.image).toList();
      case 'فيديوهات':
        return items.where((item) => item.mediaType == StoryMediaType.video).toList();
      case 'استطلاعات':
        return items.where((item) => item.poll != null).toList();
      default:
        return items;
    }
  }

  int _calculateAverageViews(Story story) {
    if (story.items.isEmpty) return 0;
    final totalViews = story.items.fold<int>(0, (sum, item) => sum + item.viewCount);
    return (totalViews / story.items.length).round();
  }

  double _calculateEngagementRate(Story story) {
    if (story.items.isEmpty) return 0.0;
    final totalViews = story.items.fold<int>(0, (sum, item) => sum + item.viewCount);
    final totalEngagements = story.items.fold<int>(
      0, (sum, item) => sum + item.reactions.length + item.shareCount,
    );
    if (totalViews == 0) return 0.0;
    return (totalEngagements / totalViews) * 100;
  }

  void _viewStory(Story story, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnhancedStoryViewerPage(
          stories: [story],
          initialStoryIndex: 0,
        ),
      ),
    );
  }

  void _deleteStoryItem(Story story, StoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'حذف القصة',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه القصة؟\nلن يمكنك التراجع عن هذا الإجراء.',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storyService.deleteStoryItem(story.id, item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم حذف القصة بنجاح',
                style: TextStyle(fontFamily: 'Ping AR + LT'),
              ),
              backgroundColor: Color(0xFF9A46D7),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'حدث خطأ أثناء حذف القصة',
                style: TextStyle(fontFamily: 'Ping AR + LT'),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _shareStory(StoryItem item) {
    // TODO: Implement story sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'مشاركة القصة',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        backgroundColor: Color(0xFF9A46D7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _EnhancedStoryCard extends StatelessWidget {
  final Story story;
  final StoryItem storyItem;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _EnhancedStoryCard({
    required this.story,
    required this.storyItem,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final timeRemaining = storyItem.timestamp
        .add(const Duration(hours: 24))
        .difference(DateTime.now());
    final isExpired = timeRemaining.isNegative;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media preview
              CachedNetworkImage(
                imageUrl: storyItem.mediaUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF9A46D7)),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.grey, size: 40),
                  ),
                ),
              ),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.9)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Story type indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(storyItem),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTypeIcon(storyItem),
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getTypeLabel(storyItem),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Ping AR + LT',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // More options
                          GestureDetector(
                            onTap: () => _showOptionsMenu(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Bottom section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats
                          Row(
                            children: [
                              _buildStatChip(
                                Icons.visibility_outlined,
                                storyItem.viewCount.toString(),
                              ),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                Icons.favorite_border,
                                storyItem.reactions.length.toString(),
                              ),
                              const SizedBox(width: 8),
                              _buildStatChip(
                                Icons.share_outlined,
                                storyItem.shareCount.toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Time info
                          Text(
                            isExpired
                                ? 'منتهية الصلاحية'
                                : 'تنتهي خلال ${timeago.format(DateTime.now().add(timeRemaining), locale: 'ar')}',
                            style: TextStyle(
                              color: isExpired ? Colors.red : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Ping AR + LT',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Expired overlay
              if (isExpired)
                Container(
                  color: Colors.black.withOpacity(0.6),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'منتهية',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Ping AR + LT',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Ping AR + LT',
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(StoryItem item) {
    if (item.poll != null) return const Color(0xFF3498DB);
    if (item.mediaType == StoryMediaType.video) return const Color(0xFFE74C3C);
    return const Color(0xFF2ECC71);
  }

  IconData _getTypeIcon(StoryItem item) {
    if (item.poll != null) return Icons.poll;
    if (item.mediaType == StoryMediaType.video) return Icons.play_arrow;
    return Icons.photo;
  }

  String _getTypeLabel(StoryItem item) {
    if (item.poll != null) return 'استطلاع';
    if (item.mediaType == StoryMediaType.video) return 'فيديو';
    return 'صورة';
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                'خيارات القصة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ping AR + LT',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF9A46D7)),
                title: const Text(
                  'مشاركة',
                  style: TextStyle(fontFamily: 'Ping AR + LT'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onShare();
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Color(0xFF2ECC71)),
                title: const Text(
                  'تحميل',
                  style: TextStyle(fontFamily: 'Ping AR + LT'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement download
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'حذف',
                  style: TextStyle(fontFamily: 'Ping AR + LT'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
