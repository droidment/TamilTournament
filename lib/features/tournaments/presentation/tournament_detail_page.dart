import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../entries/presentation/entries_section.dart';
import '../../scheduler/presentation/category_schedule_section.dart';
import '../../scheduler/presentation/court_management_section.dart';
import '../../scheduler/presentation/scheduling_seed_section.dart';
import '../../scheduler/presentation/standings_section.dart';
import '../data/tournament_providers.dart';
import '../domain/tournament.dart';
import 'categories_section.dart';
import 'organizers_section.dart';
import 'tournament_start_panel.dart';
import 'workspace_components.dart';

enum _TournamentWorkspaceTab {
  setup,
  teams,
  seeding,
  schedule,
  standings,
  courts,
}

extension on _TournamentWorkspaceTab {
  String get label => switch (this) {
    _TournamentWorkspaceTab.setup => 'Setup',
    _TournamentWorkspaceTab.teams => 'Teams',
    _TournamentWorkspaceTab.seeding => 'Seeding',
    _TournamentWorkspaceTab.schedule => 'Schedule',
    _TournamentWorkspaceTab.standings => 'Standings',
    _TournamentWorkspaceTab.courts => 'Courts',
  };

  String get headingLabel => switch (this) {
    _TournamentWorkspaceTab.setup => 'Setup',
    _TournamentWorkspaceTab.teams => 'Team desk',
    _TournamentWorkspaceTab.seeding => 'Seeding board',
    _TournamentWorkspaceTab.schedule => 'Match flow',
    _TournamentWorkspaceTab.standings => 'Standings',
    _TournamentWorkspaceTab.courts => 'Court desk',
  };

  IconData get icon => switch (this) {
    _TournamentWorkspaceTab.setup => Icons.category_rounded,
    _TournamentWorkspaceTab.teams => Icons.groups_rounded,
    _TournamentWorkspaceTab.seeding => Icons.format_list_numbered_rounded,
    _TournamentWorkspaceTab.schedule => Icons.calendar_view_week_rounded,
    _TournamentWorkspaceTab.standings => Icons.leaderboard_rounded,
    _TournamentWorkspaceTab.courts => Icons.sports_tennis_rounded,
  };

  Color get accent => switch (this) {
    _TournamentWorkspaceTab.setup => AppPalette.sky,
    _TournamentWorkspaceTab.teams => AppPalette.oliveStrong,
    _TournamentWorkspaceTab.seeding => AppPalette.apricot,
    _TournamentWorkspaceTab.schedule => AppPalette.sageStrong,
    _TournamentWorkspaceTab.standings => AppPalette.sky,
    _TournamentWorkspaceTab.courts => const Color(0xFF618374),
  };

  Color get surface => switch (this) {
    _TournamentWorkspaceTab.setup => AppPalette.skySoft,
    _TournamentWorkspaceTab.teams => const Color(0xFFE8F2E8),
    _TournamentWorkspaceTab.seeding => AppPalette.apricotSoft,
    _TournamentWorkspaceTab.schedule => AppPalette.sageSoft,
    _TournamentWorkspaceTab.standings => AppPalette.skySoft,
    _TournamentWorkspaceTab.courts => const Color(0xFFE7F0EA),
  };

  Color get surfaceAlt => switch (this) {
    _TournamentWorkspaceTab.setup => const Color(0xFFF2F8F5),
    _TournamentWorkspaceTab.teams => const Color(0xFFF3F7EF),
    _TournamentWorkspaceTab.seeding => const Color(0xFFF8F1E4),
    _TournamentWorkspaceTab.schedule => const Color(0xFFEFF7F2),
    _TournamentWorkspaceTab.standings => const Color(0xFFEFF7FA),
    _TournamentWorkspaceTab.courts => const Color(0xFFF2F7F4),
  };

