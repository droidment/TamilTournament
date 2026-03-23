import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../categories/data/category_providers.dart';
import '../../categories/domain/category_item.dart';
import '../data/entry_providers.dart';
import '../domain/entry.dart';

final class EntriesSection extends ConsumerStatefulWidget {
  const EntriesSection({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<EntriesSection> createState() => _EntriesSectionState();
}

class _EntriesSectionState extends ConsumerState<EntriesSection> {
  bool _isCreating = false;
  Set<String>? _busyEntryIdsState;

  Set<String> get _busyEntryIds => _busyEntryIdsState ??= <String>{};

  Future<void> _showCreateEntryDialog({
    required List<CategoryItem> categories,
    required List<TournamentEntry> existingEntries,
  }) async {
    final draft = await showDialog<_CreateEntryDraftData>(
      context: context,
      builder: (context) => _CreateEntryDraftDialog(
        categories: categories,
        existingEntries: existingEntries,
      ),
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
        throw StateError('You must be signed in to create an entry.');
      }
      await ref
          .read(entryRepositoryProvider)
          .createEntryDraft(
            tournamentId: widget.tournamentId,
            categoryId: draft.category.id,
            teamName: draft.teamName,
            playerOne: draft.playerOne,
            playerTwo: draft.playerTwo,
            seedNumber: draft.seedNumber,
            categoryName: draft.category.name,
            checkedIn: draft.checkedIn,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.checkedIn
                ? 'Team onboarded and checked in.'
                : 'Team onboarded.',
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
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _toggleCheckedIn(TournamentEntry entry) async {
    if (_busyEntryIds.contains(entry.id)) {
      return;
    }
    setState(() {
      _busyEntryIds.add(entry.id);
    });
    try {
      await ref
          .read(entryRepositoryProvider)
          .setCheckedIn(
            tournamentId: widget.tournamentId,
            entryId: entry.id,
            categoryId: entry.categoryId,
            checkedIn: !entry.checkedIn,
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
          _busyEntryIds.remove(entry.id);
        });
      }
    }
  }

  Future<void> _showEditEntryDialog({
    required TournamentEntry entry,
    required List<CategoryItem> categories,
    required List<TournamentEntry> existingEntries,
  }) async {
    final draft = await showDialog<_CreateEntryDraftData>(
      context: context,
      builder: (context) => _CreateEntryDraftDialog(
        categories: categories,
        existingEntries: existingEntries,
        initialEntry: entry,
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    setState(() {
      _busyEntryIds.add(entry.id);
    });

    try {
      await ref
          .read(entryRepositoryProvider)
          .updateEntryDraft(
            tournamentId: widget.tournamentId,
            entryId: entry.id,
            categoryId: draft.category.id,
            teamName: draft.teamName,
            playerOne: draft.playerOne,
            playerTwo: draft.playerTwo,
            seedNumber: draft.seedNumber,
            categoryName: draft.category.name,
            checkedIn: draft.checkedIn,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Team updated.')));
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
          _busyEntryIds.remove(entry.id);
        });
      }
    }
  }

  Future<void> _deleteEntry(TournamentEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: const BorderSide(color: AppPalette.line),
        ),
        title: const Text('Delete team'),
        content: Text(
          'Remove ${entry.displayLabel} from ${entry.categoryName}? This also clears its current seed/check-in state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _busyEntryIds.add(entry.id);
    });

    try {
      await ref
          .read(entryRepositoryProvider)
          .deleteEntry(tournamentId: widget.tournamentId, entryId: entry.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Team deleted.')));
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
          _busyEntryIds.remove(entry.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider(widget.tournamentId));
    final categories = ref.watch(
      tournamentCategoriesProvider(widget.tournamentId),
    );
    final theme = Theme.of(context);
    final categoryItems = categories.maybeWhen(
      data: (items) => items,
      orElse: () => const <CategoryItem>[],
    );
    final canCreateEntry = !_isCreating && categoryItems.isNotEmpty;

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
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 760;

              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Player and team onboarding',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Capture teams, assign category seeds, and mark them checked in as they arrive.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkSoft,
                    ),
                  ),
                ],
              );

              final action = FilledButton(
                onPressed: canCreateEntry
                    ? () => _showCreateEntryDialog(
                        categories: categoryItems,
                        existingEntries: entries.asData?.value ?? const [],
                      )
                    : null,
                child: Text(_isCreating ? 'Saving...' : 'Onboard team'),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: AppSpace.md),
                    action,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: AppSpace.md),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.lg),
          entries.when(
            data: (items) {
              if (items.isEmpty) {
                return const _EntriesEmptyState();
              }

              final checkedInCount = items
                  .where((entry) => entry.checkedIn)
                  .length;
              final seededCount = items
                  .where((entry) => entry.hasAssignedSeed)
                  .length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    total: items.length,
                    checkedIn: checkedInCount,
                    seeded: seededCount,
                  ),
                  const SizedBox(height: AppSpace.md),
                  for (var index = 0; index < items.length; index++) ...[
                    _EntryRowCard(
                      entry: items[index],
                      isBusy: _busyEntryIds.contains(items[index].id),
                      onToggleCheckedIn: () => _toggleCheckedIn(items[index]),
                      onEdit: () => _showEditEntryDialog(
                        entry: items[index],
                        categories: categoryItems,
                        existingEntries: items
                            .where(
                              (candidate) => candidate.id != items[index].id,
                            )
                            .toList(growable: false),
                      ),
                      onDelete: () => _deleteEntry(items[index]),
                    ),
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
                _EntriesErrorState(message: _friendlyError(error)),
          ),
        ],
      ),
    );
  }
}

