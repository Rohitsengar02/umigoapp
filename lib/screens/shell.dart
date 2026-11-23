import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';

/// Bottom tabs: Home, Ranks, (Go live), Wallet, Me.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = const [HomeScreen(), LeaderboardScreen(), WalletScreen(), ProfileScreen()];
    final pad = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: pad > 0 ? pad : 8, top: 6),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: UC.line))),
        child: Row(children: [
          _item(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
          _item(1, Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Ranks'),
          Expanded(
            child: Align(
              heightFactor: 1,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/golive'),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: UC.brandGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
          _item(2, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Wallet'),
          _item(3, Icons.person_rounded, Icons.person_outline_rounded, 'Me'),
        ]),
      ),
    );
  }

  Widget _item(int i, IconData on, IconData off, String label) {
    final sel = i == tab;
    return Expanded(
      child: InkResponse(
        onTap: () => setState(() => tab = i),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 54,
            height: 30,
            decoration: BoxDecoration(color: sel ? UC.soft : Colors.transparent, borderRadius: BorderRadius.circular(99)),
            child: Icon(sel ? on : off, color: sel ? UC.primary : UC.muted, size: 23),
          ),
          const SizedBox(height: 2),
          Text(label, style: ts(11, w: FontWeight.w800, c: sel ? UC.primary : UC.muted)),
        ]),
      ),
    );
  }
}
