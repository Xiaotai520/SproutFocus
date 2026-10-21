import 'package:flutter_test/flutter_test.dart';
import 'package:sprout_focus/core/ble/locker_link.dart';
import 'package:sprout_focus/core/storage/session_repository.dart';
import 'package:sprout_focus/features/focus/focus_controller.dart';
import 'package:sprout_focus/models/focus_session.dart';

void main() {
  test('changing the duration preserves the session note', () {
    final focus = FocusController(SessionRepository());

    focus.setNote('Finish the outline');
    focus.configure(hours: 1, minutes: 0);

    expect(focus.totalMinutes, 60);
    expect(focus.note, 'Finish the outline');
  });

  test('simulated planter rejects durations its firmware cannot run', () async {
    final link = LockerLink();
    await link.connectSimulated();

    await expectLater(link.setTime(61), throwsArgumentError);
    await link.disconnect();
  });

  test(
    'bloom records the reward while preserving the configured note',
    () async {
      final repository = _MemorySessionRepository();
      final focus = FocusController(repository);
      addTearDown(focus.dispose);
      addTearDown(repository.dispose);

      focus.setNote('Finish the outline');
      focus.configure(minutes: 1, tag: 'reading');
      focus.begin();

      final session = await focus.bloom();

      expect(session, isNotNull);
      expect(session!.note, 'Finish the outline');
      expect(session.plantType, 'lavender');
      expect(session.grownSeconds, 60);
      expect(focus.lastSession, same(session));
      expect(focus.lastWasNewSpecies, isTrue);
      expect(focus.hasActiveSession, isFalse);
      expect(repository.sessions, [session]);
      expect(await focus.bloom(), isNull);

      focus.begin();
      await focus.bloom();
      expect(focus.lastWasNewSpecies, isFalse);
      expect(repository.sessions, hasLength(2));
    },
  );
}

class _MemorySessionRepository extends SessionRepository {
  final List<FocusSession> sessions = [];

  @override
  Set<String> unlockedSpecies() =>
      sessions.where((s) => s.bloomed).map((s) => s.plantType).toSet();

  @override
  Future<void> add(FocusSession session) async => sessions.add(session);
}
