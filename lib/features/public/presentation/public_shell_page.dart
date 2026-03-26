import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';
import '../../categories/data/category_providers.dart';
import '../../categories/domain/category_item.dart';
import '../../scheduler/data/court_providers.dart';
import '../../scheduler/data/tournament_match_providers.dart';
import '../../scheduler/data/tournament_standings_providers.dart';
import '../../scheduler/domain/category_schedule.dart';
import '../../scheduler/domain/tournament_court.dart';
import '../../scheduler/domain/tournament_match.dart';
import '../../scheduler/domain/tournament_standings.dart';
import '../../tournaments/data/tournament_providers.dart';
import '../../tournaments/data/tournament_role_providers.dart';
import '../../tournaments/domain/tournament.dart';
import '../../tournaments/domain/tournament_role.dart';
import '../../tournaments/presentation/workspace_components.dart';

final class PublicShellPage extends ConsumerStatefulWidget {
  const PublicShellPage({required this.publicSlug, super.key});

  final String publicSlug;

  @override
  ConsumerState<PublicShellPage> createState() => _PublicShellPageState();
}

class _PublicShellPageState extends ConsumerState<PublicShellPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isSigningIn = false;
  bool _isVolunteering = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(
      publicTournamentByCodeProvider(widget.publicSlug),
    );

    return tournamentAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
      error: (error, _) => _PublicScaffold(
        child: WorkspaceErrorCard(
          title: 'Public tournament unavailable',
          message: error.toString(),
        ),
      ),
      data: (tournament) {
        if (tournament == null) {
          return const _PublicScaffold(
            child: WorkspaceErrorCard(
              title: 'Tournament not available',
              message:
                  'This tournament is not published yet or the public code is incorrect.',
            ),
          );
        }

        final categoriesAsync = ref.watch(
          tournamentCategoriesProvider(tournament.id),
        );
        final matchesAsync = ref.watch(
          tournamentMatchesProvider(tournament.id),
        );
        final courtsAsync = ref.watch(tournamentCourtsProvider(tournament.id));
        final standingsAsync = ref.watch(
          tournamentStandingsProvider(tournament.id),
        );
        final user =
            ref.watch(authStateChangesProvider).asData?.value ??
            ref.watch(firebaseAuthProvider).currentUser;
        final roleAsync = user == null
            ? const AsyncValue<TournamentRole?>.data(null)
            : ref.watch(currentUserRoleProvider(tournament.id));

        final firstError =
            categoriesAsync.error ??
            matchesAsync.error ??
            courtsAsync.error ??
            standingsAsync.error;
        if (firstError != null) {
          return _PublicScaffold(
            tournamentName: tournament.name,
            child: WorkspaceErrorCard(
              title: 'Public page needs attention',
              message: firstError.toString(),
            ),
          );
        }

        if (categoriesAsync.isLoading ||
            matchesAsync.isLoading ||
            courtsAsync.isLoading ||
            standingsAsync.isLoading) {
          return _PublicScaffold(
            tournamentName: tournament.name,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final visibleCategories = _publishedOrAll(
          categoriesAsync.value ?? const [],
        );
        final normalizedQuery = _query.trim().toLowerCase();
        final matches = _filterMatches(
          matchesAsync.value ?? const [],
          normalizedQuery,
        );
        final activeMatches = matches
            .where(
              (match) =>
                  match.assignedCourtId != null &&
                  !match.isCompleted &&
                  match.status != TournamentMatchStatus.cancelled &&
                  match.status != TournamentMatchStatus.pending,
            )
            .toList(growable: false);
        final completedMatches =
            matches.where((match) => match.isCompleted).toList(growable: false)
              ..sort((left, right) {
                final leftTime = left.completedAt?.millisecondsSinceEpoch ?? 0;
                final rightTime =
                    right.completedAt?.millisecondsSinceEpoch ?? 0;
                return rightTime.compareTo(leftTime);
              });
        final filteredCategories = normalizedQuery.isEmpty
            ? visibleCategories
            : visibleCategories
                  .where(
                    (category) =>
                        category.name.toLowerCase().contains(normalizedQuery),
                  )
                  .toList(growable: false);
        final standings = standingsAsync.asData?.value;

        return _PublicScaffold(
          tournamentName: tournament.name,
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              _HeroCard(
                tournament: tournament,
                categoryCount: visibleCategories.length,
                activeCourtCount:
                    courtsAsync.value
                        ?.where((court) => court.isAvailable)
                        .length ??
                    0,
                activeMatchCount: activeMatches.length,
                completedMatchCount: (matchesAsync.value ?? const [])
                    .where((m) => m.isCompleted)
                    .length,
              ),
              const SizedBox(height: AppSpace.lg),
              _VolunteerCard(
                tournament: tournament,
                roleAsync: roleAsync,
                isSigningIn: _isSigningIn,
                isVolunteering: _isVolunteering,
                onSignIn: _signInWithGoogle,
                onVolunteer: user == null
                    ? null
                    : () => _volunteerAsReferee(tournament.id, user),
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  labelText: 'Search matches, teams, courts, or categories',
                  hintText: 'Example: C1, RR-3, Men Open',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              WorkspaceStatRail(
                metrics: [
                  WorkspaceMetricItemData(
                    value: '${visibleCategories.length}',
                    label: 'categories',
                    foreground: const Color(0xFF456F77),
                    isHighlighted: true,
                  ),
                  WorkspaceMetricItemData(
                    value:
                        '${courtsAsync.value?.where((court) => court.isAvailable).length ?? 0}',
                    label: 'live courts',
                    foreground: const Color(0xFF365141),
                  ),
                  WorkspaceMetricItemData(
                    value: '${activeMatches.length}',
                    label: 'active matches',
                    foreground: const Color(0xFF8F6038),
                  ),
                  WorkspaceMetricItemData(
                    value: '${completedMatches.length}',
                    label: 'official results',
                    foreground: AppPalette.inkSoft,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              _Section(
                title: 'Live courts',
                subtitle:
                    'Track courts, active pairings, and what is currently in play.',
                child: _CourtBoard(
                  courts: courtsAsync.value ?? const [],
                  activeMatches: activeMatches,
                  query: normalizedQuery,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              _Section(
                title: 'Recent results',
                subtitle:
                    'Only official results appear here after assistant or organizer approval.',
                child: _ResultList(matches: completedMatches),
              ),
              const SizedBox(height: AppSpace.xl),
              _Section(
                title: 'Category standings',
                subtitle:
                    'Qualification lines update from official results as the day progresses.',
                child: _StandingsList(
                  snapshot: standings,
                  query: normalizedQuery,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              _Section(
                title: 'Categories',
                subtitle: 'Browse the divisions currently in the tournament.',
                child: _CategoryList(categories: filteredCategories),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      if (!kIsWeb) {
        throw UnsupportedError(
          'This sign-in flow is available in the web app.',
        );
      }
      final provider = GoogleAuthProvider()
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithPopup(provider);
      ref.invalidate(publicTournamentByCodeProvider(widget.publicSlug));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in. You can volunteer now.')),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_friendlyAuthError(error))));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _volunteerAsReferee(String tournamentId, User user) async {
    if (_isVolunteering) return;
    setState(() => _isVolunteering = true);
    try {
      await ref
          .read(tournamentRoleRepositoryProvider)
          .volunteerAsReferee(tournamentId: tournamentId, user: user);
      ref.invalidate(currentUserRoleProvider(tournamentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referee access is active. Open the referee desk.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isVolunteering = false);
    }
  }
}

final class _PublicScaffold extends StatelessWidget {
  const _PublicScaffold({required this.child, this.tournamentName});

  final Widget child;
  final String? tournamentName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.go('/');
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Public tournament'),
        actions: [
          if (tournamentName != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  tournamentName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}

final class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.tournament,
    required this.categoryCount,
    required this.activeCourtCount,
    required this.activeMatchCount,
    required this.completedMatchCount,
  });

  final Tournament tournament;
  final int categoryCount;
  final int activeCourtCount;
  final int activeMatchCount;
  final int completedMatchCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F2EE), Color(0xFFF7F5EF)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tournament.name,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Follow live courts, official results, and category progress from one public tournament page.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              WorkspaceTag(
                label: tournament.venue,
                background: AppPalette.surface,
                foreground: AppPalette.inkSoft,
                icon: Icons.location_on_outlined,
              ),
              WorkspaceTag(
                label: _formatDate(tournament.startDate),
                background: AppPalette.surface,
                foreground: AppPalette.inkSoft,
                icon: Icons.event_outlined,
              ),
              WorkspaceTag(
                label: tournament.status.label,
                background: AppPalette.sageSoft,
                foreground: const Color(0xFF365141),
                icon: Icons.flag_outlined,
              ),
              if (tournament.acceptingVolunteerReferees)
                const WorkspaceTag(
                  label: 'Volunteer referees open',
                  background: AppPalette.apricotSoft,
                  foreground: Color(0xFF8F6038),
                  icon: Icons.sports_tennis,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _MetricChip(label: 'Categories', value: '$categoryCount'),
              _MetricChip(label: 'Live courts', value: '$activeCourtCount'),
              _MetricChip(label: 'Active matches', value: '$activeMatchCount'),
              _MetricChip(
                label: 'Official results',
                value: '$completedMatchCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({
    required this.tournament,
    required this.roleAsync,
    required this.isSigningIn,
    required this.isVolunteering,
    required this.onSignIn,
    required this.onVolunteer,
  });

  final Tournament tournament;
  final AsyncValue<TournamentRole?> roleAsync;
  final bool isSigningIn;
  final bool isVolunteering;
  final VoidCallback onSignIn;
  final VoidCallback? onVolunteer;

  @override
  Widget build(BuildContext context) {
    final role = roleAsync.asData?.value;
    final user = FirebaseAuth.instance.currentUser;
    late final String title;
    late final String message;
    Widget? action;

    if (roleAsync.isLoading && user != null) {
      title = 'Checking desk access';
      message = 'Verifying whether you already have staff or referee access.';
      action = const FilledButton(onPressed: null, child: Text('Checking...'));
    } else if (role?.role == TournamentRoleType.organizer) {
      title = 'Organizer access active';
      message =
          'You already manage this tournament from the organizer workspace.';
      action = FilledButton.icon(
        onPressed: () => context.go('/tournaments/${tournament.id}'),
        icon: const Icon(Icons.admin_panel_settings_outlined),
        label: const Text('Open organizer workspace'),
      );
    } else if (role?.role == TournamentRoleType.assistant) {
      title = 'Assistant access active';
      message = 'You already have assistant desk access for this tournament.';
      action = FilledButton.icon(
        onPressed: () => context.go('/a/${tournament.id}'),
        icon: const Icon(Icons.assignment_ind),
        label: const Text('Open assistant desk'),
      );
    } else if (role?.role == TournamentRoleType.referee) {
      title = 'Referee access active';
      message = 'You can head straight to the referee desk and submit scores.';
      action = FilledButton.icon(
        onPressed: () => context.go('/r/${tournament.id}'),
        icon: const Icon(Icons.sports_tennis),
        label: const Text('Open referee desk'),
      );
    } else if (!tournament.acceptingVolunteerReferees) {
      title = 'Referee volunteering closed';
      message =
          'The organizer has not opened volunteer referees for this tournament.';
    } else if (user == null) {
      title = 'Volunteer as referee';
      message =
          'Sign in with Google first, then volunteer and immediately unlock the referee desk.';
      action = FilledButton.icon(
        onPressed: isSigningIn ? null : onSignIn,
        icon: const Icon(Icons.login_rounded),
        label: Text(
          isSigningIn ? 'Opening sign-in...' : 'Sign in to volunteer',
        ),
      );
    } else {
      title = 'Volunteer as referee';
      message =
          'You are signed in. Volunteer now and start using the referee desk right away.';
      action = FilledButton.icon(
        onPressed: isVolunteering ? null : onVolunteer,
        icon: const Icon(Icons.sports_tennis),
        label: Text(isVolunteering ? 'Activating...' : 'Volunteer as referee'),
      );
    }

    return WorkspaceSurfaceCard(
      accent: AppPalette.apricot,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpace.xs),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
          ),
          if (action != null) ...[const SizedBox(height: AppSpace.md), action],
        ],
      ),
    );
  }
}

final class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppPalette.line),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSpace.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
        ),
        const SizedBox(height: AppSpace.md),
        child,
      ],
    );
  }
}

