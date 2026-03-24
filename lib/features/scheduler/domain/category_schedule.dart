import 'dart:math' as math;

import '../../categories/domain/category_item.dart';
import '../../entries/domain/entry.dart';
import 'scheduling_seed.dart';

enum GeneratedScheduleMode { roundRobinTop4, groupsKnockout }

extension GeneratedScheduleModeX on GeneratedScheduleMode {
  String get label => switch (this) {
    GeneratedScheduleMode.roundRobinTop4 => 'Round robin top 4',
    GeneratedScheduleMode.groupsKnockout => 'Pool play + knockout',
  };

  String get subtitle => switch (this) {
    GeneratedScheduleMode.roundRobinTop4 =>
      'Single pool, top 4 move into semifinals.',
    GeneratedScheduleMode.groupsKnockout =>
      'Seeded pool play with knockout qualifiers.',
  };
}

final class TournamentCategoryScheduleSnapshot {
  TournamentCategoryScheduleSnapshot({
    required List<GeneratedCategorySchedule> categories,
  }) : categories = List.unmodifiable(categories);

  final List<GeneratedCategorySchedule> categories;

  bool get isEmpty => categories.isEmpty;

  int get totalMatches => categories.fold<int>(
    0,
    (sum, category) => sum + category.playableMatchCount,
  );

  int get totalRounds =>
      categories.fold<int>(0, (sum, category) => sum + category.rounds.length);

  int get totalGroups =>
      categories.fold<int>(0, (sum, category) => sum + category.groups.length);
}

final class GeneratedCategorySchedule {
  GeneratedCategorySchedule({
    required this.categoryId,
    required this.categoryName,
    required this.mode,
    required List<TournamentEntry> seededEntries,
    required List<GeneratedScheduleGroup> groups,
    required List<GeneratedScheduleRound> rounds,
    required List<GeneratedQualificationMatch> qualificationMatches,
    required this.qualifierCount,
    required this.knockoutBracketSize,
    required this.categoryFormat,
  }) : seededEntries = List.unmodifiable(seededEntries),
       groups = List.unmodifiable(groups),
       rounds = List.unmodifiable(rounds),
       qualificationMatches = List.unmodifiable(qualificationMatches);

  final String categoryId;
  final String categoryName;
  final CategoryFormat categoryFormat;
  final GeneratedScheduleMode mode;
  final List<TournamentEntry> seededEntries;
  final List<GeneratedScheduleGroup> groups;
  final List<GeneratedScheduleRound> rounds;
  final List<GeneratedQualificationMatch> qualificationMatches;
  final int qualifierCount;
  final int knockoutBracketSize;

  int get teamCount => seededEntries.length;

  int get playableMatchCount =>
      rounds.fold<int>(
        0,
        (sum, round) =>
            sum + round.matches.where((match) => !match.hasBye).length,
      ) +
      qualificationMatches.length;

  String get qualificationSummary {
    if (qualifierCount == 0) {
      return 'No knockout stage';
    }
    if (knockoutBracketSize == 4) {
      return '$qualifierCount qualifiers to semifinals';
    }
    return '$qualifierCount qualifiers to quarterfinals';
  }
}

final class GeneratedScheduleGroup {
  GeneratedScheduleGroup({
    required this.code,
    required List<TournamentEntry> entries,
  }) : entries = List.unmodifiable(entries);

  final String code;
  final List<TournamentEntry> entries;
}

final class GeneratedScheduleRound {
  GeneratedScheduleRound({
    required this.title,
    required this.roundNumber,
    this.groupCode,
    required List<GeneratedScheduledMatch> matches,
  }) : matches = List.unmodifiable(matches);

  final String title;
  final int roundNumber;
  final String? groupCode;
  final List<GeneratedScheduledMatch> matches;
}

final class GeneratedScheduledMatch {
  const GeneratedScheduledMatch({
    required this.code,
    required this.roundNumber,
    required this.teamOne,
    required this.teamTwo,
    required this.hasBye,
    this.groupCode,
  });

