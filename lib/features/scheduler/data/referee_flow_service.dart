import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/score_submission.dart';
import '../domain/tournament_match.dart';

final class RefereeFlowService {
  RefereeFlowService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _submissions(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('scoreSubmissions');
  }

  Future<void> submitScore({
    required String tournamentId,
    required String matchId,
    required String submittedByUserId,
    required String submittedByRole,
    required List<MatchGameScore> scores,
    String? note,
  }) async {
    if (scores.length < 2) {
      throw StateError('At least two completed games are required.');
    }

    await _submissions(tournamentId).add(<String, Object?>{
      'matchId': matchId,
      'submittedByUserId': submittedByUserId,
      'submittedByRole': submittedByRole,
      'submittedAt': FieldValue.serverTimestamp(),
      'games': scores.map((game) => game.toMap()).toList(growable: false),
      'proposedWinnerEntryId': null,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      'approvalStatus': ScoreApprovalStatus.pending.value,
      'approvedByUserId': null,
      'approvedByRole': null,
      'approvedAt': null,
      'rejectedReason': null,
    });
  }
}
