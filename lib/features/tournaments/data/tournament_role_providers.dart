import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/tournament_role.dart';
import 'tournament_providers.dart';
import 'tournament_role_repository.dart';

final tournamentRoleRepositoryProvider =
    Provider<TournamentRoleRepository>((ref) {
  return TournamentRoleRepository(ref.watch(firebaseFirestoreProvider));
});

final tournamentRolesProvider =
    StreamProvider.family<List<TournamentRole>, String>((
  ref,
  tournamentId,
) {
  return ref
      .watch(tournamentRoleRepositoryProvider)
      .watchRoles(tournamentId: tournamentId);
});

final currentUserRoleProvider =
    FutureProvider.family<TournamentRole?, String>((ref, tournamentId) async {
  final user = ref.watch(firebaseAuthProvider).currentUser;
  if (user == null) {
    return null;
  }
  return ref
      .watch(tournamentRoleRepositoryProvider)
      .findRoleForUser(tournamentId: tournamentId, userId: user.uid);
});
