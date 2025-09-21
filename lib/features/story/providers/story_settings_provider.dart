import 'package:flutter/material.dart';
import 'package:sumi/features/story/services/story_service.dart';

class StorySettingsProvider extends ChangeNotifier {
  final StoryService _storyService = StoryService();

  // إعدادات الخصوصية
  bool _allowSharing = true;
  bool _showViewCount = true;
  bool _showReactions = true;
  bool _allowReplies = true;
  bool _autoSaveToGallery = false;

  // إعدادات الإشعارات
  bool _enableNotifications = true;
  bool _replyNotifications = true;
  bool _reactionNotifications = true;
  bool _mentionNotifications = true;

  // حالة التحميل
  bool _isLoading = false;

  // Getters
  bool get allowSharing => _allowSharing;
  bool get showViewCount => _showViewCount;
  bool get showReactions => _showReactions;
  bool get allowReplies => _allowReplies;
  bool get autoSaveToGallery => _autoSaveToGallery;
  bool get enableNotifications => _enableNotifications;
  bool get replyNotifications => _replyNotifications;
  bool get reactionNotifications => _reactionNotifications;
  bool get mentionNotifications => _mentionNotifications;
  bool get isLoading => _isLoading;

  // تحميل الإعدادات
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final settings = await _storyService.loadStorySettings();

      final privacySettings = settings['privacy'] as Map<String, dynamic>;
      final notificationSettings = settings['notifications'] as Map<String, dynamic>;

      _allowSharing = privacySettings['allowSharing'] ?? true;
      _showViewCount = privacySettings['showViewCount'] ?? true;
      _showReactions = privacySettings['showReactions'] ?? true;
      _allowReplies = privacySettings['allowReplies'] ?? true;
      _autoSaveToGallery = privacySettings['autoSaveToGallery'] ?? false;

      _enableNotifications = notificationSettings['storyNotifications'] ?? true;
      _replyNotifications = notificationSettings['replyNotifications'] ?? true;
      _reactionNotifications = notificationSettings['reactionNotifications'] ?? true;
      _mentionNotifications = notificationSettings['mentionNotifications'] ?? true;

    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حفظ الإعدادات
  Future<bool> saveSettings() async {
    try {
      final settings = {
        'privacy': {
          'allowSharing': _allowSharing,
          'showViewCount': _showViewCount,
          'showReactions': _showReactions,
          'allowReplies': _allowReplies,
          'autoSaveToGallery': _autoSaveToGallery,
        },
        'notifications': {
          'storyNotifications': _enableNotifications,
          'replyNotifications': _replyNotifications,
          'reactionNotifications': _reactionNotifications,
          'mentionNotifications': _mentionNotifications,
        },
        'account': {
          'autoDeleteOldStories': false,
          'deleteAfterDays': 7,
          'downloadQuality': 'high',
        },
      };

      final success = await _storyService.saveStorySettings(settings);
      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }

  // تحديث إعدادات الخصوصية
  void updatePrivacySettings({
    bool? allowSharing,
    bool? showViewCount,
    bool? showReactions,
    bool? allowReplies,
    bool? autoSaveToGallery,
  }) {
    if (allowSharing != null) _allowSharing = allowSharing;
    if (showViewCount != null) _showViewCount = showViewCount;
    if (showReactions != null) _showReactions = showReactions;
    if (allowReplies != null) _allowReplies = allowReplies;
    if (autoSaveToGallery != null) _autoSaveToGallery = autoSaveToGallery;

    notifyListeners();
  }

  // تحديث إعدادات الإشعارات
  void updateNotificationSettings({
    bool? enableNotifications,
    bool? replyNotifications,
    bool? reactionNotifications,
    bool? mentionNotifications,
  }) {
    if (enableNotifications != null) _enableNotifications = enableNotifications;
    if (replyNotifications != null) _replyNotifications = replyNotifications;
    if (reactionNotifications != null) _reactionNotifications = reactionNotifications;
    if (mentionNotifications != null) _mentionNotifications = mentionNotifications;

    notifyListeners();
  }

  // إعادة تعيين الإعدادات للوضع الافتراضي
  void resetToDefaults() {
    _allowSharing = true;
    _showViewCount = true;
    _showReactions = true;
    _allowReplies = true;
    _autoSaveToGallery = false;
    _enableNotifications = true;
    _replyNotifications = true;
    _reactionNotifications = true;
    _mentionNotifications = true;

    notifyListeners();
  }
}
