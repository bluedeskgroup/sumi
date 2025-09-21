import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _languageKey = 'language_code';
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _autoSaveToGalleryKey = 'auto_save_to_gallery';
  static const String _allowSharingKey = 'allow_sharing';
  static const String _showViewCountKey = 'show_view_count';
  static const String _showReactionsKey = 'show_reactions';
  static const String _allowRepliesKey = 'allow_replies';
  static const String _searchHistoryKey = 'search_history';
  static const String _recentSearchesKey = 'recent_searches';
  static const String _hiddenUsersKey = 'hidden_users';

  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // الوضع المظلم
  Future<bool> setDarkMode(bool isDark) async {
    await init();
    return _prefs!.setBool(_isDarkModeKey, isDark);
  }

  bool get isDarkMode {
    return _prefs?.getBool(_isDarkModeKey) ?? false;
  }

  // اللغة
  Future<bool> setLanguage(String languageCode) async {
    await init();
    return _prefs!.setString(_languageKey, languageCode);
  }

  String get language {
    return _prefs?.getString(_languageKey) ?? 'ar';
  }

  // مقدمة التطبيق
  Future<bool> setHasSeenOnboarding(bool hasSeen) async {
    await init();
    return _prefs!.setBool(_hasSeenOnboardingKey, hasSeen);
  }

  bool get hasSeenOnboarding {
    return _prefs?.getBool(_hasSeenOnboardingKey) ?? false;
  }

  // إعدادات الإشعارات
  Future<bool> setNotificationsEnabled(bool enabled) async {
    await init();
    return _prefs!.setBool(_notificationsEnabledKey, enabled);
  }

  bool get notificationsEnabled {
    return _prefs?.getBool(_notificationsEnabledKey) ?? true;
  }

  // الحفظ التلقائي
  Future<bool> setAutoSaveToGallery(bool autoSave) async {
    await init();
    return _prefs!.setBool(_autoSaveToGalleryKey, autoSave);
  }

  bool get autoSaveToGallery {
    return _prefs?.getBool(_autoSaveToGalleryKey) ?? false;
  }

  // السماح بالمشاركة
  Future<bool> setAllowSharing(bool allow) async {
    await init();
    return _prefs!.setBool(_allowSharingKey, allow);
  }

  bool get allowSharing {
    return _prefs?.getBool(_allowSharingKey) ?? true;
  }

  // إظهار عدد المشاهدات
  Future<bool> setShowViewCount(bool show) async {
    await init();
    return _prefs!.setBool(_showViewCountKey, show);
  }

  bool get showViewCount {
    return _prefs?.getBool(_showViewCountKey) ?? true;
  }

  // إظهار التفاعلات
  Future<bool> setShowReactions(bool show) async {
    await init();
    return _prefs!.setBool(_showReactionsKey, show);
  }

  bool get showReactions {
    return _prefs?.getBool(_showReactionsKey) ?? true;
  }

  // السماح بالردود
  Future<bool> setAllowReplies(bool allow) async {
    await init();
    return _prefs!.setBool(_allowRepliesKey, allow);
  }

  bool get allowReplies {
    return _prefs?.getBool(_allowRepliesKey) ?? true;
  }

  // تاريخ البحث
  Future<bool> addToSearchHistory(String query) async {
    await init();
    final history = getSearchHistory();
    
    // إزالة الاستعلام إذا كان موجوداً من قبل
    history.remove(query);
    
    // إضافة الاستعلام في المقدمة
    history.insert(0, query);
    
    // الاحتفاظ بآخر 10 استعلامات فقط
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    
    return _prefs!.setStringList(_searchHistoryKey, history);
  }

  List<String> getSearchHistory() {
    return _prefs?.getStringList(_searchHistoryKey) ?? [];
  }

  Future<bool> clearSearchHistory() async {
    await init();
    return _prefs!.remove(_searchHistoryKey);
  }

  Future<bool> removeFromSearchHistory(String query) async {
    await init();
    final history = getSearchHistory();
    history.remove(query);
    return _prefs!.setStringList(_searchHistoryKey, history);
  }

  // البحثات الأخيرة
  Future<bool> addRecentSearch(String query) async {
    await init();
    final recent = getRecentSearches();
    
    recent.remove(query);
    recent.insert(0, query);
    
    if (recent.length > 5) {
      recent.removeRange(5, recent.length);
    }
    
    return _prefs!.setStringList(_recentSearchesKey, recent);
  }

  List<String> getRecentSearches() {
    return _prefs?.getStringList(_recentSearchesKey) ?? [];
  }

  Future<bool> clearRecentSearches() async {
    await init();
    return _prefs!.remove(_recentSearchesKey);
  }

  // المستخدمون المخفيون
  Future<bool> addHiddenUser(String userId) async {
    await init();
    final hiddenUsers = getHiddenUsers();
    
    if (!hiddenUsers.contains(userId)) {
      hiddenUsers.add(userId);
      return _prefs!.setStringList(_hiddenUsersKey, hiddenUsers);
    }
    
    return true;
  }

  Future<bool> removeHiddenUser(String userId) async {
    await init();
    final hiddenUsers = getHiddenUsers();
    hiddenUsers.remove(userId);
    return _prefs!.setStringList(_hiddenUsersKey, hiddenUsers);
  }

  List<String> getHiddenUsers() {
    return _prefs?.getStringList(_hiddenUsersKey) ?? [];
  }

  bool isUserHidden(String userId) {
    return getHiddenUsers().contains(userId);
  }

  Future<bool> clearHiddenUsers() async {
    await init();
    return _prefs!.remove(_hiddenUsersKey);
  }

  // مسح جميع الإعدادات
  Future<bool> clearAll() async {
    await init();
    return _prefs!.clear();
  }

  // نسخ احتياطي من الإعدادات
  Map<String, dynamic> exportSettings() {
    return {
      'isDarkMode': isDarkMode,
      'language': language,
      'hasSeenOnboarding': hasSeenOnboarding,
      'notificationsEnabled': notificationsEnabled,
      'autoSaveToGallery': autoSaveToGallery,
      'allowSharing': allowSharing,
      'showViewCount': showViewCount,
      'showReactions': showReactions,
      'allowReplies': allowReplies,
      'searchHistory': getSearchHistory(),
      'recentSearches': getRecentSearches(),
      'hiddenUsers': getHiddenUsers(),
    };
  }

  // استعادة الإعدادات من نسخ احتياطي
  Future<void> importSettings(Map<String, dynamic> settings) async {
    await init();
    
    if (settings.containsKey('isDarkMode')) {
      await setDarkMode(settings['isDarkMode'] ?? false);
    }
    
    if (settings.containsKey('language')) {
      await setLanguage(settings['language'] ?? 'ar');
    }
    
    if (settings.containsKey('hasSeenOnboarding')) {
      await setHasSeenOnboarding(settings['hasSeenOnboarding'] ?? false);
    }
    
    if (settings.containsKey('notificationsEnabled')) {
      await setNotificationsEnabled(settings['notificationsEnabled'] ?? true);
    }
    
    if (settings.containsKey('autoSaveToGallery')) {
      await setAutoSaveToGallery(settings['autoSaveToGallery'] ?? false);
    }
    
    if (settings.containsKey('allowSharing')) {
      await setAllowSharing(settings['allowSharing'] ?? true);
    }
    
    if (settings.containsKey('showViewCount')) {
      await setShowViewCount(settings['showViewCount'] ?? true);
    }
    
    if (settings.containsKey('showReactions')) {
      await setShowReactions(settings['showReactions'] ?? true);
    }
    
    if (settings.containsKey('allowReplies')) {
      await setAllowReplies(settings['allowReplies'] ?? true);
    }
    
    if (settings.containsKey('searchHistory')) {
      final history = List<String>.from(settings['searchHistory'] ?? []);
      await _prefs!.setStringList(_searchHistoryKey, history);
    }
    
    if (settings.containsKey('recentSearches')) {
      final recent = List<String>.from(settings['recentSearches'] ?? []);
      await _prefs!.setStringList(_recentSearchesKey, recent);
    }
    
    if (settings.containsKey('hiddenUsers')) {
      final hidden = List<String>.from(settings['hiddenUsers'] ?? []);
      await _prefs!.setStringList(_hiddenUsersKey, hidden);
    }
  }
}
