import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';
import '../../scheduler/data/assistant_flow_providers.dart';
import '../../scheduler/data/court_providers.dart';
import '../../scheduler/data/score_submission_providers.dart';
import '../../scheduler/data/tournament_match_providers.dart';
import '../../scheduler/domain/score_submission.dart';
import '../../scheduler/domain/tournament_court.dart';
import '../../scheduler/domain/tournament_match.dart';
import '../../tournaments/data/tournament_role_providers.dart';
import '../../tournaments/data/tournament_providers.dart';
import '../../tournaments/domain/tournament_role.dart';

final class AssistantShellPage extends ConsumerStatefulWidget {
  const AssistantShellPage({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  ConsumerState<AssistantShellPage> createState() => _AssistantShellPageState();
}

class _AssistantShellPageState extends ConsumerState<AssistantShellPage> {
  String? _busyActionId;
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(
      tournamentMatchesProvider(widget.tournamentId),
    );
    final courtsAsync = ref.watch(
      tournamentCourtsProvider(widget.tournamentId),
    );
    final submissionsAsync = ref.watch(
      pendingSubmissionsProvider(widget.tournamentId),
    );
    final roleAsync = ref.watch(currentUserRoleProvider(widget.tournamentId));
    final tournamentAsync = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final tournamentName =
        tournamentAsync.asData?.value?.name ?? widget.tournamentId;

    final firstError =
        matchesAsync.error ??
        courtsAsync.error ??
        submissionsAsync.error ??
        roleAsync.error;
    if (firstError != null) {
      return _AssistantScaffold(
        roleLabel: 'Assistant',
        tournamentName: tournamentName,
        selectedTabIndex: _selectedTabIndex,
        child: _EmptyState(
          title: 'Unable to load assistant workspace',
          message: firstError.toString(),
          icon: Icons.error_outline,
        ),
      );
    }

    if (matchesAsync.isLoading ||
        courtsAsync.isLoading ||
        submissionsAsync.isLoading ||
        roleAsync.isLoading) {
      return const _AssistantScaffold(
        roleLabel: 'Assistant',
        tournamentName: null,
        selectedTabIndex: 0,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final role = roleAsync.value;
    final user = ref.watch(firebaseAuthProvider).currentUser;
    if (role == null || user == null) {
      return const _AssistantScaffold(
        roleLabel: 'Assistant',
        tournamentName: null,
        selectedTabIndex: 0,
        child: _EmptyState(
          title: 'Assistant access not available',
          message: 'Sign in with a permitted tournament role to continue.',
          icon: Icons.lock_outline,
        ),
      );
    }

    final matches = matchesAsync.value ?? const <TournamentMatch>[];
    final courts = courtsAsync.value ?? const <TournamentCourt>[];
    final submissions = submissionsAsync.value ?? const <ScoreSubmission>[];

    final readyMatches = matches.where((match) => match.isReady).toList();
    final assignedMatches = matches
        .where((match) => match.isAssigned || match.isCalled)
        .toList();
    final onCourtMatches = matches
        .where((match) => match.isOnCourt || match.isScoreSubmitted)
        .toList();
    final occupiedCourtIds = matches
        .where(
          (match) =>
              match.assignedCourtId != null &&
              !match.isCompleted &&
              match.status != TournamentMatchStatus.cancelled,
        )
        .map((match) => match.assignedCourtId!)
        .toSet();
    final availableCourts = courts
        .where(
          (court) => court.isAvailable && !occupiedCourtIds.contains(court.id),
        )
        .toList();
    final matchByCourtId = <String, TournamentMatch>{
      for (final match in matches)
        if (match.assignedCourtId != null &&
            !match.isCompleted &&
            match.status != TournamentMatchStatus.cancelled)
          match.assignedCourtId!: match,
    };
    final matchById = <String, TournamentMatch>{
      for (final match in matches) match.id: match,
    };

    final tabBody = switch (_selectedTabIndex) {
      0 => _buildDeskTab(
        context,
        tournamentName,
        readyMatches,
        availableCourts,
        assignedMatches,
        user,
        role.role,
        onCourtMatches,
        submissions.length,
      ),
      1 => _buildApprovalsTab(
        context,
        tournamentName,
        readyMatches.length,
        assignedMatches.length,
        onCourtMatches.length,
        submissions,
        user,
        role.role,
        matchById,
      ),
      _ => _buildCourtsTab(
        context,
        tournamentName,
        readyMatches.length,
        assignedMatches.length,
        onCourtMatches.length,
        submissions.length,
        courts,
        matchByCourtId,
      ),
    };

    return _AssistantScaffold(
      roleLabel: role.role.label,
      tournamentName: tournamentName,
      selectedTabIndex: _selectedTabIndex,
      onSelectTab: (index) {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: tabBody,
    );
  }

  Widget _buildDeskTab(
    BuildContext context,
    String tournamentName,
    List<TournamentMatch> readyMatches,
    List<TournamentCourt> availableCourts,
    List<TournamentMatch> assignedMatches,
    User user,
    TournamentRoleType role,
    List<TournamentMatch> onCourtMatches,
    int pendingCount,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        _buildSummary(
          context,
          tournamentName,
          readyMatches.length,
          assignedMatches.length,
          onCourtMatches.length,
          pendingCount,
        ),
        const SizedBox(height: AppSpace.lg),
        _buildReadyQueue(context, readyMatches, availableCourts),
        const SizedBox(height: AppSpace.xl),
        _buildAssigned(context, assignedMatches),
        const SizedBox(height: AppSpace.xl),
        _buildOnCourt(context, user, role, onCourtMatches),
      ],
    );
  }

  Widget _buildApprovalsTab(
    BuildContext context,
    String tournamentName,
    int readyCount,
    int assignedCount,
    int onCourtCount,
    List<ScoreSubmission> submissions,
    User user,
    TournamentRoleType role,
    Map<String, TournamentMatch> matchById,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        _buildSummary(
          context,
          tournamentName,
          readyCount,
          assignedCount,
          onCourtCount,
          submissions.length,
        ),
        const SizedBox(height: AppSpace.lg),
        _buildSubmissions(context, user, role, submissions, matchById),
      ],
    );
  }

