import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sumi/core/helpers/search_helpers.dart';
import 'package:sumi/features/community/models/post_model.dart';
import 'package:sumi/features/community/services/hashtag_service.dart';
import 'package:uuid/uuid.dart';

import '../../auth/models/user_model.dart';
import 'package:sumi/features/notifications/models/notification_model.dart';
import 'package:sumi/features/video/models/watch_progress_model.dart';
import 'package:sumi/features/video/models/video_rating_model.dart';

class PaginatedPostsResult {
  final List<Post> posts;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  PaginatedPostsResult({
    required this.posts,
    this.lastDocument,
    required this.hasMore,
  });
}

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> _handleFirebaseOperation({
    required Future<void> Function() operation,
    required String errorMessage,
  }) async {
    try {
      await operation();
    } on FirebaseException catch (e) {
      throw Exception('$errorMessage: ${e.message}');
    } catch (e) {
      throw Exception('$errorMessage: ${e.toString()}');
    }
  }

  Future<void> createUserProfile(User user) async {
    final keywords = generateKeywords(user.displayName ?? '');
    await _handleFirebaseOperation(
      operation: () async {
        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'userName': user.displayName ?? 'مستخدم جديد',
          'userImage': user.photoURL ?? '', // Leave empty if no photo exists
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'searchKeywords': keywords,
          'subscribers': [],
          'subscriptions': [],
        }, SetOptions(merge: true));
      },
      errorMessage: 'فشل إنشاء ملف المستخدم',
    );
  }

  // Private helper to create a notification
  Future<void> _createNotification({
    required String recipientId,
    required NotificationType type,
    required String referenceId,
    String? contentSnippet,
  }) async {
    final currentUser = _auth.currentUser;
    // Don't send notifications for actions performed by the user on their own content
    if (currentUser == null || currentUser.uid == recipientId) {
      return;
    }

    final notificationRef = _firestore
        .collection('users')
        .doc(recipientId)
        .collection('notifications')
        .doc(); // Auto-generate ID

    final notification = AppNotification(
      id: notificationRef.id,
      recipientId: recipientId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName ?? 'مستخدم سومي',
      senderImageUrl: currentUser.photoURL,
      type: type,
      referenceId: referenceId,
      contentSnippet: contentSnippet,
      isRead: false,
      createdAt: Timestamp.now(),
    );

    await notificationRef.set(notification.toFirestore());
  }


  Future<void> createPost({
    required String content,
    required List<File> media,
    required PostType type,
    bool isFeatured = false,
    int? videoDurationSeconds,
    // ميزات الفيديو المحسنة
    String? videoTitle,
    String? videoDescription,
    String? originalVideoSize,
    String? compressedVideoSize,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }
      List<String> mediaUrls = [];
    String? thumbnailUrl;
    final postId = const Uuid().v4();
    final hashtagService = HashtagService();

      if (media.isNotEmpty) {
      for (int i = 0; i < media.length; i++) {
        final file = media[i];
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${i}_${file.path.split('/').last}';
        final ref = _storage.ref().child('posts/$postId/$fileName');
        final uploadTask = await ref.putFile(file);
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          
          // الملف الأول هو الفيديو، الثاني هو الصورة المصغرة (إن وجدت)
          if (i == 0) {
            mediaUrls.add(downloadUrl);
          } else if (i == 1 && type == PostType.video) {
            thumbnailUrl = downloadUrl;
          } else {
            mediaUrls.add(downloadUrl);
          }
        }
      }

    final keywords = generateKeywords(content);
    // استخراج الهاشتاجات باستخدام خدمة الهاشتاجات
    final hashtags = hashtagService.extractHashtags(content);

    final postData = {
      'id': postId,
        'userId': currentUserId!,
      'userName': _auth.currentUser?.displayName ?? 'مستخدم سومي',
      'userImage': _auth.currentUser?.photoURL ?? 'assets/images/logo.png',
        'content': content,
        'mediaUrls': mediaUrls,
        'type': type.name,
        'likes': [],
        'dislikes': [],
        'commentCount': 0,
        'viewCount': 0,
        'completionCount': 0,
        'averageRating': 0.0,
        'totalRatings': 0,
        'videoDurationSeconds': videoDurationSeconds,
      'createdAt': FieldValue.serverTimestamp(),
        'isFeatured': isFeatured,
        'hashtags': hashtags,
      'searchKeywords': keywords,
      'subscribers': [],
      'subscriptions': [],
      // ميزات الفيديو المحسنة
      'videoTitle': videoTitle,
      'videoDescription': videoDescription,
      'thumbnailUrl': thumbnailUrl,
      'originalVideoSize': originalVideoSize,
      'compressedVideoSize': compressedVideoSize,
      };

    await _handleFirebaseOperation(
      operation: () async {
        await _firestore.collection('posts').doc(postId).set(postData);
        
        // حفظ الهاشتاغات في خدمة الهاشتاجات
        if (hashtags.isNotEmpty) {
          await hashtagService.saveHashtags(hashtags, postId);
        }
      },
      errorMessage: 'فشل إضافة المنشور',
    );
  }

  Future<void> togglePostLike(String postId) async {
    if (currentUserId == null) return;
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) {
        throw Exception("Post does not exist!");
      }
      List<String> likes =
          List<String>.from(snapshot.data()!['likes'] ?? []);
      if (likes.contains(currentUserId)) {
        likes.remove(currentUserId);
      } else {
        likes.add(currentUserId!);
        }
      transaction.update(postRef, {'likes': likes});

      if (likes.contains(currentUserId)) {
        // If the like was added, create a notification
        final postData = snapshot.data() as Map<String, dynamic>;
        await _createNotification(
          recipientId: postData['userId'],
          type: NotificationType.newLike,
          referenceId: postId,
        );
      }
    });
    }
    
  Future<void> togglePostDislike(String postId) async {
    if (currentUserId == null) return;
    final postRef = _firestore.collection('posts').doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) {
        throw Exception("Post does not exist!");
      }
      List<String> dislikes =
          List<String>.from(snapshot.data()!['dislikes'] ?? []);
      if (dislikes.contains(currentUserId)) {
        dislikes.remove(currentUserId);
      } else {
        dislikes.add(currentUserId!);
      }
      transaction.update(postRef, {'dislikes': dislikes});
    });
  }

  Future<void> toggleSubscription(String targetUserId) async {
    if (currentUserId == null) return;
    if (currentUserId == targetUserId) return; // Can't subscribe to yourself

    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);

    await _firestore.runTransaction((transaction) async {
      final currentUserSnapshot = await transaction.get(currentUserRef);
      final targetUserSnapshot = await transaction.get(targetUserRef);

      if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
        throw Exception("User does not exist!");
      }

      // Update current user's subscriptions
      List<String> subscriptions = List<String>.from(currentUserSnapshot.data()!['subscriptions'] ?? []);
      if (subscriptions.contains(targetUserId)) {
        subscriptions.remove(targetUserId);
      } else {
        subscriptions.add(targetUserId);
        await _createNotification(
          recipientId: targetUserId,
          type: NotificationType.newFollower,
          referenceId: currentUserId!,
        );
      }
      transaction.update(currentUserRef, {'subscriptions': subscriptions});

      // Update target user's subscribers
      List<String> subscribers = List<String>.from(targetUserSnapshot.data()!['subscribers'] ?? []);
       if (subscribers.contains(currentUserId)) {
        subscribers.remove(currentUserId);
      } else {
        subscribers.add(currentUserId!);
      }
      transaction.update(targetUserRef, {'subscribers': subscribers});
    });
  }

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    
    final commentId = const Uuid().v4();
    final commentData = {
      'id': commentId,
      'postId': postId,
      'userId': user.uid,
      'userName': user.displayName,
      'userImage': user.photoURL,
        'content': content,
      'reactions': <String, List<String>>{},
        'createdAt': FieldValue.serverTimestamp(),
    };

    final postRef = _firestore.collection('posts').doc(postId);
    final postSnapshot = await postRef.get();
    final postOwnerId = (postSnapshot.data() as Map<String, dynamic>)['userId'];


    await _handleFirebaseOperation(
      operation: () async {
        await postRef.collection('comments').doc(commentId).set(commentData);
        await postRef.update({'commentCount': FieldValue.increment(1)});
        
        await _createNotification(
          recipientId: postOwnerId,
          type: NotificationType.newComment,
          referenceId: postId,
          contentSnippet: content,
        );
      },
      errorMessage: 'فشل إضافة التعليق',
    );
  }

  Future<void> toggleCommentReaction(String postId, String commentId, String reaction) async {
    if (currentUserId == null) return;
    
    final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
        .doc(commentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(commentRef);
      if (!snapshot.exists) {
        throw Exception("Comment does not exist!");
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
      final Map<String, List<String>> reactions = {};
       reactionsData.forEach((key, value) {
        if (value is List) {
          reactions[key] = List<String>.from(value);
        }
      });
      
      String? userPreviousReaction;
      
      // إزالة أي تفاعل سابق للمستخدم
      reactions.forEach((reac, userIds) {
        if (userIds.contains(currentUserId)) {
          userPreviousReaction = reac;
          userIds.remove(currentUserId);
        }
      });
      
      // إزالة المفاتيح الفارغة
      reactions.removeWhere((key, value) => value.isEmpty);
      
      // إضافة التفاعل الجديد إذا لم يكن هو نفسه التفاعل السابق
      if (userPreviousReaction != reaction) {
        if (reactions.containsKey(reaction)) {
          reactions[reaction]!.add(currentUserId!);
      } else {
          reactions[reaction] = [currentUserId!];
        }
      }

      transaction.update(commentRef, {'reactions': reactions});
    });
  }

  /// Returns a stream of paginated posts, ready for a StreamBuilder.
  Stream<List<Post>> getPostsStream({String? category}) {
    Query query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('type', isEqualTo: category);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  /// Returns a stream of featured posts, perfect for a dedicated section.
  Stream<List<Post>> getFeaturedPostsStream({int limit = 10}) {
    return _firestore
        .collection('posts')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }


  Future<List<Post>> getCommunityPosts() async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    }

  Future<Post?> getPost(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (doc.exists) {
      return Post.fromFirestore(doc);
    }
    return null;
  }



  Future<List<Post>> getFeaturedPosts({String? category}) async {
    Query query = _firestore
        .collection('posts')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('type', isEqualTo: category);
      }
      
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }

  Future<List<Post>> getPosts({String? category, int? limit}) async {
    Query query = _firestore.collection('posts').orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('type', isEqualTo: category);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }

  Future<PaginatedPostsResult> getPostsWithPagination({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? category,
  }) async {
    Query query =
        _firestore.collection('posts').orderBy('createdAt', descending: true).limit(limit);

    if (category != null) {
      query = query.where('type', isEqualTo: category);
      }
      
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();

    return PaginatedPostsResult(
      posts: posts,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: posts.length == limit,
    );
  }

  Future<List<Post>> searchPosts(String query) async {
    if (query.trim().isEmpty) return [];

    final searchTerms = query.trim().toLowerCase().split(RegExp(r'\\s+'));
    final limitedSearchTerms =
        searchTerms.length > 10 ? searchTerms.sublist(0, 10) : searchTerms;

    final snapshot = await _firestore
        .collection('posts')
        .where('searchKeywords', arrayContainsAny: limitedSearchTerms)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  }

  Future<bool> deletePost(String postId) async {
    if (currentUserId == null) {
      throw Exception('يجب تسجيل الدخول لحذف المنشور');
    }
    
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await postRef.get();
      
      if (!postDoc.exists) {
        throw Exception('المنشور غير موجود');
      }
      
      if (postDoc.data()?['userId'] != currentUserId) {
        throw Exception('لا يمكنك حذف منشور شخص آخر');
      }
      
      final postData = postDoc.data() as Map<String, dynamic>;
      final hashtags = List<String>.from(postData['hashtags'] ?? []);
      
      // Delete hashtags from hashtag service
      if (hashtags.isNotEmpty) {
        final hashtagService = HashtagService();
        await hashtagService.deletePostHashtags(postId, hashtags);
      }
      
      // Delete comments subcollection
      final commentsSnapshot = await postRef.collection('comments').get();
      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete media from storage
      final mediaUrls = List<String>.from(postDoc.data()?['mediaUrls'] ?? []);
      for (final url in mediaUrls) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (e) {
          // It's okay if media deletion fails, maybe the file was already deleted.
          // We can log this for debugging but it shouldn't stop the process.
        }
      }
      
      // Delete post document
      await postRef.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<AppUser?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  /// زيادة عدد المشاهدات للمنشور
  Future<void> incrementViewCount(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // يمكن تجاهل الخطأ إذا فشل في زيادة عدد المشاهدات
      // لأنه ليس أمر حرج للتطبيق
      print('فشل في زيادة عدد المشاهدات: $e');
    }
  }

  /// الحصول على فيديوهات مقترحة بناء على خوارزمية ذكية
  Future<List<Post>> getSuggestedVideos({
    required String currentVideoId,
    String? currentUserId,
    int limit = 10,
  }) async {
    try {
      // خوارزمية الاقتراحات:
      // 1. فيديوهات من نفس المؤلف
      // 2. فيديوهات ذات إعجابات مشابهة
      // 3. فيديوهات رائجة حديثاً
      
      // أولاً: احصل على الفيديو الحالي لمعرفة تفاصيله
      final currentVideoDoc = await _firestore.collection('posts').doc(currentVideoId).get();
      if (!currentVideoDoc.exists) {
        return await _getDefaultVideoSuggestions(limit);
      }
      
      final currentVideoData = currentVideoDoc.data() as Map<String, dynamic>;
      final currentVideoUserId = currentVideoData['userId'];
      
      // احصل على فيديوهات من نفس المؤلف
      final sameAuthorQuery = await _firestore
          .collection('posts')
          .where('type', isEqualTo: 'video')
          .where('userId', isEqualTo: currentVideoUserId)
          .orderBy('viewCount', descending: true)
          .limit(3)
          .get();
      
      List<Post> suggestions = sameAuthorQuery.docs
          .where((doc) => doc.id != currentVideoId)
          .map((doc) => Post.fromFirestore(doc))
          .toList();
      
      // إذا لم نصل للحد المطلوب، احصل على فيديوهات رائجة
      if (suggestions.length < limit) {
        final trendingQuery = await _firestore
            .collection('posts')
            .where('type', isEqualTo: 'video')
            .orderBy('viewCount', descending: true)
            .limit(limit * 2) // احصل على ضعف العدد للفلترة
            .get();
        
        final trendingVideos = trendingQuery.docs
            .where((doc) => doc.id != currentVideoId && 
                   !suggestions.any((s) => s.id == doc.id))
            .map((doc) => Post.fromFirestore(doc))
            .take(limit - suggestions.length)
            .toList();
        
        suggestions.addAll(trendingVideos);
      }
      
      return suggestions;
    } catch (e) {
      print('خطأ في الحصول على الاقتراحات: $e');
      return await _getDefaultVideoSuggestions(limit);
    }
  }

  /// الحصول على اقتراحات افتراضية عند فشل الخوارزمية الذكية
  Future<List<Post>> _getDefaultVideoSuggestions(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('type', isEqualTo: 'video')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  /// حفظ أو تحديث تقدم مشاهدة الفيديو
  Future<void> updateWatchProgress({
    required String postId,
    required int watchedSeconds,
    required int totalDurationSeconds,
  }) async {
    if (currentUserId == null) return;

    try {
      final watchPercentage = WatchProgress.calculateWatchPercentage(watchedSeconds, totalDurationSeconds);
      final isCompleted = WatchProgress.isVideoCompleted(watchPercentage);
      
      final progressId = '${currentUserId}_$postId'; // ID مركب للمستخدم والفيديو
      
      final progressData = {
        'userId': currentUserId,
        'postId': postId,
        'watchedSeconds': watchedSeconds,
        'totalDurationSeconds': totalDurationSeconds,
        'watchPercentage': watchPercentage,
        'lastWatchedAt': FieldValue.serverTimestamp(),
        'isCompleted': isCompleted,
      };

      await _firestore
          .collection('watch_progress')
          .doc(progressId)
          .set(progressData, SetOptions(merge: true));
      
      // إذا اكتمل الفيديو لأول مرة، أضف إلى إحصائيات الإكمال
      if (isCompleted) {
        await _firestore.collection('posts').doc(postId).update({
          'completionCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('خطأ في حفظ تقدم المشاهدة: $e');
    }
  }

  /// الحصول على تقدم مشاهدة فيديو معين للمستخدم الحالي
  Future<WatchProgress?> getWatchProgress(String postId) async {
    if (currentUserId == null) return null;

    try {
      final progressId = '${currentUserId}_$postId';
      final doc = await _firestore
          .collection('watch_progress')
          .doc(progressId)
          .get();

      if (doc.exists) {
        return WatchProgress.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب تقدم المشاهدة: $e');
      return null;
    }
  }

  /// الحصول على قائمة الفيديوهات التي شاهدها المستخدم جزئياً
  Future<List<WatchProgress>> getRecentWatchHistory({int limit = 20}) async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('watch_progress')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('lastWatchedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => WatchProgress.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب تاريخ المشاهدة: $e');
      return [];
    }
  }

  /// الحصول على فيديوهات مقترحة محسنة بناءً على تاريخ المشاهدة
  Future<List<Post>> getEnhancedSuggestedVideos({
    required String currentVideoId,
    String? currentUserId,
    int limit = 10,
  }) async {
    try {
      List<Post> suggestions = [];
      
      // 1. إذا كان المستخدم مسجل دخول، احصل على اقتراحات بناءً على تاريخه
      if (currentUserId != null) {
        final watchHistory = await getRecentWatchHistory(limit: 50);
        final watchedPostIds = watchHistory.map((w) => w.postId).toSet();
        
        // احصل على فيديوهات من مؤلفين شاهد المستخدم فيديوهاتهم
        final authorIds = <String>{};
        for (final watchProgress in watchHistory.take(10)) {
          final post = await getPost(watchProgress.postId);
          if (post != null) {
            authorIds.add(post.userId);
          }
        }
        
        // فيديوهات من المؤلفين المفضلين
        for (final authorId in authorIds.take(3)) {
          final authorVideos = await _firestore
              .collection('posts')
              .where('type', isEqualTo: 'video')
              .where('userId', isEqualTo: authorId)
              .orderBy('viewCount', descending: true)
              .limit(2)
              .get();
          
          final videos = authorVideos.docs
              .where((doc) => doc.id != currentVideoId && !watchedPostIds.contains(doc.id))
              .map((doc) => Post.fromFirestore(doc))
              .toList();
          
          suggestions.addAll(videos);
        }
      }
      
      // 2. أضف فيديوهات رائجة إذا لم نصل للحد المطلوب
      if (suggestions.length < limit) {
        final trendingVideos = await _firestore
            .collection('posts')
            .where('type', isEqualTo: 'video')
            .orderBy('viewCount', descending: true)
            .limit(limit * 2)
            .get();
        
        final additionalVideos = trendingVideos.docs
            .where((doc) => doc.id != currentVideoId && 
                   !suggestions.any((s) => s.id == doc.id))
            .map((doc) => Post.fromFirestore(doc))
            .take(limit - suggestions.length)
            .toList();
        
        suggestions.addAll(additionalVideos);
      }
      
      return suggestions.take(limit).toList();
    } catch (e) {
      print('خطأ في الحصول على الاقتراحات المحسنة: $e');
      return await _getDefaultVideoSuggestions(limit);
    }
  }

  /// إضافة أو تحديث تقييم فيديو
  Future<void> rateVideo({
    required String postId,
    required int rating,
  }) async {
    if (currentUserId == null) return;
    if (rating < 1 || rating > 5) return;

    try {
      final ratingId = '${currentUserId}_$postId';
      
      // احصل على التقييم السابق إن وجد
      final oldRatingDoc = await _firestore
          .collection('video_ratings')
          .doc(ratingId)
          .get();
      
      final oldRating = oldRatingDoc.exists ? 
          (oldRatingDoc.data()!['rating'] as int? ?? 0) : 0;
      
      // احفظ التقييم الجديد
      final ratingData = {
        'userId': currentUserId,
        'postId': postId,
        'rating': rating,
        'createdAt': oldRatingDoc.exists ? 
            oldRatingDoc.data()!['createdAt'] : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('video_ratings')
          .doc(ratingId)
          .set(ratingData, SetOptions(merge: true));
      
      // تحديث إحصائيات المنشور
      await _updatePostRatingStats(postId, rating, oldRating);
      
    } catch (e) {
      print('خطأ في حفظ التقييم: $e');
    }
  }

  /// تحديث إحصائيات التقييم للمنشور
  Future<void> _updatePostRatingStats(String postId, int newRating, int oldRating) async {
    await _firestore.runTransaction((transaction) async {
      final postRef = _firestore.collection('posts').doc(postId);
      final postDoc = await transaction.get(postRef);
      
      if (!postDoc.exists) return;
      
      final data = postDoc.data()!;
      final currentTotal = data['totalRatings'] as int? ?? 0;
      final currentAverage = (data['averageRating'] as num? ?? 0.0).toDouble();
      
      int newTotal;
      double newAverage;
      
      if (oldRating == 0) {
        // تقييم جديد
        newTotal = currentTotal + 1;
        newAverage = ((currentAverage * currentTotal) + newRating) / newTotal;
      } else {
        // تحديث تقييم موجود
        newTotal = currentTotal;
        newAverage = ((currentAverage * currentTotal) - oldRating + newRating) / newTotal;
      }
      
      transaction.update(postRef, {
        'totalRatings': newTotal,
        'averageRating': newAverage,
      });
    });
  }

  /// الحصول على تقييم المستخدم للفيديو
  Future<VideoRating?> getUserVideoRating(String postId) async {
    if (currentUserId == null) return null;

    try {
      final ratingId = '${currentUserId}_$postId';
      final doc = await _firestore
          .collection('video_ratings')
          .doc(ratingId)
          .get();

      if (doc.exists) {
        return VideoRating.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب التقييم: $e');
      return null;
    }
  }

  /// خوارزمية اقتراحات محسنة جداً تعتمد على التقييمات والسلوك
  Future<List<Post>> getUltimateVideoSuggestions({
    required String currentVideoId,
    String? currentUserId,
    int limit = 10,
  }) async {
    try {
      List<Post> suggestions = [];
      final Set<String> excludedIds = {currentVideoId};
      
      // 1. إذا كان المستخدم مسجل دخول، استخدم تفضيلاته
      if (currentUserId != null) {
        // احصل على تاريخ التقييمات للمستخدم
        final userRatings = await _firestore
            .collection('video_ratings')
            .where('userId', isEqualTo: currentUserId)
            .where('rating', isGreaterThanOrEqualTo: 4)
            .limit(20)
            .get();
        
        final likedPostIds = userRatings.docs.map((doc) => doc.data()['postId'] as String).toSet();
        
        // احصل على فيديوهات مشابهة لما قيّمه إيجابياً
        for (final postId in likedPostIds.take(5)) {
          final post = await getPost(postId);
          if (post != null) {
            // ابحث عن فيديوهات من نفس المؤلف
            final authorVideos = await _firestore
                .collection('posts')
                .where('type', isEqualTo: 'video')
                .where('userId', isEqualTo: post.userId)
                .where('averageRating', isGreaterThanOrEqualTo: 4.0)
                .orderBy('averageRating', descending: true)
                .orderBy('viewCount', descending: true)
                .limit(2)
                .get();
            
            final videos = authorVideos.docs
                .where((doc) => !excludedIds.contains(doc.id))
                .map((doc) => Post.fromFirestore(doc))
                .toList();
            
            suggestions.addAll(videos);
            excludedIds.addAll(videos.map((v) => v.id));
          }
        }
      }
      
      // 2. فيديوهات عالية الجودة والتقييم
      if (suggestions.length < limit) {
        final highQualityVideos = await _firestore
            .collection('posts')
            .where('type', isEqualTo: 'video')
            .where('averageRating', isGreaterThanOrEqualTo: 4.0)
            .where('totalRatings', isGreaterThanOrEqualTo: 5)
            .orderBy('averageRating', descending: true)
            .orderBy('totalRatings', descending: true)
            .limit(limit)
            .get();
        
        final qualityVideos = highQualityVideos.docs
            .where((doc) => !excludedIds.contains(doc.id))
            .map((doc) => Post.fromFirestore(doc))
            .take(limit - suggestions.length)
            .toList();
        
        suggestions.addAll(qualityVideos);
        excludedIds.addAll(qualityVideos.map((v) => v.id));
      }
      
      // 3. فيديوهات رائجة حديثة
      if (suggestions.length < limit) {
        final recentDate = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
        
        final trendingVideos = await _firestore
            .collection('posts')
            .where('type', isEqualTo: 'video')
            .where('createdAt', isGreaterThan: recentDate)
            .orderBy('createdAt', descending: true)
            .orderBy('viewCount', descending: true)
            .limit(limit)
            .get();
        
        final trending = trendingVideos.docs
            .where((doc) => !excludedIds.contains(doc.id))
            .map((doc) => Post.fromFirestore(doc))
            .take(limit - suggestions.length)
            .toList();
        
        suggestions.addAll(trending);
      }
      
      // ترتيب نهائي حسب درجة الشعبية
      suggestions.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
      
      return suggestions.take(limit).toList();
    } catch (e) {
      print('خطأ في الاقتراحات المحسنة: $e');
      return await _getDefaultVideoSuggestions(limit);
    }
  }

  /// إضافة رد على تعليق
  Future<void> addCommentReply({
    required String postId,
    required String parentCommentId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      // الحصول على بيانات المستخدم
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};

      // إنشاء الرد
      final reply = PostComment(
        id: const Uuid().v4(),
        userId: user.uid,
        userImage: userData['profileImageUrl'] ?? user.photoURL ?? '',
        userName: userData['name'] ?? user.displayName ?? 'مستخدم',
        content: content,
        createdAt: DateTime.now(),
        reactions: {},
        likes: [],
        replies: [],
      );

      // إضافة الرد إلى التعليق الأساسي
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(parentCommentId);

      await commentRef.update({
        'replies': FieldValue.arrayUnion([reply.toMap()]),
      });

    } catch (e) {
      print('خطأ في إضافة الرد: $e');
      rethrow;
    }
  }

  /// تبديل الإعجاب بتعليق
  Future<void> toggleCommentLike(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      // البحث عن التعليق في جميع المنشورات
      final postsSnapshot = await _firestore.collection('posts').get();
      
      for (final postDoc in postsSnapshot.docs) {
        final commentRef = _firestore
            .collection('posts')
            .doc(postDoc.id)
            .collection('comments')
            .doc(commentId);
        
        final commentDoc = await commentRef.get();
        if (commentDoc.exists) {
          final commentData = commentDoc.data()!;
          final likes = List<String>.from(commentData['likes'] ?? []);
          
          if (likes.contains(user.uid)) {
            // إزالة الإعجاب
            await commentRef.update({
              'likes': FieldValue.arrayRemove([user.uid]),
            });
          } else {
            // إضافة الإعجاب
            await commentRef.update({
              'likes': FieldValue.arrayUnion([user.uid]),
            });
          }
          return;
        }
      }
      
      throw Exception('التعليق غير موجود');
    } catch (e) {
      print('خطأ في تبديل الإعجاب: $e');
      rethrow;
    }
  }

  /// حذف تعليق
  Future<void> deleteComment(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('المستخدم غير مسجل الدخول');

      // البحث عن التعليق في جميع المنشورات
      final postsSnapshot = await _firestore.collection('posts').get();
      
      for (final postDoc in postsSnapshot.docs) {
        final commentRef = _firestore
            .collection('posts')
            .doc(postDoc.id)
            .collection('comments')
            .doc(commentId);
        
        final commentDoc = await commentRef.get();
        if (commentDoc.exists) {
          final commentData = commentDoc.data()!;
          
          // التحقق من أن المستخدم هو صاحب التعليق
          if (commentData['userId'] != user.uid) {
            throw Exception('لا يمكنك حذف تعليق شخص آخر');
          }
          
          // حذف التعليق
          await commentRef.delete();
          
          // تحديث عدد التعليقات في المنشور
          await _firestore.collection('posts').doc(postDoc.id).update({
            'commentCount': FieldValue.increment(-1),
          });
          
          return;
        }
      }
      
      throw Exception('التعليق غير موجود');
    } catch (e) {
      print('خطأ في حذف التعليق: $e');
      rethrow;
    }
  }

  /// الحصول على تعليقات منشور محدد
  Future<List<PostComment>> getCommentsForPost(String postId) async {
    try {
      final commentsSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();

      return commentsSnapshot.docs
          .map((doc) => PostComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب التعليقات: $e');
      return [];
    }
  }

  /// الحصول على منشورات رائجة بناءً على التفاعلات والهاشتاغات
  Future<List<Post>> getTrendingPosts({int limit = 30}) async { // Increased default limit to 30
    try {
      // الحصول على جميع المنشورات خلال آخر 30 يومًا
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('posts')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // تحويل المنشورات إلى قائمة
      final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();

      // حساب درجة الشعبية لكل منشور وترتيبها
      posts.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

      // أخذ أفضل المنشورات وخلطها عشوائيًا
      final topPosts = posts.take(limit * 2).toList(); // نأخذ ضعف العدد لخلطها
      
      // خلط المنشورات عشوائيًا لجعل العرض غير مرتّب
      topPosts.shuffle();

      // إرجاع العدد المطلوب
      return topPosts.take(limit).toList();
    } catch (e) {
      print('خطأ في الحصول على المنشورات الرائجة: $e');
      return [];
    }
  }

  /// Returns a stream of trending posts
  Stream<List<Post>> getTrendingPostsStream({int limit = 30}) { // Increased default limit to 30
    return Stream.fromFuture(getTrendingPosts(limit: limit));
  }
} 