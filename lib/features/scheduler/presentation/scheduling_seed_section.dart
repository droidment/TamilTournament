import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
              'Start from assigned entry seeds, adjust the live order per category, and save the bracket order for scheduling.',
          icon: Icons.format_list_numbered_rounded,
          accent: AppPalette.apricot,
        ),
        const SizedBox(height: AppSpace.lg),
        if (state.hasValue)
          WorkspaceStatRail(
            metrics: [
              WorkspaceMetricItemData(
                value: '${state.requireValue.readyCategories.length}',
                label: 'ready',
                foreground: const Color(0xFF5F7243),
                isHighlighted: true,
              ),
              WorkspaceMetricItemData(
                value: '${state.requireValue.totalCheckedInEntries}',
                label: 'checked in',
                foreground: const Color(0xFF456F77),
              ),
              WorkspaceMetricItemData(
                value: '${state.requireValue.totalMatchups}',
                label: 'seed slots',
                foreground: const Color(0xFF8F6038),
              ),
              WorkspaceMetricItemData(
                value: '${_editedCategoryCount(state.requireValue)}',
                label: 'edited',
                foreground: const Color(0xFF7B4D42),
              ),
            ],
          ),
        if (state.hasValue) const SizedBox(height: AppSpace.lg),
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
                            : () => _saveAll(snapshot),
                        child: Text(_isSavingAll ? 'Saving...' : 'Save all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
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
                    onMoveSeed: (fromIndex, delta) => _moveSeed(
                      category: snapshot.readyCategories[index],
                      fromIndex: fromIndex,
                      delta: delta,
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

  void _moveSeed({
    required ReadyCategorySeed category,
    required int fromIndex,
    required int delta,
  }) {
    final seedIds = List<String>.from(_effectiveSeedIds(category));
    final toIndex = fromIndex + delta;
    if (fromIndex < 0 ||
        fromIndex >= seedIds.length ||
        toIndex < 0 ||
        toIndex >= seedIds.length) {
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

  void _autoSeedCategory(ReadyCategorySeed category) {
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
    required this.onMoveSeed,
    required this.onResetCategory,
    required this.onAutoSeedCategory,
    required this.onSaveCategory,
  });

  final ReadyCategorySeed category;
  final List<TournamentEntry> orderedEntries;
  final bool isEdited;
  final bool isSaving;
  final bool needsSave;
  final void Function(int fromIndex, int delta) onMoveSeed;
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

    return WorkspaceSurfaceCard(
      accent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 780;

              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.categoryName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    '${category.formatLabel} · ${category.checkedInCount} checked in',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppPalette.inkSoft,
                    ),
                  ),
                ],
              );

              final status = Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
                children: [
                  _StatusChip(
                    label: '${orderedEntries.length} seeds',
                    tint: AppPalette.oliveSoft,
                    foreground: const Color(0xFF5F7243),
                  ),
                  _StatusChip(
                    label: category.hasSavedSeedPlan
                        ? (needsSave ? 'Needs save' : 'Saved')
                        : 'Generated',
                    tint: category.hasSavedSeedPlan
                        ? (needsSave
                              ? AppPalette.apricotSoft
                              : AppPalette.sageSoft)
                        : AppPalette.skySoft,
                    foreground: category.hasSavedSeedPlan
                        ? (needsSave
                              ? const Color(0xFF8F6038)
                              : const Color(0xFF365141))
                        : const Color(0xFF456F77),
                  ),
                  if (isEdited)
                    const _StatusChip(
                      label: 'Edited',
                      tint: Color(0x24C97D6B),
                      foreground: Color(0xFF7B4D42),
                    ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: AppSpace.md),
                    status,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: AppSpace.md),
                  Flexible(child: status),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.lg),
          Text('Seed order', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.sm),
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
                  onMoveUp: index > 0 ? () => onMoveSeed(index, -1) : null,
                  onMoveDown: index < orderedEntries.length - 1
                      ? () => onMoveSeed(index, 1)
                      : null,
                ),
                if (index < orderedEntries.length - 1)
                  const SizedBox(height: AppSpace.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              OutlinedButton(
                onPressed: onAutoSeedCategory,
                child: const Text('Auto-seed'),
              ),
              OutlinedButton(
                onPressed: onResetCategory,
                child: const Text('Reset'),
              ),
              FilledButton(
                onPressed: isSaving ? null : onSaveCategory,
                child: Text(isSaving ? 'Saving...' : 'Save category'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text('Matchup preview', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.sm),
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
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final TournamentEntry entry;
  final int currentSeedNumber;
  final int originalSeedNumber;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMoved = currentSeedNumber != originalSeedNumber;

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.skySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.sky.withValues(alpha: 0.35)),
            ),
            child: Text(
              '#$currentSeedNumber',
              style: AppTheme.numeric(
                theme.textTheme.labelLarge,
              ).copyWith(color: const Color(0xFF456F77)),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_entryLabel(entry), style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpace.xs),
                Text(
                  hasMoved
                      ? 'Moved from suggested seed #$originalSeedNumber.'
                      : entry.hasAssignedSeed
                      ? 'Suggested by assigned seed #${entry.seedNumber}.'
                      : 'Suggested by check-in order.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkSoft,
                  ),
                ),
                if (entry.teamName.trim().isNotEmpty &&
                    entry.rosterLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    entry.rosterLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          _SeedMoveButtons(onMoveUp: onMoveUp, onMoveDown: onMoveDown),
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

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.oliveSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPalette.oliveStrong.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'M${matchup.matchNumber}',
              style: AppTheme.numeric(
                theme.textTheme.labelMedium,
              ).copyWith(color: const Color(0xFF5F7243)),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matchup.hasBye
                      ? '${matchup.teamOne} gets a bye'
                      : '${matchup.teamOne} vs ${matchup.teamTwo}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  matchup.hasBye
                      ? 'Awaiting the next checked-in entry to complete the matchup.'
                      : 'Ready for the live court scheduler.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkSoft,
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

final class _DraftMatchupPreview {
  const _DraftMatchupPreview({
    required this.matchNumber,
    required this.teamOne,
    required this.teamTwo,
    required this.hasBye,
  });

  final int matchNumber;
  final String teamOne;
  final String teamTwo;
  final bool hasBye;
}

final class _SeedMoveButtons extends StatelessWidget {
  const _SeedMoveButtons({required this.onMoveUp, required this.onMoveDown});

  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.xs,
      children: [
        _MiniIconButton(
          tooltip: 'Move seed up',
          icon: Icons.keyboard_arrow_up_rounded,
          onPressed: onMoveUp,
        ),
        _MiniIconButton(
          tooltip: 'Move seed down',
          icon: Icons.keyboard_arrow_down_rounded,
          onPressed: onMoveDown,
        ),
      ],
    );
  }
}

final class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: AppPalette.surfaceSoft,
          foregroundColor: AppPalette.ink,
          side: const BorderSide(color: AppPalette.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
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

final class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.tint,
    required this.foreground,
  });

  final String label;
  final Color tint;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return WorkspaceTag(label: label, background: tint, foreground: foreground);
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
        teamOne: _entryLabel(orderedEntries[index]),
        teamTwo: index + 1 < orderedEntries.length
            ? _entryLabel(orderedEntries[index + 1])
            : 'Bye',
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
