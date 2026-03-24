import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/presentation/team_identity.dart';
import '../../../theme/app_theme.dart';
import '../../categories/domain/category_item.dart';
import '../../entries/domain/entry.dart';
import '../../tournaments/presentation/workspace_components.dart';
import '../data/scheduling_seed_providers.dart';
import '../domain/scheduling_seed.dart';

final class SchedulingSeedSection extends ConsumerStatefulWidget {
  const SchedulingSeedSection({
    super.key,
    required this.tournamentId,
    this.embedded = false,
  });

  final String tournamentId;
  final bool embedded;

  @override
  ConsumerState<SchedulingSeedSection> createState() =>
      _SchedulingSeedSectionState();
}

final class _SchedulingSeedSectionState
    extends ConsumerState<SchedulingSeedSection> {
  final Map<String, List<String>> _draftSeedIdsByCategory =
      <String, List<String>>{};
  final Set<String> _savingCategoryIds = <String>{};
  bool _isSavingAll = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(schedulingSeedStateProvider(widget.tournamentId));
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WorkspaceSectionLead(
          title: 'Seeding board',
          description:
              'Adjust the live seed order per category and save it for scheduling.',
          icon: Icons.format_list_numbered_rounded,
          accent: AppPalette.apricot,
        ),
        const SizedBox(height: AppSpace.md),
        state.when(
          data: (snapshot) {
            _syncLocalDrafts(snapshot);
            if (snapshot.isEmpty) {
              return const _SchedulingSeedEmptyState();
            }

            final editedCount = _editedCategoryCount(snapshot);
            final pendingSaveCount = _pendingSaveCount(snapshot);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (editedCount > 0 || pendingSaveCount > 0) ...[
                  _SeedDraftBanner(
                    title: editedCount > 0
                        ? 'Unsaved seed changes are waiting'
                        : 'Check-in updates need a save',
                    message: editedCount > 0
                        ? 'Your local seed edits are already reflected in the preview below. Save them when the order looks right.'
                        : 'New check-ins changed the effective order for one or more categories. Save again to keep the scheduler aligned.',
                    tint: editedCount > 0
                        ? AppPalette.apricotSoft
                        : AppPalette.sageSoft,
                    border: editedCount > 0
                        ? AppPalette.apricot.withValues(alpha: 0.35)
                        : AppPalette.sage.withValues(alpha: 0.35),
                    foreground: editedCount > 0
                        ? const Color(0xFF8F6038)
                        : const Color(0xFF365141),
                    actions: [
                      OutlinedButton(
                        onPressed: (editedCount > 0 || pendingSaveCount > 0)
                            ? _resetAll
                            : null,
                        child: const Text('Reset all'),
                      ),
                      FilledButton(
                        onPressed: _isSavingAll
                            ? null
                            : () async {
                                FocusManager.instance.primaryFocus?.unfocus();
                                await Future<void>.delayed(Duration.zero);
                                await _saveAll(snapshot);
                              },
                        child: Text(_isSavingAll ? 'Saving...' : 'Save all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                ],
                for (
                  var index = 0;
                  index < snapshot.readyCategories.length;
                  index++
                ) ...[
                  _EditableSeedCategoryCard(
                    category: snapshot.readyCategories[index],
                    orderedEntries: _orderedEntries(
                      snapshot.readyCategories[index],
                    ),
                    isEdited: _isCategoryEdited(
                      snapshot.readyCategories[index],
                    ),
                    isSaving: _savingCategoryIds.contains(
                      snapshot.readyCategories[index].categoryId,
                    ),
                    needsSave: _categoryNeedsSave(
                      snapshot.readyCategories[index],
                    ),
                    onSetSeedPosition: (fromIndex, seedNumber) =>
                        _setSeedPosition(
                          category: snapshot.readyCategories[index],
                          fromIndex: fromIndex,
                          requestedSeedNumber: seedNumber,
                        ),
                    onResetCategory: () =>
                        _resetCategory(snapshot.readyCategories[index]),
                    onAutoSeedCategory: () =>
                        _autoSeedCategory(snapshot.readyCategories[index]),
                    onSaveCategory: () =>
                        _saveCategory(snapshot.readyCategories[index]),
                  ),
                  if (index < snapshot.readyCategories.length - 1)
                    const SizedBox(height: AppSpace.md),
                ],
              ],
            );
          },
          loading: () => const _SchedulingSeedLoadingState(),
          error: (error, _) => _SchedulingSeedErrorState(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(
              schedulingSeedStateProvider(widget.tournamentId),
            ),
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

  void _syncLocalDrafts(SchedulingSeedSnapshot snapshot) {
    final nextDrafts = <String, List<String>>{};
    var changed = false;

    for (final category in snapshot.readyCategories) {
      final draft = _draftSeedIdsByCategory[category.categoryId];
      if (draft == null) {
        continue;
      }
      final normalized = _normalizeSeedIds(
        requestedSeedIds: draft,
        checkedInEntries: category.checkedInEntries,
      );
      if (!_sameIds(normalized, category.seedEntryIds)) {
        nextDrafts[category.categoryId] = normalized;
      }
      if (!_sameIds(draft, normalized) ||
          (_sameIds(normalized, category.seedEntryIds) &&
              _draftSeedIdsByCategory.containsKey(category.categoryId))) {
        changed = true;
      }
    }

    final removedKeys = _draftSeedIdsByCategory.keys.where(
      (key) => !snapshot.readyCategories.any(
        (category) => category.categoryId == key,
      ),
    );
    if (removedKeys.isNotEmpty) {
      changed = true;
    }

    if (!changed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _draftSeedIdsByCategory
          ..clear()
          ..addAll(nextDrafts);
      });
    });
  }

  int _editedCategoryCount(SchedulingSeedSnapshot snapshot) {
    return snapshot.readyCategories
        .where((category) => _isCategoryEdited(category))
        .length;
  }

  int _pendingSaveCount(SchedulingSeedSnapshot snapshot) {
    return snapshot.readyCategories
        .where((category) => _categoryNeedsSave(category))
        .length;
  }

  bool _categoryNeedsSave(ReadyCategorySeed category) {
    if (_isCategoryEdited(category)) {
      return true;
    }
    if (!category.hasSavedSeedPlan) {
      return true;
    }
    return !_sameIds(
      category.seedEntryIds,
      category.seedPlan?.seedEntryIds ?? const <String>[],
    );
  }

  bool _isCategoryEdited(ReadyCategorySeed category) {
    return !_sameIds(_effectiveSeedIds(category), category.seedEntryIds);
  }

  List<String> _effectiveSeedIds(ReadyCategorySeed category) {
    return _normalizeSeedIds(
      requestedSeedIds:
          _draftSeedIdsByCategory[category.categoryId] ?? category.seedEntryIds,
      checkedInEntries: category.checkedInEntries,
    );
  }

  List<TournamentEntry> _orderedEntries(ReadyCategorySeed category) {
    final entryById = <String, TournamentEntry>{
      for (final entry in category.checkedInEntries) entry.id: entry,
    };
    return _effectiveSeedIds(category)
        .map((entryId) => entryById[entryId])
        .whereType<TournamentEntry>()
        .toList(growable: false);
  }

  void _setSeedPosition({
    required ReadyCategorySeed category,
    required int fromIndex,
    required int requestedSeedNumber,
  }) {
    final seedIds = List<String>.from(_effectiveSeedIds(category));
    if (fromIndex < 0 || fromIndex >= seedIds.length) {
      return;
    }

    final toIndex = requestedSeedNumber.clamp(1, seedIds.length) - 1;
    if (toIndex == fromIndex) {
      return;
    }

    final moved = seedIds.removeAt(fromIndex);
    seedIds.insert(toIndex, moved);
    setState(() {
      _draftSeedIdsByCategory[category.categoryId] = seedIds;
    });
  }

  void _resetCategory(ReadyCategorySeed category) {
    setState(() {
      _draftSeedIdsByCategory.remove(category.categoryId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${category.categoryName} reverted to saved order.'),
      ),
    );
  }

  Future<void> _autoSeedCategory(ReadyCategorySeed category) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: const BorderSide(color: AppPalette.line),
        ),
        title: const Text('Replace this seeding?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto-seed will replace the current order for ${category.categoryName}.',
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'This can reshuffle manual seeds, change the matchup preview, and disrupt any schedule that depends on this order after you save.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
            ),
            if (category.hasSavedSeedPlan || _isCategoryEdited(category)) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                'Use this only when you want to discard the current manual arrangement.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8F6038),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace order'),
          ),
        ],
      ),
    );

    if (shouldProceed != true || !mounted) {
      return;
    }

    final suggested = category.suggestedSeedEntryIds;
    setState(() {
      _draftSeedIdsByCategory[category.categoryId] = suggested;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${category.categoryName} reset to auto-seed order.'),
      ),
    );
  }

  void _resetAll() {
    setState(() {
      _draftSeedIdsByCategory.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seed changes reset to the saved state.')),
    );
  }

  Future<void> _saveCategory(ReadyCategorySeed category) async {
    if (_savingCategoryIds.contains(category.categoryId)) {
      return;
    }

    setState(() {
      _savingCategoryIds.add(category.categoryId);
    });

    try {
      await ref
          .read(schedulingSeedRepositoryProvider)
          .saveSeedPlan(
            tournamentId: widget.tournamentId,
            categoryId: category.categoryId,
            categoryName: category.categoryName,
            format: category.format,
            checkedInEntries: category.checkedInEntries,
            seedEntryIds: _effectiveSeedIds(category),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _draftSeedIdsByCategory.remove(category.categoryId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${category.categoryName} seed plan saved.')),
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
          _savingCategoryIds.remove(category.categoryId);
        });
      }
    }
  }

  Future<void> _saveAll(SchedulingSeedSnapshot snapshot) async {
    final categoriesToSave = snapshot.readyCategories
        .where((category) => _categoryNeedsSave(category))
        .toList(growable: false);
    if (categoriesToSave.isEmpty || _isSavingAll) {
      return;
    }

    setState(() {
      _isSavingAll = true;
      _savingCategoryIds.addAll(
        categoriesToSave.map((category) => category.categoryId),
      );
    });

    try {
      for (final category in categoriesToSave) {
        await ref
            .read(schedulingSeedRepositoryProvider)
            .saveSeedPlan(
              tournamentId: widget.tournamentId,
              categoryId: category.categoryId,
              categoryName: category.categoryName,
              format: category.format,
              checkedInEntries: category.checkedInEntries,
              seedEntryIds: _effectiveSeedIds(category),
            );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        for (final category in categoriesToSave) {
          _draftSeedIdsByCategory.remove(category.categoryId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${categoriesToSave.length} seed plan(s).'),
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
          _isSavingAll = false;
          for (final category in categoriesToSave) {
            _savingCategoryIds.remove(category.categoryId);
          }
        });
      }
    }
  }
}

