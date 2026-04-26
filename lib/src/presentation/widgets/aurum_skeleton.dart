import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/design_tokens.dart';

/// Basic shimmer skeleton container.
class AurumSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AurumSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    return Shimmer.fromColors(
      baseColor: tokens.bgElevated,
      highlightColor: tokens.bgSurface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: tokens.bgElevated,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for a chat message bubble.
class AurumMessageSkeleton extends StatelessWidget {
  final bool isUser;
  const AurumMessageSkeleton({super.key, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.space4,
          vertical: tokens.space2,
        ),
        child: AurumSkeleton(
          width: isUser ? 200 : 240,
          height: 48,
          borderRadius: tokens.radiusMd,
        ),
      ),
    );
  }
}

/// Shimmer skeleton for a session list item.
class AurumSessionSkeleton extends StatelessWidget {
  const AurumSessionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space4,
        vertical: tokens.space2,
      ),
      child: Row(
        children: [
          AurumSkeleton(width: 48, height: 48, borderRadius: tokens.radiusPill),
          SizedBox(width: tokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AurumSkeleton(width: 140, height: 16, borderRadius: tokens.radiusSm),
                SizedBox(height: tokens.space2),
                AurumSkeleton(width: 200, height: 12, borderRadius: tokens.radiusSm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