  Widget _buildCourtsTab(
    BuildContext context,
    String tournamentName,
    int readyCount,
    int assignedCount,
    int onCourtCount,
    int pendingCount,
    List<TournamentCourt> courts,
    Map<String, TournamentMatch> matchByCourtId,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        _buildSummary(
          context,
          tournamentName,
          readyCount,
          assignedCount,
          onCourtCount,
          pendingCount,
        ),
        const SizedBox(height: AppSpace.lg),
        _buildCourts(context, courts, matchByCourtId),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    String tournamentName,
    int readyCount,
    int assignedCount,
    int onCourtCount,
    int pendingCount,
  ) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tournamentName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Queue matches, manage court flow, and review score submissions from one desk.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _MetricChip(label: 'Ready', value: '$readyCount'),
              _MetricChip(label: 'Assigned', value: '$assignedCount'),
              _MetricChip(label: 'On court', value: '$onCourtCount'),
              _MetricChip(label: 'Pending', value: '$pendingCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourts(
    BuildContext context,
    List<TournamentCourt> courts,
    Map<String, TournamentMatch> matchByCourtId,
  ) {
    if (courts.isEmpty) {
      return const _EmptyState(
        title: 'No courts configured',
        message:
            'Organizer court setup needs to happen before assistant queueing begins.',
        icon: Icons.grid_view_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Court board',
          subtitle:
              'Track which courts are open and what is currently on them.',
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: courts.map((court) {
            final assignedMatch = matchByCourtId[court.id];
            final label = assignedMatch == null
                ? (court.isAvailable ? 'Open' : 'Unavailable')
                : assignedMatch.status.label;
            return Container(
              width: 220,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(AppRadii.panel),
                border: Border.all(color: AppPalette.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.code,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  _StatusBadge(
                    label: label,
                    color: _statusColor(assignedMatch?.status),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    assignedMatch == null
                        ? 'No match assigned'
                        : '${assignedMatch.teamOneLabel} vs ${assignedMatch.teamTwoLabel}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReadyQueue(
    BuildContext context,
    List<TournamentMatch> readyMatches,
    List<TournamentCourt> availableCourts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Ready queue',
          subtitle: 'Queue ready matches onto open courts.',
        ),
        const SizedBox(height: AppSpace.sm),
        if (readyMatches.isEmpty)
          const _EmptyState(
            title: 'No ready matches',
            message: 'Ready matches will appear here once courts free up.',
            icon: Icons.playlist_add_check_circle_outlined,
          )
        else
          ...readyMatches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _SurfaceCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _MatchSummary(
                        match: match,
                        subtitle: '${match.categoryName} | ${match.matchCode}',
                      ),
                    ),
                    if (availableCourts.isEmpty)
                      Text(
                        'No open courts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.inkMuted,
                        ),
                      )
                    else
                      PopupMenuButton<String>(
                        enabled: _busyActionId != 'assign-${match.id}',
                        onSelected: (courtId) => _runAction(
                          actionId: 'assign-${match.id}',
                          successMessage: 'Match assigned to court.',
                          action: () => ref
                              .read(assistantFlowServiceProvider)
                              .assignMatchToCourt(
                                tournamentId: widget.tournamentId,
                                matchId: match.id,
                                courtId: courtId,
                              ),
                        ),
                        itemBuilder: (context) => availableCourts
                            .map(
                              (court) => PopupMenuItem<String>(
                                value: court.id,
                                child: Text('${court.code} | ${court.name}'),
                              ),
                            )
                            .toList(),
                        child: FilledButton(
                          onPressed: null,
                          child: Text(
                            _busyActionId == 'assign-${match.id}'
                                ? 'Assigning...'
                                : 'Assign court',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssigned(
    BuildContext context,
    List<TournamentMatch> assignedMatches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Assigned matches',
          subtitle: 'Move queued matches onto court when play is starting.',
        ),
        const SizedBox(height: AppSpace.sm),
        if (assignedMatches.isEmpty)
          const _EmptyState(
            title: 'No assigned matches',
            message: 'Assigned matches will show here before they go on court.',
            icon: Icons.sports_tennis_outlined,
          )
        else
          ...assignedMatches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _ActionMatchCard(
                match: match,
                actionLabel: 'Start match',
                isBusy: _busyActionId == 'start-${match.id}',
                onPressed: () => _runAction(
                  actionId: 'start-${match.id}',
                  successMessage: 'Match moved on court.',
                  action: () => ref
                      .read(assistantFlowServiceProvider)
                      .markMatchOnCourt(
                        tournamentId: widget.tournamentId,
                        matchId: match.id,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOnCourt(
    BuildContext context,
    User user,
    TournamentRoleType role,
    List<TournamentMatch> onCourtMatches,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'On-court matches',
          subtitle:
              'Enter scores directly from the assistant desk when needed.',
        ),
        const SizedBox(height: AppSpace.sm),
        if (onCourtMatches.isEmpty)
          const _EmptyState(
            title: 'No on-court matches',
            message: 'On-court matches will appear here once play starts.',
            icon: Icons.scoreboard_outlined,
          )
        else
          ...onCourtMatches.map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _ActionMatchCard(
                match: match,
                actionLabel: match.isScoreSubmitted
                    ? 'Submitted for review'
                    : 'Enter score',
                isBusy: _busyActionId == 'score-${match.id}',
                isActionEnabled: !match.isScoreSubmitted,
                onPressed: () => _openAssistantScoreDialog(
                  user: user,
                  role: role,
                  match: match,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissions(
    BuildContext context,
    User user,
    TournamentRoleType role,
    List<ScoreSubmission> submissions,
    Map<String, TournamentMatch> matchById,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Pending approvals',
          subtitle: 'Review referee submissions before they become official.',
        ),
        const SizedBox(height: AppSpace.sm),
        if (submissions.isEmpty)
          const _EmptyState(
            title: 'No pending submissions',
            message: 'Referee submissions awaiting approval will appear here.',
            icon: Icons.fact_check_outlined,
          )
        else
          ...submissions.map(
            (submission) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: _PendingSubmissionCard(
                submission: submission,
                match: matchById[submission.matchId],
                approveBusy: _busyActionId == 'approve-${submission.id}',
                rejectBusy: _busyActionId == 'reject-${submission.id}',
                onApprove: () => _runAction(
                  actionId: 'approve-${submission.id}',
                  successMessage: 'Score approved and match completed.',
                  action: () => ref
                      .read(assistantFlowServiceProvider)
                      .approveSubmission(
                        tournamentId: widget.tournamentId,
                        submissionId: submission.id,
                        approvedByUserId: user.uid,
                        approvedByRole: role.value,
                      ),
                ),
                onReject: () => _openRejectDialog(
                  user: user,
                  role: role,
                  submission: submission,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openAssistantScoreDialog({
    required User user,
    required TournamentRoleType role,
    required TournamentMatch match,
  }) async {
    final payload = await showDialog<_ScoreEntryPayload>(
      context: context,
      builder: (context) => _AssistantScoreDialog(match: match),
    );
    if (payload == null) {
      return;
    }
    await _runAction(
      actionId: 'score-${match.id}',
      successMessage: 'Score committed and match completed.',
      action: () => ref
          .read(assistantFlowServiceProvider)
          .submitAndApproveAssistantScore(
            tournamentId: widget.tournamentId,
            matchId: match.id,
            submittedByUserId: user.uid,
            submittedByRole: role.value,
            scores: payload.scores,
            note: payload.note,
          ),
    );
  }

  Future<void> _openRejectDialog({
    required User user,
    required TournamentRoleType role,
    required ScoreSubmission submission,
  }) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectSubmissionDialog(),
    );
    if (reason == null) {
      return;
    }
    await _runAction(
      actionId: 'reject-${submission.id}',
      successMessage: 'Submission rejected and returned for correction.',
      action: () => ref
          .read(assistantFlowServiceProvider)
          .rejectSubmission(
            tournamentId: widget.tournamentId,
            submissionId: submission.id,
            approvedByUserId: user.uid,
            approvedByRole: role.value,
            rejectedReason: reason,
          ),
    );
  }

  Future<void> _runAction({
    required String actionId,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_busyActionId != null) {
      return;
    }
    setState(() {
      _busyActionId = actionId;
    });
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyActionId = null;
        });
      }
    }
  }
}

final class _AssistantScaffold extends StatelessWidget {
  const _AssistantScaffold({
    required this.child,
    required this.roleLabel,
    required this.tournamentName,
    required this.selectedTabIndex,
    this.onSelectTab,
  });

  final Widget child;
  final String roleLabel;
  final String? tournamentName;
  final int selectedTabIndex;
  final ValueChanged<int>? onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _RoleDeskBackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.go('/');
          },
        ),
        title: const Text('Assistant desk'),
        actions: [
          if (tournamentName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  tournamentName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(roleLabel),
              backgroundColor: Colors.teal.shade50,
              side: BorderSide(color: Colors.teal.shade200),
            ),
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTabIndex,
        onDestinationSelected: onSelectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.view_list_rounded),
            selectedIcon: Icon(Icons.view_list),
            label: 'Desk',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Courts',
          ),
        ],
      ),
    );
  }
}

final class _RoleDeskBackButton extends StatelessWidget {
  const _RoleDeskBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: onPressed,
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpace.xs),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
        ),
      ],
    );
  }
}

