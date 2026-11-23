import 'package:material_ui/material_ui.dart';

import 'widgets/motion.dart';

/// Umigo "Rose Plum" palette (palette A from the approved design board).
class UC {
  static const primary = Color(0xFFCF3F6C); // rose pink: actions, LIVE
  static const soft = Color(0xFFFDEAF0);
  static const deep = Color(0xFF6B4A6E); // muted plum: chips, links, overlays
  static const accent = Color(0xFFFF9F80); // coral peach: coins, gifts
  static const accentSoft = Color(0xFFFFF0EA);
  static const accentText = Color(0xFFA84A2C);
  static const ink = Color(0xFF2E1C30);
  static const muted = Color(0xFF74647A);
  static const line = Color(0xFFF1E4EA);
  static const surface = Color(0xFFFBF4F6);
  static const gold = Color(0xFFFFC46B);
  static const green = Color(0xFF12B76A);
  static const greenText = Color(0xFF067647);
  static const greenSoft = Color(0xFFE7F8EF);
  static const red = Color(0xFFF04438);

  static Color inkA(double o) => ink.withValues(alpha: o);

  static const coinGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gold, accent]);
  static const brandGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primary, accent]);
}

const kFont = 'Jakarta';

TextStyle ts(double size, {FontWeight w = FontWeight.w700, Color? c, double? ls, double? h}) =>
    TextStyle(fontFamily: kFont, fontSize: size, fontWeight: w, color: c, letterSpacing: ls, height: h);

const kDisplay = 'Display'; // Bricolage Grotesque: headings and big numbers

TextStyle ds(double size, {FontWeight w = FontWeight.w800, Color? c, double? ls, double? h}) =>
    TextStyle(fontFamily: kDisplay, fontSize: size, fontWeight: w, color: c, letterSpacing: ls ?? -size * .03, height: h ?? 1.05);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: kFont,
    colorScheme: ColorScheme.fromSeed(seedColor: UC.primary, primary: UC.primary, surface: Colors.white),
    scaffoldBackgroundColor: Colors.white,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: UmiPageTransitions(),
        TargetPlatform.iOS: UmiPageTransitions(),
        TargetPlatform.linux: UmiPageTransitions(),
        TargetPlatform.macOS: UmiPageTransitions(),
        TargetPlatform.windows: UmiPageTransitions(),
        TargetPlatform.fuchsia: UmiPageTransitions(),
      },
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: UC.ink, displayColor: UC.ink, fontFamily: kFont),
    inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, isDense: true),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: UC.ink,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: ts(13.5, c: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
