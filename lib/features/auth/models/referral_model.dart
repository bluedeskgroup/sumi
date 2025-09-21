import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sumi/core/models/dynamic_referral_level.dart';
import 'package:sumi/core/services/dynamic_levels_service.dart';

class ReferralStats {
  final double currentBalance;
  final double totalEarnings;
  final int referralsCount;
  final String referralCode;
  final DynamicReferralLevel? level;

  ReferralStats({
    required this.currentBalance,
    required this.totalEarnings,
    required this.referralsCount,
    required this.referralCode,
    this.level,
  });

  factory ReferralStats.fromMap(Map<String, dynamic> data, String referralCode) {
    final referralsCount = data['referralsCount'] ?? 0;
    final levelsService = DynamicLevelsService();
    final level = levelsService.getUserLevel(referralsCount);

    return ReferralStats(
      currentBalance: (data['currentBalance'] ?? 0.0).toDouble(),
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      referralsCount: referralsCount,
      referralCode: referralCode,
      level: level,
    );
  }

  factory ReferralStats.initial(String referralCode) {
    final levelsService = DynamicLevelsService();
    final level = levelsService.getUserLevel(0);

    return ReferralStats(
      currentBalance: 0.0,
      totalEarnings: 0.0,
      referralsCount: 0,
      referralCode: referralCode,
      level: level,
    );
  }
}

class ReferralTransaction {
  final String id;
  final String type; // 'referral_signup', 'points_used', 'withdrawal'
  final String description;
  final double amount;
  final DateTime timestamp;
  final String? relatedUserId;
  final String? relatedUserName;

  ReferralTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.timestamp,
    this.relatedUserId,
    this.relatedUserName,
  });

  factory ReferralTransaction.fromMap(String id, Map<String, dynamic> data) {
    return ReferralTransaction(
      id: id,
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      relatedUserId: data['relatedUserId'],
      relatedUserName: data['relatedUserName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'relatedUserId': relatedUserId,
      'relatedUserName': relatedUserName,
    };
  }

  String getFormattedDate(bool isRtl) {
    final weekdays = isRtl
        ? ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']
        : ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    final months = isRtl
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 
           'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : ['January', 'February', 'March', 'April', 'May', 'June',
           'July', 'August', 'September', 'October', 'November', 'December'];

    final weekday = weekdays[timestamp.weekday % 7];
    final month = months[timestamp.month - 1];
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');

    if (isRtl) {
      return 'يوم $weekday ${timestamp.day} $month ${timestamp.year} . الساعة $hour:$minute';
    } else {
      return '$weekday ${timestamp.day} $month ${timestamp.year} . $hour:$minute';
    }
  }
}

class WithdrawalRecord {
  final String id;
  final double amount;
  final DateTime timestamp;
  final String status; // 'pending', 'completed', 'rejected'
  final String? rejectionReason;

  WithdrawalRecord({
    required this.id,
    required this.amount,
    required this.timestamp,
    required this.status,
    this.rejectionReason,
  });

  factory WithdrawalRecord.fromMap(String id, Map<String, dynamic> data) {
    return WithdrawalRecord(
      id: id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'rejectionReason': rejectionReason,
    };
  }
}