import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate.dart';

final class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    ],
  );
}
