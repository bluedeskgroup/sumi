import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:sumi/features/video/widgets/advanced_video_player.dart';
import 'package:sumi/features/video/services/advanced_video_cache_service.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:sumi/features/community/services/community_service.dart';
import 'package:sumi/features/auth/services/auth_service.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sumi/features/auth/models/user_model.dart';
import '../widgets/video_thumbnail.dart';
import 'package:sumi/features/video/models/watch_progress_model.dart';
import 'package:sumi/features/video/services/video_cache_service.dart';
import 'package:sumi/features/video/services/video_analytics_service.dart';
import 'package:sumi/features/video/models/video_analytics_model.dart';
import 'package:sumi/features/video/widgets/download_quality_dialog.dart';
import 'package:sumi/features/video/presentation/pages/video_clip_editor_page.dart';
import 'dart:async';

import 'video_page.dart';

class VideoPlayerPage extends StatefulWidget {
  final Post post;

  const VideoPlayerPage({super.key, required this.post});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  final VideoCacheService _cacheService = VideoCacheService();
  final AdvancedVideoCacheService _advancedCacheService = AdvancedVideoCacheService();
  final VideoAnalyticsService _analyticsService = VideoAnalyticsService();

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  
  late Post _currentPost;
  AppUser? _postAuthor;
  List<Post> _suggestedVideos = [];
  List<PostComment> _comments = [];
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isSubscribed = false;
  
  // متغيرات تتبع التقدم
  Timer? _progressTimer;
  WatchProgress? _watchProgress;
  int _lastSavedProgress = 0;

