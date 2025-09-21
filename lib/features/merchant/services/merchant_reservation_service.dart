import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';

class MerchantReservationService extends ChangeNotifier {
  static final MerchantReservationService _instance = MerchantReservationService._internal();
  static MerchantReservationService get instance => _instance;
  
  MerchantReservationService._internal();
  
  factory MerchantReservationService() => _instance;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ReservationModel> _reservations = [];
  bool _isLoading = false;
  String? _error;

  List<ReservationModel> get reservations => _reservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all reservations for a merchant
  Future<List<ReservationModel>> getMerchantReservations(String merchantId) async {
    try {
      _setLoading(true);
      _error = null;

      final querySnapshot = await _firestore
          .collection('reservations')
          .where('serviceProviderId', isEqualTo: merchantId)
          .orderBy('createdAt', descending: true)
          .get();

      _reservations = querySnapshot.docs
          .map((doc) => ReservationModel.fromMap({...doc.data(), 'reservationId': doc.id}))
          .toList();

      return _reservations;
    } catch (e) {
      _error = 'خطأ في جلب الحجوزات: $e';
      debugPrint('Error fetching merchant reservations: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Get reservation by ID
  Future<ReservationModel?> getReservationById(String reservationId) async {
    try {
      final doc = await _firestore.collection('reservations').doc(reservationId).get();
      
      if (doc.exists) {
        return ReservationModel.fromMap({...doc.data()!, 'reservationId': doc.id});
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching reservation: $e');
      return null;
    }
  }

  // Update reservation status
  Future<bool> updateReservationStatus(String reservationId, ReservationStatus status) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update local list
      final index = _reservations.indexWhere((r) => r.reservationId == reservationId);
      if (index != -1) {
        _reservations[index] = ReservationModel.fromMap({
          ..._reservations[index].toMap(),
          'status': status.toString().split('.').last,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'خطأ في تحديث حالة الحجز: $e';
      debugPrint('Error updating reservation status: $e');
      return false;
    }
  }

  // Accept reservation
  Future<bool> acceptReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, ReservationStatus.confirmed);
  }

  // Reject reservation
  Future<bool> rejectReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, ReservationStatus.rejected);
  }

  // Complete reservation
  Future<bool> completeReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, ReservationStatus.completed);
  }

  // Cancel reservation
  Future<bool> cancelReservation(String reservationId) async {
    return await updateReservationStatus(reservationId, ReservationStatus.cancelled);
  }

  // Get reservations statistics
  Map<String, int> getReservationsStatistics() {
    final stats = {
      'total': _reservations.length,
      'pending': 0,
      'confirmed': 0,
      'completed': 0,
      'cancelled': 0,
      'rejected': 0,
    };

    for (final reservation in _reservations) {
      switch (reservation.status) {
        case ReservationStatus.pending:
          stats['pending'] = (stats['pending'] ?? 0) + 1;
          break;
        case ReservationStatus.confirmed:
          stats['confirmed'] = (stats['confirmed'] ?? 0) + 1;
          break;
        case ReservationStatus.completed:
          stats['completed'] = (stats['completed'] ?? 0) + 1;
          break;
        case ReservationStatus.cancelled:
          stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
          break;
        case ReservationStatus.rejected:
          stats['rejected'] = (stats['rejected'] ?? 0) + 1;
          break;
      }
    }

    return stats;
  }

  // Search reservations
  List<ReservationModel> searchReservations(String query) {
    if (query.isEmpty) return _reservations;
    
    return _reservations.where((reservation) {
      return reservation.customerName.toLowerCase().contains(query.toLowerCase()) ||
             reservation.serviceTitle.toLowerCase().contains(query.toLowerCase()) ||
             reservation.reservationId.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get new reservations (last 24 hours)
  List<ReservationModel> getNewReservations() {
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    return _reservations.where((reservation) => 
      reservation.createdAt.isAfter(yesterday)
    ).toList();
  }

  // Get upcoming reservations
  List<ReservationModel> getUpcomingReservations() {
    final now = DateTime.now();
    return _reservations.where((reservation) => 
      reservation.reservationDate.isAfter(now) && 
      reservation.status == ReservationStatus.confirmed
    ).toList();
  }

  // Get overdue reservations
  List<ReservationModel> getOverdueReservations() {
    final now = DateTime.now();
    return _reservations.where((reservation) => 
      reservation.reservationDate.isBefore(now) && 
      reservation.status == ReservationStatus.confirmed
    ).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Create sample reservations for testing
  Future<void> createSampleReservations(String merchantId) async {
    final sampleReservations = [
      {
        'serviceProviderId': merchantId,
        'customerId': 'customer1',
        'customerName': 'مي عمرو السيد',
        'customerPhone': '0570151550',
        'serviceTitle': 'قص شعر وتسريح',
        'serviceDescription': 'قص شعر احترافي مع تسريح',
        'reservationDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'reservationTime': '04.24 الساعه',
        'totalAmount': 150.0,
        'status': ReservationStatus.pending.toString().split('.').last,
        'paymentStatus': PaymentStatus.pending.toString().split('.').last,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'serviceProviderId': merchantId,
        'customerId': 'customer2',
        'customerName': 'أحمد محمد علي',
        'customerPhone': '0555123456',
        'serviceTitle': 'جلسة مساج استرخاء',
        'serviceDescription': 'جلسة مساج كاملة للاسترخاء',
        'reservationDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'reservationTime': '02.30 الساعه',
        'totalAmount': 200.0,
        'status': ReservationStatus.confirmed.toString().split('.').last,
        'paymentStatus': PaymentStatus.paid.toString().split('.').last,
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'serviceProviderId': merchantId,
        'customerId': 'customer3',
        'customerName': 'فاطمة أحمد',
        'customerPhone': '0566789012',
        'serviceTitle': 'تنظيف بشرة',
        'serviceDescription': 'جلسة تنظيف بشرة عميق',
        'reservationDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'reservationTime': '10.00 الساعه',
        'totalAmount': 180.0,
        'status': ReservationStatus.pending.toString().split('.').last,
        'paymentStatus': PaymentStatus.pending.toString().split('.').last,
        'createdAt': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      }
    ];

    try {
      for (final reservation in sampleReservations) {
        await _firestore.collection('reservations').add(reservation);
      }
      debugPrint('Sample reservations created successfully');
    } catch (e) {
      debugPrint('Error creating sample reservations: $e');
    }
  }
}
