import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/account_controller.dart';
import '../features/auth/sign_in_screen.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import 'landing.dart';
import 'splash_screen.dart';

/// Root widget: applies the Sprout Focus theme, holds the branded splash for a
/// moment, then shows the garden if already signed in, otherwise the sign-in
/// screen.
class SproutFocusApp extends StatelessWidget {
  const SproutFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // Read auth state inside the builder, not here: sign-in can resolve
      // while the splash is still up.
      home: SplashScreen(
        next: (context) => context.read<AccountController>().isSignedIn
            ? landingScreen(context)
            : const SignInScreen(),
      ),
    );
  }
}
