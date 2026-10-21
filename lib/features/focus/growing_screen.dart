import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ble/locker_link.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import '../garden/widgets/plant_species.dart';
import '../garden/widgets/sprout_painter.dart';
import 'focus_controller.dart';

/// Shown while the phone is locked: the plant grows from seed toward bloom as
/// the countdown runs. The timer is owned by the hardware, so there is no
/// early-stop action — the button is informational only.
class GrowingView extends StatelessWidget {
  const GrowingView({super.key});

  @override
  Widget build(BuildContext context) {
    final remaining = context.select<LockerLink, int>(
      (l) => l.remainingSeconds ?? 0,
    );
    final focus = context.read<FocusController>();
    final species = PlantSpecies.byId(focus.plantType);
    final totalMinutes = focus.totalMinutes;
    final totalSeconds = (totalMinutes * 60).clamp(1, 1 << 30);
    final progress = (1 - remaining / totalSeconds).clamp(0.0, 1.0);

    final mins = (remaining ~/ 60).toString().padLeft(2, '0');
    final secs = (remaining % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppStrings.growingChip,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 220,
          height: 240,
          // The hardware reports roughly once a second, so the raw value steps.
          // Easing between ticks is presentation only — the target is still
          // derived entirely from the locker's remaining-seconds count.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: progress, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.linear,
            builder: (context, eased, _) => CustomPaint(
              painter: SproutPainter(progress: eased, species: species),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Growth progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            AppStrings.timeUntilBloom,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _digit(mins, 'MIN'),
            const SizedBox(width: 28),
            _digit(secs, 'SEC'),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 44),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.eco_rounded, size: 20),
              label: const Text(AppStrings.stopGrowing),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                disabledBackgroundColor: AppColors.secondary.withValues(
                  alpha: 0.5,
                ),
                disabledForegroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _digit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
