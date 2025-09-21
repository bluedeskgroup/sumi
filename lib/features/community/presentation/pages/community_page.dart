import 'package:flutter/material.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/presentation/pages/create_post_page.dart';
import 'package:sumi/features/community/presentation/widgets/featured_posts_section.dart';
import 'package:sumi/features/community/presentation/widgets/trending_posts_section.dart';
import 'package:sumi/features/community/presentation/widgets/post_card.dart';
import 'package:sumi/features/community/services/community_service.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CommunityService _communityService = CommunityService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجتمع'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const CreatePostPage(),
              ));
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: const [
                  FeaturedPostsSection(),
                  TrendingPostsSection(), // Add trending posts section
                ],
              ),
            ),
          ];
        },
        body: StreamBuilder<List<Post>>(
          stream: _communityService.getPostsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('كن أول من يضيف منشورًا!'));
            }

            // Filter out featured posts from the main list to avoid duplication
            final posts = snapshot.data!.where((post) => !post.isFeatured).toList();

            if (posts.isEmpty) {
               return const Center(child: Text('لا توجد منشورات عادية حاليًا.'));
            }

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostCard(post: posts[index], heroTagPrefix: 'community_');
              },
            );
          },
        ),
      ),
    );
  }
}