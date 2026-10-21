import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/session_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import 'widgets/plant_species.dart';
import 'widgets/sprout_painter.dart';

/// Every species in the game: the ones already grown are drawn in full bloom,
/// the rest as pale silhouettes with the condition that unlocks them.
///
/// Nothing new is persisted for this — the unlocked set is derived from the
/// session log by [SessionRepository.unlockedSpecies].
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = context.watch<SessionRepository>().unlockedSpecies();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.ink,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.collectionTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            '${unlocked.length} of ${PlantSpecies.all.length} '
                            '${AppStrings.collectionSub.toLowerCase()}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: PlantSpecies.all.length,
                  itemBuilder: (context, i) {
                    final species = PlantSpecies.all[i];
                    return _SpeciesCard(
                      species: species,
                      unlocked: unlocked.contains(species.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final PlantSpecies species;
  final bool unlocked;

  const _SpeciesCard({required this.species, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: unlocked ? 0.92 : 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? species.flower.withValues(alpha: 0.4)
              : AppColors.hairline,
          width: unlocked ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SproutMark(
                size: double.infinity,
                progress: 1.0,
                species: species,
                silhouette: !unlocked,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Column(
              children: [
                Text(
                  unlocked ? species.name : '???',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? AppColors.ink : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  unlocked ? AppStrings.collectionSub : species.unlockHint,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
