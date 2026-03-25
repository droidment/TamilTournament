import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../tournaments/presentation/workspace_components.dart';
import '../data/court_providers.dart';
import '../data/tournament_match_providers.dart';
import '../domain/tournament_court.dart';
import '../domain/tournament_match.dart';

final class CourtManagementSection extends ConsumerStatefulWidget {
  const CourtManagementSection({
    super.key,
    required this.tournamentId,
    required this.initialCourtCount,
    this.embedded = false,
    this.readOnly = false,
  });

  final String tournamentId;
  final int initialCourtCount;
  final bool embedded;
  final bool readOnly;

  @override
  ConsumerState<CourtManagementSection> createState() =>
      _CourtManagementSectionState();
}

class _CourtManagementSectionState
    extends ConsumerState<CourtManagementSection> {
  late final TextEditingController _courtCountController;
  int? _lastSyncedConfiguredCourtCount;
  bool _isGenerating = false;
  final Set<String> _busyCourtIds = <String>{};
  final Set<String> _busyMatchIds = <String>{};

  @override
  void initState() {
    super.initState();
    final initialCount = widget.initialCourtCount > 0
        ? widget.initialCourtCount
        : 10;
    _courtCountController = TextEditingController(
      text: initialCount.toString(),
    );
    _lastSyncedConfiguredCourtCount = widget.initialCourtCount > 0
        ? widget.initialCourtCount
        : null;
  }

  @override
  void didUpdateWidget(covariant CourtManagementSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournamentId != widget.tournamentId) {
      final initialCount = widget.initialCourtCount > 0
          ? widget.initialCourtCount
          : 10;
      _courtCountController.text = initialCount.toString();
      _lastSyncedConfiguredCourtCount = widget.initialCourtCount > 0
          ? widget.initialCourtCount
          : null;
    }
  }

  @override
  void dispose() {
    _courtCountController.dispose();
    super.dispose();
  }

  Future<void> _generateCourts() async {
    final totalCourts = int.tryParse(_courtCountController.text.trim());
    if (totalCourts == null || totalCourts <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid court count.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      await ref
          .read(courtRepositoryProvider)
          .generateCourts(
            tournamentId: widget.tournamentId,
            totalCourts: totalCourts,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configured $totalCourts court(s).')),
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
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _toggleCourt(TournamentCourt court) async {
    if (_busyCourtIds.contains(court.id)) {
      return;
    }
    setState(() {
      _busyCourtIds.add(court.id);
    });
    try {
      await ref
          .read(courtRepositoryProvider)
          .setCourtAvailability(
            tournamentId: widget.tournamentId,
            courtId: court.id,
            isAvailable: !court.isAvailable,
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
          _busyCourtIds.remove(court.id);
        });
      }
    }
  }

  Future<void> _editCourtDetails(TournamentCourt court) async {
    final nameController = TextEditingController(text: court.name);
    final noteController = TextEditingController(text: court.note);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: const BorderSide(color: AppPalette.line),
        ),
        title: Text('Court details · ${court.code}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Court name',
                  hintText: 'Court 1',
                ),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: noteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Operational note',
                  hintText: 'Floor wipe, net repair, reserved for finals...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save note'),
          ),
        ],
      ),
    );

    if (shouldSave != true || !mounted) {
      nameController.dispose();
      noteController.dispose();
      return;
    }

    setState(() {
      _busyCourtIds.add(court.id);
    });
    try {
      await ref
          .read(courtRepositoryProvider)
          .updateCourtDetails(
            tournamentId: widget.tournamentId,
            courtId: court.id,
            name: nameController.text.trim().isEmpty
                ? court.name
                : nameController.text,
            note: noteController.text,
          );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    } finally {
      nameController.dispose();
      noteController.dispose();
      if (mounted) {
        setState(() {
          _busyCourtIds.remove(court.id);
        });
      }
    }
  }

  Future<void> _scoreMatch(TournamentCourt court, TournamentMatch match) async {
    final result = await showDialog<_ScoreDialogResult>(
      context: context,
      builder: (context) => _ScoreMatchDialog(match: match, court: court),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _busyMatchIds.add(match.id);
    });

    try {
      final repository = ref.read(tournamentMatchRepositoryProvider);
      if (result.finishMatch) {
        await repository.completeMatch(
          tournamentId: widget.tournamentId,
          matchId: match.id,
          scores: result.scores,
        );
      } else {
        await repository.saveMatchScores(
          tournamentId: widget.tournamentId,
          matchId: match.id,
          scores: result.scores,
        );
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.finishMatch
                ? '${match.matchCode} finished and the court queue moved forward.'
                : 'Saved score for ${match.matchCode}.',
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
          _busyMatchIds.remove(match.id);
        });
      }
    }
  }

  void _syncConfiguredCourtCount(List<TournamentCourt> courts) {
    if (_isGenerating || courts.isEmpty) {
      return;
    }

    final configuredCount = courts.length;
    final currentText = _courtCountController.text.trim();
    final previousText = _lastSyncedConfiguredCourtCount?.toString();
    final canReplaceText =
        previousText == null ||
        currentText.isEmpty ||
        currentText == previousText ||
        currentText == configuredCount.toString();

    if (!canReplaceText) {
      if (currentText == configuredCount.toString()) {
        _lastSyncedConfiguredCourtCount = configuredCount;
      }
      return;
    }

    if (currentText != configuredCount.toString()) {
      _courtCountController.value = _courtCountController.value.copyWith(
        text: configuredCount.toString(),
        selection: TextSelection.collapsed(
          offset: configuredCount.toString().length,
        ),
        composing: TextRange.empty,
      );
    }
    _lastSyncedConfiguredCourtCount = configuredCount;
  }

  @override
  Widget build(BuildContext context) {
    final courts = ref.watch(tournamentCourtsProvider(widget.tournamentId));
    final matches = ref.watch(tournamentMatchesProvider(widget.tournamentId));
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkspaceSectionLead(
          title: 'Court desk',
          description:
              'Set the active court pool before live scheduling begins, then pause or restore courts as the venue changes.',
          icon: Icons.sports_tennis_rounded,
          accent: Color(0xFF618374),
        ),
        const SizedBox(height: AppSpace.lg),
        if (courts.hasValue)
          WorkspaceStatRail(
            metrics: [
              WorkspaceMetricItemData(
                value: '${courts.requireValue.length}',
                label: 'configured',
                foreground: const Color(0xFF456F77),
                isHighlighted: true,
              ),
              WorkspaceMetricItemData(
                value:
                    '${courts.requireValue.where((court) => court.isAvailable).length}',
                label: 'active',
                foreground: const Color(0xFF365141),
              ),
              WorkspaceMetricItemData(
                value:
                    '${courts.requireValue.where((court) => !court.isAvailable).length}',
                label: 'paused',
                foreground: const Color(0xFF8F6038),
              ),
            ],
          ),
        if (courts.hasValue) const SizedBox(height: AppSpace.lg),
        _CourtSetupBar(
          controller: _courtCountController,
          isGenerating: _isGenerating,
          onGenerate: widget.readOnly ? null : _generateCourts,
        ),
        const SizedBox(height: AppSpace.lg),
        courts.when(
          data: (items) {
            _syncConfiguredCourtCount(items);
            if (items.isEmpty) {
              return const _CourtEmptyState();
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final useSingleColumn = constraints.maxWidth < 720;
                final cardWidth = useSingleColumn
                    ? constraints.maxWidth
                    : 240.0;

                return Wrap(
                  spacing: AppSpace.md,
                  runSpacing: AppSpace.md,
                  children: [
                    for (final court in items)
                      Builder(
                        builder: (context) {
                          final assignedMatch = _assignedMatchForCourt(
                            matches.asData?.value ?? const <TournamentMatch>[],
                            court.id,
                          );
                          return SizedBox(
                            width: cardWidth,
                            child: _CourtCard(
                              court: court,
                              assignedMatch: assignedMatch,
                              isBusy: _busyCourtIds.contains(court.id),
                              isScoring:
                                  assignedMatch != null &&
                                  _busyMatchIds.contains(assignedMatch.id),
                              readOnly: widget.readOnly,
                              onToggleAvailability: () => _toggleCourt(court),
                              onEditDetails: () => _editCourtDetails(court),
                              onScoreMatch: (match) =>
                                  _scoreMatch(court, match),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _CourtErrorState(message: _friendlyError(error)),
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
}

TournamentMatch? _assignedMatchForCourt(
  List<TournamentMatch> matches,
  String courtId,
) {
  for (final match in matches) {
    if (match.assignedCourtId == courtId && match.isOnCourt) {
      return match;
    }
  }

  return null;
}

final class _CourtSetupBar extends StatelessWidget {
  const _CourtSetupBar({
    required this.controller,
    required this.isGenerating,
    required this.onGenerate,
  });

  final TextEditingController controller;
  final bool isGenerating;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return WorkspaceSurfaceCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;

          return Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isCompact ? constraints.maxWidth : 180,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Court count',
                    hintText: '10',
                  ),
                ),
              ),
              SizedBox(
                width: isCompact ? constraints.maxWidth : null,
                child: FilledButton(
                  onPressed: isGenerating ? null : onGenerate,
                  child: Text(isGenerating ? 'Saving...' : 'Generate courts'),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? constraints.maxWidth : 420,
                ),
                child: Text(
                  'Generating keeps C1..Cn, preserves edited names and notes, and trims only courts above the new limit.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.assignedMatch,
    required this.readOnly,
    required this.isBusy,
    required this.isScoring,
    required this.onToggleAvailability,
    required this.onEditDetails,
    required this.onScoreMatch,
  });

  final TournamentCourt court;
  final TournamentMatch? assignedMatch;
  final bool readOnly;
  final bool isBusy;
  final bool isScoring;
  final VoidCallback onToggleAvailability;
  final VoidCallback onEditDetails;
  final ValueChanged<TournamentMatch> onScoreMatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = court.isAvailable
        ? AppPalette.sageStrong
        : AppPalette.apricot;

    return WorkspaceSurfaceCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(court.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.xs),
          Text(
            court.code,
            style: AppTheme.numeric(
              theme.textTheme.bodySmall,
            ).copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.md),
          WorkspaceTag(
            label: court.status.label,
            background: court.isAvailable
                ? AppPalette.sageSoft
                : AppPalette.apricotSoft,
            foreground: court.isAvailable
                ? const Color(0xFF365141)
                : const Color(0xFF8F6038),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            court.note.trim().isEmpty ? 'No operational note yet.' : court.note,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: court.note.trim().isEmpty
                  ? AppPalette.inkMuted
                  : AppPalette.inkSoft,
            ),
          ),
          if (assignedMatch != null) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppPalette.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadii.control),
                border: Border.all(color: AppPalette.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current match',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppPalette.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    assignedMatch!.categoryName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkSoft,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '${assignedMatch!.teamOneLabel} vs ${assignedMatch!.teamTwoLabel}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (assignedMatch!.hasScores) ...[
                    const SizedBox(height: AppSpace.sm),
                    _ScoreSummaryStrip(
                      scores: assignedMatch!.scores,
                      winnerLabel: assignedMatch!.winnerLabel,
                    ),
                  ],
                  const SizedBox(height: AppSpace.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: readOnly || isScoring
                          ? null
                          : () => onScoreMatch(assignedMatch!),
                      child: Text(isScoring ? 'Saving...' : 'Enter score'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              OutlinedButton(
                onPressed: isBusy || readOnly ? null : onEditDetails,
                child: const Text('Edit court'),
              ),
              FilledButton(
                onPressed: isBusy || readOnly ? null : onToggleAvailability,
                child: Text(
                  isBusy
                      ? 'Updating...'
                      : court.isAvailable
                      ? 'Pause court'
                      : 'Restore court',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _CourtEmptyState extends StatelessWidget {
  const _CourtEmptyState();

  @override
  Widget build(BuildContext context) {
    return const WorkspaceEmptyCard(
      title: 'No courts configured',
      message:
          'Start by generating the productive court pool for this tournament.',
    );
  }
}

final class _ScoreSummaryStrip extends StatelessWidget {
  const _ScoreSummaryStrip({required this.scores, required this.winnerLabel});

  final List<MatchGameScore> scores;
  final String? winnerLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: [
        for (final score in scores)
          WorkspaceTag(
            label:
                'G${score.gameNumber} ${score.teamOnePoints}-${score.teamTwoPoints}',
            background: AppPalette.surface,
            foreground: AppPalette.inkSoft,
          ),
        if (winnerLabel != null && winnerLabel!.trim().isNotEmpty)
          WorkspaceTag(
            label: winnerLabel!,
            background: AppPalette.sageSoft,
            foreground: const Color(0xFF365141),
          ),
      ],
    );
  }
}

final class _CourtErrorState extends StatelessWidget {
  const _CourtErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WorkspaceErrorCard(title: 'Courts need attention', message: message);
  }
}

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'This organizer account cannot update live results yet. Reload and try again.';
  }
  if (message.contains('failed-precondition')) {
    return 'Court data is not ready yet in this environment. Try again in a moment.';
  }
  return message;
}

final class _ScoreDialogResult {
  const _ScoreDialogResult({required this.scores, required this.finishMatch});

  final List<MatchGameScore> scores;
  final bool finishMatch;
}

final class _ScoreMatchDialog extends StatefulWidget {
  const _ScoreMatchDialog({required this.match, required this.court});

  final TournamentMatch match;
  final TournamentCourt court;

  @override
  State<_ScoreMatchDialog> createState() => _ScoreMatchDialogState();
}

class _ScoreMatchDialogState extends State<_ScoreMatchDialog> {
  late final List<TextEditingController> _teamOneControllers;
  late final List<TextEditingController> _teamTwoControllers;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _teamOneControllers = List<TextEditingController>.generate(3, (index) {
      final score = widget.match.scores.length > index
          ? widget.match.scores[index].teamOnePoints
          : null;
      return TextEditingController(text: score?.toString() ?? '');
    });
    _teamTwoControllers = List<TextEditingController>.generate(3, (index) {
      final score = widget.match.scores.length > index
          ? widget.match.scores[index].teamTwoPoints
          : null;
      return TextEditingController(text: score?.toString() ?? '');
    });
  }

  @override
  void dispose() {
    for (final controller in _teamOneControllers) {
      controller.dispose();
    }
    for (final controller in _teamTwoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit({required bool finishMatch}) {
    final scores = <MatchGameScore>[];

    for (var index = 0; index < 3; index++) {
      final leftRaw = _teamOneControllers[index].text.trim();
      final rightRaw = _teamTwoControllers[index].text.trim();
      if (leftRaw.isEmpty && rightRaw.isEmpty) {
        continue;
      }

      final left = int.tryParse(leftRaw);
      final right = int.tryParse(rightRaw);
      if (left == null || right == null) {
        setState(() {
          _errorText = 'Enter both scores for each saved game.';
        });
        return;
      }
      if (left < 0 || right < 0) {
        setState(() {
          _errorText = 'Scores cannot be negative.';
        });
        return;
      }
      if (left == right) {
        setState(() {
          _errorText = 'Games cannot end level.';
        });
        return;
      }

      scores.add(
        MatchGameScore(
          gameNumber: index + 1,
          teamOnePoints: left,
          teamTwoPoints: right,
        ),
      );
    }

    if (finishMatch) {
      final outcome = deriveMatchScoreOutcome(widget.match, scores);
      if (outcome == null) {
        setState(() {
          _errorText =
              'Finish requires a best-of-three result with one side winning two games.';
        });
        return;
      }
    }

    Navigator.of(
      context,
    ).pop(_ScoreDialogResult(scores: scores, finishMatch: finishMatch));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
        side: const BorderSide(color: AppPalette.line),
      ),
      title: Text('${widget.match.matchCode} · ${widget.court.code}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.match.categoryName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _DialogTeamHeader(
              teamOneLabel: widget.match.teamOneLabel,
              teamTwoLabel: widget.match.teamTwoLabel,
            ),
            const SizedBox(height: AppSpace.md),
            for (var index = 0; index < 3; index++) ...[
              _GameScoreRow(
                label: 'Game ${index + 1}',
                leftController: _teamOneControllers[index],
                rightController: _teamTwoControllers[index],
              ),
              if (index < 2) const SizedBox(height: AppSpace.sm),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: AppSpace.md),
              Text(
                _errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.apricot,
                ),
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
        OutlinedButton(
          onPressed: () => _submit(finishMatch: false),
          child: const Text('Save score'),
        ),
        FilledButton(
          onPressed: () => _submit(finishMatch: true),
          child: const Text('Finish match'),
        ),
      ],
    );
  }
}

final class _DialogTeamHeader extends StatelessWidget {
  const _DialogTeamHeader({
    required this.teamOneLabel,
    required this.teamTwoLabel,
  });

  final String teamOneLabel;
  final String teamTwoLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(teamOneLabel, style: theme.textTheme.titleMedium)),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Text(
            teamTwoLabel,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

final class _GameScoreRow extends StatelessWidget {
  const _GameScoreRow({
    required this.label,
    required this.leftController,
    required this.rightController,
  });

  final String label;
  final TextEditingController leftController;
  final TextEditingController rightController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: leftController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: '21', isDense: true),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Text(
          '-',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppPalette.inkSoft,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: TextField(
            controller: rightController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(hintText: '17', isDense: true),
          ),
        ),
      ],
    );
  }
}
