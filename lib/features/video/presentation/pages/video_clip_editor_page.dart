import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/video/models/video_clip_model.dart';
import 'package:sumi/features/video/services/video_clip_service.dart';

/// صفحة محرر مقاطع الفيديو
class VideoClipEditorPage extends StatefulWidget {
  final Post originalPost;

  const VideoClipEditorPage({super.key, required this.originalPost});

  @override
  State<VideoClipEditorPage> createState() => _VideoClipEditorPageState();
}

class _VideoClipEditorPageState extends State<VideoClipEditorPage>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  late AnimationController _previewAnimationController;
  
  final VideoClipService _clipService = VideoClipService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  Duration _videoDuration = Duration.zero;
  Duration _startTime = Duration.zero;
  Duration _endTime = Duration.zero;
  Duration _currentPosition = Duration.zero;
  
  bool _isLoading = true;
  bool _isPlaying = false;
  bool _isCreatingClip = false;
  bool _isPublic = true;
  
  ClipCategory _selectedCategory = ClipCategory.highlight;
  List<String> _hashtags = [];
  
  // متغيرات التحكم في الشريط
  double _startThumbPosition = 0.0;
  double _endThumbPosition = 1.0;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;

  @override
  void initState() {
    super.initState();
    _previewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _previewAnimationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      final videoUrl = widget.originalPost.mediaUrls.first;
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      
      await _videoController!.initialize();
      
      setState(() {
        _videoDuration = _videoController!.value.duration;
        _endTime = _videoDuration;
        _isLoading = false;
      });
      
      // مراقبة موضع التشغيل
      _videoController!.addListener(_onVideoPositionChanged);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل الفيديو: $e')),
        );
      }
    }
  }

  void _onVideoPositionChanged() {
    if (_videoController != null && mounted) {
      setState(() {
        _currentPosition = _videoController!.value.position;
      });
      
      // إيقاف التشغيل عند الوصول لنهاية المقطع
      if (_currentPosition >= _endTime && _isPlaying) {
        _pauseVideo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('إنشاء مقطع'),
        actions: [
          TextButton(
            onPressed: _isCreatingClip ? null : _showClipDetailsDialog,
            child: Text(
              'إنشاء',
              style: TextStyle(
                color: _isCreatingClip ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildVideoPlayer(),
                _buildTimelineEditor(),
                _buildControlButtons(),
                _buildClipInfo(),
              ],
            ),
    );
  }

  Widget _buildVideoPlayer() {
    return Expanded(
      child: Container(
        width: double.infinity,
        child: _videoController != null
            ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            : Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(Icons.video_library, color: Colors.white, size: 64),
                ),
              ),
      ),
    );
  }

  Widget _buildTimelineEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Column(
        children: [
          _buildTimeDisplay(),
          const SizedBox(height: 16),
          _buildTimeline(),
          const SizedBox(height: 8),
          _buildTimeLabels(),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTimeInfo('البداية', _startTime, Colors.green),
        _buildTimeInfo('الحالي', _currentPosition, Colors.blue),
        _buildTimeInfo('النهاية', _endTime, Colors.red),
        _buildTimeInfo('المدة', _endTime - _startTime, Colors.orange),
      ],
    );
  }

  Widget _buildTimeInfo(String label, Duration time, Color color) {
    final minutes = time.inMinutes;
    final seconds = time.inSeconds.remainder(60);
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        Text(
          timeString,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Container(
      height: 80,
      child: Stack(
        children: [
          // خلفية الخط الزمني
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          // منطقة المقطع المحدد
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: CustomPaint(
                painter: TimelineSelectionPainter(
                  startPosition: _startThumbPosition,
                  endPosition: _endThumbPosition,
                  currentPosition: _videoDuration.inMilliseconds > 0
                      ? _currentPosition.inMilliseconds / _videoDuration.inMilliseconds
                      : 0.0,
                ),
              ),
            ),
          ),
          
          // شريط تمرير البداية
          Positioned(
            left: _startThumbPosition * (MediaQuery.of(context).size.width - 32) - 16,
            top: 0,
            child: GestureDetector(
              onPanStart: (_) => _isDraggingStart = true,
              onPanUpdate: (details) => _onStartThumbDrag(details),
              onPanEnd: (_) => _isDraggingStart = false,
              child: Container(
                width: 32,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 12),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // شريط تمرير النهاية
          Positioned(
            left: _endThumbPosition * (MediaQuery.of(context).size.width - 32) - 16,
            top: 0,
            child: GestureDetector(
              onPanStart: (_) => _isDraggingEnd = true,
              onPanUpdate: (details) => _onEndThumbDrag(details),
              onPanEnd: (_) => _isDraggingEnd = false,
              child: Container(
                width: 32,
                height: 80,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.stop, color: Colors.white, size: 12),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.red,
                      ),
                    ),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('00:00', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        Text(
          '${_videoDuration.inMinutes.toString().padLeft(2, '0')}:${_videoDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.skip_previous,
            label: 'البداية',
            onPressed: _seekToStart,
          ),
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            label: _isPlaying ? 'إيقاف' : 'تشغيل',
            onPressed: _togglePlayback,
          ),
          _buildControlButton(
            icon: Icons.skip_next,
            label: 'النهاية',
            onPressed: _seekToEnd,
          ),
          _buildControlButton(
            icon: Icons.preview,
            label: 'معاينة',
            onPressed: _previewClip,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
          iconSize: 28,
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildClipInfo() {
    final clipDuration = _endTime - _startTime;
    final isValid = clipDuration.inSeconds >= 5 && clipDuration.inSeconds <= 60;
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[850],
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.warning,
                color: isValid ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isValid
                    ? 'مدة المقطع: ${clipDuration.inSeconds} ثانية'
                    : 'مدة المقطع يجب أن تكون بين 5-60 ثانية',
                style: TextStyle(
                  color: isValid ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: 8),
            Text(
              'المدة الحالية: ${clipDuration.inSeconds} ثانية',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  void _onStartThumbDrag(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final deltaX = details.delta.dx;
    final newPosition = (_startThumbPosition + deltaX / screenWidth).clamp(0.0, _endThumbPosition - 0.05);
    
    setState(() {
      _startThumbPosition = newPosition;
      _startTime = Duration(milliseconds: (newPosition * _videoDuration.inMilliseconds).round());
    });
  }

  void _onEndThumbDrag(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final deltaX = details.delta.dx;
    final newPosition = (_endThumbPosition + deltaX / screenWidth).clamp(_startThumbPosition + 0.05, 1.0);
    
    setState(() {
      _endThumbPosition = newPosition;
      _endTime = Duration(milliseconds: (newPosition * _videoDuration.inMilliseconds).round());
    });
  }

  void _seekToStart() {
    _videoController?.seekTo(_startTime);
    setState(() {
      _currentPosition = _startTime;
    });
  }

  void _seekToEnd() {
    _videoController?.seekTo(_endTime);
    setState(() {
      _currentPosition = _endTime;
    });
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _playVideo() {
    // إذا كان الموضع خارج المقطع، ابدأ من البداية
    if (_currentPosition < _startTime || _currentPosition >= _endTime) {
      _videoController?.seekTo(_startTime);
    }
    
    _videoController?.play();
    setState(() {
      _isPlaying = true;
    });
  }

  void _pauseVideo() {
    _videoController?.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _previewClip() async {
    _previewAnimationController.forward();
    
    // تشغيل المعاينة
    await _videoController?.seekTo(_startTime);
    _videoController?.play();
    
    setState(() {
      _isPlaying = true;
    });
    
    // إيقاف المعاينة بعد انتهاء المقطع
    await Future.delayed(_endTime - _startTime);
    
    _pauseVideo();
    _previewAnimationController.reverse();
  }

  void _showClipDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => ClipDetailsDialog(
        originalPost: widget.originalPost,
        startTime: _startTime,
        endTime: _endTime,
        onClipCreated: (clip) {
          Navigator.pop(context);
          Navigator.pop(context, clip);
        },
      ),
    );
  }
}

/// رسام الخط الزمني
class TimelineSelectionPainter extends CustomPainter {
  final double startPosition;
  final double endPosition;
  final double currentPosition;

  TimelineSelectionPainter({
    required this.startPosition,
    required this.endPosition,
    required this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // رسم المنطقة المحددة
    paint.color = Colors.blue.withOpacity(0.3);
    final startX = startPosition * size.width;
    final endX = endPosition * size.width;
    
    canvas.drawRect(
      Rect.fromLTRB(startX, 0, endX, size.height),
      paint,
    );
    
    // رسم الموضع الحالي
    paint.color = Colors.blue;
    paint.strokeWidth = 2;
    final currentX = currentPosition * size.width;
    
    canvas.drawLine(
      Offset(currentX, 0),
      Offset(currentX, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(TimelineSelectionPainter oldDelegate) {
    return oldDelegate.startPosition != startPosition ||
           oldDelegate.endPosition != endPosition ||
           oldDelegate.currentPosition != currentPosition;
  }
}

/// حوار تفاصيل المقطع
class ClipDetailsDialog extends StatefulWidget {
  final Post originalPost;
  final Duration startTime;
  final Duration endTime;
  final Function(VideoClip) onClipCreated;

  const ClipDetailsDialog({
    super.key,
    required this.originalPost,
    required this.startTime,
    required this.endTime,
    required this.onClipCreated,
  });

  @override
  State<ClipDetailsDialog> createState() => _ClipDetailsDialogState();
}

class _ClipDetailsDialogState extends State<ClipDetailsDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final VideoClipService _clipService = VideoClipService();
  
  ClipCategory _selectedCategory = ClipCategory.highlight;
  bool _isPublic = true;
  bool _isCreating = false;
  List<String> _hashtags = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل المقطع',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان المقطع *',
                border: OutlineInputBorder(),
              ),
              maxLength: 100,
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            
            const SizedBox(height: 16),
            
            DropdownButtonFormField<ClipCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'الفئة',
                border: OutlineInputBorder(),
              ),
              items: ClipCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text('${category.emoji} ${category.displayName}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('عام'),
              subtitle: const Text('السماح للآخرين برؤية هذا المقطع'),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCreating ? null : () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createClip,
                    child: _isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('إنشاء'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createClip() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عنوان المقطع مطلوب')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final clipInfo = ClipCreationInfo(
        originalPostId: widget.originalPost.id,
        videoDuration: Duration(seconds: widget.originalPost.videoDurationSeconds ?? 0),
        startTime: widget.startTime,
        endTime: widget.endTime,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        hashtags: _hashtags,
        isPublic: _isPublic,
      );

      final clip = await _clipService.createClip(clipInfo);
      
      if (mounted) {
        widget.onClipCreated(clip);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء المقطع بنجاح!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إنشاء المقطع: $e')),
        );
      }
    }
  }
}
