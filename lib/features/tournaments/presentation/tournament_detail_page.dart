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

  @override
  void didUpdateWidget(covariant TournamentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId != widget.tournamentId) {
      _selectedTab = _TournamentWorkspaceTab.setup;
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
                onSelectTab: (tab) {
                  setState(() {
                    _selectedTab = tab;
                  });
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
    required this.onSelectTab,
  });

  final Tournament tournament;
  final _TournamentWorkspaceTab selectedTab;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1240;

        return Column(
          children: [
            _TournamentHero(tournament: tournament, selectedTab: selectedTab),
            const SizedBox(height: AppSpace.lg),
            if (isCompact) ...[
              _CompactWorkspaceTabs(
                tournament: tournament,
                selectedTab: selectedTab,
                onSelectTab: onSelectTab,
                tabs: _allTabs,
              ),
              const SizedBox(height: AppSpace.lg),
              Expanded(
                child: _WorkspaceContent(
                  tab: selectedTab,
                  tournament: tournament,
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
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

final class _TournamentHero extends StatelessWidget {
  const _TournamentHero({required this.tournament, required this.selectedTab});

  final Tournament tournament;
  final _TournamentWorkspaceTab selectedTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppPalette.surface, Color(0xFFF7F3EB)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F1412),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
              ),
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
          const SizedBox(height: AppSpace.lg),
          Text(tournament.name, style: theme.textTheme.displayMedium),
          const SizedBox(height: AppSpace.sm),
          Text(
            '${tournament.venue} · ${_formatDate(tournament.startDate)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              selectedTab.subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _HeaderChip(
                label: '${tournament.stats.categories} categories',
                tint: AppPalette.skySoft,
                border: AppPalette.sky.withValues(alpha: 0.45),
                foreground: const Color(0xFF456F77),
              ),
              _HeaderChip(
                label: '${tournament.stats.entries} entries',
                tint: AppPalette.oliveSoft,
                border: AppPalette.oliveStrong.withValues(alpha: 0.45),
                foreground: const Color(0xFF5F7243),
              ),
              _HeaderChip(
                label: '${tournament.stats.matches} matches',
                tint: AppPalette.apricotSoft,
                border: AppPalette.apricot.withValues(alpha: 0.45),
                foreground: const Color(0xFF8F6038),
              ),
              _HeaderChip(
                label: '${tournament.activeCourtCount} active courts',
                tint: AppPalette.sageSoft,
                border: AppPalette.sage.withValues(alpha: 0.45),
                foreground: const Color(0xFF365141),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _CompactWorkspaceTabs extends StatelessWidget {
  const _CompactWorkspaceTabs({
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
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          for (final tab in tabs)
            _WorkspacePill(
              tab: tab,
              tournament: tournament,
              isSelected: selectedTab == tab,
              onTap: () => onSelectTab(tab),
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
    final tint = isSelected
        ? tab.accent.withValues(alpha: 0.16)
        : AppPalette.surfaceSoft;
    final border = isSelected
        ? tab.accent.withValues(alpha: 0.4)
        : AppPalette.line;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(22),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tab.metric(tournament),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
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
  const _WorkspaceContent({required this.tab, required this.tournament});

  final _TournamentWorkspaceTab tab;
  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: SingleChildScrollView(
        key: ValueKey(tab),
        child: Column(
          children: [
            _WorkspaceSectionBanner(tab: tab),
            const SizedBox(height: AppSpace.lg),
            _WorkspaceSection(tab: tab, tournament: tournament),
          ],
        ),
      ),
    );
  }
}

final class _WorkspaceSectionBanner extends StatelessWidget {
  const _WorkspaceSectionBanner({required this.tab});

  final _TournamentWorkspaceTab tab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: tab.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: tab.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tab.accent.withValues(alpha: 0.24)),
            ),
            child: Icon(tab.icon, color: AppPalette.ink),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tab.label, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpace.xs),
                Text(
                  tab.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
