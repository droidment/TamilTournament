import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/score_submission.dart';

final class ScoreSubmissionRepository {
  ScoreSubmissionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _submissionsRef(
    String tournamentId,
  ) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('scoreSubmissions');

  Stream<List<ScoreSubmission>> watchPendingSubmissions({
    required String tournamentId,
  }) {
    return _submissionsRef(tournamentId)
        .where('approvalStatus', isEqualTo: ScoreApprovalStatus.pending.value)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ScoreSubmission.fromDocument(
                  doc,
                  tournamentId: tournamentId,
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<List<ScoreSubmission>> watchSubmissionsForMatch({
    required String tournamentId,
    required String matchId,
  }) {
    return _submissionsRef(tournamentId)
        .where('matchId', isEqualTo: matchId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ScoreSubmission.fromDocument(
                  doc,
                  tournamentId: tournamentId,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<DocumentReference<Map<String, dynamic>>> createSubmission({
    required String tournamentId,
    required ScoreSubmission submission,
  }) {
    return _submissionsRef(tournamentId).add(submission.toMap());
  }

  Future<void> approveSubmission({
    required String tournamentId,
    required String submissionId,
    required String approvedByUserId,
    required String approvedByRole,
  }) {
    return _submissionsRef(tournamentId).doc(submissionId).update(
      <String, Object>{
        'approvalStatus': ScoreApprovalStatus.approved.value,
        'approvedByUserId': approvedByUserId,
        'approvedByRole': approvedByRole,
        'approvedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> rejectSubmission({
    required String tournamentId,
    required String submissionId,
    required String approvedByUserId,
    required String approvedByRole,
    required String rejectedReason,
  }) {
    return _submissionsRef(tournamentId).doc(submissionId).update(
      <String, Object>{
        'approvalStatus': ScoreApprovalStatus.rejected.value,
        'approvedByUserId': approvedByUserId,
        'approvedByRole': approvedByRole,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectedReason': rejectedReason,
      },
    );
  }
}
