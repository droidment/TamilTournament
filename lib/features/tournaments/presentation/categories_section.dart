import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../categories/data/category_providers.dart';
import '../../categories/domain/category_item.dart';
import '../../scheduler/data/category_schedule_providers.dart';
import '../../scheduler/domain/category_schedule.dart';
import 'workspace_components.dart';

final class CategoriesSection extends ConsumerStatefulWidget {
  const CategoriesSection({
    super.key,
    required this.tournamentId,
    this.embedded = false,
  });

  final String tournamentId;
  final bool embedded;

  @override
  ConsumerState<CategoriesSection> createState() => _CategoriesSectionState();
}

final class _CategoriesSectionState extends ConsumerState<CategoriesSection> {
  bool _isCreating = false;

  Future<void> _showCreateCategoryDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final minPlayersController = TextEditingController(text: '2');

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppPalette.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.panel),
            side: const BorderSide(color: AppPalette.line),
          ),
          title: const Text('Create category draft'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DialogField(
                    label: 'Category name',
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Men\'s Open',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a category name.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _DialogField(
                    label: 'Auto format',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: BoxDecoration(
                        color: AppPalette.surfaceSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppPalette.line),
                      ),
                      child: Text(
                        'The app decides the format from seeded team count: 7 or fewer plays round robin top 4, 8 or more becomes pool play plus knockout.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  _DialogField(
                    label: 'Minimum players',
                    child: TextFormField(
                      controller: minPlayersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '2'),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed < 2) {
                          return 'Enter a number of at least 2.';
                        }
                        return null;
                      },
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

    if (shouldCreate != true || !mounted) {
      nameController.dispose();
      minPlayersController.dispose();
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('You must be signed in to create a category.');
      }
      await ref
          .read(categoryRepositoryProvider)
          .createDraftCategory(
            tournamentId: widget.tournamentId,
            name: nameController.text,
            format: CategoryFormat.group,
            minPlayers: int.parse(minPlayersController.text),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category draft created.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    } finally {
      nameController.dispose();
      minPlayersController.dispose();
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(
      tournamentCategoriesProvider(widget.tournamentId),
    );
    final schedulePreview = ref.watch(
      categoryScheduleSnapshotProvider(widget.tournamentId),
    );
    final sectionSpacing = widget.embedded ? AppSpace.md : AppSpace.lg;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkspaceSectionLead(
          title: 'Categories',
          description:
              'Tournament-scoped setup for divisions and minimum player rules. Match format is derived from the seeded roster.',
          trailing: FilledButton(
            onPressed: _isCreating ? null : _showCreateCategoryDialog,
            child: Text(_isCreating ? 'Creating...' : 'New category'),
          ),
        ),
        SizedBox(height: sectionSpacing),
        categories.when(
          data: (items) {
            if (items.isEmpty) {
              return const _CategoriesEmptyState();
            }

            final generatedByCategoryId = {
              for (final schedule
                  in schedulePreview.asData?.value.categories ??
                      const <GeneratedCategorySchedule>[])
                schedule.categoryId: schedule,
            };
            final roundRobinCount = generatedByCategoryId.values
                .where(
                  (schedule) =>
                      schedule.mode == GeneratedScheduleMode.roundRobinTop4,
                )
                .length;
            final poolPlayCount = generatedByCategoryId.values
                .where(
                  (schedule) =>
                      schedule.mode == GeneratedScheduleMode.groupsKnockout,
                )
                .length;
            final checkedInPairs = items.fold<int>(
              0,
              (sum, category) => sum + category.checkedInPairs,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WorkspaceStatRail(
                  metrics: [
                    WorkspaceMetricItemData(
                      value: '${items.length}',
                      label: 'categories',
                      foreground: const Color(0xFF456F77),
                      isHighlighted: true,
                    ),
                    WorkspaceMetricItemData(
                      value: '$roundRobinCount',
                      label: 'round robin',
                      foreground: const Color(0xFF5F7243),
                    ),
                    WorkspaceMetricItemData(
                      value: '$poolPlayCount',
                      label: 'pool + KO',
                      foreground: const Color(0xFF8F6038),
                    ),
                    WorkspaceMetricItemData(
                      value: '$checkedInPairs',
                      label: 'checked in',
                      foreground: AppPalette.sageStrong,
                    ),
                  ],
                ),
                SizedBox(height: sectionSpacing),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compactList = constraints.maxWidth < 620;

                    return WorkspaceSurfaceCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: compactList ? AppSpace.md : AppSpace.lg,
                        vertical: compactList ? AppSpace.sm : AppSpace.lg,
                      ),
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            _CategoryRowCard(
                              category: items[index],
                              generatedSchedule:
                                  generatedByCategoryId[items[index].id],
                            ),
                            if (index < items.length - 1)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: compactList
                                      ? AppSpace.sm
                                      : AppSpace.md,
                                ),
                                child: const Divider(height: 1),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
          loading: () => const _CategoriesLoadingState(),
          error: (error, _) =>
              _CategoriesErrorState(message: _friendlyError(error)),
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

final class _CategoryRowCard extends StatelessWidget {
  const _CategoryRowCard({
    required this.category,
    required this.generatedSchedule,
  });

  final CategoryItem category;
  final GeneratedCategorySchedule? generatedSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final derivedMode = generatedSchedule?.mode;
    final accent = switch (derivedMode) {
      GeneratedScheduleMode.roundRobinTop4 => AppPalette.sageStrong,
      GeneratedScheduleMode.groupsKnockout => AppPalette.sky,
      null => AppPalette.oliveStrong,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;
        final titleStyle =
            (isCompact
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge)
                ?.copyWith(fontWeight: FontWeight.w700);

        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name, style: titleStyle),
            const SizedBox(height: AppSpace.xs),
            Text(
              'Minimum ${category.minPlayers} players',
              style:
                  (isCompact
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(color: AppPalette.inkSoft),
            ),
          ],
        );

        final rightColumn = Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
          children: [
            WorkspaceTag(
              label: generatedSchedule == null
                  ? 'AUTO FORMAT PENDING'
                  : generatedSchedule!.mode ==
                        GeneratedScheduleMode.roundRobinTop4
                  ? 'AUTO RR TOP 4'
                  : 'AUTO POOL + KO',
              background: accent.withValues(alpha: 0.16),
              foreground: derivedMode == GeneratedScheduleMode.groupsKnockout
                  ? const Color(0xFF456F77)
                  : accent,
            ),
            Text(
              generatedSchedule == null
                  ? '${category.checkedInPairs} checked in'
                  : '${generatedSchedule!.teamCount} seeded teams',
              style:
                  (isCompact
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: AppPalette.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
            ),
          ],
        );

        if (isCompact) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    details,
                    const SizedBox(height: AppSpace.sm),
                    rightColumn,
                  ],
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 46,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(child: details),
            const SizedBox(width: AppSpace.md),
            Flexible(child: rightColumn),
          ],
        );
      },
    );
  }
}

