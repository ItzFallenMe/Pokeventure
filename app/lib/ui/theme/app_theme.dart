import 'package:flutter/material.dart';

import '../tokens/layout.dart';

/// Material 3, seeded with our brand and tuned so it does not read as a
/// stock Flutter app. Type colours stay semantic (see `TypePalette`).
abstract final class AppTheme {
  static const Color seed = Color(0xFF4F46E5);
  static const Color gold = Color(0xFFF7C948);
  static const Color teal = Color(0xFF14B8A6);
  static const Color shiny = Color(0xFFFFD75E);
  static const Color rose = Color(0xFFF472B6);
  static const Color midnight = Color(0xFF0C0A18);
  static const Color cloud = Color(0xFFF6F4FF);

  /// Selectable accent palettes for the customisation settings.
  static const Map<String, ({String label, Color color})> accents = {
    'indigo': (label: 'Indigo', color: Color(0xFF4F46E5)),
    'teal': (label: 'Teal', color: Color(0xFF0D9488)),
    'rose': (label: 'Rose', color: Color(0xFFDB2777)),
    'amber': (label: 'Amber', color: Color(0xFFD97706)),
    'emerald': (label: 'Emerald', color: Color(0xFF059669)),
    'ice': (label: 'Ice', color: Color(0xFF0284C7)),
  };

  static Color accentColor(String slug) =>
      (accents[slug] ?? accents['indigo']!).color;

  static ThemeData withAccent(Color accent, Brightness brightness) {
    return _build(brightness, seedOverride: accent);
  }

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  /// Builds the game theme around a Material You scheme while keeping the
  /// brand type colours and game semantics intact.
  static ThemeData fromScheme(ColorScheme scheme) {
    return _build(scheme.brightness, override: scheme);
  }

  static ThemeData _build(
    Brightness brightness, {
    ColorScheme? override,
    Color? seedOverride,
  }) {
    final isDark = brightness == Brightness.dark;
    final seeded =
        override ??
        ColorScheme.fromSeed(
          seedColor: seedOverride ?? seed,
          brightness: brightness,
          secondary: teal,
          tertiary: gold,
        );

    final scheme =
        override ??
        seeded.copyWith(
          primary: isDark ? const Color(0xFFC3BAFF) : const Color(0xFF4B3FD6),
          onPrimary: isDark ? const Color(0xFF21136E) : Colors.white,
          primaryContainer: isDark
              ? const Color(0xFF3A2CA6)
              : const Color(0xFFE5E1FF),
          onPrimaryContainer: isDark
              ? const Color(0xFFEDE9FF)
              : const Color(0xFF1B1166),
          secondary: isDark ? const Color(0xFF5FE3D0) : const Color(0xFF0C8F80),
          onSecondary: isDark ? const Color(0xFF003731) : Colors.white,
          secondaryContainer: isDark
              ? const Color(0xFF124C46)
              : const Color(0xFFD3F5EF),
          onSecondaryContainer: isDark
              ? const Color(0xFFC9FBEF)
              : const Color(0xFF003C35),
          tertiary: isDark ? const Color(0xFFFFD166) : const Color(0xFFB77A00),
          onTertiary: isDark ? const Color(0xFF3F2A00) : Colors.white,
          tertiaryContainer: isDark
              ? const Color(0xFF5C4100)
              : const Color(0xFFFFE9B8),
          onTertiaryContainer: isDark
              ? const Color(0xFFFFF0C9)
              : const Color(0xFF3A2600),
          surface: isDark ? midnight : cloud,
          onSurface: isDark ? const Color(0xFFF3F0FF) : const Color(0xFF171326),
          surfaceContainerLowest: isDark
              ? const Color(0xFF08060F)
              : Colors.white,
          surfaceContainerLow: isDark
              ? const Color(0xFF141020)
              : const Color(0xFFFBFAFF),
          surfaceContainer: isDark
              ? const Color(0xFF1A1529)
              : const Color(0xFFF1EEFC),
          surfaceContainerHigh: isDark
              ? const Color(0xFF221C35)
              : const Color(0xFFEAE6F8),
          surfaceContainerHighest: isDark
              ? const Color(0xFF2C2542)
              : const Color(0xFFE2DDF4),
          onSurfaceVariant: isDark
              ? const Color(0xFFBDB4D6)
              : const Color(0xFF5F587A),
          outline: isDark ? const Color(0xFF6F6690) : const Color(0xFF8C85A8),
          outlineVariant: isDark
              ? const Color(0xFF3A3352)
              : const Color(0xFFDDD6EF),
          error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Outfit',
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(
              alpha: isDark ? 0.35 : 0.55,
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF120F1E)
            : const Color(0xFFFDFBFF),
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// The hero gradient used on cards, onboarding and celebration sheets.
  static LinearGradient heroGradient(Brightness brightness) {
    final colors = brightness == Brightness.dark
        ? const [Color(0xFF4B3FD6), Color(0xFF8B2FA8), Color(0xFF12254A)]
        : const [Color(0xFF4F46E5), Color(0xFF9A3FB0), Color(0xFF1B6FA8)];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  /// A soft type-tinted wash for section backgrounds.
  static List<Color> tintWash(Color tint, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return [
        Color.alphaBlend(tint.withValues(alpha: 0.22), midnight),
        midnight,
      ];
    }
    return [Color.alphaBlend(tint.withValues(alpha: 0.18), cloud), cloud];
  }

  /// A display-ish scale on top of the platform text theme.
  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        height: 1.05,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.08,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.12,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.4),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
