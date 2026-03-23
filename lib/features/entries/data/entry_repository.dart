import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entry.dart';

final class EntryRepository {
  EntryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entries(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('entries');
  }

  Stream<List<TournamentEntry>> watchEntries(String tournamentId) {
    return _entries(
      tournamentId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      final entries = snapshot.docs
          .map(TournamentEntry.fromDocument)
          .toList(growable: true);
      entries.sort((left, right) {
        final byCategory = left.categoryName.toLowerCase().compareTo(
          right.categoryName.toLowerCase(),
        );
        if (byCategory != 0) {
          return byCategory;
        }
        final bySeed = compareEntriesForSeeding(left, right);
        if (bySeed != 0) {
          return bySeed;
        }
        return left.id.compareTo(right.id);
      });
      return entries;
    });
  }

  Future<void> createEntryDraft({
    required String tournamentId,
    required String categoryId,
    required String teamName,
    required String playerOne,
    required String playerTwo,
    required int? seedNumber,
    required String categoryName,
    bool checkedIn = false,
  }) async {
    final doc = _entries(tournamentId).doc();
    final tournamentRef = _firestore
        .collection('tournaments')
        .doc(tournamentId);
    await _firestore.runTransaction((transaction) async {
      transaction.set(
        doc,
        TournamentEntry(
          id: doc.id,
          tournamentId: tournamentId,
          categoryId: categoryId,
          teamName: teamName,
          playerOne: playerOne,
          playerTwo: playerTwo,
          seedNumber: seedNumber,
          categoryName: categoryName,
          checkedIn: checkedIn,
          createdAt: null,
          updatedAt: null,
        ).toCreateMap(
          tournamentId: tournamentId,
          categoryId: categoryId,
          teamName: teamName,
          playerOne: playerOne,
          playerTwo: playerTwo,
          seedNumber: seedNumber,
          categoryName: categoryName,
          checkedIn: checkedIn,
        ),
      );
      transaction.update(tournamentRef, <String, Object>{
        'stats.entries': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (checkedIn) {
        final categoryRef = _firestore.collection('categories').doc(categoryId);
        transaction.update(categoryRef, <String, Object>{
          'checkedInPairs': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> updateEntryDraft({
    required String tournamentId,
    required String entryId,
    required String categoryId,
    required String teamName,
    required String playerOne,
    required String playerTwo,
    required int? seedNumber,
    required String categoryName,
    required bool checkedIn,
  }) async {
    final entryRef = _entries(tournamentId).doc(entryId);
    final tournamentRef = _firestore
        .collection('tournaments')
        .doc(tournamentId);
    final nextCategoryRef = _firestore.collection('categories').doc(categoryId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(entryRef);
      if (!snapshot.exists) {
        throw StateError('Entry not found.');
      }

      final currentEntry = TournamentEntry.fromDocument(snapshot);
      final previousCategoryRef = _firestore
          .collection('categories')
          .doc(currentEntry.categoryId);

      final updates = <String, Object>{
        'categoryId': categoryId,
        'categoryName': categoryName.trim(),
        'playerOne': playerOne.trim(),
        'playerTwo': playerTwo.trim(),
        'checkedIn': checkedIn,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final normalizedTeamName = teamName.trim();
      updates['teamName'] = normalizedTeamName.isEmpty
          ? FieldValue.delete()
          : normalizedTeamName;

      final normalizedSeedNumber = seedNumber != null && seedNumber > 0
          ? seedNumber
          : null;
      updates['seedNumber'] = normalizedSeedNumber ?? FieldValue.delete();

      transaction.update(entryRef, updates);
      transaction.update(tournamentRef, <String, Object>{
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final movedCategory = currentEntry.categoryId != categoryId;
      final checkedInChanged = currentEntry.checkedIn != checkedIn;
      if (movedCategory || checkedInChanged) {
        if (currentEntry.checkedIn && currentEntry.categoryId.isNotEmpty) {
          transaction.update(previousCategoryRef, <String, Object>{
            'checkedInPairs': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (checkedIn) {
          transaction.update(nextCategoryRef, <String, Object>{
            'checkedInPairs': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> setCheckedIn({
    required String tournamentId,
    required String entryId,
    required String categoryId,
    required bool checkedIn,
  }) async {
    final entryRef = _entries(tournamentId).doc(entryId);
    final categoryRef = _firestore.collection('categories').doc(categoryId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(entryRef);
      if (!snapshot.exists) {
        throw StateError('Entry not found.');
      }
      final current = snapshot.data() ?? <String, dynamic>{};
      final wasCheckedIn = current['checkedIn'] as bool? ?? false;
      if (wasCheckedIn == checkedIn) {
        return;
      }

      transaction.update(entryRef, <String, Object>{
        'checkedIn': checkedIn,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(categoryRef, <String, Object>{
        'checkedInPairs': FieldValue.increment(checkedIn ? 1 : -1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteEntry({
    required String tournamentId,
    required String entryId,
  }) async {
    final entryRef = _entries(tournamentId).doc(entryId);
    final tournamentRef = _firestore
        .collection('tournaments')
        .doc(tournamentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(entryRef);
      if (!snapshot.exists) {
        throw StateError('Entry not found.');
      }

      final currentEntry = TournamentEntry.fromDocument(snapshot);
      transaction.delete(entryRef);
      transaction.update(tournamentRef, <String, Object>{
        'stats.entries': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (currentEntry.checkedIn && currentEntry.categoryId.isNotEmpty) {
        final categoryRef = _firestore
            .collection('categories')
            .doc(currentEntry.categoryId);
        transaction.update(categoryRef, <String, Object>{
          'checkedInPairs': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
