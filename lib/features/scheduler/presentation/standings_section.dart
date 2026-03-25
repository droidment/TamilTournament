import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/team_identity.dart';
import '../../../theme/app_theme.dart';
import '../../tournaments/presentation/workspace_components.dart';
import '../data/tournament_match_providers.dart';
import '../data/tournament_standings_providers.dart';
import '../domain/category_schedule.dart';
import '../domain/tournament_match.dart';
import '../domain/tournament_standings.dart';

final class StandingsSection extends ConsumerStatefulWidget {
  const StandingsSection({
    super.key,
    required this.tournamentId,
    this.embedded = false,
    this.readOnly = false,
  });

  final String tournamentId;
  final bool embedded;
  final bool readOnly;

  @override
  ConsumerState<StandingsSection> createState() => _StandingsSectionState();
}

class _StandingsSectionState extends ConsumerState<StandingsSection> {
  String? _selectedCategoryId;
  final Set<String> _busyCategoryIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final standings = ref.watch(
      tournamentStandingsProvider(widget.tournamentId),
    );
    final matches = ref.watch(tournamentMatchesProvider(widget.tournamentId));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkspaceSectionLead(
          title: 'Standings',
          description:
              'Track live tables, qualification lines, and pool progress from completed matches.',
          icon: Icons.leaderboard_rounded,
          accent: AppPalette.sky,
        ),
        const SizedBox(height: AppSpace.lg),
        if (standings.hasValue)
          WorkspaceStatRail(
            metrics: [
              WorkspaceMetricItemData(
                value: '${_visibleCategories(standings.requireValue).length}',
                label: 'categories',
                foreground: const Color(0xFF456F77),
                isHighlighted: true,
              ),
              WorkspaceMetricItemData(
                value:
                    '${_visibleCategories(standings.requireValue).fold<int>(0, (sum, category) => sum + category.completedPoolMatches)}',
                label: 'pool matches done',
                foreground: const Color(0xFF365141),
              ),
              WorkspaceMetricItemData(
                value:
                    '${_visibleCategories(standings.requireValue).fold<int>(0, (sum, category) => sum + category.qualifierCount)}',
                label: 'qualifier slots',
                foreground: const Color(0xFF8F6038),
              ),
            ],
          ),
        if (standings.hasValue) const SizedBox(height: AppSpace.lg),
        standings.when(
          data: (snapshot) {
            if (snapshot.isEmpty) {
              return const WorkspaceEmptyCard(
                title: 'No standings yet',
                message:
                    'Complete at least one category schedule to begin tracking live tables.',
              );
            }

            final visibleCategories = _visibleCategories(snapshot);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.categories.length > 1) ...[
                  _CategoryFilterBar(
                    selectedCategoryId: _selectedCategoryId,
                    categories: snapshot.categories
                        .map(
                          (category) => (
                            id: category.categoryId,
                            name: category.categoryName,
                          ),
                        )
                        .toList(growable: false),
                    onSelected: (categoryId) {
                      setState(() {
                        _selectedCategoryId = categoryId;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                ],
                for (
                  var index = 0;
                  index < visibleCategories.length;
                  index++
                ) ...[
                  _CategoryStandingsCard(
                    category: visibleCategories[index],
                    matches: matches.asData?.value ?? const <TournamentMatch>[],
                    isBusy:
                        widget.readOnly ||
                        _busyCategoryIds.contains(
                          visibleCategories[index].categoryId,
                        ),
                    readOnly: widget.readOnly,
                    onPrepareKnockout: () =>
                        _prepareKnockoutRound(visibleCategories[index]),
                  ),
                  if (index < visibleCategories.length - 1)
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
          error: (error, _) => WorkspaceErrorCard(
            title: 'Standings need attention',
            message: error.toString(),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: content,
    );
  }

  List<CategoryStandings> _visibleCategories(
    TournamentStandingsSnapshot snapshot,
  ) {
    final selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null) {
      return snapshot.categories;
    }
    final filtered = snapshot.categories
        .where((category) => category.categoryId == selectedCategoryId)
        .toList(growable: false);
    if (filtered.isNotEmpty) {
      return filtered;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedCategoryId = null;
      });
    });
    return snapshot.categories;
  }

  Future<void> _prepareKnockoutRound(CategoryStandings category) async {
    if (_busyCategoryIds.contains(category.categoryId)) {
      return;
    }

    setState(() {
      _busyCategoryIds.add(category.categoryId);
    });

    try {
      final count = await ref
          .read(tournamentMatchRepositoryProvider)
          .prepareNextKnockoutRound(
            tournamentId: widget.tournamentId,
            standings: category,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'No knockout placeholders are waiting for ${category.categoryName}.'
                : 'Staged $count knockout match(es) for ${category.categoryName}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyStandingsError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _busyCategoryIds.remove(category.categoryId);
        });
      }
    }
  }
}

