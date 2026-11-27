import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';
import '../widgets/motion.dart';
import '../widgets/ui.dart';

/// Sign up as a run of separate screens: one step per screen, each with an animated
/// title, Umi reacting to what you type, and fields that arrive one after another.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) => _StepScreen(step: 1, d: _RegData());
}

class _RegData {
  final name = TextEditingController(), user = TextEditingController(), phone = TextEditingController();
  final code = TextEditingController(), pw = TextEditingController();
  final dd = TextEditingController(), mm = TextEditingController(), yy = TextEditingController();
  String gender = '';
  bool codeSent = false;
  final interests = <String>[];
  String get first => name.text.trim().split(' ').first.isEmpty ? 'there' : name.text.trim().split(' ').first;
  int get pwScore =>
      (pw.text.length >= 8 ? 1 : 0) +
      (RegExp(r'\d').hasMatch(pw.text) ? 1 : 0) +
      (RegExp(r'[^A-Za-z0-9]').hasMatch(pw.text) ? 1 : 0) +
      (RegExp(r'[A-Z]').hasMatch(pw.text) ? 1 : 0);
}

const _labels = ['Name', 'Phone', 'Password', 'About you', 'Interests'];
const _titles = ["What's your\nname?", 'Verify your\nphone', 'Lock it with\na password', 'A little\nabout you', 'What do you\nlove watching?'];
const _topics = ['Music', 'Gaming', 'Dance', 'Talk shows', 'Comedy', 'Fitness', 'Cooking', 'Travel', 'Beauty', 'Study'];

