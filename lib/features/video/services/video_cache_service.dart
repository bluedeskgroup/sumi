import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// خدمة تخزين مؤقت للصور المصغرة والبيانات
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  static const String _cacheDirectoryName = 'video_cache';
  static const String _thumbnailsDirectoryName = 'thumbnails';
  static const Duration _cacheExpiryDuration = Duration(days: 7);
  
  late Directory _cacheDirectory;
  late Directory _thumbnailsDirectory;
  bool _isInitialized = false;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/$_cacheDirectoryName');
      _thumbnailsDirectory = Directory('${_cacheDirectory.path}/$_thumbnailsDirectoryName');
      
      // إنشاء المجلدات إذا لم تكن موجودة
      if (!await _cacheDirectory.exists()) {
        await _cacheDirectory.create(recursive: true);
      }
      if (!await _thumbnailsDirectory.exists()) {
        await _thumbnailsDirectory.create(recursive: true);
      }
      
      _isInitialized = true;
      
      // تنظيف الملفات المنتهية الصلاحية
      _cleanExpiredCache();
      
    } catch (e) {
      print('خطأ في تهيئة خدمة التخزين المؤقت: $e');
    }
  }

  /// توليد مفتاح فريد للملف
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// الحصول على مسار ملف الصورة المصغرة
  String _getThumbnailPath(String cacheKey) {
    return '${_thumbnailsDirectory.path}/$cacheKey.jpg';
  }

  /// الحصول على مسار ملف البيانات الوصفية
  String _getMetadataPath(String cacheKey) {
    return '${_cacheDirectory.path}/$cacheKey.meta.json';
  }

  /// حفظ صورة مصغرة في التخزين المؤقت
  Future<void> cacheThumbnail(String url, Uint8List imageData) async {
    if (!_isInitialized) await initialize();
    
    try {
      final cacheKey = _generateCacheKey(url);
      final thumbnailPath = _getThumbnailPath(cacheKey);
      final metadataPath = _getMetadataPath(cacheKey);
      
      // حفظ الصورة
      final imageFile = File(thumbnailPath);
      await imageFile.writeAsBytes(imageData);
      
      // حفظ البيانات الوصفية
      final metadata = {
        'url': url,
        'cachedAt': DateTime.now().toIso8601String(),
        'size': imageData.length,
      };
      
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(jsonEncode(metadata));
      
    } catch (e) {
      print('خطأ في حفظ الصورة المصغرة: $e');
    }
  }

  /// تحميل صورة مصغرة من التخزين المؤقت
  Future<Uint8List?> getCachedThumbnail(String url) async {
    if (!_isInitialized) await initialize();
    
    try {
      final cacheKey = _generateCacheKey(url);
      final thumbnailPath = _getThumbnailPath(cacheKey);
      final metadataPath = _getMetadataPath(cacheKey);
      
      final imageFile = File(thumbnailPath);
      final metadataFile = File(metadataPath);
      
      // تحقق من وجود الملفات
      if (!await imageFile.exists() || !await metadataFile.exists()) {
        return null;
      }
      
      // تحقق من صلاحية الملف
      final metadataContent = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataContent) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(metadata['cachedAt']);
      
      if (DateTime.now().difference(cachedAt) > _cacheExpiryDuration) {
        // الملف منتهي الصلاحية، احذفه
        await _deleteCachedFile(cacheKey);
        return null;
      }
      
      // الملف صالح، اقرأه
      return await imageFile.readAsBytes();
      
    } catch (e) {
      print('خطأ في قراءة الصورة المصغرة: $e');
      return null;
    }
  }

  /// تحميل وتخزين صورة مصغرة
  Future<Uint8List?> downloadAndCacheThumbnail(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;
        await cacheThumbnail(url, imageData);
        return imageData;
      }
      
      return null;
    } catch (e) {
      print('خطأ في تحميل الصورة: $e');
      return null;
    }
  }

  /// widget للصورة المخزنة مؤقتاً
  Widget buildCachedImage({
    required String url,
    required Widget Function() placeholderBuilder,
    required Widget Function() errorBuilder,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return FutureBuilder<Uint8List?>(
      future: _getImageData(url),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholderBuilder();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stack) => errorBuilder(),
          );
        }
        
        return errorBuilder();
      },
    );
  }

  /// الحصول على بيانات الصورة (من الكاش أو التحميل)
  Future<Uint8List?> _getImageData(String url) async {
    // التحقق من أن URL صالح ولا يشير إلى ملف فيديو
    if (url.isEmpty || 
        url.endsWith('.mp4') || 
        url.endsWith('.avi') || 
        url.endsWith('.mov') || 
        url.endsWith('.mkv') ||
        url.endsWith('.webm')) {
      print('URL غير صالح للصورة: $url');
      return null;
    }
    
    try {
      // أولاً، حاول الحصول على الصورة من الكاش
      Uint8List? cachedData = await getCachedThumbnail(url);
      
      if (cachedData != null) {
        return cachedData;
      }
      
      // إذا لم توجد في الكاش، حمّلها وخزّنها
      return await downloadAndCacheThumbnail(url);
    } catch (e) {
      print('خطأ في تحميل بيانات الصورة: $e');
      return null;
    }
  }

  /// حذف ملف مخزن مؤقتاً
  Future<void> _deleteCachedFile(String cacheKey) async {
    try {
      final thumbnailFile = File(_getThumbnailPath(cacheKey));
      final metadataFile = File(_getMetadataPath(cacheKey));
      
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
    } catch (e) {
      print('خطأ في حذف الملف المخزن مؤقتاً: $e');
    }
  }

  /// تنظيف الملفات المنتهية الصلاحية
  Future<void> _cleanExpiredCache() async {
    try {
      if (!await _cacheDirectory.exists()) return;
      
      final files = await _cacheDirectory.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.meta.json')) {
          try {
            final content = await file.readAsString();
            final metadata = jsonDecode(content) as Map<String, dynamic>;
            final cachedAt = DateTime.parse(metadata['cachedAt']);
            
            if (DateTime.now().difference(cachedAt) > _cacheExpiryDuration) {
              final cacheKey = file.path.split('/').last.replaceAll('.meta.json', '');
              await _deleteCachedFile(cacheKey);
            }
          } catch (e) {
            // ملف تالف، احذفه
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('خطأ في تنظيف التخزين المؤقت: $e');
    }
  }

  /// مسح كامل للتخزين المؤقت
  Future<void> clearCache() async {
    try {
      if (await _cacheDirectory.exists()) {
        await _cacheDirectory.delete(recursive: true);
        await _cacheDirectory.create(recursive: true);
        await _thumbnailsDirectory.create(recursive: true);
      }
    } catch (e) {
      print('خطأ في مسح التخزين المؤقت: $e');
    }
  }

  /// حساب حجم التخزين المؤقت
  Future<int> getCacheSize() async {
    try {
      if (!await _cacheDirectory.exists()) return 0;
      
      int totalSize = 0;
      final files = await _cacheDirectory.list(recursive: true).toList();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      print('خطأ في حساب حجم التخزين المؤقت: $e');
      return 0;
    }
  }

  /// تنسيق حجم الملف
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
