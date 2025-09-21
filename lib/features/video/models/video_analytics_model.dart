import 'package:cloud_firestore/cloud_firestore.dart';

/// إحصائيات تفصيلية للفيديو
class VideoAnalytics {
  final String postId;
  final int totalViews;
  final int uniqueViewers;
  final int totalCompletions;
  final double completionRate; // نسبة الإكمال (0.0 - 1.0)
  final Duration averageWatchTime;
  final Duration totalWatchTime;
  final Map<String, int> geographicData; // البيانات الجغرافية
  final Map<String, int> deviceData; // أنواع الأجهزة
  final Map<String, int> ageGroupData; // الفئات العمرية
  final List<EngagementPoint> engagementTimeline; // نقاط التفاعل عبر الوقت
  final Map<int, int> dropOffPoints; // نقاط ترك المشاهدة
  final DateTime lastUpdated;

  VideoAnalytics({
    required this.postId,
    required this.totalViews,
    required this.uniqueViewers,
    required this.totalCompletions,
    required this.completionRate,
    required this.averageWatchTime,
    required this.totalWatchTime,
    required this.geographicData,
    required this.deviceData,
    required this.ageGroupData,
    required this.engagementTimeline,
    required this.dropOffPoints,
    required this.lastUpdated,
  });

  factory VideoAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // تحويل engagementTimeline
    final timelineData = data['engagementTimeline'] as List<dynamic>? ?? [];
    final engagementTimeline = timelineData
        .map((item) => EngagementPoint.fromMap(item as Map<String, dynamic>))
        .toList();
    
    // تحويل dropOffPoints
    final dropOffData = data['dropOffPoints'] as Map<String, dynamic>? ?? {};
    final Map<int, int> dropOffPoints = {};
    dropOffData.forEach((key, value) {
      final intKey = int.tryParse(key) ?? 0;
      dropOffPoints[intKey] = value as int? ?? 0;
    });
    