class _StepScreen extends StatefulWidget {
  final int step;
  final _RegData d;
  const _StepScreen({required this.step, required this.d});
  @override
  State<_StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends State<_StepScreen> {
  _RegData get d => widget.d;
  int get step => widget.step;
  String error = '';
  bool showPw = false;
  final fA = FocusNode(), fB = FocusNode();

  @override
  void initState() {
    super.initState();
    for (final f in [fA, fB]) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    fA.dispose();
    fB.dispose();
    super.dispose();
  }

  String validate() {
    switch (step) {
      case 1:
        if (d.name.text.trim().length < 2) return 'Your name needs at least 2 letters.';
        if (d.user.text.trim().length < 3) return 'Pick a username with 3+ characters.';
      case 2:
        if (d.phone.text.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter a 10-digit mobile number.';
        if (d.code.text.length < 6) return 'Enter the 6-digit code we sent.';
      case 3:
        if (d.pwScore < 3) return 'Make it stronger: 8+ characters, a number and a symbol.';
      case 4:
        if (d.gender.isEmpty) return 'Choose an option above.';
        if (d.yy.text.length < 4) return 'Add your birth year.';
      case 5:
        if (d.interests.length < 3) return 'Pick at least 3 interests.';
    }
    return '';
  }

  void next() {
    final e = validate();
    if (e.isNotEmpty) {
      setState(() => error = e);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => error = '');
    if (step == 5) {
      AppState.I.register(name: d.name.text.trim(), username: d.user.text.trim(), interests: List.of(d.interests));
      Navigator.of(context).push(umiRoute((_) => _DoneScreen(d: d)));
    } else {
      Navigator.of(context).push(umiRoute((_) => _StepScreen(step: step + 1, d: d)));
    }
  }

  void clr(_) => setState(() => error = '');

  double lenLook(String v) => ((v.length / 14) * 2 - 1).clamp(-1, 1).toDouble();

  (String, double, String) get umi {
    var mood = 'hello', look = 0.0, bubble = "Hi, I'm Umi! Let's get you live in under a minute.";
    switch (step) {
      case 1:
        if (fA.hasFocus) {
          mood = 'look';
          look = lenLook(d.name.text);
          bubble = d.name.text.length > 1 ? 'Nice to meet you, ${d.first}!' : 'What should we call you?';
        } else if (fB.hasFocus) {
          mood = 'look';
          look = lenLook(d.user.text);
          bubble = d.user.text.length > 2 ? '@${d.user.text} sounds like a star.' : 'Pick a handle fans will remember.';
        }
      case 2:
        mood = 'look';
        look = lenLook(fB.hasFocus ? d.code.text + d.code.text : d.phone.text);
        bubble = fB.hasFocus ? 'Check your SMS, the code is in there.' : "We'll text you a code. No spam, promise.";
      case 3:
        mood = showPw ? 'peek' : 'hide';
        bubble = showPw ? 'Okay, just a tiny peek…' : "I'm not looking. Type away!";
      case 4:
        mood = 'think';
        bubble = 'Tell me a little about you, ${d.first}.';
      case 5:
        mood = d.interests.isNotEmpty ? 'love' : 'think';
        bubble = d.interests.isNotEmpty ? '${d.interests.length} picks already. Great taste!' : 'Pick what you love and I will fill your feed.';
    }
    if (error.isNotEmpty) {
      mood = 'oops';
      bubble = 'Oops! $error';
    }
    return (mood, look, bubble);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final (mood, look, bubble) = umi;
    final fields = _fields();
    return Scaffold(
      body: AuroraBg(
        child: Column(
          children: [
            _Header(step: step, mood: mood, look: look, bubble: bubble, bad: mood == 'oops'),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 18, 20, pad.bottom + 24),
                children: [
                  for (var i = 0; i < fields.length; i++) StaggerIn(index: i, child: fields[i]),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    child: error.isEmpty
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                const Icon(Icons.error_rounded, size: 16, color: UC.red),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: ts(12.5, w: FontWeight.w700, c: UC.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  StaggerIn(
                    index: fields.length,
                    child: PrimaryButton(
                      step == 5
                          ? 'Create account'
                          : step == 2
                          ? 'Verify & continue'
                          : 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      dark: step != 5,
                      onTap: next,
                    ),
                  ),
                  if (step == 1) ...[
                    const SizedBox(height: 14),
                    StaggerIn(
                      index: fields.length + 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: ts(13, w: FontWeight.w600, c: UC.muted),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: Text(
                              'Log in',
                              style: ts(14, w: FontWeight.w800, c: UC.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fields() {
    switch (step) {
      case 1:
        return [
          FieldBox(label: 'Full name', controller: d.name, focus: fA, hint: 'Aarav Mehta', onChanged: clr, error: error.contains('name')),
          const SizedBox(height: 12),
          FieldBox(
            label: 'Username',
            controller: d.user,
            focus: fB,
            hint: 'aarav.live',
            onChanged: clr,
            error: error.contains('username'),
            prefix: Text(
              '@',
              style: ts(16, w: FontWeight.w800, c: UC.deep),
            ),
            suffix: d.user.text.trim().length >= 3 ? const Icon(Icons.check_circle_rounded, color: UC.green, size: 20) : null,
          ),
        ];
      case 2:
        return [
          FieldBox(
            label: 'Mobile number',
            controller: d.phone,
            focus: fA,
            hint: '98765 43210',
            type: TextInputType.phone,
            onChanged: clr,
            prefix: Text(
              '+91',
              style: ts(15, w: FontWeight.w800, c: UC.deep),
            ),
            suffix: TextButton(
              onPressed: () {
                setState(() => d.codeSent = true);
                d.code.text = '482913';
                toast(context, 'Demo code 482913 filled in for you.');
              },
              child: Text(
                d.codeSent ? 'Resend' : 'Send code',
                style: ts(13, w: FontWeight.w800, c: UC.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FieldBox(label: '6-digit code', controller: d.code, focus: fB, hint: '••••••', type: TextInputType.number, maxLength: 6, onChanged: clr),
        ];
      case 3:
        final cols = [UC.red, const Color(0xFFF79009), UC.green, UC.green];
        final s = d.pwScore;
        final rules = [
          ('8+ chars', d.pw.text.length >= 8),
          ('Number', RegExp(r'\d').hasMatch(d.pw.text)),
          ('Symbol', RegExp(r'[^A-Za-z0-9]').hasMatch(d.pw.text)),
          ('Capital', RegExp(r'[A-Z]').hasMatch(d.pw.text)),
        ];
        return [
          FieldBox(
            label: 'Password',
            controller: d.pw,
            focus: fA,
            obscure: !showPw,
            hint: 'Umigo@2026',
            onChanged: clr,
            suffix: IconButton(
              tooltip: showPw ? 'Hide password' : 'Show password',
              onPressed: () => setState(() => showPw = !showPw),
              icon: Icon(showPw ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: UC.muted, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: i < s ? cols[s - 1] : UC.line),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in rules)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: r.$2 ? UC.greenSoft : UC.surface, borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(r.$2 ? Icons.check_rounded : Icons.circle_outlined, size: 13, color: r.$2 ? UC.greenText : UC.muted),
                      const SizedBox(width: 4),
                      Text(
                        r.$1,
                        style: ts(11.5, w: FontWeight.w800, c: r.$2 ? UC.greenText : UC.muted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ];
      case 4:
        return [
          Text(
            'I am',
            style: ts(12.5, w: FontWeight.w800, c: UC.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in ['Male', 'Female', 'Non-binary', 'Prefer not to say'])
                ChoiceChipX(
                  g,
                  on: d.gender == g,
                  onTap: () => setState(() {
                    d.gender = g;
                    error = '';
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Birthday',
            style: ts(12.5, w: FontWeight.w800, c: UC.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _dob(d.dd, 'DD', 2, fA)),
              const SizedBox(width: 8),
              Expanded(child: _dob(d.mm, 'MM', 2, null)),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _dob(d.yy, 'YYYY', 4, null)),
            ],
          ),
        ];
      default:
        return [
          Text(
            'Pick 3 or more',
            style: ts(12.5, w: FontWeight.w800, c: UC.muted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _topics.length; i++)
                StaggerIn(
                  index: i,
                  stepMs: 45,
                  baseMs: 200,
                  child: ChoiceChipX(
                    _topics[i],
                    on: d.interests.contains(_topics[i]),
                    onTap: () => setState(() {
                      final t = _topics[i];
                      d.interests.contains(t) ? d.interests.remove(t) : d.interests.add(t);
                      error = '';
                    }),
                  ),
                ),
            ],
          ),
        ];
    }
  }

  Widget _dob(TextEditingController c, String hint, int len, FocusNode? f) => Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .07), blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: TextField(
      controller: c,
      focusNode: f,
      maxLength: len,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: clr,
      style: ts(15, w: FontWeight.w800),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: ts(14, w: FontWeight.w600, c: UC.muted.withValues(alpha: .6)),
      ),
    ),
  );
}

/// Light header: back, segmented progress, big animated title, Umi and a speech bubble.
class _Header extends StatelessWidget {
  final int step;
  final String mood, bubble;
  final double look;
  final bool bad;
  const _Header({required this.step, required this.mood, required this.look, required this.bubble, required this.bad});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, pad.top + 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context)),
              const SizedBox(width: 12),
              // one bar per step; the current one fills in
              Expanded(
                child: Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(color: UC.ink.withValues(alpha: .08), borderRadius: BorderRadius.circular(9)),
                          alignment: Alignment.centerLeft,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: i < step ? 1 : 0, end: i <= step ? 1 : 0),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => FractionallySizedBox(
                              widthFactor: v,
                              child: Container(
                                decoration: BoxDecoration(gradient: UC.brandGradient, borderRadius: BorderRadius.circular(9)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$step/5',
                style: ts(14, w: FontWeight.w800, c: UC.muted),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StaggerIn(index: 0, baseMs: 60, dy: 8, child: Eyebrow('Step $step · ${_labels[step - 1]}')),
                    const SizedBox(height: 8),
                    TextReveal(
                      _titles[step - 1],
                      style: ds(36, c: UC.ink, h: 1.04),
                      delay: const Duration(milliseconds: 160),
                    ),
                  ],
                ),
              ),
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .75),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: (bad ? UC.red : UC.primary).withValues(alpha: .16), blurRadius: 30, offset: const Offset(0, 12))],
                ),
                alignment: Alignment.center,
                child: Mascot(mood: mood, look: look, size: 88),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(a),
                child: c,
              ),
            ),
            child: Container(
              key: ValueKey(bubble),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: const Color(0xFF6B4A6E).withValues(alpha: .08), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  Icon(bad ? Icons.error_rounded : Icons.auto_awesome_rounded, size: 18, color: bad ? UC.red : UC.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bubble,
                      style: ts(14.5, w: FontWeight.w700, c: bad ? UC.red : UC.ink, h: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneScreen extends StatefulWidget {
  final _RegData d;
  const _DoneScreen({required this.d});
  @override
  State<_DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends State<_DoneScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: AuroraBg(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, pad.top + 30, 22, pad.bottom + 22),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _Confetti(_burst))),
              ),
              Column(
                children: [
                  const Mascot(mood: 'party', size: 170),
                  const SizedBox(height: 18),
                  TextReveal(
                    "You're in,\n${d.first}!",
                    style: ds(40, c: UC.ink),
                    align: TextAlign.center,
                    delay: const Duration(milliseconds: 250),
                  ),
                  const SizedBox(height: 12),
                  StaggerIn(
                    index: 4,
                    child: Text(
                      'We added 100 welcome coins to your wallet. Go say hi to someone live.',
                      textAlign: TextAlign.center,
                      style: ts(14.5, w: FontWeight.w600, c: UC.muted, h: 1.45),
                    ),
                  ),
                  const SizedBox(height: 22),
                  StaggerIn(
                    index: 6,
                    child: SoftCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Avatar(img: 'assets/img/me.jpg', size: 50, border: UC.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.name.text, style: ts(16, w: FontWeight.w800)),
                                Text(
                                  '@${d.user.text} · ${d.interests.take(3).join(', ')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ts(12.5, w: FontWeight.w600, c: UC.muted),
                                ),
                              ],
                            ),
                          ),
                          const CoinDot(size: 22),
                          const SizedBox(width: 4),
                          Text(
                            '+100',
                            style: ts(14, w: FontWeight.w800, c: UC.accentText),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  StaggerIn(
                    index: 8,
                    child: PrimaryButton(
                      'Start watching',
                      dark: true,
                      icon: Icons.play_arrow_rounded,
                      onTap: () {
                        AppState.I.addCoins(100);
                        Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Confetti extends CustomPainter {
  final Animation<double> a;
  _Confetti(this.a) : super(repaint: a);
  static final _r = math.Random(7);
  static final _bits = List.generate(46, (i) => (_r.nextDouble(), _r.nextDouble(), _r.nextDouble(), i % 4));
  static const _cols = [UC.primary, UC.accent, UC.gold, UC.deep];
  @override
  void paint(Canvas c, Size s) {
    final t = Curves.easeOut.transform(a.value);
    for (final (x, sp, rot, ci) in _bits) {
      final p = Paint()..color = _cols[ci].withValues(alpha: (1 - a.value).clamp(0, 1) * .9);
      final dx = s.width / 2 + (x - .5) * s.width * 1.3 * t;
      final dy = s.height * .22 - math.sin(t * math.pi) * (120 + sp * 160) + t * t * s.height * .4 * sp;
      c.save();
      c.translate(dx, dy);
      c.rotate(rot * 6 + t * 8);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2, 8, 4), const Radius.circular(1)), p);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti o) => false;
}
