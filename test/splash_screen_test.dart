import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprout_focus/app/splash_screen.dart';
import 'package:sprout_focus/theme/app_strings.dart';

void main() {
  Widget harness() => MaterialApp(
        home: SplashScreen(
          next: (_) => const Scaffold(body: Text('destination')),
        ),
      );

  testWidgets('shows the logo and branding while it holds', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text('destination'), findsNothing);
  });

  testWidgets('still holding just before three seconds', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 2900));

    expect(find.text('destination'), findsNothing);
  });

  testWidgets('hands off to the next screen after three seconds',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('destination'), findsOneWidget);
    expect(find.text(AppStrings.appName), findsNothing);
  });

  testWidgets('cancels its timer when torn down early', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 500));

    // Replacing the tree disposes the splash mid-countdown. A live timer would
    // fire against a dead Navigator and fail the test with a pending timer.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('destination'), findsNothing);
  });
}
