import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/team_identity.dart';
import '../../../theme/app_theme.dart';
import '../../tournaments/presentation/workspace_components.dart';
import '../data/category_schedule_providers.dart';
import '../domain/category_schedule.dart';

final class CategoryScheduleSection extends ConsumerStatefulWidget {
  const CategoryScheduleSection({
    super.key,
    required this.tournamentId,
    this.embedded = false,
  });

  final String tournamentId;
  final bool embedded;

  @override
  ConsumerState<CategoryScheduleSection> createState() =>
      _CategoryScheduleSectionState();
}

class _CategoryScheduleSectionState
    extends ConsumerState<CategoryScheduleSection> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      categoryScheduleSnapshotProvider(widget.tournamentId),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkspaceSectionLead(
          title: 'Match flow',
          description:
              'Preview the derived pool structure, rounds, and knockout path from the saved seed order.',
          icon: Icons.calendar_view_week_rounded,
          accent: AppPalette.sageStrong,
        ),
        const SizedBox(height: AppSpace.lg),
        if (state.hasValue)
          WorkspaceStatRail(
            metrics: [
              WorkspaceMetricItemData(
                value: '${_visibleCategories(state.requireValue).length}',
                label: 'categories',
                foreground: const Color(0xFF456F77),
                isHighlighted: true,
              ),
              WorkspaceMetricItemData(
                value:
                    '${_visibleCategories(state.requireValue).fold<int>(0, (sum, category) => sum + category.groups.length)}',
                label: 'groups',
                foreground: const Color(0xFF365141),
              ),
              WorkspaceMetricItemData(
                value:
                    '${_visibleCategories(state.requireValue).fold<int>(0, (sum, category) => sum + category.playableMatchCount)}',
                label: 'matches',
                foreground: const Color(0xFF8F6038),
              ),
            ],
          ),
        if (state.hasValue) const SizedBox(height: AppSpace.lg),
        state.when(
          data: (snapshot) {
            if (snapshot.isEmpty) {
              return const _EmptyState();
            }

            final visibleCategories = _visibleCategories(snapshot);
            return Column(
              children: [
                if (snapshot.categories.length > 1) ...[
                  _CategoryFilterBar(
                    selectedCategoryId: _selectedCategoryId,
                    categories: snapshot.categories
                        .map(
                          (category) => (
                            id: category.categoryId,
                            name: category.categoryName,
                          ),
                        )
                        .toList(growable: false),
                    onSelected: (categoryId) {
                      setState(() {
                        _selectedCategoryId = categoryId;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                ],
                for (
                  var index = 0;
                  index < visibleCategories.length;
                  index++
                ) ...[
                  _CategoryScheduleCard(category: visibleCategories[index]),
                  if (index < visibleCategories.length - 1)
                    const SizedBox(height: AppSpace.md),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _ErrorState(message: error.toString()),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: content,
    );
  }

  List<GeneratedCategorySchedule> _visibleCategories(
    TournamentCategoryScheduleSnapshot snapshot,
  ) {
    final selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null) {
      return snapshot.categories;
    }
    final filtered = snapshot.categories
        .where((category) => category.categoryId == selectedCategoryId)
        .toList(growable: false);
    if (filtered.isNotEmpty) {
      return filtered;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedCategoryId = null;
      });
    });
    return snapshot.categories;
  }
}

final class _CategoryScheduleCard extends StatelessWidget {
  const _CategoryScheduleCard({required this.category});

  final GeneratedCategorySchedule category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (category.mode) {
      GeneratedScheduleMode.roundRobinTop4 => AppPalette.sageStrong,
      GeneratedScheduleMode.groupsKnockout => AppPalette.sky,
    };

    return WorkspaceSurfaceCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.categoryName, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpace.xs),
              Text(
                category.mode.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppPalette.inkSoft,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  WorkspaceTag(
                    label: category.mode.label,
                    background: accent.withValues(alpha: 0.16),
                    foreground: AppPalette.ink,
                  ),
                  if (category.groups.length > 1)
                    WorkspaceTag(
                      label: '${category.groups.length} pools',
                      background: AppPalette.surfaceSoft,
                      foreground: const Color(0xFF365141),
                    ),
                  WorkspaceTag(
                    label: '${category.teamCount} teams',
                    background: AppPalette.skySoft,
                    foreground: const Color(0xFF456F77),
                  ),
                  WorkspaceTag(
                    label: '${category.playableMatchCount} matches',
                    background: AppPalette.apricotSoft,
                    foreground: const Color(0xFF8F6038),
                  ),
                  if (category.qualifierCount > 0)
                    WorkspaceTag(
                      label: category.qualificationSummary,
                      background: AppPalette.oliveSoft,
                      foreground: const Color(0xFF5F7243),
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              _SectionHeader(
                title: category.groups.length > 1 ? 'Pools' : 'Seed order',
              ),
              const SizedBox(height: AppSpace.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useSingleColumn = constraints.maxWidth < 720;
                  final cardWidth = useSingleColumn
                      ? constraints.maxWidth
                      : 260.0;

                  return Wrap(
                    spacing: AppSpace.md,
                    runSpacing: AppSpace.md,
                    children: [
                      for (final group in category.groups)
                        SizedBox(
                          width: cardWidth,
                          child: _GroupCard(
                            group: group,
                            isMultiGroup: category.groups.length > 1,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpace.lg),
              _SectionHeader(
                title: category.groups.length > 1
                    ? 'Pool schedule'
                    : 'Round schedule',
              ),
              const SizedBox(height: AppSpace.sm),
              Column(
                children: [
                  for (
                    var roundIndex = 0;
                    roundIndex < category.rounds.length;
                    roundIndex++
                  ) ...[
                    _RoundCard(round: category.rounds[roundIndex]),
                    if (roundIndex < category.rounds.length - 1)
                      const SizedBox(height: AppSpace.md),
                  ],
                ],
              ),
              if (category.qualificationMatches.isNotEmpty) ...[
                const SizedBox(height: AppSpace.lg),
                const _SectionHeader(title: 'Knockout path'),
                const SizedBox(height: AppSpace.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final useSingleColumn = constraints.maxWidth < 720;
                    final cardWidth = useSingleColumn
                        ? constraints.maxWidth
                        : 220.0;

                    return Wrap(
                      spacing: AppSpace.md,
                      runSpacing: AppSpace.md,
                      children: [
                        for (final match in category.qualificationMatches)
                          SizedBox(
                            width: cardWidth,
                            child: _QualificationCard(match: match),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.isMultiGroup});

  final GeneratedScheduleGroup group;
  final bool isMultiGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMultiGroup ? 'Pool ${group.code}' : group.code,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.sm),
          for (var index = 0; index < group.entries.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${index + 1}',
                    style: AppTheme.numeric(
                      theme.textTheme.bodySmall,
                    ).copyWith(color: AppPalette.inkSoft),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    group.entries[index].detailLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (index < group.entries.length - 1)
              const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

final class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.round});

  final GeneratedScheduleRound round;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(round.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.sm),
          for (var index = 0; index < round.matches.length; index++) ...[
            _MatchRow(match: round.matches[index]),
            if (index < round.matches.length - 1)
              const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

final class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.match});

  final GeneratedScheduledMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppPalette.skySoft,
              borderRadius: BorderRadius.circular(AppRadii.chip),
              border: Border.all(color: AppPalette.sky.withValues(alpha: 0.35)),
            ),
            child: Text(
              match.code,
              style: AppTheme.numeric(
                theme.textTheme.bodySmall,
              ).copyWith(color: const Color(0xFF456F77)),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TeamIdentityAvatar(
                      entry: match.teamOne,
                      size: 28,
                      radius: 10,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        match.teamOne.displayLabel,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (match.teamTwo != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      TeamIdentityAvatar(
                        entry: match.teamTwo!,
                        size: 28,
                        radius: 10,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          match.teamTwo!.displayLabel,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Bye',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _QualificationCard extends StatelessWidget {
  const _QualificationCard({required this.match});

  final GeneratedQualificationMatch match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(match.label, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            '${match.homeSource} vs ${match.awaySource}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            match.stageLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const WorkspaceEmptyCard(
      title: 'No schedules yet',
      message:
          'Onboard at least two teams in a category to generate groupings and match rounds.',
    );
  }
}

final class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WorkspaceErrorCard(
      title: 'Scheduling needs attention',
      message: message,
    );
  }
}

final class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedCategoryId,
    required this.categories,
    required this.onSelected,
  });

  final String? selectedCategoryId;
  final List<({String id, String name})> categories;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CategoryFilterChip(
            label: 'All categories',
            selected: selectedCategoryId == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: AppSpace.xs),
            _CategoryFilterChip(
              label: category.name,
              selected: selectedCategoryId == category.id,
              onTap: () => onSelected(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

final class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppPalette.skySoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppPalette.sky.withValues(alpha: 0.4)
                : AppPalette.line,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? AppPalette.ink : AppPalette.inkSoft,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
