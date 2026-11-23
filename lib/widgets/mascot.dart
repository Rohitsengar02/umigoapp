import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Umi, the Umigo mascot. Moods: hello, look, hide, peek, think, love, oops, party.
/// [look] (-1..1) moves the pupils, used to follow text as the user types.
class Mascot extends StatefulWidget {
  final String mood;
  final double look;
  final double size;
  const Mascot({super.key, this.mood = 'hello', this.look = 0, this.size = 160});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void didUpdateWidget(covariant Mascot old) {
    super.didUpdateWidget(old);
    if (widget.mood == 'oops' && old.mood != 'oops') _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _loop.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svg = umiSvg(widget.mood, widget.look);
    return AnimatedBuilder(
      animation: Listenable.merge([_loop, _shake]),
      builder: (context, child) {
        final t = _loop.value;
        double dy, sx = 1, sy = 1, dx = 0;
        if (widget.mood == 'party') {
          final p = (t * 2.9) % 1; // ~0.9s jumps
          dy = -16 * sin(p * pi).clamp(0, 1);
          sy = 1 + 0.05 * sin(p * pi);
          sx = 1 - 0.04 * sin(p * pi);
        } else {
          dy = -5 * (0.5 - 0.5 * cos(t * 2 * pi));
        }
        if (_shake.isAnimating) dx = 5 * sin(_shake.value * pi * 6) * (1 - _shake.value);
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.diagonal3Values(sx, sy, 1), child: child),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: SvgPicture.string(svg, key: ValueKey(svg), width: widget.size, height: widget.size),
      ),
    );
  }
}

const _primary = '#CF3F6C', _accent = '#FF9F80', _deep = '#6B4A6E', _ink = '#2E1C30', _line = '#F1E4EA';

