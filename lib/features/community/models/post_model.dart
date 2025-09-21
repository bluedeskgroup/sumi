import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType {
  text,
  image,
  video,
}

// امتداد للتحويل من اسم النوع إلى PostType
extension PostTypeExtension on PostType {
  String get name {
    return toString().split('.').last;
  }
  
  static PostType fromString(String value) {
    return PostType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PostType.text,
    );
  }
}

class PostComment {
  final String id;
  final String userId;
  final String userImage;
  final String userName;
  final String content;
  final DateTime createdAt;
  final Map<String, List<String>> reactions;
  final List<String> likes;
  final List<PostComment> replies;

  PostComment({
    required this.id,
    required this.userId,
    required this.userImage,
    required this.userName,
    required this.content,
    required this.createdAt,
    required this.reactions,
    this.likes = const [],
    this.replies = const [],
  });

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // تحويل ديناميكي للـ reactions
    final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
    final Map<String, List<String>> reactions = {};
    reactionsData.forEach((key, value) {
      if (value is List) {
        reactions[key] = List<String>.from(value);
      }
    });

    // تحويل likes
    final likesData = data['likes'] as List<dynamic>? ?? [];
    final likes = List<String>.from(likesData);

    // تحويل replies
    final repliesData = data['replies'] as List<dynamic>? ?? [];
    final replies = repliesData.map((replyData) {
      if (replyData is Map<String, dynamic>) {
        return PostComment(
          id: replyData['id'] ?? '',
          userId: replyData['userId'] ?? '',
          userImage: replyData['userImage'] ?? '',
          userName: replyData['userName'] ?? '',
          content: replyData['content'] ?? '',
          createdAt: (replyData['createdAt'] is Timestamp)
              ? (replyData['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          reactions: {},
          likes: List<String>.from(replyData['likes'] ?? []),
          replies: [], // الردود لا تحتوي على ردود فرعية
        );
      }
      return PostComment(
        id: '',
        userId: '',
        userImage: '',
        userName: '',
        content: '',
        createdAt: DateTime.now(),
        reactions: {},
      );
    }).toList();

    return PostComment(
      id: doc.id,
      userId: data['userId'] ?? '',
      userImage: data['userImage'] ?? '',
      userName: data['userName'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      reactions: reactions,
      likes: likes,
      replies: replies,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userImage': userImage,
      'userName': userName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactions': reactions,
      'likes': likes,
      'replies': replies.map((reply) => reply.toMap()).toList(),
    };
  }

  PostComment copyWith({
    String? id,
    String? userId,
    String? userImage,
    String? userName,
    String? content,
    DateTime? createdAt,
    Map<String, List<String>>? reactions,
    List<String>? likes,
    List<PostComment>? replies,
  }) {
    return PostComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userImage: userImage ?? this.userImage,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
    );
  }
}

class Post {
  final String id;
  final String userId;
  final String userImage;
  final String userName;
  final String content;
  final List<String> mediaUrls;
  final PostType type;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> dislikes;
  final List<PostComment> comments;
  final int commentCount;
  final int viewCount;
  final int completionCount; // عدد المرات التي تم إكمال الفيديو فيها
  final double averageRating; // متوسط التقييم بالنجوم (0.0 - 5.0)
  final int totalRatings; // إجمالي عدد التقييمات
  final int? videoDurationSeconds; // مدة الفيديو بالثواني
  final bool isFeatured;
  final List<String> hashtags;
  final List<String> searchKeywords;
  
  // ميزات الفيديو المحسنة
  final String? videoTitle; // عنوان الفيديو (منفصل عن المحتوى)
  final String? videoDescription; // وصف الفيديو
  final String? thumbnailUrl; // رابط الصورة المصغرة
  final Map<String, String>? videoQualities; // جودات متعددة {quality: url}
  final String? originalVideoSize; // حجم الفيديو الأصلي
  final String? compressedVideoSize; // حجم الفيديو المضغوط

  Post({
    required this.id,
    required this.userId,
    required this.userImage,
    required this.userName,
    required this.content,
    required this.mediaUrls,
    required this.type,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    required this.comments,
    required this.commentCount,
    this.viewCount = 0,
    this.completionCount = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.videoDurationSeconds,
    this.isFeatured = false,
    this.hashtags = const [],
    this.searchKeywords = const [],
    // ميزات الفيديو المحسنة
    this.videoTitle,
    this.videoDescription,
    this.thumbnailUrl,
    this.videoQualities,
    this.originalVideoSize,
    this.compressedVideoSize,
  });

