import 'package:cloud_firestore/cloud_firestore.dart';

import '../../categories/domain/category_item.dart';
import '../../entries/domain/entry.dart';

final class SchedulingSeedPlan {
  SchedulingSeedPlan({
    required this.tournamentId,
    required this.categoryId,
    required this.categoryName,
    required this.format,
    required List<String> seedEntryIds,
    required this.createdAt,
    required this.updatedAt,
  }) : seedEntryIds = List.unmodifiable(seedEntryIds);

  final String tournamentId;
  final String categoryId;
  final String categoryName;
  final CategoryFormat format;
  final List<String> seedEntryIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get seededEntryCount => seedEntryIds.length;

  bool get isEmpty => seedEntryIds.isEmpty;

  factory SchedulingSeedPlan.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return SchedulingSeedPlan(
      tournamentId: data['tournamentId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? doc.id,
      categoryName: (data['categoryName'] as String?)?.trim().isNotEmpty == true
          ? (data['categoryName'] as String).trim()
          : 'Untitled category',
      format: CategoryFormatX.fromValue(data['format'] as String? ?? 'group'),
      seedEntryIds: List<String>.unmodifiable(
        (data['seedEntryIds'] as List<dynamic>? ?? const <dynamic>[]).map(
          (entryId) => entryId.toString(),
        ),
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, Object> toMap({
    required Object createdAt,
    required Object updatedAt,
  }) {
    return <String, Object>{
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'format': format.value,
      'seedEntryIds': seedEntryIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

final class SchedulingSeedSnapshot {
  SchedulingSeedSnapshot({
    required List<ReadyCategorySeed> readyCategories,
    required this.totalEntries,
    required this.totalCheckedInEntries,
    required this.totalMatchups,
    required Map<String, SchedulingSeedPlan> seedPlansByCategoryId,
  }) : readyCategories = List.unmodifiable(readyCategories),
       seedPlansByCategoryId = Map.unmodifiable(seedPlansByCategoryId);

  final List<ReadyCategorySeed> readyCategories;
  final int totalEntries;
  final int totalCheckedInEntries;
  final int totalMatchups;
  final Map<String, SchedulingSeedPlan> seedPlansByCategoryId;

  bool get isEmpty => readyCategories.isEmpty;

  bool get hasSavedSeedPlans => seedPlansByCategoryId.isNotEmpty;
}

final class ReadyCategorySeed {
  ReadyCategorySeed({
    required this.categoryId,
    required this.categoryName,
    required this.format,
    required this.formatLabel,
    required List<TournamentEntry> entries,
    required this.checkedInCount,
    required List<SeedMatchup> matchups,
    required List<String> seedEntryIds,
    required this.seedPlan,
  }) : entries = List.unmodifiable(entries),
       matchups = List.unmodifiable(matchups),
       seedEntryIds = List.unmodifiable(seedEntryIds);

  final String categoryId;
  final String categoryName;
  final CategoryFormat format;
  final String formatLabel;
  final List<TournamentEntry> entries;
  final int checkedInCount;
  final List<SeedMatchup> matchups;
  final List<String> seedEntryIds;
  final SchedulingSeedPlan? seedPlan;

  int get entryCount => entries.length;

  bool get hasSavedSeedPlan => seedPlan != null;

  List<String> get suggestedSeedEntryIds =>
      entries.map((entry) => entry.id).toList(growable: false);
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
  List<SchedulingSeedPlan> seedPlans = const [],
}) {
  final categoryLookup = _buildCategoryLookup(categories);
  final seedPlanByCategoryId = <String, SchedulingSeedPlan>{
    for (final plan in seedPlans) plan.categoryId: plan,
  };

  final entriesByCategory = <String, List<TournamentEntry>>{};
  for (final entry in entries) {
    final category =
        categoryLookup[entry.categoryId.isNotEmpty
            ? entry.categoryId
            : _normalize(entry.categoryName)] ??
        categoryLookup[_normalize(entry.categoryName)];
    if (category == null) {
      continue;
    }

    entriesByCategory.putIfAbsent(category.id, () => <TournamentEntry>[]);
    entriesByCategory[category.id]!.add(entry);
  }

  final readyCategories = <ReadyCategorySeed>[];
  for (final category in categories) {
    final categoryEntries = entriesByCategory[category.id];
    if (categoryEntries == null || categoryEntries.isEmpty) {
      continue;
    }

    categoryEntries.sort(compareEntriesForSeeding);
    final seedPlan = seedPlanByCategoryId[category.id];
    final orderedEntries = _orderEntries(
      categoryEntries,
      seedPlan?.seedEntryIds,
    );
    readyCategories.add(
      ReadyCategorySeed(
        categoryId: category.id,
        categoryName: category.name,
        format: category.format,
        formatLabel: category.format.label,
        entries: orderedEntries,
        checkedInCount: orderedEntries.where((entry) => entry.checkedIn).length,
        matchups: _buildMatchups(category, orderedEntries),
        seedEntryIds: orderedEntries
            .map((entry) => entry.id)
            .toList(growable: false),
        seedPlan: seedPlan,
      ),
    );
  }

  return SchedulingSeedSnapshot(
    readyCategories: readyCategories,
    totalEntries: readyCategories.fold<int>(
      0,
      (total, category) => total + category.entryCount,
    ),
    totalCheckedInEntries: readyCategories.fold<int>(
      0,
      (total, category) => total + category.checkedInCount,
    ),
    totalMatchups: readyCategories.fold<int>(
      0,
      (total, category) => total + category.matchups.length,
    ),
    seedPlansByCategoryId: seedPlanByCategoryId,
  );
}

Map<String, CategoryItem> _buildCategoryLookup(List<CategoryItem> categories) {
  final lookup = <String, CategoryItem>{};
  for (final category in categories) {
    lookup[category.id] = category;
    lookup[_normalize(category.name)] = category;
  }
  return lookup;
}

List<TournamentEntry> _orderEntries(
  List<TournamentEntry> categoryEntries,
  List<String>? seedEntryIds,
) {
  if (seedEntryIds == null || seedEntryIds.isEmpty) {
    return List<TournamentEntry>.unmodifiable(categoryEntries);
  }

  final entryById = <String, TournamentEntry>{
    for (final entry in categoryEntries) entry.id: entry,
  };
  final seen = <String>{};
  final orderedEntries = <TournamentEntry>[];

  for (final entryId in seedEntryIds) {
    if (!seen.add(entryId)) {
      continue;
    }

    final entry = entryById[entryId];
    if (entry != null) {
      orderedEntries.add(entry);
    }
  }

  for (final entry in categoryEntries) {
    if (seen.add(entry.id)) {
      orderedEntries.add(entry);
    }
  }

  return List<TournamentEntry>.unmodifiable(orderedEntries);
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
        playerOne: playerOne.displayLabel,
        playerTwo: hasPartner ? playerTwo!.displayLabel : 'Bye',
        playerOneEntryId: playerOne.id,
        playerTwoEntryId: playerTwo?.id,
        hasBye: !hasPartner,
      ),
    );
  }
  return matchups;
}

String _normalize(String value) {
  return value.trim().toLowerCase();
}
