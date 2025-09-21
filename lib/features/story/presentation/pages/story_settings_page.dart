import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:sumi/features/story/providers/story_settings_provider.dart';
import 'package:sumi/features/auth/services/user_service.dart';
import 'package:sumi/core/theme/app_theme.dart';

class StorySettingsPage extends StatefulWidget {
  const StorySettingsPage({super.key});

  @override
  State<StorySettingsPage> createState() => _StorySettingsPageState();
}

class _StorySettingsPageState extends State<StorySettingsPage>
    with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final UserService _userService = UserService();

  late AnimationController _fabController;
  List<String> _hiddenUsers = [];
  bool _isLoadingHidden = true;

  // إعدادات الخصوصية المحلية
  bool _allowSharing = true;
  bool _showViewCount = true;
  bool _showReactions = true;
  bool _allowReplies = true;
  bool _autoSaveToGallery = false;
  bool _enableNotifications = true;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabController.forward();
    _loadHiddenUsers();
    _loadPrivacySettings();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadHiddenUsers() async {
    final hiddenUsers = await _storyService.getHiddenUsersList();
    if (mounted) {
      setState(() {
        _hiddenUsers = hiddenUsers;
        _isLoadingHidden = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إعدادات القصص',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.bold,
            color: Color(0xFF9A46D7),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF9A46D7)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Settings Section
            _buildSectionHeader('الخصوصية'),
            _buildPrivacySettings(),

            const SizedBox(height: 24),

            // Theme Settings Section
            _buildSectionHeader('إعدادات الشكل'),
            _buildThemeSettings(),

            const SizedBox(height: 24),

            // Hidden Users Section
            _buildSectionHeader('المستخدمون المخفيون'),
            _buildHiddenUsersSection(),

            const SizedBox(height: 24),

            // Account Management Section
            _buildSectionHeader('إدارة الحساب'),
            _buildAccountManagement(),

            const SizedBox(height: 24),

            // Help & Support Section
            _buildSectionHeader('المساعدة والدعم'),
            _buildHelpSection(),

            const SizedBox(height: 24),

            // Save Settings Button
            _buildSaveButton(),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).pop(),
          backgroundColor: const Color(0xFF9A46D7),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Ping AR + LT',
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        children: [
          _buildPrivacySetting(
            'السماح بالمشاركة',
            'السماح للآخرين بمشاركة قصصك',
            Icons.share,
            _allowSharing,
            (value) => _updateSetting('allowSharing', value),
          ),
          const Divider(height: 1),
          _buildPrivacySetting(
            'إظهار عدد المشاهدات',
            'إظهار عدد المشاهدات للآخرين',
            Icons.visibility,
            _showViewCount,
            (value) => _updateSetting('showViewCount', value),
          ),
          const Divider(height: 1),
          _buildPrivacySetting(
            'إظهار التفاعلات',
            'إظهار التفاعلات على قصصك',
            Icons.favorite,
            _showReactions,
            (value) => _updateSetting('showReactions', value),
          ),
          const Divider(height: 1),
          _buildPrivacySetting(
            'السماح بالردود',
            'السماح للآخرين بالرد على قصصك',
            Icons.comment,
            _allowReplies,
            (value) => _updateSetting('allowReplies', value),
          ),
          const Divider(height: 1),
          _buildPrivacySetting(
            'إشعارات القصص',
            'تلقي إشعارات عند تفاعل الآخرين',
            Icons.notifications,
            _enableNotifications,
            (value) => _updateSetting('enableNotifications', value),
          ),
          const Divider(height: 1),
          _buildPrivacySetting(
            'الحفظ التلقائي',
            'حفظ القصص تلقائياً في المعرض',
            Icons.save,
            _autoSaveToGallery,
            (value) => _updateSetting('autoSaveToGallery', value),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettings() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF9A46D7),
                ),
                title: const Text(
                  'الوضع المظلم',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode 
                    ? 'استخدام الوضع المظلم لراحة العينين'
                    : 'استخدام الوضع الفاتح الافتراضي',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                    
                    // إظهار رسالة تأكيد
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'تم تفعيل الوضع المظلم' : 'تم تفعيل الوضع الفاتح',
                          style: const TextStyle(fontFamily: 'Ping AR + LT'),
                        ),
                        backgroundColor: const Color(0xFF9A46D7),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  activeColor: const Color(0xFF9A46D7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivacySetting(String title, String subtitle, IconData icon, bool initialValue, Function(bool) onChanged) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF9A46D7),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: 'Ping AR + LT',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontFamily: 'Ping AR + LT',
        ),
      ),
      trailing: Switch(
        value: initialValue,
                  onChanged: (value) {
          onChanged(value);
        },
        activeColor: const Color(0xFF9A46D7),
      ),
    );
  }

  Widget _buildHiddenUsersSection() {
    if (_isLoadingHidden) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hiddenUsers.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.visibility_off,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'لا يوجد مستخدمون مخفيون',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Ping AR + LT',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك إخفاء قصص أي مستخدم من هنا',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'Ping AR + LT',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: AnimationLimiter(
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _hiddenUsers.length,
          itemBuilder: (context, index) {
            final userId = _hiddenUsers[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildHiddenUserTile(userId),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHiddenUserTile(String userId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text('جاري التحميل...'),
          );
        }

        final userData = snapshot.data!;
        final displayName = userData['displayName'] ?? 'مستخدم';
        final photoURL = userData['photoURL'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photoURL.isNotEmpty
                ? CachedNetworkImageProvider(photoURL)
                : null,
            child: photoURL.isEmpty
                ? Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          title: Text(
            displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Ping AR + LT',
            ),
          ),
          subtitle: Text(
            'مخفي',
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'Ping AR + LT',
            ),
          ),
          trailing: TextButton(
            onPressed: () => _unhideUser(userId, displayName),
            child: const Text(
              'إظهار',
              style: TextStyle(
                color: Color(0xFF9A46D7),
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountManagement() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        children: [
          _buildAccountItem(
            'تصدير البيانات',
            'تصدير جميع قصصك وبياناتك',
            Icons.download,
            () => _exportData(),
          ),
          const Divider(height: 1),
          _buildAccountItem(
            'مسح البيانات',
            'مسح جميع القصص والإعدادات',
            Icons.delete_forever,
            () => _clearAllData(),
            isDestructive: true,
          ),
          const Divider(height: 1),
          _buildAccountItem(
            'إعادة تعيين الإعدادات',
            'إعادة جميع الإعدادات للوضع الافتراضي',
            Icons.restore,
            () => _resetSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        children: [
          _buildHelpItem(
            'كيفية إنشاء قصة',
            'تعلم كيفية إنشاء ومشاركة القصص',
            Icons.help_outline,
          ),
          const Divider(height: 1),
          _buildHelpItem(
            'إدارة الخصوصية',
            'كيفية التحكم في خصوصية قصصك',
            Icons.privacy_tip,
          ),
          const Divider(height: 1),
          _buildHelpItem(
            'الإبلاغ عن مشكلة',
            'إبلاغ عن مشاكل في التطبيق',
            Icons.report_problem,
          ),
          const Divider(height: 1),
          _buildHelpItem(
            'الأسئلة الشائعة',
            'أجب على الأسئلة الأكثر شيوعاً',
            Icons.question_answer,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _saveAllSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9A46D7),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'حفظ جميع الإعدادات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Ping AR + LT',
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF9A46D7),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black,
          fontFamily: 'Ping AR + LT',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontFamily: 'Ping AR + LT',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDestructive ? Colors.red : Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildHelpItem(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF9A46D7),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontFamily: 'Ping AR + LT',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontFamily: 'Ping AR + LT',
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: () {
        // TODO: Navigate to help page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'سيتم توفير هذه المساعدة قريباً',
              style: const TextStyle(fontFamily: 'Ping AR + LT'),
            ),
            backgroundColor: const Color(0xFF9A46D7),
          ),
        );
      },
    );
  }

  void _exportData() {
    // TODO: Implement data export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'سيتم تصدير البيانات قريباً',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        backgroundColor: Color(0xFF9A46D7),
      ),
    );
  }

  void _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تأكيد المسح',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        content: const Text(
          'هل أنت متأكد من مسح جميع البيانات؟ هذا الإجراء لا يمكن التراجع عنه.',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'مسح',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement data clearing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم مسح جميع البيانات',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إعادة تعيين الإعدادات',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        content: const Text(
          'هل تريد إعادة جميع الإعدادات للوضع الافتراضي؟',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'إعادة تعيين',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _allowSharing = true;
        _showViewCount = true;
        _showReactions = true;
        _allowReplies = true;
        _autoSaveToGallery = false;
        _enableNotifications = true;
      });

      // حفظ الإعدادات الافتراضية
      _saveAllSettings();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إعادة تعيين الإعدادات',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Color(0xFF9A46D7),
        ),
      );
    }
  }

  void _saveAllSettings() async {
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
        'replyNotifications': _enableNotifications,
        'reactionNotifications': _enableNotifications,
        'mentionNotifications': _enableNotifications,
      },
      'account': {
        'autoDeleteOldStories': false,
        'deleteAfterDays': 7,
        'downloadQuality': 'high',
      },
    };

    final success = await _storyService.saveStorySettings(settings);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ جميع الإعدادات بنجاح',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Color(0xFF9A46D7),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فشل في حفظ الإعدادات',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      // استخدام Firebase Auth للحصول على بيانات المستخدم
      // أو يمكن إنشاء method في StoryService للحصول على بيانات المستخدم
      return {
        'displayName': 'مستخدم',
        'photoURL': '',
      };
    } catch (e) {
      return null;
    }
  }

  void _unhideUser(String userId, String displayName) async {
    final success = await _storyService.removeHiddenUser(userId);

    if (success && mounted) {
      setState(() {
        _hiddenUsers.remove(userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إظهار قصص $displayName',
            style: const TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'فشل في إظهار المستخدم',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateSetting(String key, bool value) async {
    // تحديث الحالة المحلية أولاً
    setState(() {
      switch (key) {
        case 'allowSharing':
          _allowSharing = value;
          break;
        case 'showViewCount':
          _showViewCount = value;
          break;
        case 'showReactions':
          _showReactions = value;
          break;
        case 'allowReplies':
          _allowReplies = value;
          break;
        case 'autoSaveToGallery':
          _autoSaveToGallery = value;
          break;
        case 'enableNotifications':
          _enableNotifications = value;
          break;
      }
    });

    // حفظ الإعدادات في Firebase
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
        'replyNotifications': _enableNotifications,
        'reactionNotifications': _enableNotifications,
        'mentionNotifications': _enableNotifications,
      },
      'account': {
        'autoDeleteOldStories': false,
        'deleteAfterDays': 7,
        'downloadQuality': 'high',
      },
    };

    final success = await _storyService.saveStorySettings(settings);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ الإعدادات',
            style: TextStyle(fontFamily: 'Ping AR + LT'),
          ),
          backgroundColor: Color(0xFF9A46D7),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final settings = await _storyService.loadStorySettings();

      final privacySettings = settings['privacy'] as Map<String, dynamic>;
      final notificationSettings = settings['notifications'] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _allowSharing = privacySettings['allowSharing'] ?? true;
          _showViewCount = privacySettings['showViewCount'] ?? true;
          _showReactions = privacySettings['showReactions'] ?? true;
          _allowReplies = privacySettings['allowReplies'] ?? true;
          _autoSaveToGallery = privacySettings['autoSaveToGallery'] ?? false;
          _enableNotifications = notificationSettings['storyNotifications'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    }
  }
}
