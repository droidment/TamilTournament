import 'package:cloud_firestore/cloud_firestore.dart';

import '../../categories/domain/category_item.dart';
import '../../entries/domain/entry.dart';
import '../domain/scheduling_seed.dart';

final class SchedulingSeedRepository {
  SchedulingSeedRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _seedPlans(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('seedPlans');
  }

  Stream<List<SchedulingSeedPlan>> watchSeedPlans(String tournamentId) {
    return _seedPlans(tournamentId).snapshots().map((snapshot) {
      final plans = snapshot.docs
          .map(SchedulingSeedPlan.fromDocument)
          .toList(growable: false);
      plans.sort((left, right) {
        final byCategoryName = left.categoryName.toLowerCase().compareTo(
          right.categoryName.toLowerCase(),
        );
        if (byCategoryName != 0) {
          return byCategoryName;
        }
        return left.categoryId.compareTo(right.categoryId);
      });
      return plans;
    });
  }

  Stream<SchedulingSeedPlan?> watchSeedPlan({
    required String tournamentId,
    required String categoryId,
  }) {
    return _seedPlans(tournamentId).doc(categoryId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return SchedulingSeedPlan.fromDocument(snapshot);
    });
  }

  Future<void> saveSeedPlan({
    required String tournamentId,
    required String categoryId,
    required String categoryName,
    required CategoryFormat format,
    required List<TournamentEntry> checkedInEntries,
    List<String> seedEntryIds = const [],
  }) async {
    final normalizedSeedEntryIds = _normalizeSeedEntryIds(
      seedEntryIds.isEmpty
          ? checkedInEntries.map((entry) => entry.id).toList(growable: false)
          : seedEntryIds,
      checkedInEntries,
    );

    if (normalizedSeedEntryIds.length < 2) {
      throw StateError('A seed plan needs at least two checked-in entries.');
    }

    final plan = SchedulingSeedPlan(
      tournamentId: tournamentId,
      categoryId: categoryId,
      categoryName: categoryName,
      format: format,
      seedEntryIds: normalizedSeedEntryIds,
      createdAt: null,
      updatedAt: null,
    );

    final doc = _seedPlans(tournamentId).doc(categoryId);
    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      final createdAt = snapshot.data()?['createdAt'] ?? now;
      transaction.set(doc, plan.toMap(createdAt: createdAt, updatedAt: now));
    });
  }

  Future<void> clearSeedPlan({
    required String tournamentId,
    required String categoryId,
  }) async {
    await _seedPlans(tournamentId).doc(categoryId).delete();
  }
}

List<String> _normalizeSeedEntryIds(
  List<String> requestedSeedEntryIds,
  List<TournamentEntry> checkedInEntries,
) {
  final checkedInEntryIds = <String>{
    for (final entry in checkedInEntries) entry.id,
  };
  final seen = <String>{};
  final normalized = <String>[];

  for (final entryId in requestedSeedEntryIds) {
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
