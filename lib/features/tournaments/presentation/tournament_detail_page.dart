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

enum _TournamentWorkspaceTab { setup, teams, seeding, schedule, courts }

extension on _TournamentWorkspaceTab {
  String get label => switch (this) {
    _TournamentWorkspaceTab.setup => 'Setup',
    _TournamentWorkspaceTab.teams => 'Teams',
    _TournamentWorkspaceTab.seeding => 'Seeding',
    _TournamentWorkspaceTab.schedule => 'Schedule',
    _TournamentWorkspaceTab.courts => 'Courts',
  };

  String get subtitle => switch (this) {
    _TournamentWorkspaceTab.setup => 'Categories and formats',
    _TournamentWorkspaceTab.teams => 'Player and team onboarding',
    _TournamentWorkspaceTab.seeding => 'Seed order and check-ins',
    _TournamentWorkspaceTab.schedule => 'Groups and round plan',
    _TournamentWorkspaceTab.courts => 'Venue capacity and readiness',
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

  String metric(Tournament tournament) => switch (this) {
    _TournamentWorkspaceTab.setup =>
      '${tournament.stats.categories} categories',
    _TournamentWorkspaceTab.teams => '${tournament.stats.entries} teams',
    _TournamentWorkspaceTab.seeding => '${tournament.stats.entries} entries',
    _TournamentWorkspaceTab.schedule => '${tournament.stats.matches} matches',
    _TournamentWorkspaceTab.courts =>
      '${tournament.activeCourtCount} active courts',
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
            final isCompact = constraints.maxWidth < 1240;

            return Column(
              children: [
                _TournamentHero(
                  tournament: tournament,
                  selectedTab: selectedTab,
                  collapseProgress: collapseProgress,
                ),
                SizedBox(height: _spaceBetween(18, 10, collapseProgress)),
                if (isCompact) ...[
                  _CompactWorkspaceTabs(
                    selectedTab: selectedTab,
                    onSelectTab: onSelectTab,
                    tabs: _allTabs,
                    collapseProgress: collapseProgress,
                  ),
                  SizedBox(height: _spaceBetween(18, 10, collapseProgress)),
                  Expanded(
                    child: _WorkspaceContent(
                      tab: selectedTab,
                      tournament: tournament,
                      scrollController: scrollController,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 280,
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

final class _TournamentHero extends StatelessWidget {
  const _TournamentHero({
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
    final expandedOpacity = 1 - collapseProgress;
    final collapsedTitleOpacity = collapseProgress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metaLine =
              '${tournament.venue} · ${_formatDate(tournament.startDate)}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Opacity(
                      opacity: collapsedTitleOpacity,
                      child: Text(
                        tournament.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _HeaderChip(
                    label: tournament.status.label,
                    tint: AppPalette.skySoft,
                    border: AppPalette.sky.withValues(alpha: 0.45),
                    foreground: const Color(0xFF456F77),
                  ),
                  _HeaderChip(
                    label: selectedTab.label,
                    tint: selectedTab.accent.withValues(alpha: 0.14),
                    border: selectedTab.accent.withValues(alpha: 0.32),
                    foreground: AppPalette.ink,
                  ),
                ],
              ),
              ClipRect(
                child: Align(
                  heightFactor: expandedOpacity,
                  alignment: Alignment.topLeft,
                  child: Opacity(
                    opacity: expandedOpacity,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: _spaceBetween(8, 0, collapseProgress),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            metaLine,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppPalette.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _CompactWorkspaceTabs extends StatelessWidget {
  const _CompactWorkspaceTabs({
    required this.selectedTab,
    required this.onSelectTab,
    required this.tabs,
    required this.collapseProgress,
  });

  final _TournamentWorkspaceTab selectedTab;
  final ValueChanged<_TournamentWorkspaceTab> onSelectTab;
  final List<_TournamentWorkspaceTab> tabs;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_spaceBetween(8, 6, collapseProgress)),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < tabs.length; index++) ...[
              _WorkspacePill(
                tab: tabs[index],
                isSelected: selectedTab == tabs[index],
                onTap: () => onSelectTab(tabs[index]),
                collapseProgress: collapseProgress,
              ),
              if (index < tabs.length - 1) const SizedBox(width: AppSpace.sm),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tournament workspace', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Move between setup and live operations without swimming through one long page.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            for (final tab in tabs) ...[
              _WorkspaceNavTile(
                tab: tab,
                tournament: tournament,
                isSelected: selectedTab == tab,
                onTap: () => onSelectTab(tab),
              ),
              if (tab != tabs.last) const SizedBox(height: AppSpace.sm),
            ],
          ],
        ),
      ),
    );
  }
}

final class _WorkspacePill extends StatelessWidget {
  const _WorkspacePill({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.collapseProgress,
  });

  final _TournamentWorkspaceTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final double collapseProgress;

  @override
  Widget build(BuildContext context) {
    final tint = isSelected
        ? tab.accent.withValues(alpha: 0.16)
        : AppPalette.surfaceSoft;
    final border = isSelected
        ? tab.accent.withValues(alpha: 0.4)
        : AppPalette.line;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: _spaceBetween(10, 8, collapseProgress),
          ),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 18,
                color: isSelected ? AppPalette.ink : AppPalette.inkSoft,
              ),
              const SizedBox(width: AppSpace.sm),
              Text(tab.label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
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
    final tint = isSelected
        ? tab.accent.withValues(alpha: 0.14)
        : AppPalette.surfaceSoft;
    final border = isSelected
        ? tab.accent.withValues(alpha: 0.36)
        : AppPalette.line;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? tab.accent.withValues(alpha: 0.18)
                      : AppPalette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? tab.accent.withValues(alpha: 0.28)
                        : AppPalette.line,
                  ),
                ),
                child: Icon(
                  tab.icon,
                  size: 20,
                  color: isSelected ? AppPalette.ink : AppPalette.inkSoft,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tab.label, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      tab.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      tab.metric(tournament),
                      style: AppTheme.numeric(
                        theme.textTheme.bodySmall,
                      ).copyWith(color: AppPalette.ink),
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: SingleChildScrollView(
        key: ValueKey(tab),
        controller: scrollController,
        child: _WorkspaceSection(tab: tab, tournament: tournament),
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
      ),
      _TournamentWorkspaceTab.teams => EntriesSection(
        tournamentId: tournament.id,
      ),
      _TournamentWorkspaceTab.seeding => SchedulingSeedSection(
        tournamentId: tournament.id,
      ),
      _TournamentWorkspaceTab.schedule => CategoryScheduleSection(
        tournamentId: tournament.id,
      ),
      _TournamentWorkspaceTab.courts => CourtManagementSection(
        tournamentId: tournament.id,
        initialCourtCount: tournament.activeCourtCount,
      ),
    };
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
