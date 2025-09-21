import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../models/reservation_model.dart';
import 'card_scanner_page.dart';
import '../../services/test_data_seeder.dart';

class ReservationDetailsPage extends StatefulWidget {
  final String reservationId;
  
  const ReservationDetailsPage({
    super.key,
    required this.reservationId,
  });

  @override
  State<ReservationDetailsPage> createState() => _ReservationDetailsPageState();
}

class _ReservationDetailsPageState extends State<ReservationDetailsPage> {
  Map<String, dynamic>? _scannedCardData;
  
  // Sample data - في التطبيق الفعلي يجب جلب البيانات من الخدمة
  final ReservationModel reservation = ReservationModel(
    reservationId: 'RES_001',
    serviceProviderId: 'merchant_123',
    customerId: 'customer_001',
    customerName: 'مي عمرو السيد',
    customerPhone: '01091158519',
    serviceTitle: 'خدمات تجميل متنوعة',
    serviceDescription: 'مجموعة من خدمات التجميل المختلفة',
    reservationDate: DateTime(2024, 4, 11),
    reservationTime: '04:24 الساعه',
    totalAmount: 1907.0,
    status: ReservationStatus.pending,
    paymentStatus: PaymentStatus.pending,
    createdAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _initializeTestData();
  }

  Future<void> _initializeTestData() async {
    // Create test data for card scanning
    try {
      await TestDataSeeder.seedAllTestData();
      TestDataSeeder.printTestCodes();
    } catch (e) {
      debugPrint('Error initializing test data: $e');
    }
  }

  Future<void> _openCardScanner() async {
    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => const CardScannerPage(),
        ),
      );

      if (result != null && result['cardCode'] != null) {
        setState(() {
          _scannedCardData = result;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم مسح البطاقة بنجاح: ${result['customerName']} - ${result['cardCode']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في مسح البطاقة'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            _buildHeader(),
            Expanded(
              child: _buildMainContent(),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 68, 24, 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: const Color(0xFFE7EBEF)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF323F49),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Center(
              child: Container(
                width: 236,
                child: const Text(
                  'تفاصيل الطلب',
                  style: TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF1D2035),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildCustomerEntryDataSection(),
          const SizedBox(height: 28),
          _buildServiceTimeSection(),
          const SizedBox(height: 28),
          _buildCustomerDataSection(),
          const SizedBox(height: 28),
          _buildServiceLocationSection(),
          const SizedBox(height: 28),
          _buildSelectedServicesSection(),
          const SizedBox(height: 28),
          _buildPaymentMethodSection(),
          const SizedBox(height: 28),
          _buildInvoiceSection(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildCustomerEntryDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'بيانات دخول العميل',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 382,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9A46D7)),
          ),
          child: GestureDetector(
            onTap: _openCardScanner,
            child: Row(
              children: [
                Container(
                  width: 25,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _scannedCardData != null 
                        ? const Color(0xFF1ED29C) 
                        : const Color(0xFF1ED29C),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF0C553F), width: 1.17),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _scannedCardData != null 
                            ? 'الكود : ${_scannedCardData!['cardCode']}'
                            : 'الكود : 498904490',
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF0D0C0D),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _scannedCardData != null 
                            ? 'تم مسح البطاقة بنجاح ✓'
                            : 'اضغط لمسح كود البطاقة',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: _scannedCardData != null 
                              ? Colors.green 
                              : const Color(0xFF9A46D7),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  _scannedCardData != null ? Icons.check_circle : Icons.credit_card,
                  size: 24,
                  color: _scannedCardData != null 
                      ? Colors.green 
                      : const Color(0xFF9A46D7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'موعد تقديم الخدمة',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EBEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'يوم الأربعاء :  ${reservation.formattedDate}',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0D0C0D),
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 2),
              const Text(
                'الساعة : 06:00 م الى 07:00م',
                style: TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF9C939D),
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'بيانات العميل',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 382,
          height: 190,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EBEF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Customer info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(45),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 106,
                        height: 25,
                        child: Text(
                          _scannedCardData != null 
                              ? _scannedCardData!['customerName'] 
                              : reservation.customerName,
                          style: const TextStyle(
                            fontFamily: 'Ping AR + LT',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Color(0xFF1D2035),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scannedCardData != null 
                            ? _scannedCardData!['customerPhone'] 
                            : reservation.customerPhone,
                        style: const TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xFF637D92),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Reservation time
              Container(
                width: 321,
                child: Text(
                  'وقت الحجز : ${reservation.reservationTime}',
                  style: const TextStyle(
                    fontFamily: 'Ping AR + LT',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Color(0xFF1D2035),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 20),
              
              // Reservation date
              Text(
                'تاريخ الحجز : ${reservation.formattedDate}',
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: Color(0xFF1D2035),
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'موقع تقديم الخدمة',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 382,
          height: 50,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9A46D7)),
          ),
          child: const Center(
            child: Text(
              'داخل النشاط',
              style: TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF1D2035),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'الخدمات المحددة',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            _buildServiceItem('الخدمة المقدمة مثل الميكب او غيرو', '490'),
            const SizedBox(height: 14),
            _buildServiceItem('الخدمة المقدمة مثل الميكب او غيرو', '604'),
            const SizedBox(height: 14),
            _buildServiceItem('الخدمة المقدمة مثل الميكب او غيرو', '800'),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem(String serviceName, String price) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE4E4E4),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                serviceName,
                style: const TextStyle(
                  fontFamily: 'Ping AR + LT',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF323F49),
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$price ريال',
                    style: const TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF9A46D7),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'طريقة الدفع المستخدمة',
          style: TextStyle(
            fontFamily: 'Ping AR + LT',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1D2035),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 382,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EBEF)),
          ),
          child: Row(
            children: [
              Container(
                width: 25,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF100F11),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFEFE4ED), width: 1.17),
                ),
                child: Container(
                  margin: const EdgeInsets.all(3.75),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7.5,
                        height: 7.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEE0005),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 7.5,
                        height: 7.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9A000),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'MasterCard 6568',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF0D0C0D),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Exp 12/2024',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFF9C939D),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection() {
    return Container(
      width: 382,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'فاتورة الحجز',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w500,
              fontSize: 24,
              color: Color(0xFF141414),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 17),
          Container(
            width: 382,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDE2E4)),
            ),
            child: Column(
              children: [
                // المجموع الفرعي
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '2079 ريال',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                    const Text(
                      'المجموع الفرعي',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF141414),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFDDE2E4),
                ),
                const SizedBox(height: 15),
                
                // صالة انتظار سيارات
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '20 ريال',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                    Text(
                      'صالة انتظار سيارات',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF141414),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFDDE2E4),
                ),
                const SizedBox(height: 15),
                
                // ضريبة القيمة المضافة
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '197 ريال',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                    SizedBox(
                      width: 191,
                      child: Text(
                        'إجمالي ضريبة القيمة المضافة.',
                        style: TextStyle(
                          fontFamily: 'Ping AR + LT',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Color(0xFF141414),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFFDDE2E4),
                ),
                const SizedBox(height: 15),
                
                // إجمالي الطلب
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reservation.totalAmount.toStringAsFixed(0)} ريال',
                      style: const TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        color: Color(0xFF9A46D7),
                      ),
                    ),
                    const Text(
                      'إجمالي الطلب',
                      style: TextStyle(
                        fontFamily: 'Ping AR + LT',
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        color: Color(0xFF141414),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Reject Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم رفض الحجز'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context);
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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم قبول الحجز بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
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
    );
  }
}
