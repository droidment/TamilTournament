import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../entries/presentation/entries_section.dart';
import '../../scheduler/presentation/category_schedule_section.dart';
import '../../scheduler/presentation/court_management_section.dart';
import '../../scheduler/presentation/scheduling_seed_section.dart';
import '../data/tournament_providers.dart';
import '../domain/tournament.dart';
import 'categories_section.dart';

final class TournamentDetailPage extends ConsumerWidget {
  const TournamentDetailPage({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(tournamentByIdProvider(tournamentId));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: tournament.when(
            data: (value) {
              if (value == null) {
                return const _TournamentDetailState(
                  title: 'Tournament not available',
                  message:
                      'This tournament was not found or you do not have access to it.',
                );
              }
              return _TournamentDetailBody(tournament: value);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _TournamentDetailState(
              title: 'Tournament detail',
              message: error.toString(),
            ),
          ),
        ),
      ),
    );
  }
}

final class _TournamentDetailBody extends StatelessWidget {
  const _TournamentDetailBody({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.xl),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(AppRadii.panel),
            border: Border.all(color: AppPalette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                  ),
                  _HeaderChip(
                    label: tournament.status.label,
                    tint: AppPalette.skySoft,
                    border: AppPalette.sky.withValues(alpha: 0.45),
                    foreground: const Color(0xFF456F77),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Text(tournament.name, style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpace.sm),
              Text(
                '${tournament.venue} · ${_formatDate(tournament.startDate)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppPalette.inkSoft,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  _HeaderChip(
                    label: '${tournament.stats.categories} categories',
                    tint: AppPalette.skySoft,
                    border: AppPalette.sky.withValues(alpha: 0.45),
                    foreground: const Color(0xFF456F77),
                  ),
                  _HeaderChip(
                    label: '${tournament.stats.entries} entries',
                    tint: AppPalette.oliveSoft,
                    border: AppPalette.oliveStrong.withValues(alpha: 0.45),
                    foreground: const Color(0xFF5F7243),
                  ),
                  _HeaderChip(
                    label: '${tournament.stats.matches} matches',
                    tint: AppPalette.apricotSoft,
                    border: AppPalette.apricot.withValues(alpha: 0.45),
                    foreground: const Color(0xFF8F6038),
                  ),
                  _HeaderChip(
                    label: '${tournament.activeCourtCount} active courts',
                    tint: AppPalette.sageSoft,
                    border: AppPalette.sage.withValues(alpha: 0.45),
                    foreground: const Color(0xFF365141),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        CategoriesSection(tournamentId: tournament.id),
        const SizedBox(height: AppSpace.lg),
        EntriesSection(tournamentId: tournament.id),
        const SizedBox(height: AppSpace.lg),
        SchedulingSeedSection(tournamentId: tournament.id),
        const SizedBox(height: AppSpace.lg),
        CategoryScheduleSection(tournamentId: tournament.id),
        const SizedBox(height: AppSpace.lg),
        CourtManagementSection(
          tournamentId: tournament.id,
          initialCourtCount: tournament.activeCourtCount,
        ),
      ],
    );
  }
}

final class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

final class _TournamentDetailState extends StatelessWidget {
  const _TournamentDetailState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.all(AppSpace.xl),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(AppRadii.panel),
          border: Border.all(color: AppPalette.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpace.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
