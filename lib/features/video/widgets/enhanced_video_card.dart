import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/video/services/video_cache_service.dart';
import 'package:sumi/features/video/services/advanced_video_cache_service.dart';
import 'package:sumi/features/video/presentation/pages/video_player_page.dart';

/// Widget محسن لعرض بطاقة الفيديو مع كاش ومؤثرات بصرية
class EnhancedVideoCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onDeleted;
  final bool showStats;

  const EnhancedVideoCard({
    super.key,
    required this.post,
    this.onDeleted,
    this.showStats = true,
  });

  @override
  State<EnhancedVideoCard> createState() => _EnhancedVideoCardState();
}

class _EnhancedVideoCardState extends State<EnhancedVideoCard>
    with SingleTickerProviderStateMixin {
  final VideoCacheService _cacheService = VideoCacheService();
  final AdvancedVideoCacheService _advancedCacheService = AdvancedVideoCacheService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatViewCount(int viewCount) {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}k';
    } else {
      return viewCount.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedViews = _formatViewCount(widget.post.viewCount);
    final uploadTime = timeago.format(
      widget.post.createdAt,
      locale: Localizations.localeOf(context).languageCode,
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: () {
          _animationController.reverse();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerPage(post: widget.post),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              if (widget.post.mediaUrls.isNotEmpty)
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Colors.grey[200],
                          child: Hero(
                            tag: 'video_thumbnail_${widget.post.id}',
                            child: _buildAdvancedThumbnail(),
                          ),
                        ),
                      ),
                    ),
                    // مدة الفيديو
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.post.formattedDuration,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    // مؤشر جودة الفيديو
                    if (widget.post.isHighQuality)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hd, color: Colors.white, size: 12),
                              SizedBox(width: 2),
                              Text(
                                'HD',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورة المؤلف
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: _cacheService.buildCachedImage(
                          url: widget.post.userImage,
                          fit: BoxFit.cover,
                          placeholderBuilder: () => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          errorBuilder: () => Icon(Icons.person, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.post.userName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$formattedViews views · $uploadTime',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (widget.post.totalRatings > 0) ...[
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                SizedBox(width: 2),
                                Text(
                                  widget.post.formattedRating,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // إحصائيات إضافية
                          if (widget.showStats && widget.post.completionCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    '${widget.post.completionCount} مكتمل',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.thumb_up, color: Colors.blue, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    '${widget.post.likes.length}',
                                    style: TextStyle(
                                      color: Colors.blue[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        // Handle actions like 'Report', 'Not interested', etc.
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.report_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('إبلاغ'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'not_interested',
                          child: Row(
                            children: [
                              Icon(Icons.not_interested_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('غير مهتم'),
                            ],
                          ),
                        ),
                        if (widget.post.averageRating > 0)
                          PopupMenuItem<String>(
                            value: 'quality',
                            child: Row(
                              children: [
                                Icon(Icons.star_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('جودة: ${widget.post.qualityLevel}'),
                              ],
                            ),
                          ),
                      ],
                      icon: Icon(Icons.more_vert, color: Colors.grey[700], size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء صورة مصغرة متقدمة مع cache سريع
  Widget _buildAdvancedThumbnail() {
    // استخدام الصورة المصغرة من البيانات إذا كانت متوفرة
    if (widget.post.thumbnailUrl?.isNotEmpty == true) {
      return FutureBuilder<Uint8List?>(
        future: _advancedCacheService.getThumbnail(widget.post.thumbnailUrl!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }
          
          return _buildThumbnailPlaceholder();
        },
      );
    }
    
    // إنشاء صورة مصغرة من الفيديو
    if (widget.post.mediaUrls.isNotEmpty) {
      return FutureBuilder<Uint8List?>(
        future: _advancedCacheService.getThumbnail(widget.post.mediaUrls.first),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
            );
          }
          
          return _buildThumbnailPlaceholder();
        },
      );
    }
    
    // fallback للصورة المصغرة التقليدية
    return _cacheService.buildCachedImage(
      url: 'https://picsum.photos/seed/${widget.post.id}/400/225',
      fit: BoxFit.cover,
      placeholderBuilder: _buildThumbnailPlaceholder,
      errorBuilder: () => const Center(
        child: Icon(Icons.movie_creation_outlined,
            color: Colors.grey, size: 50)),
    );
  }

  /// بناء placeholder للصورة المصغرة
  Widget _buildThumbnailPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
        child: const Center(
          child: Icon(
            Icons.video_library_outlined,
            color: Colors.grey,
            size: 50,
          ),
        ),
      ),
    );
  }
}
