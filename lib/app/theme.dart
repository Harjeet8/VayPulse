import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

const phytoGreen = Color(0xFF1D684D);
const phytoLeaf = Color(0xFF4C8F6D);
const phytoWater = Color(0xFF397F96);
const phytoLavender = Color(0xFF727AA3);
const phytoSun = Color(0xFFAE7734);
const phytoMint = Color(0xFFE3F0E7);
const phytoAmber = Color(0xFFC88427);
const phytoTerracotta = Color(0xFFB95F43);
const phytoInk = Color(0xFF173126);
const phytoCream = Color(0xFFF7F5EF);

ThemeData buildTheme(Brightness brightness, String languageCode) {
  final dark = brightness == Brightness.dark;
  final seeded = ColorScheme.fromSeed(
    seedColor: phytoGreen,
    brightness: brightness,
  );
  final scheme = seeded.copyWith(
    primary: dark ? const Color(0xFF83D9AD) : phytoGreen,
    onPrimary: dark ? const Color(0xFF003823) : Colors.white,
    primaryContainer: dark ? const Color(0xFF214B39) : const Color(0xFFDCEEE3),
    onPrimaryContainer:
        dark ? const Color(0xFFC9F8DE) : const Color(0xFF073C29),
    secondary: dark ? const Color(0xFF9BCFBA) : const Color(0xFF4C765F),
    onSecondary: dark ? const Color(0xFF043831) : Colors.white,
    secondaryContainer:
        dark ? const Color(0xFF26483A) : const Color(0xFFE3ECE5),
    onSecondaryContainer:
        dark ? const Color(0xFFC9F5EA) : const Color(0xFF123D35),
    tertiary: dark ? const Color(0xFFF0C27B) : const Color(0xFF8A5A18),
    onTertiary: dark ? const Color(0xFF462A00) : Colors.white,
    tertiaryContainer: dark ? const Color(0xFF5B3A08) : const Color(0xFFFFDEA5),
    onTertiaryContainer:
        dark ? const Color(0xFFFFE1AC) : const Color(0xFF3A2504),
    error: dark ? const Color(0xFFFFB4A5) : const Color(0xFFBA4A35),
    onError: dark ? const Color(0xFF5A190E) : Colors.white,
    errorContainer: dark ? const Color(0xFF6D271B) : const Color(0xFFFFDAD2),
    onErrorContainer: dark ? const Color(0xFFFFDAD3) : const Color(0xFF421008),
    surface: dark ? const Color(0xFF14231B) : const Color(0xFFFFFDF9),
    onSurface: dark ? const Color(0xFFE7EEE9) : phytoInk,
    surfaceContainerLowest: dark ? const Color(0xFF0A120E) : Colors.white,
    surfaceContainerLow:
        dark ? const Color(0xFF14231B) : const Color(0xFFFAF8F3),
    surfaceContainer: dark ? const Color(0xFF182920) : const Color(0xFFF2F3ED),
    surfaceContainerHigh:
        dark ? const Color(0xFF203229) : const Color(0xFFEAEEE8),
    surfaceContainerHighest:
        dark ? const Color(0xFF293B31) : const Color(0xFFE2E9E2),
    onSurfaceVariant: dark ? const Color(0xFFBACBC0) : const Color(0xFF56675E),
    outline: dark ? const Color(0xFF718B7C) : const Color(0xFF77867D),
    outlineVariant: dark ? const Color(0xFF334B3D) : const Color(0xFFDCE3DC),
    shadow: dark ? const Color(0xFF000000) : const Color(0xFF143426),
    inverseSurface: dark ? const Color(0xFFE1EEE6) : const Color(0xFF213B2E),
    onInverseSurface: dark ? const Color(0xFF153126) : const Color(0xFFEAF4EE),
    inversePrimary: dark ? const Color(0xFF176B4D) : const Color(0xFF7BDBAB),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: languageCode == 'ta' ? 'NotoSansTamil' : null,
  );
  final cardColor = dark ? const Color(0xFF16271E) : const Color(0xFFFFFDF9);
  final typography = base.textTheme
      .copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.7,
          height: 1.06,
        ),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.65,
          height: 1.13,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.45,
          height: 1.18,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.35,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.48),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.44),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
        ),
      )
      .apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      );

  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF0B1510) : phytoCream,
    visualDensity: VisualDensity.standard,
    focusColor: scheme.primary.withValues(alpha: 0.18),
    hoverColor: scheme.primary.withValues(alpha: dark ? 0.1 : 0.06),
    canvasColor: scheme.surface,
    shadowColor: scheme.shadow,
    splashColor: scheme.primary.withValues(alpha: dark ? 0.16 : 0.1),
    highlightColor: scheme.primary.withValues(alpha: dark ? 0.1 : 0.06),
    textTheme: typography,
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    primaryIconTheme: IconThemeData(color: scheme.primary),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF0B1510) : phytoCream,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: scheme.onSurface),
      toolbarHeight: 68,
      titleTextStyle: typography.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: scheme.shadow.withValues(alpha: dark ? 0.24 : 0.08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF182A21) : const Color(0xFFF7FBF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
      ),
      prefixIconColor: scheme.primary,
      suffixIconColor: scheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: scheme.onPrimary,
        backgroundColor: scheme.primary,
        disabledBackgroundColor: scheme.surfaceContainerHighest,
        disabledForegroundColor: scheme.onSurfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: typography.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        foregroundColor: scheme.primary,
        side: BorderSide(color: dark ? scheme.outline : scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: typography.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: typography.labelLarge,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: dark ? const Color(0xFF192C22) : const Color(0xFFF2F8F4),
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: TextStyle(
        color: scheme.onPrimaryContainer,
        fontWeight: FontWeight.w600,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : dark
                  ? const Color(0xFF111F18)
                  : Colors.white,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outlineVariant,
          ),
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurfaceVariant,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.outline,
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.16),
      valueIndicatorColor: scheme.primaryContainer,
      valueIndicatorTextStyle: TextStyle(
        color: scheme.onPrimaryContainer,
        fontWeight: FontWeight.w700,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      textColor: scheme.onSurface,
      subtitleTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w700,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? const Color(0xFF111F18) : const Color(0xFFFFFDF9),
      indicatorColor: scheme.primaryContainer,
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: scheme.surface,
      modalBarrierColor: Colors.black.withValues(alpha: 0.68),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? const Color(0xFF172A20) : Colors.white,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: scheme.onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: TextStyle(color: scheme.onInverseSurface),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: scheme.surfaceContainerHighest,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        scheme.primary.withValues(alpha: dark ? 0.55 : 0.42),
      ),
      radius: const Radius.circular(99),
    ),
  );
}
