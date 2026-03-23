import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/data/category_providers.dart';
import '../../entries/data/entry_providers.dart';
import '../domain/scheduling_seed.dart';

final schedulingSeedStateProvider =
    Provider.family<AsyncValue<SchedulingSeedSnapshot>, String>((
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
        deriveSchedulingSeedSnapshot(
          categories: categoriesData,
          entries: entriesData,
        ),
      );
    });

final readyCategoriesProvider =
    Provider.family<List<ReadyCategorySeed>, String>((ref, tournamentId) {
      return ref
          .watch(schedulingSeedStateProvider(tournamentId))
          .when(
            data: (snapshot) => snapshot.readyCategories,
            loading: () => const <ReadyCategorySeed>[],
            error: (_, __) => const <ReadyCategorySeed>[],
          );
    });

final seedMatchupsProvider = Provider.family<List<SeedMatchup>, String>((
  ref,
  tournamentId,
) {
  return ref
      .watch(schedulingSeedStateProvider(tournamentId))
      .when(
        data: (snapshot) => snapshot.readyCategories
            .expand((category) => category.matchups)
            .toList(growable: false),
        loading: () => const <SeedMatchup>[],
        error: (_, __) => const <SeedMatchup>[],
      );
});
