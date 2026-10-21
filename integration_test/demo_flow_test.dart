// Drives a full demo run for screen recording: sign in, plant without the
// planter, grow a 1-minute session and let it bloom. Not an assertion-heavy
// test — it exists so the simulator can be filmed without a Simulator window
// to click on. Run it with the recorder already going:
//
//   xcrun simctl io booted recordVideo demo.mp4 &
//   flutter test integration_test/demo_flow_test.dart -d <simulator-id>
// Supply DEMO_EMAIL and DEMO_PASSWORD with --dart-define. The demo is skipped
// unless both are provided; no account credentials belong in this file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:sprout_focus/app/app.dart';
import 'package:sprout_focus/core/ble/locker_link.dart';
import 'package:sprout_focus/core/notifications/notification_center.dart';
import 'package:sprout_focus/core/storage/session_repository.dart';
import 'package:sprout_focus/core/storage/settings_store.dart';
import 'package:sprout_focus/features/auth/account_controller.dart';
import 'package:sprout_focus/features/focus/focus_controller.dart';
import 'package:sprout_focus/firebase_options.dart';

const _demoEmail = String.fromEnvironment('DEMO_EMAIL');
const _demoPassword = String.fromEnvironment('DEMO_PASSWORD');

/// Mirrors `main()` except that NotificationCenter.init() is skipped. That
/// call sets requestAlertPermission, which puts a native iOS permission alert
/// over the app — and with no Simulator window there is nothing to tap it
/// with, so the app would sit there forever before runApp().
/// Because init() is skipped above, the plugin is unauthorized and show()
/// throws UNErrorDomain 2003 when the session blooms — which fails the run
/// even though the UI is fine. Silence it; notifications aren't what we're
/// filming. On a real device with permission granted this is a no-op concern.
class _SilentNotifications extends NotificationCenter {
  @override
  Future<void> showBloomNotification(int minutes) async {}

  @override
  Future<void> scheduleDailyReminder(int hour, int minute) async {}

  @override
  Future<void> cancelDailyReminder() async {}
}

Future<Widget> buildApp() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase persists the session across launches, so a second run would skip
  // straight to the garden. The demo is meant to open on the login screen.
  await FirebaseAuth.instance.signOut();

  final repository = SessionRepository();
  await repository.init();

  final settings = SettingsStore();
  await settings.init();

  final account = AccountController()..load();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: repository),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: account),
      Provider<NotificationCenter>.value(value: _SilentNotifications()),
      ChangeNotifierProvider(create: (_) => LockerLink()),
      ChangeNotifierProvider(create: (_) => FocusController(repository)),
    ],
    child: const SproutFocusApp(),
  );
}

/// One frame at 60fps. The binding only draws when we pump, so this interval
/// is what the screen recording actually captures — at 50ms the video came
/// out around 4fps and visibly juddered.
const _frame = Duration(milliseconds: 16);

/// Real-time wait that keeps pumping frames, so animations and the simulated
/// locker's timers keep running while we sit and watch.
Future<void> hold(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(_frame);
  }
}

/// Pumps until [finder] matches, or gives up after [timeout].
Future<bool> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(_frame);
    if (finder.evaluate().isNotEmpty) return true;
  }
  return false;
}

