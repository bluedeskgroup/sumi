import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class BottomNavOrderService {
  final CollectionReference _bottomNavCollection = 
      FirebaseFirestore.instance.collection('bottom_nav_items');

  // تخزين مؤقت للعناصر
  Map<String, dynamic>? _cachedNavData;

  // الحصول على ترتيب وحالة عناصر الشريط السفلي
  Future<Map<String, dynamic>> getBottomNavOrder() async {
    try {
      // إذا كان لدينا cache، استخدمه
      if (_cachedNavData != null) {
        return _cachedNavData!;
      }

      final querySnapshot = await _bottomNavCollection
          .orderBy('order')
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        // إعدادات افتراضية إذا لم توجد بيانات
        return _getDefaultNavOrder();
      }

      final navOrder = <String, int>{};
      final navEnabled = <String, bool>{};
      final navLabels = <String, String>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tabType = data['tabType'] as String;
        
        navOrder[tabType] = data['order'] ?? 0;
        navEnabled[tabType] = data['isEnabled'] ?? true;
        navLabels[tabType] = data['label'] ?? '';
      }

      _cachedNavData = {
        'order': navOrder,
        'enabled': navEnabled,
        'labels': navLabels,
      };

      return _cachedNavData!;
    } catch (e) {
      debugPrint('Error loading bottom nav order: $e');
      // في حالة الخطأ، أرجع الإعدادات الافتراضية
      return _getDefaultNavOrder();
    }
  }

  // إعدادات افتراضية
  Map<String, dynamic> _getDefaultNavOrder() {
    return {
      'order': {
        'home': 0,
        'community': 1,
        'store': 2,
        'services': 3,
        'video': 4,
      },
      'enabled': {
        'home': true,
        'community': true,
        'store': true,
        'services': true,
        'video': true,
      },
      'labels': {
        'home': 'الرئيسية',
        'community': 'المجتمع',
        'store': 'المتجر',
        'services': 'خدمات',
        'video': 'فيديو',
      },
    };
  }

  // مسح الـ cache لإعادة تحميل البيانات
  void clearCache() {
    _cachedNavData = null;
  }

  // فلترة وترتيب العناصر المفعلة
  List<Map<String, dynamic>> getOrderedEnabledItems(
    Map<String, bool> featureFlags,
    Map<String, dynamic> navData,
  ) {
    final order = navData['order'] as Map<String, int>;
    final enabled = navData['enabled'] as Map<String, bool>;
    final labels = navData['labels'] as Map<String, String>;

    final items = <Map<String, dynamic>>[];

    // إضافة العناصر المفعلة بناءً على feature flags والإعدادات
    for (final entry in order.entries) {
      final tabType = entry.key;
      final orderIndex = entry.value;
      
      // التحقق من أن العنصر مفعل في الإعدادات وفي feature flags
      final isFeatureEnabled = featureFlags[tabType] ?? false;
      final isNavEnabled = enabled[tabType] ?? false;
      
      if (isFeatureEnabled && isNavEnabled) {
        items.add({
          'tabType': tabType,
          'order': orderIndex,
          'label': labels[tabType] ?? _getDefaultLabel(tabType),
          'iconPath': _getDefaultIconPath(tabType),
        });
      }
    }

    // ترتيب العناصر حسب الـ order
    items.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
    
    return items;
  }

  String _getDefaultLabel(String tabType) {
    switch (tabType) {
      case 'home':
        return 'الرئيسية';
      case 'community':
        return 'المجتمع';
      case 'store':
        return 'المتجر';
      case 'services':
        return 'خدمات';
      case 'video':
        return 'فيديو';
      default:
        return 'غير محدد';
    }
  }

  String _getDefaultIconPath(String tabType) {
    // Updated to use new Figma icons - replace with actual downloaded icons
    switch (tabType) {
      case 'home':
        return 'assets/icons/figma/home_icon.svg'; // New home icon from Figma
      case 'community':
        return 'assets/icons/figma/community_icon.svg'; // New community icon from Figma
      case 'store':
        return 'assets/icons/figma/store_icon.svg'; // New store icon from Figma
      case 'services':
        return 'assets/icons/figma/services_icon.svg'; // New services icon from Figma
      case 'video':
        return 'assets/icons/figma/video_icon.svg'; // New video icon from Figma
      default:
        return 'assets/icons/figma/home_icon.svg'; // Fallback to home icon
    }
  }
}
