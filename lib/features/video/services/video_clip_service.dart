import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:sumi/features/video/models/video_clip_model.dart';
import 'package:sumi/features/community/models/post_model.dart';

/// خدمة إدارة مقاطع الفيديو
class VideoClipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// إنشاء مقطع فيديو جديد
  Future<VideoClip> createClip(ClipCreationInfo clipInfo) async {
    if (currentUserId == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    // التحقق من صحة البيانات
    final validationError = clipInfo.validationError;
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      // إنشاء معرف فريد للمقطع
      final clipId = const Uuid().v4();
      
      // الحصول على معلومات المستخدم
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data();
      
      final userName = userData?['userName'] ?? 'مستخدم سومي';
      final userImage = userData?['userImage'] ?? '';

      // إنشاء رابط المقطع (في التطبيق الحقيقي ستحتاج لمعالجة الفيديو)
      final clipUrl = await _generateClipUrl(clipInfo);
      
      // إنشاء صورة مصغرة للمقطع
      final thumbnailUrl = await _generateThumbnailUrl(clipInfo);

      // إنشاء كائن المقطع
      final clip = VideoClip(
        id: clipId,
        originalPostId: clipInfo.originalPostId,
        userId: currentUserId!,
        userName: userName,
        userImage: userImage,
        title: clipInfo.title,
        description: clipInfo.description,
        startTime: clipInfo.startTime,
        endTime: clipInfo.endTime,
        clipDuration: clipInfo.clipDuration,
        clipUrl: clipUrl,
        thumbnailUrl: thumbnailUrl,
        createdAt: DateTime.now(),
        likes: [],
        dislikes: [],
        viewCount: 0,
        shareCount: 0,
        hashtags: clipInfo.hashtags,
        isPublic: clipInfo.isPublic,
        category: clipInfo.category,
      );

      // حفظ المقطع في قاعدة البيانات
      await _firestore.collection('video_clips').doc(clipId).set(clip.toMap());

      // تحديث إحصائيات الفيديو الأصلي
      await _updateOriginalPostStats(clipInfo.originalPostId);

      return clip;
    } catch (e) {
      throw Exception('فشل في إنشاء المقطع: $e');
    }
  }

  /// إنشاء رابط المقطع (محاكاة - في التطبيق الحقيقي تحتاج لمعالجة الفيديو)
  Future<String> _generateClipUrl(ClipCreationInfo clipInfo) async {
    try {
      // في التطبيق الحقيقي، ستحتاج هنا لـ:
      // 1. تحميل الفيديو الأصلي
      // 2. قص الجزء المطلوب باستخدام FFmpeg أو مكتبة مشابهة
      // 3. رفع المقطع الجديد إلى Firebase Storage
      
      // للمحاكاة، سنعيد رابط وهمي
      final clipFileName = 'clip_${const Uuid().v4()}.mp4';
      
      // في التطبيق الحقيقي:
      // final clipFile = await _processVideoClip(clipInfo);
      // final uploadTask = _storage.ref('clips/$clipFileName').putFile(clipFile);
      // final snapshot = await uploadTask;
      // return await snapshot.ref.getDownloadURL();
      
      // للمحاكاة فقط:
      return 'https://sample-videos.com/zip/10/mp4/mp4-720p.mp4';
      
    } catch (e) {
      throw Exception('فشل في إنشاء رابط المقطع: $e');
    }
  }

  /// إنشاء صورة مصغرة للمقطع
  Future<String> _generateThumbnailUrl(ClipCreationInfo clipInfo) async {
    try {
      // في التطبيق الحقيقي، ستحتاج لاستخراج إطار من الفيديو
      // هنا نستخدم رابط وهمي
      
      final thumbnailFileName = 'thumbnail_${const Uuid().v4()}.jpg';
      
      // في التطبيق الحقيقي:
      // final thumbnailFile = await _generateVideoThumbnail(clipInfo);
      // final uploadTask = _storage.ref('thumbnails/$thumbnailFileName').putFile(thumbnailFile);
      // final snapshot = await uploadTask;
      // return await snapshot.ref.getDownloadURL();
      
      // للمحاكاة فقط:
      return 'https://picsum.photos/seed/${clipInfo.originalPostId}/400/225';
      
    } catch (e) {
      throw Exception('فشل في إنشاء الصورة المصغرة: $e');
    }
  }

  /// تحديث إحصائيات المنشور الأصلي
  Future<void> _updateOriginalPostStats(String originalPostId) async {
    try {
      await _firestore.collection('posts').doc(originalPostId).update({
        'clipsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // يمكن تجاهل هذا الخطأ لأنه ليس حرجاً
      print('خطأ في تحديث إحصائيات المنشور الأصلي: $e');
    }
  }

  /// الحصول على مقطع بواسطة المعرف
  Future<VideoClip?> getClip(String clipId) async {
    try {
      final doc = await _firestore.collection('video_clips').doc(clipId).get();
      
      if (doc.exists) {
        return VideoClip.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب المقطع: $e');
      return null;
    }
  }

  /// الحصول على مقاطع مستخدم معين
  Future<List<VideoClip>> getUserClips(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('video_clips')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => VideoClip.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب مقاطع المستخدم: $e');
      return [];
    }
  }

  /// الحصول على المقاطع العامة
  Future<List<VideoClip>> getPublicClips({
    int limit = 20,
    ClipCategory? category,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('video_clips')
          .where('isPublic', isEqualTo: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      query = query.orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => VideoClip.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب المقاطع العامة: $e');
      return [];
    }
  }

  /// الحصول على المقاطع الشائعة
  Future<List<VideoClip>> getTrendingClips({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('video_clips')
          .where('isPublic', isEqualTo: true)
          .orderBy('viewCount', descending: true)
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => VideoClip.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب المقاطع الشائعة: $e');
      return [];
    }
  }

  /// الحصول على مقاطع فيديو معين
  Future<List<VideoClip>> getClipsForVideo(String originalPostId) async {
    try {
      final snapshot = await _firestore
          .collection('video_clips')
          .where('originalPostId', isEqualTo: originalPostId)
          .where('isPublic', isEqualTo: true)
          .orderBy('viewCount', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => VideoClip.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب مقاطع الفيديو: $e');
      return [];
    }
  }

  /// الإعجاب بمقطع
  Future<void> toggleClipLike(String clipId) async {
    if (currentUserId == null) return;

    try {
      final clipRef = _firestore.collection('video_clips').doc(clipId);
      
      await _firestore.runTransaction((transaction) async {
        final clipDoc = await transaction.get(clipRef);
        
        if (!clipDoc.exists) return;
        
        final clipData = clipDoc.data()!;
        final likes = List<String>.from(clipData['likes'] ?? []);
        final dislikes = List<String>.from(clipData['dislikes'] ?? []);
        
        if (likes.contains(currentUserId)) {
          likes.remove(currentUserId);
        } else {
          likes.add(currentUserId!);
          dislikes.remove(currentUserId); // إزالة من عدم الإعجاب إذا وجد
        }
        
        transaction.update(clipRef, {
          'likes': likes,
          'dislikes': dislikes,
        });
      });
    } catch (e) {
      throw Exception('فشل في تحديث الإعجاب: $e');
    }
  }

  /// عدم الإعجاب بمقطع
  Future<void> toggleClipDislike(String clipId) async {
    if (currentUserId == null) return;

    try {
      final clipRef = _firestore.collection('video_clips').doc(clipId);
      
      await _firestore.runTransaction((transaction) async {
        final clipDoc = await transaction.get(clipRef);
        
        if (!clipDoc.exists) return;
        
        final clipData = clipDoc.data()!;
        final likes = List<String>.from(clipData['likes'] ?? []);
        final dislikes = List<String>.from(clipData['dislikes'] ?? []);
        
        if (dislikes.contains(currentUserId)) {
          dislikes.remove(currentUserId);
        } else {
          dislikes.add(currentUserId!);
          likes.remove(currentUserId); // إزالة من الإعجاب إذا وجد
        }
        
        transaction.update(clipRef, {
          'likes': likes,
          'dislikes': dislikes,
        });
      });
    } catch (e) {
      throw Exception('فشل في تحديث عدم الإعجاب: $e');
    }
  }

  /// زيادة عدد المشاهدات
  Future<void> incrementClipViews(String clipId) async {
    try {
      await _firestore.collection('video_clips').doc(clipId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // يمكن تجاهل هذا الخطأ
      print('خطأ في زيادة عدد المشاهدات: $e');
    }
  }

  /// زيادة عدد المشاركات
  Future<void> incrementClipShares(String clipId) async {
    try {
      await _firestore.collection('video_clips').doc(clipId).update({
        'shareCount': FieldValue.increment(1),
      });
    } catch (e) {
      // يمكن تجاهل هذا الخطأ
      print('خطأ في زيادة عدد المشاركات: $e');
    }
  }

  /// حذف مقطع
  Future<void> deleteClip(String clipId) async {
    if (currentUserId == null) {
      throw Exception('المستخدم غير مسجل الدخول');
    }

    try {
      final clipDoc = await _firestore.collection('video_clips').doc(clipId).get();
      
      if (!clipDoc.exists) {
        throw Exception('المقطع غير موجود');
      }

      final clip = VideoClip.fromFirestore(clipDoc);
      
      // التحقق من أن المستخدم مالك المقطع
      if (clip.userId != currentUserId) {
        throw Exception('ليس لديك صلاحية لحذف هذا المقطع');
      }

      // حذف الملفات من التخزين
      try {
        await _storage.refFromURL(clip.clipUrl).delete();
        await _storage.refFromURL(clip.thumbnailUrl).delete();
      } catch (e) {
        // يمكن تجاهل أخطاء حذف الملفات
        print('خطأ في حذف الملفات: $e');
      }

      // حذف المقطع من قاعدة البيانات
      await _firestore.collection('video_clips').doc(clipId).delete();

      // تحديث إحصائيات المنشور الأصلي
      await _firestore.collection('posts').doc(clip.originalPostId).update({
        'clipsCount': FieldValue.increment(-1),
      });

    } catch (e) {
      throw Exception('فشل في حذف المقطع: $e');
    }
  }

  /// البحث في المقاطع
  Future<List<VideoClip>> searchClips({
    required String query,
    ClipCategory? category,
    int limit = 20,
  }) async {
    try {
      Query baseQuery = _firestore
          .collection('video_clips')
          .where('isPublic', isEqualTo: true);

      if (category != null) {
        baseQuery = baseQuery.where('category', isEqualTo: category.name);
      }

      // البحث بالعنوان (بحث بسيط - يمكن تحسينه)
      baseQuery = baseQuery
          .orderBy('title')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(limit);

      final snapshot = await baseQuery.get();

      return snapshot.docs
          .map((doc) => VideoClip.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في البحث عن المقاطع: $e');
      return [];
    }
  }

  /// الحصول على إحصائيات المقاطع لمستخدم
  Future<Map<String, dynamic>> getUserClipStats(String userId) async {
    try {
      final clipsSnapshot = await _firestore
          .collection('video_clips')
          .where('userId', isEqualTo: userId)
          .get();

      final clips = clipsSnapshot.docs
          .map((doc) => VideoClip.fromFirestore(doc))
          .toList();

      int totalViews = 0;
      int totalLikes = 0;
      int totalShares = 0;

      for (final clip in clips) {
        totalViews += clip.viewCount;
        totalLikes += clip.likes.length;
        totalShares += clip.shareCount;
      }

      return {
        'totalClips': clips.length,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
        'totalShares': totalShares,
        'averageViews': clips.isNotEmpty ? totalViews / clips.length : 0.0,
        'averageLikes': clips.isNotEmpty ? totalLikes / clips.length : 0.0,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات المقاطع: $e');
      return {};
    }
  }
}
