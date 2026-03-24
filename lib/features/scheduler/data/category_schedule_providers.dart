import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../categories/data/category_providers.dart';
import '../../entries/data/entry_providers.dart';
import '../domain/scheduling_seed.dart';
import 'scheduling_seed_providers.dart';
import '../domain/category_schedule.dart';

final categoryScheduleSnapshotProvider =
    Provider.family<AsyncValue<TournamentCategoryScheduleSnapshot>, String>((
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
        deriveTournamentCategorySchedules(
          categories: categoriesData,
          entries: entriesData,
          seedPlans: seedPlansData,
        ),
      );
    });

bool _isPermissionDenied(Object? error) {
  return error is FirebaseException && error.code == 'permission-denied';
}
