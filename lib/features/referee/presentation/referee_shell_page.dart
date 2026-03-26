import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../auth/data/auth_providers.dart';
import '../../scheduler/data/court_providers.dart';
import '../../scheduler/data/referee_flow_providers.dart';
import '../../scheduler/data/score_submission_providers.dart';
import '../../scheduler/data/tournament_match_providers.dart';
import '../../scheduler/domain/score_submission.dart';
import '../../scheduler/domain/tournament_court.dart';
import '../../scheduler/domain/tournament_match.dart';
import '../../tournaments/data/tournament_role_providers.dart';
import '../../tournaments/data/tournament_providers.dart';
import '../../tournaments/domain/tournament_role.dart';

final class RefereeShellPage extends ConsumerStatefulWidget {
  const RefereeShellPage({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  ConsumerState<RefereeShellPage> createState() => _RefereeShellPageState();
}

class _RefereeShellPageState extends ConsumerState<RefereeShellPage> {
  final TextEditingController _lookupController = TextEditingController();
  String _query = '';
  String? _busyActionId;
  String? _submittedMatchId;

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(currentUserRoleProvider(widget.tournamentId));
    final matchesAsync = ref.watch(
      tournamentMatchesProvider(widget.tournamentId),
    );
    final courtsAsync = ref.watch(
      tournamentCourtsProvider(widget.tournamentId),
    );
    final tournamentAsync = ref.watch(
      tournamentByIdProvider(widget.tournamentId),
    );
    final tournamentName =
        tournamentAsync.asData?.value?.name ?? widget.tournamentId;
    final error = roleAsync.error ?? matchesAsync.error ?? courtsAsync.error;

    if (error != null) {
      return _RefereeScaffold(
        roleLabel: 'Referee',
        tournamentName: tournamentName,
        child: _RefereeEmptyState(
          title: 'Unable to load referee workspace',
          message: error.toString(),
          icon: Icons.error_outline,
        ),
      );
    }

    if (roleAsync.isLoading ||
        matchesAsync.isLoading ||
        courtsAsync.isLoading) {
      return const _RefereeScaffold(
        roleLabel: 'Referee',
        tournamentName: null,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final role = roleAsync.value;
    final user = ref.watch(firebaseAuthProvider).currentUser;
    if (role == null || user == null) {
      return const _RefereeScaffold(
        roleLabel: 'Referee',
        tournamentName: null,
        child: _RefereeEmptyState(
          title: 'Referee access not available',
          message: 'Sign in with an assigned referee or staff account.',
          icon: Icons.lock_outline,
        ),
      );
    }

    final matches = matchesAsync.value ?? const <TournamentMatch>[];
    final courts = courtsAsync.value ?? const <TournamentCourt>[];
    final visibleMatches = matches
        .where(
          (match) =>
              match.isAssigned ||
              match.isCalled ||
              match.isOnCourt ||
              match.isScoreSubmitted,
        )
        .toList(growable: false);

    final filteredMatches = _query.trim().isEmpty
        ? visibleMatches
        : visibleMatches
              .where((match) {
                final normalized = _query.trim().toLowerCase();
                return match.matchCode.toLowerCase().contains(normalized) ||
                    match.categoryName.toLowerCase().contains(normalized) ||
                    match.teamOneLabel.toLowerCase().contains(normalized) ||
                    match.teamTwoLabel.toLowerCase().contains(normalized) ||
                    (match.assignedCourtCode?.toLowerCase().contains(
                          normalized,
                        ) ??
                        false);
              })
              .toList(growable: false);
    final matchByCourtId = <String, TournamentMatch>{
      for (final match in visibleMatches)
        if (match.assignedCourtId != null) match.assignedCourtId!: match,
    };

    return _RefereeScaffold(
      roleLabel: role.role.label,
      tournamentName: tournamentName,
      child: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          _RefereeHero(
            tournamentName: tournamentName,
            courtCount: courts.where((court) => court.isAvailable).length,
            activeCount: visibleMatches.length,
            submittedCount: visibleMatches
                .where((match) => match.isScoreSubmitted)
                .length,
          ),
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _lookupController,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Find by court, match code, or team',
              hintText: 'Example: C1, RR-3, Men Open',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          _RefereeCourtBoard(courts: courts, matchByCourtId: matchByCourtId),
          const SizedBox(height: AppSpace.lg),
          if (_submittedMatchId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.md),
              child: _RefereeNotice(
                message:
                    'Score submission queued. Assistant or organizer approval is still required.',
              ),
            ),
          if (filteredMatches.isEmpty)
            const _RefereeEmptyState(
              title: 'No matches available',
              message:
                  'Assigned and current matches will appear here once they are ready for referee scoring.',
              icon: Icons.sports_outlined,
            )
          else
            ...filteredMatches.map(
              (match) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: _RefereeMatchCard(
                  tournamentId: widget.tournamentId,
                  match: match,
                  isBusy: _busyActionId == 'submit-${match.id}',
                  onSubmit: () => _openSubmitDialog(
                    user: user,
                    role: role.role,
                    match: match,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openSubmitDialog({
    required User user,
    required TournamentRoleType role,
    required TournamentMatch match,
  }) async {
    final payload = await showDialog<_RefereeScorePayload>(
      context: context,
      builder: (context) => _RefereeScoreDialog(match: match),
    );
    if (payload == null) {
      return;
    }

    await _runAction(
      actionId: 'submit-${match.id}',
      successMessage: 'Score submitted for approval.',
      action: () => ref
          .read(refereeFlowServiceProvider)
          .submitScore(
            tournamentId: widget.tournamentId,
            matchId: match.id,
            submittedByUserId: user.uid,
            submittedByRole: role.value,
            scores: payload.scores,
            note: payload.note,
          ),
      onSuccess: () {
        setState(() {
          _submittedMatchId = match.id;
        });
      },
    );
  }

  Future<void> _runAction({
    required String actionId,
    required Future<void> Function() action,
    required String successMessage,
    VoidCallback? onSuccess,
  }) async {
    if (_busyActionId != null) {
      return;
    }
    setState(() {
      _busyActionId = actionId;
    });
    try {
      await action();
      onSuccess?.call();
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

final class _RefereeScaffold extends StatelessWidget {
  const _RefereeScaffold({
    required this.child,
    required this.roleLabel,
    required this.tournamentName,
  });

  final Widget child;
  final String roleLabel;
  final String? tournamentName;

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
        title: const Text('Referee desk'),
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
              backgroundColor: Colors.orange.shade50,
              side: BorderSide(color: Colors.orange.shade200),
            ),
          ),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}

final class _RefereeHero extends StatelessWidget {
  const _RefereeHero({
    required this.tournamentName,
    required this.courtCount,
    required this.activeCount,
    required this.submittedCount,
  });

  final String tournamentName;
  final int courtCount;
  final int activeCount;
  final int submittedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tournamentName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Submit official scores from court-side and leave approval to assistant or organizer staff.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _RefereeChip(label: 'Courts in view', value: '$courtCount'),
              _RefereeChip(label: 'Visible matches', value: '$activeCount'),
              _RefereeChip(
                label: 'Submitted in view',
                value: '$submittedCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _RefereeCourtBoard extends StatelessWidget {
  const _RefereeCourtBoard({
    required this.courts,
    required this.matchByCourtId,
  });

  final List<TournamentCourt> courts;
  final Map<String, TournamentMatch> matchByCourtId;

  @override
  Widget build(BuildContext context) {
    if (courts.isEmpty) {
      return const _RefereeEmptyState(
        title: 'Court lookup not ready',
        message: 'Courts will appear here once the organizer configures them.',
        icon: Icons.grid_view_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Court lookup board',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Use the court board to find active referee work before searching for a specific match.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: courts.map((court) {
            final match = matchByCourtId[court.id];
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
                  _RefereeStatusBadge(
                    label: match?.status.label ?? court.status.label,
                    color: match == null
                        ? (court.isAvailable ? Colors.teal : Colors.orange)
                        : _statusColor(match.status),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    match == null
                        ? (court.isAvailable
                              ? 'Open court'
                              : 'Court unavailable')
                        : '${match.teamOneLabel} vs ${match.teamTwoLabel}',
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

final class _RefereeChip extends StatelessWidget {
  const _RefereeChip({required this.label, required this.value});

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

final class _RefereeNotice extends StatelessWidget {
  const _RefereeNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.orange.shade800),
      ),
    );
  }
}

final class _RefereeMatchCard extends ConsumerWidget {
  const _RefereeMatchCard({
    required this.tournamentId,
    required this.match,
    required this.isBusy,
    required this.onSubmit,
  });

  final String tournamentId;
  final TournamentMatch match;
  final bool isBusy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(
      matchSubmissionsProvider((tournamentId: tournamentId, matchId: match.id)),
    );
    final submissionList = submissionsAsync.asData?.value;
    final latestSubmission = submissionList?.isNotEmpty == true
        ? submissionList!.first
        : null;

    return Container(
      width: double.infinity,
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
            '${match.categoryName} | ${match.matchCode}',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            '${match.teamOneLabel} vs ${match.teamTwoLabel}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              _RefereeStatusBadge(
                label: match.status.label,
                color: _statusColor(match.status),
              ),
              if (match.assignedCourtCode != null)
                _RefereeStatusBadge(
                  label: match.assignedCourtCode!,
                  color: Colors.indigo,
                ),
              if (latestSubmission != null)
                _RefereeStatusBadge(
                  label: latestSubmission.approvalStatus.label,
                  color:
                      latestSubmission.approvalStatus ==
                          ScoreApprovalStatus.rejected
                      ? Colors.red
                      : latestSubmission.approvalStatus ==
                            ScoreApprovalStatus.approved
                      ? Colors.green
                      : Colors.orange,
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: isBusy ? null : onSubmit,
              child: Text(isBusy ? 'Submitting...' : 'Submit score'),
            ),
          ),
        ],
      ),
    );
  }
}

final class _RefereeStatusBadge extends StatelessWidget {
  const _RefereeStatusBadge({required this.label, required this.color});

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

final class _RefereeEmptyState extends StatelessWidget {
  const _RefereeEmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
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

final class _RefereeScoreDialog extends StatefulWidget {
  const _RefereeScoreDialog({required this.match});

  final TournamentMatch match;

  @override
  State<_RefereeScoreDialog> createState() => _RefereeScoreDialogState();
}

class _RefereeScoreDialogState extends State<_RefereeScoreDialog> {
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
      _RefereeScorePayload(scores: scores, note: _noteController.text.trim()),
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
                hintText: 'Optional referee note',
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Submit for approval'),
        ),
      ],
    );
  }
}

final class _RefereeScorePayload {
  const _RefereeScorePayload({required this.scores, required this.note});

  final List<MatchGameScore> scores;
  final String note;
}

Color _statusColor(TournamentMatchStatus status) {
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
    TournamentMatchStatus.pending => Colors.grey,
  };
}