  final String code;
  final int roundNumber;
  final TournamentEntry teamOne;
  final TournamentEntry? teamTwo;
  final bool hasBye;
  final String? groupCode;
}

final class GeneratedQualificationMatch {
  const GeneratedQualificationMatch({
    required this.label,
    required this.homeSource,
    required this.awaySource,
    required this.stageLabel,
  });

  final String label;
  final String homeSource;
  final String awaySource;
  final String stageLabel;
}

TournamentCategoryScheduleSnapshot deriveTournamentCategorySchedules({
  required List<CategoryItem> categories,
  required List<TournamentEntry> entries,
  List<SchedulingSeedPlan> seedPlans = const [],
}) {
  final categoryEntries = <String, List<TournamentEntry>>{};
  for (final entry in entries) {
    if (entry.categoryId.isEmpty) {
      continue;
    }
    categoryEntries
        .putIfAbsent(entry.categoryId, () => <TournamentEntry>[])
        .add(entry);
  }

  final seedPlansByCategoryId = <String, SchedulingSeedPlan>{
    for (final plan in seedPlans) plan.categoryId: plan,
  };

  final generated = <GeneratedCategorySchedule>[];
  for (final category in categories) {
    final categoryEntriesForSchedule = List<TournamentEntry>.from(
      categoryEntries[category.id] ?? const <TournamentEntry>[],
    );
    final orderedEntries = _orderEntriesForCategory(
      entries: categoryEntriesForSchedule,
      seedEntryIds: seedPlansByCategoryId[category.id]?.seedEntryIds,
    );
    final schedule = deriveCompetitionSchedule(
      categoryId: category.id,
      categoryName: category.name,
      seededEntries: orderedEntries,
      legacyFormat: category.format,
    );
    if (schedule != null) {
      generated.add(schedule);
    }
  }

  return TournamentCategoryScheduleSnapshot(categories: generated);
}

GeneratedCategorySchedule? deriveCompetitionSchedule({
  required String categoryId,
  required String categoryName,
  required List<TournamentEntry> seededEntries,
  CategoryFormat legacyFormat = CategoryFormat.group,
}) {
  if (seededEntries.length < 2) {
    return null;
  }

  final normalizedEntries = List<TournamentEntry>.unmodifiable(seededEntries);
  final mode = _deriveMode(normalizedEntries.length);
  return switch (mode) {
    GeneratedScheduleMode.roundRobinTop4 => _buildRoundRobinCategorySchedule(
      categoryId: categoryId,
      categoryName: categoryName,
      seededEntries: normalizedEntries,
      legacyFormat: legacyFormat,
    ),
    GeneratedScheduleMode.groupsKnockout => _buildGroupedCategorySchedule(
      categoryId: categoryId,
      categoryName: categoryName,
      seededEntries: normalizedEntries,
      legacyFormat: legacyFormat,
    ),
  };
}

GeneratedScheduleMode deriveCompetitionModeForSeedCount(int seededTeamCount) {
  return _deriveMode(seededTeamCount);
}

int derivePoolCountForSeedCount(int seededTeamCount) {
  if (seededTeamCount < 8) {
    return 1;
  }
  return math.max(2, (seededTeamCount / 4).ceil());
}

GeneratedCategorySchedule _buildRoundRobinCategorySchedule({
  required String categoryId,
  required String categoryName,
  required List<TournamentEntry> seededEntries,
  required CategoryFormat legacyFormat,
}) {
  final rounds = _buildRoundRobinRounds(
    entries: seededEntries,
    titleBuilder: (roundNumber) => 'Round $roundNumber',
  );
  final qualificationMatches = seededEntries.length >= 4
      ? const [
          GeneratedQualificationMatch(
            label: 'Semifinal 1',
            homeSource: 'Rank 1',
            awaySource: 'Rank 4',
            stageLabel: 'Semifinal',
          ),
          GeneratedQualificationMatch(
            label: 'Semifinal 2',
            homeSource: 'Rank 2',
            awaySource: 'Rank 3',
            stageLabel: 'Semifinal',
          ),
          GeneratedQualificationMatch(
            label: 'Final',
            homeSource: 'Winner SF1',
            awaySource: 'Winner SF2',
            stageLabel: 'Championship',
          ),
        ]
      : const <GeneratedQualificationMatch>[];

  return GeneratedCategorySchedule(
    categoryId: categoryId,
    categoryName: categoryName,
    mode: GeneratedScheduleMode.roundRobinTop4,
    seededEntries: seededEntries,
    groups: [GeneratedScheduleGroup(code: 'All', entries: seededEntries)],
    rounds: rounds,
    qualificationMatches: qualificationMatches,
    qualifierCount: seededEntries.length >= 4 ? 4 : 0,
    knockoutBracketSize: seededEntries.length >= 4 ? 4 : 0,
    categoryFormat: legacyFormat,
  );
}

