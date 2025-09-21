import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج لتتبع تقدم مشاهدة الفيديو للمستخدم
class WatchProgress {
  final String id;
  final String userId;
  final String postId;
  final int watchedSeconds; // كم ثانية شاهد المستخدم
  final int totalDurationSeconds; // إجمالي مدة الفيديو
  final double watchPercentage; // نسبة المشاهدة (0.0 - 1.0)
  final DateTime lastWatchedAt;
  final bool isCompleted; // هل شاهد المستخدم الفيديو كاملاً

  WatchProgress({
    required this.id,
    required this.userId,
    required this.postId,
    required this.watchedSeconds,
    required this.totalDurationSeconds,
    required this.watchPercentage,
    required this.lastWatchedAt,
    required this.isCompleted,
  });

  factory WatchProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return WatchProgress(
      id: doc.id,
      userId: data['userId'] ?? '',
      postId: data['postId'] ?? '',
      watchedSeconds: data['watchedSeconds'] ?? 0,
      totalDurationSeconds: data['totalDurationSeconds'] ?? 0,
      watchPercentage: (data['watchPercentage'] ?? 0.0).toDouble(),
      lastWatchedAt: (data['lastWatchedAt'] is Timestamp)
          ? (data['lastWatchedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'postId': postId,
      'watchedSeconds': watchedSeconds,
      'totalDurationSeconds': totalDurationSeconds,
      'watchPercentage': watchPercentage,
      'lastWatchedAt': Timestamp.fromDate(lastWatchedAt),
      'isCompleted': isCompleted,
    };
  }

  WatchProgress copyWith({
    String? id,
    String? userId,
    String? postId,
    int? watchedSeconds,
    int? totalDurationSeconds,
    double? watchPercentage,
    DateTime? lastWatchedAt,
    bool? isCompleted,
  }) {
    return WatchProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      postId: postId ?? this.postId,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      watchPercentage: watchPercentage ?? this.watchPercentage,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// حساب النسبة المئوية للمشاهدة
  static double calculateWatchPercentage(int watchedSeconds, int totalSeconds) {
    if (totalSeconds <= 0) return 0.0;
    return (watchedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  /// تحديد ما إذا كان الفيديو مكتملاً (شوهد أكثر من 90%)
  static bool isVideoCompleted(double watchPercentage) {
    return watchPercentage >= 0.9;
  }

  /// تنسيق الوقت المشاهد بصيغة MM:SS
  String get formattedWatchedTime {
    final duration = Duration(seconds: watchedSeconds);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// تنسيق النسبة المئوية
  String get formattedPercentage {
    return '${(watchPercentage * 100).toInt()}%';
  }
}
