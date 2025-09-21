import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sumi/features/auth/presentation/pages/profile_page.dart';
import 'package:sumi/features/home/presentation/widgets/community_tab.dart';
import 'package:sumi/features/home/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:sumi/features/home/presentation/widgets/home_tab.dart';
import 'package:sumi/features/home/presentation/widgets/services_tab.dart';
import 'package:sumi/features/home/presentation/widgets/store_tab.dart';
import 'package:sumi/features/home/presentation/widgets/video_tab.dart';
import 'package:sumi/features/notifications/presentation/pages/notifications_page.dart';
import 'package:sumi/features/notifications/services/notification_service.dart';
import 'package:sumi/features/store/presentation/pages/cart_page.dart';
import 'package:sumi/features/store/services/cart_service.dart';
import 'package:sumi/features/search/presentation/delegates/custom_search_delegate.dart';
import 'package:sumi/core/services/feature_flag_service.dart';
import 'package:sumi/core/services/bottom_nav_order_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final FeatureFlagService _featureFlagService = FeatureFlagService();
  final BottomNavOrderService _bottomNavOrderService = BottomNavOrderService();

  late Future<List<Widget>> _tabsFuture;
  late Future<List<Map<String, dynamic>>> _navItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }

  void _loadFeatures() {
    // نحصل على feature flags وترتيب الشريط السفلي معاً
    final combinedFuture = Future.wait([
      Future.wait([
        _featureFlagService.isFeatureEnabled('community'),
        _featureFlagService.isFeatureEnabled('store'),
        _featureFlagService.isFeatureEnabled('services'),
        _featureFlagService.isFeatureEnabled('video'),
      ]).then((results) => {
        'home': true, // الرئيسية دائماً مفعلة
        'community': results[0],
        'store': results[1],
        'services': results[2],
        'video': results[3],
      }),
      _bottomNavOrderService.getBottomNavOrder(),
    ]);

    _tabsFuture = _buildTabs(combinedFuture);
    _navItemsFuture = _buildNavItems(combinedFuture);
  }

  Future<List<Widget>> _buildTabs(Future<List<dynamic>> combinedFuture) async {
    final results = await combinedFuture;
    final features = results[0] as Map<String, bool>;
    final navData = results[1] as Map<String, dynamic>;

    // الحصول على العناصر المرتبة والمفعلة
    final orderedItems = _bottomNavOrderService.getOrderedEnabledItems(features, navData);
    
    final List<Widget> tabs = [];
    
    for (final item in orderedItems) {
      final tabType = item['tabType'] as String;
      switch (tabType) {
        case 'home':
          tabs.add(const HomeTab());
          break;
        case 'community':
          tabs.add(const CommunityTab());
          break;
        case 'store':
          tabs.add(const StoreTab());
          break;
        case 'services':
          tabs.add(const ServicesTab());
          break;
        case 'video':
          tabs.add(const VideoTab());
          break;
      }
    }
    
    return tabs;
  }
  
  Future<List<Map<String, dynamic>>> _buildNavItems(Future<List<dynamic>> combinedFuture) async {
    final results = await combinedFuture;
    final features = results[0] as Map<String, bool>;
    final navData = results[1] as Map<String, dynamic>;

    // الحصول على العناصر المرتبة والمفعلة
    final orderedItems = _bottomNavOrderService.getOrderedEnabledItems(features, navData);
    
    return orderedItems.map((item) => {
      'iconPath': item['iconPath'] as String,
      'label': item['label'] as String,
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // إزالة AppBar العادي واستبداله بـ top navigation مخصص
      extendBodyBehindAppBar: true,
      body: FutureBuilder<List<Widget>>(
        future: _tabsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No features available.'));
          }
          
          final tabs = snapshot.data!;
          return PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: tabs,
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<List<Map<String, dynamic>>>(
        future: _navItemsFuture,
        builder: (context, snapshot) {
           if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a placeholder or loading indicator for the nav bar
            return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return const SizedBox(height: 60, child: Center(child: Text('Could not load navigation.')));
          }
           if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          final navItems = snapshot.data!;
          return CustomBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              _pageController.jumpToPage(index);
            },
            items: navItems,
          );
        },
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge();

  @override
  Widget build(BuildContext context) {
    // We create an instance of the service here, but in a larger app,
    // you might provide it higher up the widget tree.
    final notificationService = NotificationService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
                );
              },
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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


class _CartBadge extends StatelessWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartService>(
      builder: (context, cart, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
            if (cart.itemCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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