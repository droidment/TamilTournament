import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

final class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
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
                    child: Flex(
                      direction: isCompact ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: isCompact ? 0 : AppSpace.xl,
                              bottom: isCompact ? AppSpace.lg : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Run the tournament from one screen, not five spreadsheets.',
                                  style:
                                      (isCompact
                                              ? theme.textTheme.headlineLarge
                                              : theme.textTheme.displayLarge)
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                ),
                                const SizedBox(height: AppSpace.md),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 560,
                                  ),
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
                            ),
                          ),
                        ),
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpace.lg),
                            decoration: BoxDecoration(
                              color: AppPalette.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadii.panel,
                              ),
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
                                    onPressed: _isLoading
                                        ? null
                                        : _signInWithGoogle,
                                    child: Text(
                                      _isLoading
                                          ? 'Opening sign-in...'
                                          : 'Enter workspace',
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
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.panel,
                                      ),
                                      border: Border.all(
                                        color: const Color(0x47C97D6B),
                                      ),
                                    ),
                                    child: Text(
                                      _errorMessage!,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                          ),
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
