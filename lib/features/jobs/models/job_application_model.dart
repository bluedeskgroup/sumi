import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplicationModel {
  final String id;
  final String jobId;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final String? applicantImageUrl;
  final String coverLetter;
  final String resumeUrl;
  final List<String> skills;
  final int experienceYears;
  final String education;
  final String currentJobTitle;
  final DateTime appliedAt;
  final ApplicationStatus status;
  final String? employerNotes;
  final DateTime? statusUpdatedAt;
  final Map<String, dynamic>? metadata;

  JobApplicationModel({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    this.applicantImageUrl,
    this.coverLetter = '',
    this.resumeUrl = '',
    this.skills = const [],
    this.experienceYears = 0,
    this.education = '',
    this.currentJobTitle = '',
    required this.appliedAt,
    this.status = ApplicationStatus.pending,
    this.employerNotes,
    this.statusUpdatedAt,
    this.metadata,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      applicantId: json['applicantId'] ?? '',
      applicantName: json['applicantName'] ?? '',
      applicantEmail: json['applicantEmail'] ?? '',
      applicantPhone: json['applicantPhone'] ?? '',
      applicantImageUrl: json['applicantImageUrl'],
      coverLetter: json['coverLetter'] ?? '',
      resumeUrl: json['resumeUrl'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      experienceYears: json['experienceYears'] ?? 0,
      education: json['education'] ?? '',
      currentJobTitle: json['currentJobTitle'] ?? '',
      appliedAt: (json['appliedAt'] as Timestamp).toDate(),
      status: ApplicationStatus.fromString(json['status'] ?? 'pending'),
      employerNotes: json['employerNotes'],
      statusUpdatedAt: json['statusUpdatedAt'] != null 
          ? (json['statusUpdatedAt'] as Timestamp).toDate() 
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhone': applicantPhone,
      'applicantImageUrl': applicantImageUrl,
      'coverLetter': coverLetter,
      'resumeUrl': resumeUrl,
      'skills': skills,
      'experienceYears': experienceYears,
      'education': education,
      'currentJobTitle': currentJobTitle,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'status': status.toString(),
      'employerNotes': employerNotes,
      'statusUpdatedAt': statusUpdatedAt != null 
          ? Timestamp.fromDate(statusUpdatedAt!) 
          : null,
      'metadata': metadata,
    };
  }

  JobApplicationModel copyWith({
    String? id,
    String? jobId,
    String? applicantId,
    String? applicantName,
    String? applicantEmail,
    String? applicantPhone,
    String? applicantImageUrl,
    String? coverLetter,
    String? resumeUrl,
    List<String>? skills,
    int? experienceYears,
    String? education,
    String? currentJobTitle,
    DateTime? appliedAt,
    ApplicationStatus? status,
    String? employerNotes,
    DateTime? statusUpdatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return JobApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      applicantImageUrl: applicantImageUrl ?? this.applicantImageUrl,
      coverLetter: coverLetter ?? this.coverLetter,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      skills: skills ?? this.skills,
      experienceYears: experienceYears ?? this.experienceYears,
      education: education ?? this.education,
      currentJobTitle: currentJobTitle ?? this.currentJobTitle,
      appliedAt: appliedAt ?? this.appliedAt,
      status: status ?? this.status,
      employerNotes: employerNotes ?? this.employerNotes,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum ApplicationStatus {
  pending,
  reviewing,
  shortlisted,
  interviewed,
  accepted,
  rejected;

  static ApplicationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return ApplicationStatus.pending;
      case 'reviewing':
        return ApplicationStatus.reviewing;
      case 'shortlisted':
        return ApplicationStatus.shortlisted;
      case 'interviewed':
        return ApplicationStatus.interviewed;
      case 'accepted':
        return ApplicationStatus.accepted;
      case 'rejected':
        return ApplicationStatus.rejected;
      default:
        return ApplicationStatus.pending;
    }
  }

  String toArabic() {
    switch (this) {
      case ApplicationStatus.pending:
        return 'قيد المراجعة';
      case ApplicationStatus.reviewing:
        return 'تحت المراجعة';
      case ApplicationStatus.shortlisted:
        return 'مرشح نهائي';
      case ApplicationStatus.interviewed:
        return 'تم المقابلة';
      case ApplicationStatus.accepted:
        return 'مقبول';
      case ApplicationStatus.rejected:
        return 'مرفوض';
    }
  }

  @override
  String toString() {
    return name;
  }
}
