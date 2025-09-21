import 'package:flutter/material.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/widgets/post_card.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:sumi/features/community/services/hashtag_service.dart';
import 'package:sumi/l10n/app_localizations.dart';

class HashtagPostsPage extends StatefulWidget {
  final String hashtag;

  const HashtagPostsPage({
    super.key,
    required this.hashtag,
  });

  @override
  State<HashtagPostsPage> createState() => _HashtagPostsPageState();
}

class _HashtagPostsPageState extends State<HashtagPostsPage> {
  final HashtagService _hashtagService = HashtagService();
  final CommunityService _communityService = CommunityService();
  
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHashtagPosts();
  }

  Future<void> _loadHashtagPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // الحصول على معرفات المنشورات التي تحتوي على الهاشتاغ
      final postIds = await _hashtagService.getPostsByHashtag(widget.hashtag);
      
      if (postIds.isEmpty) {
        setState(() {
          _posts = [];
          _isLoading = false;
        });
        return;
      }

      // الحصول على المنشورات
      final posts = <Post>[];
      for (String postId in postIds) {
        final post = await _communityService.getPost(postId);
        if (post != null) {
          posts.add(post);
        }
      }

      // ترتيب المنشورات حسب التاريخ
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _posts = posts;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPosts() async {
    await _loadHashtagPosts();
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
            widget.hashtag,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.bold,
              color: Color(0xFF1AB385),
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshPosts,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: _buildBody(localizations, isArabic),
      ),
    );
  }

  Widget _buildBody(AppLocalizations localizations, bool isArabic) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A46D7)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'حدث خطأ في تحميل المنشورات' : 'Error loading posts',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A46D7),
                foregroundColor: Colors.white,
              ),
              child: Text(
                isArabic ? 'إعادة المحاولة' : 'Retry',
                style: const TextStyle(fontFamily: 'Ping AR + LT'),
              ),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tag,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isArabic 
                  ? 'لا توجد منشورات بهذا الهاشتاغ'
                  : 'No posts found with this hashtag',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic 
                  ? 'كن أول من يستخدم ${widget.hashtag} في منشور!'
                  : 'Be the first to use ${widget.hashtag} in a post!',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: const Color(0xFF9A46D7),
      child: Column(
        children: [
          // إحصائيات الهاشتاغ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1AB385), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  widget.hashtag,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isArabic 
                          ? '${_posts.length} منشور' 
                          : '${_posts.length} posts',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // قائمة المنشورات
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PostCard(
                    post: _posts[index],
                    heroTagPrefix: 'hashtag_${widget.hashtag}_',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}