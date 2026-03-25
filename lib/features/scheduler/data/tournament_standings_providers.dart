import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'category_schedule_providers.dart';
import 'tournament_match_providers.dart';
import '../domain/tournament_standings.dart';

final tournamentStandingsProvider =
    Provider.family<AsyncValue<TournamentStandingsSnapshot>, String>((
      ref,
      tournamentId,
    ) {
      final schedule = ref.watch(
        categoryScheduleSnapshotProvider(tournamentId),
      );
      final matches = ref.watch(tournamentMatchesProvider(tournamentId));

      if (schedule.hasError) {
        return AsyncError(
          schedule.error!,
          schedule.stackTrace ?? StackTrace.current,
        );
      }
      if (matches.hasError) {
        return AsyncError(
          matches.error!,
          matches.stackTrace ?? StackTrace.current,
        );
      }

      final scheduleData = schedule.asData?.value;
      final matchesData = matches.asData?.value;
      if (scheduleData == null || matchesData == null) {
        return const AsyncLoading();
      }

      return AsyncData(
        deriveTournamentStandings(
          scheduleSnapshot: scheduleData,
          matches: matchesData,
        ),
      );
    });
