import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/presentation/pages/create_story_page.dart';
import 'package:sumi/features/story/presentation/pages/my_stories_page.dart';
import 'package:sumi/features/story/presentation/pages/story_viewer_page.dart';
import 'package:sumi/features/story/services/story_service.dart';

class StoriesList extends StatefulWidget {
  const StoriesList({super.key});

  @override
  State<StoriesList> createState() => _StoriesListState();
}

class _StoriesListState extends State<StoriesList> {
  final StoryService _storyService = StoryService();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, // Increased height for the new design
      child: StreamBuilder<List<Story>>(
        stream: _storyService.getStories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final stories = snapshot.data ?? [];
          final otherStories = stories
              .where((s) => s.userId != _storyService.currentUserId)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            scrollDirection: Axis.horizontal,
            children: [
              // My story / Create story item
              _buildMyStoryItem(context),

              // Other stories
              ...otherStories
                  .map((story) => _buildStoryItem(context, story, stories)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          width: 85,
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildMyStoryItem(BuildContext context) {
    return StreamBuilder<List<Story>>(
      stream: _storyService.getMyStories(),
      builder: (context, snapshot) {
        final myStories = snapshot.data ?? [];
        final hasMyStories = myStories.isNotEmpty;

        return GestureDetector(
          onTap: () {
            if (hasMyStories) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyStoriesPage(),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateStoryPage(),
                ),
              );
            }
          },
          child: hasMyStories
              ? _buildMyStoryPreview(context, myStories.first)
              : _buildAddStoryButton(context),
        );
      },
    );
  }

  Widget _buildMyStoryPreview(BuildContext context, Story story) {
    final previewUrl = story.items.isNotEmpty
        ? story.items.first.mediaUrl
        : (story.userImage.isNotEmpty
            ? story.userImage
            : 'https://via.placeholder.com/150'); // Fallback

    return Container(
      width: 85,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: previewUrl,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          const Center(
            child: Text(
              'Your Story',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context) {
    return Container(
      width: 85,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: DottedBorder(
        options: const RoundedRectDottedBorderOptions(
          radius: Radius.circular(12),
          color: Colors.grey,
          strokeWidth: 1.5,
          dashPattern: [6, 4],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 28, color: Colors.grey),
              SizedBox(height: 4),
              Text('Add Story',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryItem(
      BuildContext context, Story story, List<Story> allStories) {
    final hasUnseenItems = story.items
        .any((item) => !item.hasUserSeen(_storyService.currentUserId ?? ''));
    final isVideo =
        story.items.isNotEmpty && story.items.first.mediaType == StoryMediaType.video;
    
    // Use first item's media, fallback to user image if no items or media fails
    final String previewUrl = story.items.isNotEmpty
        ? story.items.first.mediaUrl
        : (story.userImage.isNotEmpty ? story.userImage : 'https://via.placeholder.com/150');

    return GestureDetector(
      onTap: () {
        final userStories =
            allStories.where((s) => s.userId != _storyService.currentUserId).toList();
        final initialIndex = userStories.indexOf(story);
        if (initialIndex != -1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StoryViewerPage(
                stories: userStories,
                initialStoryIndex: initialIndex,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 85,
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnseenItems
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: previewUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, color: Colors.red),
                ),
              ),
              if (isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  story.userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 