import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class StoryNotificationsWidget extends StatelessWidget {
  final List<StoryNotification> notifications;

  const StoryNotificationsWidget({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF9A46D7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'إشعارات القصص',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
                const Spacer(),
                Text(
                  '${notifications.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Notifications list
          AnimationLimiter(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length > 5 ? 5 : notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildNotificationItem(notification),
                    ),
                  ),
                );
              },
            ),
          ),

          // Show more button
          if (notifications.length > 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to full notifications page
                },
                child: const Text(
                  'عرض المزيد',
                  style: TextStyle(
                    color: Color(0xFF9A46D7),
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(StoryNotification notification) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.grey[50] : const Color(0xFF9A46D7).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Notification icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getNotificationColor(notification.type).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 16,
            ),
          ),

          const SizedBox(width: 12),

          // Notification content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Ping AR + LT',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(notification.timestamp, locale: 'ar'),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ],
            ),
          ),

          // Unread indicator
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF9A46D7),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(StoryNotificationType type) {
    switch (type) {
      case StoryNotificationType.like:
        return Icons.favorite;
      case StoryNotificationType.comment:
        return Icons.comment;
      case StoryNotificationType.follow:
        return Icons.person_add;
      case StoryNotificationType.mention:
        return Icons.alternate_email;
      case StoryNotificationType.pollVote:
        return Icons.poll;
      case StoryNotificationType.storyView:
        return Icons.visibility;
    }
  }

  Color _getNotificationColor(StoryNotificationType type) {
    switch (type) {
      case StoryNotificationType.like:
        return Colors.red;
      case StoryNotificationType.comment:
        return Colors.blue;
      case StoryNotificationType.follow:
        return Colors.green;
      case StoryNotificationType.mention:
        return Colors.orange;
      case StoryNotificationType.pollVote:
        return Colors.purple;
      case StoryNotificationType.storyView:
        return const Color(0xFF9A46D7);
    }
  }
}

// Notification model
class StoryNotification {
  final String id;
  final String title;
  final String message;
  final StoryNotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? userImage;
  final String? storyId;

  StoryNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.userImage,
    this.storyId,
  });
}

enum StoryNotificationType {
  like,
  comment,
  follow,
  mention,
  pollVote,
  storyView,
}