final class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: child,
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
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: AppPalette.line),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

final class _MatchSummary extends StatelessWidget {
  const _MatchSummary({required this.match, required this.subtitle});

  final TournamentMatch match;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppPalette.inkSoft),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          '${match.teamOneLabel} vs ${match.teamTwoLabel}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

final class _ActionMatchCard extends StatelessWidget {
  const _ActionMatchCard({
    required this.match,
    required this.actionLabel,
    required this.isBusy,
    required this.onPressed,
    this.isActionEnabled = true,
  });

  final TournamentMatch match;
  final String actionLabel;
  final bool isBusy;
  final bool isActionEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MatchSummary(
                  match: match,
                  subtitle: '${match.categoryName} | ${match.matchCode}',
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
                    _StatusBadge(
                      label: match.status.label,
                      color: _statusColor(match.status),
                    ),
                    if (match.assignedCourtCode != null)
                      _StatusBadge(
                        label: match.assignedCourtCode!,
                        color: Colors.indigo,
                      ),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: isBusy || !isActionEnabled ? null : onPressed,
            child: Text(isBusy ? 'Working...' : actionLabel),
          ),
        ],
      ),
    );
  }
}

final class _PendingSubmissionCard extends StatelessWidget {
  const _PendingSubmissionCard({
    required this.submission,
    required this.match,
    required this.approveBusy,
    required this.rejectBusy,
    required this.onApprove,
    required this.onReject,
  });