final class _CreateEntryDraftData {
  const _CreateEntryDraftData({
    required this.category,
    required this.teamName,
    required this.playerOne,
    required this.playerTwo,
    required this.seedNumber,
    required this.checkedIn,
  });

  final CategoryItem category;
  final String teamName;
  final String playerOne;
  final String playerTwo;
  final int? seedNumber;
  final bool checkedIn;
}

final class _CreateEntryDraftDialog extends StatefulWidget {
  const _CreateEntryDraftDialog({
    required this.categories,
    required this.existingEntries,
    this.initialEntry,
  });

  final List<CategoryItem> categories;
  final List<TournamentEntry> existingEntries;
  final TournamentEntry? initialEntry;

  @override
  State<_CreateEntryDraftDialog> createState() =>
      _CreateEntryDraftDialogState();
}

class _CreateEntryDraftDialogState extends State<_CreateEntryDraftDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _teamNameController;
  late final TextEditingController _playerOneController;
  late final TextEditingController _playerTwoController;
  late final TextEditingController _seedNumberController;
  late CategoryItem _selectedCategory;
  bool _checkedIn = false;

  @override
  void initState() {
    super.initState();
    final initialEntry = widget.initialEntry;
    _teamNameController = TextEditingController(
      text: initialEntry?.teamName ?? '',
    );
    _playerOneController = TextEditingController(
      text: initialEntry?.playerOne ?? '',
    );
    _playerTwoController = TextEditingController(
      text: initialEntry?.playerTwo ?? '',
    );
    _seedNumberController = TextEditingController(
      text: initialEntry?.seedNumber?.toString() ?? '',
    );
    final matchingCategories = widget.categories.where(
      (category) => category.id == initialEntry?.categoryId,
    );
    _selectedCategory = matchingCategories.isNotEmpty
        ? matchingCategories.first
        : widget.categories.first;
    _checkedIn = initialEntry?.checkedIn ?? false;
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _playerOneController.dispose();
    _playerTwoController.dispose();
    _seedNumberController.dispose();
    super.dispose();
  }

  bool _seedAlreadyTaken(int seedNumber) {
    return widget.existingEntries.any(
      (entry) =>
          entry.id != widget.initialEntry?.id &&
          entry.categoryId == _selectedCategory.id &&
          entry.seedNumber == seedNumber,
    );
  }

  int? _parsedSeedNumber() {
    final raw = _seedNumberController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(
      _CreateEntryDraftData(
        category: _selectedCategory,
        teamName: _teamNameController.text.trim(),
        playerOne: _playerOneController.text.trim(),
        playerTwo: _playerTwoController.text.trim(),
        seedNumber: _parsedSeedNumber(),
        checkedIn: _checkedIn,
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
      title: Text(widget.initialEntry == null ? 'Onboard team' : 'Edit team'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _teamNameController,
                  decoration: const InputDecoration(
                    labelText: 'Team name',
                    hintText: 'Chennai Smashers',
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                TextFormField(
                  controller: _playerOneController,
                  decoration: const InputDecoration(
                    labelText: 'Player one',
                    hintText: 'Arun',
                  ),
                  validator: _requiredField('Enter player one.'),
                ),
                const SizedBox(height: AppSpace.md),
                TextFormField(
                  controller: _playerTwoController,
                  decoration: const InputDecoration(
                    labelText: 'Player two',
                    hintText: 'Vimal',
                  ),
                  validator: _requiredField('Enter player two.'),
                ),
                const SizedBox(height: AppSpace.md),
                DropdownButtonFormField<CategoryItem>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Select a category.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.md),
                TextFormField(
                  controller: _seedNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Assigned seed',
                    hintText: 'Leave blank to auto-seed later',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return null;
                    }
                    final parsed = int.tryParse(trimmed);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a positive seed number.';
                    }
                    if (_seedAlreadyTaken(parsed)) {
                      return 'Seed #$parsed is already used in ${_selectedCategory.name}.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assigned seeds feed the scheduler auto-order once teams check in.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppPalette.inkMuted),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _checkedIn,
                  onChanged: (value) {
                    setState(() {
                      _checkedIn = value;
                    });
                  },
                  title: const Text('Mark as checked in now'),
                  subtitle: const Text(
                    'Use this when the team is already at the venue.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.initialEntry == null ? 'Save team' : 'Save changes',
          ),
        ),
      ],
    );
  }
}

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.total,
    required this.checkedIn,
    required this.seeded,
  });

  final int total;
  final int checkedIn;
  final int seeded;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        _SummaryChip(
          label: '$total entries',
          background: AppPalette.skySoft,
          border: AppPalette.sky.withValues(alpha: 0.4),
          foreground: const Color(0xFF456F77),
        ),
        _SummaryChip(
          label: '$checkedIn checked in',
          background: AppPalette.oliveSoft,
          border: AppPalette.oliveStrong.withValues(alpha: 0.4),
          foreground: const Color(0xFF5F7243),
        ),
        _SummaryChip(
          label: '$seeded seeded',
          background: AppPalette.apricotSoft,
          border: AppPalette.apricot.withValues(alpha: 0.4),
          foreground: const Color(0xFF8F6038),
        ),
      ],
    );
  }
}

