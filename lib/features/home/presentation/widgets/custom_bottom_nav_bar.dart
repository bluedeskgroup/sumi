import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumi/l10n/app_localizations.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<Map<String, dynamic>> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final bottomPadding = mediaQuery.padding.bottom;
    final viewInsets = mediaQuery.viewInsets.bottom;
    
    // Calculate responsive dimensions based on screen size
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    final isLargeScreen = screenWidth >= 400;
    
    // Adaptive horizontal padding (3-6% of screen width)
    final horizontalPadding = (screenWidth * 0.045).clamp(12.0, 24.0);
    
    // Adaptive vertical padding with better handling for different screen types
    final topPadding = isSmallScreen ? 12.0 : 16.0;
    final bottomBasePadding = isSmallScreen ? 12.0 : 16.0;
    
    // Smart bottom padding handling for different device types
    double finalBottomPadding;
    if (bottomPadding > 0) {
      // Devices with home indicator (iPhone X+, some Android)
      finalBottomPadding = bottomPadding + bottomBasePadding;
    } else {
      // Devices with navigation buttons or older devices
      finalBottomPadding = bottomBasePadding + (isSmallScreen ? 8.0 : 12.0);
    }
    
    // Responsive icon and text sizes
    final iconSize = isSmallScreen ? 20.0 : (isMediumScreen ? 22.0 : 24.0);
    final fontSize = isSmallScreen ? 10.0 : (isMediumScreen ? 11.0 : 12.0);
    final iconTextGap = isSmallScreen ? 6.0 : (isMediumScreen ? 8.0 : 10.0);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding, 
        top: topPadding,
        bottom: finalBottomPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // Exact Figma white #FFFFFF
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF171717).withOpacity(0.06), // Exact Figma shadow rgba(23, 23, 23, 0.06)
            blurRadius: 31.7, // Exact Figma blur
            offset: const Offset(0, 4), // Exact Figma offset
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero, // Remove SafeArea's default padding since we handle it manually
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better distribution for responsive
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final bool isSelected = currentIndex == index;
            
            // Calculate max width per item based on screen size and number of items
            final availableWidth = screenWidth - (horizontalPadding * 2);
            final maxItemWidth = (availableWidth / items.length).clamp(50.0, 90.0);
            
            return Flexible(
              child: Container(
                constraints: BoxConstraints(
                  minWidth: 50,
                  maxWidth: maxItemWidth,
                ),
                child: _buildNavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                  isArabic: isArabic,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  iconTextGap: iconTextGap,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required Map<String, dynamic> item,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isArabic,
    required double iconSize,
    required double fontSize,
    required double iconTextGap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon - responsive size
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: _buildIcon(
              iconPath: item['iconPath'],
              isSelected: isSelected,
              size: iconSize,
            ),
          ),
          
          SizedBox(height: iconTextGap), // Responsive gap
          
          // Label - responsive text style
          Text(
            item['label'],
            style: TextStyle(
              fontFamily: 'Ping AR + LT', // Exact Figma font
              fontSize: fontSize, // Responsive font size
              fontWeight: FontWeight.w700, // Exact Figma font weight (700)
              color: isSelected 
                  ? const Color(0xFF9A46D7) // Exact Figma selected #9A46D7
                  : const Color(0xFFC9CEDC), // Exact Figma unselected #C9CEDC
              height: 1.6, // Exact Figma line height
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIcon({
    required String iconPath,
    required bool isSelected,
    required double size,
  }) {
    // Exact Figma colors
    final selectedColor = const Color(0xFF9A46D7); // Exact Figma selected #9A46D7
    final unselectedColor = const Color(0xFFC9CEDC); // Exact Figma unselected #C9CEDC
    
    if (iconPath.endsWith('.svg')) {
      return SvgPicture.asset(
        iconPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          isSelected ? selectedColor : unselectedColor,
          BlendMode.srcIn,
        ),
        placeholderBuilder: (context) => Icon(
          _getDefaultIcon(iconPath),
          size: size,
          color: isSelected ? selectedColor : unselectedColor,
        ),
      );
    } else {
      return Image.asset(
        iconPath,
        width: size,
        height: size,
        color: isSelected ? selectedColor : unselectedColor,
        errorBuilder: (context, error, stackTrace) {
          // Fallback icon if image fails to load
          return Icon(
            _getDefaultIcon(iconPath),
            size: size,
            color: isSelected ? selectedColor : unselectedColor,
          );
        },
      );
    }
  }
  
  IconData _getDefaultIcon(String iconPath) {
    // Enhanced fallback icons mapping for new Figma icons
    if (iconPath.contains('home') || iconPath.contains('house')) {
      return Icons.home_outlined;
    } else if (iconPath.contains('community') || iconPath.contains('user') || iconPath.contains('group')) {
      return Icons.groups_outlined;
    } else if (iconPath.contains('store') || iconPath.contains('shop') || iconPath.contains('bag')) {
      return Icons.shopping_bag_outlined;
    } else if (iconPath.contains('service') || iconPath.contains('grid')) {
      return Icons.grid_view_outlined;
    } else if (iconPath.contains('video') || iconPath.contains('play') || iconPath.contains('frame')) {
      return Icons.play_circle_outline;
    } else if (iconPath.contains('search')) {
      return Icons.search_outlined;
    } else {
      return Icons.circle_outlined;
    }
  }
} 