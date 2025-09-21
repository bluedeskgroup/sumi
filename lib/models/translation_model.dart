import 'package:cloud_firestore/cloud_firestore.dart';

class TranslationModel {
  final String id;
  final String key;
  final String arabicText;
  final String englishText;
  final String category;
  final String description;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final bool isActive;

  TranslationModel({
    required this.id,
    required this.key,
    required this.arabicText,
    required this.englishText,
    required this.category,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      id: json['id'] as String,
      key: json['key'] as String,
      arabicText: json['arabicText'] as String,
      englishText: json['englishText'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'arabicText': arabicText,
      'englishText': englishText,
      'category': category,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  TranslationModel copyWith({
    String? id,
    String? key,
    String? arabicText,
    String? englishText,
    String? category,
    String? description,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isActive,
  }) {
    return TranslationModel(
      id: id ?? this.id,
      key: key ?? this.key,
      arabicText: arabicText ?? this.arabicText,
      englishText: englishText ?? this.englishText,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// فئات الترجمة
class TranslationCategory {
  static const String general = 'general';
  static const String jobs = 'jobs';
  static const String auth = 'auth';
  static const String profile = 'profile';
  static const String navigation = 'navigation';
  static const String buttons = 'buttons';
  static const String messages = 'messages';
  static const String errors = 'errors';
  static const String forms = 'forms';
  static const String admin = 'admin';

  static List<String> get allCategories => [
    general,
    jobs,
    auth,
    profile,
    navigation,
    buttons,
    messages,
    errors,
    forms,
    admin,
  ];

  static String getCategoryName(String category, bool isArabic) {
    switch (category) {
      case general:
        return isArabic ? 'عام' : 'General';
      case jobs:
        return isArabic ? 'الوظائف' : 'Jobs';
      case auth:
        return isArabic ? 'المصادقة' : 'Authentication';
      case profile:
        return isArabic ? 'الملف الشخصي' : 'Profile';
      case navigation:
        return isArabic ? 'التنقل' : 'Navigation';
      case buttons:
        return isArabic ? 'الأزرار' : 'Buttons';
      case messages:
        return isArabic ? 'الرسائل' : 'Messages';
      case errors:
        return isArabic ? 'الأخطاء' : 'Errors';
      case forms:
        return isArabic ? 'النماذج' : 'Forms';
      case admin:
        return isArabic ? 'لوحة التحكم' : 'Admin Panel';
      default:
        return category;
    }
  }
}
