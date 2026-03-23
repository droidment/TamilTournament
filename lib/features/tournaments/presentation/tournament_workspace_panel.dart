import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../data/tournament_providers.dart';
import '../domain/tournament.dart';

final class TournamentWorkspacePanel extends ConsumerStatefulWidget {
  const TournamentWorkspacePanel({super.key});

  @override
  ConsumerState<TournamentWorkspacePanel> createState() =>
      _TournamentWorkspacePanelState();
}

class _TournamentWorkspacePanelState
    extends ConsumerState<TournamentWorkspacePanel> {
  bool _isCreating = false;

  Future<void> _showCreateTournamentDialog() async {
    final draft = await showDialog<_CreateTournamentDraftData>(
      context: context,
      builder: (context) => const _CreateTournamentDraftDialog(),
    );

    if (draft == null || !mounted) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('You must be signed in to create a tournament.');
      }
      await ref
          .read(tournamentRepositoryProvider)
          .createDraftTournament(
            organizerUid: user.uid,
            name: draft.name,
            venue: draft.venue,
            startDate: draft.startDate,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tournament draft created.')),
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
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(ownedTournamentsProvider);
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tournament workspace',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'This is the first Firestore-backed slice: create and track organizer-owned tournament drafts.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _isCreating ? null : _showCreateTournamentDialog,
                child: Text(_isCreating ? 'Creating...' : 'New tournament'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          tournaments.when(
            data: (items) {
              if (items.isEmpty) {
                return const _TournamentEmptyState();
              }
              return Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    _TournamentRowCard(tournament: items[index]),
                    if (index < items.length - 1)
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
            error: (error, _) =>
                _TournamentErrorState(message: _friendlyError(error)),
          ),
        ],
      ),
    );
  }
}

final class _CreateTournamentDraftData {
  const _CreateTournamentDraftData({
    required this.name,
    required this.venue,
    required this.startDate,
  });

  final String name;
  final String venue;
  final DateTime startDate;
}

final class _CreateTournamentDraftDialog extends StatefulWidget {
  const _CreateTournamentDraftDialog();

  @override
  State<_CreateTournamentDraftDialog> createState() =>
      _CreateTournamentDraftDialogState();
}

class _CreateTournamentDraftDialogState
    extends State<_CreateTournamentDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _venueController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (pickedDate == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(
      _CreateTournamentDraftData(
        name: _nameController.text.trim(),
        venue: _venueController.text.trim(),
        startDate: _selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
        side: const BorderSide(color: AppPalette.line),
      ),
      title: const Text('Create tournament draft'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tournament name',
                  hintText: 'Tamil Open 2026',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a tournament name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.md),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  hintText: 'Community center or school gym',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a venue.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Start date',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              OutlinedButton(
                onPressed: _pickStartDate,
                child: Text(_formatDate(_selectedDate)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create draft')),
      ],
    );
  }
}

final class _TournamentRowCard extends StatelessWidget {
  const _TournamentRowCard({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (tournament.status) {
      TournamentStatus.draft => AppPalette.sky,
      TournamentStatus.setup => AppPalette.apricot,
      TournamentStatus.live => AppPalette.sageStrong,
      TournamentStatus.completed => AppPalette.oliveStrong,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/tournaments/${tournament.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppPalette.line),
          ),
          child: Column(
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
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            '${tournament.venue} · ${_formatDate(tournament.startDate)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Wrap(
                        spacing: AppSpace.sm,
                        runSpacing: AppSpace.sm,
                        alignment: WrapAlignment.end,
                        children: [
                          _WorkspaceChip(
                            label: tournament.status.label,
                            tint: accent.withValues(alpha: 0.18),
                            border: accent.withValues(alpha: 0.45),
                            foreground: AppPalette.ink,
                          ),
                          _WorkspaceChip(
                            label: '${tournament.stats.categories} categories',
                            tint: AppPalette.skySoft,
                            border: AppPalette.sky.withValues(alpha: 0.45),
                            foreground: const Color(0xFF456F77),
                          ),
                          _WorkspaceChip(
                            label: '${tournament.stats.entries} entries',
                            tint: AppPalette.oliveSoft,
                            border: AppPalette.oliveStrong.withValues(
                              alpha: 0.45,
                            ),
                            foreground: const Color(0xFF5F7243),
                          ),
                          _WorkspaceChip(
                            label: '${tournament.stats.matches} matches',
                            tint: AppPalette.apricotSoft,
                            border: AppPalette.apricot.withValues(alpha: 0.45),
                            foreground: const Color(0xFF8F6038),
                          ),
                        ],
                      ),
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

final class _WorkspaceChip extends StatelessWidget {
  const _WorkspaceChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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

final class _TournamentEmptyState extends StatelessWidget {
  const _TournamentEmptyState();

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
          Text('No tournaments yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Create your first tournament draft to start wiring categories, entries, and scheduling against real Firestore data.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _TournamentErrorState extends StatelessWidget {
  const _TournamentErrorState({required this.message});

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
            'Firestore needs attention',
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
    return 'Deploy the Firestore rules in this repo, then reload the app.';
  }
  if (message.contains('failed-precondition')) {
    return 'Create the Firestore database in Firebase Console first, then reload the app.';
  }
  return message;
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
