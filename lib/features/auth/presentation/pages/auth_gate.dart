import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sumi/features/auth/presentation/pages/login_page.dart';
import 'package:sumi/features/home/presentation/pages/home_page.dart';
import 'package:sumi/features/merchant/presentation/pages/main_merchant_page.dart';
import 'package:sumi/features/merchant/presentation/pages/merchant_pending_approval_page.dart';
import 'package:sumi/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:sumi/core/services/user_type_service.dart';
import 'package:sumi/features/merchant/models/merchant_model.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginPage();
        }
        
        // المستخدم مسجل دخول، نحتاج لفحص نوعه
        return FutureBuilder<String?>(
          future: UserTypeService.getUserType(),
          builder: (context, userTypeSnapshot) {
            if (!userTypeSnapshot.hasData) {
              // لا يوجد نوع محفوظ، اعتبره مستخدم عادي
              return const HomePage();
            }
            
            final userType = userTypeSnapshot.data!;
            
            switch (userType) {
              case UserTypeService.typeMerchant:
                // تاجر - جلب بيانات التاجر الحقيقية من Firestore
                return FutureBuilder<MerchantModel?>(
                  future: UserTypeService.getMerchantData(),
                  builder: (context, merchantSnapshot) {
                    if (merchantSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (merchantSnapshot.hasError || !merchantSnapshot.hasData) {
                      // في حالة عدم وجود بيانات التاجر، توجيه إلى الصفحة الرئيسية العادية
                      return const HomePage();
                    }
                    
                    final merchant = merchantSnapshot.data!;
                    
                    // فحص حالة التاجر
                    if (merchant.status == MerchantStatus.pending) {
                      // تاجر قيد المراجعة - توجيه لصفحة انتظار الموافقة
                      return MerchantPendingApprovalPage(merchantId: merchant.id);
                    } else if (merchant.status == MerchantStatus.approved) {
                      // تاجر معتمد - توجيه للصفحة الرئيسية المتقدمة
                      return MainMerchantPage(merchantId: merchant.id);
                    } else {
                      // تاجر مرفوض أو معلق - توجيه للصفحة الرئيسية العادية
                      return const HomePage();
                    }
                  },
                );
              case UserTypeService.typeAdmin:
                // أدمن - إرسال لصفحة الأدمن
                return const AdminDashboardPage();
              default:
                // مستخدم عادي أو نوع غير معروف
                return const HomePage();
            }
          },
        );
      },
    );
  }
}