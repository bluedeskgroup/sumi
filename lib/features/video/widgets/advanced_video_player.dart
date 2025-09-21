import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sumi/features/community/models/post_model.dart';

/// مشغل فيديو متقدم مع دعم تغيير الجودة مثل يوتيوب
class AdvancedVideoPlayer extends StatefulWidget {
  final Post post;
  final Function(Duration)? onProgressUpdate;
  final Function? onVideoCompleted;

  const AdvancedVideoPlayer({
    super.key,
    required this.post,
    this.onProgressUpdate,
    this.onVideoCompleted,
  });

  @override
  State<AdvancedVideoPlayer> createState() => _AdvancedVideoPlayerState();
}

class _AdvancedVideoPlayerState extends State<AdvancedVideoPlayer>
    with TickerProviderStateMixin {
  
  VideoPlayerController? _controller;
  late AnimationController _controlsAnimationController;
  late AnimationController _qualityAnimationController;
  Timer? _hideControlsTimer;
  
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _showControls = true;
  bool _showQualityMenu = false;
  bool _isFullscreen = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  
  // جودات الفيديو المتاحة
  VideoQuality _currentQuality = VideoQuality.auto;
  List<VideoQualityOption> _availableQualities = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeVideo();
    _setupAvailableQualities();
  }

  void _initAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _qualityAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _controlsAnimationController.forward();
  }

  void _setupAvailableQualities() {
    // إعداد الجودات المتاحة (محاكاة - في التطبيق الحقيقي ستأتي من الخادم)
    _availableQualities = [
      VideoQualityOption(
        quality: VideoQuality.auto,
        label: 'تلقائي',
        resolution: 'تلقائي',
        isRecommended: true,
      ),
      VideoQualityOption(
        quality: VideoQuality.high,
        label: '1080p',
        resolution: '1920x1080',
      ),
      VideoQualityOption(
        quality: VideoQuality.medium,
        label: '720p',
        resolution: '1280x720',
      ),
      VideoQualityOption(
        quality: VideoQuality.low,
        label: '480p',
        resolution: '854x480',
      ),
      VideoQualityOption(
        quality: VideoQuality.lowest,
        label: '360p',
        resolution: '640x360',
      ),
    ];
  }

  Future<void> _initializeVideo() async {
    if (widget.post.mediaUrls.isEmpty) return;
    
    final videoUrl = widget.post.mediaUrls.first;
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    
    try {
      await _controller!.initialize();
      
      setState(() {
        _isInitialized = true;
        _duration = _controller!.value.duration;
        _hasError = false;
        _errorMessage = '';
      });
      
      // مراقبة حالة الفيديو
      _controller!.addListener(_videoListener);
      
      // إخفاء العناصر التحكم تلقائياً
      _startHideControlsTimer();
      
    } catch (e) {
      print('خطأ في تشغيل الفيديو: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'فشل في تحميل الفيديو. يرجى المحاولة مرة أخرى.';
        _isInitialized = false;
      });
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    
    final value = _controller!.value;
    
    // Check for video errors
    if (value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = 'حدث خطأ في تشغيل الفيديو';
      });
      return;
    }
    
    setState(() {
      _position = value.position;
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
    });
    
    // إرسال تحديث التقدم
    widget.onProgressUpdate?.call(_position);
    
    // التحقق من انتهاء الفيديو
    if (value.position >= value.duration && value.duration > Duration.zero) {
      widget.onVideoCompleted?.call();
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    
    try {
      setState(() {
        if (_isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
      
      _showControlsTemporarily();
    } catch (e) {
      print('خطأ في تشغيل/إيقاف الفيديو: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'خطأ في تشغيل الفيديو';
      });
    }
  }

  void _seekTo(Duration position) {
    try {
      _controller?.seekTo(position);
      _showControlsTemporarily();
    } catch (e) {
      print('خطأ في البحث عن الموضع: $e');
    }
  }

  void _changePlaybackSpeed(double speed) {
    _controller?.setPlaybackSpeed(speed);
    setState(() {
      _playbackSpeed = speed;
    });
    _showControlsTemporarily();
  }

  void _changeQuality(VideoQuality quality) {
    setState(() {
      _currentQuality = quality;
      _showQualityMenu = false;
    });
    
    _qualityAnimationController.reverse();
    _showControlsTemporarily();
    
    // في التطبيق الحقيقي، هنا سيتم تغيير مصدر الفيديو
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم تغيير الجودة إلى ${_getQualityLabel(quality)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getQualityLabel(VideoQuality quality) {
    final option = _availableQualities.firstWhere(
      (opt) => opt.quality == quality,
      orElse: () => _availableQualities.first,
    );
    return option.label;
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _controlsAnimationController.forward();
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
        _controlsAnimationController.reverse();
      }
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      // دخول وضع ملء الشاشة
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _FullscreenVideoPlayer(
            controller: _controller!,
            post: widget.post,
            onExit: () {
              setState(() {
                _isFullscreen = false;
              });
            },
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _controlsAnimationController.dispose();
    _qualityAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorPlayer();
    }
    
    if (!_isInitialized || _controller == null) {
      return _buildLoadingPlayer();
    }

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // مشغل الفيديو
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
            
            // مؤشر التحميل
            if (_isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            
            // عناصر التحكم
            AnimatedBuilder(
              animation: _controlsAnimationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _controlsAnimationController.value,
                  child: _showControls ? _buildControls() : const SizedBox(),
                );
              },
            ),
            
            // قائمة الجودة
            AnimatedBuilder(
              animation: _qualityAnimationController,
              builder: (context, child) {
                return _showQualityMenu ? _buildQualityMenu() : const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlayer() {
    return Container(
      height: 200,
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'جارٍ تحميل الفيديو...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlayer() {
    return Container(
      height: 200,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = '';
                  _isInitialized = false;
                });
                _initializeVideo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A46D7),
                foregroundColor: Colors.white,
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط علوي
          _buildTopControls(),
          
          const Spacer(),
          
          // عناصر التحكم الوسطى
          _buildCenterControls(),
          
          const Spacer(),
          
          // شريط سفلي
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // العنوان
            Expanded(
              child: Text(
                widget.post.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // زر ملء الشاشة
            GestureDetector(
              onTap: _toggleFullscreen,
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // زر التراجع 10 ثوان
        GestureDetector(
          onTap: () {
            final newPosition = _position - const Duration(seconds: 10);
            _seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.replay_10,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // زر التشغيل/الإيقاف
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // زر التقدم 10 ثوان
        GestureDetector(
          onTap: () {
            final newPosition = _position + const Duration(seconds: 10);
            _seekTo(newPosition > _duration ? _duration : newPosition);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forward_10,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط التقدم
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.red,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.red,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (value * _duration.inMilliseconds).round(),
                      );
                      _seekTo(newPosition);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
          
          // أزرار إضافية - صف واحد مدمج
          Row(
            children: [
              // زر السرعة
              GestureDetector(
                onTap: () {
                  // تبديل سريع بين السرعات الشائعة
                  final speeds = [1.0, 1.25, 1.5, 2.0];
                  final currentIndex = speeds.indexOf(_playbackSpeed);
                  final nextIndex = (currentIndex + 1) % speeds.length;
                  _changePlaybackSpeed(speeds[nextIndex]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, color: Colors.white, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        '${_playbackSpeed}x',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // زر الصوت
              GestureDetector(
                onTap: () {
                  setState(() {
                    _volume = _volume > 0 ? 0 : 1;
                    _controller?.setVolume(_volume);
                  });
                },
                child: Icon(
                  _volume > 0 ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityMenu() {
    return Positioned(
      top: 100,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(_qualityAnimationController),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'جودة الفيديو',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._availableQualities.map((option) => _buildQualityOption(option)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityOption(VideoQualityOption option) {
    final isSelected = option.quality == _currentQuality;
    
    return GestureDetector(
      onTap: () => _changeQuality(option.quality),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? Colors.red : Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        color: isSelected ? Colors.red : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (option.isRecommended) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'مُوصى',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  option.resolution,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// مشغل فيديو ملء الشاشة
class _FullscreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController controller;
  final Post post;
  final VoidCallback onExit;

  const _FullscreenVideoPlayer({
    required this.controller,
    required this.post,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: onExit,
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}

/// تعداد جودة الفيديو
enum VideoQuality {
  auto,
  lowest,
  low,
  medium,
  high,
  highest,
}

/// خيار جودة الفيديو
class VideoQualityOption {
  final VideoQuality quality;
  final String label;
  final String resolution;
  final bool isRecommended;

  VideoQualityOption({
    required this.quality,
    required this.label,
    required this.resolution,
    this.isRecommended = false,
  });
}
