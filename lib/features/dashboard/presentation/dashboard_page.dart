import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../firebase/firebase_status.dart';
import '../../../theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';
import '../../scheduler/data/tournament_match_providers.dart';
import '../../scheduler/domain/tournament_match.dart';
import '../../tournaments/data/tournament_providers.dart';
import '../../tournaments/domain/tournament.dart';
import '../../tournaments/presentation/tournament_workspace_panel.dart';

final class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(ownedTournamentsProvider);
    final hasResolvedAuthSession =
        ref.watch(firebaseAuthProvider).currentUser != null;

    if (tournaments.isLoading &&
        !tournaments.hasValue &&
        !hasResolvedAuthSession) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            return Padding(
              padding: EdgeInsets.all(isCompact ? AppSpace.sm : AppSpace.lg),
              child: isCompact
                  ? ListView(
                      children: [
                        _Sidebar(tournaments: tournaments, isCompact: true),
                        const SizedBox(height: AppSpace.md),
                        _DashboardContent(
                          tournaments: tournaments,
                          isCompact: true,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _Sidebar(
                            tournaments: tournaments,
                            isCompact: false,
                          ),
                        ),
                        const SizedBox(width: AppSpace.lg),
                        Expanded(
                          flex: 9,
                          child: _DashboardContent(
                            tournaments: tournaments,
                            isCompact: false,
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

final class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.tournaments, required this.isCompact});

  final AsyncValue<List<Tournament>> tournaments;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final items = tournaments.maybeWhen(
      data: (value) => value,
      orElse: () => const <Tournament>[],
    );

    return ListView(
      shrinkWrap: isCompact,
      physics: isCompact
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      children: [
        _Header(tournaments: items, isCompact: isCompact),
        SizedBox(height: isCompact ? AppSpace.md : AppSpace.lg),
        TournamentWorkspacePanel(tournaments: tournaments),
        SizedBox(height: isCompact ? AppSpace.md : AppSpace.lg),
        const _FirebaseNotice(),
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.tournaments, required this.isCompact});

  final List<Tournament> tournaments;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextTournament = tournaments.cast<Tournament?>().firstWhere(
      (tournament) => tournament?.status != TournamentStatus.completed,
      orElse: () => tournaments.isEmpty ? null : tournaments.first,
    );

    return Container(
      padding: EdgeInsets.all(isCompact ? AppSpace.md : AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nextTournament == null
                ? 'Organizer workspace'
                : nextTournament.status == TournamentStatus.completed
                ? 'Latest result'
                : 'Current tournament',
            style: isCompact
                ? theme.textTheme.headlineLarge
                : theme.textTheme.displayMedium,
          ),
          if (nextTournament == null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              'Create a tournament to start planning categories, entries, and match flow.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
          ],
          if (nextTournament != null) ...[
            const SizedBox(height: AppSpace.sm),
            _CurrentTournamentCard(tournament: nextTournament),
          ],
        ],
      ),
    );
  }
}

final class _CurrentTournamentCard extends ConsumerWidget {
  const _CurrentTournamentCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = switch (tournament.status) {
      TournamentStatus.draft => AppPalette.sky,
      TournamentStatus.setup => AppPalette.apricot,
      TournamentStatus.live => AppPalette.sageStrong,
      TournamentStatus.completed => AppPalette.oliveStrong,
    };
    final winners = tournament.status == TournamentStatus.completed
        ? ref.watch(completedWinnerSummariesProvider(tournament.id))
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go('/tournaments/${tournament.id}'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.84),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${tournament.venue} · ${_formatDate(tournament.startDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.inkSoft,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  _HeaderChip(
                    label: tournament.status.label,
                    tint: accent.withValues(alpha: 0.18),
                    border: accent.withValues(alpha: 0.4),
                    foreground: AppPalette.ink,
                  ),
                  _HeaderChip(
                    label: '${tournament.stats.categories} categories',
                    tint: AppPalette.skySoft,
                    border: AppPalette.sky.withValues(alpha: 0.35),
                    foreground: const Color(0xFF456F77),
                  ),
                  _HeaderChip(
                    label: '${tournament.stats.entries} entries',
                    tint: AppPalette.oliveSoft,
                    border: AppPalette.oliveStrong.withValues(alpha: 0.35),
                    foreground: const Color(0xFF5F7243),
                  ),
                  _HeaderChip(
                    label: '${tournament.stats.matches} matches',
                    tint: AppPalette.apricotSoft,
                    border: AppPalette.apricot.withValues(alpha: 0.35),
                    foreground: const Color(0xFF8F6038),
                  ),
                ],
              ),
              if (winners != null) ...[
                const SizedBox(height: AppSpace.md),
                _CompletedResultsSummary(
                  winners: winners,
                  emptyMessage:
                      'Final winners will show here once each category title match is completed.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
final class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.tournaments, required this.isCompact});