final class _CategoryStandingsCard extends StatelessWidget {
  const _CategoryStandingsCard({
    required this.category,
    required this.matches,
    required this.readOnly,
    required this.isBusy,
    required this.onPrepareKnockout,
  });

  final CategoryStandings category;
  final List<TournamentMatch> matches;
  final bool readOnly;
  final bool isBusy;
  final VoidCallback onPrepareKnockout;

  @override
  Widget build(BuildContext context) {
    final accent = switch (category.mode) {
      GeneratedScheduleMode.roundRobinTop4 => AppPalette.sageStrong,
      GeneratedScheduleMode.groupsKnockout => AppPalette.sky,
    };
    final completedFinal = _completedFinalMatch(category, matches);
    final championEntryId = completedFinal?.winnerEntryId;
    final runnerUpEntryId = completedFinal == null
        ? null
        : completedFinal.winnerEntryId == completedFinal.teamOneEntryId
        ? completedFinal.teamTwoEntryId
        : completedFinal.teamOneEntryId;

    return WorkspaceSurfaceCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.categoryName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            category.mode.subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              WorkspaceTag(
                label: category.mode.label,
                background: accent.withValues(alpha: 0.14),
                foreground: AppPalette.ink,
              ),
              WorkspaceTag(
                label:
                    '${category.completedPoolMatches}/${category.totalPoolMatches} pool matches',
                background: AppPalette.surfaceSoft,
                foreground: const Color(0xFF365141),
              ),
              WorkspaceTag(
                label: category.qualificationSummary,
                background: AppPalette.oliveSoft,
                foreground: const Color(0xFF5F7243),
              ),
            ],
          ),
          if (completedFinal != null) ...[
            const SizedBox(height: AppSpace.md),
            _FinalResultsBanner(match: completedFinal),
          ],
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  _knockoutStatusLabel(category, matches),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
                ),
              ),
              if (!readOnly && _canPrepareKnockout(category, matches))
                FilledButton(
                  onPressed: isBusy ? null : onPrepareKnockout,
                  child: Text(
                    isBusy
                        ? 'Setting up...'
                        : _setupButtonLabel(category, matches),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.control),
            child: LinearProgressIndicator(
              value: category.completionProgress,
              minHeight: 8,
              backgroundColor: AppPalette.surfaceSoft,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          for (var index = 0; index < category.groups.length; index++) ...[
            _GroupStandingsTable(
              group: category.groups[index],
              showGroupHeading: category.groups.length > 1,
              championEntryId: championEntryId,
              runnerUpEntryId: runnerUpEntryId,
            ),
            if (index < category.groups.length - 1)
              const SizedBox(height: AppSpace.md),
          ],
        ],
      ),
    );
  }
}

bool _canPrepareKnockout(
  CategoryStandings category,
  List<TournamentMatch> matches,
) {
  if (!category.isPoolPhaseComplete || category.qualifierCount == 0) {
    return false;
  }
  return _pendingKnockoutMatches(category, matches).isNotEmpty;
}

