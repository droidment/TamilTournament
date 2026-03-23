import '../../categories/domain/category_item.dart';
import '../../entries/domain/entry.dart';

final class SchedulingSeedSnapshot {
  const SchedulingSeedSnapshot({
    required this.readyCategories,
    required this.totalCheckedInEntries,
    required this.totalMatchups,
  });

  final List<ReadyCategorySeed> readyCategories;
  final int totalCheckedInEntries;
  final int totalMatchups;

  bool get isEmpty => readyCategories.isEmpty;
}

final class ReadyCategorySeed {
  const ReadyCategorySeed({
    required this.categoryId,
    required this.categoryName,
    required this.formatLabel,
    required this.checkedInEntries,
    required this.matchups,
  });

  final String categoryId;
  final String categoryName;
  final String formatLabel;
  final List<TournamentEntry> checkedInEntries;
  final List<SeedMatchup> matchups;

  int get checkedInCount => checkedInEntries.length;
}

final class SeedMatchup {
  const SeedMatchup({
    required this.categoryId,
    required this.categoryName,
    required this.seedNumber,
    required this.playerOne,
    required this.playerTwo,
    required this.playerOneEntryId,
    required this.playerTwoEntryId,
    required this.hasBye,
  });

  final String categoryId;
  final String categoryName;
  final int seedNumber;
  final String playerOne;
  final String playerTwo;
  final String playerOneEntryId;
  final String? playerTwoEntryId;
  final bool hasBye;
}

SchedulingSeedSnapshot deriveSchedulingSeedSnapshot({
  required List<CategoryItem> categories,
  required List<TournamentEntry> entries,
}) {
  final categoryIndex = <String, CategoryItem>{
    for (final category in categories) category.id: category,
  };

  final checkedInByCategory = <String, List<TournamentEntry>>{};
  for (final entry in entries) {
    if (!entry.checkedIn) {
      continue;
    }

    final categoryKey = entry.categoryId.isNotEmpty
        ? entry.categoryId
        : _normalize(entry.categoryName);
    if (!categoryIndex.containsKey(categoryKey)) {
      continue;
    }

    checkedInByCategory.putIfAbsent(categoryKey, () => <TournamentEntry>[]);
    checkedInByCategory[categoryKey]!.add(entry);
  }

  final readyCategories = <ReadyCategorySeed>[];
  for (final category in categories) {
    final checkedInEntries = checkedInByCategory[category.id];
    if (checkedInEntries == null || checkedInEntries.length < 2) {
      continue;
    }

    checkedInEntries.sort(_compareEntries);
    readyCategories.add(
      ReadyCategorySeed(
        categoryId: category.id,
        categoryName: category.name,
        formatLabel: category.format.label,
        checkedInEntries: List<TournamentEntry>.unmodifiable(checkedInEntries),
        matchups: List<SeedMatchup>.unmodifiable(
          _buildMatchups(category, checkedInEntries),
        ),
      ),
    );
  }

  return SchedulingSeedSnapshot(
    readyCategories: List<ReadyCategorySeed>.unmodifiable(readyCategories),
    totalCheckedInEntries: readyCategories.fold<int>(
      0,
      (total, category) => total + category.checkedInCount,
    ),
    totalMatchups: readyCategories.fold<int>(
      0,
      (total, category) => total + category.matchups.length,
    ),
  );
}

List<SeedMatchup> _buildMatchups(
  CategoryItem category,
  List<TournamentEntry> checkedInEntries,
) {
  final matchups = <SeedMatchup>[];
  for (var index = 0; index < checkedInEntries.length; index += 2) {
    final playerOne = checkedInEntries[index];
    final hasPartner = index + 1 < checkedInEntries.length;
    final playerTwo = hasPartner ? checkedInEntries[index + 1] : null;

    matchups.add(
      SeedMatchup(
        categoryId: category.id,
        categoryName: category.name,
        seedNumber: (index ~/ 2) + 1,
        playerOne: playerOne.playerOne.isNotEmpty
            ? playerOne.playerOne
            : playerOne.playerTwo,
        playerTwo: hasPartner
            ? (playerTwo!.playerOne.isNotEmpty
                  ? playerTwo.playerOne
                  : playerTwo.playerTwo)
            : 'Bye',
        playerOneEntryId: playerOne.id,
        playerTwoEntryId: playerTwo?.id,
        hasBye: !hasPartner,
      ),
    );
  }
  return matchups;
}

int _compareEntries(TournamentEntry left, TournamentEntry right) {
  final leftCreatedAt = left.createdAt ?? left.updatedAt;
  final rightCreatedAt = right.createdAt ?? right.updatedAt;

  final leftTime = leftCreatedAt?.millisecondsSinceEpoch ?? 0;
  final rightTime = rightCreatedAt?.millisecondsSinceEpoch ?? 0;
  final byTime = leftTime.compareTo(rightTime);
  if (byTime != 0) {
    return byTime;
  }

  final byFirst = left.playerOne.toLowerCase().compareTo(
    right.playerOne.toLowerCase(),
  );
  if (byFirst != 0) {
    return byFirst;
  }

  return left.id.compareTo(right.id);
}

String _normalize(String value) {
  return value.trim().toLowerCase();
}
