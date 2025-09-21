import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:video_player/video_player.dart';

enum StoryCreationMode {
  capture,
  media,
  template,
  poll,
}

class EnhancedCreateStoryPage extends StatefulWidget {
  const EnhancedCreateStoryPage({super.key});

  @override
  State<EnhancedCreateStoryPage> createState() => _EnhancedCreateStoryPageState();
}

class _EnhancedCreateStoryPageState extends State<EnhancedCreateStoryPage>
    with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  // Controllers for poll creation
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  StoryCreationMode _currentMode = StoryCreationMode.capture;
  File? _mediaFile;
  StoryMediaType _mediaType = StoryMediaType.image;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = false;
  bool _isUploading = false;
  
  // Story customization
  StoryFilter? _selectedFilter;
  String? _selectedTemplate;
  bool _allowSharing = true;
  bool _showPrivacyOptions = false;
  
  // Text overlay
  String _textOverlay = '';
  Color _textColor = Colors.white;
  double _textSize = 24.0;
  Alignment _textAlignment = Alignment.center;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeController.forward();
    _requestPermissions();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _videoController?.dispose();
    _pollQuestionController.dispose();
    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  Future<void> _pickMedia(ImageSource source, StoryMediaType type) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      if (type == StoryMediaType.image) {
        pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1080,
          maxHeight: 1920,
        );
      } else {
        pickedFile = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 30),
        );
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
          _mediaType = type;
          _currentMode = StoryCreationMode.media;
        });

        if (type == StoryMediaType.video) {
          _initializeVideoPlayer();
        }
        
        _slideController.forward();
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      _showErrorSnackBar('حدث خطأ أثناء اختيار الملف');
    }
  }

  void _initializeVideoPlayer() {
    if (_mediaFile == null) return;
    
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(_mediaFile!)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController!.play();
          _videoController!.setLooping(true);
        }
      });
  }

  Future<void> _uploadStory() async {
    if (_mediaFile == null) {
      _showErrorSnackBar('الرجاء اختيار صورة أو فيديو أولاً');
      return;
    }

    setState(() {
      _isUploading = true;
      _isLoading = true;
    });

    try {
      StoryItem? newStory;
      
      if (_currentMode == StoryCreationMode.poll) {
        if (_pollQuestionController.text.isEmpty ||
            _pollOptionControllers.any((c) => c.text.isEmpty)) {
          _showErrorSnackBar('الرجاء تعبئة جميع حقول الاستطلاع');
          setState(() => _isLoading = false);
          return;
        }
        
        newStory = await _storyService.createPollStory(
          file: _mediaFile!,
          question: _pollQuestionController.text,
          options: _pollOptionControllers.map((c) => c.text).toList(),
          filter: _selectedFilter,
        );
      } else {
        newStory = await _storyService.createStory(
          file: _mediaFile!,
          mediaType: _mediaType,
          filter: _selectedFilter,
          allowSharing: _allowSharing,
        );
      }

      if (newStory != null && mounted) {
        _showSuccessSnackBar('تم نشر القصة بنجاح! 🎉');
        Navigator.of(context).pop();
      } else if (mounted) {
        _showErrorSnackBar('فشل نشر القصة');
      }
    } catch (e) {
      debugPrint('Error uploading story: $e');
      if (mounted) {
        _showErrorSnackBar('حدث خطأ أثناء نشر القصة');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isLoading = false;
        });
      }
    }
  }

  void _selectFilter(StoryFilter? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    HapticFeedback.selectionClick();
  }

  void _selectTemplate(String template) {
    setState(() {
      _selectedTemplate = template;
    });
    HapticFeedback.selectionClick();
  }

  void _addPollOption() {
    if (_pollOptionControllers.length < 4) {
      setState(() {
        _pollOptionControllers.add(TextEditingController());
      });
    }
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length > 2) {
      setState(() {
        _pollOptionControllers[index].dispose();
        _pollOptionControllers.removeAt(index);
      });
    }
  }

  void _resetMedia() {
    setState(() {
      _mediaFile = null;
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;
      _selectedFilter = null;
      _selectedTemplate = null;
      _textOverlay = '';
      _currentMode = StoryCreationMode.capture;
    });
    _slideController.reset();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        backgroundColor: const Color(0xFF9A46D7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF9A46D7),
                    Colors.black,
                  ],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
            
            // Main content
            _isLoading 
                ? _buildLoadingState()
                : _buildMainContent(),
            
            // Floating action button
            if (_mediaFile != null && !_isUploading)
              _buildFloatingActionButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'إنشاء قصة',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Ping AR + LT',
        ),
      ),
      centerTitle: true,
      actions: [
        if (_mediaFile != null)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings, color: Colors.white),
            ),
            onPressed: () {
              setState(() {
                _showPrivacyOptions = !_showPrivacyOptions;
              });
            },
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF9A46D7),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              _isUploading ? 'جاري نشر القصة...' : 'جاري التحميل...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_mediaFile == null) {
      return _buildCaptureInterface();
    } else {
      return _buildEditInterface();
    }
  }

  Widget _buildCaptureInterface() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Spacer(),
            
            // Welcome text
            FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'شارك لحظاتك المميزة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Ping AR + LT',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر صورة أو فيديو لإنشاء قصة جديدة',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontFamily: 'Ping AR + LT',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Mode selector
            _buildModeSelector(),
            
            const SizedBox(height: 30),
            
            // Action buttons
            _buildActionButtons(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            icon: Icons.camera_alt,
            label: 'كاميرا',
            mode: StoryCreationMode.capture,
          ),
          _buildModeButton(
            icon: Icons.photo_library,
            label: 'معرض',
            mode: StoryCreationMode.media,
          ),
          _buildModeButton(
            icon: Icons.poll,
            label: 'استطلاع',
            mode: StoryCreationMode.poll,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required StoryCreationMode mode,
  }) {
    final isSelected = _currentMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9A46D7) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary actions
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_camera,
                label: 'التقاط صورة',
                onTap: () => _pickMedia(ImageSource.camera, StoryMediaType.image),
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.videocam,
                label: 'تسجيل فيديو',
                onTap: () => _pickMedia(ImageSource.camera, StoryMediaType.video),
                isPrimary: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library,
                label: 'من المعرض',
                onTap: () => _showMediaPicker(),
                isPrimary: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.text_fields,
                label: 'نص فقط',
                onTap: () => _createTextOnlyStory(),
                isPrimary: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary 
              ? const Color(0xFF9A46D7) 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary 
                ? Colors.transparent 
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditInterface() {
    return Stack(
      children: [
        // Media preview
        _buildMediaPreview(),
        
        // Edit controls overlay
        _buildEditControls(),
        
        // Privacy options
        if (_showPrivacyOptions)
          _buildPrivacyOptions(),
      ],
    );
  }

  Widget _buildMediaPreview() {
    Widget mediaWidget;
    
    if (_mediaType == StoryMediaType.video) {
      mediaWidget = _isVideoInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Color(0xFF9A46D7)),
            );
    } else {
      mediaWidget = Image.file(
        _mediaFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    
    // Apply filter if selected
    if (_mediaType == StoryMediaType.image && _selectedFilter != null) {
      mediaWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(_selectedFilter!.matrix),
        child: mediaWidget,
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: Stack(
        fit: StackFit.expand,
        children: [
          mediaWidget,
          
          // Text overlay
          if (_textOverlay.isNotEmpty)
            Positioned.fill(
              child: Align(
                alignment: _textAlignment,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _textOverlay,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: _textSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Ping AR + LT',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditControls() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 80), // AppBar space
          
          // Top controls
          _buildTopControls(),
          
          const Spacer(),
          
          // Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Reset button
          _buildControlButton(
            icon: Icons.refresh,
            onTap: _resetMedia,
          ),
          
          const Spacer(),
          
          // Text overlay button
          _buildControlButton(
            icon: Icons.text_fields,
            onTap: _showTextOverlayDialog,
          ),
          
          const SizedBox(width: 12),
          
          // Filter button
          if (_mediaType == StoryMediaType.image)
            _buildControlButton(
              icon: Icons.filter_vintage,
              onTap: _showFilterPicker,
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mode specific controls
          if (_currentMode == StoryCreationMode.poll)
            _buildPollCreator(),
          
          // Filter selector
          if (_mediaType == StoryMediaType.image && _selectedFilter == null)
            _buildFilterSelector(),
          
          const SizedBox(height: 16),
          
          // Template selector
          _buildTemplateSelector(),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterThumbnail(null, 'بدون فلتر'),
          ...storyFilters.map((filter) {
            return _buildFilterThumbnail(filter, filter.name);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterThumbnail(StoryFilter? filter, String name) {
    final isSelected = _selectedFilter == filter;
    
    Widget thumbnail = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(_mediaFile!),
          fit: BoxFit.cover,
        ),
      ),
    );
    
    if (filter != null) {
      thumbnail = ColorFiltered(
        colorFilter: ColorFilter.matrix(filter.matrix),
        child: thumbnail,
      );
    }
    
    return GestureDetector(
      onTap: () => _selectFilter(filter),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isSelected 
                    ? Border.all(color: const Color(0xFF9A46D7), width: 3)
                    : Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: thumbnail,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? const Color(0xFF9A46D7) : Colors.white,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelector() {
    final templates = ['عادي', 'احتفالي', 'رياضي', 'طعام', 'سفر'];
    
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          final isSelected = _selectedTemplate == template;
          
          return GestureDetector(
            onTap: () => _selectTemplate(template),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF9A46D7) 
                    : Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? Colors.transparent 
                      : Colors.white.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  template,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPollCreator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _pollQuestionController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Ping AR + LT',
            ),
            decoration: InputDecoration(
              hintText: 'اكتب سؤال الاستطلاع...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Ping AR + LT',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF9A46D7)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._pollOptionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Ping AR + LT',
                      ),
                      decoration: InputDecoration(
                        hintText: 'خيار ${index + 1}',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Ping AR + LT',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF9A46D7)),
                        ),
                      ),
                    ),
                  ),
                  if (_pollOptionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => _removePollOption(index),
                    ),
                ],
              ),
            );
          }),
          if (_pollOptionControllers.length < 4)
            TextButton.icon(
              onPressed: _addPollOption,
              icon: const Icon(Icons.add, color: Color(0xFF9A46D7)),
              label: const Text(
                'إضافة خيار',
                style: TextStyle(
                  color: Color(0xFF9A46D7),
                  fontFamily: 'Ping AR + LT',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOptions() {
    return Positioned(
      top: 120,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعدادات الخصوصية',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Ping AR + LT',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Switch(
                  value: _allowSharing,
                  onChanged: (value) {
                    setState(() {
                      _allowSharing = value;
                    });
                  },
                  activeColor: const Color(0xFF9A46D7),
                ),
                const SizedBox(width: 8),
                const Text(
                  'السماح بالمشاركة',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _uploadStory,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9A46D7), Color(0xFF7B1FA2)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9A46D7).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'نشر القصة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'اختر من المعرض',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ping AR + LT',
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo, color: Color(0xFF9A46D7)),
                title: const Text(
                  'صورة',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.gallery, StoryMediaType.image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF9A46D7)),
                title: const Text(
                  'فيديو',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Ping AR + LT',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.gallery, StoryMediaType.video);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'اختر فلتر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Ping AR + LT',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: storyFilters.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildFilterGridItem(null, 'بدون فلتر');
                    } else {
                      final filter = storyFilters[index - 1];
                      return _buildFilterGridItem(filter, filter.name);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterGridItem(StoryFilter? filter, String name) {
    final isSelected = _selectedFilter == filter;
    
    Widget thumbnail = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(_mediaFile!),
          fit: BoxFit.cover,
        ),
      ),
    );
    
    if (filter != null) {
      thumbnail = ColorFiltered(
        colorFilter: ColorFilter.matrix(filter.matrix),
        child: thumbnail,
      );
    }
    
    return GestureDetector(
      onTap: () {
        _selectFilter(filter);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: const Color(0xFF9A46D7), width: 3)
                    : Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: thumbnail,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              color: isSelected ? const Color(0xFF9A46D7) : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTextOverlayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'إضافة نص',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Ping AR + LT',
          ),
        ),
        content: TextField(
          onChanged: (value) {
            setState(() {
              _textOverlay = value;
            });
          },
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Ping AR + LT',
          ),
          decoration: InputDecoration(
            hintText: 'اكتب النص هنا...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontFamily: 'Ping AR + LT',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9A46D7)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'تم',
              style: TextStyle(
                color: Color(0xFF9A46D7),
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createTextOnlyStory() {
    // TODO: Implement text-only story creation
    _showErrorSnackBar('قريباً: إنشاء قصة نصية فقط');
  }
}