final class _EditableSeedCategoryCard extends StatelessWidget {
  const _EditableSeedCategoryCard({
    required this.category,
    required this.orderedEntries,
    required this.isEdited,
    required this.isSaving,
    required this.needsSave,
    required this.onSetSeedPosition,
    required this.onResetCategory,
    required this.onAutoSeedCategory,
    required this.onSaveCategory,
  });

  final ReadyCategorySeed category;
  final List<TournamentEntry> orderedEntries;
  final bool isEdited;
  final bool isSaving;
  final bool needsSave;
  final void Function(int fromIndex, int seedNumber) onSetSeedPosition;
  final VoidCallback onResetCategory;
  final VoidCallback onAutoSeedCategory;
  final VoidCallback onSaveCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (category.format) {
      CategoryFormat.knockout => AppPalette.apricot,
      CategoryFormat.group => AppPalette.sageStrong,
    };
    final matchups = _buildDraftMatchups(orderedEntries);
    final actionRow = Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton(
          onPressed: onAutoSeedCategory,
          child: const Text('Auto-seed'),
        ),
        OutlinedButton(onPressed: onResetCategory, child: const Text('Reset')),
        FilledButton(
          onPressed: isSaving
              ? null
              : () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  await Future<void>.delayed(Duration.zero);
                  onSaveCategory();
                },
          child: Text(isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );

