import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/tournament.dart';

final class TournamentRepository {
  TournamentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _firestore.collection('tournaments');

  Stream<List<Tournament>> watchOwnedTournaments(String organizerUid) {
    return _tournaments
        .where('organizerUid', isEqualTo: organizerUid)
        .snapshots()
        .map((snapshot) {
          final tournaments = snapshot.docs
              .map(Tournament.fromDocument)
              .toList(growable: false);
          tournaments.sort((left, right) {
            return right.startDate.compareTo(left.startDate);
          });
          return tournaments;
        });
  }

  Stream<Tournament?> watchTournament({
    required String tournamentId,
    required String organizerUid,
  }) {
    return _tournaments.doc(tournamentId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      final tournament = Tournament.fromDocument(snapshot);
      if (tournament.organizerUid != organizerUid) {
        return null;
      }
      return tournament;
    });
  }

  Future<void> createDraftTournament({
    required String organizerUid,
    required String name,
    required String venue,
    required DateTime startDate,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _tournaments.add(<String, Object>{
      'name': name.trim(),
      'venue': venue.trim(),
      'startDate': Timestamp.fromDate(startDate),
      'organizerUid': organizerUid,
      'status': TournamentStatus.draft.value,
      'activeCourtCount': 0,
      'stats': const TournamentStats(
        categories: 0,
        entries: 0,
        matches: 0,
      ).toMap(),
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
