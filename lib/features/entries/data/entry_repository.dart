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
          playerOne: playerOne,
          playerTwo: playerTwo,
          categoryName: categoryName,
          checkedIn: false,
          createdAt: null,
          updatedAt: null,
        ).toCreateMap(
          tournamentId: tournamentId,
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
    required bool checkedIn,
  }) async {
    await _entries(tournamentId).doc(entryId).update(<String, Object>{
      'checkedIn': checkedIn,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
