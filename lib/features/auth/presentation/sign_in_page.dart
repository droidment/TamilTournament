import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../tournaments/data/tournament_providers.dart';
import '../../tournaments/domain/tournament.dart';

final class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!kIsWeb) {
        throw UnsupportedError(
          'This sign-in flow is available in the web app.',
        );
      }

      final provider = GoogleAuthProvider()
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});

      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = _friendlyAuthError(error);
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final publicTournamentsAsync = ref.watch(publicTournamentsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF9F5EF), AppPalette.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 860;

              return Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isCompact ? AppSpace.md : AppSpace.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isCompact ? 520 : 1020,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isCompact)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildHeroContent(theme, isCompact),
                              ),
                              const SizedBox(width: AppSpace.xl),
                              Expanded(child: _buildSignInCard(theme)),
                            ],
                          )
                        else ...[
                          _buildHeroContent(theme, isCompact),
                          const SizedBox(height: AppSpace.lg),
                          _buildSignInCard(theme),
                        ],
                        const SizedBox(height: AppSpace.lg),
                        const _StaffAccessSection(),
                        const SizedBox(height: AppSpace.lg),
                        _PublicTournamentSection(
                          tournamentsAsync: publicTournamentsAsync,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeroContent(ThemeData theme, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Run the tournament from one screen, not five spreadsheets.',
          style:
              (isCompact
                      ? theme.textTheme.headlineLarge
                      : theme.textTheme.displayLarge)
                  ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpace.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Set up categories, check in pairs, manage courts, and keep the tournament moving from one workspace.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: const [
            _InfoChip(
              label: 'Check-in',
              tint: AppPalette.sageSoft,
              textColor: AppPalette.ink,
            ),
            _InfoChip(
              label: 'Categories',
              tint: AppPalette.skySoft,
              textColor: Color(0xFF456F77),
            ),
            _InfoChip(
              label: 'Courts',
              tint: AppPalette.apricotSoft,
              textColor: Color(0xFF8F6038),
            ),
            _InfoChip(
              label: 'Scores',
              tint: AppPalette.oliveSoft,
              textColor: Color(0xFF5F7243),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignInCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open the organizer workspace',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Sign in with the organizer account for this event and continue where setup left off.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
              child: Text(
                _isLoading ? 'Opening sign-in...' : 'Enter workspace',
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: const Color(0x24C97D6B),
                borderRadius: BorderRadius.circular(AppRadii.panel),
                border: Border.all(color: const Color(0x47C97D6B)),
              ),
              child: Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7B4D42),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Text(
            'Use the published organizer site when staff are signing in during live operation.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String _friendlyAuthError(FirebaseAuthException error) {
  final message = error.message ?? error.code;
  if (message.contains('authorized') || message.contains('OAuth')) {
    return 'This workspace is not ready for sign-in from this address yet. Open the organizer site from its approved web address and try again.';
  }
  if (error.code == 'popup-blocked') {
    return 'Sign-in was blocked by the browser. Allow the sign-in window and try again.';
  }
  if (error.code == 'popup-closed-by-user') {
    return 'Sign-in was closed before it finished. Try again when you are ready.';
  }
  return 'We could not open the organizer workspace right now. Please try again.';
}

final class _StaffAccessSection extends StatefulWidget {
  const _StaffAccessSection();

  @override
  State<_StaffAccessSection> createState() => _StaffAccessSectionState();
}

class _StaffAccessSectionState extends State<_StaffAccessSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToRole(String prefix) {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    context.go('/$prefix/$code');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Staff & spectator access', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Enter a tournament code to open an assistant, referee, or public view.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Tournament code or slug',
              isDense: true,
            ),
            onSubmitted: (_) => _goToRole('a'),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _RoleLinkChip(
                label: 'Assistant',
                icon: Icons.assignment_ind,
                tint: Colors.teal.shade50,
                border: Colors.teal.shade200,
                foreground: Colors.teal.shade700,
                onTap: () => _goToRole('a'),
              ),
              _RoleLinkChip(
                label: 'Referee',
                icon: Icons.sports_tennis,
                tint: Colors.orange.shade50,
                border: Colors.orange.shade200,
                foreground: Colors.orange.shade700,
                onTap: () => _goToRole('r'),
              ),
              _RoleLinkChip(
                label: 'Public',
                icon: Icons.public,
                tint: Colors.blue.shade50,
                border: Colors.blue.shade200,
                foreground: Colors.blue.shade700,
                onTap: () => _goToRole('p'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _PublicTournamentSection extends StatelessWidget {
  const _PublicTournamentSection({required this.tournamentsAsync});

  final AsyncValue<List<Tournament>> tournamentsAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Published tournaments', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Public players, spectators, and volunteer referees can open a published tournament directly from here.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          tournamentsAsync.when(
            data: (tournaments) {
              if (tournaments.isEmpty) {
                return const _LandingEmptyState(
                  title: 'No public tournaments yet',
                  message:
                      'Once an organizer publishes a tournament, it will appear here.',
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < tournaments.length; index++) ...[
                    _PublicTournamentRow(tournament: tournaments[index]),
                    if (index < tournaments.length - 1)
                      const Divider(
                        height: AppSpace.lg,
                        color: AppPalette.line,
                      ),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _LandingEmptyState(
              title: 'Could not load published tournaments',
              message: error.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PublicTournamentRow extends StatelessWidget {
  const _PublicTournamentRow({required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final publicCode = (tournament.publicSlug?.trim().isNotEmpty ?? false)
        ? tournament.publicSlug!.trim()
        : tournament.id;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tournament.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${tournament.venue} • ${_formatDate(tournament.startDate)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  _InfoChip(
                    label: 'Code: $publicCode',
                    tint: AppPalette.skySoft,
                    textColor: const Color(0xFF456F77),
                  ),
                  if (tournament.acceptingVolunteerReferees)
                    const _InfoChip(
                      label: 'Volunteer referees open',
                      tint: AppPalette.apricotSoft,
                      textColor: Color(0xFF8F6038),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.md),
        FilledButton.tonal(
          onPressed: () => context.go('/p/$publicCode'),
          child: const Text('Open'),
        ),
      ],
    );
  }
}

final class _LandingEmptyState extends StatelessWidget {
  const _LandingEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.xs),
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
        ),
      ],
    );
  }
}

final class _RoleLinkChip extends StatelessWidget {
  const _RoleLinkChip({
    required this.label,
    required this.icon,
    required this.tint,
    required this.border,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color border;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.tint,
    required this.textColor,
  });

  final String label;
  final Color tint;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: AppPalette.line),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(color: textColor),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
