import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/video/services/video_notification_service.dart';

/// حالة التحميل
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// معلومات التحميل
class DownloadInfo {
  final String id;
  final String postId;
  final String videoTitle;
  final String videoUrl;
  final String thumbnailUrl;
  final String filePath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  DownloadInfo({
    required this.id,
    required this.postId,
    required this.videoTitle,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.filePath,
    required this.totalBytes,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  double get progress {
    if (totalBytes == 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  String get progressText {
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  String get formattedSize {
    final size = totalBytes / (1024 * 1024);
    return '${size.toStringAsFixed(1)} MB';
  }

  String get qualityLabel {
    // استنتاج الجودة من اسم الملف أو حجمه
    if (filePath.contains('480p')) return '480p';
    if (filePath.contains('720p')) return '720p';
    if (filePath.contains('1080p')) return '1080p';
    
    // تقدير الجودة من الحجم
    final sizeMB = totalBytes / (1024 * 1024);
    if (sizeMB < 100) return '480p';
    if (sizeMB < 250) return '720p';
    return '1080p';
  }

  String get formattedFileSize {
    return formattedSize;
  }

  String get remainingTime {
    if (status != DownloadStatus.downloading) return '--';
    
    final remainingBytes = totalBytes - downloadedBytes;
    if (remainingBytes <= 0) return 'اكتمل';
    
    // تقدير زمني تقريبي (افتراض سرعة 1 MB/s)
    final remainingSeconds = remainingBytes / (1024 * 1024);
    
    if (remainingSeconds < 60) {
      return '${remainingSeconds.round()} ثانية';
    } else if (remainingSeconds < 3600) {
      return '${(remainingSeconds / 60).round()} دقيقة';
    } else {
      return '${(remainingSeconds / 3600).round()} ساعة';
    }
  }

  DownloadInfo copyWith({
    String? id,
    String? postId,
    String? videoTitle,
    String? videoUrl,
    String? thumbnailUrl,
    String? filePath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return DownloadInfo(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      videoTitle: videoTitle ?? this.videoTitle,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      filePath: filePath ?? this.filePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'videoTitle': videoTitle,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'filePath': filePath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'errorMessage': errorMessage,
    };
  }

  static DownloadInfo fromMap(Map<String, dynamic> map) {
    return DownloadInfo(
      id: map['id'] ?? '',
      postId: map['postId'] ?? '',
      videoTitle: map['videoTitle'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      filePath: map['filePath'] ?? '',
      totalBytes: map['totalBytes'] ?? 0,
      downloadedBytes: map['downloadedBytes'] ?? 0,
      status: DownloadStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => DownloadStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      errorMessage: map['errorMessage'],
    );
  }
}

/// خدمة تحميل الفيديوهات المبسطة
class VideoDownloadService {
  static final VideoDownloadService _instance = VideoDownloadService._internal();
  factory VideoDownloadService() => _instance;
  VideoDownloadService._internal();

  final Map<String, DownloadInfo> _downloads = {};
  final VideoNotificationService _notificationService = VideoNotificationService();
  final List<VoidCallback> _listeners = [];

  /// الحصول على جميع التحميلات
  List<DownloadInfo> get downloads => _downloads.values.toList();
  List<DownloadInfo> get allDownloads => _downloads.values.toList();

  /// الحصول على التحميلات النشطة
  List<DownloadInfo> get activeDownloads {
    return _downloads.values
        .where((d) => d.status == DownloadStatus.downloading)
        .toList();
  }

  /// الحصول على التحميلات المكتملة
  List<DownloadInfo> get completedDownloads {
    return _downloads.values
        .where((d) => d.status == DownloadStatus.completed)
        .toList();
  }

  /// تحميل فيديو
  Future<void> downloadVideo({
    required String postId,
    required String videoUrl,
    required String title,
    required String quality,
    String? thumbnailUrl,
  }) async {
    try {
      // محاكاة التحميل لأغراض العرض
      final downloadId = 'download_${DateTime.now().millisecondsSinceEpoch}';
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_$quality.mp4';
      
      // الحصول على مجلد التحميل
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      
      final filePath = '${downloadDir.path}/$fileName';

      // إنشاء معلومات التحميل
      final downloadInfo = DownloadInfo(
        id: downloadId,
        postId: postId,
        videoTitle: title,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl ?? '',
        filePath: filePath,
        totalBytes: 50 * 1024 * 1024, // 50 MB كمثال
        createdAt: DateTime.now(),
      );

      _downloads[downloadId] = downloadInfo;
      _notifyListeners();

      // إشعار بدء التحميل
      await _notificationService.showDownloadStarted(
        title: 'بدء التحميل',
        videoTitle: title,
      );

      // محاكاة عملية التحميل
      await _simulateDownload(downloadId, downloadInfo);

    } catch (e) {
      if (kDebugMode) {
        print('خطأ في التحميل: $e');
      }
      await _notificationService.showDownloadFailed(
        title: 'فشل التحميل',
        message: 'حدث خطأ أثناء تحميل الفيديو',
      );
    }
  }

  /// محاكاة عملية التحميل
  Future<void> _simulateDownload(String downloadId, DownloadInfo info) async {
    final steps = 20; // 20 خطوة للوصول إلى 100%
    
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 500)); // نصف ثانية لكل خطوة
      
      final downloadedBytes = (info.totalBytes * i / steps).round();
      final updatedInfo = info.copyWith(
        downloadedBytes: downloadedBytes,
        status: DownloadStatus.downloading,
      );
      
      _downloads[downloadId] = updatedInfo;
      _notifyListeners();

      // تحديث تقدم التحميل
      await _notificationService.updateDownloadProgress(
        downloadId,
        updatedInfo.progress * 100,
        info.videoTitle,
      );

      // التحقق من الإلغاء
      if (_downloads[downloadId]?.status == DownloadStatus.cancelled) {
        return;
      }
    }

    // إكمال التحميل
    final completedInfo = info.copyWith(
      downloadedBytes: info.totalBytes,
      status: DownloadStatus.completed,
      completedAt: DateTime.now(),
    );
    
    _downloads[downloadId] = completedInfo;
    _notifyListeners();

    // إشعار اكتمال التحميل
    await _notificationService.showDownloadCompleted(
      title: 'اكتمل التحميل',
      message: 'تم تحميل ${info.videoTitle} بنجاح',
      filePath: info.filePath,
    );

    // حفظ في Firestore
    await _saveDownloadToFirestore(completedInfo);
  }

  /// إيقاف التحميل مؤقتاً
  Future<void> pauseDownload(String downloadId) async {
    final info = _downloads[downloadId];
    if (info != null && info.status == DownloadStatus.downloading) {
      _downloads[downloadId] = info.copyWith(status: DownloadStatus.paused);
      _notifyListeners();
    }
  }

  /// استئناف التحميل
  Future<void> resumeDownload(String downloadId) async {
    final info = _downloads[downloadId];
    if (info != null && info.status == DownloadStatus.paused) {
      _downloads[downloadId] = info.copyWith(status: DownloadStatus.downloading);
      _notifyListeners();
      // محاكاة استكمال التحميل
      await _simulateDownload(downloadId, info);
    }
  }

  /// إلغاء التحميل
  Future<void> cancelDownload(String downloadId) async {
    final info = _downloads[downloadId];
    if (info != null) {
      _downloads[downloadId] = info.copyWith(status: DownloadStatus.cancelled);
      _notifyListeners();
      
      // حذف الملف المؤقت إن وجد
      final file = File(info.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  /// حذف التحميل المكتمل
  Future<void> deleteDownload(String downloadId) async {
    final info = _downloads[downloadId];
    if (info != null) {
      // حذف الملف
      final file = File(info.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // إزالة من القائمة
      _downloads.remove(downloadId);
      _notifyListeners();
    }
  }

  /// الحصول على معلومات التحميل
  DownloadInfo? getDownloadInfo(String downloadId) {
    return _downloads[downloadId];
  }

  /// حفظ التحميل في Firestore
  Future<void> _saveDownloadToFirestore(DownloadInfo downloadInfo) async {
    try {
      await FirebaseFirestore.instance
          .collection('downloads')
          .doc(downloadInfo.id)
          .set(downloadInfo.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في حفظ التحميل: $e');
      }
    }
  }

  /// تحميل التحميلات المحفوظة من Firestore
  Future<void> loadDownloadsFromFirestore(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('downloads')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        final downloadInfo = DownloadInfo.fromMap(doc.data());
        _downloads[downloadInfo.id] = downloadInfo;
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطأ في تحميل التحميلات: $e');
      }
    }
  }

  /// تنظيف التحميلات القديمة
  Future<void> cleanupOldDownloads() async {
    final now = DateTime.now();
    final toRemove = <String>[];

    for (final entry in _downloads.entries) {
      final info = entry.value;
      // حذف التحميلات الفاشلة أو الملغاة التي مر عليها أكثر من يوم
      if ((info.status == DownloadStatus.failed || info.status == DownloadStatus.cancelled) &&
          now.difference(info.createdAt).inDays > 1) {
        toRemove.add(entry.key);
        
        // حذف الملف إن وجد
        final file = File(info.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    for (final id in toRemove) {
      _downloads.remove(id);
    }
    _notifyListeners();
  }

  /// تهيئة الخدمة
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  /// إضافة مستمع للتغييرات
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// إزالة مستمع
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// إشعار المستمعين بالتغييرات
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// بدء تحميل جديد (من DownloadQualityDialog)
  Future<String> startDownload({
    required Post post,
    required double quality,
  }) async {
    final qualityLabel = quality == 0.5 ? '480p' : 
                        quality == 1.0 ? '720p' : '1080p';
    
    await downloadVideo(
      postId: post.id,
      videoUrl: post.mediaUrls.isNotEmpty 
          ? post.mediaUrls.first 
          : 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
      title: post.content,
      quality: qualityLabel,
      thumbnailUrl: '', // استخدام سلسلة فارغة للتجنب أخطاء التحميل
    );

    // إرجاع آخر downloadId تم إنشاؤه
    return _downloads.keys.last;
  }

  /// الحصول على إجمالي حجم التحميلات
  Future<int> getTotalDownloadSize() async {
    int totalSize = 0;
    for (final download in _downloads.values) {
      totalSize += download.totalBytes;
    }
    return totalSize;
  }
}
