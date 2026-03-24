import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../tournaments/presentation/workspace_components.dart';
import '../data/category_schedule_providers.dart';
import '../domain/category_schedule.dart';

final class CategoryScheduleSection extends ConsumerWidget {
  const CategoryScheduleSection({
    super.key,
    required this.tournamentId,
    this.embedded = false,
  });

  final String tournamentId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryScheduleSnapshotProvider(tournamentId));
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkspaceSectionLead(
          title: 'Schedule',
          description:
              'Generate category groups, rounds, and qualification paths from the teams you have already seeded.',
        ),
        const SizedBox(height: AppSpace.lg),
        if (state.hasValue)
          WorkspaceStatRail(
            metrics: [
              WorkspaceMetricItemData(
                value: '${state.requireValue.categories.length}',
                label: 'categories',
                foreground: const Color(0xFF456F77),
                isHighlighted: true,
              ),
              WorkspaceMetricItemData(
                value: '${state.requireValue.totalGroups}',
                label: 'groups',
                foreground: const Color(0xFF365141),
              ),
              WorkspaceMetricItemData(
                value: '${state.requireValue.totalMatches}',
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

            return Column(
              children: [
                for (
                  var index = 0;
                  index < snapshot.categories.length;
                  index++
                ) ...[
                  _CategoryScheduleCard(category: snapshot.categories[index]),
                  if (index < snapshot.categories.length - 1)
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

    if (embedded) {
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
}

final class _CategoryScheduleCard extends StatelessWidget {
  const _CategoryScheduleCard({required this.category});

  final GeneratedCategorySchedule category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (category.mode) {
      GeneratedScheduleMode.roundRobinTop4 => AppPalette.sageStrong,
      GeneratedScheduleMode.groupsTop2 => AppPalette.sky,
      GeneratedScheduleMode.knockoutPreview => AppPalette.apricot,
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
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              _SectionHeader(
                title: category.groups.length > 1 ? 'Groups' : 'Seed order',
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  for (final group in category.groups)
                    _GroupCard(
                      group: group,
                      isMultiGroup: category.groups.length > 1,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              _SectionHeader(title: 'Round schedule'),
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
                const _SectionHeader(title: 'Qualification path'),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.md,
                  runSpacing: AppSpace.md,
                  children: [
                    for (final match in category.qualificationMatches)
                      _QualificationCard(match: match),
                  ],
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
      width: 280,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMultiGroup ? 'Group ${group.code}' : group.code,
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
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(16),
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
            child: Text(
              match.hasBye
                  ? '${match.teamOne.displayLabel} has a bye'
                  : '${match.teamOne.displayLabel} vs ${match.teamTwo!.displayLabel}',
              style: theme.textTheme.bodyMedium,
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
      width: 240,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
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
