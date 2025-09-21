import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sumi/features/auth/models/user_model.dart';
import 'package:sumi/features/auth/services/user_service.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/story/presentation/pages/create_story_page.dart';
import 'package:sumi/features/story/presentation/pages/story_viewer_page.dart';
import 'package:sumi/features/story/services/story_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyStoriesPage extends StatefulWidget {
  const MyStoriesPage({super.key});

  @override
  MyStoriesPageState createState() => MyStoriesPageState();
}

class MyStoriesPageState extends State<MyStoriesPage> {
  final StoryService _storyService = StoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stories'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateStoryPage()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Story>>(
        stream: _storyService.getMyStories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final story = snapshot.data!.first;
          final storyItems = story.items;

          return AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 9 / 16,
              ),
              itemCount: storyItems.length,
              itemBuilder: (context, index) {
                final item = storyItems[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _StoryAnalyticsCard(
                        story: story,
                        storyItem: item,
                        onView: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoryViewerPage(
                                stories: snapshot.data!,
                                initialStoryIndex: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined,
              size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'You have no active stories.',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create a story to share it with your friends.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Create a Story'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateStoryPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryAnalyticsCard extends StatelessWidget {
  final Story story;
  final StoryItem storyItem;
  final VoidCallback onView;

  const _StoryAnalyticsCard({
    required this.story,
    required this.storyItem,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media preview
            CachedNetworkImage(
              imageUrl: storyItem.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[300]),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error)),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Content
            _buildCardContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final timeRemaining = storyItem.timestamp
        .add(const Duration(hours: 24))
        .difference(DateTime.now());
    final isExpired = timeRemaining.isNegative;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildDeleteButton(context),
            ],
          ),
          // Bottom section: Stats
          _buildStatsRow(context, isExpired),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Story'),
            content:
                const Text('Are you sure you want to delete this story item?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm ?? false) {
          await StoryService().deleteStoryItem(story.id, storyItem.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isExpired) {
    return GestureDetector(
      onTap: () => _showInsightsSheet(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isExpired
                ? 'Expired'
                : 'Expires in ${timeago.format(DateTime.now().add(storyItem.timestamp.add(const Duration(hours: 24)).difference(DateTime.now())))}',
            style: TextStyle(
                color: isExpired ? Colors.redAccent : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(storyItem.viewCount.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              const Icon(Icons.favorite_border, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(storyItem.reactions.length.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14)
            ],
          ),
        ],
      ),
    );
  }

  void _showInsightsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
            child: DefaultTabController(
              length: storyItem.poll != null ? 3 : 2,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Insights',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  TabBar(
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: [
                      const Tab(text: 'Views'),
                      const Tab(text: 'Reactions'),
                      if (storyItem.poll != null) const Tab(text: 'Poll'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ViewsTab(
                            viewedBy: storyItem.viewedBy
                                .where((id) => id != story.userId)
                                .toList()),
                        _ReactionsTab(reactions: storyItem.reactions),
                        if (storyItem.poll != null)
                          _PollResultsTab(poll: storyItem.poll!),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ViewsTab extends StatelessWidget {
  final List<String> viewedBy;
  final UserService _userService = UserService();

  _ViewsTab({required this.viewedBy});

  @override
  Widget build(BuildContext context) {
    if (viewedBy.isEmpty) {
      return const Center(child: Text('No other viewers yet.'));
    }
    return FutureBuilder<List<AppUser>>(
      future: _userService.getUsers(viewedBy),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final viewers = snapshot.data!;
        return ListView.builder(
          itemCount: viewers.length,
          itemBuilder: (context, index) {
            final viewer = viewers[index];
            return ListTile(
              leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(viewer.userImage)),
              title: Text(viewer.userName),
            );
          },
        );
      },
    );
  }
}

class _ReactionsTab extends StatelessWidget {
  final List<StoryReaction> reactions;
  const _ReactionsTab({required this.reactions});

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const Center(child: Text('No reactions yet.'));

    return ListView.builder(
      itemCount: reactions.length,
      itemBuilder: (context, index) {
        final reaction = reactions[index];
        return ListTile(
          leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(reaction.userImage)),
          title: Text(reaction.userName),
          trailing:
              Text(reaction.type.emoji, style: const TextStyle(fontSize: 24)),
        );
      },
    );
  }
}

class _PollResultsTab extends StatelessWidget {
  final StoryPoll poll;
  const _PollResultsTab({required this.poll});

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.totalVotes;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poll.question,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: poll.options.length,
              itemBuilder: (context, index) {
                final option = poll.options[index];
                final percentage = option.getPercentage(totalVotes);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${option.text} (${option.votes.length} votes)'),
                          Text('${percentage.toStringAsFixed(1)}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 