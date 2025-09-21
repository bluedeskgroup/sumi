import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String title;
  final String description;
  final String companyName;
  final String location;
  final String jobType; // دوام كامل، دوام جزئي، تدريب، etc
  final String category;
  final double? salaryMin;
  final double? salaryMax;
  final String salaryCurrency;
  final List<String> requirements;
  final List<String> benefits;
  final String contactEmail;
  final String contactPhone;
  final String publisherId; // معرف التاجر اللي نشر الوظيفة
  final String publisherName;
  final String publisherImageUrl;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final bool isFeatured;
  final int applicationsCount;
  final Map<String, dynamic>? metadata;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.companyName,
    required this.location,
    required this.jobType,
    required this.category,
    this.salaryMin,
    this.salaryMax,
    this.salaryCurrency = 'ج.م',
    this.requirements = const [],
    this.benefits = const [],
    required this.contactEmail,
    required this.contactPhone,
    required this.publisherId,
    required this.publisherName,
    this.publisherImageUrl = '',
    required this.publishedAt,
    this.expiresAt,
    this.isActive = true,
    this.isFeatured = false,
    this.applicationsCount = 0,
    this.metadata,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      companyName: json['companyName'] ?? '',
      location: json['location'] ?? '',
      jobType: json['jobType'] ?? '',
      category: json['category'] ?? '',
      salaryMin: json['salaryMin']?.toDouble(),
      salaryMax: json['salaryMax']?.toDouble(),
      salaryCurrency: json['salaryCurrency'] ?? 'ج.م',
      requirements: List<String>.from(json['requirements'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      publisherId: json['publisherId'] ?? '',
      publisherName: json['publisherName'] ?? '',
      publisherImageUrl: json['publisherImageUrl'] ?? '',
      publishedAt: (json['publishedAt'] as Timestamp).toDate(),
      expiresAt: json['expiresAt'] != null ? (json['expiresAt'] as Timestamp).toDate() : null,
      isActive: json['isActive'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      applicationsCount: json['applicationsCount'] ?? 0,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'companyName': companyName,
      'location': location,
      'jobType': jobType,
      'category': category,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'requirements': requirements,
      'benefits': benefits,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'publisherId': publisherId,
      'publisherName': publisherName,
      'publisherImageUrl': publisherImageUrl,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'applicationsCount': applicationsCount,
      'metadata': metadata,
    };
  }

  String getSalaryRange() {
    if (salaryMin != null && salaryMax != null) {
      return '${salaryMin!.toInt()} - ${salaryMax!.toInt()} $salaryCurrency';
    } else if (salaryMin != null) {
      return 'من ${salaryMin!.toInt()} $salaryCurrency';
    } else if (salaryMax != null) {
      return 'حتى ${salaryMax!.toInt()} $salaryCurrency';
    }
    return 'غير محدد';
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  JobModel copyWith({
    String? id,
    String? title,
    String? description,
    String? companyName,
    String? location,
    String? jobType,
    String? category,
    double? salaryMin,
    double? salaryMax,
    String? salaryCurrency,
    List<String>? requirements,
    List<String>? benefits,
    String? contactEmail,
    String? contactPhone,
    String? publisherId,
    String? publisherName,
    String? publisherImageUrl,
    DateTime? publishedAt,
    DateTime? expiresAt,
    bool? isActive,
    bool? isFeatured,
    int? applicationsCount,
    Map<String, dynamic>? metadata,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      companyName: companyName ?? this.companyName,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      category: category ?? this.category,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      publisherId: publisherId ?? this.publisherId,
      publisherName: publisherName ?? this.publisherName,
      publisherImageUrl: publisherImageUrl ?? this.publisherImageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      metadata: metadata ?? this.metadata,
    );
  }
}
