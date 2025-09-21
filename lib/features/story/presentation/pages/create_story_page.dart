import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:video_player/video_player.dart';

enum CreateStoryMode {
  media,
  poll,
}

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  final StoryService _storyService = StoryService();
  final TextEditingController _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  CreateStoryMode _currentMode = CreateStoryMode.media;
  File? _mediaFile;
  StoryMediaType _mediaType = StoryMediaType.image;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = false;
  bool _isUploading = false;
  
  // For filters
  StoryFilter? _selectedFilter;

  @override
  void dispose() {
    _videoController?.dispose();
    _pollQuestionController.dispose();
    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, StoryMediaType type) async {
    final picker = ImagePicker();
    XFile? pickedFile;

    try {
      if (type == StoryMediaType.image) {
        pickedFile = await picker.pickImage(source: source, imageQuality: 85);
      } else {
        pickedFile = await picker.pickVideo(source: source);
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
          _mediaType = type;
          _currentMode = CreateStoryMode.media; // Reset to media mode on new pick
        });

        if (type == StoryMediaType.video) {
          _initializeVideoPlayer();
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء اختيار الملف: $e')),
        );
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار صورة أو فيديو أولاً')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _isLoading = true;
    });

    try {
      StoryItem? newStory;
      
      if (_currentMode == CreateStoryMode.media) {
        newStory = await _storyService.createStory(
          file: _mediaFile!,
          mediaType: _mediaType,
          filter: _selectedFilter,
        );
      } else if (_currentMode == CreateStoryMode.poll) {
        if (_pollQuestionController.text.isEmpty ||
            _pollOptionControllers.any((c) => c.text.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرجاء تعبئة جميع حقول الاستطلاع')),
          );
          setState(() => _isLoading = false);
          return;
        }
        
        newStory = await _storyService.createPollStory(
          file: _mediaFile!,
          question: _pollQuestionController.text,
          options: _pollOptionControllers.map((c) => c.text).toList(),
          filter: _selectedFilter,
        );
      }

      if (newStory != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر القصة بنجاح!')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل نشر القصة.')),
        );
      }
    } catch (e) {
      debugPrint('Error uploading story: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
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
  
  void _selectFilter(StoryFilter? filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createStory),
        actions: [
          if (_mediaFile != null && !_isUploading)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _uploadStory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Media preview
                  if (_mediaFile == null)
                    _buildMediaPicker(l10n)
                  else
                    _buildMediaPreview(),

                  if (_mediaFile != null) ...[
                    // Mode switcher
                    _buildModeSwitcher(),
                    
                    // Fields for the current mode
                    if (_currentMode == CreateStoryMode.poll)
                      _buildPollCreator(),
                    
                    // Filter selection (only for images)
                    if (_mediaType == StoryMediaType.image)
                      _buildFilterSelector(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMediaPicker(AppLocalizations l10n) {
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.selectMediaForStory,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.gallery, StoryMediaType.image),
                  icon: const Icon(Icons.photo_library),
                  label: Text(l10n.galleryImage),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.camera, StoryMediaType.image),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n.cameraImage),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.gallery, StoryMediaType.video),
                  icon: const Icon(Icons.video_library),
                  label: Text(l10n.galleryVideo),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.camera, StoryMediaType.video),
                  icon: const Icon(Icons.videocam),
                  label: Text(l10n.cameraVideo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    Widget mediaWidget;
    if (_mediaType == StoryMediaType.video) {
      mediaWidget = _isVideoInitialized
          ? AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            )
          : const Center(child: CircularProgressIndicator());
    } else {
      mediaWidget = Image.file(_mediaFile!);
    }
    
    // Apply filter if selected (for images only)
    if (_mediaType == StoryMediaType.image && _selectedFilter != null) {
      mediaWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(_selectedFilter!.matrix),
        child: mediaWidget,
      );
    }

    return Stack(
      children: [
        mediaWidget,
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _mediaFile = null;
                  _videoController?.dispose();
                  _videoController = null;
                  _isVideoInitialized = false;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SegmentedButton<CreateStoryMode>(
        segments: const [
          ButtonSegment(
            value: CreateStoryMode.media,
            icon: Icon(Icons.perm_media),
            label: Text('وسائط'),
          ),
          ButtonSegment(
            value: CreateStoryMode.poll,
            icon: Icon(Icons.poll),
            label: Text('استطلاع'),
          ),
        ],
        selected: {_currentMode},
        onSelectionChanged: (newSelection) {
          setState(() {
            _currentMode = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildPollCreator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _pollQuestionController,
            decoration: InputDecoration(
              hintText: 'سؤال الاستطلاع',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'الخيارات:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._pollOptionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'خيار ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
              icon: const Icon(Icons.add),
              label: const Text('إضافة خيار'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSelector() {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // No filter option
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
    
    Widget thumbnail = Image.file(
      _mediaFile!,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
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
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 3) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: thumbnail,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 