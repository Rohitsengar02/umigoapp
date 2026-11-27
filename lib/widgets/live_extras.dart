import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../data/social_data.dart';
import '../live/live_session.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'common.dart';
import 'live_widgets.dart';
import 'pay_sheet.dart';
import 'ui.dart';

/// Gift goal as a glass pill with a filling bar.
class GoalBar extends StatelessWidget {
  final LiveSession s;
  const GoalBar(this.s, {super.key});
  @override
  Widget build(BuildContext context) {
    final g = s.setup;
    final v = g.goalCoins == 0 ? 0.0 : (s.goalProgress / g.goalCoins).clamp(0.0, 1.0);
    final done = v >= 1;
    return Glass(
      tint: const Color(0x40000000),
      shadow: false,
      radius: BorderRadius.circular(18),
      padding: const EdgeInsets.fromLTRB(10, 8, 12, 9),
      child: SizedBox(
        width: 190,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(done ? Icons.celebration_rounded : Icons.flag_rounded, size: 14, color: UC.gold),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    done ? 'Goal reached!' : g.goalLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(11.5, w: FontWeight.w800, c: Colors.white),
                  ),
                ),
                Text(
                  '${(v * 100).round()}%',
                  style: ts(11, w: FontWeight.w800, c: UC.gold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 6,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .22), borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.centerLeft,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: v),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, x, _) => FractionallySizedBox(
                  widthFactor: x,
                  child: Container(
                    decoration: BoxDecoration(gradient: UC.coinGradient, borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${fmtIn(s.goalProgress)} / ${fmtIn(g.goalCoins)} coins',
              style: ts(10.5, w: FontWeight.w700, c: Colors.white.withValues(alpha: .85)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The host's tip menu. Viewers pay a line; the host sees it in chat.
void showTipMenu(BuildContext context, LiveSession s) {
  showUmiSheet(
    context,
    (ctx) => ListenableBuilder(
      listenable: AppState.I,
      builder: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tip menu', style: ds(24)),
                    Text(
                      '${s.hostName} does these live when you tip',
                      style: ts(13, w: FontWeight.w500, c: UC.muted),
                    ),
                  ],
                ),
              ),
              CoinPill(AppState.I.coins, onTap: () => Navigator.pushNamed(context, '/coins')),
            ],
          ),
          const SizedBox(height: 14),
          if (s.setup.tips.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No tip menu in this live',
                textAlign: TextAlign.center,
                style: ts(14.5, w: FontWeight.w700, c: UC.muted),
              ),
            ),
          for (final t in s.setup.tips)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
              decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(gradient: UC.coinGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(t.label, style: ts(15, w: FontWeight.w800)),
                  ),
                  Pressable(
                    label: 'Tip ${t.coins} coins for ${t.label}',
                    onTap: () {
                      if (!s.sendTip(t)) {
                        Navigator.pop(ctx);
                        toast(context, 'Not enough coins. Recharge to tip.');
                        return;
                      }
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx);
                      toast(context, 'Tipped ${t.coins} coins · ${t.label}');
                    },
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: UC.ink, borderRadius: BorderRadius.circular(99)),
                      child: Row(
                        children: [
                          const CoinDot(size: 15),
                          const SizedBox(width: 5),
                          Text(
                            fmtIn(t.coins),
                            style: ts(14, w: FontWeight.w800, c: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (s.setup.goalOn) ...[
            const SizedBox(height: 6),
            Text(
              'Every tip counts toward “${s.setup.goalLabel}”.',
              textAlign: TextAlign.center,
              style: ts(12.5, w: FontWeight.w600, c: UC.deep),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Covers a private live until the viewer pays the entry fee or subscribes.
/// Client-side check for now; the backend will verify before issuing a token.
class PrivateGate extends StatelessWidget {
  final LiveSession s;
  final String? img;
  final VoidCallback onLeave;
  const PrivateGate({super.key, required this.s, required this.img, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final g = s.setup;
    final subs = g.access == LiveAccess.subscribers;
    final id = s.demoHost?.id ?? s.hostIdentity;
    final pad = MediaQuery.paddingOf(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          color: UC.inkA(.45),
          padding: EdgeInsets.fromLTRB(24, pad.top + 20, 24, pad.bottom + 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: RoundGlassButton(Icons.close_rounded, tooltip: 'Leave', size: 42, onTap: onLeave),
              ),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Avatar(img: img, name: s.hostName, size: 96, border: Colors.white, borderW: 3),
                  Positioned(
                    right: -4,
                    bottom: -2,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: subs ? const LinearGradient(colors: [Color(0xFF8E4FA0), UC.primary]) : UC.coinGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(subs ? Icons.workspace_premium_rounded : Icons.lock_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const LiveBadge(),
              const SizedBox(height: 12),
              Text(subs ? 'Subscriber-only live' : 'Private show', style: ds(32, c: Colors.white)),
              const SizedBox(height: 8),
              Text(
                subs
                    ? 'Subscribe to ${s.hostName} for ${g.subPrice} coins a month to watch this and every private live.'
                    : '${s.hostName} is live in a private show. Pay ${g.entryFee} coins once to join.',
                textAlign: TextAlign.center,
                style: ts(15, w: FontWeight.w600, c: Colors.white.withValues(alpha: .9), h: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                '${fmtK(s.viewers)} inside now',
                style: ts(13, w: FontWeight.w700, c: UC.gold),
              ),
              const Spacer(),
              PrimaryButton(
                subs ? 'Subscribe · ${g.subPrice} coins / mo' : 'Join for ${g.entryFee} coins',
                icon: subs ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
                onTap: () => showPaySheet(
                  context,
                  title: subs ? 'Subscribe to ${s.hostName}' : 'Join the private show',
                  sub: subs ? 'Private lives, exclusive posts and free chat every month.' : 'One-time entry for this live with ${s.hostName}.',
                  price: subs ? g.subPrice : g.entryFee,
                  period: subs ? 'month' : '',
                  icon: subs ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
                  img: img,
                  cta: subs ? 'Subscribe' : 'Pay & join',
                  pay: () => subs ? AppState.I.subscribe(id, g.subPrice) : AppState.I.unlock('live:$id', g.entryFee),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onLeave,
                child: Text(
                  'Maybe later',
                  style: ts(14.5, w: FontWeight.w800, c: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Is this viewer allowed into the live?
bool canWatch(LiveSession s) {
  final g = s.setup;
  final id = s.demoHost?.id ?? s.hostIdentity;
  return switch (g.access) {
    LiveAccess.public => true,
    LiveAccess.paid => AppState.I.isUnlocked('live:$id') || AppState.I.isSubscribed(id),
    LiveAccess.subscribers => AppState.I.isSubscribed(id),
  };
}
