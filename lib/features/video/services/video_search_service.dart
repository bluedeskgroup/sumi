import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/core/helpers/search_helpers.dart';

/// معايير البحث المتقدم للفيديوهات
class VideoSearchCriteria {
  final String? query;
  final Duration? minDuration;
  final Duration? maxDuration;
  final double? minRating;
  final int? minViews;
  final DateTime? uploadedAfter;
  final DateTime? uploadedBefore;
  final String? authorId;
  final List<String>? hashtags;
  final VideoSortBy sortBy;
  final bool highQualityOnly;

  VideoSearchCriteria({
    this.query,
    this.minDuration,
    this.maxDuration,
    this.minRating,
    this.minViews,
    this.uploadedAfter,
    this.uploadedBefore,
    this.authorId,
    this.hashtags,
    this.sortBy = VideoSortBy.relevance,
    this.highQualityOnly = false,
  });

  VideoSearchCriteria copyWith({
    String? query,
    Duration? minDuration,
    Duration? maxDuration,
    double? minRating,
    int? minViews,
    DateTime? uploadedAfter,
    DateTime? uploadedBefore,
    String? authorId,
    List<String>? hashtags,
    VideoSortBy? sortBy,
    bool? highQualityOnly,
  }) {
    return VideoSearchCriteria(
      query: query ?? this.query,
      minDuration: minDuration ?? this.minDuration,
      maxDuration: maxDuration ?? this.maxDuration,
      minRating: minRating ?? this.minRating,
      minViews: minViews ?? this.minViews,
      uploadedAfter: uploadedAfter ?? this.uploadedAfter,
      uploadedBefore: uploadedBefore ?? this.uploadedBefore,
      authorId: authorId ?? this.authorId,
      hashtags: hashtags ?? this.hashtags,
      sortBy: sortBy ?? this.sortBy,
      highQualityOnly: highQualityOnly ?? this.highQualityOnly,
    );
  }
}

/// خيارات ترتيب نتائج البحث
enum VideoSortBy {
  relevance,
  newest,
  oldest,
  mostViewed,
  highestRated,
  duration,
  popularity,
}

/// نتائج البحث مع بيانات إضافية
class VideoSearchResult {
  final List<Post> videos;
  final int totalCount;
  final Duration searchTime;
  final Map<String, int> facets; // إحصائيات للفلترة

  VideoSearchResult({
    required this.videos,
    required this.totalCount,
    required this.searchTime,
    required this.facets,
  });
}