  factory Post.fromFirestore(DocumentSnapshot doc, {List<PostComment>? comments}) {
    final data = doc.data() as Map<String, dynamic>;
    
    // استخراج نوع المنشور بطريقة أكثر أمانًا
    PostType postType;
    try {
      final typeString = data['type'] as String? ?? 'text';
      postType = PostTypeExtension.fromString(typeString);
    } catch (e) {
      postType = PostType.text;
    }
    
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userImage: data['userImage'] ?? '',
      userName: data['userName'] ?? '',
      content: data['content'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      type: postType,
      createdAt: (data['createdAt'] is Timestamp) 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
      comments: comments ?? [],
      commentCount: data['commentCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      completionCount: data['completionCount'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      videoDurationSeconds: data['videoDurationSeconds'],
      isFeatured: data['isFeatured'] ?? false,
      hashtags: List<String>.from(data['hashtags'] ?? []),
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      // ميزات الفيديو المحسنة
      videoTitle: data['videoTitle'],
      videoDescription: data['videoDescription'],
      thumbnailUrl: data['thumbnailUrl'],
      videoQualities: data['videoQualities'] != null 
          ? Map<String, String>.from(data['videoQualities']) 
          : null,
      originalVideoSize: data['originalVideoSize'],
      compressedVideoSize: data['compressedVideoSize'],
    );
  }

  // استخراج الهاشتاجات من محتوى المنشور
  static List<String> extractHashtags(String content) {
    final hashtagRegex = RegExp(r'#(\w+)');
    final matches = hashtagRegex.allMatches(content);
    final hashtags = <String>[];
    
    for (var match in matches) {
      if (match.group(1) != null) {
        hashtags.add(match.group(1)!.toLowerCase());
      }
    }
    
    return hashtags;
  }

  // تنسيق المحتوى لعرض الهاشتاجات بشكل مميز
  String get formattedContent {
    String formattedText = content;
    for (var hashtag in hashtags) {
      formattedText = formattedText.replaceAll(
        RegExp('#$hashtag', caseSensitive: false), 
        '#$hashtag'
      );
    }
    return formattedText;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userImage': userImage,
      'userName': userName,
      'content': content,
      'mediaUrls': mediaUrls,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'dislikes': dislikes,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'completionCount': completionCount,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'videoDurationSeconds': videoDurationSeconds,
      'isFeatured': isFeatured,
      'hashtags': hashtags,
      'searchKeywords': searchKeywords,
      // ميزات الفيديو المحسنة
      'videoTitle': videoTitle,
      'videoDescription': videoDescription,
      'thumbnailUrl': thumbnailUrl,
      'videoQualities': videoQualities,
      'originalVideoSize': originalVideoSize,
      'compressedVideoSize': compressedVideoSize,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userImage,
    String? userName,
    String? content,
    List<String>? mediaUrls,
    PostType? type,
    DateTime? createdAt,
    List<String>? likes,
    List<String>? dislikes,
    List<PostComment>? comments,
    int? commentCount,
    int? viewCount,
    int? completionCount,
    double? averageRating,
    int? totalRatings,
    int? videoDurationSeconds,
    bool? isFeatured,
    List<String>? hashtags,
    List<String>? searchKeywords,
    // ميزات الفيديو المحسنة
    String? videoTitle,
    String? videoDescription,
    String? thumbnailUrl,
    Map<String, String>? videoQualities,
    String? originalVideoSize,
    String? compressedVideoSize,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userImage: userImage ?? this.userImage,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      comments: comments ?? this.comments,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      completionCount: completionCount ?? this.completionCount,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
      isFeatured: isFeatured ?? this.isFeatured,
      hashtags: hashtags ?? this.hashtags,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      // ميزات الفيديو المحسنة
      videoTitle: videoTitle ?? this.videoTitle,
      videoDescription: videoDescription ?? this.videoDescription,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoQualities: videoQualities ?? this.videoQualities,
      originalVideoSize: originalVideoSize ?? this.originalVideoSize,
      compressedVideoSize: compressedVideoSize ?? this.compressedVideoSize,
    );
  }

  /// تنسيق مدة الفيديو بصيغة MM:SS أو HH:MM:SS
  String get formattedDuration {
    if (videoDurationSeconds == null) return '00:00';
    
    final duration = Duration(seconds: videoDurationSeconds!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// تنسيق التقييم للعرض
  String get formattedRating {
    return averageRating.toStringAsFixed(1);
  }

  /// تحديد جودة المحتوى حسب التقييم
  String get qualityLevel {
    if (averageRating >= 4.5) return 'ممتاز';
    if (averageRating >= 4.0) return 'جيد جداً';
    if (averageRating >= 3.5) return 'جيد';
    if (averageRating >= 3.0) return 'مقبول';
    return 'ضعيف';
  }

  /// حساب نسبة الإعجاب (للتوافق مع النظام القديم)
  double get likePercentage {
    final totalInteractions = likes.length + dislikes.length;
    if (totalInteractions == 0) return 0.0;
    return (likes.length / totalInteractions) * 100;
  }

  /// حساب درجة شعبية المحتوى (algorithm score)
  double get popularityScore {
    // خوارزمية معقدة لحساب الشعبية
    final viewScore = viewCount * 1.0;
    final likeScore = likes.length * 5.0;
    final ratingScore = averageRating * totalRatings * 3.0;
    final completionScore = completionCount * 10.0;
    final commentScore = commentCount * 7.0;
    final hashtagScore = hashtags.length * 2.0; // إضافة درجة للهاشتاغات
    
    // حساب عدد الهاشتاجات النشطة (التي تستخدم في منشورات أخرى)
    final activeHashtagBonus = hashtags.length > 0 ? 10.0 : 0.0;
    
    // تطبيق وزن زمني (المحتوى الأحدث يحصل على وزن أكبر)
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    final timeWeight = daysSinceCreation <= 1 ? 3.0 :  // اليوم الأخير (الآن)
                      daysSinceCreation <= 3 ? 2.0 :   // آخر 3 أيام
                      daysSinceCreation <= 7 ? 1.5 :   // آخر أسبوع
                      daysSinceCreation <= 30 ? 1.2 :  // آخر 30 يومًا
                      1.0;                             // أكثر من 30 يومًا

    // حساب درجة التفاعل النسبي
    final interactionScore = (likes.length + commentCount * 2) / (daysSinceCreation + 1);
    
    return (viewScore + likeScore + ratingScore + completionScore + commentScore + hashtagScore + activeHashtagBonus) * timeWeight * (1 + interactionScore / 100);
  }

  /// تحديد ما إذا كان المحتوى عالي الجودة
  bool get isHighQuality {
    return averageRating >= 4.0 && totalRatings >= 10 && completionCount >= 5;
  }
} 