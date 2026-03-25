import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/tournament_role.dart';

final class TournamentRoleRepository {
  TournamentRoleRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _rolesRef(String tournamentId) =>
      _firestore
          .collection('tournaments')
          .doc(tournamentId)
          .collection('roles');

  Stream<List<TournamentRole>> watchRoles({required String tournamentId}) {
    return _rolesRef(tournamentId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TournamentRole.fromDocument(
                  doc,
                  tournamentId: tournamentId,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<TournamentRole?> findRoleForUser({
    required String tournamentId,
    required String userId,
  }) async {
    final doc = await _rolesRef(tournamentId).doc(userId).get();
    if (!doc.exists) {
      return null;
    }
    final role = TournamentRole.fromDocument(
      doc,
      tournamentId: tournamentId,
    );
    return role.isActive ? role : null;
  }

  Future<void> addRole({
    required String tournamentId,
    required TournamentRole role,
  }) async {
    await _rolesRef(tournamentId).doc(role.userId).set(role.toMap());
  }

  Future<void> removeRole({
    required String tournamentId,
    required String roleId,
  }) async {
    await _rolesRef(tournamentId).doc(roleId).delete();
  }

  Future<void> deactivateRole({
    required String tournamentId,
    required String roleId,
  }) async {
    await _rolesRef(tournamentId).doc(roleId).update(<String, Object>{
      'isActive': false,
    });
  }
}
