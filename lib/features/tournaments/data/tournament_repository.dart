import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/tournament.dart';

final class TournamentRepository {
  TournamentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _firestore.collection('tournaments');

  Future<List<Tournament>> loadOwnedTournaments({
    required String organizerUid,
    required String organizerEmail,
  }) async {
    final normalizedEmail = _normalizeOrganizerEmail(organizerEmail);
    QuerySnapshot<Map<String, dynamic>>? directSnapshot;
    QuerySnapshot<Map<String, dynamic>>? sharedSnapshot;

    try {
      directSnapshot = await _tournaments
          .where('organizerUid', isEqualTo: organizerUid)
          .get();
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }
    }

    if (normalizedEmail.isNotEmpty) {
      try {
        sharedSnapshot = await _tournaments
            .where('organizerEmails', arrayContains: normalizedEmail)
            .get();
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') {
          rethrow;
        }
      }
    }

    final merged =
        <String, Tournament>{
            if (directSnapshot != null)
              for (final doc in directSnapshot.docs)
              doc.id: Tournament.fromDocument(doc),
            if (sharedSnapshot != null)
              for (final doc in sharedSnapshot.docs)
                doc.id: Tournament.fromDocument(doc),
          }.values.toList(growable: false)
          ..sort((left, right) => right.startDate.compareTo(left.startDate));

    return merged;
  }

  Stream<List<Tournament>> watchOwnedTournaments({
    required String organizerUid,
    required String organizerEmail,
  }) {
    final normalizedEmail = _normalizeOrganizerEmail(organizerEmail);
    return Stream<List<Tournament>>.multi((controller) {
      var directTournaments = const <Tournament>[];
      var sharedTournaments = const <Tournament>[];

      void emit() {
        if (controller.isClosed) {
          return;
        }

        final merged =
            <String, Tournament>{
                for (final tournament in directTournaments)
                  tournament.id: tournament,
                for (final tournament in sharedTournaments)
                  tournament.id: tournament,
              }.values.toList(growable: false)
              ..sort((left, right) => right.startDate.compareTo(left.startDate));
        controller.add(merged);
      }

      final directSubscription = _tournaments
          .where('organizerUid', isEqualTo: organizerUid)
          .snapshots()
          .listen((snapshot) {
            directTournaments = snapshot.docs
                .map(Tournament.fromDocument)
                .toList(growable: false);
            emit();
          }, onError: controller.addError);

      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      sharedSubscription;
      if (normalizedEmail.isNotEmpty) {
        sharedSubscription = _tournaments
            .where('organizerEmails', arrayContains: normalizedEmail)
            .snapshots()
            .listen((snapshot) {
              sharedTournaments = snapshot.docs
                  .map(Tournament.fromDocument)
                  .toList(growable: false);
              emit();
            }, onError: controller.addError);
      }

      controller.onCancel = () async {
        await directSubscription.cancel();
        await sharedSubscription?.cancel();
      };
    });
  }

  Stream<Tournament?> watchTournament({
    required String tournamentId,
    required String organizerUid,
    required String organizerEmail,
  }) {
    return _tournaments.doc(tournamentId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      final tournament = Tournament.fromDocument(snapshot);
      if (!_canAccessTournament(
        tournament: tournament,
        organizerUid: organizerUid,
        organizerEmail: organizerEmail,
      )) {
        return null;
      }
      return tournament;
    });
  }

  Future<void> createDraftTournament({
    required String organizerUid,
    required String organizerEmail,
    required String name,
    required String venue,
    required DateTime startDate,
  }) async {
    final now = FieldValue.serverTimestamp();
    final normalizedEmail = _normalizeOrganizerEmail(organizerEmail);
    await _tournaments.add(<String, Object>{
      'name': name.trim(),
      'venue': venue.trim(),
      'startDate': Timestamp.fromDate(startDate),
      'organizerUid': organizerUid,
      'organizerEmails': [normalizedEmail],
      'status': TournamentStatus.draft.value,
      'activeCourtCount': 0,
      'stats': const TournamentStats(
        categories: 0,
        entries: 0,
        matches: 0,
      ).toMap(),
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<void> addOrganizerEmail({
    required String tournamentId,
    required String organizerEmail,
  }) async {
    final normalizedEmail = _normalizeOrganizerEmail(organizerEmail);
    if (normalizedEmail.isEmpty) {
      throw StateError('Enter a valid organizer email.');
    }

    await _tournaments.doc(tournamentId).update(<String, Object>{
      'organizerEmails': FieldValue.arrayUnion([normalizedEmail]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTournamentStatus({
    required String tournamentId,
    required TournamentStatus status,
  }) async {
    await _tournaments.doc(tournamentId).update(<String, Object>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  bool _canAccessTournament({
    required Tournament tournament,
    required String organizerUid,
    required String organizerEmail,
  }) {
    if (tournament.organizerUid == organizerUid) {
      return true;
    }
    final normalizedEmail = _normalizeOrganizerEmail(organizerEmail);
    return tournament.organizerEmails.contains(normalizedEmail);
  }

  String _normalizeOrganizerEmail(String email) {
    return email.trim().toLowerCase();
  }
}
