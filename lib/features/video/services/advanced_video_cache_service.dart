import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as path;

/// خدمة cache متقدمة للفيديوهات والصور المصغرة
class AdvancedVideoCacheService {
  static final AdvancedVideoCacheService _instance = AdvancedVideoCacheService._internal();
  factory AdvancedVideoCacheService() => _instance;
  AdvancedVideoCacheService._internal();

  // Cache في الذاكرة
  final Map<String, Uint8List> _memoryThumbnailCache = {};
  final Map<String, String> _memoryVideoPathCache = {};
  final Map<String, VideoMetadata> _metadataCache = {};
  
  // حد أقصى لحجم الذاكرة (50 MB للصور المصغرة)
  static const int maxMemoryCacheSize = 50 * 1024 * 1024;
  int _currentMemoryUsage = 0;
  
  // مجلدات التخزين
  late Directory _thumbnailDir;
  late Directory _videoDir;
  late Directory _metadataDir;
  bool _initialized = false;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final cacheDir = await getTemporaryDirectory();
      
      _thumbnailDir = Directory(path.join(cacheDir.path, 'video_thumbnails'));
      _videoDir = Directory(path.join(cacheDir.path, 'cached_videos'));
      _metadataDir = Directory(path.join(cacheDir.path, 'video_metadata'));
      
      // إنشاء المجلدات إذا لم تكن موجودة
      await _thumbnailDir.create(recursive: true);
      await _videoDir.create(recursive: true);
      await _metadataDir.create(recursive: true);
      
      // تنظيف الملفات القديمة
      await _cleanOldFiles();
      
