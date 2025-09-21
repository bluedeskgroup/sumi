import 'package:flutter/material.dart';
import 'package:sumi/features/home/presentation/pages/home_page.dart';

class OrderConfirmationPage extends StatelessWidget {
  const OrderConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'تم استلام طلبك بنجاح!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'شكرًا لطلبك. سنتواصل معك قريبًا لتأكيد تفاصيل الشحن.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'رقم الطلب: #${DateTime.now().millisecondsSinceEpoch}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('العودة إلى الرئيسية', style: TextStyle(fontSize: 18, fontFamily: 'Almarai', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 