import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/widgets/hashtag_input_widget.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:sumi/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<File> _mediaFiles = [];
  PostType _postType = PostType.text;
  bool _isLoading = false;
  bool _isFeatured = false;
  final FocusNode _contentFocusNode = FocusNode();
  String? _errorMessage;
  List<String> _currentHashtags = [];

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        setState(() {
          _mediaFiles = pickedImages.map((xFile) => File(xFile.path)).toList();
          _postType = PostType.image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في اختيار الصور: $e';
      });
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedVideo = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (pickedVideo != null) {
        setState(() {
          _mediaFiles = [File(pickedVideo.path)];
          _postType = PostType.video;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في اختيار الفيديو: $e';
      });
    }
  }

  /// الانتقال إلى صفحة رفع الفيديو المتقدمة
  void _openAdvancedVideoUpload() {
    Navigator.pushNamed(context, '/upload-video');
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? takenPhoto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (takenPhoto != null) {
        setState(() {
          _mediaFiles = [File(takenPhoto.path)];
          _postType = PostType.image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في التقاط الصورة: $e';
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
      if (_mediaFiles.isEmpty) {
        _postType = PostType.text;
      }
    });
  }

  Future<void> _createPost() async {
    final localizations = AppLocalizations.of(context)!;
    final content = _contentController.text.trim();
    if (content.isEmpty && _mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.addContent)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _communityService.createPost(
        content: content,
        media: _mediaFiles,
        type: _postType,
        isFeatured: _isFeatured,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.postCreatedSuccess)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localizations.postCreatedFail} ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.createPostPageTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _isContentValid() 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  child: TextButton(
                    onPressed: _isContentValid() ? _createPost : null,
                    style: TextButton.styleFrom(
                      foregroundColor: _isContentValid() ? Colors.white : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isArabic ? 'نشر' : localizations.post,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(localizations),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 14),
                  ),
                ),
              _buildContentInput(localizations, isArabic),
              if (_mediaFiles.isNotEmpty) _buildMediaPreview(),
              const Divider(height: 1),
              _buildMediaOptions(localizations, isArabic),
              const SizedBox(height: 8),
              _buildFeaturedOption(localizations, isArabic),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  bool _isContentValid() {
    return _contentController.text.trim().isNotEmpty || _mediaFiles.isNotEmpty;
  }

  Widget _buildUserHeader(AppLocalizations localizations) {
    final currentUser = _auth.currentUser;
    final userName = currentUser?.displayName ?? 'مستخدم جديد';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: currentUser?.photoURL != null 
                ? NetworkImage(currentUser!.photoURL!) 
                : const AssetImage('assets/images/logo.png') as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic ? 'بماذا تفكر؟' : 'What\'s on your mind?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentInput(AppLocalizations localizations, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            decoration: InputDecoration(
              hintText: isArabic ? 'شاركي أفكارك... (استخدم # للهاشتاغات)' : 'Share your thoughts... (use # for hashtags)',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            maxLines: 5,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          // Hashtag input widget
          HashtagInputWidget(
            textController: _contentController,
            focusNode: _contentFocusNode,
            onHashtagsChanged: (hashtags) {
              setState(() {
                _currentHashtags = hashtags;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaFiles.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                width: 200,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_mediaFiles[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: _postType == PostType.video
                    ? const Center(
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.black45,
                          child: Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                top: 8,
                right: 16,
                child: GestureDetector(
                  onTap: () => _removeMedia(index),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeaturedOption(AppLocalizations localizations, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: _isFeatured ? Theme.of(context).primaryColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'مميز' : localizations.featured,
            style: TextStyle(
              fontSize: 16,
              color: _isFeatured ? Theme.of(context).primaryColor : Colors.grey[700],
              fontWeight: _isFeatured ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isFeatured,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (value) {
              setState(() {
                _isFeatured = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOptions(AppLocalizations localizations, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // الصف الأول - الخيارات الأساسية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaOptionButton(
                icon: Icons.photo_library,
                label: isArabic ? 'صورة' : localizations.photo,
                onTap: _pickImages,
                color: Colors.green,
              ),
              _buildMediaOptionButton(
                icon: Icons.camera_alt,
                label: isArabic ? 'كاميرا' : localizations.camera,
                onTap: _takePhoto,
                color: Colors.blue,
              ),
              _buildMediaOptionButton(
                icon: Icons.videocam,
                label: isArabic ? 'فيديو سريع' : 'Quick Video',
                onTap: _pickVideo,
                color: Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // الصف الثاني - خيار الفيديو المتقدم
          Container(
            width: double.infinity,
            height: 50,
            child: _buildAdvancedVideoButton(isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withAlpha(51),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// زر الفيديو المتقدم
  Widget _buildAdvancedVideoButton(bool isArabic) {
    return ElevatedButton.icon(
      onPressed: _openAdvancedVideoUpload,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.video_library,
          color: Colors.white,
          size: 18,
        ),
      ),
      label: Text(
        isArabic ? '📹 رفع فيديو متقدم (عنوان + وصف + ضغط)' : '📹 Advanced Video Upload',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF4444),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: Colors.red.withOpacity(0.3),
      ),
    );
  }
} 