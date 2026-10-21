import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/focus_session.dart';
import 'hive_boxes.dart';

/// Immutable snapshot of the garden's headline numbers, recomputed once per
/// mutation instead of on every widget build.
@immutable
class FocusStats {
  final int totalMinutes;
  final int sessionsThisWeek;
  final int longestMinutes;
  final int currentStreak;
  final int todayMinutes;
  final Map<String, int> tagBreakdown;
  final int speciesUnlocked;

  const FocusStats({
    required this.totalMinutes,
    required this.sessionsThisWeek,
    required this.longestMinutes,
    required this.currentStreak,
    required this.todayMinutes,
    required this.tagBreakdown,
    required this.speciesUnlocked,
  });

  static const empty = FocusStats(
    totalMinutes: 0,
    sessionsThisWeek: 0,
    longestMinutes: 0,
    currentStreak: 0,
    todayMinutes: 0,
    tagBreakdown: {},
    speciesUnlocked: 0,
  );
}

/// Owns the Hive-backed session log and exposes a cached [FocusStats].
class SessionRepository extends ChangeNotifier {
  late final Box<FocusSession> _logs;

  FocusStats _stats = FocusStats.empty;
  FocusStats get stats => _stats;

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(FocusSessionAdapter());
    }
    _logs = await Hive.openBox<FocusSession>(HiveBoxes.focusLogs);
    _recompute();
  }

  // --- Reads ---

  List<FocusSession> all() {
    final list = _logs.values.toList()
      ..sort((a, b) => b.plantedAt.compareTo(a.plantedAt));
    return list;
  }

  List<FocusSession> withTag(String tag) =>
      all().where((s) => s.tag == tag).toList();

  /// Species the gardener has actually grown to full bloom. Derived from the
  /// session log rather than stored separately, so there is nothing to keep in
  /// sync and no schema change.
  Set<String> unlockedSpecies() => _bloomed.map((s) => s.plantType).toSet();

  // --- Writes ---

  Future<void> add(FocusSession session) async {
    await _logs.put(session.id, session);
    _recompute();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _logs.clear();
    _recompute();
    notifyListeners();
  }

  // --- Goal-dependent helpers (need the live goal value) ---

  int todayMinutesFor(DateTime day) {
    var total = 0;
    for (final s in _completedOn(day)) {
      total += s.grownSeconds;
    }
    return total ~/ 60;
  }

  /// Consecutive days (ending today/yesterday) the daily goal was met.
  int goalStreak(int goalMinutes) {
    if (goalMinutes <= 0) return 0;
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (todayMinutesFor(day) < goalMinutes) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (todayMinutesFor(day) >= goalMinutes) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // --- Internal stat computation (formulas preserved from the original) ---

  void _recompute() {
    _stats = FocusStats(
      totalMinutes: _totalMinutes(),
      sessionsThisWeek: _sessionsThisWeek(),
      longestMinutes: _longestMinutes(),
      currentStreak: _currentStreak(),
      todayMinutes: todayMinutesFor(DateTime.now()),
      tagBreakdown: _tagBreakdown(),
      speciesUnlocked: unlockedSpecies().length,
    );
  }

  Iterable<FocusSession> get _bloomed => _logs.values.where((s) => s.bloomed);

  int _totalMinutes() {
    var total = 0;
    for (final s in _bloomed) {
      total += s.grownSeconds;
    }
    return total ~/ 60;
  }

  int _sessionsThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _bloomed.where((s) => s.plantedAt.isAfter(start)).length;
  }

  int _longestMinutes() {
    var longest = 0;
    for (final s in _bloomed) {
      if (s.grownSeconds > longest) longest = s.grownSeconds;
    }
    return longest ~/ 60;
  }

  int _currentStreak() {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (_completedOn(day).isEmpty) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (_completedOn(day).isNotEmpty) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<FocusSession> _completedOn(DateTime date) {
    return _bloomed
        .where(
          (s) =>
              s.plantedAt.year == date.year &&
              s.plantedAt.month == date.month &&
              s.plantedAt.day == date.day,
        )
        .toList();
  }

  Map<String, int> _tagBreakdown() {
    final out = <String, int>{};
    for (final s in _bloomed) {
      out[s.tag] = (out[s.tag] ?? 0) + s.grownMinutes;
    }
    return out;
  }
}
