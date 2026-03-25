import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_tournament/features/categories/domain/category_item.dart';
import 'package:tamil_tournament/features/entries/domain/entry.dart';
import 'package:tamil_tournament/features/scheduler/domain/category_schedule.dart';
import 'package:tamil_tournament/features/scheduler/domain/tournament_match.dart';
import 'package:tamil_tournament/features/scheduler/domain/tournament_standings.dart';

void main() {
  group('deriveTournamentStandings', () {
    test('marks top four as qualifying in round robin standings', () {
      final category = _category('c1', 'Mens Open');
      final entries = List.generate(
        5,
        (index) => _entry(
          id: 'e${index + 1}',
          categoryId: category.id,
          seedNumber: index + 1,
          categoryName: category.name,
        ),
      );
      final schedule = deriveTournamentCategorySchedules(
        categories: [category],
        entries: entries,
      );

      final standings = deriveTournamentStandings(
        scheduleSnapshot: schedule,
        matches: [
          _completedMatch(
            categoryId: category.id,
            categoryName: category.name,
            code: 'R1-M1',
            displayOrder: 1,
            teamOne: entries[0],
            teamTwo: entries[4],
            scores: const [
              MatchGameScore(
                gameNumber: 1,
                teamOnePoints: 21,
                teamTwoPoints: 17,
              ),
              MatchGameScore(
                gameNumber: 2,
                teamOnePoints: 21,
                teamTwoPoints: 16,
              ),
            ],
            winner: entries[0],
          ),
          _completedMatch(
            categoryId: category.id,
            categoryName: category.name,
            code: 'R1-M2',
            displayOrder: 2,
            teamOne: entries[1],
            teamTwo: entries[3],
            scores: const [
              MatchGameScore(
                gameNumber: 1,
                teamOnePoints: 18,
                teamTwoPoints: 21,
              ),
              MatchGameScore(
                gameNumber: 2,
                teamOnePoints: 16,
                teamTwoPoints: 21,
              ),
            ],
            winner: entries[3],
          ),
        ],
      );

      final rows = standings.categories.single.groups.single.rows;
      expect(rows.length, 5);
      expect(
        rows.where(
          (row) => row.qualifierStatus != StandingsQualifierStatus.outside,
        ),
        hasLength(4),
      );
      expect(rows.first.entry.id, 'e1');
    });

    test('marks group winners and best runner-up in grouped standings', () {
      final category = _category('c2', 'Women Open');
      final entries = List.generate(
        10,
        (index) => _entry(
          id: 'g${index + 1}',
          categoryId: category.id,
          seedNumber: index + 1,
          categoryName: category.name,
        ),
      );
      final schedule = deriveTournamentCategorySchedules(
        categories: [category],
        entries: entries,
      );

      final groupA = schedule.categories.single.groups[0].entries;
      final groupB = schedule.categories.single.groups[1].entries;
      final groupC = schedule.categories.single.groups[2].entries;

      final standings = deriveTournamentStandings(
        scheduleSnapshot: schedule,
        matches: [
          _completedMatch(
            categoryId: category.id,
            categoryName: category.name,
            code: 'A1',
            displayOrder: 1,
            teamOne: groupA[0],
            teamTwo: groupA[1],
            scores: const [
              MatchGameScore(
                gameNumber: 1,
                teamOnePoints: 21,
                teamTwoPoints: 9,
              ),
              MatchGameScore(
                gameNumber: 2,
                teamOnePoints: 21,
                teamTwoPoints: 13,
              ),
            ],
            winner: groupA[0],
          ),
          _completedMatch(
            categoryId: category.id,
            categoryName: category.name,
            code: 'B1',
            displayOrder: 2,
            teamOne: groupB[0],
            teamTwo: groupB[1],
            scores: const [
              MatchGameScore(
                gameNumber: 1,
                teamOnePoints: 21,
                teamTwoPoints: 18,
              ),
              MatchGameScore(
                gameNumber: 2,
                teamOnePoints: 21,
                teamTwoPoints: 14,
              ),
            ],
            winner: groupB[0],
          ),
          _completedMatch(
            categoryId: category.id,
            categoryName: category.name,
            code: 'C1',
            displayOrder: 3,
            teamOne: groupC[0],
            teamTwo: groupC[1],
            scores: const [
              MatchGameScore(
                gameNumber: 1,
                teamOnePoints: 19,
                teamTwoPoints: 21,
              ),
              MatchGameScore(
                gameNumber: 2,
                teamOnePoints: 16,
                teamTwoPoints: 21,
              ),
            ],
            winner: groupC[1],
          ),
        ],
      );

      final groups = standings.categories.single.groups;
      final allRows = groups
          .expand((group) => group.rows)
          .toList(growable: false);
      expect(
        allRows.where(
          (row) => row.qualifierStatus == StandingsQualifierStatus.winner,
        ),
        hasLength(3),
      );
      expect(
        allRows.where(
          (row) => row.qualifierStatus == StandingsQualifierStatus.qualifying,
        ),
        hasLength(1),
      );
    });
  });
}

CategoryItem _category(String id, String name) {
  return CategoryItem(
    id: id,
    tournamentId: 't1',
    name: name,
    format: CategoryFormat.group,
    minPlayers: 2,
    checkedInPairs: 0,
    isPublished: false,
    createdAt: null,
    updatedAt: null,
  );
}

TournamentEntry _entry({
  required String id,
  required String categoryId,
  required int seedNumber,
  required String categoryName,
}) {
  return TournamentEntry(
    id: id,
    tournamentId: 't1',
    categoryId: categoryId,
    teamName: 'Team $id',
    playerOne: 'P1 $id',
    playerTwo: 'P2 $id',
    seedNumber: seedNumber,
    categoryName: categoryName,
    checkedIn: true,
    createdAt: DateTime(2026, 3, 24),
    updatedAt: DateTime(2026, 3, 24),
  );
}

TournamentMatch _completedMatch({
  required String categoryId,
  required String categoryName,
  required String code,
  required int displayOrder,
  required TournamentEntry teamOne,
  required TournamentEntry teamTwo,
  required List<MatchGameScore> scores,
  required TournamentEntry winner,
}) {
  return TournamentMatch(
    id: code,
    tournamentId: 't1',
    categoryId: categoryId,
    categoryName: categoryName,
    matchCode: code,
    displayOrder: displayOrder,
    phase: 'pool',
    stageLabel: 'Pool play',
    roundTitle: 'Round 1',
    roundNumber: 1,
    groupCode: null,
    teamOneEntryId: teamOne.id,
    teamOneLabel: teamOne.displayLabel,
    teamOneDetail: teamOne.rosterLabel,
    teamTwoEntryId: teamTwo.id,
    teamTwoLabel: teamTwo.displayLabel,
    teamTwoDetail: teamTwo.rosterLabel,
    status: TournamentMatchStatus.completed,
    assignedCourtId: null,
    assignedCourtCode: null,
    assignedCourtName: null,
    scores: scores,
    winnerEntryId: winner.id,
    winnerLabel: winner.displayLabel,
    officialScoreSubmissionId: null,
    officializedByUserId: null,
    officializedByRole: null,
    officializedAt: null,
    createdAt: DateTime(2026, 3, 24),
    completedAt: DateTime(2026, 3, 24),
    updatedAt: DateTime(2026, 3, 24),
  );
}
