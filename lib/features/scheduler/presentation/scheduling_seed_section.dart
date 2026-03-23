import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../data/scheduling_seed_providers.dart';
import '../domain/scheduling_seed.dart';

final class SchedulingSeedSection extends ConsumerWidget {
  const SchedulingSeedSection({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schedulingSeedStateProvider(tournamentId));
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scheduling seeds',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Ready categories are derived from checked-in entries only. Seeds stay read-only until the scheduler is wired in.',
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
                      alignment: WrapAlignment.end,
                      children: [
                        _MetaChip(
                          label: '${snapshot.readyCategories.length} ready',
                          tint: AppPalette.sageSoft,
                          border: AppPalette.sage.withValues(alpha: 0.4),
                          foreground: const Color(0xFF365141),
                        ),
                        _MetaChip(
                          label: '${snapshot.totalCheckedInEntries} checked in',
                          tint: AppPalette.skySoft,
                          border: AppPalette.sky.withValues(alpha: 0.4),
                          foreground: const Color(0xFF456F77),
                        ),
                        _MetaChip(
                          label: '${snapshot.totalMatchups} seeds',
                          tint: AppPalette.apricotSoft,
                          border: AppPalette.apricot.withValues(alpha: 0.4),
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
                return const _SchedulingSeedEmptyState();
              }
              return Column(
                children: [
                  for (
                    var index = 0;
                    index < snapshot.readyCategories.length;
                    index++
                  ) ...[
                    _ReadyCategoryCard(
                      category: snapshot.readyCategories[index],
                    ),
                    if (index < snapshot.readyCategories.length - 1)
                      const SizedBox(height: AppSpace.md),
                  ],
                ],
              );
            },
            loading: () => const _SchedulingSeedLoadingState(),
            error: (error, _) =>
                _SchedulingSeedErrorState(message: _friendlyError(error)),
          ),
        ],
      ),
    );
  }
}

final class _ReadyCategoryCard extends StatelessWidget {
  const _ReadyCategoryCard({required this.category});

  final ReadyCategorySeed category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = category.formatLabel.toLowerCase() == 'knockout'
        ? AppPalette.apricot
        : AppPalette.sageStrong;

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.categoryName,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            '${category.formatLabel} · ${category.checkedInCount} checked in',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MetaChip(
                      label: '${category.matchups.length} seeds',
                      tint: AppPalette.oliveSoft,
                      border: AppPalette.oliveStrong.withValues(alpha: 0.4),
                      foreground: const Color(0xFF5F7243),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Column(
                  children: [
                    for (
                      var index = 0;
                      index < category.matchups.length;
                      index++
                    ) ...[
                      _SeedMatchupTile(matchup: category.matchups[index]),
                      if (index < category.matchups.length - 1)
                        const SizedBox(height: AppSpace.sm),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _SeedMatchupTile extends StatelessWidget {
  const _SeedMatchupTile({required this.matchup});

  final SeedMatchup matchup;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.skySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.sky.withValues(alpha: 0.35)),
            ),
            child: Text(
              '#${matchup.seedNumber}',
              style: AppTheme.numeric(
                theme.textTheme.labelLarge,
              ).copyWith(color: const Color(0xFF456F77)),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchup.playerTwo == 'Bye'
                      ? '${matchup.playerOne} gets a bye'
                      : '${matchup.playerOne} vs ${matchup.playerTwo}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  matchup.hasBye
                      ? 'Awaiting the next checked-in entry to complete the seed.'
                      : 'Ready to schedule once the court opens.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MetaChip extends StatelessWidget {
  const _MetaChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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

final class _SchedulingSeedLoadingState extends StatelessWidget {
  const _SchedulingSeedLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LoadingSeedCard(),
        SizedBox(height: AppSpace.md),
        _LoadingSeedCard(),
      ],
    );
  }
}

final class _LoadingSeedCard extends StatelessWidget {
  const _LoadingSeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 18,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            width: 220,
            height: 12,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SchedulingSeedEmptyState extends StatelessWidget {
  const _SchedulingSeedEmptyState();

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
          Text('No ready categories yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Check in at least two entries in a category to generate seed matchups.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _SchedulingSeedErrorState extends StatelessWidget {
  const _SchedulingSeedErrorState({required this.message});

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
            'Scheduling seeds need attention',
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

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'Deploy the current Firestore rules, then reload the app.';
  }
  if (message.contains('failed-precondition')) {
    return 'Create the Firestore database in Firebase Console first, then reload the app.';
  }
  return message;
}
