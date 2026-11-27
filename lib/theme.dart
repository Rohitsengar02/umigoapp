import 'package:material_ui/material_ui.dart';

import 'widgets/motion.dart';

/// Umigo brand palette from the client (24 Nov 2026): rose pink, warm coral peach,
/// muted plum and deep violet purple, on white (light) or near-black plum (dark).
/// Brand colours are constant; neutrals are getters that follow [UC.dark].
class UC {
  static bool dark = false;
  static T _m<T>(T light, T night) => dark ? night : light;

  // brand (same in both themes)
  static const primary = Color(0xFFD6456B); // rose pink: actions, LIVE
  static const accent = Color(0xFFF4946C); // warm coral peach: coins, gifts
  static const deep = Color(0xFF963D7D); // muted plum: chips, links, overlays
  static const violet = Color(0xFF581D64); // deep violet purple: strong surfaces
  static const gold = Color(0xFFFFC46B);
  static const green = Color(0xFF12B76A);
  static const red = Color(0xFFF04438);

  /// Filled "dark" controls (selected chips, Continue buttons, tab highlight).
  static const pill = violet;

  /// Always-dark base for camera screens and photo overlays.
  static const night = Color(0xFF1B0C1F);

  // neutrals that follow the theme
  static Color get ink => _m(const Color(0xFF2A1430), const Color(0xFFF7EEF8));
  static Color get muted => _m(const Color(0xFF7A6580), const Color(0xFFB9A6BE));
  static Color get line => _m(const Color(0xFFF2E3EB), const Color(0xFF34223A));
  static Color get surface => _m(const Color(0xFFFBF3F6), const Color(0xFF27182C));
  static Color get card => _m(Colors.white, const Color(0xFF1F1224));
  static Color get glassStrong => _m(const Color(0xE6FFFFFF), const Color(0xE6221426));
  static Color get glass => _m(const Color(0xB8FFFFFF), const Color(0xB0251628));
  static Color get soft => _m(const Color(0xFFFDE8EE), const Color(0xFF3B1627));
  static Color get accentSoft => _m(const Color(0xFFFFEFE7), const Color(0xFF3A2017));
  static Color get accentText => _m(const Color(0xFFA5482A), const Color(0xFFFFB79A));
  static Color get greenText => _m(const Color(0xFF067647), const Color(0xFF5BE3A0));
  static Color get greenSoft => _m(const Color(0xFFE7F8EF), const Color(0xFF123222));

  // soft backdrop: near-white (or near-black) base with brand-tinted light behind it
  static Color get bg => _m(const Color(0xFFFDF8FA), const Color(0xFF120914));
  static Color get lilac => _m(const Color(0xFFEFDDF3), const Color(0xFF3A1546));
  static Color get blush => _m(const Color(0xFFFFDDE6), const Color(0xFF4A1430));
  static Color get peach => _m(const Color(0xFFFFE5D9), const Color(0xFF3E1E14));
  static Color get mint => _m(const Color(0xFFE3F6EC), const Color(0xFF10261C));

  static Color inkA(double o) => night.withValues(alpha: o);

  static const coinGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gold, accent]);
  static const brandGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primary, accent]);
  static const violetGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [deep, violet]);
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
    brightness: UC.dark ? Brightness.dark : Brightness.light,
    fontFamily: kFont,
    colorScheme: ColorScheme.fromSeed(
      seedColor: UC.primary,
      brightness: UC.dark ? Brightness.dark : Brightness.light,
      primary: UC.primary,
      surface: UC.card,
      onSurface: UC.ink,
    ),
    scaffoldBackgroundColor: UC.bg,
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
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: UC.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
    dividerTheme: DividerThemeData(color: UC.line, thickness: 1),
    listTileTheme: ListTileThemeData(textColor: UC.ink, iconColor: UC.ink),
    drawerTheme: DrawerThemeData(backgroundColor: UC.bg),
    dialogTheme: DialogThemeData(backgroundColor: UC.card),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: UC.pill,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: ts(13.5, c: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
    ),
  );
}
