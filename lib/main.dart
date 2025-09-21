import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumi/core/helpers/data_seeder.dart';
import 'package:sumi/features/store/services/cart_service.dart';
import 'package:sumi/features/wallet/services/wallet_service.dart';
import 'package:sumi/features/auth/services/points_service.dart';
import 'package:sumi/features/story/providers/story_settings_provider.dart';
import 'package:sumi/core/theme/app_theme.dart';
import 'package:sumi/services/translation_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sumi/l10n/app_localizations.dart';

import 'core/helpers/search_helpers.dart';
import 'features/auth/presentation/pages/auth_gate.dart';
import 'features/language_selection/presentation/pages/language_selection_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/merchant/presentation/pages/merchant_registration_page.dart';
import 'features/merchant/presentation/pages/merchant_registration_redesign_page.dart';
import 'features/merchant/presentation/pages/merchant_registration_figma_page.dart';
import 'features/merchant/presentation/pages/merchant_login_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/community/presentation/pages/upload_video_page.dart';
import 'features/admin/presentation/pages/admin_login_page.dart';
import 'features/admin/presentation/pages/admin_dashboard_page.dart';
import 'features/admin/services/admin_service.dart';
import 'features/merchant/presentation/pages/advanced_merchant_home_page.dart';
import 'features/merchant/services/merchant_dashboard_service.dart';
import 'features/merchant/services/merchant_order_service.dart';
import 'features/merchant/services/merchant_reservation_service.dart';
import 'features/merchant/services/merchant_product_service.dart';
import 'features/merchant/services/product_variant_service.dart';
import 'features/merchant/services/category_unified_service.dart';
import 'features/user/services/user_product_service.dart';
import 'features/user/presentation/pages/stores_page.dart';
import 'firebase_options.dart';
import 'core/utils/image_error_handler.dart';
import 'core/services/data_prefetch_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تفعيل معالج أخطاء الصور
  ImageErrorHandler.handleGlobalImageErrors();
  
  // تهيئة Firebase فقط - باقي العمليات ستكون lazy
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تفعيل Firebase App Check للإنتاج (معطل مؤقتاً للاختبار)
  try {
    if (!kDebugMode) { // فقط في الإنتاج
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
      debugPrint('Firebase App Check activated successfully');
    } else {
      debugPrint('Firebase App Check disabled in debug mode');
    }
  } catch (e) {
    debugPrint('Firebase App Check activation failed: $e');
    // Continue without App Check if it fails
  }

  // إعداد timeago بدون انتظار
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartService()),
        ChangeNotifierProvider(create: (context) => TranslationService.instance),
        ChangeNotifierProvider(create: (context) => AdminService.instance),
        ChangeNotifierProvider(create: (context) => MerchantDashboardService.instance),
        ChangeNotifierProvider(create: (context) => MerchantOrderService.instance),
        ChangeNotifierProvider(create: (context) => MerchantReservationService.instance),
        ChangeNotifierProvider(create: (context) => MerchantProductService.instance),
        ChangeNotifierProvider(create: (context) => ProductVariantService.instance),
        ChangeNotifierProvider(create: (context) => CategoryUnifiedService.instance),
        ChangeNotifierProvider(create: (context) => UserProductService.instance),
        Provider(create: (context) => WalletService()),
        Provider(create: (context) => PointsService()),
        ChangeNotifierProvider(create: (context) => StorySettingsProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar');
  bool _hasSeenOnboarding = false;
  bool _languageSelected = false;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _firebaseInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // بدء التهيئة بشكل متوازي
      final futures = await Future.wait([
        _checkStatus(),
        _initializeFirebaseServices(),
        Future.delayed(Duration(milliseconds: 500)), // حد أدنى لعرض الـ splash
      ]);
      
      setState(() {
        _isLoading = false;
        _firebaseInitialized = true;
      });

      // Enable persistence and prefetch critical data in background
      // Do not block UI; this will significantly speed up lists and feeds
      DataPrefetchService.enableFirestorePersistence();
      DataPrefetchService.prefetchCriticalData();
    } catch (e) {
      print('خطأ في تهيئة التطبيق: $e');
      setState(() {
        _isLoading = false;
        _firebaseInitialized = true;
      });
    }
  }

  Future<void> _checkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language');
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (mounted) {
        setState(() {
          _languageSelected = savedLanguage != null;
          _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
          _isLoggedIn = currentUser != null;
          if (savedLanguage != null) {
            _locale = Locale(savedLanguage);
          }
        });
      }
    } catch (e) {
      print('خطأ في فحص الحالة: $e');
    }
  }

  Future<void> _initializeFirebaseServices() async {
    try {
      // تهيئة خدمة الترجمات في الخلفية
      TranslationService.instance.initializeDefaultTranslations().catchError((e) {
        print('خطأ في تهيئة الترجمات: $e');
      });
      
      // إعداد مستمع Firebase Auth في الخلفية
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          try {
            final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
            final docSnapshot = await userDoc.get();
            if (!docSnapshot.exists) {
              final searchKeywords = generateKeywords(user.displayName ?? '');
              await userDoc.set({
                'uid': user.uid,
                'email': user.email,
                'displayName': user.displayName,
                'photoURL': user.photoURL,
                'searchKeywords': searchKeywords,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
          } catch (e) {
            print('خطأ في إنشاء مستند المستخدم: $e');
          }
        }
      });
    } catch (e) {
      print('خطأ في تهيئة خدمات Firebase: $e');
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sumi',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      // تأكيد اتجاه الواجهة تلقائياً حسب اللغة (RTL للعربية و LTR للإنجليزية)
      localeResolutionCallback: (locale, supported) {
        if (locale == null) return _locale;
        for (final l in supported) {
          if (l.languageCode == locale.languageCode) return locale;
        }
        return _locale;
      },
      builder: (context, child) {
        final locale = Localizations.localeOf(context);
        final isArabic = locale.languageCode == 'ar';
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        '/splash': (context) => const SplashPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/merchant-registration': (context) => const MerchantRegistrationPage(),
        '/merchant-registration-new': (context) => const MerchantRegistrationRedesignPage(),
        '/merchant-registration-figma': (context) => const MerchantRegistrationFigmaPage(),
        '/merchant-login': (context) => const MerchantLoginPage(),
        '/upload-video': (context) => const UploadVideoPage(),
                  '/admin-login': (context) => const AdminLoginPage(),
          '/admin-dashboard': (context) => const AdminDashboardPage(),
          '/stores': (context) => const StoresPage(),
      },
          home: _isLoading ? _buildSplashScreen() : _buildHome(),
        );
      },
    );
  }

  Widget _buildSplashScreen() {
    return const SplashPage();
  }

  Widget _buildHome() {
    if (!_languageSelected) {
      return const LanguageSelectionPage();
    }
    // إذا كان المستخدم مسجل الدخول، اذهب مباشرة إلى AuthGate (سيحوله إلى HomePage)
    if (_isLoggedIn) {
      return const AuthGate();
    }
    // إذا لم يكن مسجل الدخول ولم يرَ onboarding، أظهر onboarding
    if (!_hasSeenOnboarding) {
      return const OnboardingPage();
    }
    // إذا لم يكن مسجل الدخول وقد رأى onboarding، اذهب إلى AuthGate (سيظهر LoginPage)
    return const AuthGate();
  }
} 