import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../firebase/firebase_status.dart';
import '../../../theme/app_theme.dart';
import '../../tournaments/data/tournament_providers.dart';
import '../../tournaments/domain/tournament.dart';
import '../../tournaments/presentation/tournament_workspace_panel.dart';

final class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(ownedTournamentsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _Sidebar(tournaments: tournaments)),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                flex: 9,
                child: _DashboardContent(tournaments: tournaments),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.tournaments});

  final AsyncValue<List<Tournament>> tournaments;

  @override
  Widget build(BuildContext context) {
    final items = tournaments.maybeWhen(
      data: (value) => value,
      orElse: () => const <Tournament>[],
    );

    return ListView(
      children: [
        _Header(tournaments: items),
        const SizedBox(height: AppSpace.lg),
        _OverviewRow(tournaments: items),
        const SizedBox(height: AppSpace.lg),
        _RecentTournamentsPanel(tournaments: tournaments),
        const SizedBox(height: AppSpace.lg),
        const TournamentWorkspacePanel(),
        const SizedBox(height: AppSpace.lg),
        const _FirebaseNotice(),
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.tournaments});

  final List<Tournament> tournaments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : user?.email ?? 'Organizer';
    final nextTournament = tournaments.isEmpty ? null : tournaments.first;

    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Wrap(
        spacing: AppSpace.lg,
        runSpacing: AppSpace.lg,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organizer workspace',
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  nextTournament == null
                      ? 'Signed in as $displayName. Create a tournament to start wiring categories, entries, and scheduling against Firestore.'
                      : 'Signed in as $displayName. Your latest tournament is ${nextTournament.name} at ${nextTournament.venue} on ${_formatDate(nextTournament.startDate)}.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _HeaderChip(
                label: '${tournaments.length} tournaments',
                tint: AppPalette.skySoft,
                border: AppPalette.sky.withValues(alpha: 0.45),
                foreground: const Color(0xFF456F77),
              ),
              _HeaderChip(
                label:
                    '${_statusCount(tournaments, TournamentStatus.live)} live',
                tint: AppPalette.sageSoft,
                border: AppPalette.sage.withValues(alpha: 0.45),
                foreground: const Color(0xFF365141),
              ),
              _HeaderChip(
                label:
                    '${_statusCount(tournaments, TournamentStatus.draft)} drafts',
                tint: AppPalette.apricotSoft,
                border: AppPalette.apricot.withValues(alpha: 0.45),
                foreground: const Color(0xFF8F6038),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.tournaments});

  final List<Tournament> tournaments;

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
      spacing: AppSpace.md,
      runSpacing: AppSpace.md,
      children: [
        _MetricCard(
          label: 'Tournaments',
          value: '${tournaments.length}',
          meta: '${_statusCount(tournaments, TournamentStatus.setup)} in setup',
          accent: AppPalette.sky,
          wash: const Color(0x268DBEC6),
          valueColor: const Color(0xFF376570),
        ),
        _MetricCard(
          label: 'Categories',
          value: '$totalCategories',
          meta:
              '${_statusCount(tournaments, TournamentStatus.live)} live events',
          accent: AppPalette.sageStrong,
          wash: const Color(0x1F98BFA6),
          valueColor: const Color(0xFF486655),
        ),
        _MetricCard(
          label: 'Entries',
          value: '$totalEntries',
          meta: 'Across all owned tournaments',
          accent: AppPalette.oliveStrong,
          wash: const Color(0x268FA16F),
          valueColor: const Color(0xFF5F7243),
        ),
        _MetricCard(
          label: 'Matches',
          value: '$totalMatches',
          meta: 'Stored in tournament stats',
          accent: AppPalette.apricot,
          wash: const Color(0x2BDDB085),
          valueColor: const Color(0xFF8F6038),
        ),
      ],
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.meta,
    required this.accent,
    required this.wash,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String meta;
  final Color accent;
  final Color wash;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppPalette.line),
          gradient: LinearGradient(
            colors: [wash, Colors.transparent],
            begin: Alignment.topCenter,
            end: const Alignment(0, 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 4, color: accent),
            const SizedBox(height: AppSpace.md),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              value,
              style: AppTheme.numeric(theme.textTheme.displaySmall).copyWith(
                color: valueColor,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Container(height: 1, color: AppPalette.line),
            const SizedBox(height: AppSpace.md),
            Text(
              meta,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent tournaments',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'This section is now driven by Firestore instead of sample scheduler cards.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          tournaments.when(
            data: (items) {
              if (items.isEmpty) {
                return const _EmptyRecentTournaments();
              }
              final recent = items.take(3).toList(growable: false);
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
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/tournaments/${tournament.id}'),
        child: Container(
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            '${tournament.venue} · ${_formatDate(tournament.startDate)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.sm,
                      alignment: WrapAlignment.end,
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
          Text('No tournaments yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Use the workspace below to create your first Firestore-backed tournament.',
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
                'Firebase not configured yet',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Choose the Firebase project for this app, then run flutterfire configure for web to generate the web Firebase options file.',
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
  const _Sidebar({required this.tournaments});

  final AsyncValue<List<Tournament>> tournaments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : user?.email ?? 'Organizer';
    final email = user?.email ?? 'Signed in with Google';
    final initials = _userInitials(displayName);
    final items = tournaments.maybeWhen(
      data: (value) => value,
      orElse: () => const <Tournament>[],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12443828),
            blurRadius: 50,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppPalette.sage, AppPalette.surfaceSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(initials, style: theme.textTheme.labelLarge),
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
                      'Firestore workspace',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Text(
            'Live account summary',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppPalette.inkMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          _SidebarStat(label: 'Owned tournaments', value: '${items.length}'),
          _SidebarStat(
            label: 'Live tournaments',
            value: '${_statusCount(items, TournamentStatus.live)}',
          ),
          _SidebarStat(
            label: 'Draft tournaments',
            value: '${_statusCount(items, TournamentStatus.draft)}',
          ),
          _SidebarStat(
            label: 'Total entries',
            value:
                '${items.fold<int>(0, (sum, tournament) => sum + tournament.stats.entries)}',
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppPalette.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: FirebaseAuth.instance.signOut,
                    child: const Text('Sign out'),
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

final class _SidebarStat extends StatelessWidget {
  const _SidebarStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppPalette.surfaceSoft,
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.numeric(
              theme.textTheme.titleMedium,
            ).copyWith(color: AppPalette.ink),
          ),
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

final class _DataErrorState extends StatelessWidget {
  const _DataErrorState({required this.message});

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
            'Firestore needs attention',
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
    return 'Deploy the Firestore rules in this repo, then reload the app.';
  }
  if (message.contains('failed-precondition')) {
    return 'Create the Firestore database in Firebase Console first, then reload the app.';
  }
  return message;
}

int _statusCount(List<Tournament> tournaments, TournamentStatus status) {
  return tournaments.where((tournament) => tournament.status == status).length;
}

String _userInitials(String value) {
  final parts = value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) {
    return 'TT';
  }

  return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
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
