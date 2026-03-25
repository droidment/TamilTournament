import 'package:cloud_firestore/cloud_firestore.dart';

import '../../tournaments/domain/tournament.dart';
import '../domain/category_schedule.dart';
import '../domain/tournament_court.dart';
import '../domain/tournament_match.dart';
import '../domain/tournament_standings.dart';

final class TournamentLaunchResult {
  const TournamentLaunchResult({
    required this.generatedMatches,
    required this.assignedCourts,
  });

  final int generatedMatches;
  final int assignedCourts;
}

final class TournamentMatchRepository {
  TournamentMatchRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _matches(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('matches');
  }

  CollectionReference<Map<String, dynamic>> _courts(String tournamentId) {
    return _firestore
        .collection('tournaments')
        .doc(tournamentId)
        .collection('courts');
  }

  DocumentReference<Map<String, dynamic>> _tournament(String tournamentId) {
    return _firestore.collection('tournaments').doc(tournamentId);
  }

  Stream<List<TournamentMatch>> watchMatches(String tournamentId) {
    return _matches(tournamentId).orderBy('displayOrder').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(TournamentMatch.fromDocument)
          .toList(growable: false);
    });
  }

  Future<List<TournamentWinnerSummary>> loadCompletedWinnerSummaries(
    String tournamentId,
  ) async {
    final snapshot = await _matches(tournamentId).orderBy('displayOrder').get();
    final matches = snapshot.docs
        .map(TournamentMatch.fromDocument)
        .toList(growable: false);
    return deriveCompletedWinnerSummaries(matches);
  }

  Future<TournamentLaunchResult> launchTournament({
    required Tournament tournament,
    required TournamentCategoryScheduleSnapshot scheduleSnapshot,
    required List<TournamentCourt> courts,
  }) async {
    final matchDrafts = _buildMatchDrafts(
      tournamentId: tournament.id,
      scheduleSnapshot: scheduleSnapshot,
    );
    if (matchDrafts.isEmpty) {
      throw StateError('Generate at least one playable match before launch.');
    }

    final availableCourts = List<TournamentCourt>.from(courts)
      ..sort((left, right) => left.orderIndex.compareTo(right.orderIndex));
    final activeCourts = availableCourts
        .where((court) => court.isAvailable)
        .toList(growable: false);

    for (
      var index = 0;
      index < matchDrafts.length && index < activeCourts.length;
      index++
    ) {
      final draft = matchDrafts[index];
      if (draft.status != TournamentMatchStatus.ready) {
        continue;
      }
      final court = activeCourts[index];
      draft
        ..status = TournamentMatchStatus.onCourt
        ..assignedCourtId = court.id
        ..assignedCourtCode = court.code
        ..assignedCourtName = court.name;
    }

    final existingSnapshot = await _matches(tournament.id).get();
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final doc in existingSnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final draft in matchDrafts) {
      final doc = _matches(tournament.id).doc();
      batch.set(doc, draft.toMap(now: now));
    }

    batch.update(_tournament(tournament.id), <String, Object>{
      'status': TournamentStatus.live.value,
      'stats.matches': matchDrafts.length,
      'updatedAt': now,
    });

    await batch.commit();
    return TournamentLaunchResult(
      generatedMatches: matchDrafts.length,
      assignedCourts: matchDrafts
          .where((draft) => draft.assignedCourtId != null)
          .length,
    );
  }

  Future<void> resetTournamentLaunch({required String tournamentId}) async {
    final existingSnapshot = await _matches(tournamentId).get();
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final doc in existingSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.update(_tournament(tournamentId), <String, Object>{
      'status': TournamentStatus.setup.value,
      'stats.matches': 0,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> saveMatchScores({
    required String tournamentId,
    required String matchId,
    required List<MatchGameScore> scores,
  }) async {
    final matchRef = _matches(tournamentId).doc(matchId);
    final snapshot = await matchRef.get();
    if (!snapshot.exists) {
      throw StateError('This match could not be found.');
    }

    final match = TournamentMatch.fromDocument(snapshot);
    if (!match.isOnCourt) {
      throw StateError('Only matches on court can be scored right now.');
    }

    await matchRef.update(<String, Object?>{
      'scores': scores.map((score) => score.toMap()).toList(growable: false),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeMatch({
    required String tournamentId,
    required String matchId,
    required List<MatchGameScore> scores,
  }) async {
    final matchRef = _matches(tournamentId).doc(matchId);
    final snapshot = await matchRef.get();
    if (!snapshot.exists) {
      throw StateError('This match could not be found.');
    }

    final match = TournamentMatch.fromDocument(snapshot);
    if (!match.isOnCourt) {
      throw StateError('Only matches on court can be finished.');
    }

    final outcome = deriveMatchScoreOutcome(match, scores);
    if (outcome == null) {
      throw StateError(
        'Finish the score as a best-of-three result before closing the match.',
      );
    }

    TournamentCourt? assignedCourt;
    if (match.assignedCourtId != null) {
      final courtSnapshot = await _courts(
        tournamentId,
      ).doc(match.assignedCourtId).get();
      if (courtSnapshot.exists) {
        assignedCourt = TournamentCourt.fromDocument(courtSnapshot);
      }
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? nextReadySnapshot;
    if (assignedCourt?.isAvailable ?? false) {
      final orderedSnapshot = await _matches(
        tournamentId,
      ).orderBy('displayOrder').get();
      for (final doc in orderedSnapshot.docs) {
        final candidate = TournamentMatch.fromDocument(doc);
        if (candidate.isReady) {
          nextReadySnapshot = doc;
          break;
        }
      }
    }

    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.update(matchRef, <String, Object?>{
      'scores': scores.map((score) => score.toMap()).toList(growable: false),
      'winnerEntryId': outcome.winnerEntryId,
      'winnerLabel': outcome.winnerLabel,
      'status': TournamentMatchStatus.completed.value,
      'completedAt': now,
      'updatedAt': now,
    });

    if (nextReadySnapshot != null && assignedCourt != null) {
      batch.update(nextReadySnapshot.reference, <String, Object?>{
        'status': TournamentMatchStatus.onCourt.value,
        'assignedCourtId': assignedCourt.id,
        'assignedCourtCode': assignedCourt.code,
        'assignedCourtName': assignedCourt.name,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }

  Future<int> prepareNextKnockoutRound({
    required String tournamentId,
    required CategoryStandings standings,
  }) async {
    if (!standings.isPoolPhaseComplete) {
      throw StateError('Finish all pool matches before setting up semifinals.');
    }

    final matchesSnapshot = await _matches(
      tournamentId,
    ).orderBy('displayOrder').get();
    final categoryMatches = matchesSnapshot.docs
        .map(TournamentMatch.fromDocument)
        .where((match) => match.categoryId == standings.categoryId)
        .toList(growable: false);
    final matchById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
      for (final doc in matchesSnapshot.docs) doc.id: doc,
    };

    final sourceEntries = <String, _ResolvedEntry>{
      for (final source in standings.qualificationSources.entries)
        source.key: _ResolvedEntry.fromStanding(source.value),
    };

    for (final match in categoryMatches.where((match) => match.isCompleted)) {
      final winnerToken = _winnerTokenForMatch(match);
      if (winnerToken == null ||
          match.winnerEntryId == null ||
          match.winnerEntryId!.trim().isEmpty) {
        continue;
      }
      sourceEntries[winnerToken] = _ResolvedEntry(
        entryId: match.winnerEntryId!,
        label: match.winnerLabel ?? '',
        detail: match.winnerEntryId == match.teamOneEntryId
            ? match.teamOneDetail
            : match.teamTwoDetail,
      );
    }

    final pendingKnockoutMatches = categoryMatches
        .where((match) => match.phase == 'knockout' && match.isPending)
        .toList(growable: false);
    if (pendingKnockoutMatches.isEmpty) {
      return 0;
    }

    String? targetStage;
    final toResolve = <TournamentMatch>[];
    for (final match in pendingKnockoutMatches) {
      final home = sourceEntries[match.teamOneLabel];
      final away = sourceEntries[match.teamTwoLabel];
      if (home == null || away == null) {
        continue;
      }
      targetStage ??= match.stageLabel;
      if (match.stageLabel != targetStage) {
        continue;
      }
      toResolve.add(match);
    }

    if (toResolve.isEmpty) {
      throw StateError(
        'Semifinal slots are not ready yet from current standings.',
      );
    }

    final courtsSnapshot = await _courts(
      tournamentId,
    ).orderBy('orderIndex').get();
    final courts = courtsSnapshot.docs
        .map(TournamentCourt.fromDocument)
        .where((court) => court.isAvailable)
        .toList(growable: false);
    final occupiedCourtIds = categoryMatches
        .where((match) => match.isOnCourt && match.assignedCourtId != null)
        .map((match) => match.assignedCourtId!)
        .toSet();
    final openCourts = courts
        .where((court) => !occupiedCourtIds.contains(court.id))
        .toList(growable: false);

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (var index = 0; index < toResolve.length; index++) {
      final match = toResolve[index];
      final doc = matchById[match.id];
      if (doc == null) {
        continue;
      }
      final home = sourceEntries[match.teamOneLabel]!;
      final away = sourceEntries[match.teamTwoLabel]!;
      final assignedCourt = index < openCourts.length
          ? openCourts[index]
          : null;
      batch.update(doc.reference, <String, Object?>{
        'teamOneEntryId': home.entryId,
        'teamOneLabel': home.label,
        'teamOneDetail': home.detail,
        'teamTwoEntryId': away.entryId,
        'teamTwoLabel': away.label,
        'teamTwoDetail': away.detail,
        'status': assignedCourt == null
            ? TournamentMatchStatus.ready.value
            : TournamentMatchStatus.onCourt.value,
        'assignedCourtId': assignedCourt?.id,
        'assignedCourtCode': assignedCourt?.code,
        'assignedCourtName': assignedCourt?.name,
        'updatedAt': now,
      });
    }

    await batch.commit();
    return toResolve.length;
  }
}

final class _MatchDraft {
  _MatchDraft({
    required this.tournamentId,
    required this.categoryId,
    required this.categoryName,
    required this.matchCode,
    required this.displayOrder,
    required this.phase,
    required this.stageLabel,
    required this.roundTitle,
    required this.roundNumber,
    required this.groupCode,
    required this.teamOneEntryId,
    required this.teamOneLabel,
    required this.teamOneDetail,
    required this.teamTwoEntryId,
    required this.teamTwoLabel,
    required this.teamTwoDetail,
    required this.status,
  });

  final String tournamentId;
  final String categoryId;
  final String categoryName;
  final String matchCode;
  final int displayOrder;
  final String phase;
  final String stageLabel;
  final String roundTitle;
  final int roundNumber;
  final String? groupCode;
  final String? teamOneEntryId;
  final String teamOneLabel;
  final String teamOneDetail;
  final String? teamTwoEntryId;
  final String teamTwoLabel;
  final String teamTwoDetail;
  TournamentMatchStatus status;
  String? assignedCourtId;
  String? assignedCourtCode;
  String? assignedCourtName;

  Map<String, Object?> toMap({required FieldValue now}) {
    return <String, Object?>{
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'matchCode': matchCode,
      'displayOrder': displayOrder,
      'phase': phase,
      'stageLabel': stageLabel,
      'roundTitle': roundTitle,
      'roundNumber': roundNumber,
      'groupCode': groupCode,
      'teamOneEntryId': teamOneEntryId,
      'teamOneLabel': teamOneLabel,
      'teamOneDetail': teamOneDetail,
      'teamTwoEntryId': teamTwoEntryId,
      'teamTwoLabel': teamTwoLabel,
      'teamTwoDetail': teamTwoDetail,
      'status': status.value,
      'assignedCourtId': assignedCourtId,
      'assignedCourtCode': assignedCourtCode,
      'assignedCourtName': assignedCourtName,
      'scores': const <Map<String, Object>>[],
      'winnerEntryId': null,
      'winnerLabel': null,
      'createdAt': now,
      'completedAt': null,
      'updatedAt': now,
    };
  }
}

final class _ResolvedEntry {
  const _ResolvedEntry({
    required this.entryId,
    required this.label,
    required this.detail,
  });

  final String entryId;
  final String label;
  final String detail;

  factory _ResolvedEntry.fromStanding(StandingRow row) {
    return _ResolvedEntry(
      entryId: row.entry.id,
      label: row.entry.displayLabel,
      detail: row.entry.rosterLabel,
    );
  }
}

String? _winnerTokenForMatch(TournamentMatch match) {
  final normalizedCode = match.matchCode.toLowerCase();
  final numberMatch = RegExp(r'(\d+)$').firstMatch(normalizedCode);
  if (numberMatch == null) {
    return null;
  }
  final number = numberMatch.group(1);
  if (normalizedCode.contains('semifinal')) {
    return 'Winner SF$number';
  }
  if (normalizedCode.contains('quarterfinal')) {
    return 'Winner QF$number';
  }
  return null;
}

List<_MatchDraft> _buildMatchDrafts({
  required String tournamentId,
  required TournamentCategoryScheduleSnapshot scheduleSnapshot,
}) {
  final drafts = <_MatchDraft>[];
  var displayOrder = 0;

  for (final category in scheduleSnapshot.categories) {
    for (final round in category.rounds) {
      for (final match in round.matches) {
        if (match.hasBye || match.teamTwo == null) {
          continue;
        }
        displayOrder += 1;
        drafts.add(
          _MatchDraft(
            tournamentId: tournamentId,
            categoryId: category.categoryId,
            categoryName: category.categoryName,
            matchCode: match.code,
            displayOrder: displayOrder,
            phase: 'pool',
            stageLabel: round.groupCode == null ? 'Round robin' : 'Pool play',
            roundTitle: round.title,
            roundNumber: round.roundNumber,
            groupCode: match.groupCode,
            teamOneEntryId: match.teamOne.id,
            teamOneLabel: match.teamOne.displayLabel,
            teamOneDetail: match.teamOne.rosterLabel,
            teamTwoEntryId: match.teamTwo!.id,
            teamTwoLabel: match.teamTwo!.displayLabel,
            teamTwoDetail: match.teamTwo!.rosterLabel,
            status: TournamentMatchStatus.ready,
          ),
        );
      }
    }

    for (final match in category.qualificationMatches) {
      displayOrder += 1;
      drafts.add(
        _MatchDraft(
          tournamentId: tournamentId,
          categoryId: category.categoryId,
          categoryName: category.categoryName,
          matchCode: match.label,
          displayOrder: displayOrder,
          phase: 'knockout',
          stageLabel: match.stageLabel,
          roundTitle: match.label,
          roundNumber: 0,
          groupCode: null,
          teamOneEntryId: null,
          teamOneLabel: match.homeSource,
          teamOneDetail: '',
          teamTwoEntryId: null,
          teamTwoLabel: match.awaySource,
          teamTwoDetail: '',
          status: TournamentMatchStatus.pending,
        ),
      );
    }
  }

  return drafts;
}
