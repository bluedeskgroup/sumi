import 'package:flutter/material.dart';

// كلاس زر التفاعل مع تأثيرات بصرية محسنة مثل فيسبوك
class ReactionButton extends StatefulWidget {
  final String reaction;
  final VoidCallback onTap;

  const ReactionButton({
    Key? key,
    required this.reaction,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _animationController.forward();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _animationController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isHovered 
                      ? const Color(0xFF9A46D7).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: _isHovered
                      ? Border.all(
                          color: const Color(0xFF9A46D7).withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    widget.reaction,
                    style: TextStyle(
                      fontSize: _isHovered ? 30 : 28,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
