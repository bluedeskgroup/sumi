import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

DateTime _safeParseTimestamp(dynamic value, {DateTime? fallback}) {
  final DateTime defaultValue = fallback ?? DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value) ?? defaultValue;
  return defaultValue;
}

enum StoryMediaType {
  image,
  video,
}

enum StoryReactionType {
  like,
  love,
  laugh,
  wow,
  sad,
  angry,
}

extension StoryMediaTypeExtension on StoryMediaType {
  String get name {
    return toString().split('.').last;
  }
  
  static StoryMediaType fromString(String value) {
    return StoryMediaType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => StoryMediaType.image,
    );
  }
}

extension StoryReactionTypeExtension on StoryReactionType {
  String get name {
    return toString().split('.').last;
  }
  
  String get emoji {
    switch (this) {
      case StoryReactionType.like:
        return '👍';
      case StoryReactionType.love:
        return '❤️';
      case StoryReactionType.laugh:
        return '😂';
      case StoryReactionType.wow:
        return '😮';
      case StoryReactionType.sad:
        return '😢';
      case StoryReactionType.angry:
        return '😡';
    }
  }
  
  static StoryReactionType fromString(String value) {
    return StoryReactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => StoryReactionType.like,
    );
  }
}

class StoryReaction {
  final String userId;
  final String userName;
  final String userImage;
  final StoryReactionType type;
  final DateTime timestamp;
  
  StoryReaction({
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.type,
    required this.timestamp,
  });
  
