import 'package:flutter/material.dart';
import 'package:sumi/features/video/presentation/pages/video_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sumi/features/auth/presentation/pages/login_page.dart';
import 'package:sumi/l10n/app_localizations.dart';

class VideoTab extends StatelessWidget {
  const VideoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final localizations = AppLocalizations.of(context)!;
    
    // إذا لم يكن المستخدم مسجل الدخول، عرض رسالة تطلب منه تسجيل الدخول
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              localizations.loginRequired,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: Text(localizations.login),
            ),
          ],
        ),
      );
    }
    
    return const VideoPage();
  }
} 