    return WorkspaceSurfaceCard(
      accent: accent,
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 780;

              // ignore: unused_local_variable
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.categoryName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category.formatLabel} · ${category.checkedInCount} checked in',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppPalette.inkSoft,
                    ),
                  ),
                ],
              );

              final summaryLabel = [
                category.formatLabel,
                '${category.checkedInCount} checked in',
                '${orderedEntries.length} slots',
                if (needsSave) 'needs save',
                if (isEdited) 'edited',
              ].join(' · ');

              if (isCompact) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: actionRow,
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.categoryName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summaryLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppPalette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Flexible(child: actionRow),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.md),
          Column(
            children: [
              for (var index = 0; index < orderedEntries.length; index++) ...[
                _SeedEntryTile(
                  entry: orderedEntries[index],
                  currentSeedNumber: index + 1,
                  originalSeedNumber:
                      category.suggestedSeedEntryIds.indexOf(
                        orderedEntries[index].id,
                      ) +
                      1,
                  onSeedSubmitted: (seedNumber) =>
                      onSetSeedPosition(index, seedNumber),
                ),
                if (index < orderedEntries.length - 1)
                  const SizedBox(height: AppSpace.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text('Matchup preview', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Column(
            children: [
              for (var index = 0; index < matchups.length; index++) ...[
                _MatchupPreviewTile(matchup: matchups[index]),
                if (index < matchups.length - 1)
                  const SizedBox(height: AppSpace.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final class _SeedEntryTile extends StatelessWidget {
  const _SeedEntryTile({
    required this.entry,
    required this.currentSeedNumber,
    required this.originalSeedNumber,
    required this.onSeedSubmitted,
  });

  final TournamentEntry entry;
  final int currentSeedNumber;
  final int originalSeedNumber;
  final ValueChanged<int> onSeedSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMoved = currentSeedNumber != originalSeedNumber;
    final palette = TeamIdentity.paletteForEntry(entry);
    final rowGradient = TeamIdentity.surfaceGradientForEntry(entry);
    final rowBorder = TeamIdentity.surfaceBorderForEntry(entry);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rowGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rowBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SeedPositionInput(
            value: currentSeedNumber,
            accent: palette.accent,
            onSubmitted: onSeedSubmitted,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _entryLabel(entry),
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.15),
                ),
                if (entry.teamName.trim().isNotEmpty &&
                    entry.rosterLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.rosterLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkMuted,
                    ),
                  ),
                ],
                if (hasMoved) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Was #$originalSeedNumber',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          TeamIdentityAvatar(entry: entry, size: 46, radius: 16),
        ],
      ),
    );
  }
}

final class _MatchupPreviewTile extends StatelessWidget {
  const _MatchupPreviewTile({required this.matchup});

  final _DraftMatchupPreview matchup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowGradient = TeamIdentity.surfaceGradientForMatch(
      matchup.teamOne,
      matchup.teamTwo,
    );
    final rowBorder = TeamIdentity.surfaceBorderForMatch(
      matchup.teamOne,
      matchup.teamTwo,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rowGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rowBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppPalette.oliveStrong.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'M${matchup.matchNumber}',
              style: AppTheme.numeric(
                theme.textTheme.labelSmall,
              ).copyWith(color: const Color(0xFF5F7243)),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TeamIdentityAvatar(
                      entry: matchup.teamOne,
                      size: 24,
                      radius: 9,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        matchup.teamOne.displayLabel,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (!matchup.hasBye) ...[
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      TeamIdentityAvatar(
                        entry: matchup.teamTwo!,
                        size: 24,
                        radius: 9,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          matchup.teamTwo!.displayLabel,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ],
                if (matchup.hasBye) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Waiting for one more team.',
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
  }
}

final class _DraftMatchupPreview {
  const _DraftMatchupPreview({
    required this.matchNumber,
    required this.teamOne,
    required this.teamTwo,
    required this.hasBye,
  });

  final int matchNumber;
  final TournamentEntry teamOne;
  final TournamentEntry? teamTwo;
  final bool hasBye;
}

final class _SeedPositionInput extends StatefulWidget {
  const _SeedPositionInput({
    required this.value,
    required this.accent,
    required this.onSubmitted,
  });

  final int value;
  final Color accent;
  final ValueChanged<int> onSubmitted;

  @override
  State<_SeedPositionInput> createState() => _SeedPositionInputState();
}

final class _SeedPositionInputState extends State<_SeedPositionInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _submit();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SeedPositionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != '${widget.value}') {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0) {
      _controller.text = '${widget.value}';
      return;
    }
    widget.onSubmitted(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              onSubmitted: (_) => _submit(),
              onEditingComplete: () {
                _submit();
                _focusNode.unfocus();
              },
              onTapOutside: (_) {
                _submit();
                _focusNode.unfocus();
              },
              onTap: () => _controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controller.text.length,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.72),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(
                    color: widget.accent.withValues(alpha: 0.26),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: widget.accent, width: 1.2),
                ),
              ),
              style: AppTheme.numeric(
                Theme.of(context).textTheme.labelMedium,
              ).copyWith(color: widget.accent, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Apply seed order',
            child: InkResponse(
              onTap: _submit,
              radius: 18,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: widget.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SeedDraftBanner extends StatelessWidget {
  const _SeedDraftBanner({
    required this.title,
    required this.message,
    required this.tint,
    required this.border,
    required this.foreground,
    required this.actions,
  });

  final String title;
  final String message;
  final Color tint;
  final Color border;
  final Color foreground;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WorkspaceSurfaceCard(
      accent: border,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Wrap(
        spacing: AppSpace.lg,
        runSpacing: AppSpace.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: foreground,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: actions,
          ),
        ],
      ),
    );
  }
}

