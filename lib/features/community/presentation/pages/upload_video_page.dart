import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

/// صفحة رفع الفيديو المتقدمة مع ميزات مثل يوتيوب
class UploadVideoPage extends StatefulWidget {
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> 
    with TickerProviderStateMixin {
  
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Animation Controllers
  late AnimationController _uploadAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _uploadAnimation;
  late Animation<double> _progressAnimation;
  
  // State variables
  File? _videoFile;
  File? _thumbnailFile;
  Uint8List? _thumbnailBytes;
  VideoPlayerController? _videoController;
  
  bool _isLoading = false;
  bool _isCompressing = false;
  bool _isGeneratingThumbnail = false;
  bool _customThumbnailSelected = false;
  
  double _compressionProgress = 0.0;
  String? _errorMessage;
  
  // Video info
  Duration? _videoDuration;
  String? _videoSize;
  String? _compressedSize;
  
  // Upload settings
  VideoQuality _selectedQuality = VideoQuality.MediumQuality;
  bool _generateMultipleQualities = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _uploadAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _uploadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uploadAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    _uploadAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  /// اختيار فيديو من المعرض
  Future<void> _pickVideo() async {
    try {
      final XFile? pickedVideo = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // الحد الأقصى 10 دقائق
      );
      
      if (pickedVideo != null) {
        final file = File(pickedVideo.path);
        await _initializeVideo(file);
      }
    } catch (e) {
      _setError('فشل في اختيار الفيديو: $e');
    }
  }

  /// تسجيل فيديو جديد
  Future<void> _recordVideo() async {
    try {
      final XFile? recordedVideo = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5), // 5 دقائق للتسجيل
      );
      