final class _CourtBoard extends StatelessWidget {
  const _CourtBoard({
    required this.courts,
    required this.activeMatches,
    required this.query,
  });

  final List<TournamentCourt> courts;
  final List<TournamentMatch> activeMatches;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (courts.isEmpty) {
      return const WorkspaceEmptyCard(
        title: 'Courts are not published yet',
        message:
            'The public court board will appear once courts are configured.',
      );
    }

    final matchByCourtId = <String, TournamentMatch>{
      for (final match in activeMatches)
        if (match.assignedCourtId != null) match.assignedCourtId!: match,
    };
    final filteredCourts = query.isEmpty
        ? courts
        : courts
              .where((court) {
                final match = matchByCourtId[court.id];
                return court.code.toLowerCase().contains(query) ||
                    court.name.toLowerCase().contains(query) ||
                    (match?.teamOneLabel.toLowerCase().contains(query) ??
                        false) ||
                    (match?.teamTwoLabel.toLowerCase().contains(query) ??
                        false) ||
                    (match?.categoryName.toLowerCase().contains(query) ??
                        false);
              })
              .toList(growable: false);

    return Wrap(
      spacing: AppSpace.md,
      runSpacing: AppSpace.md,
      children: [
        for (final court in filteredCourts)
          SizedBox(
            width: 250,
            child: WorkspaceSurfaceCard(
              accent: court.isAvailable
                  ? AppPalette.sageStrong
                  : AppPalette.apricot,
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          court.code,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      WorkspaceTag(
                        label:
                            matchByCourtId[court.id]?.status.label ??
                            court.status.label,
                        background: AppPalette.surfaceSoft,
                        foreground: AppPalette.inkSoft,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    court.name,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    matchByCourtId[court.id] == null
                        ? (court.isAvailable
                              ? 'Open court'
                              : 'Court unavailable')
                        : '${matchByCourtId[court.id]!.teamOneLabel} vs ${matchByCourtId[court.id]!.teamTwoLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (matchByCourtId[court.id]?.hasScores ?? false) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      matchByCourtId[court.id]!.scoreSummary,
                      style: AppTheme.numeric(
                        Theme.of(context).textTheme.bodySmall,
                      ).copyWith(color: AppPalette.inkSoft),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

final class _ResultList extends StatelessWidget {
  const _ResultList({required this.matches});

  final List<TournamentMatch> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const WorkspaceEmptyCard(
        title: 'No official results yet',
        message:
            'Completed matches will appear here after referee submissions are approved or staff commits scores directly.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < matches.length; index++) ...[
          WorkspaceSurfaceCard(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${matches[index].categoryName} | ${matches[index].matchCode}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppPalette.inkSoft),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '${matches[index].teamOneLabel} vs ${matches[index].teamTwoLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
                    WorkspaceTag(
                      label: matches[index].winnerLabel ?? 'Winner decided',
                      background: AppPalette.oliveSoft,
                      foreground: const Color(0xFF5F7243),
                    ),
                    if (matches[index].hasScores)
                      WorkspaceTag(
                        label: matches[index].scoreSummary,
                        background: AppPalette.surfaceSoft,
                        foreground: AppPalette.inkSoft,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (index < matches.length - 1) const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

final class _StandingsList extends StatelessWidget {
  const _StandingsList({required this.snapshot, required this.query});

  final TournamentStandingsSnapshot? snapshot;
  final String query;

  @override
  Widget build(BuildContext context) {
    final categories = snapshot?.categories ?? const <CategoryStandings>[];
    final filtered = query.isEmpty
        ? categories
        : categories
              .where(
                (category) =>
                    category.categoryName.toLowerCase().contains(query),
              )
              .toList(growable: false);

    if (filtered.isEmpty) {
      return const WorkspaceEmptyCard(
        title: 'Standings not ready yet',
        message:
            'Standings and qualification lines will appear once official results accumulate.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < filtered.length; index++) ...[
          WorkspaceSurfaceCard(
            accent: filtered[index].mode == GeneratedScheduleMode.roundRobinTop4
                ? AppPalette.sageStrong
                : AppPalette.sky,
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filtered[index].categoryName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  filtered[index].qualificationSummary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
                ),
                const SizedBox(height: AppSpace.md),
                for (final row
                    in filtered[index].groups
                        .expand((g) => g.rows)
                        .take(4)) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${row.rank}',
                          style: AppTheme.numeric(
                            Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(child: Text(row.entry.displayLabel)),
                      Text(
                        '${row.wins}-${row.losses}',
                        style: AppTheme.numeric(
                          Theme.of(context).textTheme.bodySmall,
                        ).copyWith(color: AppPalette.inkSoft),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                ],
              ],
            ),
          ),
          if (index < filtered.length - 1) const SizedBox(height: AppSpace.sm),
        ],
      ],
    );
  }
}

final class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<CategoryItem> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const WorkspaceEmptyCard(
        title: 'No categories match the search',
        message: 'Try a different term or clear the search field.',
      );
    }

    return Wrap(
      spacing: AppSpace.md,
      runSpacing: AppSpace.md,
      children: [
        for (final category in categories)
          SizedBox(
            width: 240,
            child: WorkspaceSurfaceCard(
              accent: category.format == CategoryFormat.knockout
                  ? AppPalette.apricot
                  : AppPalette.sageStrong,
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Wrap(
                    spacing: AppSpace.xs,
                    runSpacing: AppSpace.xs,
                    children: [
                      WorkspaceTag(
                        label: category.format.label,
                        background: AppPalette.surfaceSoft,
                        foreground: AppPalette.inkSoft,
                      ),
                      WorkspaceTag(
                        label: '${category.checkedInPairs} checked in',
                        background: AppPalette.skySoft,
                        foreground: const Color(0xFF456F77),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

List<CategoryItem> _publishedOrAll(List<CategoryItem> categories) {
  final published = categories
      .where((category) => category.isPublished)
      .toList(growable: false);
  return published.isNotEmpty ? published : categories;
}

List<TournamentMatch> _filterMatches(
  List<TournamentMatch> matches,
  String query,
) {
  if (query.isEmpty) {
    return matches;
  }
  return matches
      .where(
        (match) =>
            match.matchCode.toLowerCase().contains(query) ||
            match.categoryName.toLowerCase().contains(query) ||
            match.teamOneLabel.toLowerCase().contains(query) ||
            match.teamTwoLabel.toLowerCase().contains(query) ||
            (match.assignedCourtCode?.toLowerCase().contains(query) ?? false),
      )
      .toList(growable: false);
}

String _friendlyAuthError(FirebaseAuthException error) {
  final message = error.message ?? error.code;
  if (message.contains('authorized') || message.contains('OAuth')) {
    return 'This site is not approved for sign-in from this address yet.';
  }
  if (error.code == 'popup-blocked') {
    return 'Sign-in was blocked by the browser. Allow the sign-in window and try again.';
  }
  if (error.code == 'popup-closed-by-user') {
    return 'Sign-in was closed before it finished. Try again when you are ready.';
  }
  return 'We could not open sign-in right now. Please try again.';
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
