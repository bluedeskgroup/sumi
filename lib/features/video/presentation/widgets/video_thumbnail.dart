import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;

  const VideoThumbnailWidget({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  Future<String?>? _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _generateThumbnail();
  }

  Future<String?> _generateThumbnail() async {
    try {
      // التحقق من أن URL صالح
      if (widget.videoUrl.isEmpty) {
        print('رابط الفيديو فارغ');
        return null;
      }
      
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.WEBP,
        quality: 25,
      );
      
      // التحقق من أن الملف تم إنشاؤه بنجاح
      if (thumbnailPath != null && await File(thumbnailPath).exists()) {
        return thumbnailPath;
      } else {
        print('فشل في إنشاء thumbnail للفيديو: ${widget.videoUrl}');
        return null;
      }
    } catch (e) {
      print('خطأ في إنشاء thumbnail: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(color: Colors.black),
          );
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            color: Colors.black,
            child: const Icon(Icons.error, color: Colors.white),
          );
        } else {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('خطأ في عرض thumbnail الفيديو: $error');
              return Container(
                color: Colors.black,
                child: const Icon(Icons.video_library, color: Colors.white),
              );
            },
          );
        }
      },
    );
  }
} 