      if (recordedVideo != null) {
        final file = File(recordedVideo.path);
        await _initializeVideo(file);
      }
    } catch (e) {
      _setError('فشل في تسجيل الفيديو: $e');
    }
  }

  /// تهيئة الفيديو وتحليل معلوماته
  Future<void> _initializeVideo(File videoFile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // إنشاء مشغل الفيديو
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(videoFile);
      await _videoController!.initialize();
      
      // الحصول على معلومات الفيديو
      _videoDuration = _videoController!.value.duration;
      final videoStat = await videoFile.stat();
      _videoSize = _formatFileSize(videoStat.size);
      
      setState(() {
        _videoFile = videoFile;
      });
      
      // إنشاء صورة مصغرة تلقائياً
      await _generateAutoThumbnail();
      
    } catch (e) {
      _setError('فشل في تحليل الفيديو: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// إنشاء صورة مصغرة تلقائياً من الفيديو
  Future<void> _generateAutoThumbnail() async {
    if (_videoFile == null) return;
    
    setState(() {
      _isGeneratingThumbnail = true;
    });

    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: _videoFile!.path,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 80,
        timeMs: (_videoDuration?.inMilliseconds ?? 0) ~/ 4, // ربع مدة الفيديو
      );

      if (thumbnailPath != null) {
        _thumbnailFile = File(thumbnailPath);
        _thumbnailBytes = await _thumbnailFile!.readAsBytes();
        
        setState(() {
          _customThumbnailSelected = false;
        });
      }
    } catch (e) {
      print('فشل في إنشاء الصورة المصغرة: $e');
    } finally {
      setState(() {
        _isGeneratingThumbnail = false;
      });
    }
  }

  /// اختيار صورة مصغرة مخصصة
  Future<void> _pickCustomThumbnail() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedImage != null) {
        _thumbnailFile = File(pickedImage.path);
        _thumbnailBytes = await _thumbnailFile!.readAsBytes();
        
        setState(() {
          _customThumbnailSelected = true;
        });
      }
    } catch (e) {
      _setError('فشل في اختيار الصورة المصغرة: $e');
    }
  }

  /// ضغط الفيديو
  Future<File?> _compressVideo() async {
    if (_videoFile == null) return null;
    
    setState(() {
      _isCompressing = true;
      _compressionProgress = 0.0;
    });
    
    _progressAnimationController.forward();

    try {
      // إعداد ضغط الفيديو
      VideoCompress.setLogLevel(0);
      
      // مراقبة تقدم الضغط
      final subscription = VideoCompress.compressProgress$.subscribe((progress) {
        setState(() {
          _compressionProgress = progress / 100.0;
        });
      });

      // ضغط الفيديو
      final compressedVideo = await VideoCompress.compressVideo(
        _videoFile!.path,
        quality: _selectedQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      subscription.unsubscribe();

      if (compressedVideo != null) {
        final compressedFile = File(compressedVideo.path!);
        final compressedStat = await compressedFile.stat();
        _compressedSize = _formatFileSize(compressedStat.size);
        
        return compressedFile;
      }
      
      return null;
    } catch (e) {
      _setError('فشل في ضغط الفيديو: $e');
      return null;
    } finally {
      setState(() {
        _isCompressing = false;
      });
      _progressAnimationController.reset();
    }
  }

  /// رفع الفيديو
  Future<void> _uploadVideo() async {
    if (_videoFile == null) return;
    
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    
    if (title.isEmpty) {
      _setError('يرجى إدخال عنوان للفيديو');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    _uploadAnimationController.forward();

    try {
      // ضغط الفيديو
      File? videoToUpload = await _compressVideo();
      videoToUpload ??= _videoFile!;
      
      // إنشاء منشور الفيديو
      final List<File> mediaFiles = [videoToUpload];
      
      // إضافة الصورة المصغرة إذا كانت متوفرة
      if (_thumbnailFile != null) {
        mediaFiles.add(_thumbnailFile!);
      }
      
      // رفع المنشور
      await _communityService.createPost(
        content: '$title\n\n$description',
        media: mediaFiles,
        type: PostType.video,
        videoDurationSeconds: _videoDuration?.inSeconds,
        videoTitle: title,
        videoDescription: description,
        originalVideoSize: _videoSize,
        compressedVideoSize: _compressedSize,
      );

      if (mounted) {
        // عرض رسالة نجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم رفع الفيديو بنجاح! 🎉'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // العودة للصفحة السابقة
        Navigator.pop(context);
      }
      
    } catch (e) {
      _setError('فشل في رفع الفيديو: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _uploadAnimationController.reset();
    }
  }

  /// تعيين رسالة خطأ
  void _setError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  /// تنسيق حجم الملف
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// تنسيق مدة الفيديو
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '📹 رفع فيديو',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_videoFile != null && !_isLoading)
            TextButton.icon(
              onPressed: _uploadVideo,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('رفع'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
        ],
      ),
      body: _videoFile == null ? _buildVideoSelection() : _buildVideoEditor(),
    );
  }

  /// واجهة اختيار الفيديو
  Widget _buildVideoSelection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة رفع
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: Colors.red.shade200, width: 2),
              ),
              child: Icon(
                Icons.video_library_outlined,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // العنوان
            Text(
              'ارفع فيديوك الرائع! 🎬',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // الوصف
            Text(
              'شارك إبداعك مع المجتمع واجعل محتواك يصل للجميع',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // أزرار الاختيار
            Column(
              children: [
                // زر اختيار من المعرض
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickVideo,
                    icon: const Icon(Icons.photo_library),
                    label: const Text(
                      'اختر من المعرض',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // زر التسجيل
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _recordVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text(
                      'سجل فيديو جديد',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // معلومات إضافية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(height: 8),
                  Text(
                    'نصائح للحصول على أفضل جودة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• الحد الأقصى: 10 دقائق\n'
                    '• دقة مُحسنة: 720p أو أعلى\n'
                    '• إضاءة جيدة للوضوح\n'
                    '• صوت واضح وخالٍ من التشويش',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              const Text('جارٍ تحليل الفيديو...'),
            ],
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// واجهة تحرير الفيديو
  Widget _buildVideoEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معاينة الفيديو
          _buildVideoPreview(),
          
          const SizedBox(height: 24),
          
          // معلومات الفيديو
          _buildVideoInfo(),
          
          const SizedBox(height: 24),
          
          // حقول الإدخال
          _buildInputFields(),
          
          const SizedBox(height: 24),
          
          // الصورة المصغرة
          _buildThumbnailSection(),
          
          const SizedBox(height: 24),
          
          // إعدادات الجودة
          _buildQualitySettings(),
          
          const SizedBox(height: 24),
          
          // تقدم الضغط
          if (_isCompressing) _buildCompressionProgress(),
          
          // رسائل الخطأ
          if (_errorMessage != null) _buildErrorMessage(),
          
          const SizedBox(height: 100), // مساحة إضافية في الأسفل
        ],
      ),
    );
  }

  /// معاينة الفيديو
  Widget _buildVideoPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _videoController != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  /// معلومات الفيديو
  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'معلومات الفيديو',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'المدة',
                  _videoDuration != null ? _formatDuration(_videoDuration!) : '--',
                  Icons.schedule,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'الحجم الأصلي',
                  _videoSize ?? '--',
                  Icons.storage,
                ),
              ),
            ],
          ),
          if (_compressedSize != null)
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'الحجم المضغوط',
                    _compressedSize!,
                    Icons.compress,
                    color: Colors.green,
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// حقول الإدخال
  Widget _buildInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // حقل العنوان
        const Text(
          'عنوان الفيديو *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'أدخل عنواناً جذاباً للفيديو...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.title),
          ),
          maxLength: 100,
        ),
        
        const SizedBox(height: 16),
        
        // حقل الوصف
        const Text(
          'وصف الفيديو',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'أضف وصفاً مفصلاً عن محتوى الفيديو...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 4,
          maxLength: 500,
        ),
      ],
    );
  }

  /// قسم الصورة المصغرة
  Widget _buildThumbnailSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image, color: Colors.purple),
              const SizedBox(width: 8),
              const Text(
                'الصورة المصغرة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isGeneratingThumbnail)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (_thumbnailBytes != null) ...[
            // عرض الصورة المصغرة
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: MemoryImage(_thumbnailBytes!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  if (_customThumbnailSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'مخصصة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
          ],
          
          // أزرار الصورة المصغرة
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generateAutoThumbnail,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('تلقائية'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickCustomThumbnail,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('اختر صورة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// إعدادات الجودة
  Widget _buildQualitySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.high_quality, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'إعدادات الجودة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // جودة الضغط
          const Text(
            'جودة الضغط:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<VideoQuality>(
            value: _selectedQuality,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: VideoQuality.LowQuality,
                child: Text('جودة منخفضة (سريع - حجم صغير)'),
              ),
              DropdownMenuItem(
                value: VideoQuality.MediumQuality,
                child: Text('جودة متوسطة (متوازن)'),
              ),
              DropdownMenuItem(
                value: VideoQuality.HighestQuality,
                child: Text('جودة عالية (بطيء - حجم كبير)'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedQuality = value!;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // خيار الجودات المتعددة
          CheckboxListTile(
            title: const Text('إنشاء جودات متعددة للمشاهدة'),
            subtitle: const Text('يمكن للمشاهدين اختيار الجودة المناسبة'),
            value: _generateMultipleQualities,
            onChanged: (value) {
              setState(() {
                _generateMultipleQualities = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  /// تقدم الضغط
  Widget _buildCompressionProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.compress, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'جارٍ ضغط الفيديو...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _compressionProgress,
                backgroundColor: Colors.blue.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${(_compressionProgress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// رسالة الخطأ
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
