import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/theme/design_tokens.dart';

void main() {
  group('DesignTokens — Aurum', () {
    late DesignTokens tokens;

    setUp(() {
      tokens = DesignTokens.forBrightness(Brightness.dark);
    });

    group('background palette', () {
      test('bgDeep is #08090B', () {
        expect(tokens.bgDeep, const Color(0xFF08090B));
      });

      test('bgSurface is #111318', () {
        expect(tokens.bgSurface, const Color(0xFF111318));
      });

      test('bgElevated is #191C22', () {
        expect(tokens.bgElevated, const Color(0xFF191C22));
      });

      test('bgSoft is #20242B', () {
        expect(tokens.bgSoft, const Color(0xFF20242B));
      });

      test('bgMuted is #15171C', () {
        expect(tokens.bgMuted, const Color(0xFF15171C));
      });

      test('surfaces are ordered by depth', () {
        expect(
          _luminance(tokens.bgDeep),
          lessThan(_luminance(tokens.bgSurface)),
          reason: 'bgDeep should be darker than bgSurface',
        );
        expect(
          _luminance(tokens.bgSurface),
          lessThan(_luminance(tokens.bgElevated)),
          reason: 'bgSurface should be darker than bgElevated',
        );
      });
    });

    group('text palette', () {
      test('textPrimary is #F4F1EA', () {
        expect(tokens.textPrimary, const Color(0xFFF4F1EA));
      });

      test('textSecondary is #B9B4AA', () {
        expect(tokens.textSecondary, const Color(0xFFB9B4AA));
      });

      test('textMuted is #7C776E', () {
        expect(tokens.textMuted, const Color(0xFF7C776E));
      });

      test('textDisabled is #4F4A44', () {
        expect(tokens.textDisabled, const Color(0xFF4F4A44));
      });

      test('textInverse is #08090B', () {
        expect(tokens.textInverse, const Color(0xFF08090B));
      });

      test('text colors have correct contrast ordering', () {
        expect(_luminance(tokens.textPrimary), greaterThan(_luminance(tokens.textSecondary)));
        expect(_luminance(tokens.textSecondary), greaterThan(_luminance(tokens.textMuted)));
        expect(_luminance(tokens.textMuted), greaterThan(_luminance(tokens.textDisabled)));
      });
    });

    group('accent palette', () {
      test('accentGold is #D6B46A', () {
        expect(tokens.accentGold, const Color(0xFFD6B46A));
      });

      test('accentAmber is #F2C76E', () {
        expect(tokens.accentAmber, const Color(0xFFF2C76E));
      });

      test('accentBronze is #9B6B3D', () {
        expect(tokens.accentBronze, const Color(0xFF9B6B3D));
      });

      test('accentIvory is #FFF3D0', () {
        expect(tokens.accentIvory, const Color(0xFFFFF3D0));
      });

      test('accents are in warm family', () {
        final gold = tokens.accentGold;
        expect(_red(gold), greaterThan(_blue(gold)));
        expect(_green(gold), greaterThan(_blue(gold)));
      });
    });

    group('status palette', () {
      test('statusSuccess is #78C6A3', () {
        expect(tokens.statusSuccess, const Color(0xFF78C6A3));
      });

      test('statusWarning is #E2B86B', () {
        expect(tokens.statusWarning, const Color(0xFFE2B86B));
      });

      test('statusError is #E06F6F', () {
        expect(tokens.statusError, const Color(0xFFE06F6F));
      });

      test('statusInfo is #7BA7D9', () {
        expect(tokens.statusInfo, const Color(0xFF7BA7D9));
      });
    });

    group('surface materials', () {
      test('glass material has correct properties', () {
        expect(tokens.glass.background, const Color(0xB8111318));
        expect(tokens.glass.borderColor, const Color(0x14FFF3D0));
        expect(tokens.glass.borderWidth, 1);
        expect(tokens.glass.shadows, isNotNull);
        expect(tokens.glass.shadows!.length, 1);
      });

      test('satin material has correct properties', () {
        expect(tokens.satin.background, const Color(0xFF111318));
        expect(tokens.satin.borderColor, const Color(0x12FFFFFF));
        expect(tokens.satin.borderWidth, 1);
        expect(tokens.satin.shadows, isNotNull);
      });

      test('metal material has gold background', () {
        expect(tokens.metal.background, const Color(0xFFD6B46A));
        expect(tokens.metal.borderColor, const Color(0x47FFF3D0));
        expect(tokens.metal.shadows, isNotNull);
      });

      test('ghost material is near-transparent', () {
        expect(tokens.ghost.background, const Color(0x09FFFFFF));
        expect(tokens.ghost.borderColor, const Color(0x0FFFFFFF));
        expect(tokens.ghost.shadows, isNull);
      });

      test('toDecoration produces valid BoxDecoration', () {
        final deco = tokens.satin.toDecoration();
        expect(deco.color, isNotNull);
        expect(deco.border, isNotNull);
        expect(deco.borderRadius, isNotNull);
        expect(deco.boxShadow, isNotNull);
      });
    });

    group('shadows', () {
      test('shadowSoft has correct parameters', () {
        expect(tokens.shadowSoft.blurRadius, 32);
        expect(tokens.shadowSoft.offset.dy, 12);
      });

      test('shadowLifted has correct parameters', () {
        expect(tokens.shadowLifted.blurRadius, 80);
        expect(tokens.shadowLifted.offset.dy, 24);
      });

      test('shadowGlow uses gold color', () {
        expect(tokens.shadowGlow.color, tokens.accentGold.withValues(alpha: 0.18));
        expect(tokens.shadowGlow.blurRadius, 32);
        expect(tokens.shadowGlow.offset, Offset.zero);
      });
    });

    group('geometry', () {
      test('radius values match Aurum spec', () {
        expect(tokens.radiusSm, 12);
        expect(tokens.radiusMd, 16);
        expect(tokens.radiusLg, 22);
        expect(tokens.radiusXl, 28);
        expect(tokens.radiusPill, 999);
      });

      test('radius values are ordered', () {
        expect(tokens.radiusSm, lessThan(tokens.radiusMd));
        expect(tokens.radiusMd, lessThan(tokens.radiusLg));
        expect(tokens.radiusLg, lessThan(tokens.radiusXl));
      });
    });

    group('spacing', () {
      test('space tokens match spec', () {
        expect(tokens.space1, 4);
        expect(tokens.space2, 8);
        expect(tokens.space3, 12);
        expect(tokens.space4, 16);
        expect(tokens.space5, 24);
        expect(tokens.space6, 32);
        expect(tokens.space7, 48);
        expect(tokens.space8, 64);
      });
    });

    group('typography', () {
      test('displayLarge is 44px / weight 600', () {
        expect(tokens.textTheme.displayLarge?.fontSize, 44);
        expect(tokens.textTheme.displayLarge?.fontWeight, FontWeight.w600);
      });

      test('bodyLarge is 16px / weight 400', () {
        expect(tokens.textTheme.bodyLarge?.fontSize, 16);
        expect(tokens.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
      });

      test('labelSmall has letter spacing', () {
        expect(tokens.textTheme.labelSmall?.fontSize, 11);
        expect(tokens.textTheme.labelSmall?.letterSpacing, 0.3);
      });
    });

    group('motion', () {
      test('easePremium is cubic-bezier(0.22, 1, 0.36, 1)', () {
        expect(tokens.easePremium.a, 0.22);
        expect(tokens.easePremium.b, 1.0);
        expect(tokens.easePremium.c, 0.36);
        expect(tokens.easePremium.d, 1.0);
      });
    });

    group('contrast', () {
      test('textPrimary has excellent contrast on bgDeep', () {
        final contrast = _contrastRatio(tokens.textPrimary, tokens.bgDeep);
        expect(contrast, greaterThan(7.0));
      });

      test('accentGold has sufficient contrast on bgSurface', () {
        final contrast = _contrastRatio(tokens.accentGold, tokens.bgSurface);
        expect(contrast, greaterThan(3.0));
      });
    });
  });
}

double _luminance(Color color) {
  final r = color.r <= 0.03928 ? color.r / 12.92 : pow((color.r + 0.055) / 1.055, 2.4);
  final g = color.g <= 0.03928 ? color.g / 12.92 : pow((color.g + 0.055) / 1.055, 2.4);
  final b = color.b <= 0.03928 ? color.b / 12.92 : pow((color.b + 0.055) / 1.055, 2.4);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color foreground, Color background) {
  final l1 = _luminance(foreground) + 0.05;
  final l2 = _luminance(background) + 0.05;
  return l1 > l2 ? l1 / l2 : l2 / l1;
}

double _red(Color color) => color.r * 255;
double _green(Color color) => color.g * 255;
double _blue(Color color) => color.b * 255;
