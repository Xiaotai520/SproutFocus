import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/session_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import '../garden/widgets/plant_species.dart';
import '../garden/widgets/sprout_painter.dart';
import 'focus_controller.dart';

/// Celebratory view shown when a session completes — the plant blooms, is
/// named, and is called out if it is the first of its species.
class BloomView extends StatefulWidget {
  const BloomView({super.key});

  @override
  State<BloomView> createState() => _BloomViewState();
}

class _BloomViewState extends State<BloomView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusController>();
    final stats = context.watch<SessionRepository>().stats;

    final species = PlantSpecies.byId(focus.plantType);
    final isNew = focus.lastWasNewSpecies;
    final minutes = focus.lastSession?.grownMinutes ?? focus.totalMinutes;

    // The plant finishes opening over the first ~55% of the animation; the
    // confetti rides the whole thing.
    final grow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.55, curve: Curves.elasticOut),
    );

    // Scrollable so the recap still fits on short screens, but centred when
    // there is room — a bare SingleChildScrollView would pin it to the top.
    // minWidth matters as much as minHeight: Scaffold gives its body loose
    // width, so without it the page shrinks to the widest child and the
    // gradient stops short of the right edge.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            minHeight: constraints.maxHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      painter: _ConfettiPainter(
                        t: _controller.value,
                        seed: species.id.hashCode,
                        colors: [
                          species.flower,
                          species.leaf,
                          AppColors.bloom,
                          AppColors.primary,
                        ],
                      ),
                      child: Center(
                        child: Transform.scale(
                          scale: 0.6 + 0.4 * grow.value.clamp(0.0, 1.4),
                          child: SizedBox(
                            width: 200,
                            height: 220,
                            child: CustomPaint(
                              painter: SproutPainter(
                                progress:
                                    0.85 + 0.15 * grow.value.clamp(0.0, 1.0),
                                species: species,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (isNew) ...[
                  _NewSpeciesBadge(color: species.flower),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.bloom],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bloom.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    AppStrings.bloomTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${AppStrings.youGrewA} ${species.name}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RecapTile(
                      icon: Icons.timer_rounded,
                      value: '$minutes',
                      label: AppStrings.recapMinutes,
                    ),
                    const SizedBox(width: 12),
                    _RecapTile(
                      icon: Icons.local_fire_department_rounded,
                      value: '${stats.currentStreak}',
                      label: AppStrings.recapStreak,
                    ),
                    const SizedBox(width: 12),
                    _RecapTile(
                      icon: Icons.eco_rounded,
                      value:
                          '${stats.speciesUnlocked}/${PlantSpecies.all.length}',
                      label: AppStrings.recapSpecies,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    AppStrings.bloomBody,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewSpeciesBadge extends StatelessWidget {
  final Color color;
  const _NewSpeciesBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
          SizedBox(width: 6),
          Text(
            AppStrings.newSpecies,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _RecapTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Petals bursting outward from the centre and drifting down. Drawn in the
/// same CustomPainter idiom as the plant itself — no extra dependency.
class _ConfettiPainter extends CustomPainter {
  final double t;
  final int seed;
  final List<Color> colors;

  _ConfettiPainter({required this.t, required this.seed, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;

    final rnd = math.Random(seed);
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    const count = 26;

    // Fade the whole burst out over the last third.
    final fade = t < 0.65 ? 1.0 : (1 - (t - 0.65) / 0.35).clamp(0.0, 1.0);

    for (var i = 0; i < count; i++) {
      final angle = rnd.nextDouble() * 2 * math.pi;
      final speed = 0.5 + rnd.nextDouble() * 0.5;
      final spin = rnd.nextDouble() * math.pi;
      final w = size.width * (0.018 + rnd.nextDouble() * 0.016);

      final dist = size.width * 0.52 * speed * Curves.easeOut.transform(t);
      final drop = size.height * 0.5 * t * t * speed;

      final dx = cx + math.cos(angle) * dist;
      final dy = cy + math.sin(angle) * dist * 0.7 + drop;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(spin + t * 6 * speed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: w * 1.8),
          Radius.circular(w * 0.5),
        ),
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: 0.9 * fade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
