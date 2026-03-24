import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentMatchStatus { pending, ready, onCourt, completed }

extension TournamentMatchStatusX on TournamentMatchStatus {
  String get value => switch (this) {
    TournamentMatchStatus.pending => 'pending',
    TournamentMatchStatus.ready => 'ready',
    TournamentMatchStatus.onCourt => 'on_court',
    TournamentMatchStatus.completed => 'completed',
  };

  String get label => switch (this) {
    TournamentMatchStatus.pending => 'Pending',
    TournamentMatchStatus.ready => 'Ready',
    TournamentMatchStatus.onCourt => 'On court',
    TournamentMatchStatus.completed => 'Completed',
  };

  static TournamentMatchStatus fromValue(String value) => switch (value) {
    'ready' => TournamentMatchStatus.ready,
    'on_court' => TournamentMatchStatus.onCourt,
    'completed' => TournamentMatchStatus.completed,
    _ => TournamentMatchStatus.pending,
  };
}

final class TournamentMatch {
  const TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.categoryId,
    required this.categoryName,
    required this.matchCode,
    required this.displayOrder,
    required this.phase,
    required this.stageLabel,
    required this.roundTitle,
    required this.roundNumber,
    required this.groupCode,
    required this.teamOneEntryId,
    required this.teamOneLabel,
    required this.teamOneDetail,
    required this.teamTwoEntryId,
    required this.teamTwoLabel,
    required this.teamTwoDetail,
    required this.status,
    required this.assignedCourtId,
    required this.assignedCourtCode,
    required this.assignedCourtName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final String categoryId;
  final String categoryName;
  final String matchCode;
  final int displayOrder;
  final String phase;
  final String stageLabel;
  final String roundTitle;
  final int roundNumber;
  final String? groupCode;
  final String? teamOneEntryId;
  final String teamOneLabel;
  final String teamOneDetail;
  final String? teamTwoEntryId;
  final String teamTwoLabel;
  final String teamTwoDetail;
  final TournamentMatchStatus status;
  final String? assignedCourtId;
  final String? assignedCourtCode;
  final String? assignedCourtName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPending => status == TournamentMatchStatus.pending;
  bool get isReady => status == TournamentMatchStatus.ready;
  bool get isOnCourt => status == TournamentMatchStatus.onCourt;
  bool get isCompleted => status == TournamentMatchStatus.completed;

  bool get hasResolvedTeams =>
      teamOneEntryId != null &&
      teamOneEntryId!.isNotEmpty &&
      teamTwoEntryId != null &&
      teamTwoEntryId!.isNotEmpty;

  factory TournamentMatch.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return TournamentMatch(
      id: doc.id,
      tournamentId: data['tournamentId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? 'Unassigned',
      matchCode: data['matchCode'] as String? ?? doc.id,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 0,
      phase: data['phase'] as String? ?? 'pool',
      stageLabel: data['stageLabel'] as String? ?? 'Match',
      roundTitle: data['roundTitle'] as String? ?? 'Match',
      roundNumber: (data['roundNumber'] as num?)?.toInt() ?? 0,
      groupCode: data['groupCode'] as String?,
      teamOneEntryId: data['teamOneEntryId'] as String?,
      teamOneLabel: data['teamOneLabel'] as String? ?? 'TBD',
      teamOneDetail: data['teamOneDetail'] as String? ?? '',
      teamTwoEntryId: data['teamTwoEntryId'] as String?,
      teamTwoLabel: data['teamTwoLabel'] as String? ?? 'TBD',
      teamTwoDetail: data['teamTwoDetail'] as String? ?? '',
      status: TournamentMatchStatusX.fromValue(
        data['status'] as String? ?? TournamentMatchStatus.pending.value,
      ),
      assignedCourtId: data['assignedCourtId'] as String?,
      assignedCourtCode: data['assignedCourtCode'] as String?,
      assignedCourtName: data['assignedCourtName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
