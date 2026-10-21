import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/session_repository.dart';
import '../../core/storage/settings_store.dart';
import '../../models/focus_session.dart';
import '../../theme/app_colors.dart';
import '../garden/widgets/plant_species.dart';
import '../garden/widgets/sprout_painter.dart';
import '../../theme/app_theme.dart';
import 'history_screen.dart';

/// "Your Garden" — headline numbers, daily-goal ring, what-you-grew breakdown
/// and the most recent sessions.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SessionRepository>();
    final settings = context.watch<SettingsStore>();
    final stats = repo.stats;
    final goal = settings.dailyGoalMinutes;
    final goalStreak = repo.goalStreak(goal);
    final recent = repo.all().take(5).toList();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Color(0xFFE6F4E1)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Your Garden',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Everything you\'ve grown so far',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.ink.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Total Focus',
                      _fmt(stats.totalMinutes),
                      Icons.timer_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stat(
                      'This Week',
                      '${stats.sessionsThisWeek} grown',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Longest',
                      _fmt(stats.longestMinutes),
                      Icons.park_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _stat(
                      'Streak',
                      '${stats.currentStreak} days',
                      Icons.local_fire_department_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (goal > 0) ...[
                _goalCard(stats.todayMinutes, goal, goalStreak),
                const SizedBox(height: 22),
              ],
              if (stats.tagBreakdown.isNotEmpty) ...[
                _breakdown(stats.tagBreakdown),
                const SizedBox(height: 22),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Plants',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty) _empty() else ...recent.map(_tile),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.leafGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ink.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(int today, int goal, int streak) {
    final progress = (today / goal).clamp(0.0, 1.0);
    final met = today >= goal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.leafGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                "Today's Goal",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (met)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Bloomed!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_fmt(today)} / ${_fmt(goal)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (streak > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Goal streak: $streak days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _breakdown(Map<String, int> breakdown) {
    final total = breakdown.values.fold(0, (a, b) => a + b);
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'What You Grew',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sections: entries
                          .map(
                            (e) => PieChartSectionData(
                              value: e.value.toDouble(),
                              color: AppTheme.tagColor(e.key),
                              radius: 55,
                              showTitle: false,
                            ),
                          )
                          .toList(),
                      centerSpaceRadius: 15,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: entries.map((e) {
                      final pct = total > 0
                          ? (e.value / total * 100).round()
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppTheme.tagColor(e.key),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(FocusSession s) {
    final date = s.plantedAt;
    final dateStr =
        '${date.month}/${date.day} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (s.bloomed ? AppColors.success : AppColors.danger)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            // Show the actual species that was grown rather than one
            // generic flower for every plant.
            child: SizedBox(
              width: 20,
              height: 20,
              child: SproutMark(
                size: 20,
                progress: s.bloomed ? 1.0 : 0.3,
                species: PlantSpecies.byId(s.plantType),
                silhouette: !s.bloomed,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fmt(s.grownMinutes)} ${PlantSpecies.byId(s.plantType).name}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          _tagChip(s.tag),
        ],
      ),
    );
  }

  Widget _tagChip(String tag) {
    final color = AppTheme.tagColor(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.local_florist_outlined,
            size: 48,
            color: AppColors.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Your garden is empty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grow a focus session to plant your first one!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.ink.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  static BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static String _fmt(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
