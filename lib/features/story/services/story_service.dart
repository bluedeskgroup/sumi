import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sumi/features/story/models/story_model.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  CollectionReference get _storiesCollection => _firestore.collection('stories');
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Get current user data
  Future<Map<String, dynamic>> get _currentUserData async {
    if (_currentUserId == null) return {};
    
    final userDoc = await _usersCollection.doc(_currentUserId).get();
    return userDoc.data() as Map<String, dynamic>? ?? {};
  }
  
  // Get all stories
  Stream<List<Story>> getStories() {
    final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));
    
    return _storiesCollection
        .where('lastUpdated', isGreaterThan: cutoff)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
        });
  }
  
  // Get stories for a specific user
  Stream<List<Story>> getUserStories(String userId) {
    final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));
    
    return _storiesCollection
        .where('userId', isEqualTo: userId)
        .where('lastUpdated', isGreaterThan: cutoff)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList();
        });
  }
  
  // Get my stories
  Stream<List<Story>> getMyStories() {
    if (currentUserId == null) return Stream.value([]);
    
    return getUserStories(currentUserId!);
  }
  
  // Create a new story
  Future<StoryItem?> createStory({
    required File file,
    required StoryMediaType mediaType,
    StoryFilter? filter,
    bool allowSharing = true,
  }) async {
    try {
      if (currentUserId == null) return null;
      
      // Upload media file
      final String mediaUrl = await _uploadMedia(
        file,
        mediaType,
      );
      
      // Get user data
      final userData = await _currentUserData;

      Duration duration;
      if (mediaType == StoryMediaType.video) {
        final info = await VideoCompress.getMediaInfo(file.path);
        duration = Duration(milliseconds: info.duration!.round());
      } else {
        duration = const Duration(seconds: 5);
      }
      
      // Create story item
      final storyId = const Uuid().v4();
      final StoryItem storyItem = StoryItem(
        id: storyId,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        duration: duration,
        timestamp: DateTime.now(),
        viewedBy: [currentUserId!], // Creator has seen their own story
        filter: filter,
        allowSharing: allowSharing,
      );
      
      // Check if user already has a story document
      final storyQuery = await _storiesCollection
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      if (storyQuery.docs.isNotEmpty) {
        // Update existing story document
        final storyDoc = storyQuery.docs.first;
        await storyDoc.reference.update({
          'items': FieldValue.arrayUnion([storyItem.toMap()]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new story document
        final newStoryDocRef = _storiesCollection.doc();
        await newStoryDocRef.set({
          'id': newStoryDocRef.id,
          'userId': currentUserId,
          'userName': userData['displayName'] ?? _auth.currentUser?.displayName ?? 'User',
          'userImage': userData['photoURL'] ?? _auth.currentUser?.photoURL ?? '',
          'items': [storyItem.toMap()],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      return storyItem;
    } catch (e) {
      debugPrint('Error creating story: $e');
      return null;
    }
  }
  
  // Create a poll story
  Future<StoryItem?> createPollStory({
    required File file,
    required String question,
    required List<String> options,
    StoryFilter? filter,
  }) async {
    try {
      if (currentUserId == null) return null;
      
      // Upload media file
      final String mediaUrl = await _uploadMedia(
        file,
        StoryMediaType.image,
      );
      
      // Get user data
      final userData = await _currentUserData;
      
      // Create poll options
      final List<StoryPollOption> pollOptions = options.map((option) {
        return StoryPollOption(
          text: option,
          votes: [],
        );
      }).toList();
      
      // Create poll
      final poll = StoryPoll(
        question: question,
        options: pollOptions,
        endTime: DateTime.now().add(const Duration(hours: 24)),
      );
      
      // Create story item
      final storyId = const Uuid().v4();
      final StoryItem storyItem = StoryItem(
        id: storyId,
        mediaUrl: mediaUrl,
        mediaType: StoryMediaType.image,
        duration: const Duration(seconds: 5), // Polls are images, fixed duration
        timestamp: DateTime.now(),
        viewedBy: [currentUserId!], // Creator has seen their own story
        filter: filter,
        poll: poll,
      );
      
      // Check if user already has a story document
      final storyQuery = await _storiesCollection
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      if (storyQuery.docs.isNotEmpty) {
        // Update existing story document
        final storyDoc = storyQuery.docs.first;
        await storyDoc.reference.update({
          'items': FieldValue.arrayUnion([storyItem.toMap()]),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new story document
        final newStoryDocRef = _storiesCollection.doc();
        await newStoryDocRef.set({
          'id': newStoryDocRef.id,
          'userId': currentUserId,
          'userName': userData['displayName'] ?? _auth.currentUser?.displayName ?? 'User',
          'userImage': userData['photoURL'] ?? _auth.currentUser?.photoURL ?? '',
          'items': [storyItem.toMap()],
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      return storyItem;
    } catch (e) {
      debugPrint('Error creating poll story: $e');
      return null;
    }
  }
  
  // Upload media to Firebase Storage
  Future<String> _uploadMedia(File file, StoryMediaType mediaType) async {
    if (_currentUserId == null) throw Exception('User not authenticated');
    
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    final String storagePath = 'stories/$_currentUserId/$fileName';
    
    File fileToUpload;
    if (mediaType == StoryMediaType.video) {
      // Compress video
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
      );
      
      if (mediaInfo?.file == null) {
        throw Exception('Failed to compress video');
      }
      fileToUpload = File(mediaInfo!.file!.path);
    } else {
      fileToUpload = file;
    }
    
    // Upload the file with default metadata
    final ref = _storage.ref().child(storagePath);
    await ref.putFile(fileToUpload, SettableMetadata());
    return await ref.getDownloadURL();
  }
  
  // Mark story as viewed
  Future<void> markStoryAsViewed(String storyId, String storyItemId) async {
    try {
      if (_currentUserId == null) return;
      
      final storyDocRef = _storiesCollection.doc(storyId);
      final storyDoc = await storyDocRef.get();
      if (!storyDoc.exists) return;
      
      final storyData = storyDoc.data() as Map<String, dynamic>;
      final List<dynamic> items = storyData['items'] ?? [];
      
      // Create a deep copy to modify
      final List<dynamic> updatedItems = List<Map<String, dynamic>>.from(items.map((item) => Map<String, dynamic>.from(item as Map)));
      
      // Find the story item and update its seenBy list
      bool wasUpdated = false;
      for (int i = 0; i < updatedItems.length; i++) {
        if (updatedItems[i]['id'] == storyItemId) {
          final List<dynamic> seenBy = List<dynamic>.from(updatedItems[i]['viewedBy'] ?? []);
          if (!seenBy.contains(_currentUserId)) {
            seenBy.add(_currentUserId);
            updatedItems[i]['viewedBy'] = seenBy;
            wasUpdated = true;
          }
          break;
        }
      }
      
      // Update the document only if a change was made
      if (wasUpdated) {
        await storyDocRef.update({'items': updatedItems});
      }
    } catch (e) {
      // It's okay if this fails, the user can still view the story
    }
  }
  
  // Add a reaction to a story
  Future<bool> addReaction(String storyId, String storyItemId, StoryReactionType reactionType) async {
    try {
      if (_currentUserId == null) return false;
      
      final userData = await _currentUserData;
      
      final reaction = StoryReaction(
        userId: _currentUserId!,
        userName: userData['displayName'] ?? 'User',
        userImage: userData['photoURL'] ?? '',
        type: reactionType,
        timestamp: DateTime.now(),
      );
      
      final storyDocRef = _storiesCollection.doc(storyId);
      final storyDoc = await storyDocRef.get();
      if (!storyDoc.exists) return false;
      
      final storyData = storyDoc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(storyData['items'] ?? []);
      
      bool wasUpdated = false;
      for (int i = 0; i < items.length; i++) {
        if (items[i]['id'] == storyItemId) {
          final reactions = List<Map<String, dynamic>>.from(items[i]['reactions'] ?? []);
          reactions.removeWhere((r) => r['userId'] == _currentUserId);
          reactions.add(reaction.toMap());
          items[i]['reactions'] = reactions;
          wasUpdated = true;
          break;
        }
      }
      
      if (wasUpdated) {
        await storyDocRef.update({'items': items});
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Remove a reaction from a story
  Future<bool> removeReaction(String storyId, String storyItemId) async {
    try {
      if (_currentUserId == null) return false;
      
      final storyDocRef = _storiesCollection.doc(storyId);
      final storyDoc = await storyDocRef.get();
      if (!storyDoc.exists) return false;
      
      final storyData = storyDoc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(storyData['items'] ?? []);
      
      bool wasUpdated = false;
      for (int i = 0; i < items.length; i++) {
        if (items[i]['id'] == storyItemId) {
          final reactions = List<Map<String, dynamic>>.from(items[i]['reactions'] ?? []);
          int initialLength = reactions.length;
          reactions.removeWhere((r) => r['userId'] == _currentUserId);
          if (reactions.length < initialLength) {
            items[i]['reactions'] = reactions;
            wasUpdated = true;
          }
          break;
        }
      }
      
      if (wasUpdated) {
        await storyDocRef.update({'items': items});
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Vote in a poll
  Future<bool> voteInPoll(String storyId, String storyItemId, int optionIndex) async {
    try {
      if (_currentUserId == null) return false;
      
      final storyDocRef = _storiesCollection.doc(storyId);
      final storyDoc = await storyDocRef.get();
      if (!storyDoc.exists) return false;
      
      final storyData = storyDoc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(storyData['items'] ?? []);
      
      bool wasUpdated = false;
      for (int i = 0; i < items.length; i++) {
        if (items[i]['id'] == storyItemId) {
          final pollData = Map<String, dynamic>.from(items[i]['poll'] ?? {});
          if (pollData.isEmpty) return false;

          final DateTime endTime = (pollData['endTime'] as Timestamp).toDate();
          if (DateTime.now().isAfter(endTime)) return false;
          
          final options = List<Map<String, dynamic>>.from(pollData['options'] ?? []);
          if (optionIndex < 0 || optionIndex >= options.length) return false;
          
          // Remove user from all other options to ensure they can only vote once
          for (int j = 0; j < options.length; j++) {
            if (j == optionIndex) continue;
            final votes = List<String>.from(options[j]['votes'] ?? []);
            if (votes.contains(_currentUserId)) {
              votes.remove(_currentUserId);
              options[j]['votes'] = votes;
            }
          }
          
          // Add or remove user's vote from the selected option
          final votes = List<String>.from(options[optionIndex]['votes'] ?? []);
          if (votes.contains(_currentUserId)) {
            // If user has already voted for this option, remove the vote
            votes.remove(_currentUserId);
          } else {
            // Otherwise, add the vote
            votes.add(_currentUserId!);
          }
          options[optionIndex]['votes'] = votes;

          pollData['options'] = options;
          items[i]['poll'] = pollData;
          wasUpdated = true;
          break;
        }
      }
      
      if (wasUpdated) {
        await storyDocRef.update({'items': items});
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete a story item
  Future<bool> deleteStoryItem(String storyId, String storyItemId) async {
    try {
      if (_currentUserId == null) return false;
      
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return false;
      
      final storyData = storyDoc.data() as Map<String, dynamic>;
      
      // Verify the story belongs to the current user
      if (storyData['userId'] != _currentUserId) {
        return false;
      }
      
      final List<dynamic> items = storyData['items'] ?? [];
      
      // Find and remove the story item
      items.removeWhere((item) => item['id'] == storyItemId);
      
      if (items.isEmpty) {
        // If no items left, delete the entire story document
        await _storiesCollection.doc(storyId).delete();
      } else {
        // Otherwise update the items list
        await _storiesCollection.doc(storyId).update({
          'items': items,
        });
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get story viewers
  Future<List<Map<String, dynamic>>> getStoryViewers(String storyId, String storyItemId) async {
    try {
      if (_currentUserId == null) return [];
      
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return [];
      
      final storyData = storyDoc.data() as Map<String, dynamic>;
      
      // Verify the story belongs to the current user
      if (storyData['userId'] != _currentUserId) {
        return [];
      }
      
      final List<dynamic> items = storyData['items'] ?? [];
      
      // Find the story item
      final item = items.firstWhere(
        (item) => item['id'] == storyItemId,
        orElse: () => null,
      );
      
      if (item == null) return [];
      
      final List<dynamic> seenBy = item['viewedBy'] ?? [];
      final List<Map<String, dynamic>> viewers = [];
      
      // Get user details for each viewer
      for (final userId in seenBy) {
        if (userId == _currentUserId) continue; // Skip the story owner
        
        final userDoc = await _usersCollection.doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          viewers.add({
            'userId': userId,
            'displayName': userData['displayName'] ?? 'User',
            'photoURL': userData['photoURL'] ?? '',
          });
        }
      }
      
      return viewers;
    } catch (e) {
      return [];
    }
  }
  
  // Get story reactions
  Future<List<StoryReaction>> getStoryReactions(String storyId, String storyItemId) async {
    try {
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return [];
      
      final storyData = storyDoc.data() as Map<String, dynamic>;
      final List<dynamic> items = storyData['items'] ?? [];
      
      // Find the story item
      final item = items.firstWhere(
        (item) => item['id'] == storyItemId,
        orElse: () => null,
      );
      
      if (item == null) return [];
      
      final List<dynamic> reactionsData = item['reactions'] ?? [];
      final List<StoryReaction> reactions = [];
      
      for (final reactionData in reactionsData) {
        reactions.add(StoryReaction.fromMap(reactionData));
      }
      
      return reactions;
    } catch (e) {
      return [];
    }
  }
  
  // Share a story
  Future<bool> shareStory(String storyId, String storyItemId) async {
    try {
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return false;
      
      final storyData = storyDoc.data() as Map<String, dynamic>;
      final List<dynamic> items = storyData['items'] ?? [];
      
      // Find the story item
      final item = items.firstWhere(
        (item) => item['id'] == storyItemId,
        orElse: () => null,
      );
      
      if (item == null) return false;
      
      // Check if sharing is allowed
      final bool allowSharing = item['allowSharing'] ?? true;
      if (!allowSharing) return false;
      
      // Get the media URL
      final String mediaUrl = item['mediaUrl'] ?? '';
      if (mediaUrl.isEmpty) return false;
      
      // Implement actual sharing logic using a sharing plugin
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> incrementShareCount(String storyId, String storyItemId) async {
    try {
      final storyRef = _storiesCollection.doc(storyId);
      final storyDoc = await storyRef.get();
      if (!storyDoc.exists) return;

      final items =
          List<Map<String, dynamic>>.from(storyDoc.get('items') as List);
      final itemIndex = items.indexWhere((item) => item['id'] == storyItemId);

      if (itemIndex != -1) {
        final item = items[itemIndex];
        final currentShares = (item['shareCount'] as int?) ?? 0;
        items[itemIndex]['shareCount'] = currentShares + 1;
        await storyRef.update({'items': items});
      }
    } catch (e) {
      debugPrint('Failed to increment share count: $e');
    }
  }

  // === مميزات إضافية ===

  // إضافة رد على قصة
  Future<bool> addReply(String storyId, String storyItemId, String replyText) async {
    try {
      if (_currentUserId == null || replyText.trim().isEmpty) return false;

      final userData = await _currentUserData;

      final reply = StoryReply(
        id: const Uuid().v4(),
        userId: _currentUserId!,
        userName: userData['displayName'] ?? 'User',
        userImage: userData['photoURL'] ?? '',
        message: replyText.trim(),
        createdAt: DateTime.now(),
      );

      final storyDocRef = _storiesCollection.doc(storyId);
      final storyDoc = await storyDocRef.get();
      if (!storyDoc.exists) return false;

      final storyData = storyDoc.data() as Map<String, dynamic>;
      final items = List<Map<String, dynamic>>.from(storyData['items'] ?? []);

      bool wasUpdated = false;
      for (int i = 0; i < items.length; i++) {
        if (items[i]['id'] == storyItemId) {
          final replies = List<Map<String, dynamic>>.from(items[i]['replies'] ?? []);
          replies.add(reply.toMap());
          items[i]['replies'] = replies;
          wasUpdated = true;
          break;
        }
      }

      if (wasUpdated) {
        await storyDocRef.update({'items': items});
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // الحصول على الردود على قصة
  Future<List<StoryReply>> getStoryReplies(String storyId, String storyItemId) async {
    try {
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return [];

      final storyData = storyDoc.data() as Map<String, dynamic>;
      final List<dynamic> items = storyData['items'] ?? [];

      // Find the story item
      final item = items.firstWhere(
        (item) => item['id'] == storyItemId,
        orElse: () => null,
      );

      if (item == null) return [];

      final List<dynamic> repliesData = item['replies'] ?? [];
      final List<StoryReply> replies = [];

      for (final replyData in repliesData) {
        final replyMap = replyData as Map<String, dynamic>;
        final reply = StoryReply(
          id: replyMap['id'] ?? '',
          userId: replyMap['userId'] ?? '',
          userName: replyMap['userName'] ?? '',
          userImage: replyMap['userImage'] ?? '',
          message: replyMap['message'] ?? '',
          createdAt: (replyMap['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
        replies.add(reply);
      }

      return replies;
    } catch (e) {
      return [];
    }
  }

  // إضافة قصة للإشارات المرجعية
  Future<bool> bookmarkStory(String storyId, String storyItemId) async {
    try {
      if (_currentUserId == null) return false;

      final bookmarkRef = _firestore.collection('bookmarks').doc(_currentUserId);
      final bookmarkDoc = await bookmarkRef.get();

      Map<String, dynamic> bookmarksData;
      if (bookmarkDoc.exists) {
        bookmarksData = bookmarkDoc.data() as Map<String, dynamic>;
      } else {
        bookmarksData = {};
      }

      final bookmarkedStories = List<Map<String, dynamic>>.from(bookmarksData['stories'] ?? []);
      final bookmarkKey = '${storyId}_${storyItemId}';

      // Check if already bookmarked
      final existingIndex = bookmarkedStories.indexWhere((bookmark) => bookmark['id'] == bookmarkKey);

      if (existingIndex != -1) {
        // Remove bookmark
        bookmarkedStories.removeAt(existingIndex);
      } else {
        // Add bookmark
        bookmarkedStories.add({
          'id': bookmarkKey,
          'storyId': storyId,
          'storyItemId': storyItemId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await bookmarkRef.set({
        'stories': bookmarkedStories,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // الحصول على القصص المحفوظة
  Stream<List<Map<String, dynamic>>> getBookmarkedStories() {
    if (_currentUserId == null) return Stream.value([]);

    return _firestore.collection('bookmarks').doc(_currentUserId).snapshots().map((doc) {
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>;
      final bookmarkedStories = List<Map<String, dynamic>>.from(data['stories'] ?? []);

      // Convert to list of bookmark data with story details
      return bookmarkedStories;
    });
  }

  // التحقق من حالة الإشارة المرجعية
  Future<bool> isStoryBookmarked(String storyId, String storyItemId) async {
    try {
      if (_currentUserId == null) return false;

      final bookmarkDoc = await _firestore.collection('bookmarks').doc(_currentUserId).get();
      if (!bookmarkDoc.exists) return false;

      final data = bookmarkDoc.data() as Map<String, dynamic>;
      final bookmarkedStories = List<Map<String, dynamic>>.from(data['stories'] ?? []);
      final bookmarkKey = '${storyId}_${storyItemId}';

      return bookmarkedStories.any((bookmark) => bookmark['id'] == bookmarkKey);
    } catch (e) {
      return false;
    }
  }

  // إخفاء قصص مستخدم معين
  Future<bool> hideUserStories(String userId) async {
    try {
      if (_currentUserId == null) return false;

      final hiddenUsersRef = _firestore.collection('hidden_users').doc(_currentUserId);
      final hiddenUsersDoc = await hiddenUsersRef.get();

      Map<String, dynamic> hiddenData;
      if (hiddenUsersDoc.exists) {
        hiddenData = hiddenUsersDoc.data() as Map<String, dynamic>;
      } else {
        hiddenData = {};
      }

      final hiddenUsers = List<String>.from(hiddenData['users'] ?? []);

      if (!hiddenUsers.contains(userId)) {
        hiddenUsers.add(userId);
        await hiddenUsersRef.set({
          'users': hiddenUsers,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // إلغاء إخفاء قصص مستخدم
  Future<bool> unhideUserStories(String userId) async {
    try {
      if (_currentUserId == null) return false;

      final hiddenUsersRef = _firestore.collection('hidden_users').doc(_currentUserId);
      final hiddenUsersDoc = await hiddenUsersRef.get();

      if (!hiddenUsersDoc.exists) return false;

      final hiddenData = hiddenUsersDoc.data() as Map<String, dynamic>;
      final hiddenUsers = List<String>.from(hiddenData['users'] ?? []);

      hiddenUsers.remove(userId);
      await hiddenUsersRef.set({
        'users': hiddenUsers,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // الحصول على قائمة المستخدمين المخفيين
  Future<List<String>> getHiddenUsers() async {
    try {
      if (_currentUserId == null) return [];

      final hiddenUsersDoc = await _firestore.collection('hidden_users').doc(_currentUserId).get();
      if (!hiddenUsersDoc.exists) return [];

      final hiddenData = hiddenUsersDoc.data() as Map<String, dynamic>;
      return List<String>.from(hiddenData['users'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // الإبلاغ عن قصة
  Future<bool> reportStory(String storyId, String storyItemId, String reason) async {
    try {
      if (_currentUserId == null) return false;

      final reportRef = _firestore.collection('reports').doc();
      await reportRef.set({
        'storyId': storyId,
        'storyItemId': storyItemId,
        'reporterId': _currentUserId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // البحث في القصص
  Future<List<Story>> searchStories(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));

      // Get all stories within 24 hours
      final storiesSnapshot = await _storiesCollection
          .where('lastUpdated', isGreaterThan: cutoff)
          .get();

      final List<Story> matchingStories = [];
      final hiddenUsers = await getHiddenUsers();

      for (final doc in storiesSnapshot.docs) {
        final story = Story.fromFirestore(doc);

        // Skip hidden users
        if (hiddenUsers.contains(story.userId)) continue;

        // Search in user name or story content (if available)
        if (story.userName.toLowerCase().contains(query.toLowerCase())) {
          matchingStories.add(story);
        }
      }

      return matchingStories;
    } catch (e) {
      return [];
    }
  }

  // حفظ قصة للعرض دون اتصال
  Future<bool> saveStoryForOffline(String storyId, String storyItemId) async {
    try {
      if (_currentUserId == null) return false;

      final offlineRef = _firestore.collection('offline_stories').doc(_currentUserId);
      final offlineDoc = await offlineRef.get();

      Map<String, dynamic> offlineData;
      if (offlineDoc.exists) {
        offlineData = offlineDoc.data() as Map<String, dynamic>;
      } else {
        offlineData = {};
      }

      final savedStories = List<Map<String, dynamic>>.from(offlineData['stories'] ?? []);
      final saveKey = '${storyId}_${storyItemId}';

      // Check if already saved
      final existingIndex = savedStories.indexWhere((saved) => saved['id'] == saveKey);

      if (existingIndex == -1) {
        // Add to saved
        savedStories.add({
          'id': saveKey,
          'storyId': storyId,
          'storyItemId': storyItemId,
          'savedAt': FieldValue.serverTimestamp(),
        });

        await offlineRef.set({
          'stories': savedStories,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // الحصول على القصص المحفوظة للعرض دون اتصال
  Future<List<Map<String, dynamic>>> getSavedStories() async {
    try {
      if (_currentUserId == null) return [];

      final offlineDoc = await _firestore.collection('offline_stories').doc(_currentUserId).get();
      if (!offlineDoc.exists) return [];

      final offlineData = offlineDoc.data() as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(offlineData['stories'] ?? []);
    } catch (e) {
      return [];
    }
  }

  // الحصول على قصة واحدة بواسطة ID
  Future<Story?> getStoryById(String storyId) async {
    try {
      final storyDoc = await _storiesCollection.doc(storyId).get();
      if (!storyDoc.exists) return null;
      return Story.fromFirestore(storyDoc);
    } catch (e) {
      return null;
    }
  }

  // متابعة عنصر قصة معين بشكل لحظي
  Stream<StoryItem?> watchStoryItem(String storyId, String storyItemId) {
    return _storiesCollection.doc(storyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      final items = data['items'];
      if (items is List) {
        for (final dynamic item in items) {
          if (item is Map<String, dynamic>) {
            if (item['id'] == storyItemId) {
              return StoryItem.fromMap(item);
            }
          } else if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            if (map['id'] == storyItemId) {
              return StoryItem.fromMap(map);
            }
          }
        }
      }
      return null;
    });
  }

  // === إعدادات القصص ===

  // حفظ إعدادات القصص
  Future<bool> saveStorySettings(Map<String, dynamic> settings) async {
    try {
      if (_currentUserId == null) return false;

      final settingsRef = _firestore.collection('user_settings').doc(_currentUserId);
      await settingsRef.set({
        'privacy': settings['privacy'] ?? {},
        'notifications': settings['notifications'] ?? {},
        'account': settings['account'] ?? {},
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Error saving story settings: $e');
      return false;
    }
  }

  // تحميل إعدادات القصص
  Future<Map<String, dynamic>> loadStorySettings() async {
    try {
      if (_currentUserId == null) {
        return _getDefaultSettings();
      }

      final settingsDoc = await _firestore.collection('user_settings').doc(_currentUserId).get();

      if (settingsDoc.exists) {
        final data = settingsDoc.data() ?? {};
        return {
          'privacy': data['privacy'] ?? _getDefaultPrivacySettings(),
          'notifications': data['notifications'] ?? _getDefaultNotificationSettings(),
          'account': data['account'] ?? _getDefaultAccountSettings(),
        };
      }

      return _getDefaultSettings();
    } catch (e) {
      debugPrint('Error loading story settings: $e');
      return _getDefaultSettings();
    }
  }

  // الإعدادات الافتراضية
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'privacy': _getDefaultPrivacySettings(),
      'notifications': _getDefaultNotificationSettings(),
      'account': _getDefaultAccountSettings(),
    };
  }

  Map<String, dynamic> _getDefaultPrivacySettings() {
    return {
      'allowSharing': true,
      'showViewCount': true,
      'showReactions': true,
      'allowReplies': true,
      'autoSaveToGallery': false,
    };
  }

  Map<String, dynamic> _getDefaultNotificationSettings() {
    return {
      'storyNotifications': true,
      'replyNotifications': true,
      'reactionNotifications': true,
      'mentionNotifications': true,
    };
  }

  Map<String, dynamic> _getDefaultAccountSettings() {
    return {
      'autoDeleteOldStories': false,
      'deleteAfterDays': 7,
      'downloadQuality': 'high',
    };
  }

  // حفظ مستخدم مخفي
  Future<bool> saveHiddenUser(String userId) async {
    try {
      if (_currentUserId == null) return false;

      final hiddenUsersRef = _firestore.collection('hidden_users').doc(_currentUserId);
      await hiddenUsersRef.set({
        'hiddenUsers': FieldValue.arrayUnion([userId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Error saving hidden user: $e');
      return false;
    }
  }

  // إزالة مستخدم مخفي
  Future<bool> removeHiddenUser(String userId) async {
    try {
      if (_currentUserId == null) return false;

      final hiddenUsersRef = _firestore.collection('hidden_users').doc(_currentUserId);
      await hiddenUsersRef.set({
        'hiddenUsers': FieldValue.arrayRemove([userId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('Error removing hidden user: $e');
      return false;
    }
  }

  // الحصول على قائمة المستخدمين المخفيين
  Future<List<String>> getHiddenUsersList() async {
    try {
      if (_currentUserId == null) return [];

      final hiddenUsersDoc = await _firestore.collection('hidden_users').doc(_currentUserId).get();
      if (hiddenUsersDoc.exists) {
        final data = hiddenUsersDoc.data() ?? {};
        return List<String>.from(data['hiddenUsers'] ?? []);
      }

      return [];
    } catch (e) {
      debugPrint('Error getting hidden users: $e');
      return [];
    }
  }

  // التحقق من إخفاء مستخدم
  Future<bool> isUserHidden(String userId) async {
    final hiddenUsers = await getHiddenUsersList();
    return hiddenUsers.contains(userId);
  }
} 