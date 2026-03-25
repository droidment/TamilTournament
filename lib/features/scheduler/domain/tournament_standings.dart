import '../../entries/domain/entry.dart';
import 'category_schedule.dart';
import 'tournament_match.dart';

enum StandingsQualifierStatus { winner, qualifying, outside }

extension StandingsQualifierStatusX on StandingsQualifierStatus {
  String get label => switch (this) {
    StandingsQualifierStatus.winner => 'Group winner',
    StandingsQualifierStatus.qualifying => 'Qualification line',
    StandingsQualifierStatus.outside => 'Outside line',
  };
}

final class TournamentStandingsSnapshot {
  TournamentStandingsSnapshot({required List<CategoryStandings> categories})
    : categories = List.unmodifiable(categories);

  final List<CategoryStandings> categories;

  bool get isEmpty => categories.isEmpty;
}

final class CategoryStandings {
  CategoryStandings({
    required this.categoryId,
    required this.categoryName,
    required this.mode,
    required this.qualifierCount,
    required this.knockoutBracketSize,
    required this.completedPoolMatches,
    required this.totalPoolMatches,
    required this.qualificationSummary,
    required List<GroupStandings> groups,
  }) : groups = List.unmodifiable(groups);

  final String categoryId;
  final String categoryName;
  final GeneratedScheduleMode mode;
  final int qualifierCount;
  final int knockoutBracketSize;
  final int completedPoolMatches;
  final int totalPoolMatches;
  final String qualificationSummary;
  final List<GroupStandings> groups;

  double get completionProgress {
    if (totalPoolMatches == 0) {
      return 0;
    }
    return completedPoolMatches / totalPoolMatches;
  }

  bool get isPoolPhaseComplete =>
      totalPoolMatches > 0 && completedPoolMatches >= totalPoolMatches;

  Map<String, StandingRow> get qualificationSources {
    final sources = <String, StandingRow>{};
    if (!isPoolPhaseComplete) {
      return sources;
    }

    if (mode == GeneratedScheduleMode.roundRobinTop4) {
      final rows = groups.expand((group) => group.rows).toList(growable: false)
        ..sort((left, right) => left.rank.compareTo(right.rank));
      for (final row in rows) {
        sources['Rank ${row.rank}'] = row;
      }
      return sources;
    }

    for (final group in groups) {
      if (group.rows.isEmpty) {
        continue;
      }
      sources['Winner Group ${group.code}'] = group.rows.first;
      if (group.rows.length > 1) {
        sources['Runner-up Group ${group.code}'] = group.rows[1];
      }
    }
    return sources;
  }
}

final class GroupStandings {
  GroupStandings({
    required this.code,
    required this.label,
    required List<StandingRow> rows,
  }) : rows = List.unmodifiable(rows);

  final String code;
  final String label;
  final List<StandingRow> rows;
}

final class StandingRow {
  const StandingRow({
    required this.entry,
    required this.groupCode,
    required this.rank,
    required this.played,
    required this.wins,
    required this.losses,
    required this.gamesWon,
    required this.gamesLost,
    required this.pointsWon,
    required this.pointsLost,
    required this.qualifierStatus,
  });

  final TournamentEntry entry;
  final String groupCode;
  final int rank;
  final int played;
  final int wins;
  final int losses;
  final int gamesWon;
  final int gamesLost;
  final int pointsWon;
  final int pointsLost;
  final StandingsQualifierStatus qualifierStatus;

  int get gameDifferential => gamesWon - gamesLost;
  int get pointDifferential => pointsWon - pointsLost;
}

