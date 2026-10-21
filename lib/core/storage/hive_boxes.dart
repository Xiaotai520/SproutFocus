/// Hive box names and settings keys for Sprout Focus, kept in one place.
/// These intentionally differ from any prior schema.
class HiveBoxes {
  HiveBoxes._();

  static const String focusLogs = 'focus_logs';
  static const String prefs = 'prefs';

  // Keys inside the prefs box
  static const String accountEmail = 'account_email';
  static const String dailyGoalMin = 'daily_goal_min';
  static const String remindOn = 'remind_on';
  static const String remindHour = 'remind_h';
  static const String remindMinute = 'remind_m';
  static const String seenIntro = 'seen_intro';
  static const String demoMode = 'demo_mode';
}