  factory StoryReaction.fromMap(Map<String, dynamic> data) {
    return StoryReaction(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImage: data['userImage'] ?? '',
      type: StoryReactionTypeExtension.fromString(data['type'] ?? 'like'),
      timestamp: _safeParseTimestamp(data['timestamp']),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class StoryReply {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final String message;
  final DateTime createdAt;
  
  StoryReply({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.message,
    required this.createdAt,
  });
  
  factory StoryReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return StoryReply(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImage: data['userImage'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] is Timestamp) 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class StoryPoll {
  final String question;
  final List<StoryPollOption> options;
  final DateTime endTime;
  
  StoryPoll({
    required this.question,
    required this.options,
    required this.endTime,
  });
  
  factory StoryPoll.fromMap(Map<String, dynamic> data) {
    final List<StoryPollOption> options = [];
    if (data['options'] != null) {
      for (var option in data['options']) {
        options.add(StoryPollOption.fromMap(option));
      }
    }
    
    return StoryPoll(
      question: data['question'] ?? '',
      options: options,
      endTime: _safeParseTimestamp(data['endTime']),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options.map((option) => option.toMap()).toList(),
      'endTime': Timestamp.fromDate(endTime),
    };
  }
  
  bool get isEnded {
    return DateTime.now().isAfter(endTime);
  }
  
  int get totalVotes {
    return options.fold(0, (previousValue, option) => previousValue + option.votes.length);
  }

  bool hasUserVoted(String userId) {
    return options.any((option) => option.votes.contains(userId));
  }
}

class StoryPollOption {
  final String text;
  final List<String> votes;
  
  StoryPollOption({
    required this.text,
    required this.votes,
  });
  
  factory StoryPollOption.fromMap(Map<String, dynamic> data) {
    final List<String> votes = [];
    if (data['votes'] != null) {
      for (var userId in data['votes']) {
        votes.add(userId.toString());
      }
    }
    
    return StoryPollOption(
      text: data['text'] ?? '',
      votes: votes,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'votes': votes,
    };
  }
  
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return votes.length / totalVotes * 100;
  }
}

class StoryFilter {
  final String name;
  final List<double> matrix;
  
  const StoryFilter({required this.name, required this.matrix});
  
  static StoryFilter? fromName(String? name) {
    if (name == null) return null;
    return storyFilters.firstWhere(
      (f) => f.name == name,
      orElse: () => storyFilters.first, // Default or null
    );
  }
}

// Pre-defined list of filters
const List<StoryFilter> storyFilters = [
  StoryFilter(name: 'Clarendon', matrix: [
    1.118, -0.013, -0.105, 0, 0,
    -0.076, 1.071, 0.005, 0, 0,
    -0.082, -0.001, 1.083, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  StoryFilter(name: 'Gingham', matrix: [
    1.0, 0, 0, 0, 0.05,
    0, 1.0, 0, 0, 0.05,
    0, 0, 1.0, 0, 0.05,
    0, 0, 0, 1, 0,
  ]),
  StoryFilter(name: 'Moon', matrix: [
    0, 0, 0, 0, 1,
    0, 0, 0, 0, 1,
    0, 0, 0, 0, 1,
    0, 0, 0, 1, 0,
  ]),
  StoryFilter(name: 'Lark', matrix: [
    1.0, 0.05, 0.05, 0, 0,
    0, 1.0, 0, 0, 0,
    0, 0, 1.0, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  StoryFilter(name: 'Reyes', matrix: [
    1.43, -0.13, -0.13, 0, 0,
    -0.13, 1.43, -0.13, 0, 0,
    -0.13, -0.13, 1.43, 0, 0,
    0, 0, 0, 1, 0,
  ]),
];

class StoryItem {
  final String id;
  final StoryMediaType mediaType;
  final String mediaUrl;
  final Duration duration;
  final DateTime timestamp;
  final bool allowSharing;
  final StoryFilter? filter;
  final List<String> viewedBy;
  final List<StoryReaction> reactions;
  final StoryPoll? poll;
  final int shareCount;

  StoryItem({
    required this.id,
    required this.mediaType,
    required this.mediaUrl,
    required this.duration,
    required this.timestamp,
    this.allowSharing = true,
    this.filter,
    this.viewedBy = const [],
    this.reactions = const [],
    this.poll,
    this.shareCount = 0,
  });

  StoryItem copyWith({
    String? id,
    StoryMediaType? mediaType,
    String? mediaUrl,
    Duration? duration,
    DateTime? timestamp,
    bool? allowSharing,
    StoryFilter? filter,
    List<String>? viewedBy,
    List<StoryReaction>? reactions,
    StoryPoll? poll,
    int? shareCount,
  }) {
    return StoryItem(
      id: id ?? this.id,
      mediaType: mediaType ?? this.mediaType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      allowSharing: allowSharing ?? this.allowSharing,
      filter: filter ?? this.filter,
      viewedBy: viewedBy ?? this.viewedBy,
      reactions: reactions ?? this.reactions,
      poll: poll ?? this.poll,
      shareCount: shareCount ?? this.shareCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mediaType': mediaType.name,
      'mediaUrl': mediaUrl,
      'duration': duration.inSeconds,
      'timestamp': Timestamp.fromDate(timestamp),
      'allowSharing': allowSharing,
      'filter': filter?.name,
      'viewedBy': viewedBy,
      'reactions': reactions.map((x) => x.toMap()).toList(),
      'poll': poll?.toMap(),
      'shareCount': shareCount,
    };
  }

  factory StoryItem.fromMap(Map<String, dynamic> map) {
    return StoryItem(
      id: map['id'] ?? '',
      mediaType: StoryMediaTypeExtension.fromString(map['mediaType'] ?? 'image'),
      mediaUrl: map['mediaUrl'] ?? '',
      duration: Duration(seconds: map['duration'] as int? ?? 0),
      timestamp: _safeParseTimestamp(map['timestamp']),
      allowSharing: map['allowSharing'] as bool? ?? true,
      filter: map['filter'] != null ? StoryFilter.fromName(map['filter']) : null,
      viewedBy: List<String>.from(
        (map['viewedBy'] as List<dynamic>?)?.map((value) => value.toString()) ?? [],
      ),
      reactions: ((map['reactions'] as List<dynamic>?)
                  ?.where((value) => value != null)
                  .map((value) {
                    if (value is Map<String, dynamic>) {
                      return StoryReaction.fromMap(value);
                    }
                    // Attempt to coerce types that might be Map<Object, Object>
                    if (value is Map) {
                      return StoryReaction.fromMap(
                        Map<String, dynamic>.from(value),
                      );
                    }
                    return null;
                  })
                  .whereType<StoryReaction>()
                  .toList())
              ?? const <StoryReaction>[],
      poll: map['poll'] != null ? StoryPoll.fromMap(map['poll']) : null,
      shareCount: map['shareCount'] as int? ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory StoryItem.fromJson(String source) =>
      StoryItem.fromMap(json.decode(source));

  @override
  String toString() {
    return 'StoryItem(id: $id, mediaType: $mediaType, mediaUrl: $mediaUrl, duration: $duration, timestamp: $timestamp, allowSharing: $allowSharing, filter: $filter, viewedBy: $viewedBy, reactions: $reactions, poll: $poll, shareCount: $shareCount)';
  }
  
  bool get isExpired {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours >= 24;
  }
  
  int get viewCount => viewedBy.length;
  
  bool hasUserSeen(String userId) {
    return viewedBy.contains(userId);
  }
}

class Story {
  final String id;
  final String userId;
  final String userName;
  final String userImage;
  final List<StoryItem> items;
  final DateTime lastUpdated;
  
  // Client-side property
  final bool hasUnseenItems;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.items,
    required this.lastUpdated,
    this.hasUnseenItems = false,
  });
  
  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final List<StoryItem> items = [];
    if (data['items'] is List) {
      for (final dynamic item in (data['items'] as List)) {
        if (item is Map<String, dynamic>) {
          items.add(StoryItem.fromMap(item));
        } else if (item is Map) {
          items.add(StoryItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    
    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      userImage: data['userImage'] ?? '',
      userName: data['userName'] ?? '',
      items: items,
      lastUpdated: _safeParseTimestamp(data['lastUpdated']),
      // Implement unseen logic
    );
  }
} 