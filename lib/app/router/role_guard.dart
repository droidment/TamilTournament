import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tournaments/data/tournament_role_providers.dart';
import '../../features/tournaments/domain/tournament_role.dart';

final class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    required this.tournamentId,
    required this.allowedRoles,
    required this.child,
    super.key,
  });

  final String tournamentId;
  final Set<TournamentRoleType> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _AccessDenied(message: 'Sign in required');
    }

    final roleAsync = ref.watch(currentUserRoleProvider(tournamentId));
    return roleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _AccessDenied(message: 'Unable to verify role'),
      data: (role) {
        if (role == null || !allowedRoles.contains(role.role)) {
          return const _AccessDenied(message: 'Access denied');
        }
        return child;
      },
    );
  }
}

final class _AccessDenied extends StatelessWidget {
  const _AccessDenied({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
