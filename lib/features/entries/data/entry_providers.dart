import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entry.dart';
import 'entry_repository.dart';

final entryFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository(ref.watch(entryFirestoreProvider));
});

final entriesProvider = StreamProvider.family<List<TournamentEntry>, String>((
  ref,
  tournamentId,
) {
  return ref.watch(entryRepositoryProvider).watchEntries(tournamentId);
});
