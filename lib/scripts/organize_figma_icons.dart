#!/usr/bin/env dart

import 'dart:io';

/// Figma Icons Organizer Script
/// This script helps organize and validate Figma icons for the bottom navigation
class FigmaIconsOrganizer {
  static const String figmaIconsPath = 'assets/icons/figma';
  
  // Expected new icon names from Figma
  static const Map<String, String> expectedIcons = {
    'home': 'home_icon.svg',
    'community': 'community_icon.svg', 
    'store': 'store_icon.svg',
    'services': 'services_icon.svg',
    'video': 'video_icon.svg',
  };

  // Old icons to be removed
  static const List<String> oldIcons = [
    'house_bolt.svg',
    'user_group.svg',
    'user-group.svg', 
    'bags_shopping.svg',
    'bags-shopping.svg',
    'grid_circle.svg',
    'frame2.svg',
    'bell_alt.svg',
    'search_alt.svg',
  ];

  /// Clean old icons
  static Future<void> cleanOldIcons() async {
    print('🧹 Cleaning old navigation icons...');
    
    final figmaDir = Directory(figmaIconsPath);
    if (!await figmaDir.exists()) {
      print('❌ Figma icons directory not found!');
      return;
    }

    for (final oldIcon in oldIcons) {
      final file = File('$figmaIconsPath/$oldIcon');
      if (await file.exists()) {
        await file.delete();
        print('   ✅ Deleted: $oldIcon');
      }
    }
    
    print('✨ Old icons cleanup completed!');
  }

  /// Validate new icons are present
  static Future<bool> validateNewIcons() async {
    print('🔍 Validating new Figma icons...');
    
    final figmaDir = Directory(figmaIconsPath);
    if (!await figmaDir.exists()) {
      print('❌ Figma icons directory not found!');
      return false;
    }

    bool allPresent = true;
    for (final entry in expectedIcons.entries) {
      final file = File('$figmaIconsPath/${entry.value}');
      if (await file.exists()) {
        print('   ✅ Found: ${entry.value} (for ${entry.key})');
      } else {
        print('   ❌ Missing: ${entry.value} (for ${entry.key})');
        allPresent = false;
      }
    }

    if (allPresent) {
      print('🎉 All required icons are present!');
    } else {
      print('⚠️  Some icons are missing. Please download them from Figma.');
    }
    
    return allPresent;
  }

  /// List all current icons in figma directory
  static Future<void> listCurrentIcons() async {
    print('📋 Current icons in figma directory:');
    
    final figmaDir = Directory(figmaIconsPath);
    if (!await figmaDir.exists()) {
      print('❌ Figma icons directory not found!');
      return;
    }

    final files = await figmaDir.list().toList();
    final svgFiles = files
        .where((file) => file.path.endsWith('.svg'))
        .map((file) => file.path.split(Platform.pathSeparator).last)
        .toList();

    if (svgFiles.isEmpty) {
      print('   📂 Directory is empty');
    } else {
      for (final file in svgFiles) {
        print('   📄 $file');
      }
    }
  }

  /// Main execution
  static Future<void> organize() async {
    print('🚀 Starting Figma Icons Organization...\n');
    
    // List current icons
    await listCurrentIcons();
    print('');
    
    // Clean old icons
    await cleanOldIcons();
    print('');
    
    // Validate new icons
    final isValid = await validateNewIcons();
    print('');
    
    if (isValid) {
      print('✅ Icons organization completed successfully!');
      print('🔄 You can now run the app to see the new icons.');
    } else {
      print('📥 Next steps:');
      print('1. Download icons from Figma with these exact names:');
      for (final entry in expectedIcons.entries) {
        print('   • ${entry.value} (for ${entry.key} tab)');
      }
      print('2. Place them in: $figmaIconsPath/');
      print('3. Run this script again to validate');
    }
  }
}

void main() async {
  await FigmaIconsOrganizer.organize();
}
