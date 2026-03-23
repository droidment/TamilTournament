import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/data/category_providers.dart';
import '../../entries/data/entry_providers.dart';
import '../domain/scheduling_seed.dart';
import 'scheduling_seed_repository.dart';

final schedulerFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final schedulingSeedRepositoryProvider = Provider<SchedulingSeedRepository>((
  ref,
) {
  return SchedulingSeedRepository(ref.watch(schedulerFirestoreProvider));
});

final tournamentSeedPlansProvider =
    StreamProvider.family<List<SchedulingSeedPlan>, String>((
      ref,
      tournamentId,
    ) {
      return ref
          .watch(schedulingSeedRepositoryProvider)
          .watchSeedPlans(tournamentId);
    });

final seedPlanProvider =
    StreamProvider.family<
      SchedulingSeedPlan?,
      ({String tournamentId, String categoryId})
    >((ref, key) {
      return ref
          .watch(schedulingSeedRepositoryProvider)
          .watchSeedPlan(
            tournamentId: key.tournamentId,
            categoryId: key.categoryId,
          );
    });

final schedulingSeedStateProvider =
    Provider.family<AsyncValue<SchedulingSeedSnapshot>, String>((
      ref,
      tournamentId,
    ) {
      final categories = ref.watch(tournamentCategoriesProvider(tournamentId));
      final entries = ref.watch(entriesProvider(tournamentId));
      final seedPlans = ref.watch(tournamentSeedPlansProvider(tournamentId));

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
      if (seedPlans.hasError) {
        if (!_isPermissionDenied(seedPlans.error)) {
          return AsyncError(
            seedPlans.error!,
            seedPlans.stackTrace ?? StackTrace.current,
          );
        }
      }

      final categoriesData = categories.asData?.value;
      final entriesData = entries.asData?.value;
      final seedPlansData = seedPlans.hasError
          ? const <SchedulingSeedPlan>[]
          : seedPlans.asData?.value;
      if (categoriesData == null ||
          entriesData == null ||
          seedPlansData == null) {
        return const AsyncLoading();
      }

      return AsyncData(
        deriveSchedulingSeedSnapshot(
          categories: categoriesData,
          entries: entriesData,
          seedPlans: seedPlansData,
        ),
      );
    });

bool _isPermissionDenied(Object? error) {
  return error is FirebaseException && error.code == 'permission-denied';
}

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
