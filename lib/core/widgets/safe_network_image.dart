import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackWidget();
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('Error loading image: $url - $error');
        return errorWidget ?? _buildFallbackWidget();
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildFallbackWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.person,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.6 : height! * 0.6)
            : 40,
        color: Colors.grey[600],
      ),
    );
  }
}

class SafeCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? child;
  final Color? backgroundColor;

  const SafeCircleAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: child ?? Icon(
          Icons.person,
          size: radius * 0.8,
          color: Colors.grey[600],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: backgroundColor,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) {
        debugPrint('Error loading avatar: $url - $error');
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey[300],
          child: child ?? Icon(
            Icons.person,
            size: radius * 0.8,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }
}

// Extension للتحقق من صحة الروابط
extension SafeImageUrl on String? {
  bool get isValidImageUrl {
    if (this == null || this!.isEmpty) return false;
    
    try {
      final uri = Uri.parse(this!);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
  
  String get safeImageUrl {
    if (isValidImageUrl) return this!;
    return ''; // إرجاع string فارغ للاستخدام مع SafeNetworkImage
  }
}
