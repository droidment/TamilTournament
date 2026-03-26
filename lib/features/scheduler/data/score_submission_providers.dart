import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tournaments/data/tournament_providers.dart';
import '../domain/score_submission.dart';
import 'score_submission_repository.dart';

final scoreSubmissionRepositoryProvider = Provider<ScoreSubmissionRepository>((
  ref,
) {
  return ScoreSubmissionRepository(ref.watch(firebaseFirestoreProvider));
});

final pendingSubmissionsProvider =
    StreamProvider.family<List<ScoreSubmission>, String>((ref, tournamentId) {
      return ref
          .watch(scoreSubmissionRepositoryProvider)
          .watchPendingSubmissions(tournamentId: tournamentId);
    });

final matchSubmissionsProvider =
    StreamProvider.family<
      List<ScoreSubmission>,
      ({String tournamentId, String matchId})
    >((ref, args) {
      return ref
          .watch(scoreSubmissionRepositoryProvider)
          .watchSubmissionsForMatch(
            tournamentId: args.tournamentId,
            matchId: args.matchId,
          );
    });
