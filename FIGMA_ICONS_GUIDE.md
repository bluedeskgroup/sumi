# 📱 Bottom Navigation Icons Update Guide

## 🎯 What You Need to Do

### 1. Download Icons from Figma
- Open the Figma link: https://www.figma.com/design/wSHGO6PDHxrz8dRYo3jrdW/Sumi-App--Copy-?node-id=5016-15829&t=Lc2AOLEDqUbUJYtE-4
- Select each bottom navigation icon in the design
- Export each icon as **SVG format** 
- Recommended size: **24x24** or **32x32** pixels
- Save them with these **exact names**:

```
📁 Download these 5 icons:
├── home_icon.svg       (for Home tab)
├── community_icon.svg  (for Community tab) 
├── store_icon.svg      (for Store tab)
├── services_icon.svg   (for Services tab)
└── video_icon.svg      (for Video tab)
```

### 2. Replace Old Icons
- Navigate to: `d:\amir\sumi\assets\icons\figma\`
- **Delete all old icon files** in this folder
- **Copy your new 5 icons** into this folder

### 3. Verify Integration
- The code is already updated to use the new icon names
- Run the organize script: `dart lib/scripts/organize_figma_icons.dart`
- This will validate all icons are properly placed

### 4. Test the App
- Run: `flutter run`
- Check that all bottom navigation icons display correctly
- Both selected and unselected states should work

## 🔧 What's Already Done

✅ **Bottom Navigation Service** - Updated to use new icon paths  
✅ **Custom Bottom Nav Bar** - Enhanced with fallback icon system  
✅ **Error Handling** - Graceful fallbacks if icons are missing  
✅ **Organization Scripts** - Tools to validate and organize icons  

## 📋 File Locations

```
📂 Assets Directory:
   └── assets/icons/figma/
       ├── home_icon.svg      ← Place here
       ├── community_icon.svg ← Place here
       ├── store_icon.svg     ← Place here
       ├── services_icon.svg  ← Place here
       └── video_icon.svg     ← Place here

📂 Code Files (Already Updated):
   ├── lib/core/services/bottom_nav_order_service.dart
   ├── lib/features/home/presentation/widgets/custom_bottom_nav_bar.dart
   └── lib/scripts/organize_figma_icons.dart
```

## 🚨 Important Notes

- **Use exact file names** as specified above
- **SVG format only** for best quality and scalability  
- **Delete old icons** to avoid conflicts
- The app will use fallback Material icons if SVG fails to load

## 🎯 Quick Steps Summary

1. **Download** 5 icons from Figma as SVG
2. **Delete** old icons from `assets/icons/figma/`
3. **Copy** new icons with exact names to `assets/icons/figma/`
4. **Run** `flutter run` to test

That's it! The integration is ready and waiting for your Figma icons. 🚀