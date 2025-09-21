import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageErrorHandler {
  // قائمة الروابط المحظورة أو التي تسبب مشاكل
  static final List<String> _blacklistedDomains = [
    'i.pravatar.cc',
    'avatar.iran.liara.run', 
    'robohash.org',
    'ui-avatars.com',
  ];

  // قائمة الروابط الافتراضية الآمنة
  static final List<String> _fallbackUrls = [
    'https://www.gravatar.com/avatar/?d=mp&s=200',
    'https://via.placeholder.com/200x200/CCCCCC/666666?text=User',
  ];

  /// تحقق من صحة رابط الصورة
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      
      // تحقق من الـ scheme
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return false;
      }
      
      // تحقق من وجود authority
      if (!uri.hasAuthority) return false;
      
      // تحقق من الدومينات المحظورة
      final host = uri.host.toLowerCase();
      for (final blacklistedDomain in _blacklistedDomains) {
        if (host.contains(blacklistedDomain)) {
          debugPrint('Blocked image domain: $host');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Invalid image URL: $url - Error: $e');
      return false;
    }
  }

  /// الحصول على رابط صورة آمن
  static String getSafeImageUrl(String? url) {
    if (isValidImageUrl(url)) {
      return url!;
    }
    
    // إرجاع الرابط الافتراضي الأول
    return _fallbackUrls.first;
  }

  /// إنشاء widget للصورة الافتراضية
  static Widget buildDefaultAvatar({
    double size = 40,
    Color? backgroundColor,
    Color? iconColor,
    IconData icon = Icons.person,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[300],
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            (backgroundColor ?? Colors.grey[300]!).withOpacity(0.8),
            (backgroundColor ?? Colors.grey[400]!),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.6,
        color: iconColor ?? Colors.grey[600],
      ),
    );
  }

  /// widget لعرض الخطأ في الصورة
  static Widget buildImageError({
    double? width,
    double? height,
    String? errorMessage,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 32,
            color: Colors.grey[400],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// تسجيل أخطاء الصور للمطورين
  static void logImageError(String url, dynamic error) {
    if (kDebugMode) {
      debugPrint('═══ IMAGE ERROR ═══');
      debugPrint('URL: $url');
      debugPrint('Error: $error');
      debugPrint('Time: ${DateTime.now()}');
      debugPrint('═══════════════════');
    }
  }

  /// تنظيف وإصلاح رابط الصورة
  static String? cleanImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // إزالة المسافات الزائدة
    url = url.trim();
    
    // إصلاح الروابط النسبية
    if (url.startsWith('//')) {
      url = 'https:$url';
    }
    
    // إصلاح الروابط بدون بروتوكول
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('www.')) {
        url = 'https://$url';
      }
    }
    
    return isValidImageUrl(url) ? url : null;
  }

  /// معالج شامل لأخطاء الصور
  static void handleGlobalImageErrors() {
    // يمكن استخدامه لتسجيل جميع أخطاء الصور في التطبيق
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('NetworkImageLoadException') ||
          details.exception.toString().contains('HandshakeException') ||
          details.exception.toString().contains('SocketException')) {
        logImageError('Global Error', details.exception);
        // لا نريد إيقاف التطبيق لأخطاء الصور
        return;
      }
      
      // استدعاء معالج الأخطاء الافتراضي للأخطاء الأخرى
      FlutterError.presentError(details);
    };
  }
}
