import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ble/locker_link.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import 'focus_controller.dart';

/// Lets the user choose a duration, tag and note, then plants the session by
/// sending the duration + lock command to the planter.
class SessionSetupView extends StatefulWidget {
  const SessionSetupView({super.key});

  @override
  State<SessionSetupView> createState() => _SessionSetupViewState();
}

class _SessionSetupViewState extends State<SessionSetupView> {
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minCtrl;
  bool _sending = false;
  bool _showNote = false;
  final _noteCtrl = TextEditingController();

  FocusController get _focus => context.read<FocusController>();

  @override
  void initState() {
    super.initState();
    _hourCtrl = FixedExtentScrollController(initialItem: _focus.hours);
    _minCtrl = FixedExtentScrollController(initialItem: _focus.minutes);
    _noteCtrl.text = _focus.note ?? '';
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _plant() async {
    final total = _focus.totalMinutes;
    if (total < 1 || total > LockerLink.maxSessionMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a session between 1 and 60 minutes.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _sending = true);
    final link = context.read<LockerLink>();
    try {
      await link.setTime(total);
      await link.lock();
      _focus.begin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sending) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final focus = context.watch<FocusController>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => context.read<LockerLink>().disconnect(),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.ink, size: 28),
              ),
              const Expanded(
                child: Text(
                  'Plant a Session',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        const Spacer(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            AppStrings.setDuration,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _wheel('HR', _hourCtrl, 2, (v) {
              if (v == 1 && _focus.minutes != 0) {
                _minCtrl.jumpToItem(0);
                _focus.configure(hours: v, minutes: 0);
              } else {
                _focus.configure(hours: v);
              }
            }),
            _wheel('MIN', _minCtrl, focus.hours == 1 ? 1 : 60,
                (v) => _focus.configure(minutes: v)),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.focusPrompt,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppStrings.tags.map((tag) {
                  final selected = tag == focus.tag;
                  return ChoiceChip(
                    label: Text(tag),
                    selected: selected,
                    onSelected: (_) => _focus.configure(tag: tag),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.hairline,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primary : AppColors.muted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    checkmarkColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (!_showNote)
                GestureDetector(
                  onTap: () => setState(() => _showNote = true),
                  child: Text(
                    AppStrings.addNote,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                TextField(
                  controller: _noteCtrl,
                  maxLength: 100,
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
                  onChanged: (v) => _focus.setNote(v.isEmpty ? null : v),
                  decoration: InputDecoration(
                    hintText: AppStrings.noteHint,
                    counterText: '',
                    isDense: true,
                    fillColor: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: focus.totalMinutes > 0 ? _plant : null,
              icon: const Icon(Icons.eco_rounded, size: 22),
              label: const Text(AppStrings.startSession),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: focus.totalMinutes > 0
                    ? AppColors.primary
                    : AppColors.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wheel(String label, FixedExtentScrollController ctrl, int count,
      ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListWheelScrollView.useDelegate(
            controller: ctrl,
            itemExtent: 48,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1.4,
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (context, index) {
                if (index < 0 || index >= count) return null;
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
