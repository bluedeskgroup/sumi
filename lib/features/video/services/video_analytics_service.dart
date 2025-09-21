import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/video/models/video_analytics_model.dart';
import 'package:sumi/features/community/models/post_model.dart';

/// خدمة إحصائيات الفيديوهات
class VideoAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// تسجيل تفاعل مع الفيديو
  Future<void> recordEngagement({
    required String postId,
    required EngagementType type,
    required int videoPosition,
  }) async {
    if (currentUserId == null) return;

    try {
      final engagementPoint = EngagementPoint(
        timestamp: DateTime.now(),
        userId: currentUserId!,
        type: type,
        videoPosition: videoPosition,
      );

      // إضافة نقطة التفاعل
      await _firestore
          .collection('video_analytics')
          .doc(postId)
          .collection('engagements')
          .add(engagementPoint.toMap());

      // تحديث الإحصائيات الإجمالية
      await _updateVideoAnalytics(postId, type);
      
    } catch (e) {
      print('خطأ في تسجيل التفاعل: $e');
    }
  }

  /// تحديث إحصائيات الفيديو
  Future<void> _updateVideoAnalytics(String postId, EngagementType type) async {
    final analyticsRef = _firestore.collection('video_analytics').doc(postId);
    
    await _firestore.runTransaction((transaction) async {
      final analyticsDoc = await transaction.get(analyticsRef);
      
      Map<String, dynamic> updates = {};
      
      switch (type) {
        case EngagementType.view:
          updates['totalViews'] = FieldValue.increment(1);
          // إضافة المستخدم لقائمة المشاهدين الفريدين
          updates['uniqueViewers'] = FieldValue.arrayUnion([currentUserId!]);
          break;
        case EngagementType.completion:
          updates['totalCompletions'] = FieldValue.increment(1);
          break;
        case EngagementType.like:
        case EngagementType.comment:
        case EngagementType.share:
        case EngagementType.rate:
          // هذه التفاعلات تُحدث في خدمات أخرى
          break;
        default:
          break;
      }
      
      updates['lastUpdated'] = FieldValue.serverTimestamp();
      
      if (analyticsDoc.exists) {
        transaction.update(analyticsRef, updates);
      } else {
        // إنشاء مستند جديد
        final Map<String, Object> initialData = {
          'postId': postId,
          'totalViews': type == EngagementType.view ? 1 : 0,
          'uniqueViewers': type == EngagementType.view ? [currentUserId!] : [],
          'totalCompletions': type == EngagementType.completion ? 1 : 0,
          'completionRate': 0.0,
          'averageWatchTimeSeconds': 0,
          'totalWatchTimeSeconds': 0,
          'geographicData': <String, int>{},
          'deviceData': <String, int>{},
          'ageGroupData': <String, int>{},
          'dropOffPoints': <String, int>{},
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        
        // إضافة التحديثات
        updates.forEach((key, value) {
          initialData[key] = value;
        });
        
        transaction.set(analyticsRef, initialData);
      }
    });
  }

  /// الحصول على إحصائيات فيديو معين
  Future<VideoAnalytics?> getVideoAnalytics(String postId) async {
    try {
      final doc = await _firestore
          .collection('video_analytics')
          .doc(postId)
          .get();

      if (doc.exists) {
        return VideoAnalytics.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب إحصائيات الفيديو: $e');
      return null;
    }
  }

  /// الحصول على إحصائيات القناة
  Future<ChannelAnalytics?> getChannelAnalytics(String userId) async {
    try {
      final doc = await _firestore
          .collection('channel_analytics')
          .doc(userId)
          .get();

      if (doc.exists) {
        return ChannelAnalytics.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب إحصائيات القناة: $e');
      return null;
    }
  }

  /// حساب وتحديث إحصائيات متقدمة للفيديو
  Future<void> calculateAdvancedAnalytics(String postId) async {
    try {
      // جلب جميع نقاط التفاعل
      final engagementsSnapshot = await _firestore
          .collection('video_analytics')
          .doc(postId)
          .collection('engagements')
          .orderBy('timestamp')
          .get();

      final engagements = engagementsSnapshot.docs
          .map((doc) => EngagementPoint.fromMap(doc.data()))
          .toList();

      // جلب معلومات الفيديو
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final post = Post.fromFirestore(postDoc);
      final videoDuration = post.videoDurationSeconds ?? 0;

      // حساب الإحصائيات المتقدمة
      final analytics = _calculateVideoMetrics(engagements, videoDuration);
      
      // تحديث المستند
      await _firestore
          .collection('video_analytics')
          .doc(postId)
          .update(analytics);

    } catch (e) {
      print('خطأ في حساب الإحصائيات المتقدمة: $e');
    }
  }

  /// حساب مقاييس الفيديو
  Map<String, dynamic> _calculateVideoMetrics(
      List<EngagementPoint> engagements, int videoDuration) {
    
    final Map<String, dynamic> metrics = {};
    
    // حساب معدل الإكمال
    final viewEngagements = engagements
        .where((e) => e.type == EngagementType.view)
        .toList();
    final completionEngagements = engagements
        .where((e) => e.type == EngagementType.completion)
        .toList();
    
    final totalViews = viewEngagements.length;
    final totalCompletions = completionEngagements.length;
    
    metrics['completionRate'] = totalViews > 0 ? totalCompletions / totalViews : 0.0;
    
    // حساب متوسط وقت المشاهدة
    final watchTimes = <int>[];
    final userLastPositions = <String, int>{};
    
    for (final engagement in engagements) {
      if (engagement.type == EngagementType.view || 
          engagement.type == EngagementType.pause ||
          engagement.type == EngagementType.seek) {
        userLastPositions[engagement.userId] = engagement.videoPosition;
      } else if (engagement.type == EngagementType.completion) {
        watchTimes.add(videoDuration);
      }
    }
    
    // إضافة أوقات المشاهدة الجزئية
    watchTimes.addAll(userLastPositions.values);
    
    final averageWatchTime = watchTimes.isNotEmpty 
        ? watchTimes.reduce((a, b) => a + b) / watchTimes.length 
        : 0.0;
    
    metrics['averageWatchTimeSeconds'] = averageWatchTime.round();
    metrics['totalWatchTimeSeconds'] = watchTimes.isNotEmpty 
        ? watchTimes.reduce((a, b) => a + b) 
        : 0;
    
    // حساب نقاط التسرب
    final dropOffPoints = <int, int>{};
    for (final engagement in engagements) {
      if (engagement.type == EngagementType.pause) {
        final timeSlot = (engagement.videoPosition / 30).floor() * 30; // تجميع كل 30 ثانية
        dropOffPoints[timeSlot] = (dropOffPoints[timeSlot] ?? 0) + 1;
      }
    }
    
    // تحويل لصيغة Firestore
    final Map<String, int> dropOffForFirestore = {};
    dropOffPoints.forEach((key, value) {
      dropOffForFirestore[key.toString()] = value;
    });
    metrics['dropOffPoints'] = dropOffForFirestore;
    
    return metrics;
  }

  /// تحديث إحصائيات القناة
  Future<void> updateChannelAnalytics(String userId) async {
    try {
      // جلب جميع فيديوهات المستخدم
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'video')
          .get();

      final userPosts = postsSnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();

      if (userPosts.isEmpty) return;

      // حساب الإحصائيات الإجمالية
      int totalViews = 0;
      double totalRating = 0.0;
      int totalRatings = 0;
      Duration totalWatchTime = Duration.zero;
      
      for (final post in userPosts) {
        totalViews += post.viewCount;
        totalRating += post.averageRating * post.totalRatings;
        totalRatings += post.totalRatings;
        
        // جلب إحصائيات الفيديو
        final analytics = await getVideoAnalytics(post.id);
        if (analytics != null) {
          totalWatchTime += analytics.totalWatchTime;
        }
      }

      // جلب عدد المشتركين
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final subscribersCount = userDoc.exists 
          ? (userDoc.data()?['subscribers'] as List?)?.length ?? 0
          : 0;

      final averageRating = totalRatings > 0 ? totalRating / totalRatings : 0.0;
      
      // حساب معدل النمو (مثال بسيط)
      final growthRate = _calculateGrowthRate(userId);

      // إنشاء إحصائيات القناة
      final channelAnalytics = ChannelAnalytics(
        userId: userId,
        totalVideos: userPosts.length,
        totalViews: totalViews,
        totalSubscribers: subscribersCount,
        averageRating: averageRating,
        totalWatchTime: totalWatchTime,
        monthlyViews: await _getMonthlyViews(userId),
        topVideos: _getTopVideos(userPosts),
        growthRate: await growthRate,
        lastUpdated: DateTime.now(),
      );

      // حفظ الإحصائيات
      await _firestore
          .collection('channel_analytics')
          .doc(userId)
          .set(channelAnalytics.toMap());

    } catch (e) {
      print('خطأ في تحديث إحصائيات القناة: $e');
    }
  }

  /// حساب معدل النمو
  Future<double> _calculateGrowthRate(String userId) async {
    try {
      // مثال بسيط - يمكن تحسينه أكثر
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      
      final currentMonthSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastMonth))
          .get();
      
      final previousMonthSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .where('createdAt', 
              isLessThan: Timestamp.fromDate(lastMonth),
              isGreaterThan: Timestamp.fromDate(lastMonth.subtract(const Duration(days: 30))))
          .get();
      
      final currentCount = currentMonthSnapshot.docs.length;
      final previousCount = previousMonthSnapshot.docs.length;
      
      if (previousCount == 0) return currentCount > 0 ? 100.0 : 0.0;
      
      return ((currentCount - previousCount) / previousCount) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// الحصول على المشاهدات الشهرية
  Future<Map<String, int>> _getMonthlyViews(String userId) async {
    try {
      // مثال بسيط - في التطبيق الحقيقي ستحتاج لتخزين البيانات بشكل منفصل
      final monthlyViews = <String, int>{};
      final now = DateTime.now();
      
      for (int i = 0; i < 12; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        
        // هنا يجب جلب البيانات الفعلية من قاعدة البيانات
        monthlyViews[monthKey] = 0; // placeholder
      }
      
      return monthlyViews;
    } catch (e) {
      return {};
    }
  }

  /// الحصول على أفضل الفيديوهات
  List<String> _getTopVideos(List<Post> posts) {
    posts.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return posts.take(5).map((post) => post.id).toList();
  }

  /// الحصول على إحصائيات عامة للمنصة
  Future<Map<String, dynamic>> getPlatformAnalytics() async {
    try {
      final stats = <String, dynamic>{};
      
      // إجمالي الفيديوهات
      final videosSnapshot = await _firestore
          .collection('posts')
          .where('type', isEqualTo: 'video')
          .get();
      
      stats['totalVideos'] = videosSnapshot.docs.length;
      
      // إجمالي المشاهدات
      int totalViews = 0;
      for (final doc in videosSnapshot.docs) {
        final post = Post.fromFirestore(doc);
        totalViews += post.viewCount;
      }
      stats['totalViews'] = totalViews;
      
      // إجمالي المستخدمين
      final usersSnapshot = await _firestore.collection('users').get();
      stats['totalUsers'] = usersSnapshot.docs.length;
      
      // متوسط التقييم على المنصة
      double totalRating = 0.0;
      int totalRatings = 0;
      for (final doc in videosSnapshot.docs) {
        final post = Post.fromFirestore(doc);
        totalRating += post.averageRating * post.totalRatings;
        totalRatings += post.totalRatings;
      }
      stats['averageRating'] = totalRatings > 0 ? totalRating / totalRatings : 0.0;
      
      return stats;
    } catch (e) {
      print('خطأ في جلب إحصائيات المنصة: $e');
      return {};
    }
  }
}
