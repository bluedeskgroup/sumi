import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class StoryRepliesPage extends StatefulWidget {
  final String storyId;
  final String storyItemId;
  final String storyUserName;

  const StoryRepliesPage({
    super.key,
    required this.storyId,
    required this.storyItemId,
    required this.storyUserName,
  });

  @override
  State<StoryRepliesPage> createState() => _StoryRepliesPageState();
}

class _StoryRepliesPageState extends State<StoryRepliesPage>
    with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final TextEditingController _replyController = TextEditingController();

  late AnimationController _fabController;
  List<StoryReply> _replies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController.forward();
    _loadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    final replies = await _storyService.getStoryReplies(widget.storyId, widget.storyItemId);
    if (mounted) {
      setState(() {
        _replies = replies;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الردود على قصة ${widget.storyUserName}',
          style: const TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.bold,
            color: Color(0xFF9A46D7),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF9A46D7)),
      ),
      body: Column(
        children: [
          // Reply input
          _buildReplyInput(),

          // Replies list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _replies.isEmpty
                    ? _buildEmptyState()
                    : _buildRepliesList(),
          ),
        ],
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

  Widget _buildReplyInput() {
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: 'اكتب ردك...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: 'Ping AR + LT',
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
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendReply(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: const Color(0xFF9A46D7),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendReply,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد ردود بعد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontFamily: 'Ping AR + LT',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من يرد على هذه القصة',
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

  Widget _buildRepliesList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _replies.length,
        itemBuilder: (context, index) {
          final reply = _replies[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildReplyCard(reply),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyCard(StoryReply reply) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: reply.userImage.isNotEmpty
                  ? CachedNetworkImageProvider(reply.userImage)
                  : null,
              child: reply.userImage.isEmpty
                  ? Text(
                      reply.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            // Reply content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        reply.userName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9A46D7),
                          fontFamily: 'Ping AR + LT',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(reply.createdAt, locale: 'ar'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontFamily: 'Ping AR + LT',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reply.message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Ping AR + LT',
                      height: 1.4,
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

  void _sendReply() async {
    final replyText = _replyController.text.trim();
    if (replyText.isEmpty) return;

    final success = await _storyService.addReply(
      widget.storyId,
      widget.storyItemId,
      replyText,
    );

    if (success && mounted) {
      _replyController.clear();
      await _loadReplies();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال الرد بنجاح',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Color(0xFF9A46D7),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فشل في إرسال الرد، حاول مرة أخرى',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
