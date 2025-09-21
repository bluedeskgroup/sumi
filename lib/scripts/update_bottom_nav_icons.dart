import 'dart:io';

/// Script to help update bottom navigation icons
/// Usage: Place new icons in assets/icons/figma/ and run this script to verify they're properly linked
class BottomNavIconUpdater {
  
  // Current icon mappings from BottomNavOrderService
  static const Map<String, String> currentIconMappings = {
    'home': 'assets/icons/figma/house_bolt.svg',
    'community': 'assets/icons/figma/user_group.svg', 
    'store': 'assets/icons/figma/bags_shopping.svg',
    'services': 'assets/icons/figma/grid_circle.svg',
    'video': 'assets/icons/figma/frame2.svg',
  };

  // Recommended new icon names from Figma
  static const Map<String, String> recommendedIconNames = {
    'home': 'home_icon.svg',
    'community': 'community_icon.svg',
    'store': 'store_icon.svg', 
    'services': 'services_icon.svg',
    'video': 'video_icon.svg',
  };

  /// Check which icons exist in the figma directory
  static Future<void> checkExistingIcons() async {
    print('=== Current Bottom Navigation Icons ===');
    
    final figmaDir = Directory('assets/icons/figma');
    if (!await figmaDir.exists()) {
      print('❌ Figma icons directory not found!');
      return;
    }

    final files = await figmaDir.list().toList();
    final svgFiles = files
        .where((file) => file.path.endsWith('.svg'))
        .map((file) => file.path.split('/').last)
        .toList();

    print('📁 Available SVG icons in figma directory:');
    for (final file in svgFiles) {
      print('  • $file');
    }

    print('\n=== Current Mappings ===');
    for (final entry in currentIconMappings.entries) {
      final iconName = entry.value.split('/').last;
      final exists = svgFiles.contains(iconName);
      final status = exists ? '✅' : '❌';
      print('  $status ${entry.key}: $iconName');
    }

    print('\n=== Instructions ===');
    print('1. Download icons from Figma');
    print('2. Save them as SVG format in assets/icons/figma/');
    print('3. Use these recommended names:');
    for (final entry in recommendedIconNames.entries) {
      print('   • ${entry.key}: ${entry.value}');
    }
    print('4. Update the _getDefaultIconPath method in BottomNavOrderService');
  }

  /// Generate updated code for BottomNavOrderService
  static String generateUpdatedIconMappingCode() {
    return '''
  String _getDefaultIconPath(String tabType) {
    switch (tabType) {
      case 'home':
        return 'assets/icons/figma/home_icon.svg';
      case 'community':
        return 'assets/icons/figma/community_icon.svg';
      case 'store':
        return 'assets/icons/figma/store_icon.svg';
      case 'services':
        return 'assets/icons/figma/services_icon.svg';
      case 'video':
        return 'assets/icons/figma/video_icon.svg';
      default:
        return 'assets/icons/figma/home_icon.svg';
    }
  }
''';
  }
}

void main() async {
  await BottomNavIconUpdater.checkExistingIcons();
  print('\n=== Generated Code ===');
  print(BottomNavIconUpdater.generateUpdatedIconMappingCode());
}