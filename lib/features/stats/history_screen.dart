import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage/session_repository.dart';
import '../../models/focus_session.dart';
import '../../theme/app_colors.dart';
import '../garden/widgets/plant_species.dart';
import '../garden/widgets/sprout_painter.dart';
import '../../theme/app_strings.dart';
import '../../theme/app_theme.dart';

/// Full list of grown sessions, filterable by tag.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all';

  List<String> get _filters => ['all', ...AppStrings.tags];

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SessionRepository>();
    final sessions = _filter == 'all' ? repo.all() : repo.withTag(_filter);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.ink,
                        size: 28,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Garden History',
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
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  itemBuilder: (context, i) {
                    final tag = _filters[i];
                    final selected = tag == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(tag == 'all' ? 'All' : tag),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = tag),
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.18,
                        ),
                        checkmarkColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.hairline,
                        ),
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : AppColors.muted,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: sessions.isEmpty
                    ? Center(
                        child: Text(
                          _filter == 'all'
                              ? 'Your garden is empty'
                              : 'No "$_filter" plants yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.ink.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: sessions.length,
                        itemBuilder: (context, i) => _tile(sessions[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(FocusSession s) {
    final d = s.plantedAt;
    final dateStr =
        '${d.month}/${d.day}/${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (s.note != null && s.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.note!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ink.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
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

  static String _fmt(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}
