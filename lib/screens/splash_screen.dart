import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/mascot.dart';
import '../widgets/ui.dart';
import 'onboarding_screen.dart';

/// Brand moment: Umi pops in, the wordmark rises, then we go to the app or the intro.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1650), () {
      if (!mounted) return;
      // Only redirect when the splash is on top (deep links like /#/golive push over it).
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (AppState.I.loggedIn) {
        Navigator.pushReplacementNamed(context, '/app');
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 650),
            pageBuilder: (_, _, _) => const OnboardingScreen(),
            transitionsBuilder: (_, a, _, child) => FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween(begin: 1.04, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rise = CurvedAnimation(
      parent: c,
      curve: const Interval(.35, .85, curve: Curves.easeOutCubic),
    );
    return Scaffold(
      body: AuroraBg(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: c,
                  curve: const Interval(0, .7, curve: Curves.elasticOut),
                ),
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .7),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .18), blurRadius: 50, offset: const Offset(0, 20))],
                  ),
                  alignment: Alignment.center,
                  child: const Mascot(mood: 'hello', size: 150),
                ),
              ),
              const SizedBox(height: 26),
              FadeTransition(
                opacity: rise,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .5), end: Offset.zero).animate(rise),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('umigo', style: ds(58, c: UC.ink, ls: -2.6)),
                          Container(
                            width: 13,
                            height: 13,
                            margin: const EdgeInsets.only(left: 3),
                            decoration: const BoxDecoration(gradient: UC.brandGradient, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const HeroTitle('Go live. Get ', 'loved.', size: 20, color: UC.deep),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