  Color get darkSurface => switch (this) {
    _TournamentWorkspaceTab.setup => AppPalette.ink,
    _TournamentWorkspaceTab.teams => const Color(0xFF45533D),
    _TournamentWorkspaceTab.seeding => const Color(0xFF6E5841),
    _TournamentWorkspaceTab.schedule => const Color(0xFF365447),
    _TournamentWorkspaceTab.standings => const Color(0xFF355A62),
    _TournamentWorkspaceTab.courts => const Color(0xFF314A3D),
  };

  Color get darkSurfaceAlt => switch (this) {
    _TournamentWorkspaceTab.setup => const Color(0xFF273731),
    _TournamentWorkspaceTab.teams => const Color(0xFF5B6B51),
    _TournamentWorkspaceTab.seeding => const Color(0xFF8B6F52),
    _TournamentWorkspaceTab.schedule => const Color(0xFF47685A),
    _TournamentWorkspaceTab.standings => const Color(0xFF4D7380),
    _TournamentWorkspaceTab.courts => const Color(0xFF456053),
  };

  String get bannerTitle => switch (this) {
    _TournamentWorkspaceTab.setup => 'Setup',
    _TournamentWorkspaceTab.teams => 'Team desk',
    _TournamentWorkspaceTab.seeding => 'Seeding board',
    _TournamentWorkspaceTab.schedule => 'Match flow',
    _TournamentWorkspaceTab.standings => 'Standings',
    _TournamentWorkspaceTab.courts => 'Court desk',
  };

  String get bannerDescription => switch (this) {
    _TournamentWorkspaceTab.setup =>
      'Configure categories and tournament rules.',
    _TournamentWorkspaceTab.teams =>
      'Onboard pairs, verify arrivals, and tidy the roster.',
    _TournamentWorkspaceTab.seeding =>
      'Assign order and prepare the draw before play starts.',
    _TournamentWorkspaceTab.schedule =>
      'Stage matches, monitor queues, and keep rounds moving.',
    _TournamentWorkspaceTab.standings =>
      'Track table movement, qualification lines, and progression pressure.',
    _TournamentWorkspaceTab.courts =>
      'Track active courts, open slots, and readiness on the floor.',
  };
}

