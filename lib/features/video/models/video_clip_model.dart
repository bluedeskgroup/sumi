import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج مقطع الفيديو
class VideoClip {
  final String id;
  final String originalPostId;
  final String userId;
  final String userName;
  final String userImage;
  final String title;
  final String description;
  final Duration startTime;
  final Duration endTime;
  final Duration clipDuration;
  final String clipUrl;
  final String thumbnailUrl;
  final DateTime createdAt;
  final List<String> likes;
  final List<String> dislikes;
  final int viewCount;
  final int shareCount;
  final List<String> hashtags;
  final bool isPublic;
  final ClipCategory category;

  VideoClip({
    required this.id,
    required this.originalPostId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.clipDuration,
    required this.clipUrl,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.likes,
    required this.dislikes,
    required this.viewCount,
    required this.shareCount,
    required this.hashtags,
    required this.isPublic,
    required this.category,
  });

  factory VideoClip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VideoClip(
      id: doc.id,
      originalPostId: data['originalPostId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImage: data['userImage'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: Duration(seconds: data['startTimeSeconds'] ?? 0),
      endTime: Duration(seconds: data['endTimeSeconds'] ?? 0),
      clipDuration: Duration(seconds: data['clipDurationSeconds'] ?? 0),
      clipUrl: data['clipUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      hashtags: List<String>.from(data['hashtags'] ?? []),
      isPublic: data['isPublic'] ?? true,
      category: ClipCategory.values.firstWhere(
        (cat) => cat.name == data['category'],
        orElse: () => ClipCategory.other,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalPostId': originalPostId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'title': title,
      'description': description,
      'startTimeSeconds': startTime.inSeconds,
      'endTimeSeconds': endTime.inSeconds,
      'clipDurationSeconds': clipDuration.inSeconds,
      'clipUrl': clipUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'dislikes': dislikes,
      'viewCount': viewCount,
      'shareCount': shareCount,
      'hashtags': hashtags,
      'isPublic': isPublic,
      'category': category.name,
    };
  }

  /// تنسيق وقت البداية
  String get formattedStartTime {
    final minutes = startTime.inMinutes;
    final seconds = startTime.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// تنسيق وقت النهاية
  String get formattedEndTime {
    final minutes = endTime.inMinutes;
    final seconds = endTime.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// تنسيق مدة المقطع
  String get formattedDuration {
    final minutes = clipDuration.inMinutes;
    final seconds = clipDuration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// حساب نسبة الإعجاب
  double get likeRatio {
    final totalInteractions = likes.length + dislikes.length;
    if (totalInteractions == 0) return 0.0;
    return likes.length / totalInteractions;
  }

  VideoClip copyWith({
    String? id,
    String? originalPostId,
    String? userId,
    String? userName,
    String? userImage,
    String? title,
    String? description,
    Duration? startTime,
    Duration? endTime,
    Duration? clipDuration,
    String? clipUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    List<String>? likes,
    List<String>? dislikes,
    int? viewCount,
    int? shareCount,
    List<String>? hashtags,
    bool? isPublic,
    ClipCategory? category,
  }) {
    return VideoClip(
      id: id ?? this.id,
      originalPostId: originalPostId ?? this.originalPostId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      clipDuration: clipDuration ?? this.clipDuration,
      clipUrl: clipUrl ?? this.clipUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
      hashtags: hashtags ?? this.hashtags,
      isPublic: isPublic ?? this.isPublic,
      category: category ?? this.category,
    );
  }
}

/// فئات المقاطع
enum ClipCategory {
  highlight,  // أبرز اللحظات
  funny,      // مضحك
  educational, // تعليمي
  sports,     // رياضي
  music,      // موسيقي
  gaming,     // ألعاب
  reaction,   // ردود أفعال
  tutorial,   // شرح
  other,      // أخرى
}

/// امتداد لفئات المقاطع
extension ClipCategoryExtension on ClipCategory {
  String get displayName {
    switch (this) {
      case ClipCategory.highlight:
        return 'أبرز اللحظات';
      case ClipCategory.funny:
        return 'مضحك';
      case ClipCategory.educational:
        return 'تعليمي';
      case ClipCategory.sports:
        return 'رياضي';
      case ClipCategory.music:
        return 'موسيقي';
      case ClipCategory.gaming:
        return 'ألعاب';
      case ClipCategory.reaction:
        return 'ردود أفعال';
      case ClipCategory.tutorial:
        return 'شرح';
      case ClipCategory.other:
        return 'أخرى';
    }
  }

  String get emoji {
    switch (this) {
      case ClipCategory.highlight:
        return '⭐';
      case ClipCategory.funny:
        return '😂';
      case ClipCategory.educational:
        return '📚';
      case ClipCategory.sports:
        return '⚽';
      case ClipCategory.music:
        return '🎵';
      case ClipCategory.gaming:
        return '🎮';
      case ClipCategory.reaction:
        return '😱';
      case ClipCategory.tutorial:
        return '🔧';
      case ClipCategory.other:
        return '📝';
    }
  }
}

/// معلومات إنشاء المقطع
class ClipCreationInfo {
  final String originalPostId;
  final Duration videoDuration;
  final Duration startTime;
  final Duration endTime;
  final String title;
  final String description;
  final ClipCategory category;
  final List<String> hashtags;
  final bool isPublic;

  ClipCreationInfo({
    required this.originalPostId,
    required this.videoDuration,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    required this.category,
    required this.hashtags,
    required this.isPublic,
  });

  Duration get clipDuration => endTime - startTime;

  bool get isValid {
    return startTime < endTime &&
           endTime <= videoDuration &&
           clipDuration.inSeconds >= 5 && // الحد الأدنى 5 ثوانِ
           clipDuration.inSeconds <= 60 && // الحد الأقصى 60 ثانية
           title.trim().isNotEmpty;
  }

  String? get validationError {
    if (startTime >= endTime) {
      return 'وقت البداية يجب أن يكون قبل وقت النهاية';
    }
    if (endTime > videoDuration) {
      return 'وقت النهاية لا يمكن أن يتجاوز مدة الفيديو';
    }
    if (clipDuration.inSeconds < 5) {
      return 'مدة المقطع يجب أن تكون 5 ثوانِ على الأقل';
    }
    if (clipDuration.inSeconds > 60) {
      return 'مدة المقطع لا يمكن أن تتجاوز 60 ثانية';
    }
    if (title.trim().isEmpty) {
      return 'عنوان المقطع مطلوب';
    }
    return null;
  }
}
