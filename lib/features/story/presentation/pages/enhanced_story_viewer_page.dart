import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sumi/features/auth/models/user_model.dart';
import 'package:sumi/features/auth/services/user_service.dart';
import 'package:sumi/features/story/providers/story_settings_provider.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:sumi/features/video/services/advanced_video_cache_service.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart' as timeago;

class EnhancedStoryViewerPage extends StatefulWidget {
  final List<Story> stories;
  final int initialStoryIndex;

  const EnhancedStoryViewerPage({
    super.key,
    required this.stories,
    required this.initialStoryIndex,
  });

  @override
  State<EnhancedStoryViewerPage> createState() => _EnhancedStoryViewerPageState();
}

class _EnhancedStoryViewerPageState extends State<EnhancedStoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _storyController;
  late AnimationController _animationController;
  late AnimationController _reactionController;
  late AnimationController _tapController;
  VideoPlayerController? _videoController;

  final StoryService _storyService = StoryService();
  final UserService _userService = UserService();
  final AdvancedVideoCacheService _advancedCache = AdvancedVideoCacheService();

  late List<Story> _stories;
  int _currentStoryIndex = 0;
  int _currentPageIndex = 0;
  bool _isPaused = false;
  bool _showInterface = true;
  StreamSubscription? _storySubscription;

  // Reaction animation
  String? _lastReaction;
  bool _showReactionAnimation = false;

  // Quick reply
  final TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;

  // Hold-to-react overlay
  bool _showHoldReactionPicker = false;
  int? _holdSelectedIndex;
  static const double _holdOverlayWidth = 280.0;
  final List<StoryReactionType> _reactionTypes = StoryReactionType.values;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _stories = widget.stories;
    _currentStoryIndex = widget.initialStoryIndex;
    _currentPageIndex = 0;

    _storyController = PageController(initialPage: _currentStoryIndex);
    _animationController = AnimationController(vsync: this);
    _reactionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Defer setup that might touch context/inherited widgets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupInitialStory();
      _watchCurrentItemLive();
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.stop();
        _animationController.reset();
        _nextPage();
      }
    });

    // Keep interface visible on first open; it will auto-hide after user taps
  }

  @override
  void dispose() {
    _storyController.dispose();
    _animationController.dispose();
    _reactionController.dispose();
    _tapController.dispose();
    _videoController?.dispose();
    _storySubscription?.cancel();
    _itemSubscription?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  void _setupInitialStory() {
    _listenToStoryUpdates(_stories[_currentStoryIndex].userId);
    _loadStory(
        story: _stories[_currentStoryIndex].items[_currentPageIndex],
        animate: false);
  }

  void _listenToStoryUpdates(String userId) {
    _storySubscription?.cancel();
    _storySubscription =
        _storyService.getUserStories(userId).listen((updatedStories) {
      if (updatedStories.isNotEmpty) {
        setState(() {
          final storyIndex = _stories.indexWhere((s) => s.userId == userId);
          if (storyIndex != -1) {
            _stories[storyIndex] = updatedStories.first;
          }
        });
      }
    });
  }

  StreamSubscription<StoryItem?>? _itemSubscription;
  void _watchCurrentItemLive() {
    _itemSubscription?.cancel();
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    _itemSubscription = _storyService
        .watchStoryItem(story.id, item.id)
        .listen((liveItem) {
      if (!mounted || liveItem == null) return;
      setState(() {
        final currentStory = _stories[_currentStoryIndex];
        if (_currentPageIndex < currentStory.items.length) {
          currentStory.items[_currentPageIndex] = liveItem;
        }
      });
    });
  }

  void _onStoryUserChanged(int index) {
    setState(() {
      _currentStoryIndex = index;
      _currentPageIndex = 0;
      _setupInitialStory();
    });
    _watchCurrentItemLive();
  }

  void _pause() {
    _isPaused = true;
    _animationController.stop();
    _videoController?.pause();
  }

  void _resume() {
    _isPaused = false;
    _animationController.forward(from: _animationController.value);
    _videoController?.play();
  }

  void _loadStory({required StoryItem story, bool animate = true}) {
    _animationController.stop();
    _animationController.reset();
    _videoController?.dispose();
    _videoController = null;

    _storyService.markStoryAsViewed(_stories[_currentStoryIndex].id, story.id);
    _watchCurrentItemLive();

    if (story.mediaType == StoryMediaType.video) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl))
            ..initialize().then((_) {
              if (!mounted) return;
              setState(() {});
              _animationController.duration = _videoController!.value.duration;
              if (!_isPaused) {
                _videoController!.play();
                _animationController.forward();
              }
              _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
            });
      // Warm caches in background
      _advancedCache.precacheThumbnail(story.mediaUrl);
      _advancedCache.cacheVideo(story.mediaUrl);
    } else {
      _animationController.duration = const Duration(seconds: 5);
      if (!_isPaused) _animationController.forward();
    }

    // Preload next story's media after first frame to avoid using context in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _preloadNextMedia();
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _videoController?.setVolume(_isMuted ? 0.0 : 1.0);
    HapticFeedback.selectionClick();
  }

  void _preloadNextMedia() {
    final currentStory = _stories[_currentStoryIndex];
    StoryItem? nextItem;
    if (_currentPageIndex < currentStory.items.length - 1) {
      nextItem = currentStory.items[_currentPageIndex + 1];
    } else if (_currentStoryIndex < _stories.length - 1 && _stories[_currentStoryIndex + 1].items.isNotEmpty) {
      nextItem = _stories[_currentStoryIndex + 1].items.first;
    }

    if (nextItem == null) return;

    if (nextItem.mediaType == StoryMediaType.image) {
      // Cache image
      precacheImage(CachedNetworkImageProvider(nextItem.mediaUrl), context);
    } else if (nextItem.mediaType == StoryMediaType.video) {
      // Initialize a lightweight video controller in the background
      final controller = VideoPlayerController.networkUrl(Uri.parse(nextItem.mediaUrl));
      controller.initialize().then((_) {
        controller.dispose();
      }).catchError((_) {});
    }
  }

  void _onReactionSelected(StoryReactionType type) {
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    _storyService.addReaction(story.id, item.id, type);
    
    // Animate reaction
    setState(() {
      _lastReaction = type.emoji;
      _showReactionAnimation = true;
    });
    
    _reactionController.forward().then((_) {
      _reactionController.reset();
      setState(() {
        _showReactionAnimation = false;
      });
    });
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _onVote(int optionIndex) {
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    _storyService.voteInPoll(story.id, item.id, optionIndex);
    HapticFeedback.lightImpact();
  }

  void _onShare() {
    _pause();
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];

    if (item.allowSharing) {
      _storyService.incrementShareCount(story.id, item.id);
      
      Share.share(
        'شاهد هذه القصة من تطبيق سومي!\n${item.mediaUrl}',
        subject: 'قصة سومي',
      ).whenComplete(() => _resume());
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المشاركة معطلة لهذه القصة'),
          backgroundColor: Color(0xFF9A46D7),
        ),
      );
      _resume();
    }
  }

  void _showInsights() {
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    _showInsightsBottomSheet(story, item);
  }

  Future<void> _onSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSendingReply) return;

    setState(() {
      _isSendingReply = true;
    });

    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    final ok = await _storyService.addReply(story.id, item.id, text);

    if (!mounted) return;
    setState(() {
      _isSendingReply = false;
    });

    if (ok) {
      _replyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال الرد'),
          backgroundColor: Color(0xFF9A46D7),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر إرسال الرد'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    // Show interface on tap
    setState(() {
      _showInterface = true;
    });

    // Hide interface after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showInterface = false;
        });
      }
    });

    // Tap animation
    _tapController.forward().then((_) => _tapController.reverse());

    if (dx < screenWidth / 3) {
      _previousPage();
    } else {
      _nextPage();
    }
  }

  void _previousPage() {
    _animationController.stop();
    _animationController.reset();
    if (_currentPageIndex > 0) {
      setState(() {
        _currentPageIndex--;
        _loadStory(story: _stories[_currentStoryIndex].items[_currentPageIndex]);
      });
    } else {
      if (_currentStoryIndex > 0) {
        _storyController.previousPage(
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
      } else {
        _loadStory(story: _stories[_currentStoryIndex].items[_currentPageIndex]);
      }
    }
  }

  void _nextPage() {
    _animationController.stop();
    _animationController.reset();
    final currentStory = _stories[_currentStoryIndex];
    if (_currentPageIndex < currentStory.items.length - 1) {
      setState(() {
        _currentPageIndex++;
        _loadStory(story: currentStory.items[_currentPageIndex]);
      });
    } else {
      if (_currentStoryIndex < _stories.length - 1) {
        _storyController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
      } else {
        if (!mounted) return;
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView.builder(
          controller: _storyController,
          onPageChanged: _onStoryUserChanged,
          itemCount: _stories.length,
          itemBuilder: (context, storyIndex) {
            final currentStory = _stories[storyIndex];
            if (currentStory.items.isEmpty) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                    child: Text("هذا المستخدم ليس لديه قصص.",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Ping AR + LT',
                        ))),
              );
            }
            final currentItem = currentStory.items[
                _currentStoryIndex == storyIndex ? _currentPageIndex : 0];

            return Stack(
              children: [
                _buildStoryView(currentItem),
                
                // Reaction animation overlay
                if (_showReactionAnimation && _lastReaction != null)
                  _buildReactionAnimation(),
                
                // Interface overlay
                AnimatedOpacity(
                  opacity: _showInterface ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(currentStory, currentItem),
                        const Spacer(),
                        _buildFooter(currentItem),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoryView(StoryItem item) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onDoubleTap: () => _onReactionSelected(StoryReactionType.love),
      onLongPress: () {
        _pause();
        setState(() {
          _showHoldReactionPicker = true;
          _holdSelectedIndex = null;
        });
      },
      onLongPressMoveUpdate: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        final overlayLeft = (screenWidth - _holdOverlayWidth) / 2.0;
        final localDx = details.globalPosition.dx - overlayLeft;
        final segmentWidth = _holdOverlayWidth / _reactionTypes.length;
        int index = (localDx / segmentWidth).floor();
        if (localDx < 0) index = -1;
        if (localDx > _holdOverlayWidth) index = _reactionTypes.length;
        setState(() {
          _holdSelectedIndex = (index >= 0 && index < _reactionTypes.length) ? index : null;
        });
      },
      onLongPressUp: () {
        final selected = _holdSelectedIndex;
        setState(() {
          _showHoldReactionPicker = false;
          _holdSelectedIndex = null;
        });
        if (selected != null) {
          _onReactionSelected(_reactionTypes[selected]);
        }
        _resume();
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 600) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildMedia(item),
          
          // Tap animation overlay
          AnimatedBuilder(
            animation: _tapController,
            builder: (context, child) {
              return Container(
                color: Colors.white.withOpacity(_tapController.value * 0.1),
              );
            },
          ),

          if (_showHoldReactionPicker) _buildHoldReactionOverlay(),
        ],
      ),
    );
  }

  Widget _buildHoldReactionOverlay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final overlayLeft = (screenWidth - _holdOverlayWidth) / 2.0;
    return Positioned(
      bottom: 140,
      left: overlayLeft,
      width: _holdOverlayWidth,
      child: Container
        (
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_reactionTypes.length, (index) {
            final type = _reactionTypes[index];
            final selected = _holdSelectedIndex == index;
            return AnimatedScale(
              duration: const Duration(milliseconds: 120),
              scale: selected ? 1.4 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withOpacity(0.15) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  type.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMedia(StoryItem item) {
    Widget media;
    if (item.mediaType == StoryMediaType.video &&
        _videoController?.value.isInitialized == true) {
      media = Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else if (item.mediaType == StoryMediaType.image) {
      final image = CachedNetworkImage(
        imageUrl: item.mediaUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF9A46D7),
              strokeWidth: 3,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black,
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      );
      // Subtle Ken Burns effect during image duration
      media = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final scale = 1.0 + (_animationController.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: image,
      );
    } else {
      media = Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9A46D7),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (item.filter != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.matrix(item.filter!.matrix),
        child: media,
      );
    }
    return media;
  }

  Widget _buildHeader(Story story, StoryItem item) {
    return SafeArea(
      child: Column(
        children: [
          // Progress indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: List.generate(
                story.items.length,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    height: 3,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, _) {
                        double value;
                        if (story.userId != _stories[_currentStoryIndex].userId) {
                          value = 0;
                        } else {
                          value = index < _currentPageIndex
                              ? 1
                              : (index == _currentPageIndex
                                  ? _animationController.value
                                  : 0);
                        }
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF9A46D7),
                          ),
                          minHeight: 3,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // User info and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Close button (left in RTL)
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    if (item.mediaType == StoryMediaType.video) ...[
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _toggleMute,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const Spacer(),
                
                // User info (right in RTL)
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          story.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Ping AR + LT',
                          ),
                        ),
                        Text(
                          timeago.format(item.timestamp, locale: 'ar'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Ping AR + LT',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF9A46D7),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: story.userImage.isNotEmpty
                            ? CachedNetworkImageProvider(story.userImage)
                            : null,
                        child: story.userImage.isEmpty
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live counters (views, reactions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Consumer<StorySettingsProvider>(
                  builder: (context, settings, _) {
                    final bool isAuthor = story.userId == _storyService.currentUserId;
                    if (!settings.showViewCount || !isAuthor) return const SizedBox.shrink();
                    final views = item.viewedBy.length;
                    return _buildCounterPill(
                      icon: Icons.visibility_outlined,
                      label: _formatCount(views),
                      onTap: () => _showViewersList(story, item),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Consumer<StorySettingsProvider>(
                  builder: (context, settings, _) {
                    final bool isAuthor = story.userId == _storyService.currentUserId;
                    if (!settings.showReactions || !isAuthor) return const SizedBox.shrink();
                    final count = item.reactions.length;
                    return _buildCounterPill(
                      icon: Icons.favorite_border,
                      label: _formatCount(count),
                      onTap: () => _showReactionsList(item),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}أ';
    return n.toString();
  }

  Widget _buildCounterPill({required IconData icon, required String label, VoidCallback? onTap}) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Ping AR + LT',
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }

  void _showReactionsList(StoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          height: MediaQuery.of(context).size.height * 0.5,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: item.reactions.length,
            itemBuilder: (context, index) {
              final reaction = item.reactions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: reaction.userImage.isNotEmpty
                          ? CachedNetworkImageProvider(reaction.userImage)
                          : null,
                      child: reaction.userImage.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reaction.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Ping AR + LT',
                        ),
                      ),
                    ),
                    _buildReactionChip(reaction.type),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showViewersList(Story story, StoryItem item) {
    final viewerIds = item.viewedBy.where((id) => id != story.userId).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          height: MediaQuery.of(context).size.height * 0.5,
          child: FutureBuilder<List<AppUser>>(
            future: UserService().getUsers(viewerIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9A46D7)),
                );
              }
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد بيانات مشاهدين',
                    style: TextStyle(color: Colors.white70, fontFamily: 'Ping AR + LT'),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: u.userImage.isNotEmpty
                              ? CachedNetworkImageProvider(u.userImage)
                              : null,
                          child: u.userImage.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            u.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Ping AR + LT',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReactionChip(StoryReactionType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            _reactionLabel(type),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Ping AR + LT',
            ),
          ),
        ],
      ),
    );
  }

  String _reactionLabel(StoryReactionType type) {
    switch (type) {
      case StoryReactionType.like:
        return 'إعجاب';
      case StoryReactionType.love:
        return 'حب';
      case StoryReactionType.laugh:
        return 'ضحك';
      case StoryReactionType.wow:
        return 'واو';
      case StoryReactionType.sad:
        return 'حزين';
      case StoryReactionType.angry:
        return 'غضب';
    }
  }

  Widget _buildFooter(StoryItem item) {
    final isAuthor = _stories[_currentStoryIndex].userId == _storyService.currentUserId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poll widget
            if (item.poll != null)
              _EnhancedPollWidget(poll: item.poll!, onVote: _onVote),
            
            const SizedBox(height: 16),

            // Replies disabled per request: hide reply bar for all users
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Insights for author, reactions for others
                if (isAuthor)
                  _buildActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'الإحصائيات',
                    onTap: _showInsights,
                  )
                else
                  _EnhancedReactionButton(onSelected: _onReactionSelected),
                
                // Share button
                _buildActionButton(
                  icon: Icons.share_rounded,
                  label: 'مشاركة',
                  onTap: _onShare,
                ),
                
                // More options
                _buildActionButton(
                  icon: Icons.more_horiz_rounded,
                  label: 'المزيد',
                  onTap: () => _showMoreOptions(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Ping AR + LT'),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رداً...',
                    hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Ping AR + LT'),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _onSendReply(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSendingReply ? null : _onSendReply,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF9A46D7), Color(0xFF7B1FA2)]),
                    shape: BoxShape.circle,
                  ),
                  child: _isSendingReply
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionAnimation() {
    return AnimatedBuilder(
      animation: _reactionController,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.3 + 
               (50 * _reactionController.value),
          right: MediaQuery.of(context).size.width * 0.5 - 25,
          child: Transform.scale(
            scale: 1.0 + (_reactionController.value * 2),
            child: Opacity(
              opacity: 1.0 - _reactionController.value,
              child: Text(
                _lastReaction!,
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMoreOptions(StoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MoreOptionsSheet(
        storyId: _stories[_currentStoryIndex].id,
        storyUserId: _stories[_currentStoryIndex].userId,
        storyItem: item,
        isAuthor: _stories[_currentStoryIndex].userId == _storyService.currentUserId,
      ),
    );
  }

  void _showInsightsBottomSheet(Story story, StoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EnhancedInsightsSheet(
        story: story,
        storyItem: item,
      ),
    );
  }
}

// Enhanced Poll Widget
class _EnhancedPollWidget extends StatelessWidget {
  final StoryPoll poll;
  final ValueChanged<int> onVote;
  final StoryService _storyService = StoryService();

  _EnhancedPollWidget({required this.poll, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.hasUserVoted(_storyService.currentUserId ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            poll.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Ping AR + LT',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...List.generate(poll.options.length, (index) {
            final option = poll.options[index];
            final percentage = option.getPercentage(poll.totalVotes);
            return _buildPollOption(
              context, 
              option, 
              percentage, 
              index, 
              hasVoted,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPollOption(
    BuildContext context,
    StoryPollOption option,
    double percentage,
    int index,
    bool hasVoted,
  ) {
    return GestureDetector(
      onTap: hasVoted ? null : () => onVote(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          children: [
            // Background progress
            if (hasVoted)
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                width: MediaQuery.of(context).size.width * (percentage / 100),
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF9A46D7).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            
            // Option container
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF9A46D7),
                  width: 2,
                ),
                color: hasVoted ? Colors.transparent : Colors.black.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      option.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Ping AR + LT',
                      ),
                    ),
                  ),
                  if (hasVoted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9A46D7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Ping AR + LT',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Reaction Button
class _EnhancedReactionButton extends StatelessWidget {
  final ValueChanged<StoryReactionType> onSelected;
  
  const _EnhancedReactionButton({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showReactionPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'إعجاب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر تفاعلك',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Ping AR + LT',
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              children: StoryReactionType.values.map((type) {
                return GestureDetector(
                  onTap: () {
                    onSelected(type);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      type.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// Enhanced Insights Sheet
class _EnhancedInsightsSheet extends StatelessWidget {
  final Story story;
  final StoryItem storyItem;

  const _EnhancedInsightsSheet({
    required this.story,
    required this.storyItem,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'إحصائيات القصة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Ping AR + LT',
                    ),
                  ),
                ),
                
                // Stats overview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Consumer<StorySettingsProvider>(
                        builder: (context, settings, child) {
                          return _buildStatCard(
                            icon: Icons.visibility_outlined,
                            label: 'المشاهدات',
                            value: settings.showViewCount ? storyItem.viewedBy.length : null,
                            color: const Color(0xFF9A46D7),
                          );
                        },
                      ),
                      Consumer<StorySettingsProvider>(
                        builder: (context, settings, child) {
                          return _buildStatCard(
                            icon: Icons.favorite_border,
                            label: 'التفاعلات',
                            value: settings.showReactions ? storyItem.reactions.length : null,
                            color: Colors.pink,
                          );
                        },
                      ),
                      _buildStatCard(
                        icon: Icons.share_outlined,
                        label: 'المشاركات',
                        value: storyItem.shareCount,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Detailed insights
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          indicatorColor: const Color(0xFF9A46D7),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(fontFamily: 'Ping AR + LT'),
                          tabs: const [
                            Tab(text: 'المشاهدات'),
                            Tab(text: 'التفاعلات'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildViewersTab(),
                              _buildReactionsTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int? value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value != null ? value.toString() : '--',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Ping AR + LT',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Ping AR + LT',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewersTab() {
    final viewerIds = storyItem.viewedBy
        .where((id) => id != story.userId)
        .toList();

    if (viewerIds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'لا توجد مشاهدات حتى الآن',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<AppUser>>(
      future: UserService().getUsers(viewerIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF9A46D7)),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'لا يمكن تحميل بيانات المشاهدين',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          );
        }

        final viewers = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viewers.length,
          itemBuilder: (context, index) {
            final viewer = viewers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: viewer.userImage.isNotEmpty
                        ? CachedNetworkImageProvider(viewer.userImage)
                        : null,
                    child: viewer.userImage.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    viewer.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Ping AR + LT',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReactionsTab() {
    if (storyItem.reactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'لا توجد تفاعلات حتى الآن',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontFamily: 'Ping AR + LT',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: storyItem.reactions.length,
      itemBuilder: (context, index) {
        final reaction = storyItem.reactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: reaction.userImage.isNotEmpty
                    ? CachedNetworkImageProvider(reaction.userImage)
                    : null,
                child: reaction.userImage.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                reaction.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Ping AR + LT',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reaction.type.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// More Options Sheet
class _MoreOptionsSheet extends StatefulWidget {
  final String storyId;
  final String storyUserId;
  final StoryItem storyItem;
  final bool isAuthor;

  const _MoreOptionsSheet({
    required this.storyId,
    required this.storyUserId,
    required this.storyItem,
    required this.isAuthor,
  });

  @override
  State<_MoreOptionsSheet> createState() => _MoreOptionsSheetState();
}

class _MoreOptionsSheetState extends State<_MoreOptionsSheet> {
  final StoryService _storyService = StoryService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              'خيارات إضافية',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Ping AR + LT',
              ),
            ),
            const SizedBox(height: 20),
            
            if (!widget.isAuthor) ...[
              _buildOption(
                icon: Icons.bookmark_outline,
                title: 'حفظ القصة',
                onTap: _busy ? null : () => _bookmarkStory(context),
              ),
              _buildOption(
                icon: Icons.report_outlined,
                title: 'الإبلاغ عن القصة',
                onTap: _busy ? null : () => _showReportDialogFromOptions(context),
              ),
              _buildOption(
                icon: Icons.visibility_off_outlined,
                title: 'إخفاء قصص المستخدم',
                onTap: _busy ? null : () => _hideUserStories(context),
              ),
            ],
            
            if (widget.isAuthor) ...[
              _buildOption(
                icon: Icons.delete_outline,
                title: 'حذف القصة',
                onTap: _busy ? null : () => _deleteStory(context),
                isDestructive: true,
              ),
            ],
            
            _buildOption(
              icon: Icons.download_outlined,
              title: 'حفظ في المعرض',
              onTap: _busy ? null : () => _saveToGallery(context),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontFamily: 'Ping AR + LT',
        ),
      ),
      onTap: onTap,
    );
  }

  void _showReportDialogFromOptions(BuildContext context) {
    Navigator.pop(context);
    _showReportDialog(context);
  }

  Future<void> _deleteStory(BuildContext context) async {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القصة'),
        content: const Text('هل أنت متأكد من حذف هذه القصة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() { _busy = true; });
              final ok = await _storyService.deleteStoryItem(widget.storyId, widget.storyItem.id);
              if (!mounted) return;
              setState(() { _busy = false; });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'تم حذف القصة' : 'تعذر حذف القصة'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveToGallery(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الحفظ في المعرض'),
        backgroundColor: Color(0xFF9A46D7),
      ),
    );
  }

  Future<void> _bookmarkStory(BuildContext context) async {
    Navigator.pop(context);
    setState(() { _busy = true; });
    final ok = await _storyService.bookmarkStory(widget.storyId, widget.storyItem.id);
    if (!mounted) return;
    setState(() { _busy = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم حفظ القصة' : 'تعذر حفظ القصة'),
        backgroundColor: ok ? const Color(0xFF9A46D7) : Colors.red,
      ),
    );
  }

  void _replyToStory(BuildContext context) {
    Navigator.pop(context);
    _showReplyDialog(context);
  }

  Future<void> _hideUserStories(BuildContext context) async {
    Navigator.pop(context);
    setState(() { _busy = true; });
    final ok = await _storyService.hideUserStories(widget.storyUserId);
    if (!mounted) return;
    setState(() { _busy = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم إخفاء قصص المستخدم' : 'تعذر تنفيذ العملية'),
        backgroundColor: ok ? Colors.orange : Colors.red,
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final TextEditingController replyController = TextEditingController();
    bool sending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text(
              'الرد على القصة',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: replyController,
              decoration: const InputDecoration(
                hintText: 'اكتب ردك هنا...',
                hintStyle: TextStyle(fontFamily: 'Ping AR + LT'),
              ),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Ping AR + LT'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Ping AR + LT'),
                ),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        final text = replyController.text.trim();
                        if (text.isEmpty) return;
                        setState(() => sending = true);
                        final ok = await _storyService.addReply(
                          widget.storyId,
                          widget.storyItem.id,
                          text,
                        );
                        if (!mounted) return;
                        setState(() => sending = false);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'تم إرسال الرد' : 'تعذر إرسال الرد'),
                            backgroundColor: ok ? const Color(0xFF9A46D7) : Colors.red,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A46D7),
                ),
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'إرسال',
                        style: TextStyle(fontFamily: 'Ping AR + LT'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    final List<String> reportReasons = [
      'محتوى غير مناسب',
      'محتوى مسيء',
      'محتوى مزيف',
      'انتهاك خصوصية',
      'أخرى',
    ];

    String selectedReason = reportReasons[0];
    bool sending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text(
              'الإبلاغ عن القصة',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختر سبب الإبلاغ:',
                  style: TextStyle(fontFamily: 'Ping AR + LT'),
                ),
                const SizedBox(height: 16),
                ...reportReasons.map((reason) => RadioListTile<String>(
                  title: Text(
                    reason,
                    style: const TextStyle(fontFamily: 'Ping AR + LT'),
                  ),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setState(() { selectedReason = value!; });
                  },
                  activeColor: const Color(0xFF9A46D7),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(fontFamily: 'Ping AR + LT'),
                ),
              ),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        setState(() { sending = true; });
                        final ok = await _storyService.reportStory(
                          widget.storyId,
                          widget.storyItem.id,
                          selectedReason,
                        );
                        if (!mounted) return;
                        setState(() { sending = false; });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'تم إرسال الإبلاغ' : 'تعذر إرسال الإبلاغ'),
                            backgroundColor: ok ? Colors.green : Colors.red,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'إبلاغ',
                        style: TextStyle(fontFamily: 'Ping AR + LT'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHideUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إخفاء قصص المستخدم',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'هل تريد إخفاء قصص هذا المستخدم من الظهور في المستقبل؟',
          style: TextStyle(fontFamily: 'Ping AR + LT'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement hide user functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إخفاء قصص المستخدم'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text(
              'إخفاء',
              style: TextStyle(fontFamily: 'Ping AR + LT'),
            ),
          ),
        ],
      ),
    );
  }
}
