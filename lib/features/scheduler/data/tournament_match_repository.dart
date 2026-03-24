import 'package:cloud_firestore/cloud_firestore.dart';

import '../../tournaments/domain/tournament.dart';
import '../domain/category_schedule.dart';
import '../domain/tournament_court.dart';
import '../domain/tournament_match.dart';

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

  DocumentReference<Map<String, dynamic>> _tournament(String tournamentId) {
    return _firestore.collection('tournaments').doc(tournamentId);
  }

  Stream<List<TournamentMatch>> watchMatches(String tournamentId) {
    return _matches(
      tournamentId,
    ).orderBy('displayOrder').snapshots().map((snapshot) {
      return snapshot.docs
          .map(TournamentMatch.fromDocument)
          .toList(growable: false);
    });
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
      assignedCourts: matchDrafts.where((draft) => draft.assignedCourtId != null).length,
    );
  }

  Future<void> resetTournamentLaunch({
    required String tournamentId,
  }) async {
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
      'createdAt': now,
      'updatedAt': now,
    };
  }
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
