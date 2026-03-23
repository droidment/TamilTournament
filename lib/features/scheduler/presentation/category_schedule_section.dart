import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../data/category_schedule_providers.dart';
import '../domain/category_schedule.dart';

final class CategoryScheduleSection extends ConsumerWidget {
  const CategoryScheduleSection({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryScheduleSnapshotProvider(tournamentId));
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grouping and schedule',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Generate category groups and round order from the teams you have onboarded and seeded.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              state.whenOrNull(
                    data: (snapshot) => Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        _SummaryChip(
                          label: '${snapshot.categories.length} categories',
                          tint: AppPalette.skySoft,
                          border: AppPalette.sky.withValues(alpha: 0.35),
                          foreground: const Color(0xFF456F77),
                        ),
                        _SummaryChip(
                          label: '${snapshot.totalGroups} groups',
                          tint: AppPalette.sageSoft,
                          border: AppPalette.sage.withValues(alpha: 0.35),
                          foreground: const Color(0xFF365141),
                        ),
                        _SummaryChip(
                          label: '${snapshot.totalMatches} matches',
                          tint: AppPalette.apricotSoft,
                          border: AppPalette.apricot.withValues(alpha: 0.35),
                          foreground: const Color(0xFF8F6038),
                        ),
                      ],
                    ),
                  ) ??
                  const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
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
      ),
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

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
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
                    _SummaryChip(
                      label: category.mode.label,
                      tint: accent.withValues(alpha: 0.16),
                      border: accent.withValues(alpha: 0.35),
                      foreground: AppPalette.ink,
                    ),
                    _SummaryChip(
                      label: '${category.teamCount} teams',
                      tint: AppPalette.skySoft,
                      border: AppPalette.sky.withValues(alpha: 0.35),
                      foreground: const Color(0xFF456F77),
                    ),
                    _SummaryChip(
                      label: '${category.playableMatchCount} matches',
                      tint: AppPalette.apricotSoft,
                      border: AppPalette.apricot.withValues(alpha: 0.35),
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
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
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
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
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
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
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

final class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.tint,
    required this.border,
    required this.foreground,
  });

  final String label;
  final Color tint;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: foreground),
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No schedules yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Onboard at least two teams in a category to generate groupings and match rounds.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: const Color(0x24C97D6B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x47C97D6B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduling needs attention',
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF7B4D42),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7B4D42),
            ),
          ),
        ],
      ),
    );
  }
}
