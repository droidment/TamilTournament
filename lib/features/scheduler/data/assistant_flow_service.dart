import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/score_submission.dart';
import '../domain/tournament_court.dart';
import '../domain/tournament_match.dart';

final class AssistantFlowService {
  AssistantFlowService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _matches(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches');
  }

  CollectionReference<Map<String, dynamic>> _courts(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('courts');
  }

  CollectionReference<Map<String, dynamic>> _submissions(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('scoreSubmissions');
  }

  Future<void> assignMatchToCourt({
    required String tournamentId,
    required String matchId,
    required String courtId,
  }) async {
    final matchRef = _matches(tournamentId).doc(matchId);
    final courtRef = _courts(tournamentId).doc(courtId);
    final matchSnapshot = await matchRef.get();
    final courtSnapshot = await courtRef.get();
    if (!matchSnapshot.exists || !courtSnapshot.exists) {
      throw StateError('Match or court could not be found.');
    }

    final match = TournamentMatch.fromDocument(matchSnapshot);
    if (!(match.isReady || match.isAssigned || match.isCalled)) {
      throw StateError('Only ready or assigned matches can be queued.');
    }

    final court = TournamentCourt.fromDocument(courtSnapshot);
    if (!court.isAvailable) {
      throw StateError('This court is currently unavailable.');
    }

    final occupiedSnapshot = await _matches(tournamentId).get();
    final occupiedByOther = occupiedSnapshot.docs
        .map(TournamentMatch.fromDocument)
        .where((candidate) => candidate.id != matchId)
        .any(
          (candidate) =>
              candidate.assignedCourtId == courtId &&
              candidate.status != TournamentMatchStatus.completed &&
              candidate.status != TournamentMatchStatus.cancelled,
        );
    if (occupiedByOther) {
      throw StateError('This court already has an active match assigned.');
    }

    await matchRef.update(<String, Object?>{
      'status': TournamentMatchStatus.assigned.value,
      'assignedCourtId': court.id,
      'assignedCourtCode': court.code,
      'assignedCourtName': court.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMatchOnCourt({
    required String tournamentId,
    required String matchId,
  }) async {
    final matchRef = _matches(tournamentId).doc(matchId);
    final matchSnapshot = await matchRef.get();
    if (!matchSnapshot.exists) {
      throw StateError('This match could not be found.');
    }

    final match = TournamentMatch.fromDocument(matchSnapshot);
    if (match.assignedCourtId == null || match.assignedCourtId!.isEmpty) {
      throw StateError('Assign this match to a court before starting it.');
    }
    if (!(match.isAssigned || match.isCalled)) {
      throw StateError('Only assigned matches can be marked on court.');
    }

    await matchRef.update(<String, Object>{
      'status': TournamentMatchStatus.onCourt.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveSubmission({
    required String tournamentId,
    required String submissionId,
    required String approvedByUserId,
    required String approvedByRole,
  }) async {
    final submissionRef = _submissions(tournamentId).doc(submissionId);
    final submissionSnapshot = await submissionRef.get();
    if (!submissionSnapshot.exists) {
      throw StateError('This score submission could not be found.');
    }

    final submission = ScoreSubmission.fromDocument(
      submissionSnapshot,
      tournamentId: tournamentId,
    );
    if (submission.approvalStatus != ScoreApprovalStatus.pending) {
      throw StateError('Only pending submissions can be approved.');
    }

    final matchRef = _matches(tournamentId).doc(submission.matchId);
    final matchSnapshot = await matchRef.get();
    if (!matchSnapshot.exists) {
      throw StateError('The related match could not be found.');
    }

    final match = TournamentMatch.fromDocument(matchSnapshot);
    final outcome = deriveMatchScoreOutcome(match, submission.games);
    if (outcome == null) {
      throw StateError(
        'This submission does not contain a valid best-of-three result.',
      );
    }

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    batch.update(submissionRef, <String, Object>{
      'approvalStatus': ScoreApprovalStatus.approved.value,
      'approvedByUserId': approvedByUserId,
      'approvedByRole': approvedByRole,
      'approvedAt': now,
    });
    _applyCompletedMatchUpdate(
      batch: batch,
      matchRef: matchRef,
      scores: submission.games,
      winnerEntryId: outcome.winnerEntryId,
      winnerLabel: outcome.winnerLabel,
      officialScoreSubmissionId: submissionId,
      officializedByUserId: approvedByUserId,
      officializedByRole: approvedByRole,
      now: now,
    );

    await batch.commit();
  }

  Future<void> rejectSubmission({
    required String tournamentId,
    required String submissionId,
    required String approvedByUserId,
    required String approvedByRole,
    required String rejectedReason,
  }) async {
    final submissionRef = _submissions(tournamentId).doc(submissionId);
    final submissionSnapshot = await submissionRef.get();
    if (!submissionSnapshot.exists) {
      throw StateError('This score submission could not be found.');
    }

    final submission = ScoreSubmission.fromDocument(
      submissionSnapshot,
      tournamentId: tournamentId,
    );
    final matchRef = _matches(tournamentId).doc(submission.matchId);
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    batch.update(submissionRef, <String, Object>{
      'approvalStatus': ScoreApprovalStatus.rejected.value,
      'approvedByUserId': approvedByUserId,
      'approvedByRole': approvedByRole,
      'approvedAt': now,
      'rejectedReason': rejectedReason.trim().isEmpty
          ? 'Needs score correction.'
          : rejectedReason.trim(),
    });
    batch.update(matchRef, <String, Object>{
      'status': TournamentMatchStatus.onCourt.value,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> submitAndApproveAssistantScore({
    required String tournamentId,
    required String matchId,
    required String submittedByUserId,
    required String submittedByRole,
    required List<MatchGameScore> scores,
    String? note,
  }) async {
    final matchRef = _matches(tournamentId).doc(matchId);
    final matchSnapshot = await matchRef.get();
    if (!matchSnapshot.exists) {
      throw StateError('This match could not be found.');
    }

    final match = TournamentMatch.fromDocument(matchSnapshot);
    if (!(match.isOnCourt || match.isScoreSubmitted)) {
      throw StateError(
        'Only on-court matches can be completed from the assistant desk.',
      );
    }

    final outcome = deriveMatchScoreOutcome(match, scores);
    if (outcome == null) {
      throw StateError(
        'Enter a valid best-of-three result before completing the match.',
      );
    }

    final submissionRef = _submissions(tournamentId).doc();
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    batch.set(submissionRef, <String, Object?>{
      'matchId': matchId,
      'submittedByUserId': submittedByUserId,
      'submittedByRole': submittedByRole,
      'submittedAt': now,
      'games': scores.map((game) => game.toMap()).toList(growable: false),
      'proposedWinnerEntryId': outcome.winnerEntryId,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      'approvalStatus': ScoreApprovalStatus.approved.value,
      'approvedByUserId': submittedByUserId,
      'approvedByRole': submittedByRole,
      'approvedAt': now,
      'rejectedReason': null,
    });
    _applyCompletedMatchUpdate(
      batch: batch,
      matchRef: matchRef,
      scores: scores,
      winnerEntryId: outcome.winnerEntryId,
      winnerLabel: outcome.winnerLabel,
      officialScoreSubmissionId: submissionRef.id,
      officializedByUserId: submittedByUserId,
      officializedByRole: submittedByRole,
      now: now,
    );

    await batch.commit();
  }

  void _applyCompletedMatchUpdate({
    required WriteBatch batch,
    required DocumentReference<Map<String, dynamic>> matchRef,
    required List<MatchGameScore> scores,
    required String? winnerEntryId,
    required String winnerLabel,
    required String officialScoreSubmissionId,
    required String officializedByUserId,
    required String officializedByRole,
    required FieldValue now,
  }) {
    batch.update(matchRef, <String, Object?>{
      'scores': scores.map((score) => score.toMap()).toList(growable: false),
      'winnerEntryId': winnerEntryId,
      'winnerLabel': winnerLabel,
      'status': TournamentMatchStatus.completed.value,
      'completedAt': now,
      'officialScoreSubmissionId': officialScoreSubmissionId,
      'officializedByUserId': officializedByUserId,
      'officializedByRole': officializedByRole,
      'officializedAt': now,
      'updatedAt': now,
    });
  }
}