/// Prints visible labels, excluding form values so credentials stay private.
void dump(WidgetTester tester, String stage) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .toList();
  debugPrint('>>> [$stage] ${texts.join(" | ")}');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Default policy only draws when something explicitly schedules a frame, so
  // implicit animations stutter on camera. fullyLive requests a frame every
  // vsync, which is what makes the recording smooth.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('demo: sign in, grow without planter, bloom', (tester) async {
    await tester.pumpWidget(await buildApp());
    await hold(tester, const Duration(seconds: 3));

    // --- Sign in -----------------------------------------------------------
    final email = find.byType(TextFormField).first;
    final password = find.byType(TextFormField).at(1);

    await tester.enterText(email, _demoEmail);
    await hold(tester, const Duration(milliseconds: 800));
    await tester.enterText(password, _demoPassword);
    await hold(tester, const Duration(milliseconds: 800));

    dump(tester, 'sign-in form');

    // Dismiss the keyboard and bring the button into the viewport — the form
    // scrolls, and tapping a widget that is off-screen silently misses.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await hold(tester, const Duration(milliseconds: 600));
    await tester.ensureVisible(find.byType(ElevatedButton).first);
    await hold(tester, const Duration(milliseconds: 600));
    await tester.tap(find.byType(ElevatedButton).first);
    await hold(tester, const Duration(milliseconds: 2500));
    dump(tester, 'login +2.5s');
    await hold(tester, const Duration(seconds: 3));
    dump(tester, 'after login');

    // --- First-run tutorial: page through it, then start --------------------
    for (var i = 0; i < 8; i++) {
      final next = find.text('Next');
      if (next.evaluate().isEmpty) break;
      await tester.tap(next.first, warnIfMissed: false);
      await hold(tester, const Duration(milliseconds: 1200));
    }
    final startGrowing = find.text('START GROWING');
    if (startGrowing.evaluate().isNotEmpty) {
      await tester.tap(startGrowing.first, warnIfMissed: false);
    } else if (find.text('Skip').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip').first, warnIfMissed: false);
    }
    await hold(tester, const Duration(seconds: 2));
    dump(tester, 'garden');

    // --- Plant, then decline the planter ------------------------------------
    final plant = find.textContaining('PLANT A SESSION');
    if (plant.evaluate().isNotEmpty) {
      await tester.ensureVisible(plant.first);
      await tester.tap(plant.first, warnIfMissed: false);
    }
    await hold(tester, const Duration(seconds: 2));
    dump(tester, 'after plant tap');

    // The BLE scan has a 10s timeout before the fallback dialog appears.
    final dialog = find.text('Grow Without Planter');
    final appeared =
        await waitFor(tester, dialog, timeout: const Duration(seconds: 30));
    dump(tester, 'dialog appeared=$appeared');
    if (!appeared) return;
    await hold(tester, const Duration(seconds: 1));
    await tester.tap(dialog, warnIfMissed: false);
    await hold(tester, const Duration(seconds: 2));
    dump(tester, 'after grow-without-planter');

    // --- Set the timer to one minute ---------------------------------------
    // The MIN wheel is the second ListWheelScrollView; drive its controller so
    // the picker visibly spins from the default 25 down to 1.
    final wheels = find.byType(ListWheelScrollView);
    if (wheels.evaluate().length > 1) {
      final minWheel = tester.widget<ListWheelScrollView>(wheels.at(1));
      final controller = minWheel.controller;
      if (controller is FixedExtentScrollController) {
        controller.animateToItem(
          1,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOut,
        );
      }
    }
    await hold(tester, const Duration(seconds: 3));
    dump(tester, 'duration set');

    // --- Start, and let it bloom -------------------------------------------
    final start = find.textContaining('PLANT & LOCK');
    if (start.evaluate().isNotEmpty) {
      await tester.ensureVisible(start.first);
      await tester.tap(start.first, warnIfMissed: false);
    }
    await hold(tester, const Duration(seconds: 3));
    dump(tester, 'growing');

    // 1 simulated minute at the 3x demo factor blooms in ~20s; hold past that
    // so the recording catches the bloom screen and the auto-return.
    final bloomed = await waitFor(
      tester,
      find.textContaining('BLOOMED'),
      timeout: const Duration(seconds: 60),
    );
    dump(tester, 'bloomed=$bloomed');

    // Linger on the garden afterwards so the recording ends on the new plant.
    await hold(tester, const Duration(seconds: 8));
    dump(tester, 'end');
  },
      skip: _demoEmail.isEmpty || _demoPassword.isEmpty,
      timeout: const Timeout(Duration(minutes: 4)));
}
