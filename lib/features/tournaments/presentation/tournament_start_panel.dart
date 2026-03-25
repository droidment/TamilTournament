import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../scheduler/data/category_schedule_providers.dart';
import '../../scheduler/data/court_providers.dart';
import '../../scheduler/data/tournament_match_providers.dart';
import '../../scheduler/domain/category_schedule.dart';
import '../../scheduler/domain/tournament_court.dart';
import '../../scheduler/domain/tournament_match.dart';
import '../data/tournament_providers.dart';
import '../domain/tournament.dart';
import 'workspace_components.dart';

final class TournamentStartPanel extends ConsumerStatefulWidget {
  const TournamentStartPanel({required this.tournament, super.key});

  final Tournament tournament;

  @override
  ConsumerState<TournamentStartPanel> createState() =>
      _TournamentStartPanelState();
}

class _TournamentStartPanelState extends ConsumerState<TournamentStartPanel> {
  bool _isSubmitting = false;

  Future<void> _startTournament(_TournamentLaunchState launchState) async {
    if (!launchState.canStart ||
        _isSubmitting ||
        launchState.scheduleSnapshot == null ||
        launchState.courts == null) {
      return;
    }

    final hasExistingMatches = launchState.matchCount > 0;
    final isAlreadyLive = widget.tournament.status == TournamentStatus.live;
    final dialogTitle = isAlreadyLive
        ? hasExistingMatches
              ? 'Rebuild live schedule'
              : 'Generate live schedule'
        : 'Start tournament';
    final dialogBody = isAlreadyLive
        ? hasExistingMatches
              ? 'This will replace the current live match set and reassign open courts from the current seed plans.'
              : 'This will generate the live match set and assign open courts from the current seed plans.'
        : 'This will mark the tournament as live and move operations into active match flow. Courts can still be paused or restored after launch.';
    final confirmLabel = isAlreadyLive
        ? hasExistingMatches
              ? 'Rebuild schedule'
              : 'Generate schedule'
        : 'Start live play';

    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: const BorderSide(color: AppPalette.line),
        ),
        title: Text(dialogTitle),
        content: Text(
          dialogBody,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (shouldStart != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ref
          .read(tournamentMatchRepositoryProvider)
          .launchTournament(
            tournament: widget.tournament,
            scheduleSnapshot: launchState.scheduleSnapshot!,
            courts: launchState.courts!,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tournament is live. ${result.assignedCourts} court(s) filled from ${result.generatedMatches} generated matches.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _returnToSetup() async {
    if (_isSubmitting) {
      return;
    }

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: const BorderSide(color: AppPalette.line),
        ),
        title: const Text('Return tournament to setup'),
        content: Text(
          'This will remove the generated live matches and move the tournament back to setup so you can reseed or relaunch cleanly.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Return to setup'),
          ),
        ],
      ),
    );

    if (shouldReset != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(tournamentMatchRepositoryProvider)
          .resetTournamentLaunch(tournamentId: widget.tournament.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament returned to setup.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _completeTournament(_TournamentLaunchState launchState) async {
    if (_isSubmitting || !launchState.canComplete) {
      return;
    }

    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: const BorderSide(color: AppPalette.line),
        ),
        title: const Text('Wrap up tournament'),
        content: Text(
          'This will mark the tournament as completed and lock the organizer workspace into read-only mode.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete tournament'),
          ),
        ],
      ),
    );

    if (shouldComplete != true || !mounted) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(tournamentRepositoryProvider)
          .updateTournamentStatus(
            tournamentId: widget.tournament.id,
            status: TournamentStatus.completed,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tournament completed. Workspace is now read-only.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(
      categoryScheduleSnapshotProvider(widget.tournament.id),
    );
    final courts = ref.watch(tournamentCourtsProvider(widget.tournament.id));
    final matches = ref.watch(tournamentMatchesProvider(widget.tournament.id));
    final launchState = _deriveLaunchState(
      tournament: widget.tournament,
      schedule: schedule,
      courts: courts,
      matches: matches,
    );

    final accent = switch (widget.tournament.status) {
      TournamentStatus.draft => AppPalette.apricot,
      TournamentStatus.setup => AppPalette.sky,
      TournamentStatus.live => AppPalette.sageStrong,
      TournamentStatus.completed => AppPalette.oliveStrong,
    };
    final canStart =
        launchState.canStart &&
        widget.tournament.status != TournamentStatus.completed;
    final isLive = widget.tournament.status == TournamentStatus.live;
    final isCompleted = widget.tournament.status == TournamentStatus.completed;
    final theme = Theme.of(context);

    return WorkspaceSurfaceCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 720;

              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(isCompact ? AppSpace.md : AppSpace.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.94),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: isCompact ? -6 : 10,
                      top: isCompact ? -8 : -4,
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        size: isCompact ? 44 : 56,
                        color: accent.withValues(alpha: 0.12),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 2,
                      bottom: 2,
                      child: Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCompleted
                                ? 'Tournament complete'
                                : isLive
                                ? 'Tournament live'
                                : 'Tournament launch',
                            style: isCompact
                                ? theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )
                                : theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: Text(
                              isCompleted
                                  ? 'Play is finished. Use standings and results to review the final tournament outcome.'
                                  : isLive
                                  ? 'Live play is active. Keep courts available and use match flow to manage the day.'
                                  : 'Start the tournament once at least one category has playable matches and at least one court is active.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppPalette.inkSoft,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                          SizedBox(
                            width: isCompact ? double.infinity : null,
                            child: Wrap(
                              spacing: AppSpace.sm,
                              runSpacing: AppSpace.sm,
                              children: [
                                if (!isCompleted)
                                  SizedBox(
                                    width: isCompact ? double.infinity : 260,
                                    child: FilledButton.icon(
                                      onPressed: canStart && !_isSubmitting
                                          ? () => _startTournament(launchState)
                                          : null,
                                      icon: Icon(
                                        isLive
                                            ? Icons.autorenew_rounded
                                            : Icons.rocket_launch_rounded,
                                        size: 18,
                                      ),
                                      style: FilledButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpace.lg,
                                          vertical: isCompact
                                              ? AppSpace.md
                                              : AppSpace.lg,
                                        ),
                                        textStyle: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      label: Text(
                                        isLive
                                            ? launchState.matchCount > 0
                                                  ? 'Rebuild live schedule'
                                                  : 'Generate live schedule'
                                            : _isSubmitting
                                            ? 'Starting tournament...'
                                            : 'Start tournament',
                                      ),
                                    ),
                                  ),
                                if (isLive)
                                  SizedBox(
                                    width: isCompact ? double.infinity : 200,
                                    child: OutlinedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _returnToSetup,
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpace.lg,
                                          vertical: isCompact
                                              ? AppSpace.md
                                              : AppSpace.lg,
                                        ),
                                      ),
                                      child: const Text('Return to setup'),
                                    ),
                                  ),
                                if (isLive && launchState.canComplete)
                                  SizedBox(
                                    width: isCompact ? double.infinity : 220,
                                    child: FilledButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : () => _completeTournament(
                                              launchState,
                                            ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppPalette.oliveStrong,
                                      ),
                                      child: const Text('Complete tournament'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!isCompleted &&
                              isLive &&
                              launchState.matchCount > 0) ...[
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              '${launchState.matchCount} live match records currently staged.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppPalette.inkSoft,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpace.lg),
          WorkspaceStatRail(
            metrics: [
              WorkspaceMetricItemData(
                value: '${launchState.readyCategories}',
                label: 'ready categories',
                foreground: const Color(0xFF456F77),
                isHighlighted: true,
              ),
              WorkspaceMetricItemData(
                value: '${launchState.playableMatches}',
                label: 'playable matches',
                foreground: const Color(0xFF365141),
              ),
              WorkspaceMetricItemData(
                value: '${launchState.activeCourts}',
                label: 'active courts',
                foreground: const Color(0xFF8F6038),
              ),
            ],
          ),
          if (launchState.schedulePending || launchState.courtsPending) ...[
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                if (launchState.schedulePending)
                  const WorkspaceTag(
                    label: 'Schedule loading',
                    background: AppPalette.skySoft,
                    foreground: Color(0xFF456F77),
                  ),
                if (launchState.courtsPending)
                  const WorkspaceTag(
                    label: 'Courts loading',
                    background: AppPalette.apricotSoft,
                    foreground: Color(0xFF8F6038),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
          ],
          if (!isCompleted && !isLive && launchState.blockers.isNotEmpty) ...[
            for (final blocker in launchState.blockers) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 16,
                      color: Color(0xFF8F6038),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      blocker,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
              if (blocker != launchState.blockers.last)
                const SizedBox(height: AppSpace.xs),
            ],
          ] else if (isLive && !launchState.canComplete) ...[
            Text(
              'Complete every staged match before wrapping up the tournament.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

final class _TournamentLaunchState {
  const _TournamentLaunchState({
    required this.readyCategories,
    required this.playableMatches,
    required this.activeCourts,
    required this.pendingMatches,
    required this.readyMatches,
    required this.onCourtMatches,
    required this.schedulePending,
    required this.courtsPending,
    required this.blockers,
    required this.scheduleSnapshot,
    required this.courts,
    required this.matchCount,
  });

  final int readyCategories;
  final int playableMatches;
  final int activeCourts;
  final int pendingMatches;
  final int readyMatches;
  final int onCourtMatches;
  final bool schedulePending;
  final bool courtsPending;
  final List<String> blockers;
  final TournamentCategoryScheduleSnapshot? scheduleSnapshot;
  final List<TournamentCourt>? courts;
  final int matchCount;

  bool get canStart => blockers.isEmpty && !schedulePending && !courtsPending;
  int get incompleteMatchCount =>
      pendingMatches + readyMatches + onCourtMatches;
  bool get canComplete =>
      matchCount > 0 &&
      !schedulePending &&
      !courtsPending &&
      incompleteMatchCount == 0;
}

_TournamentLaunchState _deriveLaunchState({
  required Tournament tournament,
  required AsyncValue<TournamentCategoryScheduleSnapshot> schedule,
  required AsyncValue<List<TournamentCourt>> courts,
  required AsyncValue<List<TournamentMatch>> matches,
}) {
  final scheduleSnapshot = schedule.asData?.value;
  final readyCategories = scheduleSnapshot == null
      ? 0
      : scheduleSnapshot.categories
            .where((category) => category.playableMatchCount > 0)
            .length;
  final playableMatches = scheduleSnapshot == null
      ? 0
      : scheduleSnapshot.categories.fold<int>(
          0,
          (sum, category) => sum + category.playableMatchCount,
        );
  final activeCourts =
      courts.asData?.value.where((court) => court.isAvailable).length ??
      tournament.activeCourtCount;
  final matchList = matches.asData?.value ?? const <TournamentMatch>[];
  final matchCount = matchList.length;
  final pendingMatches = matchList.where((match) => match.isPending).length;
  final readyMatches = matchList.where((match) => match.isReady).length;
  final onCourtMatches = matchList.where((match) => match.isOnCourt).length;

  final blockers = <String>[];
  if (readyCategories == 0 || playableMatches == 0) {
    blockers.add(
      'Save seed order for at least one category so match flow can generate playable matches.',
    );
  }
  if (activeCourts == 0) {
    blockers.add('Generate or restore at least one active court.');
  }

  return _TournamentLaunchState(
    readyCategories: readyCategories,
    playableMatches: playableMatches,
    activeCourts: activeCourts,
    pendingMatches: pendingMatches,
    readyMatches: readyMatches,
    onCourtMatches: onCourtMatches,
    schedulePending: schedule.isLoading && !schedule.hasValue,
    courtsPending: courts.isLoading && !courts.hasValue,
    blockers: blockers,
    scheduleSnapshot: scheduleSnapshot,
    courts: courts.asData?.value,
    matchCount: matchCount,
  );
}

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'This organizer account cannot start the tournament yet. Reload and try again.';
  }
  return 'We could not start the tournament right now. Please try again.';
}
