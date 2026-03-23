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
          .toList(growable: false);
      return entries;
    });
  }

  Future<void> createEntryDraft({
    required String tournamentId,
    required String categoryId,
    required String playerOne,
    required String playerTwo,
    required String categoryName,
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
          playerOne: playerOne,
          playerTwo: playerTwo,
          categoryName: categoryName,
          checkedIn: false,
          createdAt: null,
          updatedAt: null,
        ).toCreateMap(
          tournamentId: tournamentId,
          categoryId: categoryId,
          playerOne: playerOne,
          playerTwo: playerTwo,
          categoryName: categoryName,
        ),
      );
      transaction.update(tournamentRef, <String, Object>{
        'stats.entries': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
}
