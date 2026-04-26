import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Aurum-themed Material 3 theme for OpenClaw.
///
/// Dark-first with warm gold accents. Both light and dark
/// themes share the deep palette; light mode is achieved
/// by elevating surface colors slightly.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final tokens = DesignTokens.forBrightness(brightness);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.accentGold,
      onPrimary: tokens.textInverse,
      secondary: tokens.accentBronze,
      onSecondary: tokens.textInverse,
      surface: tokens.bgSurface,
      onSurface: tokens.textPrimary,
      surfaceContainerHighest: tokens.bgElevated,
      error: tokens.statusError,
      onError: tokens.textPrimary,
      outline: tokens.textMuted.withValues(alpha: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.bgDeep,
      canvasColor: tokens.bgDeep,
      fontFamily: 'Inter',
      // App bar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: tokens.bgDeep,
        foregroundColor: tokens.textPrimary,
        titleTextStyle: tokens.textTheme.titleLarge,
        toolbarHeight: 72,
      ),
      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.bgSurface,
        modalBackgroundColor: tokens.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusXl)),
        ),
      ),
      // Cards — use satin material
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.satin.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: BorderSide(
            color: tokens.satin.borderColor ?? Colors.transparent,
            width: tokens.satin.borderWidth ?? 0,
          ),
        ),
        margin: EdgeInsets.all(tokens.space2),
      ),
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.bgElevated,
        hintStyle: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.textMuted.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.textMuted.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.accentGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(color: tokens.statusError),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.space4,
          vertical: tokens.space3,
        ),
      ),
      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accentGold,
          foregroundColor: tokens.textInverse,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusMd)),
          padding: EdgeInsets.symmetric(horizontal: tokens.space5, vertical: tokens.space3),
          textStyle: tokens.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          side: BorderSide(color: tokens.textMuted.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusMd)),
          padding: EdgeInsets.symmetric(horizontal: tokens.space5, vertical: tokens.space3),
          textStyle: tokens.textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accentGold,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusSm)),
          padding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: tokens.space2),
          textStyle: tokens.textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusSm)),
        ),
      ),
      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: tokens.accentGold,
        foregroundColor: tokens.textInverse,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusLg)),
        extendedPadding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space3),
      ),
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: tokens.ghost.background,
        side: BorderSide(
          color: tokens.ghost.borderColor ?? Colors.transparent,
          width: tokens.ghost.borderWidth ?? 0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusPill)),
        padding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: tokens.space1),
        labelStyle: tokens.textTheme.labelMedium,
        iconTheme: IconThemeData(color: tokens.textSecondary, size: 16),
      ),
      // Dividers
      dividerTheme: DividerThemeData(
        color: tokens.textMuted.withValues(alpha: 0.15),
        thickness: 1,
        space: tokens.space4,
      ),
      // Snackbars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: BorderSide(color: tokens.textMuted.withValues(alpha: 0.1)),
        ),
        contentTextStyle: tokens.textTheme.bodyMedium,
        elevation: 0,
        insetPadding: EdgeInsets.all(tokens.space4),
      ),
      // Bottom nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: tokens.bgDeep,
        selectedItemColor: tokens.accentGold,
        unselectedItemColor: tokens.textMuted,
        selectedLabelStyle: tokens.textTheme.labelSmall,
        unselectedLabelStyle: tokens.textTheme.labelSmall,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusXl)),
        elevation: 0,
      ),
      // Lists
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: tokens.bgElevated,
        contentPadding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusMd)),
        titleTextStyle: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
        subtitleTextStyle: tokens.textTheme.bodySmall,
        leadingAndTrailingTextStyle: tokens.textTheme.labelMedium,
      ),
      // Progress
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accentGold,
        linearTrackColor: tokens.textMuted.withValues(alpha: 0.2),
        circularTrackColor: tokens.textMuted.withValues(alpha: 0.2),
      ),
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.accentGold;
          return tokens.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.accentGold.withValues(alpha: 0.3);
          return tokens.textMuted.withValues(alpha: 0.2);
        }),
      ),
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.accentGold,
        inactiveTrackColor: tokens.textMuted.withValues(alpha: 0.2),
        thumbColor: tokens.accentGold,
        overlayColor: tokens.accentGold.withValues(alpha: 0.1),
      ),
      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.bgElevated,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          border: Border.all(color: tokens.textMuted.withValues(alpha: 0.2)),
        ),
        textStyle: tokens.textTheme.labelMedium?.copyWith(color: tokens.textPrimary),
        padding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: tokens.space2),
      ),
    );
  }
}
