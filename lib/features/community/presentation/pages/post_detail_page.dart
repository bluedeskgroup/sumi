import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/widgets/comment_card.dart';
import 'package:sumi/features/community/presentation/widgets/post_card.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sumi/features/auth/models/user_model.dart';
import 'package:sumi/features/auth/services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailPage extends StatefulWidget {
  final Post post;
  final String heroTagPrefix;

  const PostDetailPage({
    super.key,
    required this.post,
    this.heroTagPrefix = '', // Default to empty string
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FocusNode _commentFocusNode = FocusNode();
  
  bool _isLoading = true;
  Post? _post;
  List<PostComment> _comments = [];
  bool _emojiShowing = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _commentFocusNode.addListener(() {
      if (_commentFocusNode.hasFocus) {
        setState(() {
          _emojiShowing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final post = await _communityService.getPost(widget.post.id);
      if (post != null) {
        final comments = await _communityService.getCommentsForPost(widget.post.id);
        if (mounted) {
          setState(() {
            _post = post;
            _comments = comments;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoadPost)),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    if (_auth.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginToComment)),
        );
      }
      return;
    }
    
    // إخفاء الكيبورد والإيموجي قبل الإرسال
    _commentFocusNode.unfocus();
    setState(() {
      _emojiShowing = false;
    });
    
    // استخدام نسخة محلية من النص لتجنب المشاكل
    final contentToPost = _commentController.text;
    _commentController.clear();

    try {
      await _communityService.addComment(
        postId: widget.post.id,
        content: contentToPost,
      );
      await _loadPost();
    } catch (e) {
      if (mounted) {
        // إعادة النص في حالة الفشل
        _commentController.text = contentToPost;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToAddComment)),
        );
      }
    }
  }

  void _onEmojiSelected(Emoji emoji) {
    _commentController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _commentController.text.length));
  }

  void _onBackspacePressed() {
    _commentController
      ..text = _commentController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _commentController.text.length));
  }
  
  void _toggleEmojiKeyboard() {
    if (_emojiShowing) {
      _commentFocusNode.requestFocus();
    } else {
      _commentFocusNode.unfocus();
    }
    setState(() {
      _emojiShowing = !_emojiShowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.postDetailsPageTitle),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _post == null
                ? Center(child: Text(localizations.postNotFound))
                : Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                             // إخفاء الكيبورد أو الإيموجي عند الضغط خارج منطقة الإدخال
                            _commentFocusNode.unfocus();
                            if (_emojiShowing) {
                              setState(() {
                                _emojiShowing = false;
                              });
                            }
                          },
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PostCard(
                                  post: _post!.copyWith(comments: _comments),
                                  heroTagPrefix: widget.heroTagPrefix,
                                  isDetailView: true,
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    localizations.comments,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ..._buildCommentsList(localizations),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildCommentInput(localizations),
                       Offstage(
                        offstage: !_emojiShowing,
                        child: SizedBox(
                          height: 250,
                          child: EmojiPicker(
                            textEditingController: _commentController,
                            onEmojiSelected: (Category? category, Emoji emoji) {
                              _onEmojiSelected(emoji);
                            },
                            onBackspacePressed: _onBackspacePressed,
                            config: Config(
                              height: 256,
                              checkPlatformCompatibility: true,
                              emojiViewConfig: EmojiViewConfig(
                                emojiSizeMax: 28 *
                                    (foundation.defaultTargetPlatform ==
                                            TargetPlatform.iOS
                                        ? 1.20
                                        : 1.0),
                                columns: 7,
                                verticalSpacing: 0,
                                horizontalSpacing: 0,
                                gridPadding: EdgeInsets.zero,
                                recentsLimit: 28,
                                noRecents: Text(
                                  localizations.noRecents,
                                  style: const TextStyle(
                                      fontSize: 20, color: Colors.black26),
                                  textAlign: TextAlign.center,
                                ),
                                loadingIndicator: const SizedBox.shrink(),
                                buttonMode: ButtonMode.MATERIAL,
                                backgroundColor: const Color(0xFFF2F2F2),
                              ),
                              skinToneConfig: const SkinToneConfig(
                                dialogBackgroundColor: Colors.white,
                                indicatorColor: Colors.grey,
                              ),
                              categoryViewConfig: CategoryViewConfig(
                                initCategory: Category.RECENT,
                                backgroundColor: const Color(0xFFF2F2F2),
                                indicatorColor: Theme.of(context).primaryColor,
                                iconColor: Colors.grey,
                                iconColorSelected:
                                    Theme.of(context).primaryColor,
                                backspaceColor: Theme.of(context).primaryColor,
                                recentTabBehavior: RecentTabBehavior.RECENT,
                                tabIndicatorAnimDuration: kTabScrollDuration,
                                categoryIcons: const CategoryIcons(),
                              ),
                              bottomActionBarConfig: const BottomActionBarConfig(
                                showBackspaceButton: false,
                                showSearchViewButton: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _buildCommentsList(AppLocalizations localizations) {
    if (_comments.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              localizations.noCommentsYet,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ),
      ];
    }
    return _comments.map((comment) {
      return CommentCard(
        comment: comment,
        postId: widget.post.id,
        onCommentUpdated: _loadPost,
      );
    }).toList();
  }

  Widget _buildCommentInput(AppLocalizations localizations) {
    final user = _auth.currentUser;
    String userImage = user?.photoURL ?? 'assets/images/logo.png';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(userImage),
            onBackgroundImageError: (exception, stackTrace) {
              // fallback to asset image can be handled if needed
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.emoji_emotions_outlined,
              color: _emojiShowing ? Theme.of(context).primaryColor : Colors.grey,
            ),
            onPressed: _toggleEmojiKeyboard,
          ),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: Localizations.localeOf(context).languageCode == 'ar'
                    ? "أضف تعليقًا..."
                    : "Add a comment...",
                border: InputBorder.none,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
              textDirection: Localizations.localeOf(context).languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            color: Theme.of(context).primaryColor,
            onPressed: _addComment,
          ),
        ],
      ),
    );
  }
} 