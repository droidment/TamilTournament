import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../data/court_providers.dart';
import '../domain/tournament_court.dart';

final class CourtManagementSection extends ConsumerStatefulWidget {
  const CourtManagementSection({
    super.key,
    required this.tournamentId,
    required this.initialCourtCount,
  });

  final String tournamentId;
  final int initialCourtCount;

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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Courts', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Set the active court pool before live scheduling begins, then pause or restore courts as the venue changes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              courts.whenOrNull(
                    data: (items) {
                      final available = items
                          .where((court) => court.isAvailable)
                          .length;
                      return Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        children: [
                          _CourtSummaryChip(
                            label: '${items.length} total',
                            tint: AppPalette.skySoft,
                            border: AppPalette.sky.withValues(alpha: 0.35),
                            foreground: const Color(0xFF456F77),
                          ),
                          _CourtSummaryChip(
                            label: '$available active',
                            tint: AppPalette.sageSoft,
                            border: AppPalette.sage.withValues(alpha: 0.35),
                            foreground: const Color(0xFF365141),
                          ),
                          _CourtSummaryChip(
                            label: '${items.length - available} paused',
                            tint: AppPalette.apricotSoft,
                            border: AppPalette.apricot.withValues(alpha: 0.35),
                            foreground: const Color(0xFF8F6038),
                          ),
                        ],
                      );
                    },
                  ) ??
                  const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          _CourtSetupBar(
            controller: _courtCountController,
            isGenerating: _isGenerating,
            onGenerate: _generateCourts,
          ),
          const SizedBox(height: AppSpace.lg),
          courts.when(
            data: (items) {
              _syncConfiguredCourtCount(items);
              if (items.isEmpty) {
                return const _CourtEmptyState();
              }
              return Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.md,
                children: [
                  for (final court in items)
                    _CourtCard(
                      court: court,
                      isBusy: _busyCourtIds.contains(court.id),
                      onToggleAvailability: () => _toggleCourt(court),
                      onEditDetails: () => _editCourtDetails(court),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) =>
                _CourtErrorState(message: _friendlyError(error)),
          ),
        ],
      ),
    );
  }
}

final class _CourtSetupBar extends StatelessWidget {
  const _CourtSetupBar({
    required this.controller,
    required this.isGenerating,
    required this.onGenerate,
  });

  final TextEditingController controller;
  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.line),
      ),
      child: Wrap(
        spacing: AppSpace.md,
        runSpacing: AppSpace.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Court count',
                hintText: '10',
              ),
            ),
          ),
          FilledButton(
            onPressed: isGenerating ? null : onGenerate,
            child: Text(isGenerating ? 'Saving...' : 'Generate courts'),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'Generating keeps `C1..Cn`, preserves edited names and notes, and trims only courts above the new limit.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

final class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.court,
    required this.isBusy,
    required this.onToggleAvailability,
    required this.onEditDetails,
  });

  final TournamentCourt court;
  final bool isBusy;
  final VoidCallback onToggleAvailability;
  final VoidCallback onEditDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = court.isAvailable
        ? AppPalette.sageStrong
        : AppPalette.apricot;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
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
                _CourtSummaryChip(
                  label: court.status.label,
                  tint: court.isAvailable
                      ? AppPalette.sageSoft
                      : AppPalette.apricotSoft,
                  border: accent.withValues(alpha: 0.35),
                  foreground: court.isAvailable
                      ? const Color(0xFF365141)
                      : const Color(0xFF8F6038),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  court.note.trim().isEmpty
                      ? 'No operational note yet.'
                      : court.note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: court.note.trim().isEmpty
                        ? AppPalette.inkMuted
                        : AppPalette.inkSoft,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    OutlinedButton(
                      onPressed: isBusy ? null : onEditDetails,
                      child: const Text('Edit court'),
                    ),
                    FilledButton(
                      onPressed: isBusy ? null : onToggleAvailability,
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
          ),
        ],
      ),
    );
  }
}

final class _CourtSummaryChip extends StatelessWidget {
  const _CourtSummaryChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

final class _CourtEmptyState extends StatelessWidget {
  const _CourtEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No courts configured', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Start by generating the productive court pool for this tournament.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _CourtErrorState extends StatelessWidget {
  const _CourtErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: const Color(0x24C97D6B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x47C97D6B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Courts need attention',
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF7B4D42),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7B4D42),
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'Deploy the updated Firestore rules, then reload the app.';
  }
  if (message.contains('failed-precondition')) {
    return 'Create the Firestore database in Firebase Console first, then reload the app.';
  }
  return message;
}
