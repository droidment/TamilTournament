import 'package:flutter/material.dart';

import '../../features/entries/domain/entry.dart';
import '../../theme/app_theme.dart';

final class TeamIdentityPalette {
  const TeamIdentityPalette({
    required this.background,
    required this.backgroundStrong,
    required this.border,
    required this.accent,
    required this.accentSoft,
  });

  final Color background;
  final Color backgroundStrong;
  final Color border;
  final Color accent;
  final Color accentSoft;
}

final class TeamIdentity {
  static const List<TeamIdentityPalette> _palettes = [
    TeamIdentityPalette(
      background: Color(0xFFE7F1EC),
      backgroundStrong: Color(0xFFD5E7DE),
      border: Color(0xFFC7DCCF),
      accent: Color(0xFF4C7267),
      accentSoft: Color(0xFF729689),
    ),
    TeamIdentityPalette(
      background: Color(0xFFE7EFF7),
      backgroundStrong: Color(0xFFD6E4F1),
      border: Color(0xFFC5D6E6),
      accent: Color(0xFF486A82),
      accentSoft: Color(0xFF6F90A6),
    ),
    TeamIdentityPalette(
      background: Color(0xFFF6ECE5),
      backgroundStrong: Color(0xFFEEDCCD),
      border: Color(0xFFE0CCBC),
      accent: Color(0xFF8B6344),
      accentSoft: Color(0xFFB08969),
    ),
    TeamIdentityPalette(
      background: Color(0xFFF1E8EF),
      backgroundStrong: Color(0xFFE6D7E2),
      border: Color(0xFFD9C8D3),
      accent: Color(0xFF7C5E73),
      accentSoft: Color(0xFFA18397),
    ),
    TeamIdentityPalette(
      background: Color(0xFFEAF1E3),
      backgroundStrong: Color(0xFFDCE8D0),
      border: Color(0xFFCDDCBD),
      accent: Color(0xFF65764A),
      accentSoft: Color(0xFF89996B),
    ),
  ];

  static TeamIdentityPalette paletteForEntry(TournamentEntry entry) {
    return paletteForKey(_identityKeyForEntry(entry));
  }

  static List<Color> surfaceGradientForEntry(TournamentEntry entry) {
    final palette = paletteForEntry(entry);
    return [
      Color.alphaBlend(
        palette.background.withValues(alpha: 0.16),
        AppPalette.surface,
      ),
      Color.alphaBlend(
        palette.backgroundStrong.withValues(alpha: 0.08),
        AppPalette.surface,
      ),
    ];
  }

  static Color surfaceBorderForEntry(TournamentEntry entry) {
    final palette = paletteForEntry(entry);
    return Color.alphaBlend(
      palette.border.withValues(alpha: 0.34),
      AppPalette.line,
    );
  }

  static List<Color> surfaceGradientForMatch(
    TournamentEntry teamOne,
    TournamentEntry? teamTwo,
  ) {
    final left = paletteForEntry(teamOne);
    final right = teamTwo == null ? left : paletteForEntry(teamTwo);
    return [
      Color.alphaBlend(
        left.background.withValues(alpha: 0.14),
        AppPalette.surface,
      ),
      Color.alphaBlend(
        right.backgroundStrong.withValues(alpha: 0.1),
        AppPalette.surface,
      ),
    ];
  }

  static Color surfaceBorderForMatch(
    TournamentEntry teamOne,
    TournamentEntry? teamTwo,
  ) {
    final left = paletteForEntry(teamOne);
    final right = teamTwo == null ? left : paletteForEntry(teamTwo);
    return Color.lerp(
          surfaceBorderForEntry(teamOne),
          Color.alphaBlend(
            right.border.withValues(alpha: 0.34),
            AppPalette.line,
          ),
          0.5,
        ) ??
        AppPalette.line;
  }

  static TeamIdentityPalette paletteForLabel(String label) {
    return paletteForKey(_normalize(label));
  }

  static TeamIdentityPalette paletteForKey(String key) {
    final index = _stableHash(key) % _palettes.length;
    return _palettes[index];
  }

  static String _identityKeyForEntry(TournamentEntry entry) {
    final teamName = _normalize(entry.teamName);
    if (teamName.isNotEmpty) {
      return teamName;
    }
    final roster = _normalize(entry.rosterLabel);
    if (roster.isNotEmpty) {
      return roster;
    }
    return _normalize(entry.displayLabel);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    return hash.abs();
  }
}

final class TeamIdentityAvatar extends StatelessWidget {
  const TeamIdentityAvatar({
    super.key,
    required this.entry,
    this.compact = true,
    this.showSeedNumber = false,
    this.size,
    this.radius,
  });

  final TournamentEntry entry;
  final bool compact;
  final bool showSeedNumber;
  final double? size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final palette = TeamIdentity.paletteForEntry(entry);
    final resolvedSize = size ?? (compact ? 56.0 : 76.0);
    final playerSize = compact ? 24.0 : 32.0;
    final borderRadius = radius ?? (compact ? 18.0 : 20.0);

    if (showSeedNumber && entry.seedNumber != null) {
      return Container(
        width: resolvedSize,
        height: resolvedSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.background, palette.backgroundStrong],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: palette.border),
        ),
        child: Stack(
          children: [
            Positioned(
              right: compact ? 6 : 10,
              top: compact ? 6 : 10,
              child: Container(
                width: compact ? 10 : 12,
                height: compact ? 10 : 12,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.34),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Text(
                '${entry.seedNumber}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 24 : 30,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.background, palette.backgroundStrong],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: palette.border),
      ),
      child: Stack(
        children: [
          Positioned(
            left: compact ? 7 : 10,
            bottom: compact ? 7 : 10,
            child: _PlayerBadge(
              size: playerSize,
              fill: Colors.white.withValues(alpha: 0.84),
              accent: palette.accent,
            ),
          ),
          Positioned(
            right: compact ? 7 : 10,
            top: compact ? 7 : 10,
            child: _PlayerBadge(
              size: playerSize,
              fill: Colors.white.withValues(alpha: 0.74),
              accent: palette.accentSoft,
            ),
          ),
          Positioned(
            right: compact ? 5 : 8,
            bottom: compact ? 6 : 10,
            child: Transform.rotate(
              angle: -0.35,
              child: Icon(
                Icons.sports_tennis_rounded,
                size: compact ? 16 : 20,
                color: palette.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PlayerBadge extends StatelessWidget {
  const _PlayerBadge({
    required this.size,
    required this.fill,
    required this.accent,
  });

  final double size;
  final Color fill;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x160C1511),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.person_rounded, size: size * 0.62, color: accent),
    );
  }
}
