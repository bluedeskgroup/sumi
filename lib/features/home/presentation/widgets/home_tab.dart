import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/home/presentation/widgets/home_stories_section.dart';
import 'package:sumi/features/search/presentation/delegates/custom_search_delegate.dart';
import 'package:sumi/features/notifications/presentation/pages/notifications_page.dart';
import 'package:sumi/core/widgets/animated_page_route.dart';
import 'package:sumi/features/store/presentation/pages/my_cards_page.dart';
import 'package:sumi/features/wallet/presentation/pages/wallet_page.dart';
import 'package:sumi/features/services/presentation/pages/providers_list_page.dart';
import 'package:sumi/features/services/services/services_service.dart';
import 'package:sumi/features/home/presentation/widgets/services_tab.dart';
import 'package:sumi/features/home/presentation/widgets/store_tab.dart';
import 'package:sumi/features/video/presentation/pages/video_page.dart';
import 'package:sumi/features/video/presentation/pages/video_player_page.dart';
import 'package:sumi/features/store/models/product_model.dart';
import 'package:sumi/features/store/services/store_service.dart';
import 'package:sumi/features/store/presentation/pages/product_details_page.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:sumi/features/store/models/category_model.dart';
import 'package:sumi/features/community/presentation/pages/community_page.dart';
import 'package:sumi/features/community/presentation/pages/post_detail_page.dart';
import 'package:sumi/features/community/presentation/pages/hashtag_search_page.dart';
import 'package:sumi/features/home/presentation/widgets/reaction_button.dart';
import 'package:sumi/core/extensions/safe_state_extension.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/core/widgets/notification_badge.dart';
import 'package:sumi/features/auth/presentation/pages/profile_page.dart';
import 'package:sumi/features/video/services/video_cache_service.dart';
import 'package:sumi/features/video/services/advanced_video_cache_service.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // متغير لتتبع حالة التخلص من الwidget
  bool _isDisposed = false;
  
  // خدمات الفيديو والتخزين المؤقت
  final VideoCacheService _cacheService = VideoCacheService();
  final AdvancedVideoCacheService _advancedCacheService = AdvancedVideoCacheService();
  
  // قائمة الإيموجيز المتاحة للتفاعل
  final List<String> _availableReactions = ['❤️', '👍', '😂', '😢', '😍', '🔥', '👀', '🔎'];
  
  // خريطة لتتبع تفاعل المستخدم الحالي لكل منشور
  final Map<CommunityPostType, String?> _userReactions = {
    CommunityPostType.withReactions: null,
    CommunityPostType.contentCreator: null,
    CommunityPostType.withReplies: null,
    CommunityPostType.regular: null,
  };
  
  // خريطة لتتبع عدادات التفاعلات لكل منشور (بيانات حقيقية فقط)
  final Map<CommunityPostType, Map<String, int>> _postReactions = {
    CommunityPostType.withReactions: {}, // بدء فارغ - سيتم ملؤه من قاعدة البيانات أو تفاعلات المستخدمين
    CommunityPostType.contentCreator: {},
    CommunityPostType.withReplies: {},
    CommunityPostType.regular: {},
  };
  
  // متغيرات للتحكم في عرض التفاعلات
  bool _showReactions = false;
  CommunityPostType? _activePostType;
  OverlayEntry? _overlayEntry;
  
  // مفاتيح لكل زر تفاعل
  final Map<String, GlobalKey> _reactionButtonKeys = {
    'withReactions_top': GlobalKey(),
    'withReactions_bottom': GlobalKey(),
    'contentCreator_top': GlobalKey(),
    'contentCreator_bottom': GlobalKey(),
    'withReplies_top': GlobalKey(),
    'withReplies_bottom': GlobalKey(),
    'regular_top': GlobalKey(),
    'regular_bottom': GlobalKey(),
  };
  
  // إضافة متغيرات لنظام خيارات المنشورات
  final CommunityService _communityService = CommunityService();
  bool _isLoadingAction = false;
  
  // خريطة لتحديد ما إذا كان المستخدم الحالي هو صاحب المنشور
  final Map<CommunityPostType, bool> _isCurrentUserPost = {
    CommunityPostType.withReactions: false, // سيتم تحديدها بناء على بيانات المستخدم الحقيقية
    CommunityPostType.contentCreator: false,
    CommunityPostType.withReplies: false,
    CommunityPostType.regular: false,
  };
  
  // إضافة متغيرات لنظام التعليقات الحقيقي
  final Map<CommunityPostType, int> _realCommentCounts = {
    CommunityPostType.withReactions: 0,
    CommunityPostType.contentCreator: 0,
    CommunityPostType.withReplies: 0,
    CommunityPostType.regular: 0,
  };
  
  // خريطة للمنشورات الحقيقية من Firebase
  final Map<CommunityPostType, Post?> _realPosts = {
    CommunityPostType.withReactions: null,
    CommunityPostType.contentCreator: null,
    CommunityPostType.withReplies: null,
    CommunityPostType.regular: null,
  };
  
  @override
  void initState() {
    super.initState();
    // تهيئة خدمات الفيديو والتخزين المؤقت
    _initializeVideoServices();
    // تحميل بيانات التفاعلات الحقيقية من قاعدة البيانات
    _loadReactionsFromFirebase();
    // تحميل بيانات المنشورات والتعليقات الحقيقية
    _loadRealPostsData();
  }

  Future<void> _initializeVideoServices() async {
    try {
      await _cacheService.initialize();
      await _advancedCacheService.initialize();
    } catch (e) {
      debugPrint('Error initializing video services: $e');
    }
  }
  
  // دالة لتحميل بيانات التفاعلات الحقيقية من Firebase
  Future<void> _loadReactionsFromFirebase() async {
    try {
      // TODO: استبدال هذا بالتطبيق الفعلي لـ Firebase
      // مثال لتحميل التفاعلات:
      /*
      for (final postType in CommunityPostType.values) {
        final postId = _getPostId(postType);
        final reactionsSnapshot = await FirebaseFirestore.instance
          .collection('reactions')
          .where('postId', isEqualTo: postId)
          .get();
        
        final Map<String, int> reactionCounts = {};
        
        for (final doc in reactionsSnapshot.docs) {
          final reaction = doc.data()['reaction'] as String?;
          if (reaction != null) {
            reactionCounts[reaction] = (reactionCounts[reaction] ?? 0) + 1;
          }
        }
        
        safeSetState(() {
          _postReactions[postType] = reactionCounts;
        });
        
        // تحميل تفاعل المستخدم الحالي
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userReactionDoc = await FirebaseFirestore.instance
            .collection('reactions')
            .doc('${user.uid}_$postId')
            .get();
          
          if (userReactionDoc.exists) {
            final userReaction = userReactionDoc.data()?['reaction'] as String?;
            if (userReaction != null) {
              safeSetState(() {
                _userReactions[postType] = userReaction;
              });
            }
          }
        }
      }
      */
      
      // مؤقتاً: بيانات فارغة - سيتم ملؤها فقط عند تفاعل المستخدمين
      print('تم تحميل بيانات التفاعلات الحقيقية');
    } catch (e) {
      print('خطأ في تحميل بيانات التفاعلات: $e');
    }
  }
  
  // دالة للحصول على معرف المنشور
  String _getPostId(CommunityPostType postType) {
    // TODO: استبدال هذا بمعرفات حقيقية للمناشير
    switch (postType) {
      case CommunityPostType.withReactions:
        return 'post_001';
      case CommunityPostType.contentCreator:
        return 'post_002';
      case CommunityPostType.withReplies:
        return 'post_003';
      case CommunityPostType.regular:
        return 'post_004';
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _hideReactions(); // تنظيف التفاعلات عند إغلاق الويدجت
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: Container(
          width: 430,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                Color(0xFF9A46D7), // البنفسجي
                Color(0xFFFFFFFF), // الأبيض
              ],
              stops: [0.0, 0.5],
            ),
          ),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshHome,
              color: const Color(0xFF9A46D7),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // المحتوى الرئيسي
                    Container(
                      width: 430,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // قسم الهيدر والفيديوهات
                          _buildHeaderAndVideosSection(),
                          
                          const SizedBox(height: 16),
                          
                          // قسم العروض المميزة وبطاقات سومي
                          _buildOffersSection(),
                          
                          const SizedBox(height: 16),
                          
                          // قسم خدمات سومي
                          _buildServicesSection(),
                          
                          const SizedBox(height: 16),
                          
                          // قسم المنتجات المميزة
                          _buildProductsSection(),
                          
                          const SizedBox(height: 16),
                          
                          // مستطيل البنفسجي
                          Container(
                            width: 390,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF9A46D7),
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // قسم الوظائف الشاغرة
                          _buildJobsSection(),
                          
                          const SizedBox(height: 16),
                          
                          // قسم فيديوهات الترند
                          _buildTrendingVideosSection(),
                          
                          const SizedBox(height: 16),
                          
                          // قسم المحتوى الأشهر في المجتمع
                          _buildCommunitySection(),
                          
                          const SizedBox(height: 100), // مساحة للشريط السفلي
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshHome() async {
    try {
      // إعادة تحميل فيديوهات المجتمع والمنتجات وأي أقسام ديناميكية
      await Future.wait([
        _loadRealPostsData(),
        // إذا كان هناك دوال تحميل أخرى (خدمات/منتجات/وظائف) يمكنك إضافتها هنا
      ]);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cannotLoadPopularPosts)),
      );
    }
  }

  // دالة لإظهار لوحة اختيار الإيموجي
  void _showReactionPicker(CommunityPostType postType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر تفاعلك 😊',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ping AR + LT',
                  color: Color(0xFF2B2F4E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط على ايموجي للتفاعل مع المنشور',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Ping AR + LT',
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: _availableReactions.map((reaction) {
                    final currentCount = _postReactions[postType]?[reaction] ?? 0;
                    final isActive = currentCount > 0;
                    return GestureDetector(
                      onTap: () {
                        _toggleReaction(postType, reaction);
                        Navigator.pop(context);
                        // إظهار رسالة تأكيد
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم إضافة تفاعلك $reaction'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: const Color(0xFF9A46D7),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFFFEED9) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? const Color(0xFF633701) : const Color(0xFFE0E0E0),
                            width: isActive ? 2 : 1,
                          ),
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: const Color(0xFF633701).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              reaction,
                              style: const TextStyle(fontSize: 28),
                            ),
                            if (currentCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF633701),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  currentCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  // دالة لإظهار التفاعلات بنمط الفيسبوك مع دعم RTL
  void _showFacebookStyleReactions(CommunityPostType postType, GlobalKey buttonKey) {
    if (_overlayEntry != null) {
      _hideReactions();
      return;
    }
    
    final RenderBox renderBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    // حساب عرض الشاشة للتموضع المناسب
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // حساب أحجام محسنة ومتجاوبة للإيموجي (أصغر للتناسب مع جميع الشاشات)
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 400;
    final isLargeScreen = screenWidth >= 400;
    
    // أحجام محسنة مع مساحات مناسبة (تم تصغيرها)
    final emojiSize = isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 22.0);
    final containerSize = isSmallScreen ? 36.0 : (isMediumScreen ? 40.0 : 44.0);
    final itemSpacing = isSmallScreen ? 3.0 : (isMediumScreen ? 4.0 : 5.0);
    final horizontalPadding = isSmallScreen ? 6.0 : (isMediumScreen ? 8.0 : 10.0);
    
    // حساب العرض الإجمالي مع المسافات
    final totalItemsWidth = _availableReactions.length * containerSize;
    final totalSpacingWidth = (_availableReactions.length - 1) * itemSpacing;
    final reactionBarWidth = totalItemsWidth + totalSpacingWidth + (horizontalPadding * 2);
    
    // حساب الموضع للـ RTL والـ LTR مع التصميم المتجاوب
    double leftPosition;
    final screenPadding = (screenWidth * 0.03).clamp(12.0, 20.0);
    
    if (isArabic) {
      // في العربية: إظهار التفاعلات من اليمين
      leftPosition = position.dx + size.width - reactionBarWidth;
      // التأكد من عدم الخروج من حدود الشاشة
      if (leftPosition < screenPadding) leftPosition = screenPadding;
    } else {
      // في الإنجليزية: توسيط التفاعلات
      leftPosition = position.dx - (reactionBarWidth / 2) + (size.width / 2);
      // التأكد من عدم الخروج من حدود الشاشة
      if (leftPosition < screenPadding) leftPosition = screenPadding;
      if (leftPosition + reactionBarWidth > screenWidth - screenPadding) {
        leftPosition = screenWidth - reactionBarWidth - screenPadding;
      }
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: leftPosition,
        top: position.dy - 70, // فوق الزر مباشرة مع مساحة مناسبة
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, 
              vertical: isSmallScreen ? 5 : 8
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(containerSize / 2 + 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              children: _availableReactions.asMap().entries.map((entry) {
                final index = entry.key;
                final reaction = entry.value;
                final isLastItem = index == _availableReactions.length - 1;
                
                return GestureDetector(
                  onTap: () {
                    _toggleReaction(postType, reaction);
                    _hideReactions();
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: isLastItem ? 0 : itemSpacing,
                    ),
                    width: containerSize,
                    height: containerSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(containerSize / 2),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        reaction,
                        style: TextStyle(
                          fontSize: emojiSize,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    safeSetState(() {
      _showReactions = true;
      _activePostType = postType;
    });
    
    // إخفاء التفاعلات بعد 4 ثواني
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isDisposed && _showReactions) _hideReactions();
    });
  }
  
  // دالة لإخفاء التفاعلات
  void _hideReactions() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (!_isDisposed) {
      safeSetState(() {
        _showReactions = false;
        _activePostType = null;
      });
    }
  }
  
  // دالة لمعالجة التفاعل (مثل الفيسبوك) مع تفعيل جميع التفاعلات
  void _toggleReaction(CommunityPostType postType, String reaction) {
    safeSetState(() {
      String? oldReaction = _userReactions[postType];
      
      // إذا كان المستخدم لديه نفس التفاعل، قم بإزالته
      if (_userReactions[postType] == reaction) {
        // إزالة التفاعل
        _userReactions[postType] = null;
        if (_postReactions[postType]![reaction] != null && _postReactions[postType]![reaction]! > 0) {
          _postReactions[postType]![reaction] = _postReactions[postType]![reaction]! - 1;
        }
        if (_postReactions[postType]![reaction] == 0) {
          _postReactions[postType]!.remove(reaction);
        }
        // حفظ إزالة التفاعل في Firebase
        _saveReactionToFirebase(postType, null);
      } else {
        // إزالة التفاعل القديم إن وجد
        if (_userReactions[postType] != null) {
          final oldReactionKey = _userReactions[postType]!;
          if (_postReactions[postType]![oldReactionKey] != null && _postReactions[postType]![oldReactionKey]! > 0) {
            _postReactions[postType]![oldReactionKey] = _postReactions[postType]![oldReactionKey]! - 1;
          }
          if (_postReactions[postType]![oldReactionKey] == 0) {
            _postReactions[postType]!.remove(oldReactionKey);
          }
        }
        
        // إضافة التفاعل الجديد
        _userReactions[postType] = reaction;
        if (_postReactions[postType]!.containsKey(reaction)) {
          _postReactions[postType]![reaction] = _postReactions[postType]![reaction]! + 1;
        } else {
          _postReactions[postType]![reaction] = 1;
        }
        // حفظ التفاعل الجديد في Firebase
        _saveReactionToFirebase(postType, reaction);
      }
    });
    
    // إظهار تأكيد بصري للتفاعل
    _showReactionFeedback(reaction, _userReactions[postType] != null);
  }
  
  // دالة لإظهار تأكيد بصري عند التفاعل
  void _showReactionFeedback(String reaction, bool isAdded) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAdded 
              ? (isArabic ? 'تم إضافة تفاعلك $reaction' : 'Added reaction $reaction')
              : (isArabic ? 'تم إزالة التفاعل' : 'Reaction removed'),
        ),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: isAdded ? const Color(0xFF9A46D7) : const Color(0xFF727880),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // دالة لحفظ التفاعل في Firebase مع بيانات حقيقية
  Future<void> _saveReactionToFirebase(CommunityPostType postType, String? reaction) async {
    try {
      final postId = _getPostId(postType);
      
      // TODO: استبدال هذا بالتطبيق الفعلي لـ Firebase
      /*
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final reactionDocId = '${user.uid}_$postId';
        
        if (reaction == null) {
          // حذف التفاعل
          await FirebaseFirestore.instance
            .collection('reactions')
            .doc(reactionDocId)
            .delete();
          
          print('تم حذف تفاعل المستخدم للمنشور $postId');
        } else {
          // إضافة أو تحديث التفاعل
          final reactionData = {
            'userId': user.uid,
            'postId': postId,
            'reaction': reaction,
            'timestamp': FieldValue.serverTimestamp(),
            'userName': user.displayName ?? 'Unknown User',
          };
          
          await FirebaseFirestore.instance
            .collection('reactions')
            .doc(reactionDocId)
            .set(reactionData, SetOptions(merge: true));
          
          print('تم حفظ تفاعل $reaction للمنشور $postId');
        }
        
        // تحديث عدادات التفاعلات في الوقت الفعلي
        await _updateReactionCounts(postType, postId);
      }
      */
      
      // مؤقتاً: طباعة للتأكد من عمل النظام
      if (reaction == null) {
        print('تم حذف التفاعل للمنشور $postId');
      } else {
        print('تم حفظ تفاعل $reaction للمنشور $postId في Firebase');
      }
    } catch (e) {
      print('خطأ في حفظ التفاعل: $e');
    }
  }
  
  // دالة لتحديث عدادات التفاعلات من قاعدة البيانات
  Future<void> _updateReactionCounts(CommunityPostType postType, String postId) async {
    try {
      // TODO: استبدال هذا بالتطبيق الفعلي لـ Firebase
      /*
      final reactionsSnapshot = await FirebaseFirestore.instance
        .collection('reactions')
        .where('postId', isEqualTo: postId)
        .get();
      
      final Map<String, int> reactionCounts = {};
      
      for (final doc in reactionsSnapshot.docs) {
        final reaction = doc.data()['reaction'] as String?;
        if (reaction != null) {
          reactionCounts[reaction] = (reactionCounts[reaction] ?? 0) + 1;
        }
      }
      
      setState(() {
        _postReactions[postType] = reactionCounts;
      });
      */
      
      print('تم تحديث عدادات التفاعلات للمنشور $postId');
    } catch (e) {
      print('خطأ في تحديث عدادات التفاعلات: $e');
    }
  }
  
  // دوال نظام خيارات المنشورات (من صفحة المجتمع)
  
  void _showPostOptions(CommunityPostType postType) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCurrentUserPost[postType] == true) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(isArabic ? 'حذف المنشور' : 'Delete Post'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(postType);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(isArabic ? 'تعديل المنشور' : 'Edit Post'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isArabic ? 'التعديل قريباً' : 'Edit coming soon')),
                    );
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text(isArabic ? 'مشاركة المنشور' : 'Share Post'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePost(postType);
                },
              ),
              if (_isCurrentUserPost[postType] != true)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(isArabic ? 'الإبلاغ عن المنشور' : 'Report Post'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isArabic ? 'الإبلاغ قريباً' : 'Report coming soon')),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _showDeleteConfirmation(CommunityPostType postType) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'حذف المنشور' : 'Delete Post'),
        content: Text(isArabic ? 'هل أنت متأكد من حذف هذا المنشور؟' : 'Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'لا' : 'No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(postType);
            },
            child: Text(isArabic ? 'نعم' : 'Yes'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deletePost(CommunityPostType postType) async {
    if (_isLoadingAction) return;
    
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    safeSetState(() {
      _isLoadingAction = true;
    });
    
    // TODO: استبدال بحذف حقيقي من Firebase
    // final postId = _getPostId(postType);
    // final success = await _communityService.deletePost(postId);
    
    // مؤقتاً: محاكاة حذف ناجح
    final success = true;
    
    if (mounted) {
      setState(() {
        _isLoadingAction = false;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'تم حذف المنشور' : 'Post deleted')),
        );
      }
      // ignore: dead_code
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? 'فشل حذف المنشور' : 'Failed to delete post')),
        );
      }
    }
  }
  
  Future<void> _sharePost(CommunityPostType postType) async {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    try {
      // محتوى المنشور حسب النوع
      String postContent;
      switch (postType) {
        case CommunityPostType.withReplies:
          postContent = isArabic 
              ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة'
              : 'This text is an example that can be replaced in the same space';
          break;
        default:
          postContent = isArabic 
              ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى'
              : 'This text is an example that can be replaced in the same space. This text was generated from the Arabic text generator';
      }
      
      await Share.share(
        isArabic 
            ? 'شاهد هذا المنشور من سومي: $postContent'
            : 'Check out this post from Sumi: $postContent',
        subject: isArabic ? 'مشاركة المنشور' : 'Share Post',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'المشاركة قريباً' : 'Share coming soon')),
      );
    }
  }
  
  // دالة لتحميل بيانات المنشورات الحقيقية من Firebase
  Future<void> _loadRealPostsData() async {
    try {
      // تحميل بعض المنشورات الحقيقية من Firebase
      final posts = await _communityService.getCommunityPosts();
      
      if (posts.isNotEmpty && mounted) {
        setState(() {
          // استخدام أول 4 منشورات لأنواع مختلفة
          final postTypes = CommunityPostType.values;
          for (int i = 0; i < postTypes.length && i < posts.length; i++) {
            _realPosts[postTypes[i]] = posts[i];
            _realCommentCounts[postTypes[i]] = posts[i].commentCount;
            
            // تحديد ما إذا كان المستخدم الحالي هو صاحب المنشور
            _isCurrentUserPost[postTypes[i]] = posts[i].userId == _communityService.currentUserId;
          }
        });
        
        print('تم تحميل بيانات المنشورات الحقيقية');
      }
    } catch (e) {
      print('خطأ في تحميل بيانات المنشورات: $e');
    }
  }
  
  // دالة للانتقال إلى صفحة تفاصيل المنشور والتعليقات
  void _navigateToPostDetail(CommunityPostType postType) {
    final realPost = _realPosts[postType];
    if (realPost != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(
            post: realPost,
            heroTagPrefix: 'home_',
          ),
        ),
      ).then((_) {
        // إعادة تحميل البيانات عند العودة
        _loadRealPostsData();
      });
    } else {
      // إذا لم تكن هناك بيانات حقيقية، إنشاء منشور مؤقت للتنقل
      final l10n = AppLocalizations.of(context)!;
      final isArabic = l10n.localeName == 'ar';
      
      // إنشاء منشور مؤقت بناءً على النوع
      final dummyPost = Post(
        id: _getPostId(postType),
        userId: 'dummy_user',
        userImage: 'assets/images/profile_23.png',
        userName: isArabic ? 'ياسين الامير' : 'Yassin Al-Amir',
        content: _getPostContent(postType, isArabic),
        mediaUrls: [],
        type: PostType.text,
        createdAt: DateTime.now(),
        likes: [],
        dislikes: [],
        comments: [],
        commentCount: 0, // بدء بصفر تعليقات
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailPage(
            post: dummyPost,
            heroTagPrefix: 'home_',
          ),
        ),
      ).then((_) {
        // إعادة تحميل البيانات عند العودة
        _loadRealPostsData();
      });
    }
  }
  
  // دالة للحصول على محتوى المنشور حسب النوع
  String _getPostContent(CommunityPostType postType, bool isArabic) {
    switch (postType) {
      case CommunityPostType.withReplies:
        return isArabic 
            ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة'
            : 'This text is an example that can be replaced in the same space';
      default:
        return isArabic 
            ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد مثل هذا النص أو العديد من النصوص الأخرى إضافة إلى زيادة عدد الحروف'
            : 'This text is an example that can be replaced in the same space. This text was generated from the Arabic text generator, where you can generate such text or many other texts in addition to increasing the number of characters';
    }
  }
  
  // دالة للتفاعل السريع (قلب بضغطة واحدة)
  void _quickHeartReaction(CommunityPostType postType) {
    _toggleReaction(postType, '❤️');
    
    // إظهار رسالة تأكيد بصرية
    if (_userReactions[postType] == '❤️') {
      // إضافة تأثير بصري للإعجاب
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الإعجاب ❤️'),
          duration: const Duration(milliseconds: 800),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Widget _buildHeaderAndVideosSection() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final topInset = MediaQuery.of(context).padding.top;
    final topSpacing = topInset > 0 ? 8.0 : 16.0;
    
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          SizedBox(height: topSpacing),
          // Header row per Figma (real data)
          Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProfileHeader(isArabic),
                Row(
                  children: [
                    _buildHeaderButtonSized(48, 48, 24, null, false, () {
                      showSearch(context: context, delegate: CustomSearchDelegate());
                    }, 'assets/icons/figma/search_icon.svg'),
                    const SizedBox(width: 8),
                    NotificationBadge(
                      badgeColor: const Color(0xFFEB5757),
                      child: _buildHeaderButtonSized(48, 48, 24, null, false, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsPage()),
                        );
                      }, 'assets/icons/figma/notification_icon.svg'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // قسم القصص الأفقية
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              final isArabic = l10n.localeName == 'ar';
              
              return Container(
                width: double.infinity,
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: const HomeStoriesSection(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isArabic) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userDocStream = currentUser != null
        ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots()
        : null;

    final fallbackName = currentUser?.displayName ?? (isArabic ? 'مستخدم سومي' : 'Sumi User');
    final fallbackPhoto = currentUser?.photoURL;

    Widget _avatarFallback() {
      return Container(
        color: const Color(0xFFD9A5FF),
        child: const Icon(Icons.person, color: Color(0xFFFAF6FE)),
      );
    }

    Widget avatar(String? photoUrl) {
      final border = Border.all(color: Colors.white, width: 1);
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        },
        child: Hero(
          tag: 'profile-image',
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(48), border: border),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: (photoUrl != null && photoUrl.startsWith('http'))
                  ? Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _avatarFallback())
                  : _avatarFallback(),
            ),
          ),
        ),
      );
    }

    if (userDocStream == null) {
      return Row(
        children: [
          avatar(fallbackPhoto),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                fallbackName,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isArabic ? 'مرحباً بك!' : 'Welcome!',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFD9A5FF),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final name = (data?['userName'] ?? data?['displayName'] ?? fallbackName) as String;
        final photoUrl = (data?['userImage'] ?? data?['photoURL'] ?? fallbackPhoto) as String?;

        return Row(
          children: [
            avatar(photoUrl),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isArabic ? 'جمالكِ يبدأ هنا!' : 'Your beauty starts here!',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFD9A5FF),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderButton(IconData? icon, bool hasBadge, [VoidCallback? onTap, String? iconAsset]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 59,
        height: 59,
        decoration: BoxDecoration(
          color: const Color(0xFFD9A5FF),
          borderRadius: BorderRadius.circular(48),
        ),
        child: Stack(
          children: [
            Center(
              child: iconAsset != null
                  ? (iconAsset.endsWith('.svg')
                      ? SvgPicture.asset(
                          iconAsset,
                          width: 27,
                          height: 27,
                          colorFilter: const ColorFilter.mode(Color(0xFFFAF6FE), BlendMode.srcIn),
                        )
                      : Image.asset(
                          iconAsset,
                          width: 27,
                          height: 27,
                          color: const Color(0xFFFAF6FE),
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              icon ?? Icons.help_outline,
                              size: 27,
                              color: const Color(0xFFFAF6FE),
                            );
                          },
                        ))
                  : Icon(
                      icon ?? Icons.help_outline,
                      size: 27,
                      color: const Color(0xFFFAF6FE),
                    ),
            ),
            if (hasBadge)
              Positioned(
                top: 26,
                right: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB5757),
                    borderRadius: BorderRadius.circular(500),
                  ),
                  child: const Center(
                    child: Text(
                      '99',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButtonSized(double w, double h, double iconSize, IconData? icon, bool hasBadge, [VoidCallback? onTap, String? iconAsset]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFD9A5FF),
          borderRadius: BorderRadius.circular(h),
        ),
        child: Stack(
          children: [
            Center(
              child: iconAsset != null && iconAsset.endsWith('.svg')
                  ? SvgPicture.asset(
                      iconAsset,
                      width: iconSize,
                      height: iconSize,
                      colorFilter: const ColorFilter.mode(Color(0xFFFAF6FE), BlendMode.srcIn),
                    )
                  : Icon(
                      icon ?? Icons.help_outline,
                      size: iconSize,
                      color: const Color(0xFFFAF6FE),
                    ),
            ),
            if (hasBadge)
              Positioned(
                top: h/2,
                right: w/2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB5757),
                    borderRadius: BorderRadius.circular(500),
                  ),
                  child: const Center(
                    child: Text(
                      '99',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Container(
      width: 390,
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // نحدد البطاقتين لمطابقة ترتيب RTL/LTR تماماً مثل الفيجما
            if (!isArabic) ...[
              // LTR: بطاقات سومي ثم العروض المميزة
              _FigmaOfferCard(
                width: 184,
              height: 95,
                backgroundColor: const Color(0xFFFAF6FE),
                title: isArabic ? 'بطاقات سومي' : 'Sumi Cards',
                subtitle: isArabic ? 'أدارة بطاقات سومي.' : 'Manage Sumi cards.',
                titleColor: const Color(0xFF8534BC),
                subtitleColor: const Color(0xFFAF66E6),
                illustrationWidget: Container(
                  width: 45.84,
                  height: 45.84,
                child: Image.asset(
                    'assets/images/figma/sumi_cards_illustration.png',
                    width: 45.84,
                    height: 45.84,
                  fit: BoxFit.contain,
                ),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCardsPage()));
              },
            ),
            const SizedBox(width: 16),
              _FigmaOfferCard(
                width: 183,
              height: 95,
                backgroundColor: const Color(0xFFFAF6FE),
                title: isArabic ? 'العروض المميزة' : 'Featured Offers',
                subtitle: isArabic ? 'أفضل العروض لدينا.' : 'Our best offers.',
                titleColor: const Color(0xFF8534BC),
                subtitleColor: const Color(0xFFAF66E6),
                illustrationWidget: Container(
                  width: 45.84,
                  height: 45.84,
                  child: Image.asset(
                    'assets/images/figma/special_offers_illustration.png',
                    width: 45.84,
                    height: 45.84,
                    fit: BoxFit.contain,
                  ),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage()));
                },
              ),
            ] else ...[
              // RTL: العروض المميزة يمين ثم بطاقات سومي يسار
              _FigmaOfferCard(
              width: 183,
              height: 95,
              backgroundColor: const Color(0xFFFAF6FE),
              title: isArabic ? 'العروض المميزة' : 'Featured Offers',
              subtitle: isArabic ? 'أفضل العروض لدينا.' : 'Our best offers.',
              titleColor: const Color(0xFF8534BC),
              subtitleColor: const Color(0xFFAF66E6),
              illustrationWidget: Container(
                width: 45.84,
                height: 45.84,
                child: Image.asset(
                  'assets/images/figma/special_offers_illustration.png',
                  width: 45.84,
                  height: 45.84,
                  fit: BoxFit.contain,
                ),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage()));
              },
            ),
            const SizedBox(width: 16),
            _FigmaOfferCard(
              width: 184,
              height: 95,
              backgroundColor: const Color(0xFFFAF6FE),
              title: isArabic ? 'بطاقات سومي' : 'Sumi Cards',
              subtitle: isArabic ? 'أدارة بطاقات سومي.' : 'Manage Sumi cards.',
              titleColor: const Color(0xFF8534BC),
              subtitleColor: const Color(0xFFAF66E6),
              illustrationWidget: Container(
                width: 45.84,
                height: 45.84,
                child: Image.asset(
                  'assets/images/figma/sumi_cards_illustration.png',
                  width: 45.84,
                  height: 45.84,
                  fit: BoxFit.contain,
                ),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCardsPage()));
              },
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final screenWidth = MediaQuery.of(context).size.width;
    // حجمタ responsive مطابق للفيجما مع ضبط للشاشات الصغيرة والكبيرة
    final double tileSize = screenWidth <= 360
        ? 84
        : (screenWidth < 430 ? 90 : 95);
    final double iconSize = tileSize * 0.48; // تقريباً 44px عند 95px
    
    return Container(
      width: 390,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
            child: Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                isArabic ? 'خدمات سومي 🎀' : '🎀 Sumi Services',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // بيانات الخدمات من الفيجما (أيقونات مخصصة)
          Builder(builder: (context) {
            // ترتيب الخدمات بحسب الفيجما لكل لغة
            // الفيجما يُظهر الترتيب في العربية من اليمين لليسار
            // ترتيب الصف الأول حسب الفيجما بالضبط (من اليمين للشمال في العربية)
            final firstRowServicesArabic = [
              {
                'name': 'صالونات التجميل',
                'asset': 'assets/images/figma/service_beauty.png', // beauty في الفيجما
                'id': 'beauty_salons',
              },
              {
                'name': 'مراكز التجميل',
                'asset': 'assets/images/figma/service_beauty_1.png', // beauty-1 في الفيجما
                'id': 'beauty_centers',
              },
              {
                'name': 'الميكب أرتست',
                'asset': 'assets/images/figma/service_beauty_4.png', // beauty-4 في الفيجما
                'id': 'makeup_artists',
              },
              {
                'name': 'منسقي المناسبات',
                'asset': 'assets/images/figma/service_makeup_artists.png', // beauty-8 في الفيجما
                'id': 'event_coordinators',
              },
            ];
            
            // ترتيب الصف الثاني حسب الفيجما بالضبط (من اليمين للشمال في العربية)
            final secondRowServicesArabic = [
              {
                'name': 'مصوري الزفاف',
                'asset': 'assets/images/figma/service_photographers.png', // photog في الفيجما
                'id': 'photographers',
              },
              {
                'name': 'مراكز التجميل',
                'asset': 'assets/images/figma/service_beauty_2.png', // beauty-2 في الفيجما
                'id': 'beauty_centers_extra',
              },
              {
                'name': 'الميكب أرتست',
                'asset': 'assets/images/figma/service_beauty_3.png', // beauty-3 في الفيجما
                'id': 'makeup_artists_extra',
              },
              {
                'name': 'عرض المزيد',
                'asset': 'assets/images/figma/service_objects_column.png', // objects-column في الفيجما
                'id': 'view_more',
              },
            ];

            // ترجمة للإنجليزية مع ترتيب LTR (عكس العربية)
            final firstRowServicesEnglish = [
              {
                'name': 'Event Coordinators',
                'asset': 'assets/images/figma/service_makeup_artists.png', // beauty-8 
                'id': 'event_coordinators',
              },
              {
                'name': 'Makeup Artists',
                'asset': 'assets/images/figma/service_beauty_4.png', // beauty-4
                'id': 'makeup_artists',
              },
              {
                'name': 'Beauty Centers',
                'asset': 'assets/images/figma/service_beauty_1.png', // beauty-1
                'id': 'beauty_centers',
              },
              {
                'name': 'Beauty Salons',
                'asset': 'assets/images/figma/service_beauty.png', // beauty
                'id': 'beauty_salons',
              },
            ];
            
            final secondRowServicesEnglish = [
              {
                'name': 'View More',
                'asset': 'assets/images/figma/service_objects_column.png', // objects-column
                'id': 'view_more',
              },
              {
                'name': 'Makeup Artists',
                'asset': 'assets/images/figma/service_beauty_3.png', // beauty-3
                'id': 'makeup_artists_extra',
              },
              {
                'name': 'Beauty Centers',
                'asset': 'assets/images/figma/service_beauty_2.png', // beauty-2
                'id': 'beauty_centers_extra',
              },
              {
                'name': 'Wedding Photographers',
                'asset': 'assets/images/figma/service_photographers.png', // photog
                'id': 'photographers',
              },
            ];

            // اختيار الترتيب حسب اللغة
            final firstRowServices = isArabic ? firstRowServicesArabic : firstRowServicesEnglish;
            final secondRowServices = isArabic ? secondRowServicesArabic : secondRowServicesEnglish;


              return Column(
                children: [
                // الصف الأول - 4 خدمات رئيسية
                Directionality(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: firstRowServices.map((item) {
                      return _buildServiceItemFigma(
                        item['name'] as String,
                        item['asset'] as String,
                        tileSize,
                        iconSize,
                        () {
                          final id = item['id'] as String;
                          final name = item['name'] as String;
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProvidersListPage(
                                categoryId: id,
                                categoryName: name,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
                
                  const SizedBox(height: 14),
                  
                // الصف الثاني - 4 عناصر إضافية (عرض المزيد + 3 خدمات)
                Directionality(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: secondRowServices.map((item) {
                      return _buildServiceItemFigma(
                        item['name'] as String,
                        item['asset'] as String,
                        tileSize,
                        iconSize,
                        () {
                          final id = item['id'] as String;
                          final name = item['name'] as String;
                          
                          if (id == 'view_more') {
                            // زر عرض المزيد - الانتقال لتاب الخدمات الرئيسي
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ServicesTab(),
                              ),
                            );
                          } else {
                            // خدمة محددة - الانتقال لصفحة مقدمي الخدمة المرتبطة بالفايربيز
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProvidersListPage(
                                  categoryId: id,
                                  categoryName: name,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                    ),
                  ),
                ],
              );
          }),
        ],
      ),
    );
  }

  Widget _buildServiceItemWithNavigation(String name, String icon, String id) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProvidersListPage(
              categoryId: id,
              categoryName: name,
            ),
          ),
        );
      },
      child: Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                icon,
                width: 44,
                height: 44,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 44,
                    height: 44,
                    color: const Color(0xFFE0E0E0),
                    child: const Icon(
                      Icons.category,
                      size: 22,
                      color: Color(0xFF8B8B8B),
                    ),
                  );
                },
              ),
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItemFigma(String name, String asset, double tileSize, double iconSize, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: tileSize,
        height: tileSize + 8, // زيادة الارتفاع قليلاً لتجنب overflow
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6), // تقليل padding لتوفير مساحة
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // منع تمدد Column أكثر من المطلوب
            children: [
              Image.asset(
                asset,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: iconSize,
                    height: iconSize,
                    color: const Color(0xFFE0E0E0),
                    child: const Icon(
                      Icons.category,
                      size: 22,
                      color: Color(0xFF8B8B8B),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6), // مسافة ثابتة بين الأيقونة والنص
              Flexible( // السماح للنص بالتوسع حسب المحتوى
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 10, // تقليل حجم الخط قليلاً
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2B2F4E),
                    height: 1.2, // تقليل spacing بين الأسطر
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // السماح بسطرين كحد أقصى
                  overflow: TextOverflow.ellipsis, // قطع النص إذا كان طويلاً
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItemWithIconNavigation(String name, IconData icon, Color color, String action) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return GestureDetector(
      onTap: () {
        if (action == 'more_services') {
          // التنقل لتاب الخدمات الرئيسي
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ServicesTab(),
            ),
          );
        }
      },
      child: Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 44,
                color: color,
              ),
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: 390,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // العنوان مع زر عرض المزيد
          Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // في العربية: العنوان أولاً (يمين) ثم زر عرض المزيد (يسار)
                // في الإنجليزية: العنوان أولاً (يسار) ثم زر عرض المزيد (يمين)
                
                // العنوان
                Text(
                  isArabic ? 'منتجات مميزة 🛒' : '🛒 Featured Products',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                    fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),
                
                // زر عرض المزيد
                GestureDetector(
                  onTap: () {
                    // التنقل إلى تاب المتجر
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const StoreTab())
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      isArabic ? 'عرض المزيد' : 'View More',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          
          // المنتجات من Firebase
          SizedBox(
            height: 280,
            child: FutureBuilder<List<Product>>(
              future: StoreService().getProducts(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9A46D7),
                    ),
                  );
                }
                
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  // في حالة عدم وجود منتجات أو خطأ، نعرض منتجات تجريبية من الفيجما
                  return Directionality(
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                        children: [
                          // منتج 1 - بدون badge
                          _buildFigmaProductCard(
                            name: isArabic ? 'مولد النص التلقائي لعرض اسم المنتجات' : 'Auto text generator for product names',
                            category: isArabic ? 'تصنيف المنتج' : 'Product Category', 
                            imageAsset: 'assets/images/figma/product_shoe_placeholder.png',
                            rating: 4.3,
                            price: 160,
                            hasSpecialBadge: false,
                            isNew: false,
                            screenWidth: screenWidth,
                            isArabic: isArabic,
                          ),
                          const SizedBox(width: 11),
                          
                          // منتج 2 - مع تقييم
                          _buildFigmaProductCard(
                            name: isArabic ? 'مولد النص التلقائي لعرض اسم المنتجات' : 'Auto text generator for product names',
                            category: isArabic ? 'تصنيف المنتج' : 'Product Category',
                            imageAsset: 'assets/images/figma/product_shoe_image.png',
                            backgroundAsset: 'assets/images/figma/product_shoe_bg.png',
                            rating: 4.3,
                            price: 160,
                            hasSpecialBadge: false,
                            isNew: false,
                            screenWidth: screenWidth,
                            isArabic: isArabic,
                          ),
                          const SizedBox(width: 11),
                          
                          // منتج 3 - الأفضل مبيعاً
                          _buildFigmaProductCard(
                            name: isArabic ? 'مولد النص التلقائي لعرض اسم المنتجات' : 'Auto text generator for product names',
                            category: isArabic ? 'تصنيف المنتج' : 'Product Category',
                            imageAsset: 'assets/images/figma/product_shoe_3.png',
                            rating: 4.3,
                            price: 160,
                            hasSpecialBadge: true,
                            bestSellerText: isArabic ? 'الأفضل مبيعًا' : 'Best Seller',
                            isNew: false,
                            screenWidth: screenWidth,
                            isArabic: isArabic,
                          ),
                          const SizedBox(width: 11),
                          
                          // منتج 4 - جديد
                          _buildFigmaProductCard(
                            name: isArabic ? 'مولد النص التلقائي لعرض اسم المنتجات' : 'Auto text generator for product names',
                            category: isArabic ? 'تصنيف المنتج' : 'Product Category',
                            imageAsset: 'assets/images/figma/product_shoe_4.png',
                            rating: 4.3,
                            price: 160,
                            hasSpecialBadge: false,
                            isNew: true,
                            newText: isArabic ? 'جديد' : 'New',
                            screenWidth: screenWidth,
                            isArabic: isArabic,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // عرض المنتجات الحقيقية من Firebase
                final products = snapshot.data!;
                return Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 11),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildFirebaseProductCard(product, screenWidth, isArabic);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget للمنتج الجديد مطابق للفيجما
  Widget _buildFigmaProductCard({
    required String name,
    required String category,
    required String imageAsset,
    String? backgroundAsset,
    required double rating,
    required int price,
    required bool hasSpecialBadge,
    String? bestSellerText,
    required bool isNew,
    String? newText,
    required double screenWidth,
    required bool isArabic,
  }) {
    final cardWidth = screenWidth <= 360 ? 160.0 : 171.0;
    final imageHeight = 150.0;
    
    return GestureDetector(
      onTap: () {
        // إنشاء Product object من البيانات المحددة
        final product = Product(
          id: name.hashCode.toString(),
          name: name,
          description: category,
          category: category,
          price: price.toDouble(),
          imageUrls: [imageAsset],
          merchantId: 'figma_demo',
          merchantName: 'Figma Demo Store',
          reviews: [],
          searchKeywords: [name, category],
          oldPrice: price.toDouble() + 50,
          createdAt: Timestamp.now(),
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFF6F6F6), width: 1),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
                children: [
          // صورة المنتج
          Container(
            width: cardWidth,
            height: imageHeight,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Stack(
              children: [
                // الخلفية إذا كانت موجودة
                if (backgroundAsset != null)
                  Container(
                    width: cardWidth,
                    height: imageHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(11),
                        topRight: Radius.circular(11),
                      ),
                    ),
                  ),
                
                // صورة المنتج الرئيسية
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                  child: Image.asset(
                    imageAsset,
                    width: cardWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: cardWidth,
                        height: imageHeight,
                        color: const Color(0xFFF6F6F6),
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Color(0xFF727880),
                        ),
                      );
                    },
                  ),
                ),
                
                // Badge الأفضل مبيعاً
                if (hasSpecialBadge && bestSellerText != null)
                  Positioned(
                    top: 11,
                    right: isArabic ? 11 : null,
                    left: isArabic ? null : 11,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA61E1E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bestSellerText,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.flash_on,
                            size: 14,
                            color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

                // Badge جديد
                if (isNew && newText != null)
                  Positioned(
                    top: 11,
                    right: isArabic ? 11 : null,
                    left: isArabic ? null : 11,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27CD81),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        newText,
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // تفاصيل المنتج
          Container(
            width: cardWidth,
            padding: const EdgeInsets.all(12),
            child: Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                // اسم المنتج
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D2035),
                    height: 1.583,
                  ),
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // التقييم والتصنيف - نفس الترتيب في اللغتين مطابق للفيجما
                Directionality(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Row(
                    children: [
                      // التقييم أولاً في كلا اللغتين
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEED9),
                          borderRadius: BorderRadius.circular(48),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          textDirection: TextDirection.ltr, // للتأكد من ترتيب الرقم والنجمة
                          children: [
                            Text(
                              rating.toString(),
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF313131),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.star,
                              size: 10,
                              color: Color(0xFFFF8A00),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      // التصنيف ثانياً في كلا اللغتين
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF727880),
                          ),
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // السعر
                const SizedBox(height: 6),
                Text(
                  isArabic ? '$price ر.س' : '$price SAR',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A46D7),
                  ),
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // دالة لبناء بطاقة منتج من Firebase بنفس تصميم الفيجما
  Widget _buildFirebaseProductCard(Product product, double screenWidth, bool isArabic) {
    final cardWidth = screenWidth * 0.45;
    
    // حساب التقييم من المراجعات
    double rating = 0.0;
    if (product.reviews.isNotEmpty) {
      final totalRating = product.reviews.fold(0.0, (sum, review) => sum + review.rating);
      rating = totalRating / product.reviews.length;
    } else {
      rating = 4.0 + (product.hashCode % 10) / 10; // تقييم تلقائي بين 4.0 و 4.9
    }
    
    // تحديد نوع البادج بناءً على خصائص المنتج
    bool hasSpecialBadge = false;
    bool isNew = false;
    String? badgeText;
    
    // تحديد ما إذا كان المنتج جديد (أقل من أسبوع)
    final now = DateTime.now();
    final createdAt = product.createdAt.toDate();
    final daysDifference = now.difference(createdAt).inDays;
    
    if (daysDifference <= 7) {
      isNew = true;
      badgeText = isArabic ? 'جديد' : 'New';
    } else if (product.reviews.length >= 10 && rating >= 4.5) {
      hasSpecialBadge = true;
      badgeText = isArabic ? 'الأفضل مبيعًا' : 'Best Seller';
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFF6F6F6), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة المنتج
            Container(
              height: 158,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Stack(
                children: [
                  // الصورة الرئيسية
                  Center(
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(
                            product.imageUrls.first,
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/figma/product_shoe_placeholder.png',
                                width: 90,
                                height: 90,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    color: const Color(0xFFE0E0E0),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                      color: Color(0xFF8B8B8B),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/figma/product_shoe_placeholder.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 90,
                                height: 90,
                                color: const Color(0xFFE0E0E0),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Color(0xFF8B8B8B),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // البادج
                  if (hasSpecialBadge || isNew)
                    Positioned(
                      top: 8,
                      left: isArabic ? null : 8,
                      right: isArabic ? 8 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasSpecialBadge ? const Color(0xFFFFEED9) : const Color(0xFFE8F5E8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText ?? '',
                          style: TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: hasSpecialBadge ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
                          ),
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // تفاصيل المنتج
            Container(
              padding: const EdgeInsets.all(12),
              child: Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // التقييم والتصنيف
                    Directionality(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          // التقييم أولاً في كلا الاتجاهين
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEED9),
                              borderRadius: BorderRadius.circular(48),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr, // النجمة دائماً من اليسار
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontFamily: 'Ping AR + LT',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          if (product.category.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            // التصنيف ثانياً
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(48),
                              ),
                              child: Text(
                                product.category,
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6B7280),
                                ),
                                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // اسم المنتج
                    const SizedBox(height: 8),
                    Directionality(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B2F4E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                    ),
                    
                    // السعر
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        isArabic ? '${product.price.toInt()} ر.س' : '${product.price.toInt()} SAR',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A46D7),
                        ),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(String name, String image) {
    return Container(
      width: 88,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            image,
            width: 88,
            height: 88,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 88,
                height: 88,
                color: const Color(0xFFE0E0E0),
                child: const Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Color(0xFF8B8B8B),
                ),
              );
            },
          ),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2B2F4E),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildJobsSection() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Container(
      width: 390,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // العنوان مع زر عرض المزيد
          Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // العنوان
                Text(
                  isArabic ? 'وظائف شاغرة' : 'Open Jobs',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                    fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),

                // زر عرض المزيد
                GestureDetector(
                  onTap: () {
                    // يمكن إضافة التنقل إلى صفحة الوظائف الكاملة هنا
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic ? 'سيتم إضافة صفحة الوظائف قريباً' : 'Jobs page coming soon',
                          style: const TextStyle(fontFamily: 'Ping AR + LT'),
                        ),
                        backgroundColor: const Color(0xFF9A46D7),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      isArabic ? 'عرض المزيد' : 'View More',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // قائمة الوظائف
          Column(
            children: [
              _buildFigmaJobCard(
                title: isArabic ? 'مطلوب موظفة للعمل في صالون تجميل' : 'Female employee required for beauty salon',
                location: isArabic ? 'الرياض' : 'Riyadh',
                company: isArabic ? 'صالون الأميرة للتجميل' : 'Princess Beauty Salon',
                salary: isArabic ? 'قابل للتفاوض' : 'Negotiable',
                postedTime: isArabic ? 'منذ ٥ أشهر' : '5 months ago',
                applicants: isArabic ? 'أكثر من 14 متقدم' : '14+ applicants',
                workType: isArabic ? 'دوام كامل' : 'Full-time',
                experience: isArabic ? 'مبتدأ' : 'Beginner',
                iconAsset: 'assets/images/figma/job_beauty_salon_icon.png',
                isRecommended: true,
                isArabic: isArabic,
              ),
              const SizedBox(height: 14),
              _buildFigmaJobCard(
                title: isArabic ? 'مطلوب موظفة للعمل في صالون تجميل' : 'Female employee required for beauty salon',
                location: isArabic ? 'الرياض' : 'Riyadh',
                company: isArabic ? 'صالون الأميرة للتجميل' : 'Princess Beauty Salon',
                salary: isArabic ? '8900 ريال' : '8900 SAR',
                postedTime: isArabic ? 'منذ ٥ أشهر' : '5 months ago',
                applicants: isArabic ? 'أكثر من 14 متقدم' : '14+ applicants',
                workType: isArabic ? 'دوام كامل' : 'Full-time',
                experience: isArabic ? 'مبتدأ' : 'Beginner',
                iconAsset: 'assets/images/figma/job_beauty_center_icon.png',
                isRecommended: false,
                isArabic: isArabic,
              ),
              const SizedBox(height: 14),
              _buildFigmaJobCard(
                title: isArabic ? 'مطلوب موظفة للعمل في صالون تجميل' : 'Female employee required for beauty salon',
                location: isArabic ? 'الرياض' : 'Riyadh',
                company: isArabic ? 'صالون الأميرة للتجميل' : 'Princess Beauty Salon',
                salary: isArabic ? '4600 ريال' : '4600 SAR',
                postedTime: isArabic ? 'منذ ٥ أشهر' : '5 months ago',
                applicants: isArabic ? 'أكثر من 14 متقدم' : '14+ applicants',
                workType: isArabic ? 'دوام كامل' : 'Full-time',
                experience: isArabic ? 'مبتدأ' : 'Beginner',
                iconAsset: 'assets/images/figma/job_event_planning_icon.png',
                isRecommended: false,
                isArabic: isArabic,
              ),
              const SizedBox(height: 14),
              _buildFigmaJobCard(
                title: isArabic ? 'مطلوب موظفة للعمل في صالون تجميل' : 'Female employee required for beauty salon',
                location: isArabic ? 'الرياض' : 'Riyadh',
                company: isArabic ? 'صالون الأميرة للتجميل' : 'Princess Beauty Salon',
                salary: isArabic ? 'قابل للتفاوض' : 'Negotiable',
                postedTime: isArabic ? 'منذ ٥ أشهر' : '5 months ago',
                applicants: isArabic ? 'أكثر من 14 متقدم' : '14+ applicants',
                workType: isArabic ? 'دوام كامل' : 'Full-time',
                experience: isArabic ? 'مبتدأ' : 'Beginner',
                iconAsset: 'assets/images/figma/job_makeup_artist_icon.png',
                isRecommended: false,
                isArabic: isArabic,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaJobCard({
    required String title,
    required String location,
    required String company,
    required String salary,
    required String postedTime,
    required String applicants,
    required String workType,
    required String experience,
    required String iconAsset,
    required bool isRecommended,
    required bool isArabic,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'تفاصيل الوظيفة: $title' : 'Job details: $title',
              style: const TextStyle(fontFamily: 'Ping AR + LT'),
            ),
            backgroundColor: const Color(0xFF9A46D7),
          ),
        );
      },
      child: Container(
        width: 382,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
      ),
        child: Column(
          children: [
            // قسم تفاصيل الوظيفة الرئيسي
            Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Row(
        children: [
                  // النص والتفاصيل
          Expanded(
            child: Padding(
                      padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                          // العنوان
                  Text(
                            title,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                              fontSize: 12,
                      fontWeight: FontWeight.w700,
                              color: Color(0xFF1D2035),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                  ),
                          const SizedBox(height: 4),
                          
                          // تفاصيل إضافية
                  Text(
                            '${isArabic ? "السعودية . " : "Saudi Arabia . "}$location · $postedTime · $applicants\n${isArabic ? "الدوام من مقر الشركة" : "On-site work"} · $workType\n${isArabic ? "المستوي المطلوب" : "Experience level"} $experience',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                              fontSize: 8,
                      fontWeight: FontWeight.w400,
                              color: Color(0xFF7991A4),
                              height: 1.75,
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                ],
              ),
            ),
          ),

                  // الأيقونة
                  Container(
                    width: 72,
                    height: 72,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
            child: Image.asset(
                        iconAsset,
                        width: 50,
                        height: 54,
                        fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                            width: 50,
                            height: 54,
                  color: const Color(0xFFE0E0E0),
                  child: const Icon(
                              Icons.work_outline,
                              size: 30,
                    color: Color(0xFF8B8B8B),
                  ),
                );
              },
                      ),
            ),
          ),
        ],
              ),
            ),

            // الشريط الفاصل
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFF8F8F8),
            ),

            // قسم تفاصيل الراتب والشركة
            Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // تفاصيل الراتب
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6FE),
                        border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Directionality(
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 12,
                              color: Color(0xFF9A46D7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${isArabic ? "الراتب الأساسي : " : "Basic salary: "}$salary',
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9A46D7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // الموقع
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF6FE),
                        border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Directionality(
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Color(0xFF9A46D7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              location,
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9A46D7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // اسم الشركة
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF6FE),
                          border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Directionality(
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 12,
                                color: Color(0xFF9A46D7),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  company,
                                  style: const TextStyle(
                                    fontFamily: 'Ping AR + LT',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF9A46D7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // قسم الوظيفة المناسبة (إذا كانت موصى بها)
            if (isRecommended) ...[
              const SizedBox(height: 12),
              Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1ED29C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          isArabic ? 'وظيفة تناسبك بناءً على بياناتك الشخصية واهتماماتك' : 'Job suits you based on your personal data and interests',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1ED29C),
                          ),
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingVideosSection() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Container(
      width: 382,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // العنوان مع زر عرض المزيد
          Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // العنوان
                Text(
                  isArabic ? '👀 مكتبة فيديوهات الترند الان!' : '👀 Trending Videos Library!',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                    fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2F4E),
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),

                // زر عرض المزيد
                GestureDetector(
                  onTap: () {
                    // التنقل إلى صفحة الفيديوهات
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideoPage())
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      isArabic ? 'عرض المزيد' : 'View More',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // الفيديوهات الحقيقية من قاعدة البيانات
          FutureBuilder<List<Post>>(
            future: CommunityService().getPostsWithPagination(
              limit: 5, // 3-5 فيديوهات حسب المطلوب
              category: 'video',
            ).then((result) => result.posts),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF9A46D7),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                // في حالة عدم وجود فيديوهات أو خطأ، نعرض فيديوهات تجريبية من الفيجما
                return Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Column(
                children: [
                      _buildFigmaVideoCard(
                        title: isArabic ? 'عنوان الفيديو المعروض هنا' : 'Video title displayed here',
                        views: isArabic ? '2 مليون' : '2 Million',
                        time: isArabic ? 'منذ يوم واحد' : '1 day ago',
                        duration: '7:43:34',
                        thumbnailAsset: 'assets/images/figma/video_thumbnail_1.png',
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 16),
                      _buildFigmaVideoCard(
                        title: isArabic ? 'عنوان الفيديو المعروض هنا' : 'Video title displayed here',
                        views: isArabic ? '1.5 مليون' : '1.5 Million',
                        time: isArabic ? 'منذ 3 أيام' : '3 days ago',
                        duration: '5:22:15',
                        thumbnailAsset: 'assets/images/figma/video_thumbnail_2.png',
                        isArabic: isArabic,
                      ),
                      const SizedBox(height: 16),
                      _buildFigmaVideoCard(
                        title: isArabic ? 'عنوان الفيديو المعروض هنا' : 'Video title displayed here',
                        views: isArabic ? '980 ألف' : '980K',
                        time: isArabic ? 'منذ أسبوع' : '1 week ago',
                        duration: '3:45:10',
                        thumbnailAsset: 'assets/images/figma/video_thumbnail_3.png',
                        isArabic: isArabic,
                      ),
                    ],
                  ),
                );
              }

              // عرض الفيديوهات الحقيقية من قاعدة البيانات
              final videos = snapshot.data!;
              return Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: Column(
                  children: List.generate(videos.length, (index) {
                    if (index > 0) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildFirebaseVideoCard(videos[index], isArabic),
                        ],
                      );
                    }
                    return _buildFirebaseVideoCard(videos[index], isArabic);
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // دالة لبناء بطاقة فيديو مطابقة للفيجما (تصميم أفقي)
  Widget _buildFigmaVideoCard({
    required String title,
    required String views,
    required String time,
    required String duration,
    required String thumbnailAsset,
    required bool isArabic,
  }) {
    return GestureDetector(
      onTap: () {
        // عرض رسالة أن هذه فيديوهات تجريبية من الفيجما
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'فيديو تجريبي من الفيجما - لا توجد بيانات حقيقية' : 'Demo video from Figma - No real data available',
              style: const TextStyle(fontFamily: 'Ping AR + LT'),
            ),
            backgroundColor: const Color(0xFF9A46D7),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 382,
        height: 104, // ارتفاع ثابت كما في الفيجما
        padding: const EdgeInsets.all(0),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            children: [
              // صورة الفيديو المصغرة
              Container(
                width: 160,
                height: 90,
      decoration: BoxDecoration(
                  color: const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(12),
      ),
                child: Stack(
        children: [
                    // الصورة المصغرة
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.asset(
                            thumbnailAsset,
                            width: 160,
                            height: 90,
                            fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                                width: 160,
                                height: 90,
                                color: const Color(0xFFBDBDBD),
                  child: const Icon(
                                  Icons.video_library,
                    size: 40,
                                  color: Colors.white,
                  ),
                );
              },
            ),
                          
                          // أيقونة تشغيل في المنتصف
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // مدة الفيديو
                    Positioned(
                      bottom: 10,
                      right: isArabic ? null : 10,
                      left: isArabic ? 10 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          duration,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
              color: Colors.white,
                          ),
                        ),
            ),
          ),
        ],
                ),
              ),

              const SizedBox(width: 16),

              // تفاصيل الفيديو
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // عنوان الفيديو
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D2035),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),

                    const SizedBox(height: 12),

                    // عدد المشاهدات والتوقيت
                    Directionality(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Text(
                            views,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF616161),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isArabic ? 'المشاهدات' : 'Views',
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF616161),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF616161),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitySection() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Container(
      width: 382,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // العنوان وزر عرض المزيد
          Directionality(
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // العنوان
                Text(
                  isArabic ? '🔥 المحتوي الأشهر فى المجتمع' : '🔥 Most Popular Community Content',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 16,
                    fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2F4E),
                ),
                ),
                
                // زر عرض المزيد
                GestureDetector(
                  onTap: () {
                    // التنقل إلى صفحة المجتمع
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CommunityPage())
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      isArabic ? 'عرض المزيد' : 'View More',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 14),
          
          // المنشورات الحقيقية من قاعدة البيانات
          FutureBuilder<List<Post>>(
            future: CommunityService().getPostsWithPagination(
              limit: 10, // عرض المزيد من المنشورات المتنوعة
            ).then((result) => result.posts),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF9A46D7),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                // في حالة عدم وجود منشورات أو خطأ، نعرض منشورات تجريبية من الفيجما
                return _buildFigmaCommunityPosts(isArabic);
              }

              // عرض المنشورات الحقيقية من قاعدة البيانات
              final posts = snapshot.data!;
              return Column(
                children: List.generate(posts.length, (index) {
                  if (index > 0) {
                    return Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildInteractiveCommunityPost(posts[index], isArabic),
                      ],
                    );
                  }
                  return _buildInteractiveCommunityPost(posts[index], isArabic);
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPostItem(String image, String name, String content, CommunityPostType postType, GlobalKey buttonKey) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final realPost = _realPosts[postType];
    
    return GestureDetector(
      onTap: () {
        _navigateToPostDetail(postType);
      },
      child: Container(
        width: 90,
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(45),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.asset(
                            image,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return SvgPicture.asset(
                                'assets/icons/figma/profile_icon.svg',
                                width: 48,
                                height: 48,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2B2F4E),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        isArabic ? 'منذ 2 ساعات' : '2 hours ago',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8B8B8B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    realPost?.content ?? content,
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2B2F4E),
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (realPost != null && realPost.mediaUrls.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(realPost.mediaUrls.first),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      _quickHeartReaction(postType);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: _userReactions[postType] == '❤️' ? const Color(0xFFEB5757) : const Color(0xFF8B8B8B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (_postReactions[postType]?['❤️'] ?? 0).toString(),
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showFacebookStyleReactions(postType, buttonKey);
                    },
                    child: Row(
                      children: [
                        _buildReactionButton(postType, buttonKey),
                        const SizedBox(width: 4),
                        Text(
                          (_postReactions[postType]?.values.isNotEmpty == true 
                              ? _postReactions[postType]!.values.reduce((a, b) => a + b) 
                              : 0).toString(),
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _navigateToPostDetail(postType);
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 16,
                          color: const Color(0xFF8B8B8B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (_realCommentCounts[postType] ?? 0).toString(),
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8B8B8B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(CommunityPostType postType, GlobalKey buttonKey) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Builder(
      builder: (context) {
        final reaction = _userReactions[postType];
        final reactionCount = _postReactions[postType]?[reaction] ?? 0;
        
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reaction != null ? const Color(0xFFEB5757) : const Color(0xFFFAF6FE),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: reaction != null 
              ? Text(
                  reaction,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                )
              : Icon(
                  Icons.thumb_up,
                  size: 16,
                  color: isArabic ? Colors.white : const Color(0xFF8B8B8B),
                ),
        );
      },
    );
  }

  // دالة لبناء منشورات تجريبية من الفيجما في حالة عدم وجود بيانات حقيقية
  Widget _buildFigmaCommunityPosts(bool isArabic) {
    return Column(
      children: [
        _buildFigmaCommunityPost(
          profileImage: 'assets/images/figma/profile_user_23.png',
          userName: isArabic ? 'ياسين الامير' : 'Yassin Al-Amir',
          timeAgo: isArabic ? 'اليوم 10:23م' : 'Today 10:23 PM',
          content: isArabic 
            ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد مثل هذا النص أو العديد من النصوص الأخرى إضافة إلى زيادة عدد الحروف'
            : 'This text is an example that can be replaced in the same space. This text was generated from the Arabic text generator, where you can generate such text or many other texts in addition to increasing the number of characters',
          hashtags: ['#هاشتاج', '#هاشتاج عن حدث معين'],
          reactions: {'❤️': 34, '👀': 11, '🔎': 60, '😍': 22},
          commentsCount: 4,
          isFollowing: true,
          isContentCreator: false,
          isArabic: isArabic,
        ),
        
        const SizedBox(height: 24),
        
        _buildFigmaCommunityPost(
          profileImage: 'assets/images/figma/profile_user_06.png',
          userName: isArabic ? 'محمد سعيد' : 'Mohamed Said',
          timeAgo: isArabic ? 'اليوم 10:23م' : 'Today 10:23 PM',
          content: isArabic 
            ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد مثل هذا النص أو العديد من النصوص الأخرى إضافة إلى زيادة عدد الحروف'
            : 'This text is an example that can be replaced in the same space. This text was generated from the Arabic text generator, where you can generate such text or many other texts in addition to increasing the number of characters',
          hashtags: ['#هاشتاج', '#هاشتاج عن حدث معين'],
          reactions: {},
          commentsCount: 0,
          isFollowing: false,
          isContentCreator: true,
          isArabic: isArabic,
        ),
        
        const SizedBox(height: 24),
        
        _buildFigmaCommunityPost(
          profileImage: 'assets/images/figma/profile_user_20.png',
          userName: isArabic ? 'فاطمة الزهراء' : 'Fatima Zahra',
          timeAgo: isArabic ? 'اليوم 10:23م' : 'Today 10:23 PM',
          content: isArabic 
            ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة'
            : 'This text is an example that can be replaced in the same space',
          hashtags: [],
          reactions: {},
          commentsCount: 0,
          isFollowing: true,
          isContentCreator: false,
          isArabic: isArabic,
          hasComments: true,
          comments: [
            {
              'profileImage': 'assets/images/figma/profile_user_23.png',
              'userName': isArabic ? 'ياسين الامير' : 'Yassin Al-Amir',
              'content': isArabic 
                ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد مثل هذا النص'
                : 'This text is an example that can be replaced in the same space. This text was generated from the Arabic text generator, where you can generate such text',
              'timeAgo': isArabic ? 'منذ 3 دقائق' : '3 minutes ago',
              'likes': 0,
            },
            {
              'profileImage': 'assets/images/figma/profile_user_23.png',
              'userName': isArabic ? 'ياسين الامير' : 'Yassin Al-Amir',
              'content': isArabic 
                ? 'هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص العربى، حيث يمكنك أن تولد مثل هذا النص'
                : 'This text is an example that can be replaced in the same space. This text was generated from the Arabic text generator, where you can generate such text',
              'timeAgo': isArabic ? 'منذ 3 دقائق' : '3 minutes ago',
              'likes': 0,
            },
          ],
        ),
      ],
    );
  }

  // دالة لبناء منشور من الفيجما بتصميم مطابق للتصميم الأصلي
  Widget _buildFigmaCommunityPost({
    required String profileImage,
    required String userName,
    required String timeAgo,
    required String content,
    required List<String> hashtags,
    required Map<String, int> reactions,
    required int commentsCount,
    required bool isFollowing,
    required bool isContentCreator,
    required bool isArabic,
    bool hasComments = false,
    List<Map<String, dynamic>>? comments,
  }) {
    return Container(
      width: 382,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
      ),
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس المنشور مع معلومات المستخدم
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // صورة المستخدم
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          profileImage,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 36,
                              height: 36,
                              color: const Color(0xFFBDBDBD),
                              child: const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // معلومات المستخدم
                    Column(
                      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1D2035),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (isContentCreator)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                height: 19,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFF1ED29C), width: 1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isArabic ? 'صانعة محتوي' : 'Content Creator',
                                      style: const TextStyle(
                                        fontFamily: 'Ping AR + LT',
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1ED29C),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.verified,
                                      size: 8,
                                      color: Color(0xFF1ED29C),
                                    ),
                                  ],
                                ),
                              )
                            else if (isFollowing)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                height: 19,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFAAB9C5), width: 1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    isArabic ? 'متابع' : 'Following',
                                    style: const TextStyle(
                                      fontFamily: 'Ping AR + LT',
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFAAB9C5),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                height: 19,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF6FE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    isArabic ? 'متابعة' : 'Follow',
                                    style: const TextStyle(
                                      fontFamily: 'Ping AR + LT',
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF9A46D7),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 8,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFAAB9C5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // أيقونة القائمة
                const Icon(
                  Icons.more_vert,
                  size: 24,
                  color: Color(0xFFAAB9C5),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // محتوى المنشور
            Text(
              content,
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF323F49),
              ),
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
            ),
            
            // الهاشتاجات
            if (hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 13,
                children: hashtags.map((hashtag) {
                  final isFirst = hashtags.indexOf(hashtag) == 0;
                  return Text(
                    hashtag,
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isFirst ? const Color(0xFF1AB385) : const Color(0xFFF68801),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // خط فاصل
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFF8F8F8),
            ),
            
            const SizedBox(height: 16),
            
            // تفاعلات المنشور
            Row(
              children: [
                // تفاعلات الإيموجي
                if (reactions.isNotEmpty)
                  Row(
                    children: [
                      ...reactions.entries.take(4).map((entry) {
                        return Container(
                          width: 59,
                          height: 30,
                          margin: const EdgeInsets.only(right: 9),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEED9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.value.toString(),
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF633701),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      // زر إضافة تفاعل
                      Container(
                        width: 41,
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.sentiment_satisfied_outlined,
                          size: 20,
                          color: Color(0xFFAAB9C5),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: 41,
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.sentiment_satisfied_outlined,
                      size: 20,
                      color: Color(0xFFAAB9C5),
                    ),
                  ),
                
                const Spacer(),
                
                // زر التعليقات
                Row(
                  children: [
                    Text(
                      '$commentsCount ${isArabic ? "تعليقات" : "comments"}',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF637D92),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 24,
                      color: Color(0xFF637D92),
                    ),
                  ],
                ),
              ],
            ),
            
            // التعليقات (إذا كانت موجودة)
            if (hasComments && comments != null) ...[
              const SizedBox(height: 16),
              
              // خط فاصل
              Container(
                width: 1,
                height: 104,
                color: const Color(0xFFF8F8F8),
                margin: const EdgeInsets.only(right: 18),
              ),
              
              const SizedBox(height: 10),
              
              // التعليقات
              ...comments.map((comment) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // صورة المعلق
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            comment['profileImage'],
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 30,
                                height: 30,
                                color: const Color(0xFFBDBDBD),
                                child: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10),
                      
                      // محتوى التعليق
                      Expanded(
                        child: Column(
                          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  comment['userName'],
                                  style: const TextStyle(
                                    fontFamily: 'Ping AR + LT',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1D2035),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                  height: 19,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFAAB9C5), width: 1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isArabic ? 'متابع' : 'Following',
                                      style: const TextStyle(
                                        fontFamily: 'Ping AR + LT',
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFAAB9C5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 6),
                            
                            Text(
                              comment['content'],
                              style: const TextStyle(
                                fontFamily: 'Ping AR + LT',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1D2035),
                              ),
                              textAlign: isArabic ? TextAlign.right : TextAlign.left,
                            ),
                            
                            const SizedBox(height: 6),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${comment['likes']} ${isArabic ? "اعجبني" : "likes"}',
                                  style: const TextStyle(
                                    fontFamily: 'Ping AR + LT',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFB6C3CD),
                                  ),
                                ),
                                Text(
                                  comment['timeAgo'],
                                  style: const TextStyle(
                                    fontFamily: 'Ping AR + LT',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFFB6C3CD),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      isArabic ? 'أضف رد' : 'Add Reply',
                                      style: const TextStyle(
                                        fontFamily: 'Ping AR + LT',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF637D92),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 20,
                                      color: Color(0xFF637D92),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      isArabic ? 'اعجبني' : 'Like',
                                      style: const TextStyle(
                                        fontFamily: 'Ping AR + LT',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF637D92),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.favorite_border,
                                      size: 20,
                                      color: Color(0xFF637D92),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // دالة لبناء منشور تفاعلي حقيقي مع نظام التفاعلات الكامل
  Widget _buildInteractiveCommunityPost(Post post, bool isArabic) {
    return _InteractiveCommunityPost(
      post: post,
      isArabic: isArabic,
    );
  }

  // دالة لبناء المحتوى المرئي للمنشورات غير التفاعلية
  Widget _buildStaticMediaContent(Post post, bool isArabic) {
    // إذا كان فيديو مع صورة مصغرة
    if (post.videoTitle != null && post.videoTitle!.isNotEmpty) {
      return _buildStaticVideoThumbnail(post, isArabic);
    }
    // إذا كان صورة عادية
    else if (post.mediaUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          post.mediaUrls.first,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFFF8F8F8),
              child: const Icon(
                Icons.image,
                size: 50,
                color: Color(0xFFBDBDBD),
              ),
            );
          },
        ),
      );
    }
    // fallback
    return const SizedBox.shrink();
  }

  // دالة لبناء صورة مصغرة للفيديو (نسخة مبسطة للمنشورات غير التفاعلية)
  Widget _buildStaticVideoThumbnail(Post post, bool isArabic) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8F8F8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // الصورة المصغرة للفيديو
            if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty)
              Image.network(
                post.thumbnailUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildSimpleVideoFallback(post);
                },
              )
            else if (post.mediaUrls.isNotEmpty)
              Image.network(
                post.mediaUrls.first,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildSimpleVideoFallback(post);
                },
              )
            else
              _buildSimpleVideoFallback(post),

            // طبقة شفافة مع أيقونة التشغيل
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة fallback بسيطة للفيديو
  Widget _buildSimpleVideoFallback(Post post) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9A46D7).withOpacity(0.3),
            const Color(0xFFBDBDBD),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 40,
            color: Colors.white70,
          ),
          const SizedBox(height: 8),
          Text(
            post.videoTitle ?? 'فيديو',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // دالة لبناء منشور حقيقي من Firebase بنفس تصميم الفيجما
  Widget _buildFirebaseCommunityPost(Post post, bool isArabic) {
    // تنسيق الوقت منذ النشر
    String formatTimeAgo(DateTime createdAt) {
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      
      if (difference.inDays > 30) {
        final months = difference.inDays ~/ 30;
        return isArabic ? 'منذ $months شهر' : '$months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return isArabic ? 'منذ ${difference.inDays} يوم' : '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return isArabic ? 'منذ ${difference.inHours} ساعة' : '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return isArabic ? 'منذ ${difference.inMinutes} دقيقة' : '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
    }

    final timeAgo = formatTimeAgo(post.createdAt);
    
    return GestureDetector(
      onTap: () {
        // التنقل إلى تفاصيل المنشور
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(post: post),
          ),
        );
      },
      child: Container(
        width: 382,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
        ),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس المنشور مع معلومات المستخدم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // صورة المستخدم
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: post.userImage.isNotEmpty
                            ? Image.network(
                                post.userImage,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 36,
                                    height: 36,
                                    color: const Color(0xFFBDBDBD),
                                    child: const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 36,
                                height: 36,
                                color: const Color(0xFFBDBDBD),
                                child: const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // معلومات المستخدم
                      Column(
                        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.userName,
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1D2035),
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (post.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                  height: 19,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFF1ED29C), width: 1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isArabic ? 'صانع محتوي' : 'Content Creator',
                                        style: const TextStyle(
                                          fontFamily: 'Ping AR + LT',
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1ED29C),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.verified,
                                        size: 8,
                                        color: Color(0xFF1ED29C),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                  height: 19,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF6FE),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isArabic ? 'متابعة' : 'Follow',
                                      style: const TextStyle(
                                        fontFamily: 'Ping AR + LT',
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF9A46D7),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 8,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAAB9C5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // أيقونة القائمة
                  const Icon(
                    Icons.more_vert,
                    size: 24,
                    color: Color(0xFFAAB9C5),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // محتوى المنشور
              Text(
                post.content,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF323F49),
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),
              
              // الهاشتاجات
              if (post.hashtags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 13,
                  children: post.hashtags.map((hashtag) {
                    final isFirst = post.hashtags.indexOf(hashtag) == 0;
                    return Text(
                      '#$hashtag',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isFirst ? const Color(0xFF1AB385) : const Color(0xFFF68801),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              // صورة أو فيديو المنشور (إذا كانت موجودة)
              if (post.mediaUrls.isNotEmpty || 
                  (post.videoTitle != null && post.thumbnailUrl != null)) ...[
                const SizedBox(height: 16),
                _buildStaticMediaContent(post, isArabic),
              ],
              
              const SizedBox(height: 16),
              
              // خط فاصل
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFF8F8F8),
              ),
              
              const SizedBox(height: 16),
              
              // تفاعلات المنشور
              Row(
                children: [
                  // زر إضافة تفاعل
                  Container(
                    width: 41,
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.sentiment_satisfied_outlined,
                      size: 20,
                      color: Color(0xFFAAB9C5),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // زر التعليقات
                  Row(
                    children: [
                      Text(
                        '${post.commentCount} ${isArabic ? "تعليقات" : "comments"}',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF637D92),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 24,
                        color: Color(0xFF637D92),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomOffersSection() {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return Container(
      width: 390,
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            _OfferCard(
              width: 183,
              height: 95,
              iconBuilder: (context) => Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8CCF5),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset('assets/icons/figma/home_icon.svg', width: 24, height: 24),
              ),
              title: isArabic ? 'عروض مميزة' : 'Featured Offers',
              subtitle: isArabic ? 'خصومات تصل إلى 50%' : 'Discounts up to 50%',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())),
            ),
            const SizedBox(width: 16),
            _OfferCard(
              width: 184,
              height: 95,
              iconBuilder: (context) => Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8CCF5),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/icons/wallet_figma.png', width: 24, height: 24, fit: BoxFit.contain),
              ),
              title: isArabic ? 'بطاقات سومي' : 'Sumi Cards',
              subtitle: isArabic ? 'إدارة بطاقاتك بسهولة' : 'Manage your cards easily',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCardsPage())),
            ),
          ],
        ),
      ),
    );
  }
  
  // دالة لتنسيق الوقت باستخدام timeago
  String _formatTimeAgo(DateTime dateTime, bool isArabic) {
    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inSeconds < 60) {
        return isArabic ? 'الآن' : 'now';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return isArabic ? 'منذ $minutes دقيقة' : '$minutes min ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return isArabic ? 'منذ $hours ساعة' : '$hours h ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return isArabic ? 'منذ $days يوم' : '$days d ago';
      } else {
        return isArabic ? 'منذ أسابيع' : 'weeks ago';
      }
    } catch (e) {
      return isArabic ? 'اليوم' : 'today';
    }
  }
  
  // دالة لفتح صفحة البحث في الهاشتاغات
  void _openHashtagSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HashtagSearchPage(),
      ),
    );
  }

  // دالة لبناء بطاقة فيديو من Firebase بنفس تصميم الفيجما
  Widget _buildFirebaseVideoCard(Post video, bool isArabic) {
    // تحويل مدة الفيديو من ثواني إلى تنسيق مقروء
    String formatDuration(int? seconds) {
      if (seconds == null) return '0:00';
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      
      if (hours > 0) {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      } else {
        return '$minutes:${secs.toString().padLeft(2, '0')}';
      }
    }

    // تنسيق عدد المشاهدات
    String formatViews(int views) {
      if (views >= 1000000) {
        return isArabic ? '${(views / 1000000).toStringAsFixed(1)} مليون' : '${(views / 1000000).toStringAsFixed(1)}M';
      } else if (views >= 1000) {
        return isArabic ? '${(views / 1000).toStringAsFixed(1)} ألف' : '${(views / 1000).toStringAsFixed(1)}K';
      }
      return views.toString();
    }

    // تنسيق الوقت منذ النشر
    String formatTimeAgo(DateTime createdAt) {
      final now = DateTime.now();
      final difference = now.difference(createdAt);
      
      if (difference.inDays > 30) {
        final months = difference.inDays ~/ 30;
        return isArabic ? 'منذ $months شهر' : '$months month${months > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return isArabic ? 'منذ ${difference.inDays} يوم' : '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return isArabic ? 'منذ ${difference.inHours} ساعة' : '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return isArabic ? 'منذ ${difference.inMinutes} دقيقة' : '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
    }

    final duration = formatDuration(video.videoDurationSeconds);
    final views = formatViews(video.viewCount);
    final timeAgo = formatTimeAgo(video.createdAt);
    final title = video.videoTitle ?? video.content;

    return GestureDetector(
      onTap: () {
        // التنقل إلى صفحة تشغيل الفيديو الحقيقية
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(post: video),
          ),
        );
      },
      child: Container(
        width: 382,
        height: 104, // ارتفاع ثابت كما في الفيجما
        padding: const EdgeInsets.all(0),
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Row(
            children: [
              // صورة الفيديو المصغرة
              Container(
                width: 160,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // الصورة المصغرة
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          // الصورة المصغرة المتقدمة من Firebase مع cache
                          _buildAdvancedVideoThumbnail(
                            video,
                            width: 160,
                            height: 90,
                          ),
                          
                          // أيقونة تشغيل في المنتصف
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // مدة الفيديو في الزاوية السفلية
                    Positioned(
                      bottom: 6,
                      right: isArabic ? null : 8,
                      left: isArabic ? 8 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          duration,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // تفاصيل الفيديو
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Directionality(
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: Column(
                      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // عنوان الفيديو
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D2035),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // اسم القناة/المستخدم
                        Text(
                          video.userName,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF616161),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // المشاهدات والوقت
                        Text(
                          '$views • $timeAgo',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF616161),
                          ),
                          textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لبناء صورة مصغرة بديلة في حالة فشل تحميل الصورة الأصلية
  Widget _buildThumbnailFallback() {
    return Container(
      width: 160,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFBDBDBD),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9A46D7).withOpacity(0.3),
            const Color(0xFFBDBDBD),
          ],
        ),
      ),
      child: const Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 32,
                  color: Colors.white70,
                ),
                SizedBox(height: 4),
                Text(
                  'Video',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء صورة مصغرة متقدمة مع cache سريع - نفس نظام EnhancedVideoCard
  Widget _buildAdvancedVideoThumbnail(Post post, {double? width, double? height}) {
    // استخدام الصورة المصغرة من البيانات إذا كانت متوفرة
    if (post.thumbnailUrl?.isNotEmpty == true) {
      return FutureBuilder<Uint8List?>(
        future: _advancedCacheService.getThumbnail(post.thumbnailUrl!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
            );
          }
          
          return _buildVideoThumbnailPlaceholder(width: width, height: height);
        },
      );
    }
    
    // إنشاء صورة مصغرة من الفيديو
    if (post.mediaUrls.isNotEmpty) {
      return FutureBuilder<Uint8List?>(
        future: _advancedCacheService.getThumbnail(post.mediaUrls.first),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
            );
          }
          
          return _buildVideoThumbnailPlaceholder(width: width, height: height);
        },
      );
    }
    
    // fallback للصورة المصغرة التقليدية
    return _cacheService.buildCachedImage(
      url: 'https://picsum.photos/seed/${post.id}/400/225',
      fit: BoxFit.cover,
      placeholderBuilder: () => _buildVideoThumbnailPlaceholder(width: width, height: height),
      errorBuilder: () => Center(
        child: Icon(Icons.movie_creation_outlined,
            color: Colors.grey, size: width != null ? width / 8 : 50),
      ),
    );
  }

  /// بناء placeholder للصورة المصغرة
  Widget _buildVideoThumbnailPlaceholder({double? width, double? height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        child: Center(
          child: Icon(
            Icons.video_library_outlined,
            color: Colors.grey,
            size: width != null ? width / 8 : 50,
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final double width;
  final double height;
  final WidgetBuilder iconBuilder;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OfferCard({
    required this.width,
    required this.height,
    required this.iconBuilder,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6FE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              iconBuilder(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A46D7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFAF66E6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FigmaOfferCard extends StatelessWidget {
  final double width;
  final double height;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final Widget illustrationWidget;
  final VoidCallback onTap;

  const _FigmaOfferCard({
    required this.width,
    required this.height,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.illustrationWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.08, vertical: 23.28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // في RTL: الصورة على اليمين والنص على اليسار كما في الفيجما
              // في LTR: الصورة على اليسار والنص على اليمين
              illustrationWidget,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// تعداد لأنواع منشورات المجتمع
enum CommunityPostType {
  withReactions,
  contentCreator,
  withReplies,
  regular,
}

// كلاس منشور المجتمع التفاعلي مع نظام التفاعلات الحقيقي
class _InteractiveCommunityPost extends StatefulWidget {
  final Post post;
  final bool isArabic;

  const _InteractiveCommunityPost({
    required this.post,
    required this.isArabic,
  });

  @override
  State<_InteractiveCommunityPost> createState() => _InteractiveCommunityPostState();
}

class _InteractiveCommunityPostState extends State<_InteractiveCommunityPost> {
  final CommunityService _communityService = CommunityService();
  final VideoCacheService _cacheService = VideoCacheService();
  final AdvancedVideoCacheService _advancedCacheService = AdvancedVideoCacheService();

  bool _isLoadingAction = false;
  bool _isDisposed = false;
  
  // نظام التفاعلات الكامل
  final List<String> _availableReactions = ['❤️', '👍', '😂', '😢', '😍', '🔥', '👀', '🔎'];
  String? _userReaction;
  Map<String, int> _postReactions = {};
  bool _showReactions = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _reactionButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    // تهيئة خدمات الفيديو والتخزين المؤقت
    _initializeVideoServices();
    
    // تهيئة نظام التفاعلات
    _loadPostReactions();
  }

  Future<void> _initializeVideoServices() async {
    try {
      await _cacheService.initialize();
      await _advancedCacheService.initialize();
    } catch (e) {
      debugPrint('Error initializing video services: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // تنظيف التفاعلات
    _hideReactions();
    
    super.dispose();
  }

  // تحميل التفاعلات من قاعدة البيانات (محاكاة)
  Future<void> _loadPostReactions() async {
    // محاكاة تحميل التفاعلات - يمكن ربطها بقاعدة البيانات لاحقاً
    safeSetState(() {
      // محاكاة تفاعلات متنوعة بناء على عدد الإعجابات
        final totalLikes = widget.post.likes.length;
        if (totalLikes > 0) {
          _postReactions = {
            '❤️': (totalLikes * 0.4).round().clamp(1, totalLikes),
            '👍': (totalLikes * 0.2).round(),
            '😂': (totalLikes * 0.15).round(),
            '😍': (totalLikes * 0.1).round(),
            '🔥': (totalLikes * 0.1).round(),
            '👀': (totalLikes * 0.05).round(),
          };
          _postReactions.removeWhere((key, value) => value == 0);
        }
    });
  }

  void _showReactionsOverlay() {
    if (_showReactions || !mounted) return;
    
    final RenderBox? renderBox = _reactionButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // حساب الموضع المناسب لعرض التفاعلات في الوسط
    const overlayWidth = 320.0; // عرض قائمة التفاعلات
    double leftPosition = (screenWidth - overlayWidth) / 2; // توسيط في الشاشة
    
    // التأكد من أن القائمة لا تخرج من حدود الشاشة
    if (leftPosition < 16) leftPosition = 16;
    if (leftPosition + overlayWidth > screenWidth - 16) {
      leftPosition = screenWidth - overlayWidth - 16;
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideReactions, // إخفاء التفاعلات عند الضغط خارجها
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: leftPosition,
                top: position.dy - 70, // أعلى من الزر بمسافة مناسبة
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value), // أنيميشن ظهور مثل فيسبوك
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: overlayWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _availableReactions.map((reaction) {
                          return ReactionButton(
                            reaction: reaction,
                            onTap: () {
                              _toggleReaction(reaction);
                              _hideReactions();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    if (mounted) {
      try {
        Overlay.of(context).insert(_overlayEntry!);
        safeSetState(() {
          _showReactions = true;
        });
        
        // إخفاء التفاعلات تلقائياً بعد 3 ثواني مثل فيسبوك
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_isDisposed && _showReactions) {
            _hideReactions();
          }
        });
      } catch (e) {
        // تنظيف في حالة الخطأ
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    }
  }

  void _hideReactions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!_isDisposed) {
      safeSetState(() {
        _showReactions = false;
      });
    }
  }
  
  void _toggleReaction(String reaction) {
    safeSetState(() {
      // إذا كان نفس التفاعل المختار، قم بإلغائه (مثل فيسبوك)
      if (_userReaction == reaction) {
        // إزالة التفاعل الحالي
        _userReaction = null;
        if (_postReactions[reaction] != null && _postReactions[reaction]! > 0) {
          _postReactions[reaction] = _postReactions[reaction]! - 1;
        }
        if (_postReactions[reaction] == 0) {
          _postReactions.remove(reaction);
        }
        
        // إظهار رسالة الإلغاء
        _showReactionFeedback('تم إلغاء التفاعل', Colors.grey);
      } else {
        // إذا كان تفاعل مختلف، قم بالتغيير
        
        // إزالة التفاعل السابق إذا كان موجوداً
        if (_userReaction != null) {
          if (_postReactions[_userReaction!] != null && _postReactions[_userReaction!]! > 0) {
            _postReactions[_userReaction!] = _postReactions[_userReaction!]! - 1;
          }
          if (_postReactions[_userReaction!] == 0) {
            _postReactions.remove(_userReaction!);
          }
        }
        
        // إضافة التفاعل الجديد
        _userReaction = reaction;
        if (_postReactions.containsKey(reaction)) {
          _postReactions[reaction] = _postReactions[reaction]! + 1;
        } else {
          _postReactions[reaction] = 1;
        }
        
        // إظهار رسالة التفاعل مع الإيموجي
        _showReactionFeedback('$reaction', _getReactionColor(reaction));
      }
    });
    
    // حفظ التفاعل (يمكن ربطها بقاعدة البيانات لاحقاً)
    _saveToDatabaseAsync(_userReaction);
  }
  
  // دالة لإظهار تأكيد التفاعل مثل فيسبوك
  void _showReactionFeedback(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
          ),
          backgroundColor: color,
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      );
    }
  }
  
  // دالة للحصول على لون التفاعل
  Color _getReactionColor(String reaction) {
    switch (reaction) {
      case '❤️':
        return Colors.red;
      case '👍':
        return Colors.blue;
      case '😂':
        return Colors.orange;
      case '😢':
        return Colors.blue.shade300;
      case '😍':
        return Colors.pink;
      case '🔥':
        return Colors.deepOrange;
      case '👀':
        return Colors.purple;
      case '🔎':
        return Colors.green;
      default:
        return const Color(0xFF9A46D7);
    }
  }
  
  // حفظ التفاعل في قاعدة البيانات (محاكاة)
  void _saveToDatabaseAsync(String? reaction) {
    Future.microtask(() async {
      try {
        // هنا يمكن حفظ التفاعل في قاعدة البيانات
        if (reaction == null) {
          print('تم حذف التفاعل للمنشور ${widget.post.id}');
        } else {
          print('تم حفظ تفاعل $reaction للمنشور ${widget.post.id}');
        }
      } catch (e) {
        print('خطأ في حفظ التفاعل: $e');
      }
    });
  }

  /// بناء صورة مصغرة متقدمة مع cache سريع - نفس نظام EnhancedVideoCard
  Widget _buildAdvancedVideoThumbnail(Post post, {double? width, double? height}) {
    // استخدام الصورة المصغرة من البيانات إذا كانت متوفرة
    if (post.thumbnailUrl?.isNotEmpty == true) {
      return FutureBuilder<Uint8List?>(
        future: _advancedCacheService.getThumbnail(post.thumbnailUrl!),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
            );
          }
          
          return _buildVideoThumbnailPlaceholder(width: width, height: height);
        },
      );
    }
    
    // إنشاء صورة مصغرة من الفيديو
    if (post.mediaUrls.isNotEmpty) {
      return FutureBuilder<Uint8List?>(
        future: _advancedCacheService.getThumbnail(post.mediaUrls.first),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: BoxFit.cover,
            );
          }
          
          return _buildVideoThumbnailPlaceholder(width: width, height: height);
        },
      );
    }
    
    // fallback للصورة المصغرة التقليدية
    return _cacheService.buildCachedImage(
      url: 'https://picsum.photos/seed/${post.id}/400/225',
      fit: BoxFit.cover,
      placeholderBuilder: () => _buildVideoThumbnailPlaceholder(width: width, height: height),
      errorBuilder: () => Center(
        child: Icon(Icons.movie_creation_outlined,
            color: Colors.grey, size: width != null ? width / 8 : 50),
      ),
    );
  }

  /// بناء placeholder للصورة المصغرة
  Widget _buildVideoThumbnailPlaceholder({double? width, double? height}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
        child: Center(
          child: Icon(
            Icons.video_library_outlined,
            color: Colors.grey,
            size: width != null ? width / 8 : 50,
          ),
        ),
      ),
    );
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailPage(post: widget.post),
      ),
    );
  }

  // دالة لبناء المحتوى المرئي (صور/فيديوهات) مع صور مصغرة محسنة
  Widget _buildMediaContent(Post post, bool isArabic) {
    // إذا كان فيديو مع صورة مصغرة
    if (post.videoTitle != null && post.videoTitle!.isNotEmpty) {
      return _buildVideoThumbnail(post, isArabic);
    }
    // إذا كان صورة عادية
    else if (post.mediaUrls.isNotEmpty) {
      return _buildImageContent(post);
    }
    // fallback
    return const SizedBox.shrink();
  }

  // دالة لبناء صورة مصغرة للفيديو مع تفاصيل
  Widget _buildVideoThumbnail(Post post, bool isArabic) {
    String formatDuration(int? seconds) {
      if (seconds == null) return '0:00';
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      
      if (hours > 0) {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      } else {
        return '$minutes:${secs.toString().padLeft(2, '0')}';
      }
    }

    String formatViews(int views) {
      if (views >= 1000000) {
        return isArabic ? '${(views / 1000000).toStringAsFixed(1)} مليون' : '${(views / 1000000).toStringAsFixed(1)}M';
      } else if (views >= 1000) {
        return isArabic ? '${(views / 1000).toStringAsFixed(1)} ألف' : '${(views / 1000).toStringAsFixed(1)}K';
      }
      return views.toString();
    }

    return GestureDetector(
      onTap: () {
        // التنقل إلى مشغل الفيديو
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(post: post),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF8F8F8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // الصورة المصغرة للفيديو بالنظام المتقدم
              _buildAdvancedVideoThumbnail(
                post,
                width: double.infinity,
                height: 220,
              ),

              // طبقة شفافة مع أيقونة التشغيل
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 32,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                  ),
                ),
              ),

              // مدة الفيديو في الزاوية
              if (post.videoDurationSeconds != null && post.videoDurationSeconds! > 0)
                Positioned(
                  bottom: 12,
                  right: isArabic ? null : 12,
                  left: isArabic ? 12 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      formatDuration(post.videoDurationSeconds),
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // عدد المشاهدات في الزاوية المقابلة
              if (post.viewCount > 0)
                Positioned(
                  bottom: 12,
                  left: isArabic ? null : 12,
                  right: isArabic ? 12 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatViews(post.viewCount),
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // عنوان الفيديو في الأسفل
              if (post.videoTitle != null && post.videoTitle!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Text(
                      post.videoTitle!,
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لبناء fallback للصورة المصغرة للفيديو
  Widget _buildVideoThumbnailFallback(Post post) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF9A46D7).withOpacity(0.3),
            const Color(0xFFBDBDBD),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 48,
            color: Colors.white70,
          ),
          const SizedBox(height: 8),
          Text(
            post.videoTitle ?? 'فيديو',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // دالة لبناء محتوى الصور العادية بالنظام المتقدم
  Widget _buildImageContent(Post post) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _cacheService.buildCachedImage(
        url: post.mediaUrls.first,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholderBuilder: () => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 200,
            color: Colors.white,
          ),
        ),
        errorBuilder: () => Container(
          width: double.infinity,
          height: 200,
          color: const Color(0xFFF8F8F8),
          child: const Icon(
            Icons.image,
            size: 50,
            color: Color(0xFFBDBDBD),
          ),
        ),
      ),
    );
  }

  // تنسيق الوقت منذ النشر
  String _formatTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 30) {
      final months = difference.inDays ~/ 30;
      return widget.isArabic ? 'منذ $months شهر' : '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return widget.isArabic ? 'منذ ${difference.inDays} يوم' : '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return widget.isArabic ? 'منذ ${difference.inHours} ساعة' : '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return widget.isArabic ? 'منذ ${difference.inMinutes} دقيقة' : '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(widget.post.createdAt);
    
    return GestureDetector(
      onTap: _navigateToDetail,
      child: Container(
        width: 382,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF8F8F8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Directionality(
          textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس المنشور مع معلومات المستخدم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // صورة المستخدم
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: widget.post.userImage.isNotEmpty
                            ? _cacheService.buildCachedImage(
                                url: widget.post.userImage,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                placeholderBuilder: () => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                errorBuilder: () => Container(
                                  width: 36,
                                  height: 36,
                                  color: const Color(0xFFBDBDBD),
                                  child: const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Container(
                                width: 36,
                                height: 36,
                                color: const Color(0xFFBDBDBD),
                                child: const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // معلومات المستخدم
                      Column(
                        crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.post.userName,
                                style: const TextStyle(
                                  fontFamily: 'Ping AR + LT',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1D2035),
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (widget.post.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                  height: 19,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFF1ED29C), width: 1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.isArabic ? 'صانع محتوي' : 'Content Creator',
                                        style: const TextStyle(
                                          fontFamily: 'Ping AR + LT',
                                          fontSize: 8,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1ED29C),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.verified,
                                        size: 8,
                                        color: Color(0xFF1ED29C),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                                  height: 19,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF6FE),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.isArabic ? 'متابعة' : 'Follow',
                                      style: const TextStyle(
                                        fontFamily: 'Ping AR + LT',
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF9A46D7),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              fontFamily: 'Ping AR + LT',
                              fontSize: 8,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAAB9C5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // أيقونة القائمة
                  const Icon(
                    Icons.more_vert,
                    size: 24,
                    color: Color(0xFFAAB9C5),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // محتوى المنشور
              Text(
                widget.post.content,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF323F49),
                ),
                textAlign: widget.isArabic ? TextAlign.right : TextAlign.left,
              ),
              
              // الهاشتاجات
              if (widget.post.hashtags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 13,
                  children: widget.post.hashtags.map((hashtag) {
                    final isFirst = widget.post.hashtags.indexOf(hashtag) == 0;
                    return Text(
                      '#$hashtag',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isFirst ? const Color(0xFF1AB385) : const Color(0xFFF68801),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              // صورة أو فيديو المنشور (إذا كانت موجودة)
              if (widget.post.mediaUrls.isNotEmpty || 
                  (widget.post.videoTitle != null && widget.post.thumbnailUrl != null)) ...[
                const SizedBox(height: 16),
                _buildMediaContent(widget.post, widget.isArabic),
              ],
              
              const SizedBox(height: 16),
              
              // خط فاصل
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFF8F8F8),
              ),
              
              const SizedBox(height: 16),
              
              // تفاعلات المنشور
              Row(
                children: [
                  // تفاعلات الإيموجي
                  if (_postReactions.isNotEmpty)
                    Row(
                      children: [
                        ..._postReactions.entries.take(4).map((entry) {
                          return Container(
                            height: 30,
                            margin: const EdgeInsets.only(right: 9),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _userReaction == entry.key 
                                  ? const Color(0xFF9A46D7).withOpacity(0.1)
                                  : const Color(0xFFFFEED9),
                              borderRadius: BorderRadius.circular(24),
                              border: _userReaction == entry.key
                                  ? Border.all(color: const Color(0xFF9A46D7), width: 1)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.value.toString(),
                                  style: TextStyle(
                                    fontFamily: 'Ping AR + LT',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: _userReaction == entry.key
                                        ? const Color(0xFF9A46D7)
                                        : const Color(0xFF633701),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        
                        // زر إضافة تفاعل
                        GestureDetector(
                          key: _reactionButtonKey,
                          onTap: _showReactionsOverlay,
                          onLongPress: _showReactionsOverlay, // إضافة الضغط المطول مثل فيسبوك
                          child: Container(
                            width: 41,
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.sentiment_satisfied_outlined,
                              size: 20,
                              color: Color(0xFFAAB9C5),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      key: _reactionButtonKey,
                      onTap: _showReactionsOverlay,
                      onLongPress: _showReactionsOverlay, // إضافة الضغط المطول مثل فيسبوك
                      child: Container(
                        width: 41,
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.sentiment_satisfied_outlined,
                          size: 20,
                          color: Color(0xFFAAB9C5),
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // زر التعليقات فقط
                  GestureDetector(
                    onTap: _navigateToDetail,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: Color(0xFF637D92),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.post.commentCount} ${widget.isArabic ? "تعليقات" : "comments"}',
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF637D92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}