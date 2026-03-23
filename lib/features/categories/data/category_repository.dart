import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/category_item.dart';

final class CategoryRepository {
  CategoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  Stream<List<CategoryItem>> watchTournamentCategories(String tournamentId) {
    return _categories
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
          final categories = snapshot.docs
              .map(CategoryItem.fromDocument)
              .toList(growable: false);
          categories.sort((left, right) {
            return left.name.toLowerCase().compareTo(right.name.toLowerCase());
          });
          return categories;
        });
  }

  Future<void> createDraftCategory({
    required String tournamentId,
    required String name,
    required CategoryFormat format,
    required int minPlayers,
  }) async {
    final now = FieldValue.serverTimestamp();
    final doc = _categories.doc();
    final tournamentRef = _firestore
        .collection('tournaments')
        .doc(tournamentId);
    await _firestore.runTransaction((transaction) async {
      transaction.set(doc, <String, Object>{
        'tournamentId': tournamentId,
        'name': name.trim(),
        'format': format.value,
        'minPlayers': minPlayers,
        'checkedInPairs': 0,
        'createdAt': now,
        'updatedAt': now,
      });
      transaction.update(tournamentRef, <String, Object>{
        'stats.categories': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> adjustCheckedInPairs({
    required String categoryId,
    required int delta,
  }) async {
    await _categories.doc(categoryId).update(<String, Object>{
      'checkedInPairs': FieldValue.increment(delta),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