  final List<Tournament> tournaments;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final totalCategories = tournaments.fold<int>(
      0,
      (sum, tournament) => sum + tournament.stats.categories,
    );
    final totalEntries = tournaments.fold<int>(
      0,
      (sum, tournament) => sum + tournament.stats.entries,
    );
    final totalMatches = tournaments.fold<int>(
      0,
      (sum, tournament) => sum + tournament.stats.matches,
    );

    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        _MetricBadge(
          label: 'Tournaments',
          value: '${tournaments.length}',
          accent: const Color(0xFF376570),
          tint: AppPalette.skySoft,
          meta: '${_statusCount(tournaments, TournamentStatus.setup)} in setup',
        ),
        _MetricBadge(
          label: 'Categories',
          value: '$totalCategories',
          accent: const Color(0xFF486655),
          tint: AppPalette.sageSoft,
          meta:
              '${_statusCount(tournaments, TournamentStatus.live)} live events',
        ),
        _MetricBadge(
          label: 'Entries',
          value: '$totalEntries',
          accent: const Color(0xFF5F7243),
          tint: AppPalette.oliveSoft,
          meta: 'Across all owned tournaments',
        ),
        _MetricBadge(
          label: 'Matches',
          value: '$totalMatches',
          accent: const Color(0xFF8F6038),
          tint: AppPalette.apricotSoft,
          meta: 'Stored in tournament stats',
        ),
      ],
    );
  }
}

// ignore: unused_element
final class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    required this.meta,
    required this.accent,
    required this.tint,
  });

  final String label;
  final String value;
  final String meta;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTheme.numeric(
              theme.textTheme.titleLarge,
            ).copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            '$label  ·  $meta',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
final class _RecentTournamentsPanel extends StatelessWidget {
  const _RecentTournamentsPanel({required this.tournaments});

  final AsyncValue<List<Tournament>> tournaments;

