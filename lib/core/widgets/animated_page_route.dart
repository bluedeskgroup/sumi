import 'package:flutter/material.dart';

class AnimatedPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType transitionType;

  AnimatedPageRoute({
    required this.child,
    this.transitionType = PageTransitionType.slideFromRight,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
              transitionType: transitionType,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );

  static Widget _buildTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required PageTransitionType transitionType,
  }) {
    switch (transitionType) {
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      
      case PageTransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      
      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      
      case PageTransitionType.fadeIn:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      
      case PageTransitionType.scaleIn:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          child: child,
        );
      
      case PageTransitionType.rotateIn:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
    }
  }
}

enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  fadeIn,
  scaleIn,
  rotateIn,
}

// Extension للتسهيل
extension NavigatorExtension on BuildContext {
  Future<T?> pushAnimated<T extends Object?>(
    Widget page, {
    PageTransitionType transition = PageTransitionType.slideFromRight,
  }) {
    return Navigator.push<T>(
      this,
      AnimatedPageRoute<T>(
        child: page,
        transitionType: transition,
      ),
    );
  }

  Future<T?> pushReplacementAnimated<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType transition = PageTransitionType.slideFromRight,
    TO? result,
  }) {
    return Navigator.pushReplacement<T, TO>(
      this,
      AnimatedPageRoute<T>(
        child: page,
        transitionType: transition,
      ),
      result: result,
    );
  }
}
