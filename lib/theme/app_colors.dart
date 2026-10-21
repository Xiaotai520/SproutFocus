import 'package:flutter/material.dart';

/// Centralized colour palette for Sprout Focus — a plant/garden growth theme.
/// Defined once here so the whole app shares a single source of truth rather
/// than scattering hex literals across every widget.
class AppColors {
  AppColors._();

  // Core greens
  static const Color primary = Color(0xFF4CAF6D); // sprout green
  static const Color secondary = Color(0xFF8BC34A); // leaf lime
  static const Color bloom = Color(0xFFF4A259); // warm terracotta accent

  // Surfaces & text
  static const Color background = Color(0xFFF4FBF2); // pale mint
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF2E4034); // forest text
  static const Color muted = Color(0xFF6B7A70); // muted greenish grey
  static const Color hairline = Color(0xFFD9E6DA); // light border

  // Soil / earth tones for the planter
  static const Color soil = Color(0xFF7A5C42);
  static const Color soilLight = Color(0xFFA1785C);

  // Status
  static const Color success = Color(0xFF43A047);
  static const Color danger = Color(0xFFE25555);

  // Gradients reused across the garden UI
  static const LinearGradient leafGradient = LinearGradient(
    colors: [primary, secondary],
  );

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, Color(0xFFE6F4E1), Color(0xFFCFE9C5)],
  );
}
