import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_tournament/features/scheduler/domain/tournament_match.dart';

void main() {
  group('deriveMatchScoreOutcome', () {
    test('returns the team one winner after two game wins', () {
      final match = _match();

      final outcome = deriveMatchScoreOutcome(match, const [
        MatchGameScore(gameNumber: 1, teamOnePoints: 21, teamTwoPoints: 15),
        MatchGameScore(gameNumber: 2, teamOnePoints: 18, teamTwoPoints: 21),
        MatchGameScore(gameNumber: 3, teamOnePoints: 21, teamTwoPoints: 12),
      ]);

      expect(outcome, isNotNull);
      expect(outcome!.winnerEntryId, 'e1');
      expect(outcome.winnerLabel, 'Bala Team');
      expect(outcome.teamOneGamesWon, 2);
      expect(outcome.teamTwoGamesWon, 1);
    });

    test('returns null when no side has won two games yet', () {
      final match = _match();

      final outcome = deriveMatchScoreOutcome(match, const [
        MatchGameScore(gameNumber: 1, teamOnePoints: 21, teamTwoPoints: 18),
      ]);

      expect(outcome, isNull);
    });

    test('returns null for tied games', () {
      final match = _match();

      final outcome = deriveMatchScoreOutcome(match, const [
        MatchGameScore(gameNumber: 1, teamOnePoints: 20, teamTwoPoints: 20),
        MatchGameScore(gameNumber: 2, teamOnePoints: 21, teamTwoPoints: 18),
      ]);

      expect(outcome, isNull);
    });
  });
}

TournamentMatch _match() {
  return const TournamentMatch(
    id: 'm1',
    tournamentId: 't1',
    categoryId: 'c1',
    categoryName: 'Mens Open',
    matchCode: 'M1',
    displayOrder: 1,
    phase: 'pool',
    stageLabel: 'Pool play',
    roundTitle: 'Round 1',
    roundNumber: 1,
    groupCode: 'A',
    teamOneEntryId: 'e1',
    teamOneLabel: 'Bala Team',
    teamOneDetail: 'Bala1 / Bala2',
    teamTwoEntryId: 'e2',
    teamTwoLabel: 'Raj / Bala',
    teamTwoDetail: 'Raj / Bala',
    status: TournamentMatchStatus.onCourt,
    assignedCourtId: 'court-1',
    assignedCourtCode: 'C1',
    assignedCourtName: 'Court 1',
    scores: <MatchGameScore>[],
    winnerEntryId: null,
    winnerLabel: null,
    officialScoreSubmissionId: null,
    officializedByUserId: null,
    officializedByRole: null,
    officializedAt: null,
    createdAt: null,
    completedAt: null,
    updatedAt: null,
  );
}