final class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
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

final class _EntryRowCard extends StatelessWidget {
  const _EntryRowCard({
    required this.entry,
    required this.isBusy,
    required this.onToggleCheckedIn,
    required this.onEdit,
    required this.onDelete,
  });

  final TournamentEntry entry;
  final bool isBusy;
  final VoidCallback onToggleCheckedIn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = entry.checkedIn ? AppPalette.sageStrong : AppPalette.sky;

    return Container(
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
            child: Wrap(
              spacing: AppSpace.md,
              runSpacing: AppSpace.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 220,
                    maxWidth: 520,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayLabel,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (entry.teamName.trim().isNotEmpty &&
                          entry.rosterLabel.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          entry.rosterLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppPalette.ink,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.sm),
                      Wrap(
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        children: [
                          _StateChip(
                            label: entry.categoryName,
                            background: AppPalette.surface,
                            border: AppPalette.line,
                            foreground: AppPalette.inkSoft,
                          ),
                          if (entry.hasAssignedSeed)
                            _StateChip(
                              label: 'Seed #${entry.seedNumber}',
                              background: AppPalette.apricotSoft,
                              border: AppPalette.apricot.withValues(
                                alpha: 0.45,
                              ),
                              foreground: const Color(0xFF8F6038),
                            ),
                          _StateChip(
                            label: entry.checkedIn ? 'Checked in' : 'Waiting',
                            background: entry.checkedIn
                                ? const Color(0x2F98BFA6)
                                : const Color(0x268DBEC6),
                            border: accent.withValues(alpha: 0.45),
                            foreground: AppPalette.ink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 176,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Wrap(
                        spacing: AppSpace.xs,
                        runSpacing: AppSpace.xs,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: isBusy ? null : onEdit,
                            child: const Text('Edit'),
                          ),
                          OutlinedButton(
                            onPressed: isBusy ? null : onDelete,
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isBusy ? 'Updating...' : 'Checked in',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppPalette.inkSoft,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Checkbox(
                            value: entry.checkedIn,
                            onChanged: isBusy
                                ? null
                                : (_) => onToggleCheckedIn(),
                          ),
                        ],
                      ),
                    ],
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

final class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
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

final class _EntriesEmptyState extends StatelessWidget {
  const _EntriesEmptyState();

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
          Text('No entries yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Start onboarding teams with roster names, category assignment, and optional seeds.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _EntriesErrorState extends StatelessWidget {
  const _EntriesErrorState({required this.message});

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
            'Entries need attention',
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

String? Function(String?) _requiredField(String message) {
  return (value) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  };
}
