import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tournament_court.dart';
import 'court_repository.dart';

final courtFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final courtRepositoryProvider = Provider<CourtRepository>((ref) {
  return CourtRepository(ref.watch(courtFirestoreProvider));
});

final tournamentCourtsProvider =
    StreamProvider.family<List<TournamentCourt>, String>((ref, tournamentId) {
      return ref.watch(courtRepositoryProvider).watchCourts(tournamentId);
    });
