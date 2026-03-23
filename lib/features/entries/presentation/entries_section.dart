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

  Future<void> _showCreateEntryDialog(List<CategoryItem> categories) async {
    final formKey = GlobalKey<FormState>();
    final playerOneController = TextEditingController();
    final playerTwoController = TextEditingController();
    var selectedCategory = categories.first;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppPalette.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.panel),
                side: const BorderSide(color: AppPalette.line),
              ),
              title: const Text('Create entry draft'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: playerOneController,
                        decoration: const InputDecoration(
                          labelText: 'Player one',
                          hintText: 'Arun',
                        ),
                        validator: _requiredField('Enter player one.'),
                      ),
                      const SizedBox(height: AppSpace.md),
                      TextFormField(
                        controller: playerTwoController,
                        decoration: const InputDecoration(
                          labelText: 'Player two',
                          hintText: 'Vimal',
                        ),
                        validator: _requiredField('Enter player two.'),
                      ),
                      const SizedBox(height: AppSpace.md),
                      DropdownButtonFormField<CategoryItem>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories
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
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Select a category.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Entries will be stored against the selected category id.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppPalette.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) {
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Create draft'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldCreate != true || !mounted) {
      playerOneController.dispose();
      playerTwoController.dispose();
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
            categoryId: selectedCategory.id,
            playerOne: playerOneController.text,
            playerTwo: playerTwoController.text,
            categoryName: selectedCategory.name,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entry draft created.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    } finally {
      playerOneController.dispose();
      playerTwoController.dispose();
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _toggleCheckedIn(TournamentEntry entry) async {
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entries and check-in',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Create pair drafts, then mark them checked in when they reach the venue.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: canCreateEntry
                    ? () => _showCreateEntryDialog(categoryItems)
                    : null,
                child: Text(_isCreating ? 'Creating...' : 'New entry'),
              ),
            ],
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(total: items.length, checkedIn: checkedInCount),
                  const SizedBox(height: AppSpace.md),
                  for (var index = 0; index < items.length; index++) ...[
                    _EntryRowCard(
                      entry: items[index],
                      onToggleCheckedIn: () => _toggleCheckedIn(items[index]),
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

final class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.total, required this.checkedIn});

  final int total;
  final int checkedIn;

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
  const _EntryRowCard({required this.entry, required this.onToggleCheckedIn});

  final TournamentEntry entry;
  final VoidCallback onToggleCheckedIn;

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.playerOne} / ${entry.playerTwo}',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        entry.categoryName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StateChip(
                      label: entry.checkedIn ? 'Checked in' : 'Waiting',
                      background: entry.checkedIn
                          ? const Color(0x2F98BFA6)
                          : const Color(0x268DBEC6),
                      border: accent.withValues(alpha: 0.45),
                      foreground: AppPalette.ink,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Checkbox(
                      value: entry.checkedIn,
                      onChanged: (_) => onToggleCheckedIn(),
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
            'Create the first pair draft for this tournament, then start marking players checked in when they arrive.',
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
