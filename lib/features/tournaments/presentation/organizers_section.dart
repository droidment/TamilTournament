import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  bool _isAddingReferee = false;
  bool _isUpdatingPublicAccess = false;
  String? _busyRoleId;

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
              assignmentSource: TournamentRoleAssignmentSource.organizer,
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

  Future<void> _showAddRefereeDialog(List<TournamentRole> roles) async {
    final addedEmail = await showDialog<String>(
      context: context,
      builder: (context) => const _RoleEmailDialog(
        title: 'Add referee',
        description:
            'Assign a referee by the Google email they use to sign in.',
        fieldLabel: 'Referee email',
        fieldHint: 'referee@example.com',
        confirmLabel: 'Add referee',
        emptyMessage: 'Enter a referee email.',
      ),
    );

    if (addedEmail == null || !mounted) {
      return;
    }

    final normalizedEmail = addedEmail.trim().toLowerCase();
    final existingReferee = roles.any(
      (role) =>
          role.role == TournamentRoleType.referee &&
          role.isActive &&
          role.email.trim().toLowerCase() == normalizedEmail,
    );
    if (existingReferee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$normalizedEmail is already a referee.')),
      );
      return;
    }

    setState(() {
      _isAddingReferee = true;
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
              role: TournamentRoleType.referee,
              isActive: true,
              assignmentSource: TournamentRoleAssignmentSource.organizer,
              assignedAt: null,
              assignedBy: currentUser?.uid ?? '',
            ),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$normalizedEmail can now open the referee desk.'),
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
          _isAddingReferee = false;
        });
      }
    }
  }

  Future<void> _updatePublicAccess({
    required bool isPublic,
    required bool acceptingVolunteerReferees,
  }) async {
    if (_isUpdatingPublicAccess) {
      return;
    }
    setState(() {
      _isUpdatingPublicAccess = true;
    });
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .updatePublicAccess(
            tournamentId: widget.tournament.id,
            isPublic: isPublic,
            acceptingVolunteerReferees: acceptingVolunteerReferees,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPublic
                ? acceptingVolunteerReferees
                      ? 'Public view is live and volunteer referees are enabled.'
                      : 'Public view is live.'
                : 'Public view is now hidden.',
          ),
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
          _isUpdatingPublicAccess = false;
        });
      }
    }
  }

  Future<void> _deactivateRole(TournamentRole role) async {
    if (_busyRoleId != null) {
      return;
    }
    setState(() {
      _busyRoleId = role.id;
    });
    try {
      await ref
          .read(tournamentRoleRepositoryProvider)
          .deactivateRole(tournamentId: widget.tournament.id, roleId: role.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${role.email} no longer has referee desk access.'),
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
          _busyRoleId = null;
        });
      }
    }
  }

  Future<void> _showAccessListDialog({
    required String title,
    required Color accent,
    required Widget child,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.panel),
          side: const BorderSide(color: AppPalette.line),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(title)),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(child: child),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
    final publicCode =
        (widget.tournament.publicSlug?.trim().isNotEmpty ?? false)
        ? widget.tournament.publicSlug!.trim()
        : widget.tournament.id;
    final assistantRoles = rolesAsync.maybeWhen(
      data: (roles) =>
          roles
              .where(
                (role) =>
                    role.role == TournamentRoleType.assistant && role.isActive,
              )
              .toList(growable: false)
            ..sort((left, right) => left.email.compareTo(right.email)),
      orElse: () => const <TournamentRole>[],
    );
    final refereeRoles = rolesAsync.maybeWhen(
      data: (roles) =>
          roles
              .where((role) => role.role == TournamentRoleType.referee)
              .toList(growable: false)
            ..sort((left, right) {
              if (left.isActive != right.isActive) {
                return right.isActive ? 1 : -1;
              }
              return left.email.compareTo(right.email);
            }),
      orElse: () => const <TournamentRole>[],
    );
    final organizerAssignedReferees = refereeRoles
        .where(
          (role) =>
              role.assignmentSource == TournamentRoleAssignmentSource.organizer,
        )
        .toList(growable: false);
    final volunteeredReferees = refereeRoles
        .where(
          (role) =>
              role.assignmentSource == TournamentRoleAssignmentSource.volunteer,
        )
        .toList(growable: false);
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email
        ?.trim()
        .toLowerCase();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkspaceSectionLead(
          title: 'Public & volunteer access',
          description:
              'Publish the tournament page for players and spectators, then choose whether signed-in visitors can volunteer as referees.',
          icon: Icons.public,
          accent: AppPalette.sky,
          trailing: FilledButton.tonalIcon(
            onPressed: widget.tournament.isPublic
                ? () => context.go('/p/$publicCode')
                : null,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open public view'),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        WorkspaceSurfaceCard(
          padding: const EdgeInsets.all(AppSpace.md),
          radius: 16,
          accent: AppPalette.sky,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ToggleAccessRow(
                title: 'Public tournament page',
                description:
                    'Lets players and spectators open the tournament by public code and follow official results live.',
                value: widget.tournament.isPublic,
                isBusy: _isUpdatingPublicAccess,
                onChanged: widget.readOnly
                    ? null
                    : (value) => _updatePublicAccess(
                        isPublic: value,
                        acceptingVolunteerReferees: value
                            ? widget.tournament.acceptingVolunteerReferees
                            : false,
                      ),
              ),
              const Divider(height: AppSpace.lg, color: AppPalette.line),
              _ToggleAccessRow(
                title: 'Volunteer referees',
                description: widget.tournament.isPublic
                    ? 'Signed-in visitors can immediately volunteer and unlock the referee desk.'
                    : 'Turn on the public tournament page first to accept volunteer referees.',
                value:
                    widget.tournament.isPublic &&
                    widget.tournament.acceptingVolunteerReferees,
                isBusy: _isUpdatingPublicAccess,
                onChanged: widget.readOnly || !widget.tournament.isPublic
                    ? null
                    : (value) => _updatePublicAccess(
                        isPublic: true,
                        acceptingVolunteerReferees: value,
                      ),
              ),
              const SizedBox(height: AppSpace.md),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  _OrganizerBadge(
                    label: widget.tournament.isPublic
                        ? 'Public code: $publicCode'
                        : 'Private tournament',
                    foreground: widget.tournament.isPublic
                        ? const Color(0xFF456F77)
                        : AppPalette.inkSoft,
                    background: widget.tournament.isPublic
                        ? AppPalette.skySoft
                        : AppPalette.surfaceSoft,
                  ),
                  if (widget.tournament.acceptingVolunteerReferees)
                    const _OrganizerBadge(
                      label: 'Volunteers open',
                      foreground: Color(0xFF365141),
                      background: Color(0xFFE7F4EE),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        WorkspaceSectionLead(
          title: 'Access management',
          description:
              'Manage organizer, assistant, and referee access from compact action buttons instead of long inline lists.',
          icon: Icons.manage_accounts_outlined,
          accent: AppPalette.sage,
        ),
        const SizedBox(height: AppSpace.md),
        WorkspaceSurfaceCard(
          padding: const EdgeInsets.all(AppSpace.md),
          radius: 16,
          accent: AppPalette.sage,
          child: Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.md,
            children: [
              _AccessActionTile(
                title: 'Organizers',
                subtitle: '${organizerEmails.length} active',
                accent: AppPalette.sky,
                primaryLabel: _isAddingOrganizer ? 'Adding...' : 'Add',
                primaryIcon: _isAddingOrganizer
                    ? null
                    : Icons.person_add_alt_1_rounded,
                onPrimaryPressed: widget.readOnly || _isAddingOrganizer
                    ? null
                    : _showAddOrganizerDialog,
                secondaryLabel: 'View',
                onSecondaryPressed: () => _showAccessListDialog(
                  title: 'Organizer access',
                  accent: AppPalette.sky,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < organizerEmails.length;
                        index++
                      ) ...[
                        _OrganizerRow(
                          email: organizerEmails[index],
                          isCurrentUser:
                              organizerEmails[index] == currentUserEmail,
                        ),
                        if (index < organizerEmails.length - 1)
                          const Divider(
                            height: AppSpace.lg,
                            color: AppPalette.line,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              _AccessActionTile(
                title: 'Assistants',
                subtitle: assistantRoles.isEmpty
                    ? 'No assistants'
                    : '${assistantRoles.length} active',
                accent: AppPalette.sage,
                primaryLabel: _isAddingAssistant ? 'Adding...' : 'Add',
                primaryIcon: _isAddingAssistant
                    ? null
                    : Icons.person_add_alt_1_rounded,
                onPrimaryPressed: widget.readOnly || _isAddingAssistant
                    ? null
                    : () => _showAddAssistantDialog(assistantRoles),
                secondaryLabel: 'View',
                onSecondaryPressed: () => _showAccessListDialog(
                  title: 'Assistant access',
                  accent: AppPalette.sage,
                  child: assistantRoles.isEmpty
                      ? const _AccessEmptyState(
                          title: 'No assistants assigned yet',
                          message:
                              'Add an assistant email to let someone open the assistant desk.',
                        )
                      : Column(
                          children: [
                            for (
                              var index = 0;
                              index < assistantRoles.length;
                              index++
                            ) ...[
                              _RoleAccessRow(
                                email: assistantRoles[index].email,
                                isCurrentUser:
                                    assistantRoles[index].email ==
                                    currentUserEmail,
                                badges: const [
                                  _OrganizerBadge(
                                    label: 'Assistant',
                                    foreground: Color(0xFF365141),
                                    background: Color(0xFFE7F4EE),
                                  ),
                                ],
                              ),
                              if (index < assistantRoles.length - 1)
                                const Divider(
                                  height: AppSpace.lg,
                                  color: AppPalette.line,
                                ),
                            ],
                          ],
                        ),
                ),
              ),
              _AccessActionTile(
                title: 'Referees',
                subtitle: refereeRoles.isEmpty
                    ? 'No referees'
                    : '${refereeRoles.where((role) => role.isActive).length} active',
                accent: AppPalette.apricot,
                primaryLabel: _isAddingReferee ? 'Adding...' : 'Add',
                primaryIcon: _isAddingReferee
                    ? null
                    : Icons.person_add_alt_1_rounded,
                onPrimaryPressed: widget.readOnly || _isAddingReferee
                    ? null
                    : () => _showAddRefereeDialog(refereeRoles),
                secondaryLabel: 'Manage',
                onSecondaryPressed: () => _showAccessListDialog(
                  title: 'Referee access',
                  accent: AppPalette.apricot,
                  child: refereeRoles.isEmpty
                      ? const _AccessEmptyState(
                          title: 'No referees added yet',
                          message:
                              'Assign a referee by email or let signed-in visitors volunteer once the public page is live.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RoleGroupBlock(
                              title: 'Organizer-assigned',
                              roles: organizerAssignedReferees,
                              currentUserEmail: currentUserEmail,
                              busyRoleId: _busyRoleId,
                              onDeactivate: widget.readOnly
                                  ? null
                                  : _deactivateRole,
                            ),
                            const SizedBox(height: AppSpace.lg),
                            _RoleGroupBlock(
                              title: 'Volunteered',
                              roles: volunteeredReferees,
                              currentUserEmail: currentUserEmail,
                              busyRoleId: _busyRoleId,
                              onDeactivate: widget.readOnly
                                  ? null
                                  : _deactivateRole,
                            ),
                          ],
                        ),
                ),
              ),
            ],
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

final class _AccessActionTile extends StatelessWidget {
  const _AccessActionTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.primaryIcon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback onSecondaryPressed;
  final IconData? primaryIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.inkSoft),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPrimaryPressed,
                  icon: primaryIcon == null
                      ? const SizedBox.shrink()
                      : Icon(primaryIcon, size: 16),
                  label: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondaryPressed,
                  child: Text(secondaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _RoleAccessRow extends StatelessWidget {
  const _RoleAccessRow({
    required this.email,
    required this.isCurrentUser,
    required this.badges,
    this.trailing,
    this.icon = Icons.assignment_ind,
  });

  final String email;
  final bool isCurrentUser;
  final List<_OrganizerBadge> badges;
  final Widget? trailing;
  final IconData icon;

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
          child: Icon(icon, size: 18, color: AppPalette.inkSoft),
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
                  ...badges,
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
        if (trailing != null) ...[
          const SizedBox(width: AppSpace.md),
          trailing!,
        ],
      ],
    );
  }
}

final class _RoleGroupBlock extends StatelessWidget {
  const _RoleGroupBlock({
    required this.title,
    required this.roles,
    required this.currentUserEmail,
    required this.busyRoleId,
    required this.onDeactivate,
  });

  final String title;
  final List<TournamentRole> roles;
  final String? currentUserEmail;
  final String? busyRoleId;
  final ValueChanged<TournamentRole>? onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpace.sm),
        if (roles.isEmpty)
          const _AccessEmptyState(
            title: 'Nothing here yet',
            message: 'This group will populate once referee access is added.',
          )
        else
          Column(
            children: [
              for (var index = 0; index < roles.length; index++) ...[
                _RoleAccessRow(
                  email: roles[index].email,
                  isCurrentUser: roles[index].email == currentUserEmail,
                  icon: Icons.sports_tennis,
                  badges: [
                    _OrganizerBadge(
                      label: roles[index].assignmentSource.label,
                      foreground:
                          roles[index].assignmentSource ==
                              TournamentRoleAssignmentSource.volunteer
                          ? const Color(0xFF8F6038)
                          : const Color(0xFF365141),
                      background:
                          roles[index].assignmentSource ==
                              TournamentRoleAssignmentSource.volunteer
                          ? AppPalette.apricotSoft
                          : const Color(0xFFE7F4EE),
                    ),
                    _OrganizerBadge(
                      label: roles[index].isActive ? 'Active' : 'Inactive',
                      foreground: roles[index].isActive
                          ? const Color(0xFF365141)
                          : AppPalette.inkSoft,
                      background: roles[index].isActive
                          ? const Color(0xFFE7F4EE)
                          : AppPalette.surfaceSoft,
                    ),
                  ],
                  trailing: roles[index].isActive && onDeactivate != null
                      ? OutlinedButton(
                          onPressed: busyRoleId == roles[index].id
                              ? null
                              : () => onDeactivate!(roles[index]),
                          child: Text(
                            busyRoleId == roles[index].id
                                ? 'Updating...'
                                : 'Deactivate',
                          ),
                        )
                      : null,
                ),
                if (index < roles.length - 1)
                  const Divider(height: AppSpace.lg, color: AppPalette.line),
              ],
            ],
          ),
      ],
    );
  }
}

final class _ToggleAccessRow extends StatelessWidget {
  const _ToggleAccessRow({
    required this.title,
    required this.description,
    required this.value,
    required this.isBusy,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final bool isBusy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpace.xs),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPalette.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Switch.adaptive(value: value, onChanged: isBusy ? null : onChanged),
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