  @override
  Widget build(BuildContext context) {
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
          Text('Other tournaments', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Open another tournament or start a new one.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          tournaments.when(
            data: (items) {
              final recent = items.skip(1).take(3).toList(growable: false);
              if (recent.isEmpty) {
                return const _EmptyRecentTournaments();
              }
              return Column(
                children: [
                  for (var index = 0; index < recent.length; index++) ...[
                    _RecentTournamentCard(tournament: recent[index]),
                    if (index < recent.length - 1)
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
            error: (error, _) =>
                _DataErrorState(message: _friendlyError(error)),
          ),
        ],
      ),
    );
  }
}

final class _RecentTournamentCard extends StatelessWidget {
  const _RecentTournamentCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (tournament.status) {
      TournamentStatus.draft => AppPalette.sky,
      TournamentStatus.setup => AppPalette.apricot,
      TournamentStatus.live => AppPalette.sageStrong,
      TournamentStatus.completed => AppPalette.oliveStrong,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/tournaments/${tournament.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPalette.line),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      '${tournament.venue} · ${_formatDate(tournament.startDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      children: [
                        _HeaderChip(
                          label: tournament.status.label,
                          tint: accent.withValues(alpha: 0.18),
                          border: accent.withValues(alpha: 0.45),
                          foreground: AppPalette.ink,
                        ),
                        _HeaderChip(
                          label: '${tournament.stats.categories} categories',
                          tint: AppPalette.skySoft,
                          border: AppPalette.sky.withValues(alpha: 0.45),
                          foreground: const Color(0xFF456F77),
                        ),
                        _HeaderChip(
                          label: '${tournament.stats.entries} entries',
                          tint: AppPalette.oliveSoft,
                          border: AppPalette.oliveStrong.withValues(
                            alpha: 0.45,
                          ),
                          foreground: const Color(0xFF5F7243),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EmptyRecentTournaments extends StatelessWidget {
  const _EmptyRecentTournaments();

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
          Text('No other tournaments yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Use the tournament list above to create another tournament when you need one.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _FirebaseNotice extends StatelessWidget {
  const _FirebaseNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<FirebaseStatus>(
      valueListenable: FirebaseBindingState.instance.value,
      builder: (context, status, _) {
        if (status == FirebaseStatus.configured) {
          return const SizedBox.shrink();
        }
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
              Text(
                'Workspace setup incomplete',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Tournament services are not ready in this environment yet. Open the live organizer site or finish setup before continuing.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppPalette.inkSoft,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.tournaments, required this.isCompact});

  final AsyncValue<List<Tournament>> tournaments;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = tournaments.maybeWhen(
      data: (value) => value,
      orElse: () => const <Tournament>[],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  gradient: const LinearGradient(
                    colors: [AppPalette.sage, AppPalette.surfaceSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.emoji_events_outlined, size: 18),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tamil Tournament',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Workspace',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: FirebaseAuth.instance.signOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                tooltip: 'Sign out',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _HeaderChip(
                label: '${items.length} owned',
                tint: AppPalette.skySoft,
                border: AppPalette.sky.withValues(alpha: 0.35),
                foreground: const Color(0xFF456F77),
              ),
              _HeaderChip(
                label: '${_statusCount(items, TournamentStatus.live)} live',
                tint: AppPalette.sageSoft,
                border: AppPalette.sage.withValues(alpha: 0.35),
                foreground: const Color(0xFF365141),
              ),
              _HeaderChip(
                label: '${_statusCount(items, TournamentStatus.draft)} drafts',
                tint: AppPalette.apricotSoft,
                border: AppPalette.apricot.withValues(alpha: 0.35),
                foreground: const Color(0xFF8F6038),
              ),
              _HeaderChip(
                label:
                    '${_statusCount(items, TournamentStatus.completed)} completed',
                tint: AppPalette.oliveSoft,
                border: AppPalette.oliveStrong.withValues(alpha: 0.35),
                foreground: const Color(0xFF5F7243),
              ),
              _HeaderChip(
                label:
                    '${items.fold<int>(0, (sum, tournament) => sum + tournament.stats.entries)} entries',
                tint: AppPalette.surfaceSoft,
                border: AppPalette.lineStrong,
                foreground: AppPalette.inkSoft,
              ),
            ],
          ),
          if (!isCompact) const Spacer(),
        ],
      ),
    );
  }
}

final class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
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

final class _CompletedResultsSummary extends StatelessWidget {
  const _CompletedResultsSummary({
    required this.winners,
    required this.emptyMessage,
  });

  final AsyncValue<List<TournamentWinnerSummary>> winners;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return winners.when(
      data: (items) {
        if (items.isEmpty) {
          return Text(
            emptyMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category winners',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final winner in items) _WinnerSummaryChip(summary: winner),
              ],
            ),
          ],
        );
      },
      loading: () => Text(
        'Loading category winners...',
        style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
      ),
      error: (_, _) => Text(
        'Category winners are not available right now.',
        style: theme.textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
      ),
    );
  }
}

final class _WinnerSummaryChip extends StatelessWidget {
  const _WinnerSummaryChip({required this.summary});

  final TournamentWinnerSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.oliveSoft, AppPalette.surface],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPalette.oliveStrong.withValues(alpha: 0.26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.categoryName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary.championLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPalette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

final class _DataErrorState extends StatelessWidget {
  const _DataErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: const Color(0x24C97D6B),
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: const Color(0x47C97D6B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace needs attention',
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
    return 'This organizer account does not have access to tournament data yet. Reload and try again.';
  }
  if (message.contains('failed-precondition')) {
    return 'Tournament data is not ready yet in this environment. Try again in a moment.';
  }
  return 'We could not load the organizer workspace right now. Please try again.';
}

int _statusCount(List<Tournament> tournaments, TournamentStatus status) {
  return tournaments.where((tournament) => tournament.status == status).length;
}

String _formatDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
