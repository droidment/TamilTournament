import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/category_item.dart';
import 'category_repository.dart';

final categoryFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(categoryFirestoreProvider));
});

final tournamentCategoriesProvider =
    StreamProvider.family<List<CategoryItem>, String>((ref, tournamentId) {
      return ref
          .watch(categoryRepositoryProvider)
          .watchTournamentCategories(tournamentId);
    });
