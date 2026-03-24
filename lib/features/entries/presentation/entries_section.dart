import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/team_identity.dart';
import '../../../theme/app_theme.dart';
import '../../categories/data/category_providers.dart';
import '../../categories/domain/category_item.dart';
import '../../tournaments/presentation/workspace_components.dart';
import '../data/entry_providers.dart';
import '../domain/entry.dart';

final class EntriesSection extends ConsumerStatefulWidget {
  const EntriesSection({
    super.key,
    required this.tournamentId,
    this.embedded = false,
  });

  final String tournamentId;
  final bool embedded;

  @override
  ConsumerState<EntriesSection> createState() => _EntriesSectionState();
}

enum _EntrySortMode { defaultOrder, uncheckedFirst }

class _EntriesSectionState extends ConsumerState<EntriesSection> {
  bool _isCreating = false;
  Set<String>? _busyEntryIdsState;
  final _EntrySortMode _sortMode = _EntrySortMode.uncheckedFirst;
  String? _selectedCategoryId;

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
    final categoryItems = categories.maybeWhen(
      data: (items) => items,
      orElse: () => const <CategoryItem>[],
    );
    final canCreateEntry = !_isCreating && categoryItems.isNotEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkspaceSectionLead(
          title: 'Team desk',
          description:
              'Onboard pairs, verify arrivals, and tidy the roster before matches begin.',
          icon: Icons.groups_rounded,
          accent: AppPalette.oliveStrong,
          trailing: FilledButton(
            onPressed: canCreateEntry
                ? () => _showCreateEntryDialog(
                    categories: categoryItems,
                    existingEntries: entries.asData?.value ?? const [],
                  )
                : null,
            child: Text(_isCreating ? 'Saving...' : 'Onboard team'),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        entries.when(
          data: (items) {
            if (items.isEmpty) {
              return const _EntriesEmptyState();
            }

            final categoryById = {
              for (final category in categoryItems) category.id: category,
            };
            final visibleItems = _visibleEntries(items, categoryById);
            final checkedInCount = visibleItems
                .where((entry) => entry.checkedIn)
                .length;
            final seededCount = visibleItems
                .where((entry) => entry.hasAssignedSeed)
                .length;

            if (_selectedCategoryId != null && visibleItems.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoryItems.length > 1) ...[
                    _CategoryFilterBar(
                      selectedCategoryId: _selectedCategoryId,
                      categories: categoryItems
                          .map(
                            (category) =>
                                (id: category.id, name: category.name),
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
                  _EntriesEmptyState(
                    title: 'No teams in this category yet',
                    message:
                        'Switch categories or onboard the first team into this category.',
                  ),
                ],
              );
            }

            final sortedItems = _sortEntries(visibleItems);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (categoryItems.length > 1) ...[
                  _CategoryFilterBar(
                    selectedCategoryId: _selectedCategoryId,
                    categories: categoryItems
                        .map(
                          (category) => (id: category.id, name: category.name),
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
                WorkspaceStatRail(
                  metrics: [
                    WorkspaceMetricItemData(
                      value: '${visibleItems.length}',
                      label: 'entries',
                      foreground: const Color(0xFF456F77),
                      isHighlighted: true,
                    ),
                    WorkspaceMetricItemData(
                      value: '$checkedInCount',
                      label: 'checked in',
                      foreground: const Color(0xFF5F7243),
                    ),
                    WorkspaceMetricItemData(
                      value: '$seededCount',
                      label: 'seeded',
                      foreground: const Color(0xFF8F6038),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                for (var index = 0; index < sortedItems.length; index++) ...[
                  _EntryRowCard(
                    entry: sortedItems[index],
                    isBusy: _busyEntryIds.contains(sortedItems[index].id),
                    onToggleCheckedIn: () =>
                        _toggleCheckedIn(sortedItems[index]),
                    onEdit: () => _showEditEntryDialog(
                      entry: sortedItems[index],
                      categories: categoryItems,
                      existingEntries: items
                          .where(
                            (candidate) =>
                                candidate.id != sortedItems[index].id,
                          )
                          .toList(growable: false),
                    ),
                    onDelete: () => _deleteEntry(sortedItems[index]),
                  ),
                  if (index < sortedItems.length - 1)
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

  List<TournamentEntry> _sortEntries(List<TournamentEntry> items) {
    if (_sortMode == _EntrySortMode.defaultOrder) {
      return items;
    }

    final sorted = List<TournamentEntry>.of(items);
    sorted.sort((a, b) {
      final checkedCompare = a.checkedIn == b.checkedIn
          ? 0
          : (a.checkedIn ? 1 : -1);
      if (checkedCompare != 0) {
        return checkedCompare;
      }

      if (a.hasAssignedSeed != b.hasAssignedSeed) {
        return a.hasAssignedSeed ? -1 : 1;
      }

      final seedA = a.seedNumber ?? 9999;
      final seedB = b.seedNumber ?? 9999;
      final seedCompare = seedA.compareTo(seedB);
      if (seedCompare != 0) {
        return seedCompare;
      }

      return a.displayLabel.toLowerCase().compareTo(
        b.displayLabel.toLowerCase(),
      );
    });
    return sorted;
  }

  List<TournamentEntry> _visibleEntries(
    List<TournamentEntry> items,
    Map<String, CategoryItem> categoryById,
  ) {
    final selectedCategoryId = _selectedCategoryId;
    if (selectedCategoryId == null) {
      return items;
    }
    final selectedCategoryName = categoryById[selectedCategoryId]?.name
        .trim()
        .toLowerCase();
    final filtered = items
        .where(
          (entry) =>
              entry.categoryId == selectedCategoryId ||
              (selectedCategoryName != null &&
                  entry.categoryName.trim().toLowerCase() ==
                      selectedCategoryName),
        )
        .toList(growable: false);
    return filtered;
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
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120C1511),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
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
            padding: const EdgeInsets.all(AppSpace.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 760;

                final infoBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (entry.teamName.trim().isNotEmpty &&
                        entry.rosterLabel.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        entry.rosterLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkSoft,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.md),
                    Wrap(
                      spacing: AppSpace.md,
                      runSpacing: AppSpace.xs,
                      children: [
                        _EntryMetaText(
                          label: entry.categoryName,
                          foreground: AppPalette.inkSoft,
                        ),
                      ],
                    ),
                  ],
                );

                final actionRow = Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    _EntryActionLink(
                      label: 'Edit',
                      icon: Icons.edit_outlined,
                      compact: isCompact,
                      onTap: isBusy ? null : onEdit,
                    ),
                    _EntryActionLink(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      compact: isCompact,
                      destructive: true,
                      onTap: isBusy ? null : onDelete,
                    ),
                  ],
                );

                final footer = Container(
                  margin: EdgeInsets.only(
                    top: isCompact ? AppSpace.sm : AppSpace.lg,
                  ),
                  padding: EdgeInsets.only(
                    top: isCompact ? AppSpace.sm : AppSpace.md,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppPalette.line)),
                  ),
                  child: isCompact
                      ? const SizedBox.shrink()
                      : Row(
                          children: [
                            actionRow,
                            const Spacer(),
                            _CheckInControl(
                              checkedIn: entry.checkedIn,
                              isBusy: isBusy,
                              onToggle: onToggleCheckedIn,
                            ),
                          ],
                        ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TeamAvatar(entry: entry),
                          const SizedBox(width: AppSpace.md),
                          Expanded(child: infoBlock),
                          const SizedBox(width: AppSpace.sm),
                          _CompactEntryUtilities(
                            checkedIn: entry.checkedIn,
                            isBusy: isBusy,
                            onToggleCheckedIn: onToggleCheckedIn,
                            actionRow: actionRow,
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TeamAvatar(entry: entry, compact: false),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [infoBlock, footer],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final class _EntryMetaText extends StatelessWidget {
  const _EntryMetaText({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: foreground),
    );
  }
}

final class _EntryActionLink extends StatelessWidget {
  const _EntryActionLink({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive
        ? const Color(0xFF9A5A49)
        : AppPalette.inkSoft;

    if (compact) {
      return Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 20,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: destructive
                  ? const Color(0x14C97D6B)
                  : AppPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: destructive ? const Color(0x33C97D6B) : AppPalette.line,
              ),
            ),
            child: Icon(icon, size: 16, color: foreground),
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

final class _CheckInControl extends StatelessWidget {
  const _CheckInControl({
    required this.checkedIn,
    required this.isBusy,
    required this.onToggle,
  });

  final bool checkedIn;
  final bool isBusy;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isBusy ? 'Updating...' : 'Arrival';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: checkedIn ? AppPalette.ink : AppPalette.inkSoft,
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        Checkbox(
          value: checkedIn,
          onChanged: isBusy ? null : (_) => onToggle(),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ignore: unused_element
final class _EntrySortButton extends StatelessWidget {
  const _EntrySortButton({required this.sortMode, required this.onSelected});

  final _EntrySortMode sortMode;
  final ValueChanged<_EntrySortMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_EntrySortMode>(
      tooltip: 'Sort teams',
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _EntrySortMode.uncheckedFirst,
          child: Text('Unchecked first'),
        ),
        PopupMenuItem(
          value: _EntrySortMode.defaultOrder,
          child: Text('Default order'),
        ),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppPalette.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 18, color: AppPalette.inkSoft),
            const SizedBox(width: AppSpace.xs),
            Text(
              sortMode == _EntrySortMode.uncheckedFirst
                  ? 'Unchecked first'
                  : 'Default order',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppPalette.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CompactEntryUtilities extends StatelessWidget {
  const _CompactEntryUtilities({
    required this.checkedIn,
    required this.isBusy,
    required this.onToggleCheckedIn,
    required this.actionRow,
  });

  final bool checkedIn;
  final bool isBusy;
  final VoidCallback onToggleCheckedIn;
  final Widget actionRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        actionRow,
        const SizedBox(height: AppSpace.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Arrival',
              style: theme.textTheme.bodySmall?.copyWith(
                color: checkedIn ? AppPalette.ink : AppPalette.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Checkbox(
              value: checkedIn,
              onChanged: isBusy ? null : (_) => onToggleCheckedIn(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}

final class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.entry, this.compact = true});

  final TournamentEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TeamIdentityAvatar(
      entry: entry,
      compact: compact,
      showSeedNumber: true,
    );
  }
}

final class _EntriesEmptyState extends StatelessWidget {
  const _EntriesEmptyState({
    this.title = 'No entries yet',
    this.message =
        'Start onboarding teams with roster names, category assignment, and optional seeds.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return WorkspaceEmptyCard(title: title, message: message);
  }
}

final class _EntriesErrorState extends StatelessWidget {
  const _EntriesErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WorkspaceErrorCard(
      title: 'Entries need attention',
      message: message,
    );
  }
}

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'This organizer account cannot update entries yet. Reload and try again.';
  }
  if (message.contains('failed-precondition')) {
    return 'Entry data is not ready yet in this environment. Try again in a moment.';
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
          color: selected ? AppPalette.sageSoft : AppPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppPalette.sage.withValues(alpha: 0.4)
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
