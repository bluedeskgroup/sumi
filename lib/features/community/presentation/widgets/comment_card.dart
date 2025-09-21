import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentCard extends StatefulWidget {
  final PostComment comment;
  final String postId;
  final VoidCallback onCommentUpdated;

  const CommentCard({
    super.key,
    required this.comment,
    required this.postId,
    required this.onCommentUpdated,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CommunityService _communityService = CommunityService();
  
  // قائمة الإيموجيز المتاحة للتفاعل
  final List<String> _availableReactions = ['❤️', '👍', '😂', '😢', '😠'];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    timeago.setLocaleMessages('en', timeago.EnMessages());
  }
  
  // دالة لإظهار لوحة اختيار الإيموجي
  void _showReactionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _availableReactions.map((reaction) {
              return IconButton(
                icon: Text(reaction, style: const TextStyle(fontSize: 28)),
                onPressed: () {
                  Navigator.of(context).pop();
                  _toggleReaction(reaction);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
  
  // دالة لمعالجة التفاعل
  Future<void> _toggleReaction(String reaction) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    
    // التحديث الفوري للواجهة
    setState(() {
      final reactions = widget.comment.reactions;
      String? userPreviousReaction;
      
      reactions.forEach((reac, userIds) {
        if (userIds.contains(currentUserId)) {
          userPreviousReaction = reac;
          userIds.remove(currentUserId);
        }
      });
      
      if (userPreviousReaction != reaction) {
        if (reactions.containsKey(reaction)) {
          reactions[reaction]!.add(currentUserId);
        } else {
          reactions[reaction] = [currentUserId];
        }
      }
      reactions.removeWhere((key, value) => value.isEmpty);
    });

    try {
      await _communityService.toggleCommentReaction(
        widget.postId,
        widget.comment.id,
        reaction,
      );
      widget.onCommentUpdated();
    } catch (e) {
      // يمكنك هنا إعادة الحالة السابقة إذا فشل التحديث
      debugPrint("Failed to toggle reaction: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: _getUserImage(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: _showReactionSheet,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.comment.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.comment.content,
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          if (widget.comment.reactions.isNotEmpty)
                            _buildReactionsDisplay(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                    child: Row(
                      children: [
                        Text(
                          _getTimeAgo(context),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: _showReactionSheet,
                          child: Text(
                            isArabic ? 'تفاعل' : 'React',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
  }
  
  Widget _buildReactionsDisplay() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 4.0,
        children: widget.comment.reactions.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(entry.key, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
                Text(
                  entry.value.length.toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTimeAgo(BuildContext context) {
    return timeago.format(
      widget.comment.createdAt,
      locale: Localizations.localeOf(context).languageCode,
    );
  }
  
  ImageProvider _getUserImage() {
    final imageUrl = widget.comment.userImage;
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    return const AssetImage('assets/images/logo.png');
  }
} 