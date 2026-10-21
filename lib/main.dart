import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'core/ble/locker_link.dart';
import 'core/notifications/notification_center.dart';
import 'core/storage/session_repository.dart';
import 'core/storage/settings_store.dart';
import 'features/auth/account_controller.dart';
import 'features/focus/focus_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Order matters: the repository initialises Hive and opens the focus log,
  // then settings opens the prefs box that the account controller reads from.
  final repository = SessionRepository();
  await repository.init();

  final settings = SettingsStore();
  await settings.init();

  // Anyone upgrading who has already grown something knows how this works —
  // don't greet them with a beginner tutorial. Only genuinely new gardeners
  // see it. (Settings has a "Replay tutorial" row for everyone else.)
  if (!settings.seenIntro && repository.all().isNotEmpty) {
    await settings.setSeenIntro(true);
  }

  final account = AccountController()..load();

  final notifications = NotificationCenter();
  await notifications.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: repository),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: account),
        Provider.value(value: notifications),
        ChangeNotifierProvider(create: (_) => LockerLink()),
        ChangeNotifierProvider(create: (_) => FocusController(repository)),
      ],
      child: const SproutFocusApp(),
    ),
  );
}
