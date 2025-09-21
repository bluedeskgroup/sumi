import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/widgets/post_card.dart';
import 'package:sumi/features/community/services/community_service.dart';
import 'package:flutter/material.dart';

class FeaturedPostsSection extends StatelessWidget {
  const FeaturedPostsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final CommunityService _communityService = CommunityService();

    return StreamBuilder<List<Post>>(
      stream: _communityService.getFeaturedPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Don't show anything if no featured posts
        }

        final featuredPosts = snapshot.data!;

        return Container(
          height: 250, // Adjust height as needed
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '🌟 منشورات مميزة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredPosts.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: PostCard(post: featuredPosts[index]),
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