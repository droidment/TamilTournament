import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../firebase/firebase_status.dart';
import '../../../theme/app_theme.dart';
import '../../tournaments/presentation/tournament_workspace_panel.dart';

final class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Sidebar(),
              SizedBox(width: AppSpace.lg),
              Expanded(child: _DashboardContent()),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _Header(),
        SizedBox(height: AppSpace.lg),
        _OverviewRow(),
        SizedBox(height: AppSpace.lg),
        _WorkArea(),
        SizedBox(height: AppSpace.lg),
        TournamentWorkspacePanel(),
        SizedBox(height: AppSpace.lg),
        _FirebaseNotice(),
      ],
    );
  }
}

final class _FirebaseNotice extends StatelessWidget {
  const _FirebaseNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<FirebaseStatus>(
      valueListenable: FirebaseBindingState.instance.value,
      builder: (context, status, _) {
        if (status == FirebaseStatus.configured) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(AppRadii.panel),
            border: Border.all(color: AppPalette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase not configured yet',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Choose the Firebase project for this app, then run flutterfire configure for web to generate the web Firebase options file.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppPalette.inkSoft,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : user?.email ?? 'Organizer';
    final email = user?.email ?? 'Signed in with Google';
    final initials = _userInitials(displayName);

    return Container(
      width: 248,
      padding: const EdgeInsets.all(AppSpace.lg),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppPalette.sage, AppPalette.surfaceSoft],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(initials, style: theme.textTheme.labelLarge),
              ),
              const SizedBox(width: AppSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tamil Tournament', style: theme.textTheme.titleMedium),
                  Text(
                    'Web MVP shell',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppPalette.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          const _SidebarSection(
            label: 'Operations',
            items: [
              _NavItemData('Dashboard', '4'),
              _NavItemData('Scheduler', '12', selected: true),
              _NavItemData('Courts', '10'),
              _NavItemData('Scores', '3'),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          const _SidebarSection(
            label: 'Tournament',
            items: [
              _NavItemData('Entries', ''),
              _NavItemData('Categories', ''),
              _NavItemData('Standings', ''),
              _NavItemData('Print Center', ''),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: AppPalette.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppPalette.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppPalette.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: FirebaseAuth.instance.signOut,
                    child: const Text('Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _userInitials(String value) {
  final parts = value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) {
    return 'TT';
  }

  return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
}

final class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.label, required this.items});

  final String label;
  final List<_NavItemData> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppPalette.inkMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        for (final item in items) _SidebarItem(item: item),
      ],
    );
  }
}

final class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.item});

  final _NavItemData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: item.selected
            ? const LinearGradient(
                colors: [Color(0x2D98BFA6), Color(0x61DCE9E0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        border: Border.all(
          color: item.selected ? const Color(0x4D98BFA6) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: item.selected ? AppPalette.ink : AppPalette.inkSoft,
              ),
            ),
          ),
          if (item.count.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppPalette.surfaceSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppPalette.line),
              ),
              child: Text(
                item.count,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppPalette.inkSoft,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _NavItemData {
  const _NavItemData(this.label, this.count, {this.selected = false});

  final String label;
  final String count;
  final bool selected;
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduler board', style: theme.textTheme.displayMedium),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Saturday, June 14 · 10 active courts · Web-first tournament shell',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _GhostChip(label: 'Round robin'),
              _GhostChip(label: 'Pause court'),
              _PrimaryPill(label: 'Assign next match'),
            ],
          ),
        ],
      ),
    );
  }
}

final class _OverviewRow extends StatelessWidget {
  const _OverviewRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Matches live',
            value: '6',
            meta: '2 courts opening soon',
            accent: AppPalette.sageStrong,
            wash: Color(0x1F98BFA6),
            valueColor: Color(0xFF486655),
          ),
        ),
        SizedBox(width: AppSpace.md),
        Expanded(
          child: _MetricCard(
            label: 'Ready queue',
            value: '12',
            meta: '3 waiting on overlap',
            accent: AppPalette.sky,
            wash: Color(0x268DBEC6),
            valueColor: Color(0xFF376570),
          ),
        ),
        SizedBox(width: AppSpace.md),
        Expanded(
          child: _MetricCard(
            label: 'Pending scores',
            value: '3',
            meta: 'approval target under 5 min',
            accent: AppPalette.apricot,
            wash: Color(0x2BDDB085),
            valueColor: Color(0xFF8F6038),
          ),
        ),
        SizedBox(width: AppSpace.md),
        Expanded(
          child: _MetricCard(
            label: 'Checked in',
            value: '44',
            meta: '4 pairs not yet confirmed',
            accent: AppPalette.oliveStrong,
            wash: Color(0x268FA16F),
            valueColor: Color(0xFF5F7243),
          ),
        ),
      ],
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.meta,
    required this.accent,
    required this.wash,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String meta;
  final Color accent;
  final Color wash;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
        gradient: LinearGradient(
          colors: [wash, Colors.transparent],
          begin: Alignment.topCenter,
          end: const Alignment(0, 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 4, color: accent),
          const SizedBox(height: AppSpace.md),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            value,
            style: AppTheme.numeric(theme.textTheme.displaySmall).copyWith(
              color: valueColor,
              fontSize: 32,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(height: 1, color: AppPalette.line),
          const SizedBox(height: AppSpace.md),
          Text(
            meta,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppPalette.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

final class _WorkArea extends StatelessWidget {
  const _WorkArea();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _QueuePanel()),
        SizedBox(width: AppSpace.lg),
        Expanded(flex: 5, child: _CourtsPanel()),
      ],
    );
  }
}

final class _QueuePanel extends StatelessWidget {
  const _QueuePanel();

