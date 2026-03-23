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
        throw UnsupportedError('Google popup sign-in is configured for web.');
      }

      final provider = GoogleAuthProvider()
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});

      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = error.message ?? 'Google sign-in failed.';
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpace.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Run the tournament from one screen, not five spreadsheets.',
                            style: theme.textTheme.displayLarge,
                          ),
                          const SizedBox(height: AppSpace.lg),
                          Text(
                            'Google sign-in is the first gate for the web MVP. After auth, the app will move into tournament setup, entries, scheduling, and score approval.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppPalette.inkSoft,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          Wrap(
                            spacing: AppSpace.sm,
                            runSpacing: AppSpace.sm,
                            children: const [
                              _InfoChip(
                                label: 'Google Auth',
                                tint: AppPalette.sageSoft,
                                textColor: AppPalette.ink,
                              ),
                              _InfoChip(
                                label: 'Firestore',
                                tint: AppPalette.skySoft,
                                textColor: Color(0xFF456F77),
                              ),
                              _InfoChip(
                                label: 'Storage',
                                tint: AppPalette.apricotSoft,
                                textColor: Color(0xFF8F6038),
                              ),
                              _InfoChip(
                                label: 'Hosting',
                                tint: AppPalette.oliveSoft,
                                textColor: Color(0xFF5F7243),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpace.xl),
                      decoration: BoxDecoration(
                        color: AppPalette.surface,
                        borderRadius: BorderRadius.circular(AppRadii.panel),
                        border: Border.all(color: AppPalette.line),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12443828),
                            blurRadius: 50,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in to continue',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            'Use your Google account to access the organizer workspace.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.inkSoft,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpace.sm,
                                ),
                                child: Text(
                                  _isLoading
                                      ? 'Opening Google...'
                                      : 'Continue with Google',
                                ),
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
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0x47C97D6B),
                                ),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF7B4D42),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpace.xl),
                          Text(
                            'Before sign-in works in the browser, make sure Google is enabled in Firebase Authentication and localhost is listed as an authorized domain.',
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(color: textColor),
      ),
    );
  }
}
