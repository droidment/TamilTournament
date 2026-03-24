import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_tournament/features/categories/domain/category_item.dart';
import 'package:tamil_tournament/features/entries/domain/entry.dart';
import 'package:tamil_tournament/features/scheduler/domain/scheduling_seed.dart';

void main() {
  test('deriveSchedulingSeedSnapshot includes categories before check-in', () {
    final category = CategoryItem(
      id: 'c1',
      tournamentId: 't1',
      name: 'Women Open',
      format: CategoryFormat.group,
      minPlayers: 2,
      checkedInPairs: 0,
      createdAt: null,
      updatedAt: null,
    );

    final snapshot = deriveSchedulingSeedSnapshot(
      categories: [category],
      entries: [
        _entry(id: 'e1', categoryId: category.id, checkedIn: false),
        _entry(id: 'e2', categoryId: category.id, checkedIn: false),
        _entry(id: 'e3', categoryId: category.id, checkedIn: true),
      ],
    );

    expect(snapshot.readyCategories, hasLength(1));
    expect(snapshot.readyCategories.single.entryCount, 3);
    expect(snapshot.readyCategories.single.checkedInCount, 1);
    expect(snapshot.readyCategories.single.seedEntryIds, ['e1', 'e2', 'e3']);
  });

  test('deriveSchedulingSeedSnapshot includes categories with one entry', () {
    final category = CategoryItem(
      id: 'c2',
      tournamentId: 't1',
      name: 'Women Open',
      format: CategoryFormat.group,
      minPlayers: 2,
      checkedInPairs: 0,
      createdAt: null,
      updatedAt: null,
    );

    final snapshot = deriveSchedulingSeedSnapshot(
      categories: [category],
      entries: [_entry(id: 'solo', categoryId: category.id, checkedIn: false)],
    );

    expect(snapshot.readyCategories, hasLength(1));
    expect(snapshot.readyCategories.single.entryCount, 1);
    expect(snapshot.readyCategories.single.seedEntryIds, ['solo']);
  });
}

TournamentEntry _entry({
  required String id,
  required String categoryId,
  required bool checkedIn,
}) {
  return TournamentEntry(
    id: id,
    tournamentId: 't1',
    categoryId: categoryId,
    teamName: 'Team $id',
    playerOne: 'P1 $id',
    playerTwo: 'P2 $id',
    seedNumber: null,
    categoryName: 'Women Open',
    checkedIn: checkedIn,
    createdAt: DateTime(2026, 3, 24),
    updatedAt: DateTime(2026, 3, 24),
  );
}
