import 'package:flutter/material.dart';

/// Reusable animation utilities for consistent animations across the app
class AnimationUtils {
  /// Fade in animation for widgets
  static Widget fadeIn({
    required Widget child,
    required Animation<double> animation,
    Duration delay = Duration.zero,
  }) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Interval(
            delay.inMilliseconds / 1000,
            1.0,
            curve: Curves.easeIn,
          ),
        ),
      ),
      child: child,
    );
  }

  /// Slide in from bottom animation
  static Widget slideInFromBottom({
    required Widget child,
    required Animation<double> animation,
    Duration delay = Duration.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(
                delay.inMilliseconds / 1000,
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Slide in from left animation
  static Widget slideInFromLeft({
    required Widget child,
    required Animation<double> animation,
    Duration delay = Duration.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(
                delay.inMilliseconds / 1000,
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Slide in from right animation
  static Widget slideInFromRight({
    required Widget child,
    required Animation<double> animation,
    Duration delay = Duration.zero,
  }) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(
                delay.inMilliseconds / 1000,
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Scale animation
  static Widget scaleIn({
    required Widget child,
    required Animation<double> animation,
    Duration delay = Duration.zero,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Interval(
            delay.inMilliseconds / 1000,
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Staggered list animation
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    required Animation<double> animation,
  }) {
    final delay = index * 50; // 50ms delay between items
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: Interval(
                (delay / 1000).clamp(0.0, 0.8),
                1.0,
                curve: Curves.easeOut,
              ),
            ),
          ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(
              (delay / 1000).clamp(0.0, 0.8),
              1.0,
              curve: Curves.easeIn,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Mixin for screens that need animations
mixin ScreenAnimationMixin<T extends StatefulWidget> on State<T>
    implements TickerProviderStateMixin<T> {
  late AnimationController animationController;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );
    animationController.forward();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}
