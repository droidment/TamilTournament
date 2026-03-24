import 'package:flutter_test/flutter_test.dart';
import 'package:tamil_tournament/features/categories/domain/category_item.dart';
import 'package:tamil_tournament/features/entries/domain/entry.dart';
import 'package:tamil_tournament/features/scheduler/domain/category_schedule.dart';
import 'package:tamil_tournament/features/scheduler/domain/scheduling_seed.dart';

void main() {
  group('deriveTournamentCategorySchedules', () {
    test('uses round robin top 4 for seven or fewer seeded teams', () {
      final category = _category('c1', 'Mens Open');
      final entries = List.generate(
        7,
        (index) => _entry(
          id: 'e${index + 1}',
          categoryId: category.id,
          seedNumber: index + 1,
        ),
      );

      final snapshot = deriveTournamentCategorySchedules(
        categories: [category],
        entries: entries,
      );

      expect(snapshot.categories, hasLength(1));
      final generated = snapshot.categories.single;
      expect(generated.mode, GeneratedScheduleMode.roundRobinTop4);
      expect(generated.groups, hasLength(1));
      expect(generated.qualifierCount, 4);
      expect(generated.qualificationMatches, hasLength(3));
    });

    test('uses variable pool play for eight seeded teams', () {
      final category = _category('c1', 'Mens Open');
      final entries = List.generate(
        8,
        (index) => _entry(
          id: 'e${index + 1}',
          categoryId: category.id,
          seedNumber: index + 1,
        ),
      );

      final snapshot = deriveTournamentCategorySchedules(
        categories: [category],
        entries: entries,
      );

      expect(snapshot.categories, hasLength(1));
      final generated = snapshot.categories.single;
      expect(generated.mode, GeneratedScheduleMode.groupsKnockout);
      expect(generated.groups, hasLength(2));
      expect(generated.groups.map((group) => group.entries.length), [4, 4]);
      expect(generated.qualifierCount, 4);
    });

    test('creates target-four pools for nine to sixteen teams', () {
      final category = _category('c1', 'Mens Open');
      final entries = List.generate(
        10,
        (index) => _entry(
          id: 'e${index + 1}',
          categoryId: category.id,
          seedNumber: index + 1,
        ),
      );

      final snapshot = deriveTournamentCategorySchedules(
        categories: [category],
        entries: entries,
      );

      final generated = snapshot.categories.single;
      expect(generated.mode, GeneratedScheduleMode.groupsKnockout);
      expect(generated.groups, hasLength(3));
      expect(generated.groups.map((group) => group.entries.length), [4, 3, 3]);
      expect(generated.qualifierCount, 4);
      expect(generated.qualificationMatches.first.homeSource, 'Winner Group A');
      expect(
        generated.qualificationMatches.first.awaySource,
        'Runner-up Group A',
      );
    });

    test('applies saved seed plan order before raw entry ordering', () {
      final category = _category('c1', 'Mens Open');
      final entries = List.generate(
        8,
        (index) => _entry(
          id: 'e${index + 1}',
          categoryId: category.id,
          seedNumber: index + 1,
        ),
      );
      final seedPlan = SchedulingSeedPlan(
        tournamentId: 't1',
        categoryId: category.id,
        categoryName: category.name,
        format: CategoryFormat.group,
        seedEntryIds: const ['e8', 'e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7'],
        createdAt: null,
        updatedAt: null,
      );

      final snapshot = deriveTournamentCategorySchedules(
        categories: [category],
        entries: entries,
        seedPlans: [seedPlan],
      );

      final generated = snapshot.categories.single;
      expect(generated.seededEntries.first.id, 'e8');
      expect(generated.groups.first.entries.first.id, 'e8');
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
    createdAt: null,
    updatedAt: null,
  );
}

TournamentEntry _entry({
  required String id,
  required String categoryId,
  required int seedNumber,
}) {
  return TournamentEntry(
    id: id,
    tournamentId: 't1',
    categoryId: categoryId,
    teamName: 'Team $id',
    playerOne: 'P1 $id',
    playerTwo: 'P2 $id',
    seedNumber: seedNumber,
    categoryName: 'Mens Open',
    checkedIn: true,
    createdAt: DateTime(2026, 3, 24),
    updatedAt: DateTime(2026, 3, 24),
  );
}
