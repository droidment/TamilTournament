import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/tournaments/presentation/tournament_detail_page.dart';

final class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
      GoRoute(
        path: '/tournaments/:tournamentId',
        builder: (context, state) => TournamentDetailPage(
          tournamentId: state.pathParameters['tournamentId']!,
        ),
      ),
    ],
  );
}
