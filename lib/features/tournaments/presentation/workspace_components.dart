import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

final class WorkspaceMetricItemData {
  const WorkspaceMetricItemData({
    required this.value,
    required this.label,
    required this.foreground,
    this.isHighlighted = false,
  });

  final String value;
  final String label;
  final Color foreground;
  final bool isHighlighted;
}

final class WorkspaceStatRail extends StatelessWidget {
  const WorkspaceStatRail({required this.metrics, super.key});

  final List<WorkspaceMetricItemData> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                WorkspaceMetricTile(metric: metrics[index]),
                if (index < metrics.length - 1)
                  const SizedBox(height: AppSpace.sm),
              ],
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppPalette.surfaceSoft,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppPalette.line.withValues(alpha: 0.9)),
          ),
          child: Row(
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                Expanded(child: WorkspaceMetricTile(metric: metrics[index])),
                if (index < metrics.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

final class WorkspaceMetricTile extends StatelessWidget {
  const WorkspaceMetricTile({required this.metric, super.key});

  final WorkspaceMetricItemData metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 620;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: metric.isHighlighted ? AppPalette.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: metric.isHighlighted
            ? const [
                BoxShadow(
                  color: Color(0x140F1913),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: isCompact
          ? Row(
              children: [
                Text(
                  metric.value,
                  style: AppTheme.numeric(theme.textTheme.titleMedium).copyWith(
                    color: metric.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  metric.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppPalette.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: metric.value,
                    style: AppTheme.numeric(theme.textTheme.titleMedium)
                        .copyWith(
                          color: metric.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextSpan(
                    text: ' ${metric.label}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppPalette.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

final class WorkspaceSectionLead extends StatelessWidget {
  const WorkspaceSectionLead({
    required this.title,
    required this.description,
    this.trailing,
    super.key,
  });

  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.displaySmall),
            const SizedBox(height: AppSpace.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppPalette.inkSoft,
                ),
              ),
            ),
          ],
        );

        if (trailing == null) {
          return titleBlock;
        }

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: AppSpace.md),
              trailing!,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppSpace.lg),
            trailing!,
          ],
        );
      },
    );
  }
}

final class WorkspaceSurfaceCard extends StatelessWidget {
  const WorkspaceSurfaceCard({
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(AppSpace.xl),
    this.radius = 26,
    super.key,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120E1712),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (accent != null)
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

final class WorkspaceTag extends StatelessWidget {
  const WorkspaceTag({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    super.key,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

final class WorkspaceEmptyCard extends StatelessWidget {
  const WorkspaceEmptyCard({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WorkspaceSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpace.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class WorkspaceErrorCard extends StatelessWidget {
  const WorkspaceErrorCard({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: const Color(0x1FD6A38B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x5ED6A38B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF7B4D42),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7B4D42),
            ),
          ),
        ],
      ),
    );
  }
}
