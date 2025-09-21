import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/features/community/models/hashtag_model.dart';

class HashtagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// استخراج الهاشتاغات من النص
  List<String> extractHashtags(String text) {
    final regex = RegExp(r'#[\u0600-\u06FFa-zA-Z0-9_]+');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(0)!.toLowerCase()).toSet().toList();
  }
  
  /// حفظ أو تحديث هاشتاغ
  Future<void> saveHashtag(String hashtag, String postId) async {
    try {
      final hashtagRef = _firestore.collection('hashtags').doc(hashtag);
      final hashtagDoc = await hashtagRef.get();
      
      if (hashtagDoc.exists) {
        // تحديث الهاشتاغ الموجود
        await hashtagRef.update({
          'count': FieldValue.increment(1),
          'lastUsed': FieldValue.serverTimestamp(),
          'posts': FieldValue.arrayUnion([postId]),
        });
      } else {
        // إنشاء هاشتاغ جديد
        await hashtagRef.set({
          'tag': hashtag,
          'count': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUsed': FieldValue.serverTimestamp(),
          'posts': [postId],
        });
      }
    } catch (e) {
      print('خطأ في حفظ الهاشتاغ: $e');
    }
  }
  
  /// حفظ هاشتاغات متعددة
  Future<void> saveHashtags(List<String> hashtags, String postId) async {
    for (String hashtag in hashtags) {
      await saveHashtag(hashtag, postId);
    }
  }
  
  /// إزالة هاشتاغ من منشور
  Future<void> removeHashtagFromPost(String hashtag, String postId) async {
    try {
      final hashtagRef = _firestore.collection('hashtags').doc(hashtag);
      await hashtagRef.update({
        'count': FieldValue.increment(-1),
        'posts': FieldValue.arrayRemove([postId]),
      });
      
      // حذف الهاشتاغ إذا لم يعد مستخدماً
      final updatedDoc = await hashtagRef.get();
      if (updatedDoc.exists && updatedDoc.data()!['count'] <= 0) {
        await hashtagRef.delete();
      }
    } catch (e) {
      print('خطأ في إزالة الهاشتاغ: $e');
    }
  }
  
  /// البحث عن الهاشتاغات
  Future<List<HashtagModel>> searchHashtags(String query) async {
    try {
      final result = await _firestore
          .collection('hashtags')
          .where('tag', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('tag', isLessThan: query.toLowerCase() + 'z')
          .orderBy('tag')
          .orderBy('count', descending: true)
          .limit(20)
          .get();
      
      return result.docs
          .map((doc) => HashtagModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في البحث عن الهاشتاغات: $e');
      return [];
    }
  }
  
  /// الحصول على أشهر الهاشتاغات
  Future<List<HashtagModel>> getTrendingHashtags({int limit = 10}) async {
    try {
      final result = await _firestore
          .collection('hashtags')
          .orderBy('count', descending: true)
          .limit(limit)
          .get();
      
      return result.docs
          .map((doc) => HashtagModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في الحصول على الهاشتاغات الرائجة: $e');
      return [];
    }
  }
  
  /// الحصول على المنشورات بهاشتاغ معين
  Future<List<String>> getPostsByHashtag(String hashtag) async {
    try {
      final doc = await _firestore.collection('hashtags').doc(hashtag).get();
      if (doc.exists) {
        final data = doc.data()!;
        return List<String>.from(data['posts'] ?? []);
      }
      return [];
    } catch (e) {
      print('خطأ في الحصول على منشورات الهاشتاغ: $e');
      return [];
    }
  }
  
  /// تحديث هاشتاغات منشور عند التعديل
  Future<void> updatePostHashtags(String postId, List<String> oldHashtags, List<String> newHashtags) async {
    // إزالة الهاشتاغات القديمة
    for (String hashtag in oldHashtags) {
      if (!newHashtags.contains(hashtag)) {
        await removeHashtagFromPost(hashtag, postId);
      }
    }
    
    // إضافة الهاشتاغات الجديدة
    for (String hashtag in newHashtags) {
      if (!oldHashtags.contains(hashtag)) {
        await saveHashtag(hashtag, postId);
      }
    }
  }
  
  /// حذف جميع هاشتاغات منشور
  Future<void> deletePostHashtags(String postId, List<String> hashtags) async {
    for (String hashtag in hashtags) {
      await removeHashtagFromPost(hashtag, postId);
    }
  }
}