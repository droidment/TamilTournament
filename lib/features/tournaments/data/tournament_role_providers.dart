import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/tournament.dart';
import '../domain/tournament_role.dart';
import 'tournament_providers.dart';
import 'tournament_role_repository.dart';

final tournamentRoleRepositoryProvider = Provider<TournamentRoleRepository>((
  ref,
) {
  return TournamentRoleRepository(ref.watch(firebaseFirestoreProvider));
});

final tournamentRolesProvider =
    StreamProvider.family<List<TournamentRole>, String>((ref, tournamentId) {
      return ref
          .watch(tournamentRoleRepositoryProvider)
          .watchRoles(tournamentId: tournamentId);
    });

final currentUserRoleProvider = FutureProvider.family<TournamentRole?, String>((
  ref,
  tournamentId,
) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return null;
  }
  Tournament? ownedTournament;
  try {
    ownedTournament = await ref.watch(
      tournamentByIdProvider(tournamentId).future,
    );
  } on FirebaseException catch (error) {
    if (error.code != 'permission-denied') {
      rethrow;
    }
  }
  if (ownedTournament != null) {
    return TournamentRole(
      id: user.uid,
      tournamentId: tournamentId,
      userId: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Organizer',
      role: TournamentRoleType.organizer,
      isActive: true,
      assignedAt: null,
      assignedBy: user.uid,
    );
  }
  return ref
      .watch(tournamentRoleRepositoryProvider)
      .findRoleForUser(tournamentId: tournamentId, userId: user.uid);
});
