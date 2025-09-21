import 'package:flutter/material.dart';
import 'package:sumi/core/services/notification_service.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color? badgeColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    required this.child,
    this.badgeColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        if (unreadCount == 0) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Widget للاستخدام السريع في أيقونة الإشعارات
class NotificationIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;

  const NotificationIcon({
    super.key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NotificationBadge(
        child: Icon(
          Icons.notifications_outlined,
          color: iconColor ?? Theme.of(context).iconTheme.color,
          size: iconSize,
        ),
      ),
    );
  }
}
