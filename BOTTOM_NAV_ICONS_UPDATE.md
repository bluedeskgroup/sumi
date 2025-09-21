# Bottom Navigation Icons Update Guide

## Current Status
- Current icons are located in `assets/icons/figma/`
- Icons are mapped in `BottomNavOrderService._getDefaultIconPath()`

## Current Icon Mappings:
- **Home**: `house_bolt.svg` 
- **Community**: `user_group.svg`
- **Store**: `bags_shopping.svg` 
- **Services**: `grid_circle.svg`
- **Video**: `frame2.svg`

## Steps to Update Icons from Figma:

### 1. Download from Figma
- Open: https://www.figma.com/design/wSHGO6PDHxrz8dRYo3jrdW/Sumi-App--Copy-?node-id=5016-15829&t=Lc2AOLEDqUbUJYtE-4
- Select each bottom navigation icon
- Export as SVG (24x24 or 32x32 pixels recommended)
- Use these names:
  - `home_icon.svg`
  - `community_icon.svg` 
  - `store_icon.svg`
  - `services_icon.svg`
  - `video_icon.svg`

### 2. Replace Icons
- Delete old icons from `assets/icons/figma/`
- Place new icons in `assets/icons/figma/`

### 3. Update Code
The code will be automatically updated once you provide the new icons.

## Files to Update:
1. `assets/icons/figma/` - Place new icons here
2. `lib/core/services/bottom_nav_order_service.dart` - Update icon mappings
3. `pubspec.yaml` - Ensure assets are listed (already configured)