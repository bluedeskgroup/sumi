import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/pages/merchant_registration_page.dart';

/// Widget حماية لصفحة تسجيل التاجر - يتأكد من أن المستخدم مسجل دخول أولاً
class MerchantRegistrationGuard extends StatelessWidget {
  const MerchantRegistrationGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // أثناء التحميل
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'جارٍ التحقق من حالة تسجيل الدخول...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // إذا لم يكن مسجل دخول
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('تسجيل حساب تاجر'),
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'يجب تسجيل الدخول أولاً',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لتسجيل حساب تاجر، يجب أن يكون لديك حساب مستخدم في التطبيق أولاً.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/login');
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('تسجيل الدخول'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('العودة للخلف'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF667EEA)),
                              foregroundColor: const Color(0xFF667EEA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // المستخدم مسجل دخول، يمكن عرض صفحة التسجيل
        return const MerchantRegistrationPage();
      },
    );
  }
}
