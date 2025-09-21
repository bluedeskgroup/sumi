import 'package:cloud_firestore/cloud_firestore.dart';

class HashtagModel {
  final String tag;
  final int count;
  final DateTime createdAt;
  final DateTime lastUsed;
  final List<String> posts;

  HashtagModel({
    required this.tag,
    required this.count,
    required this.createdAt,
    required this.lastUsed,
    required this.posts,
  });

  factory HashtagModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HashtagModel(
      tag: data['tag'] ?? '',
      count: data['count'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (data['lastUsed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      posts: List<String>.from(data['posts'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tag': tag,
      'count': count,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUsed': Timestamp.fromDate(lastUsed),
      'posts': posts,
    };
  }

  @override
  String toString() {
    return 'HashtagModel(tag: $tag, count: $count)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HashtagModel && other.tag == tag;
  }

  @override
  int get hashCode => tag.hashCode;
}