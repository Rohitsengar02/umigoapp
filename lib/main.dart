import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'screens/buy_coins_screen.dart';
import 'screens/go_live_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/register_screen.dart';
import 'screens/server_settings_screen.dart';
import 'screens/shell.dart';
import 'screens/splash_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/withdraw_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.I.load();
  UC.dark = AppState.I.darkMode;
  _statusBar();
  runApp(const UmigoApp());
}

void _statusBar() =>
    SystemChrome.setSystemUIOverlayStyle((UC.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent));

/// Rebuilds the whole tree when the light/dark choice changes, keeping every
/// open screen and its state (colours are read from [UC] at build time).
class UmigoApp extends StatefulWidget {
  const UmigoApp({super.key});
  @override
  State<UmigoApp> createState() => _UmigoAppState();
}

class _UmigoAppState extends State<UmigoApp> {
  @override
  void initState() {
    super.initState();
    AppState.I.addListener(_onState);
  }

  @override
  void dispose() {
    AppState.I.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (AppState.I.darkMode == UC.dark) return;
    UC.dark = AppState.I.darkMode;
    _statusBar();
    setState(() {});
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Umigo',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Let a mouse drag scroll lists and swipe pages too (web preview on a laptop).
      scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      // On a wide screen (desktop browser) show the app inside a phone-sized frame.
      builder: (context, child) => _PhoneFrame(child: child!),
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/app': (_) => const Shell(),
        '/golive': (_) => const GoLiveScreen(),
        '/coins': (_) => const BuyCoinsScreen(),
        '/transactions': (_) => const TransactionsScreen(),
        '/withdraw': (_) => const WithdrawScreen(),
        '/inbox': (_) => const ActivityScreen(),
        '/messages': (_) => const MessagesScreen(asTab: false),
        '/categories': (_) => const CategoriesScreen(),
        '/server': (_) => const ServerSettingsScreen(),
      },
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  final Widget child;
  const _PhoneFrame({required this.child});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) return child;
    final h = (size.height - 40).clamp(500.0, 860.0);
    final w = h * 390 / 844;
    return ColoredBox(
      color: const Color(0xFFEFE6EE),
      child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [BoxShadow(color: UC.inkA(.18), blurRadius: 40, offset: const Offset(0, 16))],
          ),
          clipBehavior: Clip.antiAlias,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: Size(w, h), padding: const EdgeInsets.only(top: 20, bottom: 10)),
            child: child,
          ),
        ),
      ),
    );
  }
}