String _setupButtonLabel(
  CategoryStandings category,
  List<TournamentMatch> matches,
) {
  final pending = _pendingKnockoutMatches(category, matches);
  if (pending.isEmpty) {
    return 'Knockout ready';
  }
  return _isFinalStage(pending.first) ? 'Set up final' : 'Set up semifinals';
}

String _knockoutStatusLabel(
  CategoryStandings category,
  List<TournamentMatch> matches,
) {
  if (!category.isPoolPhaseComplete) {
    return 'Finish all pool matches before staging the knockout round.';
  }
  final pending = _pendingKnockoutMatches(category, matches);
  if (pending.isNotEmpty) {
    return _isFinalStage(pending.first)
        ? 'Final placeholder is ready to be populated from semifinal winners.'
        : 'Semifinal placeholders are ready to be populated from this table.';
  }
  final stagedFinal = _stagedFinalMatch(category, matches);
  if (stagedFinal != null) {
    return switch (stagedFinal.status) {
      TournamentMatchStatus.ready =>
        'Final is staged and waiting in the ready queue.',
      TournamentMatchStatus.onCourt => 'Final is already on court.',
      TournamentMatchStatus.completed => 'Final is completed.',
      _ => 'Final is already staged.',
    };
  }
  return 'No pending knockout placeholders remain for this category.';
}

List<TournamentMatch> _pendingKnockoutMatches(
  CategoryStandings category,
  List<TournamentMatch> matches,
) {
  return matches
      .where(
        (match) =>
            match.categoryId == category.categoryId &&
            match.phase == 'knockout' &&
            match.isPending,
      )
      .toList(growable: false);
}

TournamentMatch? _stagedFinalMatch(
  CategoryStandings category,
  List<TournamentMatch> matches,
) {
  for (final match in matches) {
    if (match.categoryId != category.categoryId || match.phase != 'knockout') {
      continue;
    }
    if (_isFinalStage(match) && !match.isPending) {
      return match;
    }
  }
  return null;
}

TournamentMatch? _completedFinalMatch(
  CategoryStandings category,
  List<TournamentMatch> matches,
) {
  for (final match in matches) {
    if (match.categoryId != category.categoryId || match.phase != 'knockout') {
      continue;
    }
    if (_isFinalStage(match) && match.isCompleted) {
      return match;
    }
  }
  return null;
}

bool _isFinalStage(TournamentMatch match) {
  final normalizedCode = match.matchCode.toLowerCase();
  final normalizedStage = match.stageLabel.toLowerCase();
  return normalizedCode.contains('final') ||
      normalizedStage.contains('championship');
}

final class _GroupStandingsTable extends StatelessWidget {
  const _GroupStandingsTable({
    required this.group,
    required this.showGroupHeading,
    required this.championEntryId,
    required this.runnerUpEntryId,
  });

