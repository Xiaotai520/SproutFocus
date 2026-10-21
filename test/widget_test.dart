import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sprout_focus/features/auth/account_controller.dart';
import 'package:sprout_focus/features/auth/sign_in_screen.dart';
import 'package:sprout_focus/theme/app_theme.dart';

void main() {
  testWidgets('Sign-in screen renders the Sprout Focus brand and login form',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AccountController>(
        create: (_) => AccountController(),
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const SignInScreen(),
        ),
      ),
    );

    expect(find.text('SPROUT FOCUS'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });
}
