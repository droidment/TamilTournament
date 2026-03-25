import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentMatchStatus {
  pending,
  ready,
  assigned,
  called,
  onCourt,
  scoreSubmitted,
  completed,
  held,
  cancelled,
  forfeit,
}

extension TournamentMatchStatusX on TournamentMatchStatus {
  String get value => switch (this) {
    TournamentMatchStatus.pending => 'pending',
    TournamentMatchStatus.ready => 'ready',
    TournamentMatchStatus.assigned => 'assigned',
    TournamentMatchStatus.called => 'called',
    TournamentMatchStatus.onCourt => 'on_court',
    TournamentMatchStatus.scoreSubmitted => 'score_submitted',
    TournamentMatchStatus.completed => 'completed',
    TournamentMatchStatus.held => 'held',
    TournamentMatchStatus.cancelled => 'cancelled',
    TournamentMatchStatus.forfeit => 'forfeit',
  };

  String get label => switch (this) {
    TournamentMatchStatus.pending => 'Pending',
    TournamentMatchStatus.ready => 'Ready',
    TournamentMatchStatus.assigned => 'Assigned',
    TournamentMatchStatus.called => 'Called',
    TournamentMatchStatus.onCourt => 'On court',
    TournamentMatchStatus.scoreSubmitted => 'Score submitted',
    TournamentMatchStatus.completed => 'Completed',
    TournamentMatchStatus.held => 'Held',
    TournamentMatchStatus.cancelled => 'Cancelled',
    TournamentMatchStatus.forfeit => 'Forfeit',
  };

  static TournamentMatchStatus fromValue(String value) => switch (value) {
    'ready' => TournamentMatchStatus.ready,
    'assigned' => TournamentMatchStatus.assigned,
    'called' => TournamentMatchStatus.called,
    'on_court' => TournamentMatchStatus.onCourt,
    'score_submitted' => TournamentMatchStatus.scoreSubmitted,
    'completed' => TournamentMatchStatus.completed,
    'held' => TournamentMatchStatus.held,
    'cancelled' => TournamentMatchStatus.cancelled,
    'forfeit' => TournamentMatchStatus.forfeit,
    _ => TournamentMatchStatus.pending,
  };
}

final class MatchGameScore {
  const MatchGameScore({
    required this.gameNumber,
    required this.teamOnePoints,
    required this.teamTwoPoints,
  });

  final int gameNumber;
  final int teamOnePoints;
  final int teamTwoPoints;

  Map<String, Object> toMap() {
    return <String, Object>{
      'gameNumber': gameNumber,
      'teamOnePoints': teamOnePoints,
      'teamTwoPoints': teamTwoPoints,
    };
  }

