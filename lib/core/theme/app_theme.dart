import 'package:flutter/material.dart';
import 'package:sumi/core/services/preferences_service.dart';

class AppTheme {
  // الألوان الأساسية
  static const Color primaryColor = Color(0xFF9A46D7);
  static const Color secondaryColor = Color(0xFF6200EA);
  static const Color accentColor = Color(0xFFBB86FC);

  // الوضع الفاتح
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: Colors.white,
      background: Color(0xFFF8F9FA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
    ),
    
    // شريط التطبيق
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Ping AR + LT',
      ),
    ),

    // البطاقات
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // الأزرار المرفوعة
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Ping AR + LT',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // حقول النص
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // شريط التنقل السفلي
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // النصوص
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Ping AR + LT',
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Ping AR + LT',
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Ping AR + LT',
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Ping AR + LT',
        color: Colors.black87,
      ),
    ),
  );

  // الوضع المظلم
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),

    // شريط التطبيق
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Ping AR + LT',
      ),
    ),

    // البطاقات
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // الأزرار المرفوعة
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Ping AR + LT',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // حقول النص
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // شريط التنقل السفلي
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // النصوص
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Ping AR + LT',
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Ping AR + LT',
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Ping AR + LT',
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Ping AR + LT',
        color: Colors.white,
      ),
    ),
  );
}

// مزود الوضع المظلم
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  ThemeData get currentTheme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  Future<void> initializeTheme() async {
    if (_isInitialized) return;
    
    try {
      final PreferencesService prefs = PreferencesService();
      await prefs.init();
      _isDarkMode = prefs.isDarkMode;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      _isInitialized = true;
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    try {
      final PreferencesService prefs = PreferencesService();
      await prefs.setDarkMode(_isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
    
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;
    
    _isDarkMode = isDark;
    
    try {
      final PreferencesService prefs = PreferencesService();
      await prefs.setDarkMode(_isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
    
    notifyListeners();
  }
}
