import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sumi/core/services/notification_service.dart';
import 'package:sumi/core/widgets/animated_page_route.dart';
import 'package:sumi/features/story/presentation/pages/enhanced_story_viewer_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // تحديد جميع الإشعارات كمقروءة عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.markAllAsRead();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontFamily: 'Ping AR + LT'),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'القصص'),
            Tab(text: 'التفاعلات'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text(
                      'تحديد الكل كمقروء',
                      style: TextStyle(fontFamily: 'Ping AR + LT'),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'حذف الكل',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(),
          _buildNotificationsList(filter: 'story'),
          _buildNotificationsList(filter: 'interaction'),
        ],
      ),
    );
  }

  Widget _buildNotificationsList({String? filter}) {
    return StreamBuilder<List<AppNotification>>(
      stream: _notificationService.getUserNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final notifications = snapshot.data ?? [];
        final filteredNotifications = _filterNotifications(notifications, filter);

        if (filteredNotifications.isEmpty) {
          return _buildEmptyState();
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildNotificationItem(filteredNotifications[index]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<AppNotification> _filterNotifications(
    List<AppNotification> notifications,
    String? filter,
  ) {
    if (filter == null) return notifications;
    
    switch (filter) {
      case 'story':
        return notifications
            .where((n) => n.type == 'new_story' || n.type == 'story_reply')
            .toList();
      case 'interaction':
        return notifications
            .where((n) => n.type == 'story_interaction')
            .toList();
      default:
        return notifications;
    }
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? Theme.of(context).cardColor 
            : Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: notification.isRead 
            ? null 
            : Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: notification.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            notification.icon,
            color: notification.color,
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontFamily: 'Ping AR + LT',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(fontFamily: 'Ping AR + LT'),
            ),
            const SizedBox(height: 8),
            Text(
              timeago.format(notification.createdAt, locale: 'ar'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleNotificationAction(value, notification),
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'تحديد كمقروء',
                      style: TextStyle(fontFamily: 'Ping AR + LT'),
                    ),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'حذف',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _onNotificationTap(notification),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
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
            'حدث خطأ في تحميل الإشعارات',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Ping AR + LT',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
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
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              fontFamily: 'Ping AR + LT',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر إشعاراتك هنا عند وصولها',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Ping AR + LT',
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        _notificationService.markAllAsRead();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تحديد جميع الإشعارات كمقروءة',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
        );
        break;
      case 'delete_all':
        _showDeleteAllDialog();
        break;
    }
  }

  void _handleNotificationAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        _notificationService.markAsRead(notification.id);
        break;
      case 'delete':
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حذف الإشعار',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
        );
        break;
    }
  }

  void _onNotificationTap(AppNotification notification) {
    // تحديد الإشعار كمقروء
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // التنقل حسب نوع الإشعار
    if (notification.storyId != null) {
      // يمكن إضافة منطق للحصول على القصة والتنقل إليها
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سيتم فتح القصة قريباً',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
        ),
      );
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف جميع الإشعارات',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        content: const Text(
          'هل أنت متأكد من حذف جميع الإشعارات؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _notificationService.deleteAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'تم حذف جميع الإشعارات',
                    style: TextStyle(fontFamily: 'Ping AR + LT'),
                  ),
                ),
              );
            },
            child: const Text(
              'حذف',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}