GeneratedCategorySchedule _buildGroupedCategorySchedule({
  required String categoryId,
  required String categoryName,
  required List<TournamentEntry> seededEntries,
  required CategoryFormat legacyFormat,
}) {
  final groups = _snakeSeedGroups(seededEntries);
  final roundsByGroup = <List<GeneratedScheduleRound>>[
    for (final group in groups)
      _buildRoundRobinRounds(
        entries: group.entries,
        groupCode: group.code,
        titleBuilder: (roundNumber) =>
            'Group ${group.code} - Round $roundNumber',
      ),
  ];
  final interleavedRounds = _interleaveRounds(roundsByGroup);
  final qualifierCount = _deriveKnockoutBracketSize(groups.length);
  final qualifierSources = _buildQualifierSources(
    groups: groups,
    qualifierCount: qualifierCount,
  );

  return GeneratedCategorySchedule(
    categoryId: categoryId,
    categoryName: categoryName,
    mode: GeneratedScheduleMode.groupsKnockout,
    seededEntries: seededEntries,
    groups: groups,
    rounds: interleavedRounds,
    qualificationMatches: _buildKnockoutPath(qualifierSources),
    qualifierCount: qualifierCount,
    knockoutBracketSize: qualifierCount,
    categoryFormat: legacyFormat,
  );
}

GeneratedScheduleMode _deriveMode(int seededTeamCount) {
  if (seededTeamCount >= 8) {
    return GeneratedScheduleMode.groupsKnockout;
  }
  return GeneratedScheduleMode.roundRobinTop4;
}

List<TournamentEntry> _orderEntriesForCategory({
  required List<TournamentEntry> entries,
  List<String>? seedEntryIds,
}) {
  final sortedEntries = List<TournamentEntry>.from(entries)
    ..sort(compareEntriesForSeeding);
  if (seedEntryIds == null || seedEntryIds.isEmpty) {
    return List<TournamentEntry>.unmodifiable(sortedEntries);
  }

  final entryById = <String, TournamentEntry>{
    for (final entry in sortedEntries) entry.id: entry,
  };
  final seen = <String>{};
  final ordered = <TournamentEntry>[];

  for (final entryId in seedEntryIds) {
    if (!seen.add(entryId)) {
      continue;
    }
    final entry = entryById[entryId];
    if (entry != null) {
      ordered.add(entry);
    }
  }

  for (final entry in sortedEntries) {
    if (seen.add(entry.id)) {
      ordered.add(entry);
    }
  }

  return List<TournamentEntry>.unmodifiable(ordered);
}

List<GeneratedScheduleRound> _interleaveRounds(
  List<List<GeneratedScheduleRound>> roundsByGroup,
) {
  final rounds = <GeneratedScheduleRound>[];
  final maxRounds = roundsByGroup.fold<int>(
    0,
    (maxCount, groupRounds) => math.max(maxCount, groupRounds.length),
  );
  for (var roundIndex = 0; roundIndex < maxRounds; roundIndex++) {
    for (final groupRounds in roundsByGroup) {
      if (roundIndex < groupRounds.length) {
        rounds.add(groupRounds[roundIndex]);
      }
    }
  }
  return List<GeneratedScheduleRound>.unmodifiable(rounds);
}