  @override
  void initState() {
    super.initState();
    _currentPost = widget.post;
    _initializePage();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.id != oldWidget.post.id) {
      _currentPost = widget.post;
      _initializePage();
    }
  }

  Future<void> _initializePage() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Dispose old controllers before initializing new ones
    await _videoPlayerController?.dispose();
    _chewieController?.dispose();

    try {
      // Fetch initial data
      final post = await _communityService.getPost(widget.post.id);
      if (post == null) throw Exception('Post not found');
      _currentPost = post;

      // زيادة عدد المشاهدات وتسجيل التفاعل
      _communityService.incrementViewCount(_currentPost.id);
      _analyticsService.recordEngagement(
        postId: _currentPost.id,
        type: EngagementType.view,
        videoPosition: 0,
      );

      // Initialize Video Player with advanced caching
      final videoUrl = _currentPost.mediaUrls.firstWhere((url) => url.toLowerCase().contains('.mp4'), orElse: () => '');
      if (videoUrl.isNotEmpty) {
        // بدء cache للفيديو في الخلفية
        _advancedCacheService.precacheVideo(videoUrl);
        _advancedCacheService.precacheThumbnail(videoUrl);
        
        // تهيئة الفيديو (سيستخدم المشغل المتقدم لاحقاً)
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        await _videoPlayerController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: true,
        );
      }

      // Fetch other data using the new smart suggestions
      final author = await _communityService.getUser(_currentPost.userId);
      final suggested = await _communityService.getUltimateVideoSuggestions(
        currentVideoId: _currentPost.id,
        currentUserId: _authService.currentUser?.uid,
        limit: 10,
      );
      final comments = await _communityService.getCommentsForPost(_currentPost.id);
      
      // تحميل تقدم المشاهدة المحفوظ
      final watchProgress = await _communityService.getWatchProgress(_currentPost.id);

      if (mounted) {
        setState(() {
          _postAuthor = author;
          _suggestedVideos = suggested;
          _comments = comments;
          _watchProgress = watchProgress;
          _isLiked = _currentPost.likes.contains(_authService.currentUser?.uid);
          _isDisliked = _currentPost.dislikes.contains(_authService.currentUser?.uid);
          _isSubscribed = _postAuthor?.subscribers.contains(_authService.currentUser?.uid) ?? false;
          _isLoading = false; // Everything is loaded
        });
        
        // بدء تتبع التقدم
        _startProgressTracking();
        
        // إذا كان هناك تقدم محفوظ، اذهب إلى ذلك الموضع
        if (watchProgress != null && watchProgress.watchedSeconds > 10) {
          _seekToSavedPosition(watchProgress.watchedSeconds);
        }
      }
    } catch (e) {
      if(mounted){
        setState(() {
          _isLoading = false;
        });
      }
      // Optionally show an error message
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _handleLike() async {
    final userId = _authService.currentUser?.uid;
    if(userId == null) return;

    final wasLiked = _isLiked;
    final wasDisliked = _isDisliked;

    setState(() {
      _isLiked = !wasLiked;
      if (_isLiked && wasDisliked) {
        _isDisliked = false;
      }
    });
    
    try {
      if (wasDisliked) {
        await _communityService.togglePostDislike(_currentPost.id);
      }
      await _communityService.togglePostLike(_currentPost.id);
      
      // تسجيل تفاعل الإعجاب
      if (!wasLiked) {
        _analyticsService.recordEngagement(
          postId: _currentPost.id,
          type: EngagementType.like,
          videoPosition: _videoPlayerController?.value.position.inSeconds ?? 0,
        );
      }
      
      final updatedPost = await _communityService.getPost(_currentPost.id);
      if (updatedPost != null && mounted) {
        setState(() => _currentPost = updatedPost);
      }

    } catch (e) {
      // Revert state
      setState(() {
        _isLiked = wasLiked;
        _isDisliked = wasDisliked;
      });
    }
  }
  
  void _handleDislike() async {
    final userId = _authService.currentUser?.uid;
    if(userId == null) return;
    
    final wasDisliked = _isDisliked;
    final wasLiked = _isLiked;

    setState(() {
      _isDisliked = !wasDisliked;
       if (_isDisliked && wasLiked) {
        _isLiked = false;
      }
    });

    try {
      if (wasLiked) {
        await _communityService.togglePostLike(_currentPost.id);
      }
      await _communityService.togglePostDislike(_currentPost.id);

      final updatedPost = await _communityService.getPost(_currentPost.id);
      if (updatedPost != null && mounted) {
        setState(() => _currentPost = updatedPost);
      }
    } catch (e) {
      // Revert state
      setState(() {
         _isDisliked = wasDisliked;
         _isLiked = wasLiked;
      });
    }
  }

  void _handleSubscription() async {
    if (_postAuthor == null) return;

    final wasSubscribed = _isSubscribed;
    setState(() => _isSubscribed = !wasSubscribed );

    try {
       await _communityService.toggleSubscription(_postAuthor!.userId);
    } catch (e) {
      setState(() => _isSubscribed = wasSubscribed );
    }
  }

  Future<void> _handleAddComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    final content = _commentController.text.trim();
    _commentController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      await _communityService.addComment(
        postId: _currentPost.id,
        content: content,
      );
      
      // تسجيل تفاعل التعليق
      _analyticsService.recordEngagement(
        postId: _currentPost.id,
        type: EngagementType.comment,
        videoPosition: _videoPlayerController?.value.position.inSeconds ?? 0,
      );
      
      // Refresh comments after adding
      final newComments = await _communityService.getCommentsForPost(_currentPost.id);
      if(mounted) {
        setState(() {
          _comments = newComments;
        });
      }
    } catch (e) {
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add comment.')),
            );
        }
    }
  }

  void _handleShare() {
    Share.share('Check out this video from Sumi App! ${_currentPost.mediaUrls[0]}');
    
    // تسجيل تفاعل المشاركة
    _analyticsService.recordEngagement(
      postId: _currentPost.id,
      type: EngagementType.share,
      videoPosition: _videoPlayerController?.value.position.inSeconds ?? 0,
    );
  }

  void _handleDownload() {
    showDownloadQualityDialog(
      context: context,
      post: _currentPost,
      onDownloadStarted: (downloadId) {
        // يمكن إضافة المزيد من المنطق هنا إذا لزم الأمر
      },
    );
  }

  void _handleCreateClip() async {
    // إيقاف الفيديو مؤقتاً
    final wasPlaying = _videoPlayerController?.value.isPlaying ?? false;
    if (wasPlaying) {
      await _videoPlayerController?.pause();
    }

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoClipEditorPage(originalPost: _currentPost),
        ),
      );

      if (result != null) {
        // تم إنشاء مقطع بنجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء المقطع بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      // استئناف التشغيل إذا كان قيد التشغيل
      if (wasPlaying && mounted) {
        await _videoPlayerController?.play();
      }
    }
  }

  void _showFeatureNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedViews = _formatViewCount(_currentPost.viewCount);
    final uploadTime = timeago.format(_currentPost.createdAt, locale: Localizations.localeOf(context).languageCode);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: (_videoPlayerController?.value.isInitialized ?? false)
                  ? _videoPlayerController!.value.aspectRatio
                  : 16 / 9,
              child: _isLoading
                  ? Container(
                      color: Colors.black,
                      child: const Center(child: CircularProgressIndicator()),
                    )
                  : AdvancedVideoPlayer(
                      post: _currentPost,
                      onProgressUpdate: (duration) {
                        // تحديث تقدم المشاهدة
                        _updateWatchProgress(duration.inSeconds);
                      },
                      onVideoCompleted: () {
                        // تسجيل إكمال الفيديو
                        _analyticsService.recordEngagement(
                          postId: _currentPost.id,
                          type: EngagementType.completion,
                          videoPosition: _currentPost.videoDurationSeconds ?? 0,
                        );
                      },
                    ),
            ),
            Expanded(
              child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentPost.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '$formattedViews views · $uploadTime',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              if (_currentPost.totalRatings > 0) ...[
                                Text(' · ', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '${_currentPost.formattedRating} (${_currentPost.totalRatings})',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(_postAuthor?.userImage ?? _currentPost.userImage),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _postAuthor?.userName ?? _currentPost.userName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_postAuthor?.subscribers.length ?? 0} subscribers',
                                       style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    )
                                  ],
                                ),
                              ),
                              if (_postAuthor != null && _postAuthor!.userId != _authService.currentUser?.uid)
                                ElevatedButton(
                                  onPressed: _handleSubscription,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isSubscribed ? Colors.grey[800] : Colors.white,
                                    foregroundColor: _isSubscribed ? Colors.white : Colors.black,
                                  ),
                                  child: Text(_isSubscribed ? 'Subscribed' : 'Subscribe'),
                                )
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 24),
                    _buildSuggestedVideosSection(),
                    const Divider(color: Colors.grey, height: 24),
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: _currentPost.likes.length.toString(),
            onTap: _handleLike,
          ),
          const SizedBox(width: 15),
          _buildActionButton(
            icon: _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined, 
            label: 'Dislike',
            onTap: _handleDislike
          ),
          const SizedBox(width: 15),
          _buildActionButton(icon: Icons.share_outlined, label: 'Share', onTap: _handleShare),
          const SizedBox(width: 15),
          _buildActionButton(icon: Icons.download_outlined, label: 'Download', onTap: _handleDownload),
          const SizedBox(width: 15),
          _buildActionButton(icon: Icons.cut_outlined, label: 'Clip', onTap: _handleCreateClip),
          const SizedBox(width: 15),
          _buildRatingButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSuggestedVideosSection() {
    if (_suggestedVideos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No suggested videos found.', style: TextStyle(color: Colors.grey))),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Up next', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _suggestedVideos.length,
          itemBuilder: (context, index) {
            final video = _suggestedVideos[index];
            return _buildSuggestedVideoTile(video);
          },
        ),
      ],
    );
  }

  Widget _buildSuggestedVideoTile(Post post) {
    final formattedViews = _formatViewCount(post.viewCount);
    final uploadDate = post.createdAt;

    return GestureDetector(
      onTap: () {
        if (post.id != _currentPost.id) {
            // Close the current player and open a new one
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VideoPlayerPage(post: post),
              ),
            );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 150,
                  height: 84,
                  color: Colors.grey[800], // Placeholder color
                  child: post.mediaUrls.isNotEmpty
                      ? _cacheService.buildCachedImage(
                          url: 'https://picsum.photos/seed/${post.id}/150/84',
                          width: 150,
                          height: 84,
                          fit: BoxFit.cover,
                          placeholderBuilder: () => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          errorBuilder: () => const Icon(Icons.movie, color: Colors.white, size: 40),
                        )
                      : const Icon(Icons.movie, color: Colors.white, size: 40),
                ),
                // This is where video duration would go
                // Padding(
                //   padding: const EdgeInsets.all(4.0),
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                //     color: Colors.black.withOpacity(0.7),
                //     child: const Text('12:34', style: TextStyle(color: Colors.white, fontSize: 10)),
                //   ),
                // ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.userName,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedViews views · ${timeago.format(uploadDate)}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments ${_comments.length}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAddCommentField(),
          const SizedBox(height: 16),
          if (_comments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text("No comments yet. Be the first to comment!", style: TextStyle(color: Colors.grey)),
              )
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return _buildCommentTile(comment);
              },
            ),
        ],
      ),
    );
  }

   Widget _buildAddCommentField() {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: _authService.currentUser?.photoURL != null
              ? NetworkImage(_authService.currentUser!.photoURL!)
              : null,
          child: _authService.currentUser?.photoURL == null 
              ? const Icon(Icons.person, size: 18) 
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _commentController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.white),
          onPressed: _handleAddComment,
        ),
      ],
    );
  }

  Widget _buildCommentTile(PostComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(comment.userImage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt, locale: 'en_short'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
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

  /// بدء تتبع تقدم المشاهدة
  void _startProgressTracking() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveWatchProgress();
    });
  }

  /// تحديث تقدم المشاهدة (للمشغل المتقدم)
  void _updateWatchProgress(int currentSeconds) {
    final totalSeconds = _currentPost.videoDurationSeconds ?? 0;
    
    // احفظ التقدم فقط إذا تغير بمقدار 10 ثوانِ على الأقل
    if ((currentSeconds - _lastSavedProgress).abs() >= 10 && totalSeconds > 0) {
      _communityService.updateWatchProgress(
        postId: _currentPost.id,
        watchedSeconds: currentSeconds,
        totalDurationSeconds: totalSeconds,
      );
      
      _lastSavedProgress = currentSeconds;
      
      // تسجيل تفاعل المستخدم
      _analyticsService.recordEngagement(
        postId: _currentPost.id,
        type: EngagementType.seek,
        videoPosition: currentSeconds,
      );
    }
  }

  /// حفظ تقدم المشاهدة (للمشغل القديم)
  void _saveWatchProgress() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      return;
    }

    final currentPositionSeconds = _videoPlayerController!.value.position.inSeconds;
    final totalDurationSeconds = _videoPlayerController!.value.duration.inSeconds;
    
    // احفظ التقدم فقط إذا تغير بمقدار 10 ثوانِ على الأقل
    if ((currentPositionSeconds - _lastSavedProgress).abs() >= 10 && totalDurationSeconds > 0) {
      _communityService.updateWatchProgress(
        postId: _currentPost.id,
        watchedSeconds: currentPositionSeconds,
        totalDurationSeconds: totalDurationSeconds,
      );
      _lastSavedProgress = currentPositionSeconds;
    }
  }

  /// الانتقال إلى الموضع المحفوظ
  void _seekToSavedPosition(int seconds) {
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      _videoPlayerController!.seekTo(Duration(seconds: seconds));
    }
  }

  /// بناء زر التقييم
  Widget _buildRatingButton() {
    return InkWell(
      onTap: _showRatingDialog,
      child: Column(
        children: [
          Icon(Icons.star_outline, color: Colors.white),
          const SizedBox(height: 8),
          Text('Rate', style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  /// إظهار حوار التقييم
  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'قيم هذا الفيديو',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        _rateVideo(index + 1);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.star_outline,
                          color: Colors.amber,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// تقييم الفيديو
  void _rateVideo(int rating) async {
    await _communityService.rateVideo(
      postId: _currentPost.id,
      rating: rating,
    );
    
    // تسجيل تفاعل التقييم
    _analyticsService.recordEngagement(
      postId: _currentPost.id,
      type: EngagementType.rate,
      videoPosition: _videoPlayerController?.value.position.inSeconds ?? 0,
    );
    
    // تحديث المنشور لإظهار التقييم الجديد
    final updatedPost = await _communityService.getPost(_currentPost.id);
    if (updatedPost != null && mounted) {
      setState(() {
        _currentPost = updatedPost;
      });
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('شكراً لك! تم حفظ تقييمك'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
} 