import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Aurum-styled card widget with selectable surface material.
///
/// Defaults to glass material for a premium frosted look.
///
/// ```dart
/// AurumCard(
///   material: SurfaceMaterial.glass(),
///   child: Text('Hello'),
/// )
/// ```
class AurumCard extends StatelessWidget {
  final Widget? child;
  final SurfaceMaterial? material;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Clip clipBehavior;

  const AurumCard({
    super.key,
    this.child,
    this.material,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);
    final effectiveMaterial = material ?? tokens.glass;
    final effectiveRadius = borderRadius ?? tokens.radiusLg;

    final baseDecoration = effectiveMaterial.toDecoration();
    final decoration = BoxDecoration(
      color: baseDecoration.color,
      border: baseDecoration.border,
      borderRadius: BorderRadius.circular(effectiveRadius),
      boxShadow: baseDecoration.boxShadow,
    );

    Widget content = Container(
      padding: padding ?? EdgeInsets.all(tokens.space4),
      decoration: decoration,
      clipBehavior: clipBehavior,
      child: child,
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