List<GeneratedScheduleGroup> _snakeSeedGroups(
  List<TournamentEntry> seededEntries,
) {
  final groupCount = derivePoolCountForSeedCount(seededEntries.length);
  final baseSize = seededEntries.length ~/ groupCount;
  final remainder = seededEntries.length % groupCount;
  final capacities = <int>[
    for (var index = 0; index < groupCount; index++)
      baseSize + (index < remainder ? 1 : 0),
  ];

  final buckets = <List<TournamentEntry>>[
    for (var index = 0; index < groupCount; index++) <TournamentEntry>[],
  ];

  var nextEntryIndex = 0;
  var forward = true;
  while (nextEntryIndex < seededEntries.length) {
    final pass = forward
        ? List<int>.generate(groupCount, (index) => index)
        : List<int>.generate(groupCount, (index) => groupCount - 1 - index);
    for (final groupIndex in pass) {
      if (nextEntryIndex >= seededEntries.length) {
        break;
      }
      if (buckets[groupIndex].length >= capacities[groupIndex]) {
        continue;
      }
      buckets[groupIndex].add(seededEntries[nextEntryIndex]);
      nextEntryIndex += 1;
    }
    forward = !forward;
  }

  return List<GeneratedScheduleGroup>.unmodifiable([
    for (var index = 0; index < buckets.length; index++)
      GeneratedScheduleGroup(
        code: _groupCode(index),
        entries: List<TournamentEntry>.unmodifiable(buckets[index]),
      ),
  ]);
}

String _groupCode(int index) {
  final codeUnit = 'A'.codeUnitAt(0) + index;
  return String.fromCharCode(codeUnit);
}

List<GeneratedScheduleRound> _buildRoundRobinRounds({
  required List<TournamentEntry> entries,
  required String Function(int roundNumber) titleBuilder,
  String? groupCode,
}) {
  final rotation = List<TournamentEntry?>.from(entries);
  if (rotation.length.isOdd) {
    rotation.add(null);
  }

  final rounds = <GeneratedScheduleRound>[];
  final totalRounds = rotation.length - 1;
  for (var roundIndex = 0; roundIndex < totalRounds; roundIndex++) {
    final matches = <GeneratedScheduledMatch>[];
    for (var index = 0; index < rotation.length / 2; index++) {
      final left = rotation[index];
      final right = rotation[rotation.length - 1 - index];
      if (left == null && right == null) {
        continue;
      }

      final teamOne = left ?? right!;
      final teamTwo = left == null || right == null ? null : right;
      matches.add(
        GeneratedScheduledMatch(
          code:
              '${groupCode == null ? 'R' : '${groupCode}R'}${roundIndex + 1}-M${index + 1}',
          roundNumber: roundIndex + 1,
          teamOne: teamOne,
          teamTwo: teamTwo,
          hasBye: teamTwo == null,
          groupCode: groupCode,
        ),
      );
    }

    rounds.add(
      GeneratedScheduleRound(
        title: titleBuilder(roundIndex + 1),
        roundNumber: roundIndex + 1,
        groupCode: groupCode,
        matches: matches,
      ),
    );

    if (rotation.length > 2) {
      final fixed = rotation.first;
      final rest = rotation.sublist(1);
      rotation
        ..clear()
        ..add(fixed)
        ..add(rest.last)
        ..addAll(rest.sublist(0, rest.length - 1));
    }
  }

  return List<GeneratedScheduleRound>.unmodifiable(rounds);
}

int _deriveKnockoutBracketSize(int groupCount) {
  if (groupCount <= 4) {
    return 4;
  }
  return 8;
}

List<_QualifierSource> _buildQualifierSources({
  required List<GeneratedScheduleGroup> groups,
  required int qualifierCount,
}) {
  final winners = <_QualifierSource>[
    for (final group in groups)
      _QualifierSource(
        seedOrder: winnersSeedOrder(group.code),
        label: 'Winner Group ${group.code}',
      ),
  ];

  final runnersUp = <_QualifierSource>[
    for (final group in groups)
      _QualifierSource(
        seedOrder: 100 + winnersSeedOrder(group.code),
        label: 'Runner-up Group ${group.code}',
      ),
  ];

  return List<_QualifierSource>.unmodifiable([
    ...winners.take(qualifierCount),
    ...runnersUp.take(math.max(0, qualifierCount - winners.length)),
  ]);
}

