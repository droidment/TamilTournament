import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../../categories/data/category_providers.dart';
import '../../categories/domain/category_item.dart';

final class CategoriesSection extends ConsumerStatefulWidget {
  const CategoriesSection({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<CategoriesSection> createState() => _CategoriesSectionState();
}

final class _CategoriesSectionState extends ConsumerState<CategoriesSection> {
  bool _isCreating = false;

  Future<void> _showCreateCategoryDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final minPlayersController = TextEditingController(text: '2');
    var selectedFormat = CategoryFormat.group;

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
                        label: 'Format',
                        child: DropdownButtonFormField<CategoryFormat>(
                          initialValue: selectedFormat,
                          items: CategoryFormat.values
                              .map(
                                (format) => DropdownMenuItem(
                                  value: format,
                                  child: Text(format.label),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() {
                              selectedFormat = value;
                            });
                          },
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
            format: selectedFormat,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 720;

              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categories', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    'Tournament-scoped category setup and drafts.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkSoft,
                    ),
                  ),
                ],
              );

              final action = FilledButton(
                onPressed: _isCreating ? null : _showCreateCategoryDialog,
                child: Text(_isCreating ? 'Creating...' : 'New category'),
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
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: AppSpace.md),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.lg),
          categories.when(
            data: (items) {
              if (items.isEmpty) {
                return const _CategoriesEmptyState();
              }
              return Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    _CategoryRowCard(category: items[index]),
                    if (index < items.length - 1)
                      const SizedBox(height: AppSpace.md),
                  ],
                ],
              );
            },
            loading: () => const _CategoriesLoadingState(),
            error: (error, _) =>
                _CategoriesErrorState(message: _friendlyError(error)),
          ),
        ],
      ),
    );
  }
}

final class _CategoryRowCard extends StatelessWidget {
  const _CategoryRowCard({required this.category});

  final CategoryItem category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = switch (category.format) {
      CategoryFormat.group => AppPalette.sageStrong,
      CategoryFormat.knockout => AppPalette.apricot,
    };
    final chips = [
      _CategoryChip(
        label: category.format.label,
        tint: accent.withValues(alpha: 0.18),
        border: accent.withValues(alpha: 0.45),
        foreground: AppPalette.ink,
      ),
      _CategoryChip(
        label: '${category.minPlayers} min',
        tint: AppPalette.skySoft,
        border: AppPalette.sky.withValues(alpha: 0.45),
        foreground: const Color(0xFF456F77),
      ),
      _CategoryChip(
        label: '${category.checkedInPairs} checked in',
        tint: AppPalette.oliveSoft,
        border: AppPalette.oliveStrong.withValues(alpha: 0.45),
        foreground: const Color(0xFF5F7243),
      ),
    ];

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 760;

                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      '${category.format.label} · min ${category.minPlayers} players',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                  ],
                );

                final chipWrap = Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  alignment: isCompact
                      ? WrapAlignment.start
                      : WrapAlignment.end,
                  children: chips,
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      details,
                      const SizedBox(height: AppSpace.md),
                      chipWrap,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: AppSpace.md),
                    Flexible(child: chipWrap),
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

final class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
          Text('No categories yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Create the first draft category for this tournament to start shaping entry and scheduling workflows.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _CategoriesErrorState extends StatelessWidget {
  const _CategoriesErrorState({required this.message});

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
            'Categories need attention',
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
    return 'Deploy the Firestore rules for categories, then reload the app.';
  }
  if (message.contains('failed-precondition')) {
    return 'Create the Firestore database in Firebase Console first, then reload the app.';
  }
  return message;
}
