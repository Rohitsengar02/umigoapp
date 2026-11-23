import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/mascot.dart';

/// Splash + welcome: the brand moment, then "Create account" / "I already have an account".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  bool showActions = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      // Only redirect when the splash is on top (deep links like /#/golive push over it).
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      if (AppState.I.loggedIn) {
        Navigator.pushReplacementNamed(context, '/app');
      } else {
        setState(() => showActions = true);
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
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFFDEAF0), Color(0xFFFFE6DC)]),
        ),
        child: Stack(
          children: [
            // soft blobs
            Positioned(top: -80, right: -60, child: _blob(220, UC.primary.withValues(alpha: .10))),
            Positioned(bottom: 140, left: -70, child: _blob(180, UC.accent.withValues(alpha: .18))),
            Column(
              children: [
                SizedBox(height: pad.top + 40),
                const Spacer(),
                ScaleTransition(
                  scale: CurvedAnimation(parent: c, curve: Curves.elasticOut),
                  child: const Mascot(mood: 'hello', size: 180),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: CurvedAnimation(parent: c, curve: const Interval(.3, 1)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            'umigo',
                            style: ts(52, w: FontWeight.w800, c: UC.ink, ls: -2.5),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(left: 2),
                            decoration: const BoxDecoration(color: UC.accent, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Go live. Get loved.',
                        style: ts(17, w: FontWeight.w700, c: UC.deep),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  opacity: showActions ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedSlide(
                    offset: showActions ? Offset.zero : const Offset(0, .3),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, pad.bottom + 20),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: showActions ? () => Navigator.pushNamed(context, '/register') : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: UC.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                textStyle: ts(16.5, w: FontWeight.w800),
                              ),
                              child: const Text('Create account'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: showActions ? () => Navigator.pushNamed(context, '/login') : null,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: UC.ink,
                                side: const BorderSide(color: UC.line, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                textStyle: ts(16.5, w: FontWeight.w800),
                              ),
                              child: const Text('I already have an account'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'By continuing you agree to the Terms and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: ts(12, w: FontWeight.w600, c: UC.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double s, Color c) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}