final class TournamentDetailPage extends ConsumerStatefulWidget {
  const TournamentDetailPage({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  ConsumerState<TournamentDetailPage> createState() =>
      _TournamentDetailPageState();
}

final class _TournamentDetailPageState
    extends ConsumerState<TournamentDetailPage> {
  _TournamentWorkspaceTab _selectedTab = _TournamentWorkspaceTab.setup;
  late final ScrollController _workspaceScrollController;

  @override
  void initState() {
    super.initState();
    _workspaceScrollController = ScrollController();
  }

  @override
  void dispose() {
    _workspaceScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TournamentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId != widget.tournamentId) {
      _selectedTab = _TournamentWorkspaceTab.setup;
      if (_workspaceScrollController.hasClients) {
        _workspaceScrollController.jumpTo(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final pagePadding = constraints.maxWidth < 900
                ? AppSpace.md
                : AppSpace.lg;

            return Padding(
              padding: EdgeInsets.all(pagePadding),
              child: tournament.when(
                data: (value) {
                  if (value == null) {
                    return const _TournamentDetailState(
                      title: 'Tournament not available',
                      message:
                          'This tournament was not found or you do not have access to it.',
                    );
                  }
                  return _TournamentDetailBody(
                    tournament: value,
                    selectedTab: _selectedTab,
                    scrollController: _workspaceScrollController,
                    onSelectTab: (tab) async {
                      setState(() {
                        _selectedTab = tab;
                      });
                      if (_workspaceScrollController.hasClients &&
                          _workspaceScrollController.offset > 0) {
                        await _workspaceScrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const _TournamentDetailState(
                  title: 'Tournament detail',
                  message:
                      'We could not load this tournament right now. Please try again.',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _TournamentDetailBody extends StatelessWidget {
  const _TournamentDetailBody({
    required this.tournament,
    required this.selectedTab,
    required this.scrollController,
    required this.onSelectTab,
  });

  final Tournament tournament;
  final _TournamentWorkspaceTab selectedTab;
  final ScrollController scrollController;
  final ValueChanged<_TournamentWorkspaceTab> onSelectTab;

  static const _allTabs = <_TournamentWorkspaceTab>[
    _TournamentWorkspaceTab.setup,
    _TournamentWorkspaceTab.teams,
    _TournamentWorkspaceTab.seeding,
    _TournamentWorkspaceTab.schedule,
    _TournamentWorkspaceTab.standings,
    _TournamentWorkspaceTab.courts,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final collapseProgress = scrollController.hasClients
            ? (scrollController.offset / 92).clamp(0.0, 1.0)
            : 0.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;
            final showsTournamentHero =
                selectedTab == _TournamentWorkspaceTab.setup;

            return Column(
              children: [
                _WorkspaceToolbar(
                  tournament: tournament,
                  selectedTab: selectedTab,
                  collapseProgress: collapseProgress,
                ),
                if (isCompact && showsTournamentHero) ...[
                  const SizedBox(height: AppSpace.sm),
                  _SetupCompactHero(tournament: tournament),
                  const SizedBox(height: AppSpace.sm),
                ] else if (!isCompact && showsTournamentHero) ...[
                  ClipRect(
                    child: Align(
                      heightFactor: 1 - collapseProgress,
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: 1 - collapseProgress,
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpace.md),
                          child: _SetupHeroCard(tournament: tournament),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: _spaceBetween(18, 10, collapseProgress)),
                ] else ...[
                  const SizedBox(height: AppSpace.sm),
                ],
                if (isCompact) ...[
                  Expanded(
                    child: _WorkspaceContent(
                      tab: selectedTab,
                      tournament: tournament,
                      scrollController: scrollController,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: _BottomWorkspaceNavigation(
                        selectedTab: selectedTab,
                        onSelectTab: onSelectTab,
                        tabs: _allTabs,
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 240,
                          child: _WorkspaceSidebar(
                            tournament: tournament,
                            selectedTab: selectedTab,
                            onSelectTab: onSelectTab,
                            tabs: _allTabs,
                          ),
                        ),
                        const SizedBox(width: AppSpace.lg),
                        Expanded(
                          child: _WorkspaceContent(
                            tab: selectedTab,
                            tournament: tournament,
                            scrollController: scrollController,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ignore: unused_element
final class _WorkspaceTabBanner extends StatelessWidget {
  const _WorkspaceTabBanner({required this.tab, required this.tournament});

  final _TournamentWorkspaceTab tab;
  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final statLabel = switch (tab) {
          _TournamentWorkspaceTab.teams => '${tournament.stats.entries} teams',
          _TournamentWorkspaceTab.seeding =>
            '${tournament.stats.entries} entries to order',
          _TournamentWorkspaceTab.schedule =>
            '${tournament.stats.matches} matches tracked',
          _TournamentWorkspaceTab.standings =>
            '${tournament.stats.categories} tables in view',
          _TournamentWorkspaceTab.courts =>
            '${tournament.activeCourtCount} courts active',
          _TournamentWorkspaceTab.setup =>
            '${tournament.stats.categories} categories',
        };

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? AppSpace.md : AppSpace.lg,
            vertical: isCompact ? AppSpace.md : AppSpace.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [tab.surface, tab.surfaceAlt],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tab.accent.withValues(alpha: 0.24)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: isCompact ? -10 : 8,
                top: isCompact ? -8 : 2,
                child: Icon(
                  tab.icon,
                  size: isCompact ? 48 : 64,
                  color: tab.accent.withValues(alpha: 0.12),
                ),
              ),
              if (!isCompact)
                Positioned(
                  right: -18,
                  bottom: -24,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tab.accent.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: isCompact ? 56 : 64,
                    decoration: BoxDecoration(
                      color: tab.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tab.bannerTitle,
                          style: isCompact
                              ? theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )
                              : theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isCompact ? 320 : 520,
                          ),
                          child: Text(
                            tab.bannerDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.inkSoft,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        _HeroInfoChip(
                          icon: tab.icon,
                          label: statLabel,
                          tint: tab.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _WorkspaceToolbar extends StatelessWidget {
  const _WorkspaceToolbar({
    required this.tournament,
    required this.selectedTab,
    required this.collapseProgress,
  });

  final Tournament tournament;
  final _TournamentWorkspaceTab selectedTab;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final usesDarkHeader = selectedTab != _TournamentWorkspaceTab.setup;

        if (usesDarkHeader) {
          final foreground = Colors.white.withValues(alpha: 0.96);
          final secondary = Colors.white.withValues(alpha: 0.76);
          final darkStyle = theme.textTheme.headlineMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: _spaceBetween(22, 18, collapseProgress),
          );
          final darkSubStyle = theme.textTheme.titleMedium?.copyWith(
            color: secondary,
            fontSize: _spaceBetween(isCompact ? 15 : 16, 14, collapseProgress),
          );

          return Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isCompact ? AppSpace.sm : AppSpace.md,
              isCompact ? AppSpace.sm : AppSpace.md,
              isCompact ? AppSpace.md : AppSpace.lg,
              isCompact ? AppSpace.md : AppSpace.lg,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [selectedTab.darkSurface, selectedTab.darkSurfaceAlt],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0C1511),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: isCompact ? -4 : 8,
                  top: isCompact ? -2 : 0,
                  child: Icon(
                    selectedTab.icon,
                    size: isCompact ? 56 : 72,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                Positioned(
                  right: isCompact ? 20 : 38,
                  bottom: isCompact ? -20 : -26,
                  child: Container(
                    width: isCompact ? 74 : 96,
                    height: isCompact ? 74 : 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedTab.accent.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/'),
                      style: TextButton.styleFrom(
                        foregroundColor: foreground,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: isCompact ? 54 : 64,
                          decoration: BoxDecoration(
                            color: selectedTab.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tournament.name, style: darkStyle),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                '${tournament.status.label} / ${selectedTab.headingLabel}',
                                style: darkSubStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F2ED), Color(0xFFF7ECDD)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppPalette.lineStrong),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120D1813),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -14,
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.sky.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Positioned(
                left: 120,
                bottom: -34,
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppPalette.apricotSoft.withValues(alpha: 0.24),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? AppSpace.sm : AppSpace.md,
                  isCompact ? AppSpace.sm : AppSpace.md,
                  isCompact ? AppSpace.md : AppSpace.lg,
                  isCompact ? AppSpace.md : AppSpace.lg,
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: () => context.go('/'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppPalette.ink,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.58,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            tournament.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: _spaceBetween(22, 18, collapseProgress),
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.sm,
                            children: [
                              _HeroInfoChip(
                                icon: Icons.flag_outlined,
                                label: tournament.status.label,
                                tint: AppPalette.sage,
                              ),
                              _HeroInfoChip(
                                icon: selectedTab.icon,
                                label: selectedTab.headingLabel,
                                tint: AppPalette.apricotSoft,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => context.go('/'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppPalette.ink,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.58,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Text(
                              tournament.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: _spaceBetween(
                                  22,
                                  18,
                                  collapseProgress,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          _HeroInfoChip(
                            icon: Icons.flag_outlined,
                            label: tournament.status.label,
                            tint: AppPalette.sage,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          _HeroInfoChip(
                            icon: selectedTab.icon,
                            label: selectedTab.headingLabel,
                            tint: AppPalette.apricotSoft,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ignore: unused_element
final class _CompactTournamentSummary extends StatelessWidget {
  const _CompactTournamentSummary({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppPalette.sage,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppPalette.sageStrong,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              '${tournament.venue} · ${_formatDate(tournament.startDate)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
final class _TournamentHeroCard extends StatelessWidget {
  const _TournamentHeroCard({
    required this.tournament,
    required this.selectedTab,
  });

  final Tournament tournament;
  final _TournamentWorkspaceTab selectedTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.surfaceSoft, Color(0xFFF3F7EC)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final meta =
              '${tournament.venue} · ${_formatDate(tournament.startDate)}';
          final titleStyle = theme.textTheme.displayLarge?.copyWith(
            fontSize: constraints.maxWidth < 700 ? 34 : 50,
            fontWeight: FontWeight.w700,
            height: 1.02,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tournament.status.label.toUpperCase()} TOURNAMENT',
                style: AppTheme.numeric(theme.textTheme.labelLarge).copyWith(
                  color: AppPalette.inkSoft,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(tournament.name, style: titleStyle),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppPalette.sage,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppPalette.sageStrong,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        meta,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    selectedTab.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppPalette.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _SetupCompactHero extends StatelessWidget {
  const _SetupCompactHero({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = '${tournament.venue} - ${_formatDate(tournament.startDate)}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F4EF), Color(0xFFF7F3E7)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.lineStrong),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.skySoft.withValues(alpha: 0.75),
              ),
            ),
          ),
          Positioned(
            bottom: -18,
            right: 24,
            child: Transform.rotate(
              angle: -0.25,
              child: Icon(
                Icons.sports_tennis_rounded,
                size: 42,
                color: AppPalette.sageStrong.withValues(alpha: 0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup overview',
                  style: AppTheme.numeric(theme.textTheme.labelLarge).copyWith(
                    color: AppPalette.inkSoft,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  tournament.name,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppPalette.sage,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppPalette.sageStrong,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        meta,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    _HeroInfoChip(
                      icon: Icons.category_rounded,
                      label: '${tournament.stats.categories} categories',
                    ),
                    _HeroInfoChip(
                      icon: Icons.groups_rounded,
                      label: '${tournament.stats.entries} teams',
                    ),
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

final class _SetupHeroCard extends StatelessWidget {
  const _SetupHeroCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD7F0EA), Color(0xFFEAF5E1), Color(0xFFF7E3CC)],
          stops: [0.0, 0.46, 1.0],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(color: const Color(0xFFCBDBD2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x170A1511),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -54,
            right: -24,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.skySoft.withValues(alpha: 0.72),
              ),
            ),
          ),
          Positioned(
            bottom: -72,
            left: 140,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPalette.oliveSoft.withValues(alpha: 0.55),
              ),
            ),
          ),
          Positioned(
            right: 42,
            top: 28,
            child: Transform.rotate(
              angle: -0.24,
              child: Icon(
                Icons.sports_tennis_rounded,
                size: 84,
                color: AppPalette.sageStrong.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final meta =
                    '${tournament.venue} - ${_formatDate(tournament.startDate)}';
                final isNarrow = constraints.maxWidth < 900;
                final titleStyle = theme.textTheme.displayLarge?.copyWith(
                  fontSize: constraints.maxWidth < 1080 ? 38 : 50,
                  fontWeight: FontWeight.w700,
                  height: 1.02,
                );

                final overviewPanel = Container(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.78),
                        AppPalette.surfaceSoft.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120E1713),
                        blurRadius: 22,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tournament snapshot',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        'Everything you need to prepare the categories, teams, seeding, and court flow.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkSoft,
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        children: [
                          _HeroMetricTile(
                            label: 'Categories',
                            value: '${tournament.stats.categories}',
                            accent: AppPalette.sky,
                          ),
                          _HeroMetricTile(
                            label: 'Teams',
                            value: '${tournament.stats.entries}',
                            accent: AppPalette.sage,
                          ),
                          _HeroMetricTile(
                            label: 'Matches',
                            value: '${tournament.stats.matches}',
                            accent: AppPalette.apricotSoft,
                          ),
                          _HeroMetricTile(
                            label: 'Courts',
                            value: '${tournament.activeCourtCount}',
                            accent: AppPalette.oliveSoft,
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final intro = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOURNAMENT CONTROL',
                      style: AppTheme.numeric(theme.textTheme.labelLarge)
                          .copyWith(
                            color: AppPalette.inkSoft,
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 7,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF63A9A6), Color(0xFF9A8A58)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(tournament.name, style: titleStyle),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        'Build the draw, confirm arrivals, seed divisions, and keep the day moving without spreadsheet handoffs.',
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
                        _HeroInfoChip(
                          icon: Icons.location_on_outlined,
                          label: meta,
                          tint: AppPalette.sky,
                        ),
                        _HeroInfoChip(
                          icon: Icons.flag_outlined,
                          label: tournament.status.label,
                          tint: AppPalette.apricotSoft,
                        ),
                      ],
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      intro,
                      const SizedBox(height: AppSpace.lg),
                      overviewPanel,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: intro),
                    const SizedBox(width: AppSpace.xl),
                    Expanded(flex: 4, child: overviewPanel),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({required this.icon, required this.label, this.tint});

  final IconData icon;
  final String label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final chipTint = tint ?? AppPalette.sky;
    final chipForeground = Color.lerp(AppPalette.ink, chipTint, 0.28)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            chipTint.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipTint.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: chipForeground),
          const SizedBox(width: AppSpace.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: chipForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

final class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 132,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            value,
            style: AppTheme.numeric(
              theme.textTheme.headlineMedium,
            ).copyWith(color: AppPalette.ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

final class _BottomWorkspaceNavigation extends StatelessWidget {
  const _BottomWorkspaceNavigation({
    required this.selectedTab,
    required this.onSelectTab,
    required this.tabs,
  });

  final _TournamentWorkspaceTab selectedTab;
  final ValueChanged<_TournamentWorkspaceTab> onSelectTab;
  final List<_TournamentWorkspaceTab> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs) ...[
              _BottomNavItem(
                tab: tab,
                isSelected: tab == selectedTab,
                onTap: () => onSelectTab(tab),
              ),
              if (tab != tabs.last) const SizedBox(width: AppSpace.xs),
            ],
          ],
        ),
      ),
    );
  }
}

final class _WorkspaceSidebar extends StatelessWidget {
  const _WorkspaceSidebar({
    required this.tournament,
    required this.selectedTab,
    required this.onSelectTab,
    required this.tabs,
  });

  final Tournament tournament;
  final _TournamentWorkspaceTab selectedTab;
  final ValueChanged<_TournamentWorkspaceTab> onSelectTab;
  final List<_TournamentWorkspaceTab> tabs;

  @override
  Widget build(BuildContext context) {
    return WorkspaceSurfaceCard(
      accent: selectedTab.accent,
      padding: const EdgeInsets.all(AppSpace.lg),
      radius: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workspace',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppPalette.inkSoft,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          for (final tab in tabs) ...[
            _WorkspaceNavTile(
              tab: tab,
              tournament: tournament,
              isSelected: selectedTab == tab,
              onTap: () => onSelectTab(tab),
            ),
            if (tab != tabs.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

final class _WorkspaceNavTile extends StatelessWidget {
  const _WorkspaceNavTile({
    required this.tab,
    required this.tournament,
    required this.isSelected,
    required this.onTap,
  });

  final _TournamentWorkspaceTab tab;
  final Tournament tournament;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.control),
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
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tab.surface, Colors.white.withValues(alpha: 0.82)],
                  )
                : null,
            borderRadius: BorderRadius.circular(AppRadii.control),
            border: isSelected
                ? Border.all(color: tab.accent.withValues(alpha: 0.24))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: isSelected ? 34 : 28,
                height: isSelected ? 34 : 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? tab.accent.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  tab.icon,
                  size: 17,
                  color: isSelected ? tab.accent : AppPalette.inkSoft,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected ? AppPalette.ink : AppPalette.inkSoft,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 2),
                      Text(
                        _navMetric(tab, tournament),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppPalette.inkMuted,
                        ),
                      ),
                    ],
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

final class _WorkspaceContent extends StatelessWidget {
  const _WorkspaceContent({
    required this.tab,
    required this.tournament,
    required this.scrollController,
  });

  final _TournamentWorkspaceTab tab;
  final Tournament tournament;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth > 1120
            ? 1120.0
            : constraints.maxWidth;

        return SingleChildScrollView(
          key: ValueKey(tab),
          controller: scrollController,
          padding: const EdgeInsets.only(top: AppSpace.xs, bottom: AppSpace.lg),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: contentWidth,
              child: _WorkspaceSection(tab: tab, tournament: tournament),
            ),
          ),
        );
      },
    );
  }
}

final class _WorkspaceSection extends StatelessWidget {
  const _WorkspaceSection({required this.tab, required this.tournament});

  final _TournamentWorkspaceTab tab;
  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final readOnly = tournament.status == TournamentStatus.completed;
    return switch (tab) {
      _TournamentWorkspaceTab.setup => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (readOnly) ...[
            const _ReadOnlyBanner(),
            const SizedBox(height: AppSpace.xl),
          ],
          OrganizersSection(
            tournament: tournament,
            embedded: true,
            readOnly: readOnly,
          ),
          const SizedBox(height: AppSpace.xl),
          CategoriesSection(
            tournamentId: tournament.id,
            embedded: true,
            readOnly: readOnly,
          ),
        ],
      ),
      _TournamentWorkspaceTab.teams => EntriesSection(
        tournamentId: tournament.id,
        embedded: true,
        readOnly: readOnly,
      ),
      _TournamentWorkspaceTab.seeding => SchedulingSeedSection(
        tournamentId: tournament.id,
        embedded: true,
        readOnly: readOnly,
      ),
      _TournamentWorkspaceTab.schedule => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TournamentStartPanel(tournament: tournament),
          const SizedBox(height: AppSpace.xl),
          CategoryScheduleSection(tournamentId: tournament.id, embedded: true),
        ],
      ),
      _TournamentWorkspaceTab.standings => StandingsSection(
        tournamentId: tournament.id,
        embedded: true,
        readOnly: readOnly,
      ),
      _TournamentWorkspaceTab.courts => CourtManagementSection(
        tournamentId: tournament.id,
        initialCourtCount: tournament.activeCourtCount,
        embedded: true,
        readOnly: readOnly,
      ),
    };
  }
}

final class _ReadOnlyBanner extends StatelessWidget {
  const _ReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return WorkspaceSurfaceCard(
      accent: AppPalette.oliveStrong,
      child: Text(
        'Tournament is completed. The workspace is now read-only.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
      ),
    );
  }
}

final class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final _TournamentWorkspaceTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.control),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 84,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpace.sm,
          horizontal: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.sageSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: isSelected ? AppPalette.ink : AppPalette.inkMuted,
            ),
            const SizedBox(height: 6),
            Text(
              tab.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? AppPalette.ink : AppPalette.inkMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _TournamentDetailState extends StatelessWidget {
  const _TournamentDetailState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(AppSpace.xl),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(AppRadii.panel),
          border: Border.all(color: AppPalette.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpace.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

double _spaceBetween(double start, double end, double progress) {
  return start + ((end - start) * progress);
}

String _navMetric(_TournamentWorkspaceTab tab, Tournament tournament) {
  return switch (tab) {
    _TournamentWorkspaceTab.setup =>
      '${tournament.stats.categories} categories',
    _TournamentWorkspaceTab.teams => '${tournament.stats.entries} teams',
    _TournamentWorkspaceTab.seeding => '${tournament.stats.entries} entries',
    _TournamentWorkspaceTab.schedule => '${tournament.stats.matches} matches',
    _TournamentWorkspaceTab.standings =>
      '${tournament.stats.categories} tables',
    _TournamentWorkspaceTab.courts =>
      '${tournament.activeCourtCount} active courts',
  };
}
