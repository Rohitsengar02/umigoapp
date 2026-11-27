import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';
import 'menu_screens.dart';
import 'messages_screen.dart';
import 'reels_screen.dart';

/// Four tabs in a floating glass bar, with Go live as its own round button beside it.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

const _tabs = [
  (Icons.home_rounded, Icons.home_outlined, 'Home'),
  (Icons.favorite_rounded, Icons.favorite_border_rounded, 'Following'),
  (Icons.play_circle_rounded, Icons.play_circle_outline_rounded, 'Reels'),
  (Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
];

class _ShellState extends State<Shell> with SingleTickerProviderStateMixin {
  int tab = 0;
  final _seen = <int>{0}; // build a tab the first time it is opened, then keep it alive
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);
  late final Animation<double> _fade = CurvedAnimation(parent: _in, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween(begin: const Offset(0, .015), end: Offset.zero).animate(CurvedAnimation(parent: _in, curve: Curves.easeOutCubic));

  void _go(int i) {
    if (i == tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      tab = i;
      _seen.add(i);
    });
    _in.forward(from: 0);
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [const HomeScreen(), const LiveListScreen(kind: LiveListKind.following, asTab: true), const ReelsScreen(), const MessagesScreen()];
    final pad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      drawer: const AppDrawer(),
      extendBody: true,
      body: Stack(
        children: [
          // Inactive tabs are fully offstage (kept alive, no paint, no ticks); only the
          // tab being opened fades in. A frozen fade used to leave one tab drawn on top.
          for (var i = 0; i < pages.length; i++)
            if (_seen.contains(i))
              Positioned.fill(
                child: Offstage(
                  offstage: i != tab,
                  child: TickerMode(
                    enabled: i == tab,
                    child: FadeTransition(
                      opacity: i == tab ? _fade : kAlwaysCompleteAnimation,
                      child: SlideTransition(position: i == tab ? _slide : const AlwaysStoppedAnimation(Offset.zero), child: pages[i]),
                    ),
                  ),
                ),
              ),
          Positioned(
            left: 16,
            right: 16,
            bottom: (pad > 0 ? pad : 12) + 6,
            child: _TabBar(index: tab, dark: tab == 2, onTap: _go, onLive: () => Navigator.pushNamed(context, '/golive')),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final int index;
  final bool dark;
  final ValueChanged<int> onTap;
  final VoidCallback onLive;
  const _TabBar({required this.index, required this.dark, required this.onTap, required this.onLive});

  @override
  Widget build(BuildContext context) {
    const h = 68.0;
    final tint = dark ? const Color(0x8C2E1C30) : UC.glassStrong;
    final idle = dark ? Colors.white.withValues(alpha: .8) : UC.ink;
    return Row(
      children: [
        Expanded(
          child: Glass(
            tint: tint,
            child: SizedBox(
              height: h,
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = (c.maxWidth - 12) / _tabs.length;
                  return Stack(
                    children: [
                      // sliding highlight
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 460),
                        curve: Curves.easeOutBack,
                        left: 6 + w * index + 4,
                        top: 9,
                        width: w - 8,
                        height: h - 18,
                        child: Container(
                          decoration: BoxDecoration(
                            color: dark ? Colors.white : UC.pill,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [BoxShadow(color: UC.inkA(.30), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            for (var i = 0; i < _tabs.length; i++)
                              Expanded(
                                child: Semantics(
                                  selected: i == index,
                                  button: true,
                                  label: _tabs[i].$3,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => onTap(i),
                                    child: SizedBox(
                                      height: h,
                                      child: Center(
                                        child: AnimatedScale(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOutBack,
                                          scale: i == index ? 1.08 : 1,
                                          child: Icon(
                                            i == index ? _tabs[i].$1 : _tabs[i].$2,
                                            size: 26,
                                            color: i == index ? (dark ? UC.night : Colors.white) : idle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Pressable(
          onTap: onLive,
          label: 'Go live',
          child: Glass(
            tint: tint,
            child: SizedBox(
              width: h,
              height: h,
              child: Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: UC.brandGradient,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .4), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
