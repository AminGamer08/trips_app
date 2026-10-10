import 'package:flutter/material.dart';
import '../models/journal.dart';

abstract final class Space {
  static const double xs = 4,
      sm = 8,
      md = 12,
      lg = 16,
      xl = 24,
      xxl = 32,
      xxxl = 48;
  static const page = EdgeInsets.all(xl);
  static const radius = BorderRadius.all(Radius.circular(24));
  static const smallRadius = BorderRadius.all(Radius.circular(16));
  static const duration = Duration(milliseconds: 280);
}

@immutable
class JournalPalette extends ThemeExtension<JournalPalette> {
  const JournalPalette({
    required this.categoryColors,
    required this.onPhoto,
    required this.scrim,
  });
  final List<Color> categoryColors;
  final Color onPhoto, scrim;
  @override
  JournalPalette copyWith({
    List<Color>? categoryColors,
    Color? onPhoto,
    Color? scrim,
  }) => JournalPalette(
    categoryColors: categoryColors ?? this.categoryColors,
    onPhoto: onPhoto ?? this.onPhoto,
    scrim: scrim ?? this.scrim,
  );
  @override
  JournalPalette lerp(covariant JournalPalette? other, double t) =>
      other == null
      ? this
      : JournalPalette(
          categoryColors: List.generate(
            categoryColors.length,
            (i) => Color.lerp(categoryColors[i], other.categoryColors[i], t)!,
          ),
          onPhoto: Color.lerp(onPhoto, other.onPhoto, t)!,
          scrim: Color.lerp(scrim, other.scrim, t)!,
        );
}

abstract final class JournalTheme {
  static const seeds = <String, int>{
    'Salbei': 0xff547466,
    'Ozean': 0xff47728b,
    'Terrakotta': 0xffa7674f,
    'Lavendel': 0xff786795,
  };
  static ThemeData build(
    Brightness brightness,
    int seed, {
    ColorScheme? dynamicScheme,
  }) {
    final dark = brightness == Brightness.dark;
    final scheme =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: Color(seed),
          brightness: brightness,
        ).copyWith(
          surface: dark ? const Color(0xff121713) : const Color(0xfff8f9f5),
          surfaceContainerLowest: dark
              ? const Color(0xff101410)
              : const Color(0xffffffff),
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Manrope',
      brightness: brightness,
    );
    final text = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontSize: 36,
        height: 1.18,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 30,
        height: 1.22,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 26,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: -.8,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.65),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.6,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [
        JournalPalette(
          categoryColors: [
            scheme.tertiary,
            scheme.secondary,
            scheme.primary,
            HSLColor.fromColor(scheme.primary)
                .withHue((HSLColor.fromColor(scheme.primary).hue + 45) % 360)
                .toColor(),
            HSLColor.fromColor(scheme.tertiary)
                .withHue((HSLColor.fromColor(scheme.tertiary).hue + 55) % 360)
                .toColor(),
            scheme.outline,
          ],
          onPhoto: const Color(0xffffffff),
          scrim: const Color(0xff0a1913),
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: Space.radius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .45)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: text.labelLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: Space.smallRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.all(18),
        border: const OutlineInputBorder(borderRadius: Space.smallRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: Space.smallRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Space.smallRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: Space.smallRadius),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .5),
        thickness: 1,
        space: 32,
      ),
    );
  }
}

extension CategoryPresentation on PlaceCategory {
  String get label => switch (this) {
    PlaceCategory.food => 'Food',
    PlaceCategory.hotel => 'Hotel',
    PlaceCategory.nature => 'Nature',
    PlaceCategory.sightseeing => 'Sightseeing',
    PlaceCategory.event => 'Event',
    PlaceCategory.other => 'Other',
  };
  IconData get icon => switch (this) {
    PlaceCategory.food => Icons.restaurant_rounded,
    PlaceCategory.hotel => Icons.bed_rounded,
    PlaceCategory.nature => Icons.park_rounded,
    PlaceCategory.sightseeing => Icons.account_balance_rounded,
    PlaceCategory.event => Icons.celebration_rounded,
    PlaceCategory.other => Icons.location_on_rounded,
  };
  Color color(BuildContext context) =>
      Theme.of(context).extension<JournalPalette>()!.categoryColors[index];
}
