import 'package:go_router/go_router.dart';

import '../../features/assistant/presentation/assistant_shell_page.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/public/presentation/public_shell_page.dart';
import '../../features/referee/presentation/referee_shell_page.dart';
import '../../features/tournaments/domain/tournament_role.dart';
import '../../features/tournaments/presentation/tournament_detail_page.dart';
import 'role_guard.dart';

final class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      // Organizer routes
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
      GoRoute(
        path: '/tournaments/:tournamentId',
        builder: (context, state) => TournamentDetailPage(
          tournamentId: state.pathParameters['tournamentId']!,
        ),
      ),

      // Assistant route family
      GoRoute(
        path: '/a/:tournamentId',
        builder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId']!;
          return RoleGuard(
            tournamentId: tournamentId,
            allowedRoles: const {
              TournamentRoleType.organizer,
              TournamentRoleType.assistant,
            },
            child: AssistantShellPage(tournamentId: tournamentId),
          );
        },
      ),

      // Referee route family
      GoRoute(
        path: '/r/:tournamentId',
        builder: (context, state) {
          final tournamentId = state.pathParameters['tournamentId']!;
          return RoleGuard(
            tournamentId: tournamentId,
            allowedRoles: const {
              TournamentRoleType.organizer,
              TournamentRoleType.assistant,
              TournamentRoleType.referee,
            },
            child: RefereeShellPage(tournamentId: tournamentId),
          );
        },
      ),

      // Public route family (no auth required)
      GoRoute(
        path: '/p/:publicSlug',
        builder: (context, state) => PublicShellPage(
          publicSlug: state.pathParameters['publicSlug']!,
        ),
      ),
    ],
  );
}