      _initialized = true;
      debugPrint('AdvancedVideoCacheService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AdvancedVideoCacheService: $e');
    }
  }

  /// تنظيف الملفات القديمة (أكثر من 7 أيام)
  Future<void> _cleanOldFiles() async {
    try {
      final now = DateTime.now();
      final maxAge = const Duration(days: 7);
      
      for (final dir in [_thumbnailDir, _videoDir, _metadataDir]) {
        if (await dir.exists()) {
          await for (final entity in dir.list()) {
            if (entity is File) {
              final stat = await entity.stat();
              if (now.difference(stat.modified) > maxAge) {
                await entity.delete();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning old cache files: $e');
    }
  }

  /// إنشاء مفتاح hash للURL
  String _generateKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// الحصول على الصورة المصغرة
  Future<Uint8List?> getThumbnail(String videoUrl, {bool forceRefresh = false}) async {
    await initialize();
    
    final key = _generateKey(videoUrl);
    
    // التحقق من cache الذاكرة أولاً
    if (!forceRefresh && _memoryThumbnailCache.containsKey(key)) {
      return _memoryThumbnailCache[key];
    }
    
    // التحقق من cache القرص
    final file = File(path.join(_thumbnailDir.path, '$key.jpg'));
    if (!forceRefresh && await file.exists()) {
      try {
        final data = await file.readAsBytes();
        _addToMemoryCache(key, data);
        return data;
      } catch (e) {
        debugPrint('Error reading thumbnail from cache: $e');
      }
    }
    
    // إنشاء صورة مصغرة جديدة
    return await _generateAndCacheThumbnail(videoUrl, key);
  }

  /// إنشاء وحفظ صورة مصغرة
  Future<Uint8List?> _generateAndCacheThumbnail(String videoUrl, String key) async {
    try {
      // تحديد موقع الإنشاء حسب نوع URL
      String? thumbnailPath;
      
      if (_isLocalFile(videoUrl)) {
        // فيديو محلي
        thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoUrl,
          thumbnailPath: _thumbnailDir.path,
          imageFormat: ImageFormat.JPEG,
          quality: 80,
          timeMs: 2000, // 2 ثانية من بداية الفيديو
        );
      } else {
        // فيديو من الإنترنت
        thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoUrl,
          thumbnailPath: _thumbnailDir.path,
          imageFormat: ImageFormat.JPEG,
          quality: 80,
          timeMs: 2000,
        );
      }
      
      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        if (await thumbnailFile.exists()) {
          final data = await thumbnailFile.readAsBytes();
          
          // حفظ بالمفتاح الصحيح
          final cachedFile = File(path.join(_thumbnailDir.path, '$key.jpg'));
          await cachedFile.writeAsBytes(data);
          
          // حذف الملف المؤقت إذا كان مختلف
          if (thumbnailPath != cachedFile.path) {
            await thumbnailFile.delete();
          }
          
          _addToMemoryCache(key, data);
          return data;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error generating thumbnail for $videoUrl: $e');
      return null;
    }
  }

  /// إضافة إلى cache الذاكرة مع إدارة الحجم
  void _addToMemoryCache(String key, Uint8List data) {
    final dataSize = data.lengthInBytes;
    
    // تنظيف الذاكرة إذا تجاوزت الحد الأقصى
    while (_currentMemoryUsage + dataSize > maxMemoryCacheSize && _memoryThumbnailCache.isNotEmpty) {
      final firstKey = _memoryThumbnailCache.keys.first;
      final removedData = _memoryThumbnailCache.remove(firstKey);
      if (removedData != null) {
        _currentMemoryUsage -= removedData.lengthInBytes;
      }
    }
    
    _memoryThumbnailCache[key] = data;
    _currentMemoryUsage += dataSize;
  }

  /// التحقق من كون الملف محلي
  bool _isLocalFile(String url) {
    return url.startsWith('/') || url.startsWith('file://');
  }

  /// cache الفيديو للمشاهدة السريعة
  Future<String?> cacheVideo(String videoUrl, {Function(double)? onProgress}) async {
    await initialize();
    
    if (_isLocalFile(videoUrl)) {
      return videoUrl; // الفيديو محلي بالفعل
    }
    
    final key = _generateKey(videoUrl);
    
    // التحقق من وجود الفيديو في cache
    if (_memoryVideoPathCache.containsKey(key)) {
      final cachedPath = _memoryVideoPathCache[key]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      }
    }
    
    // البحث في القرص
    final cachedFile = File(path.join(_videoDir.path, '$key.mp4'));
    if (await cachedFile.exists()) {
      _memoryVideoPathCache[key] = cachedFile.path;
      return cachedFile.path;
    }
    
    // تحميل وحفظ الفيديو
    return await _downloadAndCacheVideo(videoUrl, key, onProgress);
  }

  /// تحميل وحفظ الفيديو
  Future<String?> _downloadAndCacheVideo(String videoUrl, String key, Function(double)? onProgress) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(videoUrl));
      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        debugPrint('Failed to download video: ${response.statusCode}');
        return null;
      }
      
      final cachedFile = File(path.join(_videoDir.path, '$key.mp4'));
      final sink = cachedFile.openWrite();
      
      int downloaded = 0;
      final totalBytes = response.contentLength ?? 0;
      
      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          downloaded += chunk.length;
          
          if (totalBytes > 0 && onProgress != null) {
            onProgress(downloaded / totalBytes);
          }
        },
        onDone: () async {
          await sink.close();
          client.close();
        },
        onError: (error) async {
          await sink.close();
          client.close();
          debugPrint('Error downloading video: $error');
        },
      ).asFuture();
      
      if (await cachedFile.exists()) {
        _memoryVideoPathCache[key] = cachedFile.path;
        return cachedFile.path;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error caching video $videoUrl: $e');
      return null;
    }
  }

  /// حفظ metadata للفيديو
  Future<void> saveVideoMetadata(String videoUrl, VideoMetadata metadata) async {
    await initialize();
    
    final key = _generateKey(videoUrl);
    _metadataCache[key] = metadata;
    
    try {
      final file = File(path.join(_metadataDir.path, '$key.json'));
      await file.writeAsString(jsonEncode(metadata.toJson()));
    } catch (e) {
      debugPrint('Error saving video metadata: $e');
    }
  }

  /// الحصول على metadata للفيديو
  Future<VideoMetadata?> getVideoMetadata(String videoUrl) async {
    await initialize();
    
    final key = _generateKey(videoUrl);
    
    // التحقق من cache الذاكرة
    if (_metadataCache.containsKey(key)) {
      return _metadataCache[key];
    }
    
    // التحقق من القرص
    try {
      final file = File(path.join(_metadataDir.path, '$key.json'));
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final metadata = VideoMetadata.fromJson(jsonDecode(jsonStr));
        _metadataCache[key] = metadata;
        return metadata;
      }
    } catch (e) {
      debugPrint('Error loading video metadata: $e');
    }
    
    return null;
  }

  /// مسح cache معين
  Future<void> clearCache({bool thumbnails = true, bool videos = true, bool metadata = true}) async {
    await initialize();
    
    try {
      if (thumbnails) {
        _memoryThumbnailCache.clear();
        _currentMemoryUsage = 0;
        if (await _thumbnailDir.exists()) {
          await for (final file in _thumbnailDir.list()) {
            if (file is File) await file.delete();
          }
        }
      }
      
      if (videos) {
        _memoryVideoPathCache.clear();
        if (await _videoDir.exists()) {
          await for (final file in _videoDir.list()) {
            if (file is File) await file.delete();
          }
        }
      }
      
      if (metadata) {
        _metadataCache.clear();
        if (await _metadataDir.exists()) {
          await for (final file in _metadataDir.list()) {
            if (file is File) await file.delete();
          }
        }
      }
      
      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// الحصول على حجم cache
  Future<Map<String, int>> getCacheSize() async {
    await initialize();
    
    int thumbnailSize = 0;
    int videoSize = 0;
    int metadataSize = 0;
    
    try {
      // حساب حجم الصور المصغرة
      if (await _thumbnailDir.exists()) {
        await for (final file in _thumbnailDir.list()) {
          if (file is File) {
            final stat = await file.stat();
            thumbnailSize += stat.size;
          }
        }
      }
      
      // حساب حجم الفيديوهات
      if (await _videoDir.exists()) {
        await for (final file in _videoDir.list()) {
          if (file is File) {
            final stat = await file.stat();
            videoSize += stat.size;
          }
        }
      }
      
      // حساب حجم metadata
      if (await _metadataDir.exists()) {
        await for (final file in _metadataDir.list()) {
          if (file is File) {
            final stat = await file.stat();
            metadataSize += stat.size;
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
    }
    
    return {
      'thumbnails': thumbnailSize,
      'videos': videoSize,
      'metadata': metadataSize,
      'total': thumbnailSize + videoSize + metadataSize,
    };
  }

  /// تنسيق حجم البيانات
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// بدء cache فيديو في الخلفية
  void precacheVideo(String videoUrl) {
    cacheVideo(videoUrl).then((path) {
      if (path != null) {
        debugPrint('Video precached: $videoUrl');
      }
    }).catchError((e) {
      debugPrint('Error precaching video: $e');
    });
  }

  /// بدء cache صورة مصغرة في الخلفية
  void precacheThumbnail(String videoUrl) {
    getThumbnail(videoUrl).then((data) {
      if (data != null) {
        debugPrint('Thumbnail precached: $videoUrl');
      }
    }).catchError((e) {
      debugPrint('Error precaching thumbnail: $e');
    });
  }
}

/// نموذج metadata للفيديو
class VideoMetadata {
  final String url;
  final Duration? duration;
  final int? width;
  final int? height;
  final int? fileSize;
  final DateTime cachedAt;
  final Map<String, String>? qualities;

  VideoMetadata({
    required this.url,
    this.duration,
    this.width,
    this.height,
    this.fileSize,
    required this.cachedAt,
    this.qualities,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'duration': duration?.inMilliseconds,
    'width': width,
    'height': height,
    'fileSize': fileSize,
    'cachedAt': cachedAt.toIso8601String(),
    'qualities': qualities,
  };

  factory VideoMetadata.fromJson(Map<String, dynamic> json) => VideoMetadata(
    url: json['url'] ?? '',
    duration: json['duration'] != null ? Duration(milliseconds: json['duration']) : null,
    width: json['width'],
    height: json['height'],
    fileSize: json['fileSize'],
    cachedAt: DateTime.parse(json['cachedAt'] ?? DateTime.now().toIso8601String()),
    qualities: json['qualities'] != null ? Map<String, String>.from(json['qualities']) : null,
  );
}