String umiSvg(String m, double look) {
  double dx = 0, dy = 0;
  if (m == 'look') {
    dx = look.clamp(-1, 1) * 7;
    dy = 5;
  }
  if (m == 'think') {
    dx = 6;
    dy = -7;
  }
  if (m == 'peek') {
    dx = -5;
    dy = 5;
  }
  if (m == 'oops') dy = 3;
  final blush = (m == 'hide' || m == 'peek' || m == 'love') ? 0.55 : 0.22;
  final lx = 76 + dx, rx = 124 + dx, y = 101 + dy, lhx = 73 + dx, rhx = 121 + dx, hy = 97 + dy;
  final b = StringBuffer()
    ..write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" fill="none">')
    ..write('<defs><linearGradient id="g" x1="0.15" y1="0.05" x2="0.9" y2="1">'
        '<stop offset="0" stop-color="$_primary"/><stop offset="1" stop-color="$_accent"/></linearGradient></defs>')
    ..write('<ellipse cx="100" cy="190" rx="50" ry="6" fill="$_ink" opacity="0.08"/>');
  if (m == 'party') {
    b.write('<rect x="30" y="20" width="8" height="12" rx="2" fill="$_accent" transform="rotate(20 34 26)"/>'
        '<rect x="160" y="10" width="7" height="11" rx="2" fill="$_primary" transform="rotate(-25 163 15)"/>'
        '<circle cx="56" cy="8" r="4" fill="#FFB800"/><rect x="138" y="4" width="6" height="10" rx="2" fill="#12B76A"/>'
        '<circle cx="180" cy="30" r="3.5" fill="$_accent"/><rect x="14" y="40" width="6" height="9" rx="2" fill="$_primary"/>');
  }
  // antenna with live signal
  b.write('<path d="M100 42 L100 22" stroke="$_deep" stroke-width="4" stroke-linecap="round"/>'
      '<circle cx="100" cy="17" r="8" fill="$_accent"/><circle cx="97" cy="14" r="2.5" fill="#FFFFFF" opacity="0.7"/>'
      '<path d="M84 8 Q78 17 84 26" stroke="$_accent" stroke-width="3" stroke-linecap="round"/>'
      '<path d="M116 8 Q122 17 116 26" stroke="$_accent" stroke-width="3" stroke-linecap="round"/>'
      '<path d="M76 2 Q66 17 76 32" stroke="$_accent" stroke-width="3" stroke-linecap="round" opacity="0.5"/>'
      '<path d="M124 2 Q134 17 124 32" stroke="$_accent" stroke-width="3" stroke-linecap="round" opacity="0.5"/>'
      '<ellipse cx="76" cy="178" rx="15" ry="7" fill="$_deep"/><ellipse cx="124" cy="178" rx="15" ry="7" fill="$_deep"/>');
  // arms behind body
  if (['look', 'think', 'oops', 'love'].contains(m)) {
    b.write('<ellipse cx="32" cy="124" rx="11" ry="18" fill="$_deep" transform="rotate(22 32 124)"/>'
        '<ellipse cx="168" cy="124" rx="11" ry="18" fill="$_deep" transform="rotate(-22 168 124)"/>');
  }
  if (m == 'hello') {
    b.write('<ellipse cx="32" cy="124" rx="11" ry="18" fill="$_deep" transform="rotate(22 32 124)"/>'
        '<ellipse cx="172" cy="80" rx="11" ry="20" fill="$_deep" transform="rotate(28 172 80)"/>');
  }
  if (m == 'party') {
    b.write('<ellipse cx="30" cy="70" rx="11" ry="21" fill="$_deep" transform="rotate(-30 30 70)"/>'
        '<ellipse cx="170" cy="70" rx="11" ry="21" fill="$_deep" transform="rotate(30 170 70)"/>');
  }
  // body
  b.write('<path d="M100 40 C150 40 174 70 174 112 C174 158 142 180 100 180 C58 180 26 158 26 112 C26 70 50 40 100 40 Z" fill="url(#g)"/>'
      '<ellipse cx="100" cy="146" rx="40" ry="24" fill="#FFFFFF" opacity="0.16"/>'
      '<ellipse cx="62" cy="70" rx="13" ry="7" fill="#FFFFFF" opacity="0.35" transform="rotate(-32 62 70)"/>');
  // eyes
  if (['hello', 'look', 'think', 'oops', 'hide'].contains(m)) {
    b.write('<ellipse cx="76" cy="100" rx="18" ry="20" fill="#FFFFFF"/><ellipse cx="124" cy="100" rx="18" ry="20" fill="#FFFFFF"/>'
        '<circle cx="$lx" cy="$y" r="9" fill="$_ink"/><circle cx="$rx" cy="$y" r="9" fill="$_ink"/>'
        '<circle cx="$lhx" cy="$hy" r="3" fill="#FFFFFF"/><circle cx="$rhx" cy="$hy" r="3" fill="#FFFFFF"/>');
  }
  if (m == 'peek') {
    b.write('<ellipse cx="124" cy="100" rx="18" ry="20" fill="#FFFFFF"/><circle cx="$rx" cy="$y" r="9" fill="$_ink"/>'
        '<circle cx="$rhx" cy="$hy" r="3" fill="#FFFFFF"/>');
  }
  if (m == 'party') {
    b.write('<path d="M62 104 Q76 86 90 104" stroke="$_ink" stroke-width="6" stroke-linecap="round"/>'
        '<path d="M110 104 Q124 86 138 104" stroke="$_ink" stroke-width="6" stroke-linecap="round"/>');
  }
  if (m == 'love') {
    b.write('<path d="M76 116 L60 100 A9 9 0 0 1 76 88 A9 9 0 0 1 92 100 Z" fill="#FFFFFF"/>'
        '<path d="M124 116 L108 100 A9 9 0 0 1 124 88 A9 9 0 0 1 140 100 Z" fill="#FFFFFF"/>'
        '<path d="M76 110 L66 100 A5.5 5.5 0 0 1 76 93 A5.5 5.5 0 0 1 86 100 Z" fill="$_deep"/>'
        '<path d="M124 110 L114 100 A5.5 5.5 0 0 1 124 93 A5.5 5.5 0 0 1 134 100 Z" fill="$_deep"/>'
        '<path d="M170 60 l-8 -8 a5 5 0 0 1 8 -6 a5 5 0 0 1 8 6 z" fill="$_accent"/>'
        '<path d="M30 70 l-6 -6 a4 4 0 0 1 6 -5 a4 4 0 0 1 6 5 z" fill="$_primary"/>');
  }
  if (m == 'oops') {
    b.write('<path d="M60 74 L88 80" stroke="$_ink" stroke-width="5" stroke-linecap="round"/>'
        '<path d="M140 74 L112 80" stroke="$_ink" stroke-width="5" stroke-linecap="round"/>'
        '<path d="M156 58 C150 68 150 74 156 76 C162 74 162 68 156 58 Z" fill="#8FD3FF"/>');
  }
  if (m == 'look' || m == 'peek') {
    b.write('<path d="M62 72 Q76 64 90 72" stroke="$_ink" stroke-width="4.5" stroke-linecap="round"/>'
        '<path d="M110 70 Q124 62 138 70" stroke="$_ink" stroke-width="4.5" stroke-linecap="round"/>');
  }
  b.write('<ellipse cx="54" cy="128" rx="10" ry="6" fill="#FFFFFF" opacity="$blush"/>'
      '<ellipse cx="146" cy="128" rx="10" ry="6" fill="#FFFFFF" opacity="$blush"/>');
  // mouth
  switch (m) {
    case 'hello':
    case 'look':
      b.write('<path d="M86 130 Q100 144 114 130" stroke="$_ink" stroke-width="5" stroke-linecap="round"/>');
    case 'peek':
      b.write('<ellipse cx="100" cy="135" rx="6" ry="7" fill="$_ink"/>');
    case 'party':
    case 'love':
      b.write('<path d="M82 126 Q100 158 118 126 Z" fill="$_ink"/><ellipse cx="100" cy="142" rx="8" ry="5" fill="#FF6B8B"/>');
    case 'hide':
      b.write('<path d="M86 136 q3.5 -5 7 0 q3.5 5 7 0 q3.5 -5 7 0 q3.5 5 7 0" stroke="$_ink" stroke-width="4" stroke-linecap="round"/>');
    case 'oops':
      b.write('<path d="M88 140 Q100 128 112 140" stroke="$_ink" stroke-width="5" stroke-linecap="round"/>');
    case 'think':
      b.write('<path d="M92 136 Q104 132 112 136" stroke="$_ink" stroke-width="5" stroke-linecap="round"/>');
  }
  // arms in front
  if (m == 'hide') {
    b.write('<ellipse cx="74" cy="100" rx="26" ry="16" fill="$_deep" transform="rotate(-12 74 100)"/>'
        '<ellipse cx="126" cy="100" rx="26" ry="16" fill="$_deep" transform="rotate(12 126 100)"/>');
  }
  if (m == 'peek') {
    b.write('<ellipse cx="74" cy="100" rx="26" ry="16" fill="$_deep" transform="rotate(-12 74 100)"/>'
        '<ellipse cx="166" cy="128" rx="11" ry="18" fill="$_deep" transform="rotate(-22 166 128)"/>');
  }
  if (m == 'think') {
    b.write('<circle cx="166" cy="40" r="18" fill="#FFFFFF" stroke="$_line" stroke-width="2"/>'
        '<circle cx="150" cy="62" r="4" fill="#FFFFFF" stroke="$_line" stroke-width="2"/>'
        '<path d="M160 34 a6 6 0 1 1 8 6 q-2 1 -2 4" stroke="$_primary" stroke-width="3.5" stroke-linecap="round"/>'
        '<circle cx="166" cy="50" r="2.2" fill="$_primary"/>');
  }
  b.write('</svg>');
  return b.toString();
}
