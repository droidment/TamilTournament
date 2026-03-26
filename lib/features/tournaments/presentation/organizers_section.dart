import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_theme.dart';
import '../data/tournament_providers.dart';
import '../data/tournament_role_providers.dart';
import '../domain/tournament.dart';
import '../domain/tournament_role.dart';
import 'workspace_components.dart';

final class OrganizersSection extends ConsumerStatefulWidget {
  const OrganizersSection({
    required this.tournament,
    this.embedded = false,
    this.readOnly = false,
    super.key,
  });

  final Tournament tournament;
  final bool embedded;
  final bool readOnly;

  @override
  ConsumerState<OrganizersSection> createState() => _OrganizersSectionState();
}

class _OrganizersSectionState extends ConsumerState<OrganizersSection> {
  bool _isAddingOrganizer = false;
  bool _isAddingAssistant = false;

  Future<void> _showAddOrganizerDialog() async {
    final addedEmail = await showDialog<String>(
      context: context,
      builder: (context) => const _RoleEmailDialog(
        title: 'Add organizer',
        description:
            'Invite another organizer by the Google email they use to sign in.',
        fieldLabel: 'Organizer email',
        fieldHint: 'director@example.com',
        confirmLabel: 'Add organizer',
        emptyMessage: 'Enter an organizer email.',
      ),
    );

    if (addedEmail == null || !mounted) {
      return;
    }

    final normalizedEmail = addedEmail.trim().toLowerCase();
    final organizerEmails = _displayOrganizerEmails;
    if (organizerEmails.contains(normalizedEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$normalizedEmail already has access.')),
      );
      return;
    }

    setState(() {
      _isAddingOrganizer = true;
    });

    try {
      await ref
          .read(tournamentRepositoryProvider)
          .addOrganizerEmail(
            tournamentId: widget.tournament.id,
            organizerEmail: normalizedEmail,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$normalizedEmail can now open this tournament.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyOrganizerError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isAddingOrganizer = false;
        });
      }
    }
  }

  Future<void> _showAddAssistantDialog(List<TournamentRole> roles) async {
    final addedEmail = await showDialog<String>(
      context: context,
      builder: (context) => const _RoleEmailDialog(
        title: 'Add assistant',
        description:
            'Assign an assistant by the Google email they use to sign in.',
        fieldLabel: 'Assistant email',
        fieldHint: 'assistant@example.com',
        confirmLabel: 'Add assistant',
        emptyMessage: 'Enter an assistant email.',
      ),
    );

    if (addedEmail == null || !mounted) {
      return;
    }

    final normalizedEmail = addedEmail.trim().toLowerCase();
    final existingAssistant = roles.any(
      (role) =>
          role.role == TournamentRoleType.assistant &&
          role.isActive &&
          role.email.trim().toLowerCase() == normalizedEmail,
    );
    if (existingAssistant) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$normalizedEmail is already an assistant.')),
      );
      return;
    }

    setState(() {
      _isAddingAssistant = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      await ref
          .read(tournamentRoleRepositoryProvider)
          .addRole(
            tournamentId: widget.tournament.id,
            role: TournamentRole(
              id: normalizedEmail,
              tournamentId: widget.tournament.id,
              userId: normalizedEmail,
              email: normalizedEmail,
              displayName: normalizedEmail,
              role: TournamentRoleType.assistant,
              isActive: true,
              assignedAt: null,
              assignedBy: currentUser?.uid ?? '',
            ),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$normalizedEmail can now open the assistant desk.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyOrganizerError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isAddingAssistant = false;
        });
      }
    }
  }

  Set<String> get _displayOrganizerEmails {
    final emails = widget.tournament.organizerEmails
        .map((email) => email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet();
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email
        ?.trim()
        .toLowerCase();
    if (currentUserEmail != null && currentUserEmail.isNotEmpty) {
      emails.add(currentUserEmail);
    }
    return emails;
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(tournamentRolesProvider(widget.tournament.id));
    final organizerEmails = _displayOrganizerEmails.toList(growable: false)
      ..sort();
    final assistantRoles = rolesAsync.maybeWhen(
      data: (roles) => roles
          .where(
            (role) =>
                role.role == TournamentRoleType.assistant && role.isActive,
          )
          .toList(growable: false)
        ..sort((left, right) => left.email.compareTo(right.email)),
      orElse: () => const <TournamentRole>[],
    );
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email
        ?.trim()
        .toLowerCase();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkspaceSectionLead(
          title: 'Organizer access',
          description:
              'Share this tournament with another organizer using the Google email they sign in with.',
          icon: Icons.admin_panel_settings_outlined,
          accent: AppPalette.sky,
          trailing: FilledButton.icon(
            onPressed: widget.readOnly || _isAddingOrganizer
                ? null
                : _showAddOrganizerDialog,
            icon: _isAddingOrganizer
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(_isAddingOrganizer ? 'Adding...' : 'Add organizer'),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        WorkspaceSurfaceCard(
          padding: const EdgeInsets.all(AppSpace.md),
          radius: 16,
          accent: AppPalette.sky,
          child: Column(
            children: [
              for (var index = 0; index < organizerEmails.length; index++) ...[
                _OrganizerRow(
                  email: organizerEmails[index],
                  isCurrentUser: organizerEmails[index] == currentUserEmail,
                ),
                if (index < organizerEmails.length - 1)
                  const Divider(height: AppSpace.lg, color: AppPalette.line),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        WorkspaceSectionLead(
          title: 'Assistant access',
          description:
              'Assign assistant desk access by the Google email they use to sign in.',
          icon: Icons.assignment_ind,
          accent: AppPalette.sage,
          trailing: FilledButton.icon(
            onPressed: widget.readOnly || _isAddingAssistant
                ? null
                : () => _showAddAssistantDialog(assistantRoles),
            icon: _isAddingAssistant
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(_isAddingAssistant ? 'Adding...' : 'Add assistant'),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        WorkspaceSurfaceCard(
          padding: const EdgeInsets.all(AppSpace.md),
          radius: 16,
          accent: AppPalette.sage,
          child: rolesAsync.when(
            data: (_) => assistantRoles.isEmpty
                ? const _AccessEmptyState(
                    title: 'No assistants assigned yet',
                    message:
                        'Add an assistant email to let someone open the assistant desk.',
                  )
                : Column(
                    children: [
                      for (var index = 0; index < assistantRoles.length; index++) ...[
                        _RoleAccessRow(
                          email: assistantRoles[index].email,
                          isCurrentUser:
                              assistantRoles[index].email == currentUserEmail,
                          badgeLabel: 'Assistant',
                        ),
                        if (index < assistantRoles.length - 1)
                          const Divider(
                            height: AppSpace.lg,
                            color: AppPalette.line,
                          ),
                      ],
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _AccessEmptyState(
              title: 'Could not load assistant access',
              message: _friendlyOrganizerError(error),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Padding(padding: const EdgeInsets.all(AppSpace.lg), child: content);
  }
}

final class _OrganizerRow extends StatelessWidget {
  const _OrganizerRow({required this.email, required this.isCurrentUser});

  final String email;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDFF1EE), Color(0xFFF4FBFA)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.line),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 18,
            color: AppPalette.inkSoft,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  const _OrganizerBadge(
                    label: 'Can organize',
                    foreground: Color(0xFF5F7243),
                    background: Color(0xFFEEF3E5),
                  ),
                  if (isCurrentUser)
                    const _OrganizerBadge(
                      label: 'You',
                      foreground: Color(0xFF8C6238),
                      background: Color(0xFFF8EBDD),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _RoleAccessRow extends StatelessWidget {
  const _RoleAccessRow({
    required this.email,
    required this.isCurrentUser,
    required this.badgeLabel,
  });

  final String email;
  final bool isCurrentUser;
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDFF1EE), Color(0xFFF4FBFA)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.line),
          ),
          child: const Icon(
            Icons.assignment_ind,
            size: 18,
            color: AppPalette.inkSoft,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: AppSpace.xs,
                runSpacing: AppSpace.xs,
                children: [
                  _OrganizerBadge(
                    label: badgeLabel,
                    foreground: const Color(0xFF365141),
                    background: const Color(0xFFE7F4EE),
                  ),
                  if (isCurrentUser)
                    const _OrganizerBadge(
                      label: 'You',
                      foreground: Color(0xFF8C6238),
                      background: Color(0xFFF8EBDD),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _AccessEmptyState extends StatelessWidget {
  const _AccessEmptyState({required this.title, required this.message});

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
          ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
        ),
      ],
    );
  }
}

final class _OrganizerBadge extends StatelessWidget {
  const _OrganizerBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: background.withValues(alpha: 0.9)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _RoleEmailDialog extends StatefulWidget {
  const _RoleEmailDialog({
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.fieldHint,
    required this.confirmLabel,
    required this.emptyMessage,
  });

  final String title;
  final String description;
  final String fieldLabel;
  final String fieldHint;
  final String confirmLabel;
  final String emptyMessage;

  @override
  State<_RoleEmailDialog> createState() => _RoleEmailDialogState();
}

class _RoleEmailDialogState extends State<_RoleEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppPalette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.panel),
        side: const BorderSide(color: AppPalette.line),
      ),
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
              ),
              const SizedBox(height: AppSpace.md),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: widget.fieldLabel,
                  hintText: widget.fieldHint,
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return widget.emptyMessage;
                  }
                  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailPattern.hasMatch(email)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

String _friendlyOrganizerError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'This organizer account cannot update sharing for this tournament yet.';
  }
  if (message.contains('Enter a valid organizer email.')) {
    return 'Enter a valid organizer email.';
  }
  return 'Could not update organizer access right now.';
}
