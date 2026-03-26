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
          if (metrics.length <= 3) {
            return Container(
              padding: const EdgeInsets.all(AppSpace.xs),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppPalette.surface,
                    AppPalette.surfaceSoft.withValues(alpha: 0.78),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadii.panel),
                border: Border.all(
                  color: AppPalette.lineStrong.withValues(alpha: 0.88),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x100E1914),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var index = 0; index < metrics.length; index++) ...[
                    Expanded(
                      child: WorkspaceMetricTile(metric: metrics[index]),
                    ),
                    if (index < metrics.length - 1)
                      const SizedBox(width: AppSpace.xs),
                  ],
                ],
              ),
            );
          }

          final compactWidth = metrics.length == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - AppSpace.sm) / 2;

          return Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final metric in metrics)
                SizedBox(
                  width: compactWidth,
                  child: WorkspaceMetricTile(metric: metric),
                ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(AppSpace.xs),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPalette.surface,
                AppPalette.surfaceSoft.withValues(alpha: 0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadii.panel),
            border: Border.all(
              color: AppPalette.lineStrong.withValues(alpha: 0.88),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x100E1914),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = MediaQuery.sizeOf(context).width < 620;
        final useStackedCompact = isCompact && constraints.maxWidth < 124;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: useStackedCompact ? AppSpace.sm : AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: metric.isHighlighted
                ? AppPalette.surfaceSoft
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.panel),
            border: metric.isHighlighted
                ? Border.all(color: AppPalette.line)
                : null,
          ),
          child: !isCompact
              ? RichText(
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
                )
              : useStackedCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.value,
                      style: AppTheme.numeric(theme.textTheme.titleMedium)
                          .copyWith(
                            color: metric.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      metric.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppPalette.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      metric.value,
                      style: AppTheme.numeric(theme.textTheme.titleMedium)
                          .copyWith(
                            color: metric.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppPalette.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

final class WorkspaceSectionLead extends StatelessWidget {
  const WorkspaceSectionLead({
    required this.title,
    required this.description,
    this.icon,
    this.accent,
    this.trailing,
    super.key,
  });

  final String title;
  final String description;
  final IconData? icon;
  final Color? accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedAccent = accent ?? AppPalette.sageStrong;

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleText = Text(
          title,
          style: constraints.maxWidth < 620
              ? theme.textTheme.headlineLarge
              : theme.textTheme.displaySmall,
        );

        final titleWidget = icon == null
            ? titleText
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: constraints.maxWidth < 620 ? 28 : 30,
                    height: constraints.maxWidth < 620 ? 28 : 30,
                    decoration: BoxDecoration(
                      color: resolvedAccent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 16, color: resolvedAccent),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(child: titleText),
                ],
              );

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget,
            const SizedBox(height: AppSpace.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                description,
                style:
                    (constraints.maxWidth < 620
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(color: AppPalette.inkSoft),
              ),
            ),
          ],
        );

        final leadContent = trailing == null
            ? titleBlock
            : constraints.maxWidth < 760
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: titleWidget),
                      const SizedBox(width: AppSpace.md),
                      trailing!,
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Text(
                      description,
                      style:
                          (constraints.maxWidth < 620
                                  ? theme.textTheme.bodySmall
                                  : theme.textTheme.bodyMedium)
                              ?.copyWith(color: AppPalette.inkSoft),
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: AppSpace.lg),
                  trailing!,
                ],
              );

        if (icon == null) {
          return leadContent;
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 620 ? AppSpace.md : AppSpace.lg,
            vertical: constraints.maxWidth < 620 ? AppSpace.md : AppSpace.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                resolvedAccent.withValues(alpha: 0.22),
                resolvedAccent.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.36, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: resolvedAccent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: resolvedAccent.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: constraints.maxWidth < 620 ? -28 : -18,
                bottom: constraints.maxWidth < 620 ? -26 : -20,
                child: Container(
                  width: constraints.maxWidth < 620 ? 88 : 108,
                  height: constraints.maxWidth < 620 ? 88 : 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: resolvedAccent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                right: constraints.maxWidth < 620 ? -8 : 4,
                top: constraints.maxWidth < 620 ? -8 : -2,
                child: Icon(
                  icon,
                  size: constraints.maxWidth < 620 ? 40 : 52,
                  color: resolvedAccent.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                left: 0,
                top: 2,
                bottom: 2,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: resolvedAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: AppSpace.md),
                child: leadContent,
              ),
            ],
          ),
        );
      },
    );
  }
}

final class WorkspaceSurfaceCard extends StatelessWidget {
  const WorkspaceSurfaceCard({
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.radius = 16,
    super.key,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final accentWash = accent?.withValues(alpha: 0.08);
    final borderColor = accent?.withValues(alpha: 0.22) ?? AppPalette.line;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentWash ?? AppPalette.surface, AppPalette.surface],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: (accent ?? AppPalette.ink).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                gradient: LinearGradient(
                  colors: [accent!, accent!.withValues(alpha: 0.72)],
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: AppPalette.line),
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
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: const Color(0x1FD6A38B),
        borderRadius: BorderRadius.circular(AppRadii.panel),
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