    return VideoAnalytics(
      postId: doc.id,
      totalViews: data['totalViews'] ?? 0,
      uniqueViewers: data['uniqueViewers'] ?? 0,
      totalCompletions: data['totalCompletions'] ?? 0,
      completionRate: (data['completionRate'] ?? 0.0).toDouble(),
      averageWatchTime: Duration(seconds: data['averageWatchTimeSeconds'] ?? 0),
      totalWatchTime: Duration(seconds: data['totalWatchTimeSeconds'] ?? 0),
      geographicData: Map<String, int>.from(data['geographicData'] ?? {}),
      deviceData: Map<String, int>.from(data['deviceData'] ?? {}),
      ageGroupData: Map<String, int>.from(data['ageGroupData'] ?? {}),
      engagementTimeline: engagementTimeline,
      dropOffPoints: dropOffPoints,
      lastUpdated: (data['lastUpdated'] is Timestamp)
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    // تحويل dropOffPoints
    final Map<String, int> dropOffForFirestore = {};
    dropOffPoints.forEach((key, value) {
      dropOffForFirestore[key.toString()] = value;
    });

    return {
      'totalViews': totalViews,
      'uniqueViewers': uniqueViewers,
      'totalCompletions': totalCompletions,
      'completionRate': completionRate,
      'averageWatchTimeSeconds': averageWatchTime.inSeconds,
      'totalWatchTimeSeconds': totalWatchTime.inSeconds,
      'geographicData': geographicData,
      'deviceData': deviceData,
      'ageGroupData': ageGroupData,
      'engagementTimeline': engagementTimeline.map((e) => e.toMap()).toList(),
      'dropOffPoints': dropOffForFirestore,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// حساب معدل المشاركة
  double get engagementRate {
    if (totalViews == 0) return 0.0;
    return (totalCompletions / totalViews) * 100;
  }

  /// الحصول على أكثر المناطق الجغرافية مشاهدة
  String get topGeography {
    if (geographicData.isEmpty) return 'غير محدد';
    return geographicData.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// الحصول على أكثر الأجهزة استخداماً
  String get topDevice {
    if (deviceData.isEmpty) return 'غير محدد';
    return deviceData.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// تحديد أفضل وقت للنشر بناءً على البيانات
  String get bestPublishTime {
    // هذا مثال بسيط، يمكن تحسينه أكثر
    final totalEngagement = engagementTimeline.length;
    if (totalEngagement == 0) return 'غير محدد';
    
    // تحليل أوقات التفاعل
    final hourMap = <int, int>{};
    for (final point in engagementTimeline) {
      final hour = point.timestamp.hour;
      hourMap[hour] = (hourMap[hour] ?? 0) + 1;
    }
    
    if (hourMap.isEmpty) return 'غير محدد';
    
    final bestHour = hourMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return '${bestHour.toString().padLeft(2, '0')}:00';
  }

  /// تحديد نقطة التسرب الأكثر شيوعاً
  int? get mostCommonDropOffPoint {
    if (dropOffPoints.isEmpty) return null;
    return dropOffPoints.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// تقييم الأداء العام للفيديو
  String get performanceGrade {
    double score = 0.0;
    
    // معدل الإكمال (40% من النتيجة)
    score += completionRate * 0.4;
    
    // معدل المشاركة (30% من النتيجة)
    final engagementScore = engagementRate / 100;
    score += engagementScore * 0.3;
    
    // نسبة المشاهدين الفريدين (20% من النتيجة)
    final uniqueViewerRatio = totalViews > 0 ? uniqueViewers / totalViews : 0.0;
    score += uniqueViewerRatio * 0.2;
    
    // معدل الوقت المشاهد (10% من النتيجة)
    final watchTimeRatio = averageWatchTime.inSeconds > 0 ? 
        (averageWatchTime.inSeconds / 300) : 0.0; // مقارنة مع 5 دقائق
    score += (watchTimeRatio.clamp(0.0, 1.0)) * 0.1;
    
    if (score >= 0.9) return 'ممتاز';
    if (score >= 0.8) return 'جيد جداً';
    if (score >= 0.6) return 'جيد';
    if (score >= 0.4) return 'مقبول';
    return 'ضعيف';
  }
}

/// نقطة تفاعل في الخط الزمني
class EngagementPoint {
  final DateTime timestamp;
  final String userId;
  final EngagementType type;
  final int videoPosition; // الموضع في الفيديو بالثواني

  EngagementPoint({
    required this.timestamp,
    required this.userId,
    required this.type,
    required this.videoPosition,
  });

  factory EngagementPoint.fromMap(Map<String, dynamic> map) {
    return EngagementPoint(
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      userId: map['userId'] ?? '',
      type: EngagementType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => EngagementType.view,
      ),
      videoPosition: map['videoPosition'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'type': type.name,
      'videoPosition': videoPosition,
    };
  }
}

/// أنواع التفاعل
enum EngagementType {
  view,
  like,
  comment,
  share,
  completion,
  pause,
  seek,
  rate,
}

/// إحصائيات إجمالية للقناة/المؤلف
class ChannelAnalytics {
  final String userId;
  final int totalVideos;
  final int totalViews;
  final int totalSubscribers;
  final double averageRating;
  final Duration totalWatchTime;
  final Map<String, int> monthlyViews; // المشاهدات الشهرية
  final List<String> topVideos; // أفضل الفيديوهات
  final double growthRate; // معدل النمو الشهري
  final DateTime lastUpdated;

  ChannelAnalytics({
    required this.userId,
    required this.totalVideos,
    required this.totalViews,
    required this.totalSubscribers,
    required this.averageRating,
    required this.totalWatchTime,
    required this.monthlyViews,
    required this.topVideos,
    required this.growthRate,
    required this.lastUpdated,
  });

  factory ChannelAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChannelAnalytics(
      userId: doc.id,
      totalVideos: data['totalVideos'] ?? 0,
      totalViews: data['totalViews'] ?? 0,
      totalSubscribers: data['totalSubscribers'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalWatchTime: Duration(seconds: data['totalWatchTimeSeconds'] ?? 0),
      monthlyViews: Map<String, int>.from(data['monthlyViews'] ?? {}),
      topVideos: List<String>.from(data['topVideos'] ?? []),
      growthRate: (data['growthRate'] ?? 0.0).toDouble(),
      lastUpdated: (data['lastUpdated'] is Timestamp)
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalVideos': totalVideos,
      'totalViews': totalViews,
      'totalSubscribers': totalSubscribers,
      'averageRating': averageRating,
      'totalWatchTimeSeconds': totalWatchTime.inSeconds,
      'monthlyViews': monthlyViews,
      'topVideos': topVideos,
      'growthRate': growthRate,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  /// معدل المشاهدات لكل فيديو
  double get averageViewsPerVideo {
    if (totalVideos == 0) return 0.0;
    return totalViews / totalVideos;
  }

  /// تحديد اتجاه النمو
  String get growthTrend {
    if (growthRate > 10) return 'نمو سريع';
    if (growthRate > 5) return 'نمو جيد';
    if (growthRate > 0) return 'نمو بطيء';
    if (growthRate > -5) return 'ثابت';
    return 'تراجع';
  }

  /// تنسيق إجمالي وقت المشاهدة
  String get formattedTotalWatchTime {
    final hours = totalWatchTime.inHours;
    final minutes = totalWatchTime.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
