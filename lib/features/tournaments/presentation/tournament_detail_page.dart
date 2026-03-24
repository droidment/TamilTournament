import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../entries/presentation/entries_section.dart';
import '../../scheduler/presentation/category_schedule_section.dart';
import '../../scheduler/presentation/court_management_section.dart';
import '../../scheduler/presentation/scheduling_seed_section.dart';
import '../data/tournament_providers.dart';
import '../domain/tournament.dart';
import 'categories_section.dart';
import 'workspace_components.dart';

enum _TournamentWorkspaceTab { setup, teams, seeding, schedule, courts }

extension on _TournamentWorkspaceTab {
  String get label => switch (this) {
    _TournamentWorkspaceTab.setup => 'Setup',
    _TournamentWorkspaceTab.teams => 'Teams',
    _TournamentWorkspaceTab.seeding => 'Seeding',
    _TournamentWorkspaceTab.schedule => 'Schedule',
    _TournamentWorkspaceTab.courts => 'Courts',
  };

  IconData get icon => switch (this) {
    _TournamentWorkspaceTab.setup => Icons.category_rounded,
    _TournamentWorkspaceTab.teams => Icons.groups_rounded,
    _TournamentWorkspaceTab.seeding => Icons.format_list_numbered_rounded,
    _TournamentWorkspaceTab.schedule => Icons.calendar_view_week_rounded,
    _TournamentWorkspaceTab.courts => Icons.sports_tennis_rounded,
  };

  Color get accent => switch (this) {
    _TournamentWorkspaceTab.setup => AppPalette.sky,
    _TournamentWorkspaceTab.teams => AppPalette.oliveStrong,
    _TournamentWorkspaceTab.seeding => AppPalette.apricot,
    _TournamentWorkspaceTab.schedule => AppPalette.sageStrong,
    _TournamentWorkspaceTab.courts => const Color(0xFF618374),
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
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
            error: (error, _) => _TournamentDetailState(
              title: 'Tournament detail',
              message: error.toString(),
            ),
          ),
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

            return Column(
              children: [
                _WorkspaceToolbar(
                  tournament: tournament,
                  selectedTab: selectedTab,
                  collapseProgress: collapseProgress,
                ),
                ClipRect(
                  child: Align(
                    heightFactor: 1 - collapseProgress,
                    alignment: Alignment.topCenter,
                    child: Opacity(
                      opacity: 1 - collapseProgress,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpace.md),
                        child: _TournamentHeroCard(
                          tournament: tournament,
                          selectedTab: selectedTab,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: _spaceBetween(18, 10, collapseProgress)),
                if (isCompact) ...[
                  Expanded(
                    child: _WorkspaceContent(
                      tab: selectedTab,
                      tournament: tournament,
                      scrollController: scrollController,
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _BottomWorkspaceNavigation(
                    selectedTab: selectedTab,
                    onSelectTab: onSelectTab,
                    tabs: _allTabs,
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

    return Container(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppPalette.line.withValues(alpha: 0.85)),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.go('/'),
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
                fontSize: _spaceBetween(22, 18, collapseProgress),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Text(
            '${tournament.status.label} / ${selectedTab.label}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppPalette.inkSoft,
              fontSize: _spaceBetween(18, 14, collapseProgress),
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.surfaceSoft, Color(0xFFF3F7EC)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final meta =
              '${tournament.venue} · ${_formatDate(tournament.startDate)}';
          final titleStyle = theme.textTheme.displayLarge?.copyWith(
            fontSize: constraints.maxWidth < 700 ? 42 : 56,
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
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppPalette.sage,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: AppPalette.sageStrong,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F1913),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: _BottomNavItem(
                tab: tab,
                isSelected: tab == selectedTab,
                onTap: () => onSelectTab(tab),
              ),
            ),
        ],
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
      padding: const EdgeInsets.all(AppSpace.lg),
      radius: 24,
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppPalette.surfaceSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? tab.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                tab.icon,
                size: 18,
                color: isSelected ? AppPalette.ink : AppPalette.inkSoft,
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
    return SingleChildScrollView(
      key: ValueKey(tab),
      controller: scrollController,
      padding: const EdgeInsets.only(top: AppSpace.sm, bottom: AppSpace.xl),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: _WorkspaceSection(tab: tab, tournament: tournament),
        ),
      ),
    );
  }
}

final class _WorkspaceSection extends StatelessWidget {
  const _WorkspaceSection({required this.tab, required this.tournament});

  final _TournamentWorkspaceTab tab;
  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _TournamentWorkspaceTab.setup => CategoriesSection(
        tournamentId: tournament.id,
        embedded: true,
      ),
      _TournamentWorkspaceTab.teams => EntriesSection(
        tournamentId: tournament.id,
        embedded: true,
      ),
      _TournamentWorkspaceTab.seeding => SchedulingSeedSection(
        tournamentId: tournament.id,
        embedded: true,
      ),
      _TournamentWorkspaceTab.schedule => CategoryScheduleSection(
        tournamentId: tournament.id,
        embedded: true,
      ),
      _TournamentWorkspaceTab.courts => CourtManagementSection(
        tournamentId: tournament.id,
        initialCourtCount: tournament.activeCourtCount,
        embedded: true,
      ),
    };
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppPalette.sage : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
    _TournamentWorkspaceTab.courts =>
      '${tournament.activeCourtCount} active courts',
  };
}