TournamentStandingsSnapshot deriveTournamentStandings({
  required TournamentCategoryScheduleSnapshot scheduleSnapshot,
  required List<TournamentMatch> matches,
}) {
  final categories = <CategoryStandings>[];

  for (final category in scheduleSnapshot.categories) {
    final entryStates = <String, _StandingState>{};
    final groupByEntryId = <String, String>{};
    final seedOrderByEntryId = <String, int>{};

    for (
      var seedIndex = 0;
      seedIndex < category.seededEntries.length;
      seedIndex++
    ) {
      final entry = category.seededEntries[seedIndex];
      seedOrderByEntryId[entry.id] = seedIndex;
    }

    for (final group in category.groups) {
      for (final entry in group.entries) {
        groupByEntryId[entry.id] = group.code;
        entryStates[entry.id] = _StandingState(
          entry: entry,
          groupCode: group.code,
        );
      }
    }

    final completedPoolMatches = matches
        .where((match) {
          return match.categoryId == category.categoryId &&
              match.phase == 'pool' &&
              match.isCompleted &&
              match.teamOneEntryId != null &&
              match.teamTwoEntryId != null &&
              match.scores.isNotEmpty;
        })
        .toList(growable: false);

    for (final match in completedPoolMatches) {
      final teamOneId = match.teamOneEntryId!;
      final teamTwoId = match.teamTwoEntryId!;
      final left = entryStates[teamOneId];
      final right = entryStates[teamTwoId];
      if (left == null || right == null) {
        continue;
      }

      left.played += 1;
      right.played += 1;

      var leftGames = 0;
      var rightGames = 0;
      var leftPoints = 0;
      var rightPoints = 0;

      for (final score in match.scores) {
        leftPoints += score.teamOnePoints;
        rightPoints += score.teamTwoPoints;
        if (score.teamOnePoints > score.teamTwoPoints) {
          leftGames += 1;
        } else if (score.teamTwoPoints > score.teamOnePoints) {
          rightGames += 1;
        }
      }

      left.gamesWon += leftGames;
      left.gamesLost += rightGames;
      right.gamesWon += rightGames;
      right.gamesLost += leftGames;
      left.pointsWon += leftPoints;
      left.pointsLost += rightPoints;
      right.pointsWon += rightPoints;
      right.pointsLost += leftPoints;

      if (match.winnerEntryId == teamOneId) {
        left.wins += 1;
        right.losses += 1;
      } else if (match.winnerEntryId == teamTwoId) {
        right.wins += 1;
        left.losses += 1;
      }
    }

    final sortedByGroup = <String, List<_StandingState>>{};
    for (final state in entryStates.values) {
      sortedByGroup
          .putIfAbsent(state.groupCode, () => <_StandingState>[])
          .add(state);
    }
    for (final states in sortedByGroup.values) {
      states.sort(
        (left, right) => _compareStandingState(
          left,
          right,
          seedOrderByEntryId: seedOrderByEntryId,
        ),
      );
      for (var index = 0; index < states.length; index++) {
        states[index].rank = index + 1;
      }
    }

    _markQualifiers(
      category: category,
      groupedStates: sortedByGroup,
      seedOrderByEntryId: seedOrderByEntryId,
    );

    final groups = category.groups
        .map((group) {
          final states = List<_StandingState>.from(
            sortedByGroup[group.code] ?? const <_StandingState>[],
          );
          return GroupStandings(
            code: group.code,
            label: category.groups.length > 1
                ? 'Pool ${group.code}'
                : 'Standings',
            rows: states
                .map(
                  (state) => StandingRow(
                    entry: state.entry,
                    groupCode: state.groupCode,
                    rank: state.rank,
                    played: state.played,
                    wins: state.wins,
                    losses: state.losses,
                    gamesWon: state.gamesWon,
                    gamesLost: state.gamesLost,
                    pointsWon: state.pointsWon,
                    pointsLost: state.pointsLost,
                    qualifierStatus: state.qualifierStatus,
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);

    categories.add(
      CategoryStandings(
        categoryId: category.categoryId,
        categoryName: category.categoryName,
        mode: category.mode,
        qualifierCount: category.qualifierCount,
        knockoutBracketSize: category.knockoutBracketSize,
        completedPoolMatches: completedPoolMatches.length,
        totalPoolMatches: category.rounds.fold<int>(
          0,
          (sum, round) =>
              sum + round.matches.where((match) => !match.hasBye).length,
        ),
        qualificationSummary: category.qualificationSummary,
        groups: groups,
      ),
    );
  }

  return TournamentStandingsSnapshot(categories: categories);
}

void _markQualifiers({
  required GeneratedCategorySchedule category,
  required Map<String, List<_StandingState>> groupedStates,
  required Map<String, int> seedOrderByEntryId,
}) {
  if (category.mode == GeneratedScheduleMode.roundRobinTop4) {
    final allStates =
        groupedStates.values.expand((states) => states).toList(growable: false)
          ..sort(
            (left, right) => _compareStandingState(
              left,
              right,
              seedOrderByEntryId: seedOrderByEntryId,
            ),
          );
    for (var index = 0; index < allStates.length && index < 4; index++) {
      allStates[index].qualifierStatus = StandingsQualifierStatus.qualifying;
    }
    return;
  }

  final winners = <_StandingState>[];
  final runnersUp = <_StandingState>[];
  for (final group in category.groups) {
    final states = groupedStates[group.code] ?? const <_StandingState>[];
    if (states.isEmpty) {
      continue;
    }
    winners.add(states.first);
    states.first.qualifierStatus = StandingsQualifierStatus.winner;
    if (states.length > 1) {
      runnersUp.add(states[1]);
    }
  }

  if (category.qualifierCount <= winners.length) {
    return;
  }

  runnersUp.sort(
    (left, right) => _compareStandingState(
      left,
      right,
      seedOrderByEntryId: seedOrderByEntryId,
    ),
  );
  final extraQualifiers = category.qualifierCount - winners.length;
  for (
    var index = 0;
    index < runnersUp.length && index < extraQualifiers;
    index++
  ) {
    runnersUp[index].qualifierStatus = StandingsQualifierStatus.qualifying;
  }
}

int _compareStandingState(
  _StandingState left,
  _StandingState right, {
  required Map<String, int> seedOrderByEntryId,
}) {
  final byWins = right.wins.compareTo(left.wins);
  if (byWins != 0) {
    return byWins;
  }

  final byGameDifferential = right.gameDifferential.compareTo(
    left.gameDifferential,
  );
  if (byGameDifferential != 0) {
    return byGameDifferential;
  }

  final byPointDifferential = right.pointDifferential.compareTo(
    left.pointDifferential,
  );
  if (byPointDifferential != 0) {
    return byPointDifferential;
  }

  final byPointsWon = right.pointsWon.compareTo(left.pointsWon);
  if (byPointsWon != 0) {
    return byPointsWon;
  }

  final leftSeed = seedOrderByEntryId[left.entry.id] ?? 9999;
  final rightSeed = seedOrderByEntryId[right.entry.id] ?? 9999;
  final bySeed = leftSeed.compareTo(rightSeed);
  if (bySeed != 0) {
    return bySeed;
  }

  return left.entry.displayLabel.toLowerCase().compareTo(
    right.entry.displayLabel.toLowerCase(),
  );
}

final class _StandingState {
  _StandingState({required this.entry, required this.groupCode});

  final TournamentEntry entry;
  final String groupCode;
  int rank = 0;
  int played = 0;
  int wins = 0;
  int losses = 0;
  int gamesWon = 0;
  int gamesLost = 0;
  int pointsWon = 0;
  int pointsLost = 0;
  StandingsQualifierStatus qualifierStatus = StandingsQualifierStatus.outside;

  int get gameDifferential => gamesWon - gamesLost;
  int get pointDifferential => pointsWon - pointsLost;
}
