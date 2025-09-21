class ReservationModel {
  final String reservationId;
  final String serviceProviderId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String serviceTitle;
  final String serviceDescription;
  final DateTime reservationDate;
  final String reservationTime;
  final double totalAmount;
  final ReservationStatus status;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReservationModel({
    required this.reservationId,
    required this.serviceProviderId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceTitle,
    required this.serviceDescription,
    required this.reservationDate,
    required this.reservationTime,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      reservationId: map['reservationId'] ?? '',
      serviceProviderId: map['serviceProviderId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      serviceTitle: map['serviceTitle'] ?? '',
      serviceDescription: map['serviceDescription'] ?? '',
      reservationDate: DateTime.parse(map['reservationDate']),
      reservationTime: map['reservationTime'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: ReservationStatus.values.firstWhere(
        (e) => e.toString() == 'ReservationStatus.${map['status']}',
        orElse: () => ReservationStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${map['paymentStatus']}',
        orElse: () => PaymentStatus.pending,
      ),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'serviceProviderId': serviceProviderId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'serviceTitle': serviceTitle,
      'serviceDescription': serviceDescription,
      'reservationDate': reservationDate.toIso8601String(),
      'reservationTime': reservationTime,
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get formattedReservationNumber => '#${reservationId.substring(0, 9).toUpperCase()}';
  
  String get formattedDate {
    final weekdays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    final weekday = weekdays[reservationDate.weekday - 1];
    return '${reservationDate.day.toString().padLeft(2, '0')}/${reservationDate.month.toString().padLeft(2, '0')}/${reservationDate.year} يوم $weekday';
  }
  
  String get statusText {
    switch (status) {
      case ReservationStatus.pending:
        return 'في انتظار الموافقة';
      case ReservationStatus.confirmed:
        return 'مؤكد';
      case ReservationStatus.completed:
        return 'مكتمل';
      case ReservationStatus.cancelled:
        return 'ملغي';
      case ReservationStatus.rejected:
        return 'مرفوض';
    }
  }
}

enum ReservationStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  rejected,
}

enum PaymentStatus {
  pending,
  paid,
  refunded,
  failed,
}
