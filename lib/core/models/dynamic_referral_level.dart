import 'package:cloud_firestore/cloud_firestore.dart';

class DynamicReferralLevel {
  final String id;
  final String nameAr;
  final String nameEn;
  final int percentage;
  final int threshold;
  final String colorHex;
  final String iconCode;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DynamicReferralLevel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.percentage,
    required this.threshold,
    required this.colorHex,
    required this.iconCode,
    required this.order,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory DynamicReferralLevel.fromMap(String id, Map<String, dynamic> data) {
    return DynamicReferralLevel(
      id: id,
      nameAr: data['nameAr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      percentage: data['percentage'] ?? 0,
      threshold: data['threshold'] ?? 0,
      colorHex: data['colorHex'] ?? '#9A46D7',
      iconCode: data['iconCode'] ?? '🏆',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'percentage': percentage,
      'threshold': threshold,
      'colorHex': colorHex,
      'iconCode': iconCode,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  DynamicReferralLevel copyWith({
    String? nameAr,
    String? nameEn,
    int? percentage,
    int? threshold,
    String? colorHex,
    String? iconCode,
    int? order,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return DynamicReferralLevel(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      percentage: percentage ?? this.percentage,
      threshold: threshold ?? this.threshold,
      colorHex: colorHex ?? this.colorHex,
      iconCode: iconCode ?? this.iconCode,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicReferralLevel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Helper class for level calculations
class ReferralLevelCalculator {
  static DynamicReferralLevel? getUserLevel(
    int referralsCount,
    List<DynamicReferralLevel> levels,
  ) {
    if (levels.isEmpty) return null;
    
    // Sort levels by threshold descending
    final sortedLevels = List<DynamicReferralLevel>.from(levels)
      ..sort((a, b) => b.threshold.compareTo(a.threshold));
    
    // Find the highest level the user qualifies for
    for (final level in sortedLevels) {
      if (level.isActive && referralsCount >= level.threshold) {
        return level;
      }
    }
    
    // Return the lowest level if user doesn't qualify for any
    final lowestLevel = levels
        .where((level) => level.isActive)
        .reduce((a, b) => a.threshold < b.threshold ? a : b);
    
    return lowestLevel;
  }

  static DynamicReferralLevel? getNextLevel(
    int referralsCount,
    List<DynamicReferralLevel> levels,
  ) {
    if (levels.isEmpty) return null;
    
    final currentLevel = getUserLevel(referralsCount, levels);
    if (currentLevel == null) return null;
    
    // Find the next level
    final nextLevels = levels
        .where((level) => 
            level.isActive && 
            level.threshold > currentLevel.threshold)
        .toList()
      ..sort((a, b) => a.threshold.compareTo(b.threshold));
    
    return nextLevels.isNotEmpty ? nextLevels.first : null;
  }

  static int getReferralsNeededForNextLevel(
    int referralsCount,
    List<DynamicReferralLevel> levels,
  ) {
    final nextLevel = getNextLevel(referralsCount, levels);
    if (nextLevel == null) return 0;
    
    return nextLevel.threshold - referralsCount;
  }
}

// Default levels for initialization
class DefaultReferralLevels {
  static List<Map<String, dynamic>> getDefaultLevels() {
    return [
      {
        'nameAr': 'البرونزية',
        'nameEn': 'Bronze',
        'percentage': 3,
        'threshold': 0,
        'colorHex': '#CD7F32',
        'iconCode': '🥉',
        'order': 1,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'nameAr': 'الفضية',
        'nameEn': 'Silver',
        'percentage': 4,
        'threshold': 20,
        'colorHex': '#C0C0C0',
        'iconCode': '🥈',
        'order': 2,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'nameAr': 'الذهبية',
        'nameEn': 'Gold',
        'percentage': 7,
        'threshold': 50,
        'colorHex': '#FFD700',
        'iconCode': '🥇',
        'order': 3,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];
  }
}