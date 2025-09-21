import 'dart:math' as math;
import 'package:flutter/material.dart';

/// مؤشر تحميل دائري مخصص يطابق تصميم الفيجما
class CustomLoadingIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final Duration duration;

  const CustomLoadingIndicator({
    super.key,
    this.size = 57.0,
    this.strokeWidth = 7.0,
    this.color = const Color(0xFF9A46D7),
    this.backgroundColor = const Color(0x339A46D7),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: CustomPaint(
              painter: _LoadingPainter(
                progress: _controller.value,
                strokeWidth: widget.strokeWidth,
                color: widget.color,
                backgroundColor: widget.backgroundColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  _LoadingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // رسم الدائرة الخلفية
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // رسم القوس المتحرك
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // البداية من الأعلى
    const sweepAngle = math.pi; // نصف دائرة

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// مؤشر تحميل متدرج متقدم
class GradientLoadingIndicator extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final List<Color> colors;
  final Duration duration;

  const GradientLoadingIndicator({
    super.key,
    this.size = 57.0,
    this.strokeWidth = 7.0,
    this.colors = const [
      Color(0xFF9A46D7),
      Color(0xFFE91E63),
      Color(0xFF2196F3),
    ],
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<GradientLoadingIndicator> createState() => _GradientLoadingIndicatorState();
}

class _GradientLoadingIndicatorState extends State<GradientLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _gradientController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds * 2),
      vsync: this,
    );

    _rotationController.repeat();
    _gradientController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _gradientController]),
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * math.pi,
            child: CustomPaint(
              painter: _GradientLoadingPainter(
                rotationProgress: _rotationController.value,
                gradientProgress: _gradientController.value,
                strokeWidth: widget.strokeWidth,
                colors: widget.colors,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GradientLoadingPainter extends CustomPainter {
  final double rotationProgress;
  final double gradientProgress;
  final double strokeWidth;
  final List<Color> colors;

  _GradientLoadingPainter({
    required this.rotationProgress,
    required this.gradientProgress,
    required this.strokeWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // إنشاء التدرج الدوار
    final gradient = SweepGradient(
      colors: colors,
      stops: List.generate(colors.length, (index) => index / (colors.length - 1)),
      transform: GradientRotation(gradientProgress * 2 * math.pi),
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // رسم القوس
    const startAngle = -math.pi / 2;
    const sweepAngle = math.pi * 1.5; // ثلاثة أرباع الدائرة

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GradientLoadingPainter oldDelegate) {
    return oldDelegate.rotationProgress != rotationProgress ||
        oldDelegate.gradientProgress != gradientProgress;
  }
}

/// مؤشر تحميل بنقاط متحركة
class DotsLoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final int dotsCount;
  final Duration duration;

  const DotsLoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color = const Color(0xFF9A46D7),
    this.dotsCount = 3,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<DotsLoadingIndicator> createState() => _DotsLoadingIndicatorState();
}

class _DotsLoadingIndicatorState extends State<DotsLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size / 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.dotsCount, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final progress = (_controller.value - delay) % 1.0;
              final scale = progress < 0.5 
                  ? 1.0 + (progress * 2) * 0.5
                  : 1.5 - ((progress - 0.5) * 2) * 0.5;

              return Transform.scale(
                scale: scale.clamp(1.0, 1.5),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