  factory MatchGameScore.fromMap(Map<String, dynamic> data) {
    return MatchGameScore(
      gameNumber: (data['gameNumber'] as num?)?.toInt() ?? 0,
      teamOnePoints: (data['teamOnePoints'] as num?)?.toInt() ?? 0,
      teamTwoPoints: (data['teamTwoPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

final class MatchScoreOutcome {
  const MatchScoreOutcome({
    required this.teamOneGamesWon,
    required this.teamTwoGamesWon,
    required this.winnerEntryId,
    required this.winnerLabel,
  });

  final int teamOneGamesWon;
  final int teamTwoGamesWon;
  final String? winnerEntryId;
  final String winnerLabel;
}

final class TournamentWinnerSummary {
  const TournamentWinnerSummary({
    required this.categoryId,
    required this.categoryName,
    required this.championEntryId,
    required this.championLabel,
    required this.runnerUpEntryId,
    required this.runnerUpLabel,
    required this.scoreSummary,
  });

  final String categoryId;
  final String categoryName;
  final String? championEntryId;
  final String championLabel;
  final String? runnerUpEntryId;
  final String runnerUpLabel;
  final String scoreSummary;
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
    required this.scores,
    required this.winnerEntryId,
    required this.winnerLabel,
    required this.officialScoreSubmissionId,
    required this.officializedByUserId,
    required this.officializedByRole,
    required this.officializedAt,
    required this.createdAt,
    required this.completedAt,
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
  final List<MatchGameScore> scores;
  final String? winnerEntryId;
  final String? winnerLabel;
  final String? officialScoreSubmissionId;
  final String? officializedByUserId;
  final String? officializedByRole;
  final DateTime? officializedAt;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  bool get isPending => status == TournamentMatchStatus.pending;
  bool get isReady => status == TournamentMatchStatus.ready;
  bool get isOnCourt => status == TournamentMatchStatus.onCourt;
  bool get isCompleted => status == TournamentMatchStatus.completed;
  bool get hasScores => scores.isNotEmpty;
  String get scoreSummary => scores
      .map((score) => '${score.teamOnePoints}-${score.teamTwoPoints}')
      .join(' · ');

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
      scores: ((data['scores'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(MatchGameScore.fromMap)
          .toList(growable: false),
      winnerEntryId: data['winnerEntryId'] as String?,
      winnerLabel: data['winnerLabel'] as String?,
      officialScoreSubmissionId:
          data['officialScoreSubmissionId'] as String?,
      officializedByUserId: data['officializedByUserId'] as String?,
      officializedByRole: data['officializedByRole'] as String?,
      officializedAt: (data['officializedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

bool isChampionshipMatch(TournamentMatch match) {
  final normalizedCode = match.matchCode.toLowerCase();
  final normalizedStage = match.stageLabel.toLowerCase();
  return normalizedCode.contains('final') ||
      normalizedStage.contains('championship');
}

List<TournamentWinnerSummary> deriveCompletedWinnerSummaries(
  List<TournamentMatch> matches,
) {
  final summaries =
      matches
          .where(
            (match) =>
                match.phase == 'knockout' &&
                match.isCompleted &&
                isChampionshipMatch(match) &&
                (match.winnerLabel?.trim().isNotEmpty ?? false),
          )
          .map((match) {
            final championIsTeamOne =
                match.winnerEntryId == match.teamOneEntryId;
            return TournamentWinnerSummary(
              categoryId: match.categoryId,
              categoryName: match.categoryName,
              championEntryId: match.winnerEntryId,
              championLabel: match.winnerLabel!.trim(),
              runnerUpEntryId: championIsTeamOne
                  ? match.teamTwoEntryId
                  : match.teamOneEntryId,
              runnerUpLabel: championIsTeamOne
                  ? match.teamTwoLabel
                  : match.teamOneLabel,
              scoreSummary: match.scoreSummary,
            );
          })
          .toList(growable: false)
        ..sort(
          (left, right) => left.categoryName.toLowerCase().compareTo(
            right.categoryName.toLowerCase(),
          ),
        );
  return summaries;
}

MatchScoreOutcome? deriveMatchScoreOutcome(
  TournamentMatch match,
  List<MatchGameScore> scores,
) {
  var teamOneGamesWon = 0;
  var teamTwoGamesWon = 0;

  for (final score in scores) {
    if (score.teamOnePoints == score.teamTwoPoints) {
      return null;
    }
    if (score.teamOnePoints > score.teamTwoPoints) {
      teamOneGamesWon += 1;
    } else {
      teamTwoGamesWon += 1;
    }
  }

  if (teamOneGamesWon < 2 && teamTwoGamesWon < 2) {
    return null;
  }

  final teamOneWon = teamOneGamesWon > teamTwoGamesWon;
  return MatchScoreOutcome(
    teamOneGamesWon: teamOneGamesWon,
    teamTwoGamesWon: teamTwoGamesWon,
    winnerEntryId: teamOneWon ? match.teamOneEntryId : match.teamTwoEntryId,
    winnerLabel: teamOneWon ? match.teamOneLabel : match.teamTwoLabel,
  );
}
