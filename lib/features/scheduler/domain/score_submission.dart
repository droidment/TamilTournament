import 'package:cloud_firestore/cloud_firestore.dart';

import 'tournament_match.dart';

enum ScoreApprovalStatus { pending, approved, rejected }

extension ScoreApprovalStatusX on ScoreApprovalStatus {
  String get value => switch (this) {
    ScoreApprovalStatus.pending => 'pending',
    ScoreApprovalStatus.approved => 'approved',
    ScoreApprovalStatus.rejected => 'rejected',
  };

  String get label => switch (this) {
    ScoreApprovalStatus.pending => 'Pending',
    ScoreApprovalStatus.approved => 'Approved',
    ScoreApprovalStatus.rejected => 'Rejected',
  };

  static ScoreApprovalStatus fromValue(String value) => switch (value) {
    'approved' => ScoreApprovalStatus.approved,
    'rejected' => ScoreApprovalStatus.rejected,
    _ => ScoreApprovalStatus.pending,
  };
}

final class ScoreSubmission {
  const ScoreSubmission({
    required this.id,
    required this.tournamentId,
    required this.matchId,
    required this.submittedByUserId,
    required this.submittedByRole,
    required this.submittedAt,
    required this.games,
    required this.proposedWinnerEntryId,
    required this.note,
    required this.approvalStatus,
    required this.approvedByUserId,
    required this.approvedByRole,
    required this.approvedAt,
    required this.rejectedReason,
  });

  final String id;
  final String tournamentId;
  final String matchId;
  final String submittedByUserId;
  final String submittedByRole;
  final DateTime? submittedAt;
  final List<MatchGameScore> games;
  final String? proposedWinnerEntryId;
  final String? note;
  final ScoreApprovalStatus approvalStatus;
  final String? approvedByUserId;
  final String? approvedByRole;
  final DateTime? approvedAt;
  final String? rejectedReason;

  factory ScoreSubmission.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String tournamentId,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    return ScoreSubmission(
      id: doc.id,
      tournamentId: tournamentId,
      matchId: data['matchId'] as String? ?? '',
      submittedByUserId: data['submittedByUserId'] as String? ?? '',
      submittedByRole: data['submittedByRole'] as String? ?? '',
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      games: ((data['games'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(MatchGameScore.fromMap)
          .toList(growable: false),
      proposedWinnerEntryId: data['proposedWinnerEntryId'] as String?,
      note: data['note'] as String?,
      approvalStatus: ScoreApprovalStatusX.fromValue(
        data['approvalStatus'] as String? ?? 'pending',
      ),
      approvedByUserId: data['approvedByUserId'] as String?,
      approvedByRole: data['approvedByRole'] as String?,
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedReason: data['rejectedReason'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'matchId': matchId,
      'submittedByUserId': submittedByUserId,
      'submittedByRole': submittedByRole,
      'submittedAt': submittedAt != null
          ? Timestamp.fromDate(submittedAt!)
          : FieldValue.serverTimestamp(),
      'games': games.map((game) => game.toMap()).toList(growable: false),
      'proposedWinnerEntryId': proposedWinnerEntryId,
      'note': note,
      'approvalStatus': approvalStatus.value,
      'approvedByUserId': approvedByUserId,
      'approvedByRole': approvedByRole,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedReason': rejectedReason,
    };
  }
}