  @override
  Widget build(BuildContext context) {
    return const _SurfacePanel(
      title: 'Ready queue',
      subtitle:
          'Whiter surfaces, stronger text, spring accent only where useful',
      trailing: _TintChip(
        label: '12 matches',
        background: AppPalette.skySoft,
        border: Color(0x528DBEC6),
        foreground: Color(0xFF456F77),
      ),
      child: Column(
        children: [
          _QueueCard(
            accent: AppPalette.menCategory,
            categoryLabel: "Men's Open",
            title: "Men's Open · Group A",
            matchup: 'Arun / Vimal vs Hari / Satheesh',
            sequence: 'SEQ 014',
            primaryAction: 'Assign to court',
            secondaryAction: 'Hold',
          ),
          SizedBox(height: AppSpace.md),
          _QueueCard(
            accent: AppPalette.fortyCategory,
            categoryLabel: '40+',
            title: '40+ · Semifinal',
            matchup: 'Bala / Mano vs Siva / Rajan',
            sequence: 'SEQ 018',
            primaryAction: 'Review conflict',
            secondaryAction: 'Move later',
            conflict: true,
          ),
          SizedBox(height: AppSpace.md),
          _QueueCard(
            accent: AppPalette.womenCategory,
            categoryLabel: "Women's Open",
            title: "Women's Open · Group B",
            matchup: 'Nila / Kavya vs Anu / Revathi',
            sequence: 'SEQ 020',
            primaryAction: 'Assign to court',
            secondaryAction: 'Details',
          ),
        ],
      ),
    );
  }
}

final class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.accent,
    required this.categoryLabel,
    required this.title,
    required this.matchup,
    required this.sequence,
    required this.primaryAction,
    required this.secondaryAction,
    this.conflict = false,
  });

  final Color accent;
  final String categoryLabel;
  final String title;
  final String matchup;
  final String sequence;
  final String primaryAction;
  final String secondaryAction;
  final bool conflict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpace.sm,
                            children: [
                              Text(title, style: theme.textTheme.titleLarge),
                              _CategoryChip(
                                label: categoryLabel,
                                accent: accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            matchup,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppPalette.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      sequence,
                      style: AppTheme.numeric(
                        theme.textTheme.bodySmall,
                      ).copyWith(color: AppPalette.inkSoft),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    const _StateChip(
                      label: 'Ready now',
                      background: Color(0x2F98BFA6),
                      border: Color(0x4D6F9A82),
                      foreground: Color(0xFF365141),
                    ),
                    _StateChip(
                      label: conflict ? 'Unlock in 7m' : 'Rested 14m',
                      background: const Color(0x42E9D9A5),
                      border: const Color(0x57CCB778),
                      foreground: const Color(0xFF6F6241),
                    ),
                    if (conflict)
                      const _StateChip(
                        label: 'Player overlap',
                        background: Color(0x24C97D6B),
                        border: Color(0x47C97D6B),
                        foreground: Color(0xFF7B4D42),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    _PrimaryPill(label: primaryAction),
                    const SizedBox(width: AppSpace.sm),
                    _GhostChip(label: secondaryAction),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _CourtsPanel extends StatelessWidget {
  const _CourtsPanel();

  @override
  Widget build(BuildContext context) {
    return const _SurfacePanel(
      title: 'Live courts',
      subtitle:
          'Color now supports status instead of tinting the whole interface',
      trailing: _TintChip(
        label: '10 active',
        background: AppPalette.oliveSoft,
        border: Color(0x528FA16F),
        foreground: Color(0xFF5F7243),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CourtCard(
                  accent: AppPalette.fiftyCategory,
                  status: 'In progress',
                  court: 'COURT 01',
                  title: 'Rakesh / Dinesh vs Mano / Kumar',
                  detail: '50+ · Game 2 · Started 9:42 AM',
                ),
              ),
              SizedBox(width: AppSpace.md),
              Expanded(
                child: _CourtCard(
                  accent: AppPalette.oliveStrong,
                  status: 'Open',
                  court: 'COURT 02',
                  title: 'Available for next ready match',
                  detail: "Suggested: Men's Open · Group A",
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: _CourtCard(
                  accent: AppPalette.apricot,
                  status: 'Paused',
                  court: 'COURT 03',
                  title: 'Floor wipe in progress',
                  detail: 'Expected return in 8 minutes',
                ),
              ),
              SizedBox(width: AppSpace.md),
              Expanded(
                child: _CourtCard(
                  accent: AppPalette.terracotta,
                  status: 'Called',
                  court: 'COURT 04',
                  title: 'Naren / Kobi vs Senthil / Ashok',
                  detail: '40+ · Players walking to court',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.accent,
    required this.status,
    required this.court,
    required this.title,
    required this.detail,
  });

  final Color accent;
  final String status;
  final String court;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 216,
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        court,
                        style: AppTheme.numeric(
                          theme.textTheme.bodySmall,
                        ).copyWith(color: AppPalette.inkSoft),
                      ),
                    ),
                    _GhostChip(label: status),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpace.md),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          child,
        ],
      ),
    );
  }
}

final class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: 0.1), Colors.white),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppPalette.inkSoft,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

final class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: foreground),
      ),
    );
  }
}

final class _GhostChip extends StatelessWidget {
  const _GhostChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.line),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: AppPalette.ink),
      ),
    );
  }
}

final class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA9CCB7), Color(0xFF8FB69D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x596F9A82)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x336F9A82),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppPalette.ink),
        ),
      ),
    );
  }
}

final class _TintChip extends StatelessWidget {
  const _TintChip({
    required this.label,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color border;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
      ),
    );
  }
}
