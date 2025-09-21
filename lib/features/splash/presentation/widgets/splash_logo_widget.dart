import 'package:flutter/material.dart';

/// ويدجت شعار التطبيق مع التأثيرات البصرية
class SplashLogoWidget extends StatefulWidget {
  final double size;
  final Duration animationDuration;
  final String? logoPath;

  const SplashLogoWidget({
    super.key,
    this.size = 168.0,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.logoPath,
  });

  @override
  State<SplashLogoWidget> createState() => _SplashLogoWidgetState();
}

class _SplashLogoWidgetState extends State<SplashLogoWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // تحريك التكبير
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // تحريك التوهج
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // بدء التحريك
    _scaleController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size * 0.92, // نسبة مناسبة للوجو
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9A46D7).withOpacity(
                    0.3 * _glowAnimation.value,
                  ),
                  blurRadius: 30 * _glowAnimation.value,
                  spreadRadius: 10 * _glowAnimation.value,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                widget.logoPath ?? 'assets/images/logo_splash.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF9A46D7),
                        width: 3,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'سُمي',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9A46D7),
                          fontFamily: 'Almarai',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ويدجت نص مرحب متحرك
class SplashWelcomeText extends StatefulWidget {
  final String text;
  final Duration delay;

  const SplashWelcomeText({
    super.key,
    this.text = 'سُمي',
    this.delay = const Duration(milliseconds: 500),
  });

  @override
  State<SplashWelcomeText> createState() => _SplashWelcomeTextState();
}

class _SplashWelcomeTextState extends State<SplashWelcomeText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // تأخير ثم بدء التحريك
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Text(
              widget.text,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                letterSpacing: 2,
                fontFamily: 'Almarai',
              ),
            ),
          ),
        );
      },
    );
  }
}
