import 'package:flutter/material.dart';

Color sectionAccent(int index, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (index) {
    0 => dark ? const Color(0xFF74DDAA) : const Color(0xFF176B4D),
    1 => dark ? const Color(0xFFAAB7FF) : const Color(0xFF4F5FAE),
    2 || 3 => dark ? const Color(0xFF8BCBFF) : const Color(0xFF2879B9),
    4 => dark ? const Color(0xFFFFC982) : const Color(0xFF9A6227),
    _ => dark ? const Color(0xFFB7C3CC) : const Color(0xFF5B6670),
  };
}

Color _sectionBackground(int index, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  if (index == 0) {
    return dark ? const Color(0xFF07120D) : const Color(0xFFF3F8F5);
  }
  if (index == 1) {
    return dark ? const Color(0xFF0E111A) : const Color(0xFFF6F6FA);
  }
  if (index == 2 || index == 3) {
    return dark ? const Color(0xFF0A1218) : const Color(0xFFF4F7F9);
  }
  if (index == 4) {
    return dark ? const Color(0xFF15110D) : const Color(0xFFF8F6F2);
  }
  return dark ? const Color(0xFF111417) : const Color(0xFFF6F7F8);
}

ThemeData sectionTheme(BuildContext context, int index) {
  final base = Theme.of(context);
  final scheme = base.colorScheme;
  final accent = sectionAccent(index, base.brightness);
  final container = Color.alphaBlend(
    accent.withValues(alpha: base.brightness == Brightness.dark ? 0.20 : 0.10),
    scheme.surface,
  );
  final onAccent = accent.computeLuminance() > 0.54
      ? const Color(0xFF11171B)
      : Colors.white;
  final sectionScheme = scheme.copyWith(
    primary: accent,
    onPrimary: onAccent,
    primaryContainer: container,
    onPrimaryContainer: scheme.onSurface,
    secondary: accent,
  );

  return base.copyWith(
    colorScheme: sectionScheme,
    scaffoldBackgroundColor: _sectionBackground(index, base.brightness),
    iconTheme: base.iconTheme.copyWith(color: scheme.onSurfaceVariant),
    primaryIconTheme: IconThemeData(color: accent),
    listTileTheme: base.listTileTheme.copyWith(iconColor: accent),
    progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
      color: accent,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: scheme.surfaceContainerHighest,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      prefixIconColor: accent,
      floatingLabelStyle: TextStyle(
        color: accent,
        fontWeight: FontWeight.w800,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: accent, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: onAccent,
        backgroundColor: accent,
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
        foregroundColor: accent,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
