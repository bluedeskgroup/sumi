import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole {
  superAdmin,    // الأدمن الرئيسي
  admin,         // أدمن عادي
  moderator,     // مشرف
}

enum AdminPermission {
  manageMerchants,      // إدارة التجار
  manageUsers,          // إدارة المستخدمين
  manageContent,        // إدارة المحتوى
  viewAnalytics,        // عرض التحليلات
  manageSettings,       // إدارة الإعدادات
  manageNotifications,  // إدارة الإشعارات
}

class AdminModel {
  final String id;
  final String email;
  final String fullName;
  final AdminRole role;
  final List<AdminPermission> permissions;
  final String? profileImageUrl;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp lastLoginAt;
  final String? createdBy;

  AdminModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.permissions,
    this.profileImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.lastLoginAt,
    this.createdBy,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: AdminRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => AdminRole.admin,
      ),
      permissions: _parsePermissions(json['permissions']),
      profileImageUrl: json['profileImageUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? Timestamp.now(),
      lastLoginAt: json['lastLoginAt'] ?? Timestamp.now(),
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role.toString().split('.').last,
      'permissions': permissions.map((p) => p.toString().split('.').last).toList(),
      'profileImageUrl': profileImageUrl,
      'isActive': isActive,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
      'createdBy': createdBy,
    };
  }

  AdminModel copyWith({
    String? id,
    String? email,
    String? fullName,
    AdminRole? role,
    List<AdminPermission>? permissions,
    String? profileImageUrl,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? lastLoginAt,
    String? createdBy,
  }) {
    return AdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool hasPermission(AdminPermission permission) {
    return permissions.contains(permission) || role == AdminRole.superAdmin;
  }

  /// تحليل الـ permissions من أي نوع بيانات
  static List<AdminPermission> _parsePermissions(dynamic permissionsData) {
    if (permissionsData == null) {
      return [AdminPermission.viewAnalytics]; // صلاحية افتراضية
    }

    // إذا كانت List بالفعل
    if (permissionsData is List) {
      return permissionsData
          .map((p) => AdminPermission.values.firstWhere(
                (e) => e.toString().split('.').last == p.toString(),
                orElse: () => AdminPermission.viewAnalytics,
              ))
          .toList();
    }

    // إذا كانت String واحد (مفصولة بفواصل أو أي شكل آخر)
    if (permissionsData is String) {
      // محاولة تحليل النص كـ JSON array
      try {
        final List<dynamic> permissionsList = List<String>.from(
          permissionsData
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty),
        );
        
        return permissionsList
            .map((p) => AdminPermission.values.firstWhere(
                  (e) => e.toString().split('.').last == p.toString(),
                  orElse: () => AdminPermission.viewAnalytics,
                ))
            .toList();
      } catch (e) {
        // في حالة فشل التحليل، إرجاع جميع الصلاحيات للسوبر أدمن
        return AdminPermission.values;
      }
    }

    // نوع بيانات غير متوقع، إرجاع صلاحية افتراضية
    return [AdminPermission.viewAnalytics];
  }
}
