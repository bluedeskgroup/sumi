import 'package:flutter/material.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/widgets/post_card.dart';
import 'package:sumi/features/community/services/community_service.dart';

class TrendingPostsSection extends StatelessWidget {
  const TrendingPostsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final CommunityService _communityService = CommunityService();

    return StreamBuilder<List<Post>>(
      stream: _communityService.getTrendingPostsStream(limit: 30), // Increased limit to 30 posts
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Don't show anything if no trending posts
        }

        final trendingPosts = snapshot.data!;

        return Container(
          height: 300, // Increased height to accommodate more posts
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '🔥 الأكثر شهرة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: trendingPosts.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7, // Slightly smaller width for more posts
                      child: PostCard(post: trendingPosts[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}