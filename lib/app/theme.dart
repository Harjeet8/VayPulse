import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

const phytoGreen = Color(0xFF176B4D);
const phytoLeaf = Color(0xFF31A36F);
const phytoMint = Color(0xFFDDF4E8);
const phytoAmber = Color(0xFFF3A83B);
const phytoTerracotta = Color(0xFFD9684B);
const phytoInk = Color(0xFF14251E);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final seeded = ColorScheme.fromSeed(
    seedColor: phytoGreen,
    brightness: brightness,
  );
  final scheme = seeded.copyWith(
    primary: dark ? const Color(0xFF74DDAA) : phytoGreen,
    onPrimary: dark ? const Color(0xFF003823) : Colors.white,
    primaryContainer: dark ? const Color(0xFF174D37) : const Color(0xFFC9F3DD),
    onPrimaryContainer:
        dark ? const Color(0xFFC9F8DE) : const Color(0xFF073C29),
    secondary: dark ? const Color(0xFF8EDBC9) : const Color(0xFF276C60),
    onSecondary: dark ? const Color(0xFF043831) : Colors.white,
    secondaryContainer:
        dark ? const Color(0xFF17483F) : const Color(0xFFC0EEE3),
    onSecondaryContainer:
        dark ? const Color(0xFFC9F5EA) : const Color(0xFF123D35),
    tertiary: dark ? const Color(0xFFFFC66D) : const Color(0xFF8B5A08),
    onTertiary: dark ? const Color(0xFF462A00) : Colors.white,
    tertiaryContainer: dark ? const Color(0xFF5B3A08) : const Color(0xFFFFDEA5),
    onTertiaryContainer:
        dark ? const Color(0xFFFFE1AC) : const Color(0xFF3A2504),
    error: dark ? const Color(0xFFFFB4A5) : const Color(0xFFBA4A35),
    onError: dark ? const Color(0xFF5A190E) : Colors.white,
    errorContainer: dark ? const Color(0xFF6D271B) : const Color(0xFFFFDAD2),
    onErrorContainer: dark ? const Color(0xFFFFDAD3) : const Color(0xFF421008),
    surface: dark ? const Color(0xFF101F17) : const Color(0xFFF8FCF9),
    onSurface: dark ? const Color(0xFFE7F2EB) : phytoInk,
    surfaceContainerLowest: dark ? const Color(0xFF07110D) : Colors.white,
    surfaceContainerLow:
        dark ? const Color(0xFF102018) : const Color(0xFFF4F9F6),
    surfaceContainer: dark ? const Color(0xFF15271D) : const Color(0xFFEEF6F1),
    surfaceContainerHigh:
        dark ? const Color(0xFF192A21) : const Color(0xFFE8F1EB),
    surfaceContainerHighest:
        dark ? const Color(0xFF22362B) : const Color(0xFFDFEBE4),
    onSurfaceVariant: dark ? const Color(0xFFBDD0C4) : const Color(0xFF4C6256),
    outline: dark ? const Color(0xFF6F8D7C) : const Color(0xFF71877B),
    outlineVariant: dark ? const Color(0xFF2B4638) : const Color(0xFFD4E2D9),
    shadow: dark ? const Color(0xFF000000) : const Color(0xFF143426),
    inverseSurface: dark ? const Color(0xFFE1EEE6) : const Color(0xFF213B2E),
    onInverseSurface: dark ? const Color(0xFF153126) : const Color(0xFFEAF4EE),
    inversePrimary: dark ? const Color(0xFF176B4D) : const Color(0xFF7BDBAB),
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );
  final cardColor = dark ? const Color(0xFF14271D) : const Color(0xFFFFFFFF);
  final subtleBorder = dark ? const Color(0xFF294537) : const Color(0xFFE0ECE5);

  return base.copyWith(
    scaffoldBackgroundColor:
        dark ? const Color(0xFF07120D) : const Color(0xFFF3F8F5),
    visualDensity: VisualDensity.standard,
    focusColor: scheme.primary.withValues(alpha: 0.18),
    hoverColor: scheme.primary.withValues(alpha: dark ? 0.1 : 0.06),
    canvasColor: scheme.surface,
    shadowColor: scheme.shadow,
    splashColor: scheme.primary.withValues(alpha: dark ? 0.16 : 0.1),
    highlightColor: scheme.primary.withValues(alpha: dark ? 0.1 : 0.06),
    textTheme: base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    primaryIconTheme: IconThemeData(color: scheme.primary),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
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
      backgroundColor: dark
          ? const Color(0xFF08130E).withValues(alpha: 0.96)
          : Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: scheme.onSurface),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: scheme.shadow.withValues(alpha: dark ? 0.32 : 0.09),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: subtleBorder),
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
        fontWeight: FontWeight.w800,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
      ),
      prefixIconColor: scheme.primary,
      suffixIconColor: scheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        foregroundColor: scheme.primary,
        side: BorderSide(color: dark ? scheme.outline : scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: dark ? const Color(0xFF192C22) : const Color(0xFFF2F8F4),
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: TextStyle(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: TextStyle(
        color: scheme.onPrimaryContainer,
        fontWeight: FontWeight.w800,
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
          TextStyle(fontWeight: FontWeight.w800),
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
        fontWeight: FontWeight.w900,
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
              ? FontWeight.w900
              : FontWeight.w700,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? const Color(0xFF0D1913) : const Color(0xFFFFFFFF),
      indicatorColor: scheme.primaryContainer,
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w900,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: scheme.surfaceContainerLow,
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
        fontWeight: FontWeight.w900,
      ),
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
