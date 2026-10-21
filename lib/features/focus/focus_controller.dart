import 'package:flutter/foundation.dart';

import '../../core/storage/session_repository.dart';
import '../../models/focus_session.dart';

/// Holds the configuration for the session being planted and records the
/// result to the [SessionRepository] when it blooms or is abandoned.
class FocusController extends ChangeNotifier {
  final SessionRepository repository;

  FocusController(this.repository);

  int hours = 0;
  int minutes = 25;
  String tag = 'studying';
  String? note;

  DateTime? _startedAt;
  int? _plannedMinutes;

  /// The session most recently recorded, and whether it was the first time
  /// that species reached bloom. Read by the bloom screen to name the reward.
  FocusSession? lastSession;
  bool lastWasNewSpecies = false;

  bool get hasActiveSession => _startedAt != null;

  /// Species this session will grow, derived from the current tag.
  String get plantType => FocusSession.plantForTag(tag);
  int get totalMinutes => hours * 60 + minutes;

  void configure({int? hours, int? minutes, String? tag}) {
    if (hours != null) this.hours = hours;
    if (minutes != null) this.minutes = minutes;
    if (tag != null) this.tag = tag;
    notifyListeners();
  }

  void setNote(String? note) {
    this.note = note;
    notifyListeners();
  }

  void begin() {
    _startedAt = DateTime.now();
    _plannedMinutes = totalMinutes;
    notifyListeners();
  }

  Future<FocusSession?> bloom() => _record(bloomed: true);

  Future<FocusSession?> abandon() => _record(bloomed: false);

  Future<FocusSession?> _record({required bool bloomed}) async {
    final started = _startedAt;
    final planned = _plannedMinutes;
    if (started == null || planned == null) return null;

    final plant = FocusSession.plantForTag(tag);
    final isNewSpecies =
        bloomed && !repository.unlockedSpecies().contains(plant);

    final session = FocusSession(
      id: started.millisecondsSinceEpoch.toString(),
      tag: tag,
      note: note,
      plantType: plant,
      plannedMinutes: planned,
      // A bloomed session ran to completion by definition, so it is worth the
      // full planned time. Only an unfinished session is measured by the
      // clock — and that is clamped so a stale start time can't inflate it.
      grownSeconds: bloomed
          ? planned * 60
          : DateTime.now().difference(started).inSeconds.clamp(0, planned * 60),
      bloomed: bloomed,
      plantedAt: started,
    );
    lastSession = session;
    lastWasNewSpecies = isNewSpecies;
    _startedAt = null;
    _plannedMinutes = null;

    await repository.add(session);
    notifyListeners();
    return session;
  }
}
