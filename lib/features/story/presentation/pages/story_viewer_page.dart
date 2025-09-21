import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sumi/features/auth/models/user_model.dart';
import 'package:sumi/features/auth/services/user_service.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart' as timeago;

class StoryViewerPage extends StatefulWidget {
  final List<Story> stories;
  final int initialStoryIndex;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.initialStoryIndex,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _storyController;
  late AnimationController _animationController;
  VideoPlayerController? _videoController;

  final StoryService _storyService = StoryService();
  final UserService _userService = UserService();

  late List<Story> _stories;
  int _currentStoryIndex = 0;
  int _currentPageIndex = 0;
  bool _isPaused = false;
  StreamSubscription? _storySubscription;

  @override
  void initState() {
    super.initState();
    _stories = widget.stories;
    _currentStoryIndex = widget.initialStoryIndex;
    _currentPageIndex = 0;

    _storyController = PageController(initialPage: _currentStoryIndex);
    _animationController = AnimationController(vsync: this);

    _setupInitialStory();

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.stop();
        _animationController.reset();
        _nextPage();
      }
    });
  }

  @override
  void dispose() {
    _storyController.dispose();
    _animationController.dispose();
    _videoController?.dispose();
    _storySubscription?.cancel();
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
          // Find the index of the story that was updated
          final storyIndex = _stories.indexWhere((s) => s.userId == userId);
          if (storyIndex != -1) {
            _stories[storyIndex] = updatedStories.first;
          }
        });
      }
    });
  }

  void _onStoryUserChanged(int index) {
    setState(() {
      _currentStoryIndex = index;
      _currentPageIndex = 0;
      _setupInitialStory();
    });
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
            });
    } else {
      _animationController.duration = const Duration(seconds: 5);
      if (!_isPaused) _animationController.forward();
    }
  }

  void _onReactionSelected(StoryReactionType type) {
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    _storyService.addReaction(story.id, item.id, type);
  }

  void _onCommentAdded(String text) {
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    // This service call is now removed.
    // _storyService.addComment(story.id, item.id, text);
  }

  void _onVote(int optionIndex) {
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    _storyService.voteInPoll(story.id, item.id, optionIndex);
  }

  void _onShare() {
    _pause();
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];

    if (item.allowSharing) {
      // Increment the share count
      _storyService.incrementShareCount(story.id, item.id);
      
      Share.share(
        'Check out this story from Sumi!\n${item.mediaUrl}',
        subject: 'Sumi Story',
      ).whenComplete(() => _resume());
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing is disabled for this story.')),
      );
      _resume();
    }
  }

  void _showInsights() {
    final story = _stories[_currentStoryIndex];
    final item = story.items[_currentPageIndex];
    showModalBottomSheet(
      context: context,
      builder: (context) => _StoryInsightsSheet(storyItem: item),
    );
  }

  void _onTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < screenWidth / 3) {
      _previousPage();
    } else if (dx > screenWidth * 2 / 3) {
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
    return PageView.builder(
      controller: _storyController,
      onPageChanged: _onStoryUserChanged,
      itemCount: _stories.length,
      itemBuilder: (context, storyIndex) {
        final currentStory = _stories[storyIndex];
        if (currentStory.items.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
                child: Text("This user has no stories.",
                    style: TextStyle(color: Colors.white))),
          );
        }
        final currentItem = currentStory.items[
            _currentStoryIndex == storyIndex ? _currentPageIndex : 0];

        return Stack(
          children: [
            _buildStoryView(currentItem),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildHeader(currentStory, currentItem),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFooter(currentItem),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoryView(StoryItem item) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPress: _pause,
        onLongPressUp: _resume,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMedia(item),
            // Add a gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 0.6, 1.0],
                ),
              ),
            ),
          ],
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
      media = CachedNetworkImage(
        imageUrl: item.mediaUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (context, url, error) =>
            const Center(child: Icon(Icons.error, color: Colors.white)),
      );
    } else {
      media = const Center(child: CircularProgressIndicator(color: Colors.white));
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
    return Column(
      children: [
        SafeArea(
          child: Row(
            children: List.generate(
              story.items.length,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) {
                      // Only show animation for the current story user
                      if (story.userId != _stories[_currentStoryIndex].userId) {
                        return LinearProgressIndicator(
                          value: 0,
                          backgroundColor: Colors.white38,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 2,
                        );
                      }
                      return LinearProgressIndicator(
                        value: index < _currentPageIndex
                            ? 1
                            : (index == _currentPageIndex
                                ? _animationController.value
                                : 0),
                        backgroundColor: Colors.white38,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 2,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(story.userImage),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    timeago.format(item.timestamp, locale: 'en_short'),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(StoryItem item) {
    final isAuthor =
        _stories[_currentStoryIndex].userId == _storyService.currentUserId;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.poll != null)
            _PollWidget(poll: item.poll!, onVote: _onVote),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (isAuthor)
                IconButton(
                  onPressed: _showInsights,
                  icon: const Icon(Icons.bar_chart,
                      color: Colors.white, size: 28),
                )
              else
                _ReactionButton(onSelected: _onReactionSelected),
              IconButton(
                onPressed: _onShare,
                icon: const Icon(Icons.share, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryInsightsSheet extends StatelessWidget {
  final StoryItem storyItem;
  final UserService _userService = UserService();

  _StoryInsightsSheet({required this.storyItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Insights',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInsightColumn(Icons.visibility_outlined, 'Views',
                  storyItem.viewedBy.length),
              _buildInsightColumn(
                  Icons.favorite_border, 'Reactions', storyItem.reactions.length),
              _buildInsightColumn(
                  Icons.share_outlined, 'Shares', storyItem.shareCount),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24, indent: 16, endIndent: 16),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Viewers',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          _buildViewersList(),
        ],
      ),
    );
  }

  Widget _buildViewersList() {
    final viewerIds = storyItem.viewedBy
        .where((id) => id != StoryService().currentUserId)
        .toList();

    if (viewerIds.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No one else has viewed this story yet.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return Expanded(
      child: FutureBuilder<List<AppUser>>(
        future: _userService.getUsers(viewerIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('Could not load viewers.',
                    style: TextStyle(color: Colors.white70)));
          }

          final viewers = snapshot.data!;
          return ListView.builder(
            itemCount: viewers.length,
            itemBuilder: (context, index) {
              final viewer = viewers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(viewer.userImage),
                ),
                title: Text(
                  viewer.userName,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInsightColumn(IconData icon, String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

// Breaking down UI into smaller, manageable widgets

class _ReactionButton extends StatelessWidget {
  final ValueChanged<StoryReactionType> onSelected;
  const _ReactionButton({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StoryReactionType>(
      onSelected: onSelected,
      itemBuilder: (context) => StoryReactionType.values.map((type) {
        return PopupMenuItem(
          value: type,
          child: Text(type.emoji, style: const TextStyle(fontSize: 24)),
        );
      }).toList(),
      child: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
    );
  }
}

class _PollWidget extends StatelessWidget {
  final StoryPoll poll;
  final ValueChanged<int> onVote;
  final StoryService _storyService = StoryService();

  _PollWidget({required this.poll, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.hasUserVoted(_storyService.currentUserId ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            poll.question,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ...List.generate(poll.options.length, (index) {
            final option = poll.options[index];
            final percentage = option.getPercentage(poll.totalVotes);
            return GestureDetector(
              onTap: hasVoted ? null : () => onVote(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    if (hasVoted)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width:
                            MediaQuery.of(context).size.width * (percentage / 100),
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(102),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(option.text,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                          if (hasVoted)
                            Text('${percentage.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
} 