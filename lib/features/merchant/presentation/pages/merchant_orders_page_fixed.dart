import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../services/merchant_order_service.dart';
import 'advanced_order_details_page.dart';

class MerchantOrdersPage extends StatefulWidget {
  const MerchantOrdersPage({super.key});

  @override
  State<MerchantOrdersPage> createState() => _MerchantOrdersPageState();
}

class _MerchantOrdersPageState extends State<MerchantOrdersPage> {
  late MerchantOrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = Provider.of<MerchantOrderService>(context, listen: false);
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
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          title: const Text(
            'الطلبات',
            style: TextStyle(
              fontFamily: 'Ping AR + LT',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1D2035),
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Store Status Toggle
            _buildStoreStatusSection(),
            
            // Tabs Section
            _buildTabsSection(),
            
            // Orders List
            Expanded(
              child: _buildOrdersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreStatusSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
            'حالة المتجر',
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
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      width: 382,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          // طلبات الحجز
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('طلبات الحجز - قيد التطوير'),
                    backgroundColor: Colors.blue,
                  ),
                );
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
                    'طلبات الحجز',
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
          // طلبات الشراء (Active)
          Expanded(
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('أنت في قسم طلبات الشراء'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(5),
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBD9FB),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text(
                    'طلبات الشراء',
                    style: TextStyle(
                      fontFamily: 'Ping AR + LT',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF9A46D7),
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

  Widget _buildOrdersList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSimpleOrderCard(
            orderNumber: '#544658468',
            customerName: 'مي عمرو السيد',
            location: 'السعودية ، الرياض الحي الرابع',
            amount: '4609 ريال',
          );
        } else if (index == 1) {
          return _buildSimpleOrderCard(
            orderNumber: '#544658468',
            customerName: 'مي عمرو السيد',
            location: 'السعودية ، الرياض الحي الرابع',
            amount: '4609 ريال',
          );
        } else {
          return _buildSimpleOrderCard(
            orderNumber: '#544658468',
            customerName: 'مي عمرو السيد',
            location: 'مصر ، طنطا، القاهرة',
            amount: '4609 ريال',
          );
        }
      },
    );
  }

  Widget _buildSimpleOrderCard({
    required String orderNumber,
    required String customerName,
    required String location,
    required String amount,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdvancedOrderDetailsPage(orderId: 'ORDER_001'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
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
              'رقم الطلب: $orderNumber',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF1D2035),
              ),
            ),
            const SizedBox(height: 16),
            
            // Customer Name
            Text(
              'أسم العميل : $customerName',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF1D2035),
              ),
            ),
            const SizedBox(height: 16),
            
            // Location
            Text(
              'الموقع : $location',
              style: const TextStyle(
                fontFamily: 'Ping AR + LT',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF1D2035),
              ),
            ),
            const SizedBox(height: 16),
            
            // Amount
            Text(
              'قيمة الطلب : $amount',
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
                    builder: (context) => const AdvancedOrderDetailsPage(orderId: 'ORDER_001'),
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdvancedOrderDetailsPage(orderId: 'ORDER_001'),
                        ),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdvancedOrderDetailsPage(orderId: 'ORDER_001'),
                        ),
                      );
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
      ),
    );
  }
}
