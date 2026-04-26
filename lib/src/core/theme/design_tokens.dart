import 'dart:math';
import 'package:flutter/material.dart';

/// Aurum Design System — premium UI tokens for OpenClaw.
///
/// Dark-first with warm gold accents, soft glass, satin surfaces,
/// active metal, and ghost surfaces.
class DesignTokens {
  final Brightness brightness;

  // ── Background palette ──────────────────────────────
  final Color bgDeep;
  final Color bgSurface;
  final Color bgElevated;
  final Color bgSoft;
  final Color bgMuted;

  // ── Text palette ────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;
  final Color textInverse;

  // ── Accent palette ──────────────────────────────────
  final Color accentGold;
  final Color accentAmber;
  final Color accentBronze;
  final Color accentIvory;

  // ── Status palette ──────────────────────────────────
  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;
  final Color statusInfo;

  // ── Surface materials ─────────────────────────────
  final SurfaceMaterial glass;
  final SurfaceMaterial satin;
  final SurfaceMaterial metal;
  final SurfaceMaterial ghost;

  // ── Shadows ─────────────────────────────────────────
  final BoxShadow shadowSoft;
  final BoxShadow shadowLifted;
  final BoxShadow shadowGlow;

  // ── Geometry ──────────────────────────────────────
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusPill;

  // ── Spacing ─────────────────────────────────────────
  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;
  final double space6;
  final double space7;
  final double space8;

  // ── Typography ────────────────────────────────────
  final TextTheme textTheme;

  // ── Motion ──────────────────────────────────────────
  final Cubic easePremium;

  const DesignTokens({
    required this.brightness,
    required this.bgDeep,
    required this.bgSurface,
    required this.bgElevated,
    required this.bgSoft,
    required this.bgMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
    required this.textInverse,
    required this.accentGold,
    required this.accentAmber,
    required this.accentBronze,
    required this.accentIvory,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
    required this.statusInfo,
    required this.glass,
    required this.satin,
    required this.metal,
    required this.ghost,
    required this.shadowSoft,
    required this.shadowLifted,
    required this.shadowGlow,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space5,
    required this.space6,
    required this.space7,
    required this.space8,
    required this.textTheme,
    required this.easePremium,
  });

  factory DesignTokens.forBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return DesignTokens(
      brightness: brightness,
      bgDeep: const Color(0xFF08090B),
      bgSurface: const Color(0xFF111318),
      bgElevated: const Color(0xFF191C22),
      bgSoft: const Color(0xFF20242B),
      bgMuted: const Color(0xFF15171C),
      textPrimary: const Color(0xFFF4F1EA),
      textSecondary: const Color(0xFFB9B4AA),
      textMuted: const Color(0xFF7C776E),
      textDisabled: const Color(0xFF4F4A44),
      textInverse: const Color(0xFF08090B),
      accentGold: const Color(0xFFD6B46A),
      accentAmber: const Color(0xFFF2C76E),
      accentBronze: const Color(0xFF9B6B3D),
      accentIvory: const Color(0xFFFFF3D0),
      statusSuccess: const Color(0xFF78C6A3),
      statusWarning: const Color(0xFFE2B86B),
      statusError: const Color(0xFFE06F6F),
      statusInfo: const Color(0xFF7BA7D9),
      glass: SurfaceMaterial.glass(),
      satin: SurfaceMaterial.satin(isDark: isDark),
      metal: SurfaceMaterial.metal(),
      ghost: SurfaceMaterial.ghost(),
      shadowSoft: const BoxShadow(
        color: Color(0x47000000), blurRadius: 32, offset: Offset(0, 12),
      ),
      shadowLifted: const BoxShadow(
        color: Color(0x73000000), blurRadius: 80, offset: Offset(0, 24),
      ),
      shadowGlow: BoxShadow(
        color: const Color(0xFFD6B46A).withValues(alpha: 0.18),
        blurRadius: 32, offset: Offset.zero,
      ),
      radiusSm: 12, radiusMd: 16, radiusLg: 22, radiusXl: 28, radiusPill: 999,
      space1: 4, space2: 8, space3: 12, space4: 16,
      space5: 24, space6: 32, space7: 48, space8: 64,
      textTheme: _buildTextTheme(),
      easePremium: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
  }

  static TextTheme _buildTextTheme() {
    const primary = Color(0xFFF4F1EA);
    const secondary = Color(0xFFB9B4AA);
    const muted = Color(0xFF7C776E);
    return TextTheme(
      displayLarge: const TextStyle(fontSize: 44, fontWeight: FontWeight.w600, color: primary, height: 1.2, letterSpacing: -0.5),
      displayMedium: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: primary, height: 1.2, letterSpacing: -0.3),
      headlineLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: primary, height: 1.3),
      headlineMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: primary, height: 1.3),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary, height: 1.4),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary, height: 1.4),
      titleSmall: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary, height: 1.4),
      bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: primary, height: 1.5),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: primary, height: 1.5),
      bodySmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: secondary, height: 1.4),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primary, height: 1.2),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondary, height: 1.2),
      labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted, height: 1.2, letterSpacing: 0.3),
    );
  }
}

/// One of Aurum's four surface materials.
class SurfaceMaterial {
  final Color background;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? shadows;

  const SurfaceMaterial({required this.background, this.borderColor, this.borderWidth, this.shadows});

  factory SurfaceMaterial.glass() => SurfaceMaterial(
    background: const Color(0xB8111318),
    borderColor: const Color(0x14FFF3D0),
    borderWidth: 1,
    shadows: const [BoxShadow(color: Color(0x73000000), blurRadius: 80, offset: Offset(0, 24))],
  );

  factory SurfaceMaterial.satin({required bool isDark}) => SurfaceMaterial(
    background: isDark ? const Color(0xFF111318) : const Color(0xFFF5F5F0),
    borderColor: const Color(0x12FFFFFF),
    borderWidth: 1,
    shadows: const [BoxShadow(color: Color(0x47000000), blurRadius: 32, offset: Offset(0, 12))],
  );

  factory SurfaceMaterial.metal() => const SurfaceMaterial(
    background: Color(0xFFD6B46A),
    borderColor: Color(0x47FFF3D0),
    borderWidth: 1,
    shadows: [BoxShadow(color: Color(0x38D6B46A), blurRadius: 28, offset: Offset(0, 10))],
  );

  factory SurfaceMaterial.ghost() => const SurfaceMaterial(
    background: Color(0x09FFFFFF),
    borderColor: Color(0x0FFFFFFF),
    borderWidth: 1,
  );

  BoxDecoration toDecoration() => BoxDecoration(
    color: background,
    border: borderColor != null ? Border.all(color: borderColor!, width: borderWidth ?? 1) : null,
    borderRadius: BorderRadius.circular(22),
    boxShadow: shadows,
  );
}