int winnersSeedOrder(String code) {
  return code.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1;
}

List<GeneratedQualificationMatch> _buildKnockoutPath(
  List<_QualifierSource> qualifiers,
) {
  if (qualifiers.length == 4) {
    return const [
          GeneratedQualificationMatch(
            label: 'Semifinal 1',
            homeSource: 'Qualifier 1',
            awaySource: 'Qualifier 4',
            stageLabel: 'Semifinal',
          ),
          GeneratedQualificationMatch(
            label: 'Semifinal 2',
            homeSource: 'Qualifier 2',
            awaySource: 'Qualifier 3',
            stageLabel: 'Semifinal',
          ),
          GeneratedQualificationMatch(
            label: 'Final',
            homeSource: 'Winner SF1',
            awaySource: 'Winner SF2',
            stageLabel: 'Championship',
          ),
        ]
        .map((match) {
          return GeneratedQualificationMatch(
            label: match.label,
            homeSource: _resolveQualifierLabel(match.homeSource, qualifiers),
            awaySource: _resolveQualifierLabel(match.awaySource, qualifiers),
            stageLabel: match.stageLabel,
          );
        })
        .toList(growable: false);
  }

  if (qualifiers.length == 8) {
    return const [
          GeneratedQualificationMatch(
            label: 'Quarterfinal 1',
            homeSource: 'Qualifier 1',
            awaySource: 'Qualifier 8',
            stageLabel: 'Quarterfinal',
          ),
          GeneratedQualificationMatch(
            label: 'Quarterfinal 2',
            homeSource: 'Qualifier 4',
            awaySource: 'Qualifier 5',
            stageLabel: 'Quarterfinal',
          ),
          GeneratedQualificationMatch(
            label: 'Quarterfinal 3',
            homeSource: 'Qualifier 2',
            awaySource: 'Qualifier 7',
            stageLabel: 'Quarterfinal',
          ),
          GeneratedQualificationMatch(
            label: 'Quarterfinal 4',
            homeSource: 'Qualifier 3',
            awaySource: 'Qualifier 6',
            stageLabel: 'Quarterfinal',
          ),
          GeneratedQualificationMatch(
            label: 'Semifinal 1',
            homeSource: 'Winner QF1',
            awaySource: 'Winner QF2',
            stageLabel: 'Semifinal',
          ),
          GeneratedQualificationMatch(
            label: 'Semifinal 2',
            homeSource: 'Winner QF3',
            awaySource: 'Winner QF4',
            stageLabel: 'Semifinal',
          ),
          GeneratedQualificationMatch(
            label: 'Final',
            homeSource: 'Winner SF1',
            awaySource: 'Winner SF2',
            stageLabel: 'Championship',
          ),
        ]
        .map((match) {
          return GeneratedQualificationMatch(
            label: match.label,
            homeSource: _resolveQualifierLabel(match.homeSource, qualifiers),
            awaySource: _resolveQualifierLabel(match.awaySource, qualifiers),
            stageLabel: match.stageLabel,
          );
        })
        .toList(growable: false);
  }

  return const <GeneratedQualificationMatch>[];
}

String _resolveQualifierLabel(String token, List<_QualifierSource> qualifiers) {
  if (!token.startsWith('Qualifier ')) {
    return token;
  }
  final qualifierIndex = int.tryParse(token.replaceFirst('Qualifier ', ''));
  if (qualifierIndex == null ||
      qualifierIndex <= 0 ||
      qualifierIndex > qualifiers.length) {
    return token;
  }
  return qualifiers[qualifierIndex - 1].label;
}

final class _QualifierSource {
  const _QualifierSource({required this.seedOrder, required this.label});

  final int seedOrder;
  final String label;
}