  final ScoreSubmission submission;
  final TournamentMatch? match;
  final bool approveBusy;
  final bool rejectBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final matchLabel = match == null
        ? 'Match ${submission.matchId}'
        : '${match!.teamOneLabel} vs ${match!.teamTwoLabel}';
    final subtitle = match == null
        ? 'Pending score submission'
        : '${match!.categoryName} | ${match!.matchCode}';

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(matchLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.sm),
          Text(
            submission.games
                .map(
                  (game) =>
                      'G${game.gameNumber}: ${game.teamOnePoints}-${game.teamTwoPoints}',
                )
                .join(' | '),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (submission.note != null &&
              submission.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              submission.note!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              FilledButton(
                onPressed: approveBusy || rejectBusy ? null : onApprove,
                child: Text(approveBusy ? 'Approving...' : 'Approve'),
              ),
              const SizedBox(width: AppSpace.sm),
              OutlinedButton(
                onPressed: approveBusy || rejectBusy ? null : onReject,
                child: Text(rejectBusy ? 'Rejecting...' : 'Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppPalette.inkMuted),
          const SizedBox(height: AppSpace.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
          ),
        ],
      ),
    );
  }
}

final class _AssistantScoreDialog extends StatefulWidget {
  const _AssistantScoreDialog({required this.match});