  final GroupStandings group;
  final bool showGroupHeading;
  final String? championEntryId;
  final String? runnerUpEntryId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showGroupHeading)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.md,
                AppSpace.md,
                0,
              ),
              child: Text(
                group.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 70,
              horizontalMargin: AppSpace.md,
              columnSpacing: AppSpace.md,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Team')),
                DataColumn(label: Text('W-L')),
                DataColumn(label: Text('Games')),
                DataColumn(label: Text('Points')),
                DataColumn(label: Text('Line')),
              ],
              rows: [
                for (final row in group.rows)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          '${row.rank}',
                          style: AppTheme.numeric(
                            Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      DataCell(_TeamCell(row: row)),
                      DataCell(
                        Text(
                          '${row.wins}-${row.losses}',
                          style: AppTheme.numeric(
                            Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${row.gamesWon}-${row.gamesLost}',
                          style: AppTheme.numeric(
                            Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${row.pointDifferential >= 0 ? '+' : ''}${row.pointDifferential}',
                          style: AppTheme.numeric(
                            Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                      DataCell(
                        _QualificationBadge(
                          status: row.qualifierStatus,
                          isChampion: row.entry.id == championEntryId,
                          isRunnerUp: row.entry.id == runnerUpEntryId,
                        ),
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

final class _TeamCell extends StatelessWidget {
  const _TeamCell({required this.row});

  final StandingRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamIdentityAvatar(entry: row.entry, size: 34, radius: 12),
        const SizedBox(width: AppSpace.sm),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.entry.displayLabel),
            Text(
              row.entry.rosterLabel,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
            ),
          ],
        ),
      ],
    );
  }
}

final class _QualificationBadge extends StatelessWidget {
  const _QualificationBadge({
    required this.status,
    required this.isChampion,
    required this.isRunnerUp,
  });

  final StandingsQualifierStatus status;
  final bool isChampion;
  final bool isRunnerUp;

  @override
  Widget build(BuildContext context) {
    if (isChampion) {
      return const WorkspaceTag(
        label: 'Champion',
        background: AppPalette.oliveSoft,
        foreground: Color(0xFF5F7243),
      );
    }
    if (isRunnerUp) {
      return const WorkspaceTag(
        label: 'Runner-up',
        background: AppPalette.apricotSoft,
        foreground: Color(0xFF8F6038),
      );
    }
    return switch (status) {
      StandingsQualifierStatus.winner => const WorkspaceTag(
        label: 'Winner',
        background: AppPalette.sageSoft,
        foreground: Color(0xFF365141),
      ),
      StandingsQualifierStatus.qualifying => const WorkspaceTag(
        label: 'In line',
        background: AppPalette.skySoft,
        foreground: Color(0xFF456F77),
      ),
      StandingsQualifierStatus.outside => const WorkspaceTag(
        label: 'Outside',
        background: AppPalette.surface,
        foreground: AppPalette.inkSoft,
      ),
    };
  }
}

final class _FinalResultsBanner extends StatelessWidget {
  const _FinalResultsBanner({required this.match});

  final TournamentMatch match;

  @override
  Widget build(BuildContext context) {
    final championLabel = match.winnerLabel?.trim().isNotEmpty == true
        ? match.winnerLabel!
        : 'Champion decided';
    final runnerUpLabel = match.winnerEntryId == match.teamOneEntryId
        ? match.teamTwoLabel
        : match.teamOneLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.oliveSoft, AppPalette.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(
          color: AppPalette.oliveStrong.withValues(alpha: 0.28),
        ),
      ),
      child: Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const WorkspaceTag(
            label: 'Final complete',
            background: AppPalette.surface,
            foreground: Color(0xFF5F7243),
          ),
          Text(
            'Champion: $championLabel',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'Runner-up: $runnerUpLabel',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
          ),
          if (match.hasScores)
            Text(
              match.scoreSummary,
              style: AppTheme.numeric(
                Theme.of(context).textTheme.bodySmall,
              ).copyWith(color: AppPalette.inkSoft),
            ),
        ],
      ),
    );
  }
}

final class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedCategoryId,
    required this.categories,
    required this.onSelected,
  });

  final String? selectedCategoryId;
  final List<({String id, String name})> categories;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CategoryFilterChip(
            label: 'All categories',
            selected: selectedCategoryId == null,
            onTap: () => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: AppSpace.xs),
            _CategoryFilterChip(
              label: category.name,
              selected: selectedCategoryId == category.id,
              onTap: () => onSelected(category.id),
            ),
          ],
        ],
      ),
    );
  }
}

final class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppPalette.skySoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppPalette.sky.withValues(alpha: 0.4)
                : AppPalette.line,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? AppPalette.ink : AppPalette.inkSoft,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

String _friendlyStandingsError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'This organizer account cannot stage knockout matches yet. Reload and try again.';
  }
  if (message.contains('Finish all pool matches')) {
    return 'Finish every pool match first, then set up the semifinals.';
  }
  return message;
}
