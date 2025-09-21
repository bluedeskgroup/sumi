import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../services/merchant_reservation_service.dart';
import '../../models/reservation_model.dart';
import 'reservation_details_page.dart';

class MerchantReservationsPage extends StatefulWidget {
  const MerchantReservationsPage({super.key});

  @override
  State<MerchantReservationsPage> createState() => _MerchantReservationsPageState();
}

class _MerchantReservationsPageState extends State<MerchantReservationsPage> {
  late MerchantReservationService _reservationService;
  List<ReservationModel> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reservationService = Provider.of<MerchantReservationService>(context, listen: false);
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
    });

    // For demo purposes, create sample data
    await _reservationService.createSampleReservations('merchant_123');
    
    final reservations = await _reservationService.getMerchantReservations('merchant_123');
    setState(() {
      _reservations = reservations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        body: Column(
          children: [
            // Store Status Section
            _buildStoreStatusSection(),
            
            // Tabs Section
            _buildTabsSection(),
            
            // Reservations List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildReservationsList(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildStoreStatusSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF6F8F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'حالة المتجر ',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
          ),
          Row(
            children: [
              const Text(
                'مغلق',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xFF7991A4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF1AB385),
                  borderRadius: BorderRadius.circular(1000),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1AB385), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'فعال',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xFF1AB385),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      width: 382,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          // طلبات الحجز (Active)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(5),
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEBD9FB),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  'طلبات الحجز',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF9A46D7),
                  ),
                ),
              ),
            ),
          ),
          // طلبات الشراء
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.all(5),
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    'طلبات الشراء',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF808D9E),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    if (_reservations.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد طلبات حجز',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontSize: 16,
            color: Color(0xFF7991A4),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _reservations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildReservationCard(_reservations[index]);
      },
    );
  }

  Widget _buildReservationCard(ReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Order Number
          Text(
            'رقم الطلب: ${reservation.formattedReservationNumber}',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 16),
          
          // Reservation Time
          Text(
            'وقت الحجز : ${reservation.reservationTime}',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 16),
          
          // Reservation Date
          Text(
            'تاريخ الحجز : ${reservation.formattedDate}',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 16),
          
          // Total Amount
          Text(
            'قيمة الطلب : ${reservation.totalAmount.toStringAsFixed(0)} ريال',
            style: const TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF1D2035),
            ),
          ),
          const SizedBox(height: 16),
          
          // Details Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReservationDetailsPage(reservationId: reservation.reservationId),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF292D32),
                  ),
                  const Text(
                    'تفاصيل الطلب',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Color(0xFF141414),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              // Reject Button
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _reservationService.rejectReservation(reservation.reservationId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم رفض الحجز'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    _loadReservations();
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFADCDF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'رفض',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFFE84E5D),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Accept Button
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _reservationService.acceptReservation(reservation.reservationId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم قبول الحجز بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadReservations();
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1AB385),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'موافقة',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF141936),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 31.7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.grid_view,
              label: 'المزيد',
              isActive: false,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.store,
              label: 'المنتجات',
              isActive: false,
              onTap: () {},
            ),
            _buildAddButton(),
            _buildNavItem(
              icon: Icons.inbox,
              label: 'الطلبات',
              isActive: true,
              onTap: () {},
            ),
            _buildNavItem(
              icon: Icons.home,
              label: 'الرئيسية',
              isActive: false,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? const Color(0xFF9A46D7) : const Color(0xFFAAB9C5),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isActive ? const Color(0xFF9A46D7) : const Color(0xFFC9CEDC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF9A46D7),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
