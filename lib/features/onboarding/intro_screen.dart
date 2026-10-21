import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/settings_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import '../garden/root_shell.dart';
import '../garden/widgets/plant_species.dart';
import '../garden/widgets/sprout_painter.dart';

class _IntroPage {
  final String title;
  final String body;
  final double progress;
  final PlantSpecies species;

  const _IntroPage({
    required this.title,
    required this.body,
    required this.progress,
    required this.species,
  });
}

/// First-run tutorial: the four steps of one planting, each illustrated by the
/// plant a little further along, so the tutorial doubles as a preview of the
/// reward. Deliberately short — learn by doing, not by reading.
class IntroScreen extends StatefulWidget {
  /// When true this was opened from Settings as a replay, so finishing pops
  /// back instead of replacing the app root.
  final bool isReplay;

  const IntroScreen({super.key, this.isReplay = false});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pages = const [
    _IntroPage(
      title: 'Pick how long to focus',
      body:
          'Choose a duration and what you are working on. '
          'That is the whole setup.',
      progress: 0.12,
      species: PlantSpecies.sprout,
    ),
    _IntroPage(
      title: 'Lock your phone away',
      body:
          'Put your phone in the Sprout Focus planter and tap plant. '
          'The planter holds it until time is up.',
      progress: 0.4,
      species: PlantSpecies.fern,
    ),
    _IntroPage(
      title: 'Watch it grow',
      body:
          'Your plant grows in step with the planter’s countdown. '
          'No phone, no distractions.',
      progress: 0.72,
      species: PlantSpecies.lavender,
    ),
    _IntroPage(
      title: 'Earn your plant',
      body:
          'Finish the session and it blooms into your collection. '
          'Different focus types grow different species.',
      progress: 1.0,
      species: PlantSpecies.sunflower,
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<SettingsStore>().setSeenIntro(true);
    if (!mounted) return;
    if (widget.isReplay) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const RootShell()));
    }
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4),
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text(
                      AppStrings.introSkip,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: SproutMark(
                                size: double.infinity,
                                progress: page.progress,
                                species: page.species,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text(
                      isLast ? AppStrings.introStart : AppStrings.introNext,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
