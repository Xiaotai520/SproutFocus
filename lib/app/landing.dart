import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/storage/settings_store.dart';
import '../features/garden/root_shell.dart';
import '../features/onboarding/intro_screen.dart';

/// Where a signed-in gardener should land: the tutorial if they have never
/// seen it, otherwise straight into the garden.
///
/// Used by the app root and by both auth screens so the decision lives in one
/// place and a brand-new account can't slip past the tutorial.
Widget landingScreen(BuildContext context) {
  final seen = context.read<SettingsStore>().seenIntro;
  return seen ? const RootShell() : const IntroScreen();
}
