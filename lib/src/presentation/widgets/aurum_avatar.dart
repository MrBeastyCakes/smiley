import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Aurum-styled avatar for agents and users.
///
/// Displays either a network image or initials. A gold ring
/// appears when [isOnline] is true.
class AurumAvatar extends StatelessWidget {
  final String? initials;
  final String? imageUrl;
  final AurumAvatarSize size;
  final bool isOnline;

  const AurumAvatar({
    super.key,
    this.initials,
    this.imageUrl,
    this.size = AurumAvatarSize.md,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);
    final dimension = size.dimension;
    final fontSize = dimension * 0.4;
    final ringWidth = size == AurumAvatarSize.sm ? 2.0 : 3.0;

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(
          imageUrl!,
          width: dimension,
          height: dimension,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(tokens, fontSize),
        ),
      );
    } else {
      avatar = _fallback(tokens, fontSize);
    }

    if (isOnline) {
      avatar = Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: tokens.accentGold,
            width: ringWidth,
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _fallback(DesignTokens tokens, double fontSize) {
    final dimension = size.dimension;
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: tokens.bgElevated,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        (initials != null && initials!.isNotEmpty) ? initials! : '?',
        style: tokens.textTheme.labelLarge?.copyWith(
          fontSize: fontSize,
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}

enum AurumAvatarSize {
  sm(32),
  md(48),
  lg(64);

  final double dimension;
  const AurumAvatarSize(this.dimension);
}
