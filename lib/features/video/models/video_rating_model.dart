import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج تقييم الفيديو بالنجوم
class VideoRating {
  final String id;
  final String userId;
  final String postId;
  final int rating; // من 1 إلى 5 نجوم
  final DateTime createdAt;
  final DateTime? updatedAt;

  VideoRating({
    required this.id,
    required this.userId,
    required this.postId,
    required this.rating,
    required this.createdAt,
    this.updatedAt,
  });

  factory VideoRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VideoRating(
      id: doc.id,
      userId: data['userId'] ?? '',
      postId: data['postId'] ?? '',
      rating: data['rating'] ?? 1,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  VideoRating copyWith({
    String? id,
    String? userId,
    String? postId,
    int? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoRating(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// تحويل التقييم إلى النجوم المناسبة
  static List<bool> getStarsFromRating(int rating) {
    return List.generate(5, (index) => index < rating);
  }

  /// الحصول على لون النجمة حسب التقييم
  static String getRatingColor(int rating) {
    if (rating >= 4) return 'excellent'; // أخضر
    if (rating >= 3) return 'good';      // أصفر
    if (rating >= 2) return 'fair';      // برتقالي
    return 'poor';                       // أحمر
  }

  /// تحديد ما إذا كان التقييم إيجابي أم لا
  bool get isPositiveRating => rating >= 4;
}

/// إحصائيات تقييم الفيديو
class VideoRatingStats {
  final String postId;
  final int totalRatings;
  final double averageRating;
  final Map<int, int> ratingDistribution; // مثل {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  VideoRatingStats({
    required this.postId,
    required this.totalRatings,
    required this.averageRating,
    required this.ratingDistribution,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  factory VideoRatingStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final distributionData = data['ratingDistribution'] as Map<String, dynamic>? ?? {};
    final Map<int, int> distribution = {};
    distributionData.forEach((key, value) {
      final intKey = int.tryParse(key) ?? 1;
      distribution[intKey] = value as int? ?? 0;
    });
    
    return VideoRatingStats(
      postId: doc.id,
      totalRatings: data['totalRatings'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      ratingDistribution: distribution,
      fiveStarCount: data['fiveStarCount'] ?? 0,
      fourStarCount: data['fourStarCount'] ?? 0,
      threeStarCount: data['threeStarCount'] ?? 0,
      twoStarCount: data['twoStarCount'] ?? 0,
      oneStarCount: data['oneStarCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    // تحويل ratingDistribution إلى Map<String, int> للحفظ
    final Map<String, int> distributionForFirestore = {};
    ratingDistribution.forEach((key, value) {
      distributionForFirestore[key.toString()] = value;
    });

    return {
      'totalRatings': totalRatings,
      'averageRating': averageRating,
      'ratingDistribution': distributionForFirestore,
      'fiveStarCount': fiveStarCount,
      'fourStarCount': fourStarCount,
      'threeStarCount': threeStarCount,
      'twoStarCount': twoStarCount,
      'oneStarCount': oneStarCount,
    };
  }

  /// حساب نسبة التقييمات الإيجابية (4-5 نجوم)
  double get positiveRatingPercentage {
    if (totalRatings == 0) return 0.0;
    return ((fiveStarCount + fourStarCount) / totalRatings) * 100;
  }

  /// تحديد جودة الفيديو حسب التقييم
  String get qualityLevel {
    if (averageRating >= 4.5) return 'ممتاز';
    if (averageRating >= 4.0) return 'جيد جداً';
    if (averageRating >= 3.5) return 'جيد';
    if (averageRating >= 3.0) return 'مقبول';
    return 'ضعيف';
  }

  /// حساب درجة الثقة في التقييم (كلما زاد العدد زادت الثقة)
  double get confidenceScore {
    if (totalRatings == 0) return 0.0;
    if (totalRatings >= 100) return 1.0;
    if (totalRatings >= 50) return 0.8;
    if (totalRatings >= 20) return 0.6;
    if (totalRatings >= 10) return 0.4;
    return 0.2;
  }

  /// تنسيق التقييم للعرض
  String get formattedRating {
    return averageRating.toStringAsFixed(1);
  }
}