/// خدمة البحث المتقدم في الفيديوهات
class VideoSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// البحث المتقدم في الفيديوهات
  Future<VideoSearchResult> searchVideos({
    required VideoSearchCriteria criteria,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      Query query = _firestore.collection('posts').where('type', isEqualTo: 'video');
      
      // تطبيق الفلاتر
      query = _applyFilters(query, criteria);
      
      // تطبيق الترتيب
      query = _applySorting(query, criteria.sortBy);
      
      // تطبيق التصفح
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      query = query.limit(limit);
      
      final snapshot = await query.get();
      List<Post> videos = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      
      // فلترة إضافية على جانب العميل للمعايير المعقدة
      videos = _applyClientSideFilters(videos, criteria);
      
      // البحث النصي المتقدم إذا كان هناك نص للبحث
      if (criteria.query != null && criteria.query!.isNotEmpty) {
        videos = _performAdvancedTextSearch(videos, criteria.query!);
      }
      
      // حساب الإحصائيات
      final facets = await _calculateFacets(criteria);
      
      stopwatch.stop();
      
      return VideoSearchResult(
        videos: videos,
        totalCount: videos.length,
        searchTime: stopwatch.elapsed,
        facets: facets,
      );
      
    } catch (e) {
      stopwatch.stop();
      print('خطأ في البحث: $e');
      return VideoSearchResult(
        videos: [],
        totalCount: 0,
        searchTime: stopwatch.elapsed,
        facets: {},
      );
    }
  }

  /// تطبيق الفلاتر على الاستعلام
  Query _applyFilters(Query query, VideoSearchCriteria criteria) {
    // فلتر التقييم الأدنى
    if (criteria.minRating != null) {
      query = query.where('averageRating', isGreaterThanOrEqualTo: criteria.minRating);
    }
    
    // فلتر عدد المشاهدات الأدنى
    if (criteria.minViews != null) {
      query = query.where('viewCount', isGreaterThanOrEqualTo: criteria.minViews);
    }
    
    // فلتر تاريخ النشر
    if (criteria.uploadedAfter != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(criteria.uploadedAfter!));
    }
    
    if (criteria.uploadedBefore != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(criteria.uploadedBefore!));
    }
    
    // فلتر المؤلف
    if (criteria.authorId != null) {
      query = query.where('userId', isEqualTo: criteria.authorId);
    }
    
    // فلتر الهاشتاجات
    if (criteria.hashtags != null && criteria.hashtags!.isNotEmpty) {
      query = query.where('hashtags', arrayContainsAny: criteria.hashtags);
    }
    
    // فلتر الجودة العالية فقط
    if (criteria.highQualityOnly) {
      query = query.where('averageRating', isGreaterThanOrEqualTo: 4.0);
      query = query.where('totalRatings', isGreaterThanOrEqualTo: 10);
    }
    
    return query;
  }

  /// تطبيق الترتيب
  Query _applySorting(Query query, VideoSortBy sortBy) {
    switch (sortBy) {
      case VideoSortBy.newest:
        return query.orderBy('createdAt', descending: true);
      case VideoSortBy.oldest:
        return query.orderBy('createdAt', descending: false);
      case VideoSortBy.mostViewed:
        return query.orderBy('viewCount', descending: true);
      case VideoSortBy.highestRated:
        return query.orderBy('averageRating', descending: true);
      case VideoSortBy.duration:
        return query.orderBy('videoDurationSeconds', descending: true);
      case VideoSortBy.popularity:
        return query.orderBy('viewCount', descending: true);
      case VideoSortBy.relevance:
      default:
        return query.orderBy('createdAt', descending: true);
    }
  }

  /// فلترة إضافية على جانب العميل
  List<Post> _applyClientSideFilters(List<Post> videos, VideoSearchCriteria criteria) {
    return videos.where((video) {
      // فلتر مدة الفيديو
      if (criteria.minDuration != null && video.videoDurationSeconds != null) {
        if (video.videoDurationSeconds! < criteria.minDuration!.inSeconds) {
          return false;
        }
      }
      
      if (criteria.maxDuration != null && video.videoDurationSeconds != null) {
        if (video.videoDurationSeconds! > criteria.maxDuration!.inSeconds) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  /// البحث النصي المتقدم
  List<Post> _performAdvancedTextSearch(List<Post> videos, String query) {
    final searchTerms = query.toLowerCase().split(' ').where((term) => term.isNotEmpty).toList();
    
    // نسبة التطابق لكل فيديو
    final scoredVideos = videos.map((video) {
      double score = 0.0;
      
      // البحث في العنوان (وزن عالي)
      final contentLower = video.content.toLowerCase();
      for (final term in searchTerms) {
        if (contentLower.contains(term)) {
          score += 3.0;
          // نقاط إضافية للتطابق الدقيق
          if (contentLower.startsWith(term)) {
            score += 2.0;
          }
        }
      }
      
      // البحث في اسم المؤلف (وزن متوسط)
      final userNameLower = video.userName.toLowerCase();
      for (final term in searchTerms) {
        if (userNameLower.contains(term)) {
          score += 1.5;
        }
      }
      
      // البحث في الهاشتاجات (وزن متوسط)
      for (final hashtag in video.hashtags) {
        for (final term in searchTerms) {
          if (hashtag.toLowerCase().contains(term)) {
            score += 2.0;
          }
        }
      }
      
      // البحث في الكلمات المفتاحية (وزن منخفض)
      for (final keyword in video.searchKeywords) {
        for (final term in searchTerms) {
          if (keyword.toLowerCase().contains(term)) {
            score += 1.0;
          }
        }
      }
      
      return {'video': video, 'score': score};
    }).where((item) => item['score'] as double > 0).toList();
    
    // ترتيب حسب النتيجة مع مراعاة عوامل أخرى
    scoredVideos.sort((a, b) {
      final scoreA = a['score'] as double;
      final scoreB = b['score'] as double;
      
      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA);
      }
      
      // في حالة التعادل، رتب حسب الشعبية
      final videoA = a['video'] as Post;
      final videoB = b['video'] as Post;
      return videoB.popularityScore.compareTo(videoA.popularityScore);
    });
    
    return scoredVideos.map((item) => item['video'] as Post).toList();
  }

  /// حساب الإحصائيات للفلاتر
  Future<Map<String, int>> _calculateFacets(VideoSearchCriteria criteria) async {
    try {
      // هذا مثال بسيط، يمكن تحسينه أكثر
      final snapshot = await _firestore
          .collection('posts')
          .where('type', isEqualTo: 'video')
          .get();
      
      final videos = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      
      final facets = <String, int>{};
      
      // إحصائيات التقييمات
      int highRated = 0, mediumRated = 0, lowRated = 0;
      int shortVideos = 0, mediumVideos = 0, longVideos = 0;
      int recentVideos = 0, oldVideos = 0;
      
      final now = DateTime.now();
      
      for (final video in videos) {
        // تصنيف التقييمات
        if (video.averageRating >= 4.0) {
          highRated++;
        } else if (video.averageRating >= 3.0) {
          mediumRated++;
        } else {
          lowRated++;
        }
        
        // تصنيف المدة
        if (video.videoDurationSeconds != null) {
          if (video.videoDurationSeconds! < 300) { // أقل من 5 دقائق
            shortVideos++;
          } else if (video.videoDurationSeconds! < 1800) { // أقل من 30 دقيقة
            mediumVideos++;
          } else {
            longVideos++;
          }
        }
        
        // تصنيف زمني
        if (now.difference(video.createdAt).inDays <= 30) {
          recentVideos++;
        } else {
          oldVideos++;
        }
      }
      
      facets['high_rated'] = highRated;
      facets['medium_rated'] = mediumRated;
      facets['low_rated'] = lowRated;
      facets['short_videos'] = shortVideos;
      facets['medium_videos'] = mediumVideos;
      facets['long_videos'] = longVideos;
      facets['recent_videos'] = recentVideos;
      facets['old_videos'] = oldVideos;
      
      return facets;
    } catch (e) {
      return {};
    }
  }

  /// اقتراحات البحث التلقائي
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    if (partialQuery.length < 2) return [];
    
    try {
      final suggestions = <String>[];
      
      // البحث في أسماء المستخدمين
      final usersSnapshot = await _firestore
          .collection('users')
          .where('searchKeywords', arrayContains: partialQuery.toLowerCase())
          .limit(5)
          .get();
      
      for (final doc in usersSnapshot.docs) {
        final userName = doc.data()['userName'] as String?;
        if (userName != null) {
          suggestions.add(userName);
        }
      }
      
      // البحث في الهاشتاجات الشائعة
      final hashtagsSnapshot = await _firestore
          .collection('posts')
          .where('type', isEqualTo: 'video')
          .where('hashtags', arrayContains: partialQuery.toLowerCase())
          .limit(5)
          .get();
      
      final Set<String> hashtags = {};
      for (final doc in hashtagsSnapshot.docs) {
        final postHashtags = List<String>.from(doc.data()['hashtags'] ?? []);
        for (final hashtag in postHashtags) {
          if (hashtag.toLowerCase().contains(partialQuery.toLowerCase())) {
            hashtags.add('#$hashtag');
          }
        }
      }
      
      suggestions.addAll(hashtags.take(3));
      
      return suggestions.take(8).toList();
    } catch (e) {
      return [];
    }
  }

  /// فلاتر سريعة مُعرفة مسبقاً
  static List<VideoSearchCriteria> getQuickFilters() {
    return [
      VideoSearchCriteria(
        sortBy: VideoSortBy.newest,
      ),
      VideoSearchCriteria(
        minRating: 4.0,
        highQualityOnly: true,
      ),
      VideoSearchCriteria(
        maxDuration: Duration(minutes: 5),
        sortBy: VideoSortBy.mostViewed,
      ),
      VideoSearchCriteria(
        uploadedAfter: DateTime.now().subtract(Duration(days: 7)),
        sortBy: VideoSortBy.newest,
      ),
      VideoSearchCriteria(
        minViews: 1000,
        sortBy: VideoSortBy.popularity,
      ),
    ];
  }
}
