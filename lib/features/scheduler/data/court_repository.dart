import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/tournament_court.dart';

final class CourtRepository {
  CourtRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _courts(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('courts');
  }

  DocumentReference<Map<String, dynamic>> _tournament(String tournamentId) {
    return _firestore.collection('tournaments').doc(tournamentId);
  }

  Stream<List<TournamentCourt>> watchCourts(String tournamentId) {
    return _courts(tournamentId).orderBy('orderIndex').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(TournamentCourt.fromDocument)
          .toList(growable: false);
    });
  }

  Future<void> generateCourts({
    required String tournamentId,
    required int totalCourts,
  }) async {
    if (totalCourts <= 0) {
      throw StateError('Add at least one court.');
    }

    final courtsRef = _courts(tournamentId);
    final tournamentRef = _tournament(tournamentId);
    final existingSnapshot = await courtsRef.orderBy('orderIndex').get();
    final existingByCode =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
          for (final doc in existingSnapshot.docs)
            (doc.data()['code'] as String? ?? ''): doc,
        };
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    var availableCount = 0;

    for (var index = 0; index < totalCourts; index++) {
      final code = 'C${index + 1}';
      final existingDoc = existingByCode[code];
      final existingData = existingDoc?.data() ?? const <String, dynamic>{};
      final status =
          existingData['status'] as String? ??
          TournamentCourtStatus.available.value;
      if (status == TournamentCourtStatus.available.value) {
        availableCount += 1;
      }

      batch.set(existingDoc?.reference ?? courtsRef.doc(), <String, Object?>{
        'tournamentId': tournamentId,
        'code': code,
        'name': (existingData['name'] as String?)?.trim().isNotEmpty == true
            ? (existingData['name'] as String).trim()
            : 'Court ${index + 1}',
        'status': status,
        'orderIndex': index,
        'note': (existingData['note'] as String?)?.trim() ?? '',
        'createdAt': existingData.containsKey('createdAt')
            ? existingData['createdAt']
            : now,
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    for (final doc in existingSnapshot.docs) {
      final orderIndex = (doc.data()['orderIndex'] as num?)?.toInt() ?? 0;
      if (orderIndex >= totalCourts) {
        batch.delete(doc.reference);
      }
    }

    batch.update(tournamentRef, <String, Object>{
      'activeCourtCount': availableCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> setCourtAvailability({
    required String tournamentId,
    required String courtId,
    required bool isAvailable,
  }) async {
    final courtRef = _courts(tournamentId).doc(courtId);
    final tournamentRef = _tournament(tournamentId);
    final allCourtsSnapshot = await _courts(tournamentId).get();
    final targetCourt = allCourtsSnapshot.docs.where(
      (doc) => doc.id == courtId,
    );
    if (targetCourt.isEmpty) {
      throw StateError('Court not found.');
    }
    final targetStatus = isAvailable
        ? TournamentCourtStatus.available.value
        : TournamentCourtStatus.unavailable.value;
    var availableCount = 0;
    for (final doc in allCourtsSnapshot.docs) {
      final status = doc.id == courtId
          ? targetStatus
          : doc.data()['status'] as String? ??
                TournamentCourtStatus.available.value;
      if (status == TournamentCourtStatus.available.value) {
        availableCount += 1;
      }
    }

    final batch = _firestore.batch();
    batch.update(courtRef, <String, Object>{
      'status': targetStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(tournamentRef, <String, Object>{
      'activeCourtCount': availableCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateCourtDetails({
    required String tournamentId,
    required String courtId,
    required String name,
    required String note,
  }) async {
    await _courts(tournamentId).doc(courtId).update(<String, Object>{
      'name': name.trim(),
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