  final TournamentMatch match;

  @override
  State<_AssistantScoreDialog> createState() => _AssistantScoreDialogState();
}

class _AssistantScoreDialogState extends State<_AssistantScoreDialog> {
  late final List<TextEditingController> _controllers;
  final TextEditingController _noteController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      6,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final scores = <MatchGameScore>[];
    for (var gameIndex = 0; gameIndex < 3; gameIndex++) {
      final left = _controllers[gameIndex * 2].text.trim();
      final right = _controllers[(gameIndex * 2) + 1].text.trim();
      if (left.isEmpty && right.isEmpty) {
        if (gameIndex < 2) {
          setState(() {
            _error = 'Games 1 and 2 are required.';
          });
          return;
        }
        continue;
      }
      if (left.isEmpty || right.isEmpty) {
        setState(() {
          _error = 'Enter both scores for each completed game.';
        });
        return;
      }

      final leftScore = int.tryParse(left);
      final rightScore = int.tryParse(right);
      if (leftScore == null || rightScore == null) {
        setState(() {
          _error = 'Scores must be whole numbers.';
        });
        return;
      }

      scores.add(
        MatchGameScore(
          gameNumber: gameIndex + 1,
          teamOnePoints: leftScore,
          teamTwoPoints: rightScore,
        ),
      );
    }

    Navigator.of(context).pop(
      _ScoreEntryPayload(scores: scores, note: _noteController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.match.matchCode),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.match.teamOneLabel} vs ${widget.match.teamTwoLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpace.md),
            for (var game = 0; game < 3; game++) ...[
              Text('Game ${game + 1}'),
              const SizedBox(height: AppSpace.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[game * 2],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: widget.match.teamOneLabel,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: TextField(
                      controller: _controllers[(game * 2) + 1],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: widget.match.teamTwoLabel,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional floor note',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Commit result')),
      ],
    );
  }
}

final class _RejectSubmissionDialog extends StatefulWidget {
  const _RejectSubmissionDialog();

  @override
  State<_RejectSubmissionDialog> createState() =>
      _RejectSubmissionDialogState();
}

class _RejectSubmissionDialogState extends State<_RejectSubmissionDialog> {
  final TextEditingController _controller = TextEditingController(
    text: 'Needs score correction.',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject submission'),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Explain what needs correction',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

final class _ScoreEntryPayload {
  const _ScoreEntryPayload({required this.scores, required this.note});

  final List<MatchGameScore> scores;
  final String note;
}

Color _statusColor(TournamentMatchStatus? status) {
  return switch (status) {
    TournamentMatchStatus.ready => Colors.teal,
    TournamentMatchStatus.assigned => Colors.indigo,
    TournamentMatchStatus.called => Colors.orange,
    TournamentMatchStatus.onCourt => Colors.green,
    TournamentMatchStatus.scoreSubmitted => Colors.deepPurple,
    TournamentMatchStatus.completed => Colors.blueGrey,
    TournamentMatchStatus.held => Colors.brown,
    TournamentMatchStatus.cancelled => Colors.red,
    TournamentMatchStatus.forfeit => Colors.redAccent,
    _ => Colors.grey,
  };
}