final class _DialogField extends StatelessWidget {
  const _DialogField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpace.sm),
        child,
      ],
    );
  }
}

final class _CategoriesLoadingState extends StatelessWidget {
  const _CategoriesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LoadingSkeletonRow(),
        SizedBox(height: AppSpace.md),
        _LoadingSkeletonRow(),
      ],
    );
  }
}

final class _LoadingSkeletonRow extends StatelessWidget {
  const _LoadingSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppPalette.line.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Container(
                  width: 240,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppPalette.line.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Container(
            width: 92,
            height: 30,
            decoration: BoxDecoration(
              color: AppPalette.line.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

final class _CategoriesEmptyState extends StatelessWidget {
  const _CategoriesEmptyState();

  @override
  Widget build(BuildContext context) {
    return const WorkspaceEmptyCard(
      title: 'No categories yet',
      message:
          'Create the first draft category for this tournament to start shaping entry and scheduling workflows.',
    );
  }
}

final class _CategoriesErrorState extends StatelessWidget {
  const _CategoriesErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WorkspaceErrorCard(
      title: 'Categories need attention',
      message: message,
    );
  }
}

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'This organizer account cannot update categories yet. Reload and try again.';
  }
  if (message.contains('failed-precondition')) {
    return 'Category data is not ready yet in this environment. Try again in a moment.';
  }
  return message;
}
