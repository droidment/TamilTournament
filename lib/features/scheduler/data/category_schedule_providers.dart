import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/data/category_providers.dart';
import '../../entries/data/entry_providers.dart';
import '../domain/category_schedule.dart';

final categoryScheduleSnapshotProvider =
    Provider.family<AsyncValue<TournamentCategoryScheduleSnapshot>, String>((
      ref,
      tournamentId,
    ) {
      final categories = ref.watch(tournamentCategoriesProvider(tournamentId));
      final entries = ref.watch(entriesProvider(tournamentId));

      if (categories.hasError) {
        return AsyncError(
          categories.error!,
          categories.stackTrace ?? StackTrace.current,
        );
      }
      if (entries.hasError) {
        return AsyncError(
          entries.error!,
          entries.stackTrace ?? StackTrace.current,
        );
      }

      final categoriesData = categories.asData?.value;
      final entriesData = entries.asData?.value;
      if (categoriesData == null || entriesData == null) {
        return const AsyncLoading();
      }

      return AsyncData(
        deriveTournamentCategorySchedules(
          categories: categoriesData,
          entries: entriesData,
        ),
      );
    });