final class _SchedulingSeedLoadingState extends StatelessWidget {
  const _SchedulingSeedLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LoadingSeedCard(),
        SizedBox(height: AppSpace.md),
        _LoadingSeedCard(),
      ],
    );
  }
}

final class _LoadingSeedCard extends StatelessWidget {
  const _LoadingSeedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 18,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            width: 220,
            height: 12,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SchedulingSeedEmptyState extends StatelessWidget {
  const _SchedulingSeedEmptyState();

  @override
  Widget build(BuildContext context) {
    return const WorkspaceEmptyCard(
      title: 'No ready categories yet',
      message:
          'Check in at least two entries in a category to generate seed matchups.',
    );
  }
}

final class _SchedulingSeedErrorState extends StatelessWidget {
  const _SchedulingSeedErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkspaceErrorCard(
          title: 'Scheduling seeds need attention',
          message: message,
        ),
        const SizedBox(height: AppSpace.md),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

List<String> _normalizeSeedIds({
  required List<String> requestedSeedIds,
  required List<TournamentEntry> checkedInEntries,
}) {
  final checkedInEntryIds = <String>{
    for (final entry in checkedInEntries) entry.id,
  };
  final normalized = <String>[];
  final seen = <String>{};

  for (final entryId in requestedSeedIds) {
    if (!checkedInEntryIds.contains(entryId) || !seen.add(entryId)) {
      continue;
    }
    normalized.add(entryId);
  }

  for (final entry in checkedInEntries) {
    if (seen.add(entry.id)) {
      normalized.add(entry.id);
    }
  }

  return List<String>.unmodifiable(normalized);
}

List<_DraftMatchupPreview> _buildDraftMatchups(
  List<TournamentEntry> orderedEntries,
) {
  return [
    for (var index = 0; index < orderedEntries.length; index += 2)
      _DraftMatchupPreview(
        matchNumber: (index ~/ 2) + 1,
        teamOne: orderedEntries[index],
        teamTwo: index + 1 < orderedEntries.length
            ? orderedEntries[index + 1]
            : null,
        hasBye: index + 1 >= orderedEntries.length,
      ),
  ];
}

String _entryLabel(TournamentEntry entry) {
  return entry.displayLabel;
}

bool _sameIds(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'This organizer account cannot save seed changes yet. Reload and try again.';
  }
  if (message.contains('failed-precondition')) {
    return 'Seeding data is not ready yet in this environment. Try again in a moment.';
  }
  return message;
}
