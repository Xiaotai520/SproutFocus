import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_boxes.dart';

/// Persists user preferences (daily goal, reminder schedule) in the prefs box
/// and notifies listeners on change.
class SettingsStore extends ChangeNotifier {
  late final Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(HiveBoxes.prefs);
  }

  int get dailyGoalMinutes =>
      _box.get(HiveBoxes.dailyGoalMin, defaultValue: 0) as int;

  Future<void> setDailyGoalMinutes(int minutes) async {
    await _box.put(HiveBoxes.dailyGoalMin, minutes);
    notifyListeners();
  }

  bool get reminderEnabled =>
      _box.get(HiveBoxes.remindOn, defaultValue: false) as bool;

  Future<void> setReminderEnabled(bool enabled) async {
    await _box.put(HiveBoxes.remindOn, enabled);
    notifyListeners();
  }

  int get reminderHour =>
      _box.get(HiveBoxes.remindHour, defaultValue: 9) as int;

  int get reminderMinute =>
      _box.get(HiveBoxes.remindMinute, defaultValue: 0) as int;

  Future<void> setReminderTime(int hour, int minute) async {
    await _box.put(HiveBoxes.remindHour, hour);
    await _box.put(HiveBoxes.remindMinute, minute);
    notifyListeners();
  }

  /// Whether the first-run tutorial has been shown.
  bool get seenIntro =>
      _box.get(HiveBoxes.seenIntro, defaultValue: false) as bool;

  Future<void> setSeenIntro(bool seen) async {
    await _box.put(HiveBoxes.seenIntro, seen);
    notifyListeners();
  }

  /// Skip the Bluetooth scan and grow simulated sessions. Exists so the app
  /// can be demonstrated without the planter in hand.
  bool get demoMode =>
      _box.get(HiveBoxes.demoMode, defaultValue: false) as bool;

  Future<void> setDemoMode(bool enabled) async {
    await _box.put(HiveBoxes.demoMode, enabled);
    notifyListeners();
  }
}
