import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ble/locker_link.dart';
import '../../core/notifications/notification_center.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import 'bloom_screen.dart';
import 'focus_controller.dart';
import 'growing_screen.dart';
import 'session_setup_screen.dart';

/// Coordinates the focus session: it watches [LockerLink] and shows the setup,
/// growing or bloom view for the current phase. It also reacts to phase
/// transitions — recording the session when it blooms and leaving when the
/// planter disconnects.
class FocusFlowScreen extends StatefulWidget {
  const FocusFlowScreen({super.key});

  @override
  State<FocusFlowScreen> createState() => _FocusFlowScreenState();
}

class _FocusFlowScreenState extends State<FocusFlowScreen> {
  late final LockerLink _link;
  LockerPhase _previous = LockerPhase.unknown;

  @override
  void initState() {
    super.initState();
    _link = context.read<LockerLink>();
    _previous = _link.phase;
    _link.addListener(_onLinkChanged);
  }

  @override
  void dispose() {
    _link.removeListener(_onLinkChanged);
    super.dispose();
  }

  void _onLinkChanged() {
    final phase = _link.phase;
    if (phase == _previous) return;

    // Session ran to completion → record the bloom and notify.
    if (_previous == LockerPhase.growing && phase == LockerPhase.bloomed) {
      final focus = context.read<FocusController>();
      final minutes = focus.totalMinutes;
      focus.bloom();
      context.read<NotificationCenter>().showBloomNotification(minutes);
    }

    // Planter disconnected → back to the garden.
    if (phase == LockerPhase.offline && mounted) {
      Navigator.of(context).maybePop();
    }

    _previous = phase;
  }

  @override
  Widget build(BuildContext context) {
    final phase = context.select<LockerLink, LockerPhase>((l) => l.phase);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(child: _viewFor(phase)),
      ),
    );
  }

  Widget _viewFor(LockerPhase phase) {
    switch (phase) {
      case LockerPhase.idle:
        return const SessionSetupView();
      case LockerPhase.growing:
        return const GrowingView();
      case LockerPhase.bloomed:
        return const BloomView();
      case LockerPhase.unknown:
      case LockerPhase.offline:
        return const _Waiting();
    }
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            AppStrings.waitingDevice,
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
