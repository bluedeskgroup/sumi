import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/splash_logo_widget.dart';
import '../widgets/loading_indicator_widget.dart';

/// صفحة البداية (Splash Screen) للتطبيق
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد شريط الحالة
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    // إعداد الرسوم المتحركة
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    // بدء الرسوم المتحركة
    _animationController.forward();

    // الانتقال إلى الصفحة الرئيسية بعد 3 ثوانٍ
    _navigateToHome();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              // محتوى الشاشة الرئيسي
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // شعار التطبيق مع التأثيرات
                              const SplashLogoWidget(
                                size: 168,
                                animationDuration: Duration(milliseconds: 1500),
                              ),
                              
                              const SizedBox(height: 60),
                              
                              // نص اسم التطبيق مع تحريك
                              const SplashWelcomeText(
                                text: 'سُمي',
                                delay: Duration(milliseconds: 800),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // مؤشر التحميل المتطور
              const Padding(
                padding: EdgeInsets.only(bottom: 100),
                child: CustomLoadingIndicator(
                  size: 57,
                  strokeWidth: 7,
                  color: Color(0xFF9A46D7),
                  backgroundColor: Color(0x339A46D7),
                  duration: Duration(milliseconds: 1500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شاشة بداية مخصصة للتطبيق
class CustomSplashScreen extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color backgroundColor;

  const CustomSplashScreen({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.backgroundColor = Colors.white,
  });

  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (_animation.isCompleted) {
          return widget.child;
        }
        
        return Container(
          color: widget.backgroundColor,
          child: const Center(
            child: SplashPage(),
          ),
        );
      },
    );
  }
}
