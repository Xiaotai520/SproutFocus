import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_strings.dart';

/// Branded splash shown for three seconds on launch, then replaced by whatever
/// [next] builds.
///
/// This lives in Dart rather than the native launch screen because the native
/// one can't be held for a fixed time — Android and iOS both tear it down as
/// soon as Flutter renders its first frame.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});

  /// Built when the splash elapses rather than up front, so the destination
  /// reflects auth and settings state as of the hand-off.
  final WidgetBuilder next;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _hold = Duration(seconds: 3);
  static const Duration _fade = Duration(milliseconds: 600);

  Timer? _timer;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    // Fade the mark in on the frame after first paint; popping it in at full
    // opacity reads as a flicker rather than an intro.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
    _timer = Timer(_hold, _goNext);
  }

  @override
  void dispose() {
    // Without this a hot restart (or any early teardown) fires the timer
    // against a disposed Navigator.
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, _, __) => widget.next(context),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: Center(
          child: AnimatedOpacity(
            opacity: _shown ? 1 : 0,
            duration: _fade,
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      'assets/app_logo.png',
                      width: 148,
                      height: 148,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  AppStrings.tagline,
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
