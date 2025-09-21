import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/pages/post_detail_page.dart';
import 'package:sumi/features/community/presentation/widgets/hashtag_widget.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:sumi/features/video/widgets/advanced_video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final Post post;
  final bool showFullContent;
  final bool isDetailView;
  final VoidCallback? onPostDeleted;
  final String heroTagPrefix;
  
  const PostCard({
    super.key,
    required this.post,
    this.showFullContent = false,
    this.isDetailView = false,
    this.onPostDeleted,
    this.heroTagPrefix = '',
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();

  bool _isLiked = false;
  int _likeCount = 0;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;
  bool _isCurrentUserPost = false;
  bool _isLoadingAction = false;
  
  // إضافة نظام التفاعلات الكامل من الرئيسية
  final List<String> _availableReactions = ['❤️', '👍', '😂', '😢', '😍', '🔥', '👀', '🔎'];
  String? _userReaction;
  Map<String, int> _postReactions = {};
  bool _showReactions = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _reactionButtonKey = GlobalKey();
  
  // إضافة آلية لتتبع العمليات الغير متزامنة
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likes.length;
    _isLiked = widget.post.likes.contains(_communityService.currentUserId);
    _isCurrentUserPost = widget.post.userId == _communityService.currentUserId;
    
    // تهيئة نظام التفاعلات
    _loadPostReactions();
    
    _likeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _likeAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _isDisposed = true; // تعيين حالة الإلغاء
    _likeAnimationController.dispose();
    _hideReactions(); // تنظيف التفاعلات عند إغلاق الويدجت
    super.dispose();
  }

  // دوال نظام التفاعلات الكامل (من الرئيسية)
  
  Future<void> _loadPostReactions() async {
    // TODO: تحميل بيانات التفاعلات من Firebase
    if (!_isDisposed && mounted) {
      setState(() {
        _postReactions = {};
        _userReaction = null;
      });
    }
  }
  
  void _showFacebookStyleReactions() {
    if (_overlayEntry != null) {
      _hideReactions();
      return;
    }
    
    final RenderBox renderBox = _reactionButtonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    final screenWidth = MediaQuery.of(context).size.width;
    const emojiSize = 20.0;
    const containerSize = 40.0;
    const itemSpacing = 4.0;
    const horizontalPadding = 8.0;
    
    final totalItemsWidth = _availableReactions.length * containerSize;
    final totalSpacingWidth = (_availableReactions.length - 1) * itemSpacing;
    final reactionBarWidth = totalItemsWidth + totalSpacingWidth + (horizontalPadding * 2);
    
    double leftPosition;
    const screenPadding = 16.0;
    
    if (isArabic) {
      leftPosition = position.dx + size.width - reactionBarWidth;
      if (leftPosition < screenPadding) leftPosition = screenPadding;
    } else {
      leftPosition = position.dx - (reactionBarWidth / 2) + (size.width / 2);
      if (leftPosition < screenPadding) leftPosition = screenPadding;
      if (leftPosition + reactionBarWidth > screenWidth - screenPadding) {
        leftPosition = screenWidth - reactionBarWidth - screenPadding;
      }
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition,
        top: position.dy - 70,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(containerSize / 2 + 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              children: _availableReactions.asMap().entries.map((entry) {
                final index = entry.key;
                final reaction = entry.value;
                final isLastItem = index == _availableReactions.length - 1;
                
                return GestureDetector(
                  onTap: () {
                    _toggleReaction(reaction);
                    _hideReactions();
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: isLastItem ? 0 : itemSpacing,
                    ),
                    width: containerSize,
                    height: containerSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(containerSize / 2),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        reaction,
                        style: const TextStyle(
                          fontSize: emojiSize,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
    
    if (mounted && !_isDisposed) {
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        _showReactions = true;
      });
      
      Future.delayed(const Duration(seconds: 4), () {
        if (!_isDisposed && mounted && _showReactions) {
          _hideReactions();
        }
      });
    }
  }
  
  void _hideReactions() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (!_isDisposed && mounted) {
      setState(() {
        _showReactions = false;
      });
    }
  }
  
  void _toggleReaction(String reaction) {
    if (_isDisposed || !mounted) return;
    
    if (mounted) {
      setState(() {
        if (_userReaction == reaction) {
          _userReaction = null;
          if (_postReactions[reaction] != null && _postReactions[reaction]! > 0) {
            _postReactions[reaction] = _postReactions[reaction]! - 1;
          }
          if (_postReactions[reaction] == 0) {
            _postReactions.remove(reaction);
          }
        } else {
          if (_userReaction != null) {
            if (_postReactions[_userReaction!] != null && _postReactions[_userReaction!]! > 0) {
              _postReactions[_userReaction!] = _postReactions[_userReaction!]! - 1;
            }
            if (_postReactions[_userReaction!] == 0) {
              _postReactions.remove(_userReaction!);
            }
          }
          
          _userReaction = reaction;
          if (_postReactions.containsKey(reaction)) {
            _postReactions[reaction] = _postReactions[reaction]! + 1;
          } else {
            _postReactions[reaction] = 1;
          }
        }
      });
    }
    
    _saveReactionToFirebase(reaction);
  }
  
  Future<void> _saveReactionToFirebase(String? reaction) async {
    try {
      if (reaction == null) {
        print('تم حذف التفاعل للمنشور ${widget.post.id}');
      } else {
        print('تم حفظ تفاعل $reaction للمنشور ${widget.post.id}');
      }
    } catch (e) {
      print('خطأ في حفظ التفاعل: $e');
    }
  }
  
  void _quickHeartReaction() {
    if (_isDisposed || !mounted) return;
    
    _toggleReaction('❤️');
    
    if (!_isDisposed && mounted && _userReaction == '❤️') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الإعجاب ❤️'),
          duration: Duration(milliseconds: 800),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
    }
  }

  Future<void> _toggleLike() async {
    if (_isDisposed || !mounted) return;
    
    final originalIsLiked = _isLiked;
    final originalLikeCount = _likeCount;
    
    if (mounted) {
      setState(() {
        if (_isLiked) {
          _likeCount--;
        } else {
          _likeCount++;
          // Fire-and-forget the animation
          () async {
            if (!_isDisposed) {
              await _likeAnimationController.forward();
              if (!_isDisposed && mounted) {
                await _likeAnimationController.reverse();
              }
            }
          }();
        }
        _isLiked = !_isLiked;
      });
    }

    try {
      await _communityService.togglePostLike(widget.post.id);
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLiked = originalIsLiked;
          _likeCount = originalLikeCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToUpdateLikeStatus)),
        );
      }
    }
  }

  Future<void> _sharePost() async {
    final localizations = AppLocalizations.of(context)!;
    final shareSubject = localizations.sharePost;
    final errorMessage =
        localizations.shareComingSoon;
    try {
      await Share.share(
      'شاهد هذا المنشور من سومي: ${widget.post.content}',
        subject: shareSubject,
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _navigateToDetail() {
    if (!widget.isDetailView) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(
            post: widget.post,
            heroTagPrefix: widget.heroTagPrefix,
          ),
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    final localizations = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deletePost),
        content: Text(localizations.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            child: Text(localizations.yes),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    if (_isLoadingAction || _isDisposed || !mounted) return;
    
    final localizations = AppLocalizations.of(context)!;
    
    final postDeletedMessage =
        localizations.postDeleted;
    final failedMessage =
        localizations.failedToDeletePost;
    
    if (mounted) {
      setState(() {
        _isLoadingAction = true;
      });
    }
    
    final success = await _communityService.deletePost(widget.post.id);
    
    if (mounted && !_isDisposed) {
      setState(() {
        _isLoadingAction = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(postDeletedMessage)),
        );
        
        // Call the callback if provided
        widget.onPostDeleted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failedMessage)),
        );
      }
    }
  }

  void _showPostOptions() {
    final localizations = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCurrentUserPost) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(localizations.deletePost),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(localizations.editPost),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.editComingSoon)),
                    );
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(localizations.sharePost),
                onTap: () {
                  Navigator.pop(context);
                  _sharePost();
                },
              ),
              if (!_isCurrentUserPost)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(localizations.reportPost),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(localizations.reportComingSoon)),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: widget.isDetailView
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFF8F8F8)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // هيدر المنشور - تصميم الرئيسية
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // معلومات المستخدم والصورة الشخصية - قابلة للنقر لفتح المنشور
              GestureDetector(
                onTap: _navigateToDetail,
                child: Row(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                  // الصورة الشخصية
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: widget.post.userImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.post.userImage,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 36,
                                height: 36,
                                color: const Color(0xFFF8F8F8),
                                child: const Icon(Icons.person, color: Colors.grey, size: 20),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage('assets/images/profile_23.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/images/profile_23.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // معلومات المستخدم
                  Column(
                    crossAxisAlignment: isArabic ? CrossAxisAlignment.start : CrossAxisAlignment.start,
                    children: [
                      Row(
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Text(
                            widget.post.userName.isNotEmpty ? widget.post.userName : (isArabic ? 'مستخدم غير معروف' : 'Unknown User'),
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1D2035),
                            ),
                          ),
                          // هنا يمكن إضافة الشارات أو أزرار المتابعة لاحقاً
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimeAgo(widget.post.createdAt, isArabic),
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 8,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFAAB9C5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
              
              // أيقونة المزيد (الثلاث نقط) على الجانب المقابل
              GestureDetector(
                onTap: _showPostOptions,
                child: const Icon(
                  Icons.more_vert,
                  size: 24,
                  color: Color(0xFFAAB9C5),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // محتوى المنشور - معروض دائماً - قابل للنقر لفتح التفاصيل
          GestureDetector(
            onTap: _navigateToDetail,
            child: Container(
              width: double.infinity,
              child: HashtagWidget(
                text: widget.post.content.isNotEmpty 
                    ? widget.post.content 
                    : (isArabic ? 'لا يوجد محتوى للمنشور' : 'No content available'),
                textStyle: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF323F49),
                  height: 1.4,
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                maxLines: widget.showFullContent ? null : 4,
                overflow: widget.showFullContent ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // عرض الوسائط إذا وجدت
          if (widget.post.type != PostType.text && widget.post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Flexible(
              child: _buildMediaContent(),
            ),
          ],
          
          // الهاشتاجز إذا وجدت
          if (widget.post.hashtags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              children: widget.post.hashtags.map((hashtag) => Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                child: Text(
                  '#$hashtag',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1AB385),
                  ),
                ),
              )).toList(),
            ),
          ],
          
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFF8F8F8),
          ),
          const SizedBox(height: 16),
          
          // قسم التعليقات والتفاعلات - تصميم الرئيسية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // قسم التعليقات
              GestureDetector(
                onTap: _navigateToDetail,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Text(
                        isArabic 
                            ? '${widget.post.commentCount} تعليقات'
                            : '${widget.post.commentCount} Comments',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF637D92),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: Color(0xFF637D92),
                      ),
                    ],
                  ),
                ),
              ),
              
              // قسم التفاعلات (نظام الفيسبوك الكامل)
              GestureDetector(
                key: _reactionButtonKey,
                onTap: _quickHeartReaction,
                onLongPress: _showFacebookStyleReactions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _userReaction != null 
                        ? const Color(0xFFFFE5E5)
                        : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(24),
                    border: _userReaction != null
                        ? Border.all(color: const Color(0xFFFF6B6B), width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      // عرض التفاعل الحالي أو أيقونة افتراضية
                      if (_userReaction != null) ...[
                        Text(
                          _userReaction!,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // عرض العدد الإجمالي للتفاعلات
                        if (_postReactions.isNotEmpty)
                          Text(
                            _postReactions.values.fold(0, (sum, count) => sum + count).toString(),
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                      ] else ...[
                        const Icon(
                          Icons.sentiment_satisfied_alt_outlined,
                          size: 18,
                          color: Color(0xFFAAB9C5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isArabic ? 'تفاعل' : 'React',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFAAB9C5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
  
  Widget _buildPostHeader(AppLocalizations localizations) {
    final timeAgo = timeago.format(widget.post.createdAt,
            locale: Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // صورة الملف الشخصي للمستخدم
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: widget.post.userImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: widget.post.userImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    color: Theme.of(context).primaryColor.withAlpha(51),
                    child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                  ),
          ),
          const SizedBox(width: 12),
          // اسم المستخدم والوقت
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.userName.isNotEmpty ? widget.post.userName : 'مستخدم غير معروف',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          // زر خيارات المنشور
          IconButton(
            icon: const Icon(Icons.more_vert),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _showPostOptions,
          ),
        ],
      ),
    );
  }
  
  // دالة لتنسيق الوقت بنفس نمط الرئيسية
  String _formatTimeAgo(DateTime dateTime, bool isArabic) {
    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inSeconds < 60) {
        return isArabic ? 'الآن' : 'now';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return isArabic ? 'منذ $minutes دقيقة' : '$minutes min ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return isArabic ? 'منذ $hours ساعة' : '$hours h ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return isArabic ? 'منذ $days يوم' : '$days d ago';
      } else {
        return isArabic ? 'منذ أسابيع' : 'weeks ago';
      }
    } catch (e) {
      return isArabic ? 'اليوم' : 'today';
    }
  }

  Widget _buildMediaContent() {
    if (widget.post.type != PostType.text && widget.post.mediaUrls.isNotEmpty) {
      return _buildMediaWidget();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMediaWidget() {
    switch (widget.post.type) {
      case PostType.image:
        return _buildImageGallery();
      case PostType.video:
        return _buildVideoPlayer();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // زر الإعجاب
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.grey[700],
            label: '$_likeCount',
            onTap: _toggleLike,
            showAnimation: _isLiked,
          ),
          
          // زر التعليقات
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            color: Colors.grey[700],
            label: '${widget.post.commentCount}',
            onTap: _navigateToDetail,
          ),
          
          // زر المشاركة
          _buildActionButton(
            icon: Icons.share_outlined,
            color: Colors.grey[700],
            label: localizations.share,
            onTap: _sharePost,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color? color,
    required String label,
    required VoidCallback onTap,
    bool showAnimation = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            showAnimation
                ? ScaleTransition(
                    scale: _likeAnimation,
                    child: Icon(icon, color: color, size: 22),
                  )
                : Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 220,
          ),
          child: AdvancedVideoPlayer(
            post: widget.post,
            onProgressUpdate: (duration) {
              // يمكن إضافة منطق تتبع تقدم المشاهدة هنا
            },
            onVideoCompleted: () {
              // إحصائيات إكمال الفيديو
              _communityService.incrementViewCount(widget.post.id);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return GestureDetector(
      onTap: _navigateToDetail,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: widget.isDetailView 
            ? CachedNetworkImage(
                imageUrl: widget.post.mediaUrls.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.error),
                  ),
                ),
              )
            : Hero(
                tag: '${widget.heroTagPrefix}post_image_${widget.post.id}',
        child: CachedNetworkImage(
          imageUrl: widget.post.mediaUrls.first,
          fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
            child: CircularProgressIndicator(),
          ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error),
                    ),
                  ),
                ),
              ),
        ),
      ),
    );
  }
} 