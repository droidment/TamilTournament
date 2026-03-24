import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/tournament.dart';
import 'tournament_repository.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository(ref.watch(firebaseFirestoreProvider));
});

final ownedTournamentsProvider = StreamProvider<List<Tournament>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  final email = user?.email;
  if (user == null || email == null || email.trim().isEmpty) {
    return Stream.value(const <Tournament>[]);
  }
  return ref
      .watch(tournamentRepositoryProvider)
      .watchOwnedTournaments(organizerUid: user.uid, organizerEmail: email);
});

final tournamentByIdProvider = StreamProvider.family<Tournament?, String>((
  ref,
  tournamentId,
) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  final email = user?.email;
  if (user == null || email == null || email.trim().isEmpty) {
    return Stream.value(null);
  }
  return ref
      .watch(tournamentRepositoryProvider)
      .watchTournament(
        tournamentId: tournamentId,
        organizerUid: user.uid,
        organizerEmail: email,
      );
});
