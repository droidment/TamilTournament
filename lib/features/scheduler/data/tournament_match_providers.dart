import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tournament_match.dart';
import 'tournament_match_repository.dart';

final tournamentMatchFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final tournamentMatchRepositoryProvider = Provider<TournamentMatchRepository>((ref) {
  return TournamentMatchRepository(ref.watch(tournamentMatchFirestoreProvider));
});

final tournamentMatchesProvider =
    StreamProvider.family<List<TournamentMatch>, String>((ref, tournamentId) {
      return ref
          .watch(tournamentMatchRepositoryProvider)
          .watchMatches(tournamentId);
    });
