import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ble/locker_link.dart';
import '../../core/storage/session_repository.dart';
import '../../core/storage/settings_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import '../focus/focus_flow_screen.dart';
import 'collection_screen.dart';
import 'widgets/plant_species.dart';
import 'widgets/sprout_painter.dart';

/// The Garden tab: a planter waiting for a seed, plus a strip of the species
/// grown so far. Tapping the CTA scans for the focus locker and, once
/// connected, opens the focus flow.
class GardenHomeScreen extends StatefulWidget {
  const GardenHomeScreen({super.key});

  @override
  State<GardenHomeScreen> createState() => _GardenHomeScreenState();
}

class _GardenHomeScreenState extends State<GardenHomeScreen> {
  LockerLink get _link => context.read<LockerLink>();

  Future<void> _plant() async {
    // Demo mode skips the radio entirely — no failed scan to sit through.
    if (context.read<SettingsStore>().demoMode) {
      await _link.connectSimulated();
      if (mounted) _openFlow();
      return;
    }

    try {
      await _link.scanAndConnect();
      if (mounted) _openFlow();
    } catch (_) {
      if (!mounted) return;
      final simulate = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(AppStrings.lockerNotFoundTitle),
          content: const Text(AppStrings.lockerNotFoundBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(AppStrings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.growWithoutDevice),
            ),
          ],
        ),
      );
      if (simulate == true && mounted) {
        await _link.connectSimulated();
        if (mounted) _openFlow();
      }
    }
  }

  void _openFlow() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FocusFlowScreen()));
  }

  void _openCollection() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CollectionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final scanning = context.select<LockerLink, bool>((l) => l.scanning);
    final demo = context.select<SettingsStore, bool>((s) => s.demoMode);
    final unlocked = context.watch<SessionRepository>().unlockedSpecies();

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (demo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bloom.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(
                          color: AppColors.bloom,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.leafGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      AppStrings.brandBadge,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: scanning
                            ? const _PlantingIndicator()
                            : const SproutMark(size: 180, progress: 0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      scanning
                          ? AppStrings.searchingDevice
                          : 'Your planter is ready',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink.withValues(alpha: 0.75),
                      ),
                    ),
                    if (scanning) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => _link.cancelScan(),
                        child: const Text(AppStrings.cancel),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _CollectionStrip(unlocked: unlocked, onTap: _openCollection),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 28),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: scanning ? null : _plant,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: scanning
                        ? AppColors.muted
                        : AppColors.primary,
                  ),
                  child: Text(
                    scanning ? AppStrings.planting : AppStrings.plantCta,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact row of every species — grown ones in colour, the rest as faded
/// silhouettes — doubling as the entry point to the full collection.
class _CollectionStrip extends StatelessWidget {
  final Set<String> unlocked;
  final VoidCallback onTap;

  const _CollectionStrip({required this.unlocked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${unlocked.length}/${PlantSpecies.all.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            AppStrings.viewCollection,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 44,
                        child: Row(
                          children: [
                            for (final s in PlantSpecies.all)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: SproutMark(
                                  size: 44,
                                  progress: 1.0,
                                  species: s,
                                  silhouette: !unlocked.contains(s.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlantingIndicator extends StatelessWidget {
  const _PlantingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bluetooth_searching_rounded,
          size: 64,
          color: AppColors.primary,
        ),
        SizedBox(height: 16),
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ],
    );
  }
}
