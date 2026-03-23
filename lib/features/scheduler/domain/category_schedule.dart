import '../../categories/domain/category_item.dart';
import '../../entries/domain/entry.dart';

enum GeneratedScheduleMode { roundRobinTop4, groupsTop2, knockoutPreview }

extension GeneratedScheduleModeX on GeneratedScheduleMode {
  String get label => switch (this) {
    GeneratedScheduleMode.roundRobinTop4 => 'Round robin',
    GeneratedScheduleMode.groupsTop2 => 'Groups A/B',
    GeneratedScheduleMode.knockoutPreview => 'Knockout',
  };

  String get subtitle => switch (this) {
    GeneratedScheduleMode.roundRobinTop4 => 'Single group, top 4 to semifinals',
    GeneratedScheduleMode.groupsTop2 =>
      'Snake-seeded Groups A/B, top 2 qualify',
    GeneratedScheduleMode.knockoutPreview => 'Seeded knockout preview',
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

  int get teamCount => seededEntries.length;

  int get playableMatchCount => rounds.fold<int>(
    0,
    (sum, round) => sum + round.matches.where((match) => !match.hasBye).length,
  );
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

  final generated = <GeneratedCategorySchedule>[];
  for (final category in categories) {
    final seededEntries = List<TournamentEntry>.from(
      categoryEntries[category.id] ?? const <TournamentEntry>[],
    )..sort(compareEntriesForSeeding);
    if (seededEntries.length < 2) {
      continue;
    }

    if (category.format == CategoryFormat.knockout) {
      generated.add(_buildKnockoutCategorySchedule(category, seededEntries));
      continue;
    }

    if (seededEntries.length >= 8) {
      generated.add(_buildGroupedCategorySchedule(category, seededEntries));
      continue;
    }

    generated.add(_buildRoundRobinCategorySchedule(category, seededEntries));
  }

  return TournamentCategoryScheduleSnapshot(categories: generated);
}

GeneratedCategorySchedule _buildRoundRobinCategorySchedule(
  CategoryItem category,
  List<TournamentEntry> seededEntries,
) {
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
            stageLabel: 'Top 4 advance',
          ),
          GeneratedQualificationMatch(
            label: 'Semifinal 2',
            homeSource: 'Rank 2',
            awaySource: 'Rank 3',
            stageLabel: 'Top 4 advance',
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
    categoryId: category.id,
    categoryName: category.name,
    mode: GeneratedScheduleMode.roundRobinTop4,
    seededEntries: seededEntries,
    groups: [GeneratedScheduleGroup(code: 'All', entries: seededEntries)],
    rounds: rounds,
    qualificationMatches: qualificationMatches,
    categoryFormat: category.format,
  );
}

GeneratedCategorySchedule _buildGroupedCategorySchedule(
  CategoryItem category,
  List<TournamentEntry> seededEntries,
) {
  final split = _snakeSeedGroups(seededEntries);
  final groupA = GeneratedScheduleGroup(code: 'A', entries: split.$1);
  final groupB = GeneratedScheduleGroup(code: 'B', entries: split.$2);
  final roundsA = _buildRoundRobinRounds(
    entries: groupA.entries,
    groupCode: groupA.code,
    titleBuilder: (roundNumber) => 'Group A · Round $roundNumber',
  );
  final roundsB = _buildRoundRobinRounds(
    entries: groupB.entries,
    groupCode: groupB.code,
    titleBuilder: (roundNumber) => 'Group B · Round $roundNumber',
  );

  final interleavedRounds = <GeneratedScheduleRound>[];
  final maxRounds = roundsA.length > roundsB.length
      ? roundsA.length
      : roundsB.length;
  for (var index = 0; index < maxRounds; index++) {
    if (index < roundsA.length) {
      interleavedRounds.add(roundsA[index]);
    }
    if (index < roundsB.length) {
      interleavedRounds.add(roundsB[index]);
    }
  }

  return GeneratedCategorySchedule(
    categoryId: category.id,
    categoryName: category.name,
    mode: GeneratedScheduleMode.groupsTop2,
    seededEntries: seededEntries,
    groups: [groupA, groupB],
    rounds: interleavedRounds,
    qualificationMatches: const [
      GeneratedQualificationMatch(
        label: 'Semifinal 1',
        homeSource: 'A1',
        awaySource: 'B2',
        stageLabel: 'Top 2 qualify',
      ),
      GeneratedQualificationMatch(
        label: 'Semifinal 2',
        homeSource: 'B1',
        awaySource: 'A2',
        stageLabel: 'Top 2 qualify',
      ),
      GeneratedQualificationMatch(
        label: 'Final',
        homeSource: 'Winner SF1',
        awaySource: 'Winner SF2',
        stageLabel: 'Championship',
      ),
    ],
    categoryFormat: category.format,
  );
}

GeneratedCategorySchedule _buildKnockoutCategorySchedule(
  CategoryItem category,
  List<TournamentEntry> seededEntries,
) {
  final matches = <GeneratedScheduledMatch>[];
  for (var index = 0; index < seededEntries.length; index += 2) {
    final teamOne = seededEntries[index];
    final hasBye = index + 1 >= seededEntries.length;
    final teamTwo = hasBye ? null : seededEntries[index + 1];
    matches.add(
      GeneratedScheduledMatch(
        code: 'K${(index ~/ 2) + 1}',
        roundNumber: 1,
        teamOne: teamOne,
        teamTwo: teamTwo,
        hasBye: hasBye,
      ),
    );
  }

  return GeneratedCategorySchedule(
    categoryId: category.id,
    categoryName: category.name,
    mode: GeneratedScheduleMode.knockoutPreview,
    seededEntries: seededEntries,
    groups: [GeneratedScheduleGroup(code: 'Bracket', entries: seededEntries)],
    rounds: [
      GeneratedScheduleRound(
        title: 'Opening round',
        roundNumber: 1,
        matches: matches,
      ),
    ],
    qualificationMatches: const <GeneratedQualificationMatch>[],
    categoryFormat: category.format,
  );
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
              '${groupCode == null ? 'R' : '$groupCode-R'}${roundIndex + 1}-M${index + 1}',
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

(List<TournamentEntry>, List<TournamentEntry>) _snakeSeedGroups(
  List<TournamentEntry> seededEntries,
) {
  final groupA = <TournamentEntry>[];
  final groupB = <TournamentEntry>[];
  var forward = true;

  for (var index = 0; index < seededEntries.length; index += 2) {
    final chunk = seededEntries.skip(index).take(2).toList(growable: false);
    if (forward) {
      if (chunk.isNotEmpty) {
        groupA.add(chunk[0]);
      }
      if (chunk.length > 1) {
        groupB.add(chunk[1]);
      }
    } else {
      if (chunk.isNotEmpty) {
        groupB.add(chunk[0]);
      }
      if (chunk.length > 1) {
        groupA.add(chunk[1]);
      }
    }
    forward = !forward;
  }

  return (
    List<TournamentEntry>.unmodifiable(groupA),
    List<TournamentEntry>.unmodifiable(groupB),
  );
}
