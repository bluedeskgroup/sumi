import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sumi/features/story/models/story_model.dart';
import 'package:sumi/features/video/services/advanced_video_cache_service.dart';
import 'package:sumi/features/video/services/video_cache_service.dart';

class DataPrefetchService {
  static bool _persistenceConfigured = false;

  /// Enable Firestore offline persistence and enlarge cache to reduce network hits
  static Future<void> enableFirestorePersistence() async {
    if (_persistenceConfigured) return;
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      _persistenceConfigured = true;
      debugPrint('Firestore persistence enabled with unlimited cache');
    } catch (e) {
      debugPrint('Failed to enable Firestore persistence: $e');
    }
  }

  /// Warm critical queries and caches across the app in parallel.
  /// This primes the local persistence so subsequent screens render instantly.
  static Future<void> prefetchCriticalData() async {
    try {
      final List<Future<void>> tasks = [];

      // Prefetch posts (latest) and authors/media
      tasks.add(_prefetchPostsAndAuthors());

      // Prefetch featured posts snapshot into cache
      tasks.add(_prefetchCollection(
        FirebaseFirestore.instance
            .collection('posts')
            .where('isFeatured', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(30),
      ));

      // Prefetch stories within last 24h and warm thumbnails for videos
      tasks.add(_prefetchStoriesAndThumbnails());

      // Prefetch store products and categories
      tasks.add(_prefetchCollection(
        FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .limit(60),
      ));
      tasks.add(_prefetchCollection(
        FirebaseFirestore.instance
            .collection('categories')
            .where('type', isEqualTo: 'product')
            .where('isActive', isEqualTo: true)
            .orderBy('displayOrder')
            .limit(100),
      ));

      // Optionally prefetch current user doc
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        tasks.add(FirebaseFirestore.instance.collection('users').doc(uid).get().then((_) {}));
      }

      // Prefetch comments for recent posts (lightweight cap)
      tasks.add(_prefetchCommentsForRecentPosts());

      await Future.wait(tasks);
      debugPrint('Data prefetch complete');
    } catch (e) {
      debugPrint('Data prefetch encountered an error: $e');
    }
  }

  static Future<void> _prefetchCollection(Query query) async {
    try {
      await query.get();
    } catch (e) {
      debugPrint('Prefetch query failed: $e');
    }
  }

  static Future<void> _prefetchStoriesAndThumbnails() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .where('lastUpdated', isGreaterThan: Timestamp.fromDate(cutoff))
          .orderBy('lastUpdated', descending: true)
          .limit(60)
          .get();

      // Warm thumbnails for first item of each story if video
      final advancedCache = AdvancedVideoCacheService();
      await advancedCache.initialize();

      for (final doc in snapshot.docs) {
        try {
          final story = Story.fromFirestore(doc);
          if (story.items.isNotEmpty) {
            final first = story.items.first;
            if (first.mediaType == StoryMediaType.video) {
              advancedCache.precacheThumbnail(first.mediaUrl);
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Prefetch stories failed: $e');
    }
  }

  static Future<void> _prefetchPostsAndAuthors() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(60);
      final snapshot = await query.get();

      // Warm author docs and profile images + post thumbnails
      final videoCache = VideoCacheService();
      await videoCache.initialize();

      final Set<String> authorIds = {};
      final Set<String> imageUrls = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final uid = data['userId'] as String?;
        final userImage = data['userImage'] as String?;
        final thumbnailUrl = data['thumbnailUrl'] as String?;

        if (uid != null && uid.isNotEmpty) authorIds.add(uid);
        if (userImage != null && userImage.isNotEmpty) imageUrls.add(userImage);
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) imageUrls.add(thumbnailUrl);
      }

      // Fetch author docs in parallel (batched by default client)
      await Future.wait(authorIds.map((uid) => FirebaseFirestore.instance.collection('users').doc(uid).get().then((_) {})));

      // Cache images locally
      await Future.wait(imageUrls.map((url) => videoCache.downloadAndCacheThumbnail(url).then((_) {})));
    } catch (e) {
      debugPrint('Prefetch posts/authors failed: $e');
    }
  }

  static Future<void> _prefetchCommentsForRecentPosts() async {
    try {
      final posts = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      // Prefetch up to 20 comments for each recent post
      await Future.wait(posts.docs.map((post) async {
        try {
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(post.id)
              .collection('comments')
              .orderBy('createdAt', descending: false)
              .limit(20)
              .get();
        } catch (_) {}
      }));
    } catch (e) {
      debugPrint('Prefetch comments failed: $e');
    }
  }
}


