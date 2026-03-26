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

enum _PublicFocusFilter { all, live, results, standings, categories }

extension on _PublicFocusFilter {
  String get label => switch (this) {
    _PublicFocusFilter.all => 'All',
    _PublicFocusFilter.live => 'Live',
    _PublicFocusFilter.results => 'Results',
    _PublicFocusFilter.standings => 'Standings',
    _PublicFocusFilter.categories => 'Categories',
  };

  IconData get icon => switch (this) {
    _PublicFocusFilter.all => Icons.dashboard_outlined,
    _PublicFocusFilter.live => Icons.sports_tennis,
    _PublicFocusFilter.results => Icons.emoji_events_outlined,
    _PublicFocusFilter.standings => Icons.leaderboard_rounded,
    _PublicFocusFilter.categories => Icons.category_rounded,
  };
}

final class PublicShellPage extends ConsumerStatefulWidget {
  const PublicShellPage({required this.publicSlug, super.key});

  final String publicSlug;

  @override
  ConsumerState<PublicShellPage> createState() => _PublicShellPageState();
}

class _PublicShellPageState extends ConsumerState<PublicShellPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _PublicFocusFilter _focusFilter = _PublicFocusFilter.live;
  bool _isSigningIn = false;
  bool _isVolunteering = false;

  static const _mobileTabs = <_PublicFocusFilter>[
    _PublicFocusFilter.live,
    _PublicFocusFilter.results,
    _PublicFocusFilter.standings,
    _PublicFocusFilter.categories,
  ];

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
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isCompact = screenWidth < 760;
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
        final visibleCategories = _publishedOrAll(
          categoriesAsync.asData?.value ?? const <CategoryItem>[],
        );
        final normalizedQuery = _query.trim().toLowerCase();
        final matches = _filterMatches(
          matchesAsync.asData?.value ?? const <TournamentMatch>[],
          normalizedQuery,
        );
        final courts = courtsAsync.asData?.value ?? const <TournamentCourt>[];
        final activeMatches = matches
            .where(
              (match) =>
                  match.assignedCourtId != null &&
                  !match.isCompleted &&
                  match.status != TournamentMatchStatus.cancelled &&
                  match.status != TournamentMatchStatus.pending,
            )
            .toList(growable: false);
        activeMatches.sort(_compareActiveMatches);
        final completedMatches =
            matches.where((match) => match.isCompleted).toList(growable: false)
              ..sort((left, right) {
                final leftTime = left.completedAt?.millisecondsSinceEpoch ?? 0;
                final rightTime =
                    right.completedAt?.millisecondsSinceEpoch ?? 0;
                return rightTime.compareTo(leftTime);
              });
        final liveCourtCount = activeMatches
            .where((match) => match.assignedCourtId != null)
            .length;
        final filteredCategories = normalizedQuery.isEmpty
            ? visibleCategories
            : visibleCategories
                  .where(
                    (category) =>
                        category.name.toLowerCase().contains(normalizedQuery) ||
                        category.format.label.toLowerCase().contains(
                          normalizedQuery,
                        ),
                  )
                  .toList(growable: false);
        final standings = standingsAsync.asData?.value;
        final highlightMatches = activeMatches.take(3).toList(growable: false);
        final recentResults = completedMatches.take(6).toList(growable: false);
        final visibleCategoriesPreview = filteredCategories
            .take(6)
            .toList(growable: false);
        final activeFilter = isCompact && _focusFilter == _PublicFocusFilter.all
            ? _PublicFocusFilter.live
            : _focusFilter;

        return _PublicScaffold(
          tournamentName: tournament.name,
          bottomNavigationBar: isCompact
              ? _PublicBottomNavigation(
                  currentFilter: activeFilter,
                  tabs: _mobileTabs,
                  onSelect: (filter) {
                    setState(() {
                      _focusFilter = filter;
                    });
                  },
                )
              : null,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.lg,
              AppSpace.lg,
              isCompact ? 96 : AppSpace.xxl,
            ),
            children: [
              _HeroCard(
                tournament: tournament,
                categoryCount: categoriesAsync.hasValue
                    ? visibleCategories.length
                    : tournament.stats.categories,
                activeCourtCount: courtsAsync.hasValue
                    ? liveCourtCount
                    : tournament.activeCourtCount,
                activeMatchCount: activeMatches.length,
                completedMatchCount:
                    (matchesAsync.asData?.value ?? const <TournamentMatch>[])
                        .where((m) => m.isCompleted)
                        .length,
                highlightMatches: highlightMatches,
              ),
              const SizedBox(height: AppSpace.lg),
              _SearchHubCard(
                controller: _searchController,
                query: normalizedQuery,
                focusFilter: activeFilter,
                showsFilters: !isCompact,
                onChanged: (value) => setState(() => _query = value),
                onSelectFilter: (filter) {
                  setState(() {
                    _focusFilter = filter;
                  });
                },
                onClear: normalizedQuery.isEmpty
                    ? null
                    : () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _focusFilter = isCompact
                              ? _PublicFocusFilter.live
                              : _PublicFocusFilter.all;
                        });
                      },
                stats: [
                  WorkspaceMetricItemData(
                    value: '${visibleCategories.length}',
                    label: 'categories',
                    foreground: const Color(0xFF456F77),
                    isHighlighted: true,
                  ),
                  WorkspaceMetricItemData(
                    value: '$liveCourtCount',
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
              if (activeFilter == _PublicFocusFilter.all ||
                  activeFilter == _PublicFocusFilter.live) ...[
                const SizedBox(height: AppSpace.xl),
                _Section(
                  title: 'Live courts',
                  subtitle:
                      'Track what is on court now and which matches are getting called next.',
                  accent: AppPalette.sageStrong,
                  icon: Icons.sports_tennis,
                  child: _buildSectionBody<List<TournamentCourt>>(
                    state: courtsAsync,
                    loadingTitle: 'Loading live courts',
                    loadingMessage:
                        'Pulling court assignments and current floor activity.',
                    errorTitle: 'Live courts unavailable',
                    content: (_) => _CourtBoard(
                      courts: courts,
                      activeMatches: activeMatches,
                      query: normalizedQuery,
                    ),
                  ),
                ),
              ],
              if (activeFilter == _PublicFocusFilter.all ||
                  activeFilter == _PublicFocusFilter.results ||
                  activeFilter == _PublicFocusFilter.standings) ...[
                const SizedBox(height: AppSpace.xl),
                _Section(
                  title: 'Recent official results',
                  subtitle:
                      'Only approved results appear here after assistant or organizer approval.',
                  accent: AppPalette.apricot,
                  icon: Icons.emoji_events_outlined,
                  child: _buildSectionBody<List<TournamentMatch>>(
                    state: matchesAsync,
                    loadingTitle: 'Loading official results',
                    loadingMessage:
                        'Checking the latest approved results for this tournament.',
                    errorTitle: 'Results unavailable',
                    content: (_) => _ResultList(matches: recentResults),
                  ),
                ),
                if (activeFilter == _PublicFocusFilter.all ||
                    activeFilter == _PublicFocusFilter.standings) ...[
                  const SizedBox(height: AppSpace.xl),
                  _Section(
                    title: 'Category standings',
                    subtitle:
                        'Qualification lines update from official results as the day moves.',
                    accent: AppPalette.sky,
                    icon: Icons.leaderboard_rounded,
                    child: _buildSectionBody<TournamentStandingsSnapshot>(
                      state: standingsAsync,
                      loadingTitle: 'Loading standings',
                      loadingMessage:
                          'Calculating category tables from official tournament results.',
                      errorTitle: 'Standings unavailable',
                      content: (_) => _StandingsList(
                        snapshot: standings,
                        query: normalizedQuery,
                        limit: activeFilter == _PublicFocusFilter.all
                            ? 3
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
              if (activeFilter == _PublicFocusFilter.all ||
                  activeFilter == _PublicFocusFilter.categories) ...[
                const SizedBox(height: AppSpace.xl),
                _Section(
                  title: 'Categories',
                  subtitle:
                      'Browse the divisions in the event and see which formats are in play.',
                  accent: AppPalette.sky,
                  icon: Icons.category_rounded,
                  child: _buildSectionBody<List<CategoryItem>>(
                    state: categoriesAsync,
                    loadingTitle: 'Loading categories',
                    loadingMessage:
                        'Bringing in the published divisions for this tournament.',
                    errorTitle: 'Categories unavailable',
                    content: (_) =>
                        _CategoryList(categories: visibleCategoriesPreview),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionBody<T>({
    required AsyncValue<T> state,
    required String loadingTitle,
    required String loadingMessage,
    required String errorTitle,
    required Widget Function(T? value) content,
  }) {
    if (state.hasError && !state.hasValue) {
      return WorkspaceErrorCard(
        title: errorTitle,
        message: state.error.toString(),
      );
    }
    if (state.isLoading && !state.hasValue) {
      return _SectionLoadingCard(title: loadingTitle, message: loadingMessage);
    }
    return content(state.asData?.value);
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
  const _PublicScaffold({
    required this.child,
    this.tournamentName,
    this.bottomNavigationBar,
  });

  final Widget child;
  final String? tournamentName;
  final Widget? bottomNavigationBar;

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
      bottomNavigationBar: bottomNavigationBar,
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
    required this.highlightMatches,
  });

  final Tournament tournament;
  final int categoryCount;
  final int activeCourtCount;
  final int activeMatchCount;
  final int completedMatchCount;
  final List<TournamentMatch> highlightMatches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDDF3EC), Color(0xFFE8F4E0), Color(0xFFF6E4D1)],
          stops: [0.0, 0.48, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9DDD3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B1612),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 860;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PUBLIC TOURNAMENT BOARD',
                style: AppTheme.numeric(theme.textTheme.labelLarge).copyWith(
                  color: AppPalette.inkSoft,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                tournament.name,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'Find live courts first, then follow official results, standings, and category movement without asking the desk.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppPalette.inkSoft,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  WorkspaceTag(
                    label: tournament.venue,
                    background: Colors.white.withValues(alpha: 0.78),
                    foreground: AppPalette.inkSoft,
                    icon: Icons.location_on_outlined,
                  ),
                  WorkspaceTag(
                    label: _formatDate(tournament.startDate),
                    background: Colors.white.withValues(alpha: 0.78),
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
                  _MetricChip(
                    label: 'Active matches',
                    value: '$activeMatchCount',
                  ),
                  _MetricChip(
                    label: 'Official results',
                    value: '$completedMatchCount',
                  ),
                ],
              ),
            ],
          );

          final liveNowPanel = Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  AppPalette.surfaceSoft.withValues(alpha: 0.86),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live now',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  highlightMatches.isEmpty
                      ? 'Courts and matchups will appear here as soon as the floor is active.'
                      : 'Top live or upcoming courts at a glance.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.inkSoft,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                if (highlightMatches.isEmpty)
                  const WorkspaceTag(
                    label: 'Waiting for live court assignments',
                    background: AppPalette.surface,
                    foreground: AppPalette.inkSoft,
                    icon: Icons.schedule_rounded,
                  )
                else
                  for (final match in highlightMatches) ...[
                    _LiveHighlightRow(match: match),
                    if (match != highlightMatches.last)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpace.sm),
                        child: Divider(height: 1, color: AppPalette.line),
                      ),
                  ],
              ],
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                const SizedBox(height: AppSpace.lg),
                liveNowPanel,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: intro),
              const SizedBox(width: AppSpace.xl),
              Expanded(flex: 4, child: liveNowPanel),
            ],
          );
        },
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
          'Sign in with Google first, then volunteer and immediately unlock the referee desk for court-side score submission.';
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
          'You are signed in. Volunteer now to unlock the referee desk. Referee submissions still require assistant or organizer approval before they become official.';
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppPalette.apricotSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_tennis,
                  color: Color(0xFF8F6038),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.md),
          const Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              WorkspaceTag(
                label: 'Public page shows official data only',
                background: AppPalette.skySoft,
                foreground: Color(0xFF456F77),
                icon: Icons.verified_outlined,
              ),
            ],
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
    this.accent = AppPalette.sageStrong,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkspaceSectionLead(
          title: title,
          description: subtitle,
          icon: icon,
          accent: accent,
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
                    (match?.teamOneDetail.toLowerCase().contains(query) ??
                        false) ||
                    (match?.teamTwoDetail.toLowerCase().contains(query) ??
                        false) ||
                    (match?.categoryName.toLowerCase().contains(query) ??
                        false);
              })
              .toList(growable: false);
    filteredCourts.sort((left, right) {
      final leftRank = _courtPriority(matchByCourtId[left.id], left);
      final rightRank = _courtPriority(matchByCourtId[right.id], right);
      if (leftRank != rightRank) {
        return leftRank.compareTo(rightRank);
      }
      return left.orderIndex.compareTo(right.orderIndex);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = switch (availableWidth) {
          < 720 => availableWidth,
          < 1120 => (availableWidth - AppSpace.md) / 2,
          _ => (availableWidth - (AppSpace.md * 2)) / 3,
        };

        return Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          children: [
            for (final court in filteredCourts)
              SizedBox(
                width: cardWidth,
                child: WorkspaceSurfaceCard(
                  accent: _courtAccent(matchByCourtId[court.id], court),
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
                            label: _courtStatusLabel(
                              matchByCourtId[court.id],
                              court,
                            ),
                            background: _courtTagBackground(
                              matchByCourtId[court.id],
                              court,
                            ),
                            foreground: _courtTagForeground(
                              matchByCourtId[court.id],
                              court,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        court.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.inkSoft,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        matchByCourtId[court.id] == null
                            ? (court.isAvailable
                                  ? 'Open court'
                                  : 'Court unavailable')
                            : matchByCourtId[court.id]!.categoryName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: matchByCourtId[court.id] == null
                              ? AppPalette.inkSoft
                              : AppPalette.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (matchByCourtId[court.id] != null) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          '${_publicTeamLabel(matchByCourtId[court.id]!.teamOneLabel, matchByCourtId[court.id]!.teamOneDetail)} vs ${_publicTeamLabel(matchByCourtId[court.id]!.teamTwoLabel, matchByCourtId[court.id]!.teamTwoDetail)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPalette.inkSoft),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Wrap(
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xs,
                          children: [
                            WorkspaceTag(
                              label: matchByCourtId[court.id]!.matchCode,
                              background: AppPalette.surfaceSoft,
                              foreground: AppPalette.inkSoft,
                            ),
                            if (matchByCourtId[court.id]!.assignedCourtName !=
                                null)
                              WorkspaceTag(
                                label: matchByCourtId[court.id]!
                                    .assignedCourtName!,
                                background: AppPalette.skySoft,
                                foreground: const Color(0xFF456F77),
                              ),
                          ],
                        ),
                      ],
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
      },
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
                  '${_publicTeamLabel(matches[index].teamOneLabel, matches[index].teamOneDetail)} vs ${_publicTeamLabel(matches[index].teamTwoLabel, matches[index].teamTwoDetail)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
                    WorkspaceTag(
                      label: _winnerPublicLabel(matches[index]),
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
  const _StandingsList({
    required this.snapshot,
    required this.query,
    this.limit,
  });

  final TournamentStandingsSnapshot? snapshot;
  final String query;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final filtered = _filterStandings(
      snapshot?.categories ?? const <CategoryStandings>[],
      query,
    );
    final visible = limit == null
        ? filtered
        : filtered.take(limit!).toList(growable: false);

    if (visible.isEmpty) {
      return const WorkspaceEmptyCard(
        title: 'Standings not ready yet',
        message:
            'Standings and qualification lines will appear once official results accumulate.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < visible.length; index++) ...[
          WorkspaceSurfaceCard(
            accent: visible[index].mode == GeneratedScheduleMode.roundRobinTop4
                ? AppPalette.sageStrong
                : AppPalette.sky,
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visible[index].categoryName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  visible[index].qualificationSummary,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
                ),
                const SizedBox(height: AppSpace.md),
                for (final row
                    in visible[index].groups.expand((g) => g.rows).take(4)) ...[
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
          if (index < visible.length - 1) const SizedBox(height: AppSpace.sm),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = switch (availableWidth) {
          < 720 => availableWidth,
          < 1120 => (availableWidth - AppSpace.md) / 2,
          _ => (availableWidth - (AppSpace.md * 2)) / 3,
        };

        return Wrap(
          spacing: AppSpace.md,
          runSpacing: AppSpace.md,
          children: [
            for (final category in categories)
              SizedBox(
                width: cardWidth,
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
      },
    );
  }
}

final class _SearchHubCard extends StatelessWidget {
  const _SearchHubCard({
    required this.controller,
    required this.query,
    required this.focusFilter,
    required this.showsFilters,
    required this.onChanged,
    required this.onSelectFilter,
    required this.onClear,
    required this.stats,
  });

  final TextEditingController controller;
  final String query;
  final _PublicFocusFilter focusFilter;
  final bool showsFilters;
  final ValueChanged<String> onChanged;
  final ValueChanged<_PublicFocusFilter> onSelectFilter;
  final VoidCallback? onClear;
  final List<WorkspaceMetricItemData> stats;

  @override
  Widget build(BuildContext context) {
    return WorkspaceSurfaceCard(
      accent: AppPalette.sky,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find your match fast',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Search by team, player, category, match code, or court. Use quick filters to stay on the slice you care about.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: 'Search the tournament',
              hintText: 'Example: C1, RR-3, Men Open, Raj, Bala',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: onClear == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          if (showsFilters) ...[
            const SizedBox(height: AppSpace.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _PublicFocusFilter.values) ...[
                    _FilterChip(
                      filter: filter,
                      isSelected: focusFilter == filter,
                      onTap: () => onSelectFilter(filter),
                    ),
                    if (filter != _PublicFocusFilter.values.last)
                      const SizedBox(width: AppSpace.sm),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          WorkspaceStatRail(metrics: stats),
          if (query.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              'Filtering across live courts, official results, standings, and categories for "$query".',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

final class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final _PublicFocusFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4F7D73), Color(0xFF6C958C)],
                  )
                : null,
            color: isSelected ? null : AppPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4F7D73)
                  : AppPalette.lineStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                filter.icon,
                size: 16,
                color: isSelected ? Colors.white : AppPalette.inkSoft,
              ),
              const SizedBox(width: AppSpace.xs),
              Text(
                filter.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : AppPalette.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PublicBottomNavigation extends StatelessWidget {
  const _PublicBottomNavigation({
    required this.currentFilter,
    required this.tabs,
    required this.onSelect,
  });

  final _PublicFocusFilter currentFilter;
  final List<_PublicFocusFilter> tabs;
  final ValueChanged<_PublicFocusFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final currentIndex = tabs.indexOf(currentFilter);
    final selectedIndex = currentIndex < 0 ? 0 : currentIndex;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.xs,
          AppSpace.md,
          AppSpace.md,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5FAF8), Color(0xFFFFFBF5)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppPalette.lineStrong),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140B1612),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppPalette.sageSoft,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) => onSelect(tabs[index]),
            destinations: [
              for (final tab in tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.icon, color: AppPalette.sageStrong),
                  label: tab.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LiveHighlightRow extends StatelessWidget {
  const _LiveHighlightRow({required this.match});

  final TournamentMatch match;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _matchAccent(match).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _matchStatusIcon(match),
            color: _matchAccent(match),
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.assignedCourtCode == null
                    ? match.matchCode
                    : '${match.assignedCourtCode} • ${match.matchCode}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppPalette.inkSoft),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                '${_publicTeamLabel(match.teamOneLabel, match.teamOneDetail)} vs ${_publicTeamLabel(match.teamTwoLabel, match.teamTwoDetail)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                match.categoryName,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        WorkspaceTag(
          label: _matchStatusLabel(match),
          background: _matchAccent(match).withValues(alpha: 0.14),
          foreground: _matchAccent(match),
        ),
      ],
    );
  }
}

final class _SectionLoadingCard extends StatelessWidget {
  const _SectionLoadingCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return WorkspaceSurfaceCard(
      accent: AppPalette.sky,
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
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
            match.teamOneDetail.toLowerCase().contains(query) ||
            match.teamTwoDetail.toLowerCase().contains(query) ||
            (match.assignedCourtCode?.toLowerCase().contains(query) ?? false),
      )
      .toList(growable: false);
}

List<CategoryStandings> _filterStandings(
  List<CategoryStandings> categories,
  String query,
) {
  if (query.isEmpty) {
    return categories;
  }
  return categories
      .where(
        (category) =>
            category.categoryName.toLowerCase().contains(query) ||
            category.qualificationSummary.toLowerCase().contains(query),
      )
      .toList(growable: false);
}

int _compareActiveMatches(TournamentMatch left, TournamentMatch right) {
  final leftRank = _matchPriority(left);
  final rightRank = _matchPriority(right);
  if (leftRank != rightRank) {
    return leftRank.compareTo(rightRank);
  }
  return left.displayOrder.compareTo(right.displayOrder);
}

int _matchPriority(TournamentMatch match) => switch (match.status) {
  TournamentMatchStatus.onCourt => 0,
  TournamentMatchStatus.called => 1,
  TournamentMatchStatus.assigned => 2,
  TournamentMatchStatus.scoreSubmitted => 3,
  _ => 4,
};

String _matchStatusLabel(TournamentMatch match) => switch (match.status) {
  TournamentMatchStatus.onCourt => 'Live now',
  TournamentMatchStatus.called => 'Starting soon',
  TournamentMatchStatus.assigned => 'Assigned',
  TournamentMatchStatus.scoreSubmitted => 'Awaiting approval',
  _ => match.status.label,
};

IconData _matchStatusIcon(TournamentMatch match) => switch (match.status) {
  TournamentMatchStatus.onCourt => Icons.play_circle_fill_rounded,
  TournamentMatchStatus.called => Icons.campaign_rounded,
  TournamentMatchStatus.assigned => Icons.schedule_rounded,
  TournamentMatchStatus.scoreSubmitted => Icons.verified_outlined,
  _ => Icons.sports_tennis,
};

Color _matchAccent(TournamentMatch match) => switch (match.status) {
  TournamentMatchStatus.onCourt => AppPalette.sageStrong,
  TournamentMatchStatus.called => AppPalette.apricot,
  TournamentMatchStatus.assigned => AppPalette.sky,
  TournamentMatchStatus.scoreSubmitted => AppPalette.oliveStrong,
  _ => AppPalette.inkSoft,
};

int _courtPriority(TournamentMatch? match, TournamentCourt court) {
  if (match != null) {
    return _matchPriority(match);
  }
  return court.isAvailable ? 4 : 5;
}

Color _courtAccent(TournamentMatch? match, TournamentCourt court) {
  if (match != null) {
    return _matchAccent(match);
  }
  return court.isAvailable ? AppPalette.sky : AppPalette.lineStrong;
}

String _courtStatusLabel(TournamentMatch? match, TournamentCourt court) {
  if (match != null) {
    return _matchStatusLabel(match);
  }
  return court.isAvailable ? 'Open' : court.status.label;
}

Color _courtTagBackground(TournamentMatch? match, TournamentCourt court) {
  if (match != null) {
    return _matchAccent(match).withValues(alpha: 0.16);
  }
  return court.isAvailable ? AppPalette.skySoft : AppPalette.surfaceSoft;
}

Color _courtTagForeground(TournamentMatch? match, TournamentCourt court) {
  if (match != null) {
    return _matchAccent(match);
  }
  return court.isAvailable ? const Color(0xFF456F77) : AppPalette.inkSoft;
}

String _winnerPublicLabel(TournamentMatch match) {
  if (match.winnerEntryId != null &&
      match.winnerEntryId == match.teamOneEntryId) {
    return _publicTeamLabel(match.teamOneLabel, match.teamOneDetail);
  }
  if (match.winnerEntryId != null &&
      match.winnerEntryId == match.teamTwoEntryId) {
    return _publicTeamLabel(match.teamTwoLabel, match.teamTwoDetail);
  }
  if (match.winnerLabel?.trim().isNotEmpty ?? false) {
    return _publicTeamLabel(match.winnerLabel!.trim(), '');
  }
  return 'Winner decided';
}

String _publicTeamLabel(String primaryLabel, String detailLabel) {
  final normalizedPrimary = primaryLabel.trim();
  final normalizedDetail = detailLabel.trim();
  final rosterSource = normalizedDetail.contains('·')
      ? normalizedDetail.split('·').last.trim()
      : normalizedDetail;
  final participants = rosterSource
      .split('/')
      .map((part) => _shortPersonName(part))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (participants.isNotEmpty) {
    return participants.join(' / ');
  }
  return _shortPersonName(normalizedPrimary);
}

String _shortPersonName(String value) {
  final cleaned = value.trim();
  if (cleaned.isEmpty) {
    return '';
  }
  final words = cleaned
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    return '';
  }
  if (words.length == 1) {
    return words.first;
  }
  final first = words.first;
  final lastInitial = words.last.substring(0, 1).toUpperCase();
  return '$first $lastInitial.';
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
