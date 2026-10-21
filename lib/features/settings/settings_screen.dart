import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_config.dart';
import '../../core/notifications/notification_center.dart';
import '../../core/storage/settings_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import '../auth/account_controller.dart';
import '../onboarding/intro_screen.dart';
import '../auth/sign_in_screen.dart';

/// Daily goal, reminder schedule and account actions.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _confirm({
    required String title,
    required String body,
    required String action,
    required Future<void> Function() onConfirm,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(foregroundColor: AppColors.danger)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok == true) await onConfirm();
  }

  Future<void> _toReSignIn() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final account = context.watch<AccountController>();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Color(0xFFE6F4E1)],
        ),
      ),
      child: SafeArea(
        child: _busy
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.settingsSub,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.ink.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _goalCard(settings),
                    const SizedBox(height: 20),
                    _reminderCard(settings),
                    const SizedBox(height: 20),
                    _accountCard(account.email),
                    const SizedBox(height: 20),
                    _helpCard(settings),
                    const SizedBox(height: 28),
                    _signOutButton(),
                    const SizedBox(height: 60),
                    _deleteButton(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _goalCard(SettingsStore settings) {
    final goal = settings.dailyGoalMinutes;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'Daily Growth Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            goal > 0 ? _goalText(goal) : 'No goal set',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: goal > 0 ? AppColors.ink : AppColors.muted,
            ),
          ),
          Slider(
            value: goal.toDouble(),
            min: 0,
            max: 480,
            divisions: 32,
            activeColor: AppColors.primary,
            onChanged: (v) => settings.setDailyGoalMinutes(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Off',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '8h',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(SettingsStore settings) {
    final notifications = context.read<NotificationCenter>();
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text(
                'Daily Reminder',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Switch(
                value: settings.reminderEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (on) async {
                  if (on && !await notifications.requestPermission()) return;
                  await settings.setReminderEnabled(on);
                  if (on) {
                    await notifications.scheduleDailyReminder(
                      settings.reminderHour,
                      settings.reminderMinute,
                    );
                  } else {
                    await notifications.cancelDailyReminder();
                  }
                },
              ),
            ],
          ),
          if (settings.reminderEnabled) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute,
                  ),
                );
                if (picked != null) {
                  await settings.setReminderTime(picked.hour, picked.minute);
                  await notifications.scheduleDailyReminder(
                    picked.hour,
                    picked.minute,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      TimeOfDay(
                        hour: settings.reminderHour,
                        minute: settings.reminderMinute,
                      ).format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit_rounded,
                      color: AppColors.ink.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tutorial replay plus the demo-mode escape hatch for showing the app
  /// without the planter in hand.
  Widget _helpCard(SettingsStore settings) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  AppStrings.replayTutorial,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const IntroScreen(isReplay: true),
                  ),
                ),
                child: const Text('Show'),
              ),
            ],
          ),
          if (kShowDemoModeToggle) ...[
            const Divider(height: 28, color: AppColors.hairline),
            Row(
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                const Text(
                  AppStrings.demoModeLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: settings.demoMode,
                  activeThumbColor: AppColors.primary,
                  onChanged: (on) => settings.setDemoMode(on),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.demoModeHelp,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accountCard(String? email) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              email ?? 'Unknown',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _confirm(
          title: 'Sign Out',
          body: 'Are you sure you want to sign out?',
          action: 'Sign Out',
          onConfirm: () async {
            setState(() => _busy = true);
            await context.read<AccountController>().signOut();
            await _toReSignIn();
          },
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('SIGN OUT'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _deleteButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: TextButton.icon(
        onPressed: () => _confirm(
          title: 'Delete Account',
          body: 'Are you sure? This cannot be undone.',
          action: 'Delete',
          destructive: true,
          onConfirm: () async {
            setState(() => _busy = true);
            final account = context.read<AccountController>();
            final ok = await account.deleteAccount();
            if (ok) {
              await _toReSignIn();
            } else if (mounted) {
              setState(() => _busy = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    account.lastError ?? 'Failed to delete account',
                  ),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.danger,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size.fromHeight(52),
        ),
        icon: const Icon(Icons.delete_forever_rounded, size: 20),
        label: const Text('DELETE ACCOUNT'),
      ),
    );
  }

  static String _goalText(int minutes) {
    if (minutes < 60) return '${minutes}m per day';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m per day' : '${h}h per day';
  }
}
