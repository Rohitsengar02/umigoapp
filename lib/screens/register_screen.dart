import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mascot.dart';

/// One continuous, single-scroll 5-step sign up. Umi reacts to every field.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int step = 1;
  String error = '';
  bool showPw = false;
  String gender = '';
  final interests = <String>[];
  final name = TextEditingController(), user = TextEditingController(), phone = TextEditingController();
  final code = TextEditingController(), pw = TextEditingController();
  final dd = TextEditingController(), mm = TextEditingController(), yy = TextEditingController();
  final fName = FocusNode(), fUser = FocusNode(), fPhone = FocusNode(), fCode = FocusNode(), fPw = FocusNode(), fDob = FocusNode();
  bool codeSent = false;
  final scroll = ScrollController();

  static const titles = ['Your name', 'Phone verification', 'Create a password', 'About you', 'Your interests'];
  static const topics = ['Music', 'Gaming', 'Dance', 'Talk shows', 'Comedy', 'Fitness', 'Cooking', 'Travel', 'Beauty', 'Study'];

  @override
  void initState() {
    super.initState();
    for (final f in [fName, fUser, fPhone, fCode, fPw, fDob]) {
      f.addListener(() => setState(() {}));
    }
  }

  int get pwScore =>
      (pw.text.length >= 8 ? 1 : 0) +
      (RegExp(r'\d').hasMatch(pw.text) ? 1 : 0) +
      (RegExp(r'[^A-Za-z0-9]').hasMatch(pw.text) ? 1 : 0) +
      (RegExp(r'[A-Z]').hasMatch(pw.text) ? 1 : 0);

  String get first => name.text.trim().split(' ').first.isEmpty ? 'there' : name.text.trim().split(' ').first;

  String validate() {
    switch (step) {
      case 1:
        if (name.text.trim().length < 2) return 'Your name needs at least 2 letters.';
        if (user.text.trim().length < 3) return 'Pick a username with 3+ characters.';
      case 2:
        if (phone.text.replaceAll(RegExp(r'\D'), '').length < 10) return 'Enter a 10-digit mobile number.';
        if (code.text.length < 6) return 'Enter the 6-digit code we sent.';
      case 3:
        if (pwScore < 3) return 'Make it stronger: 8+ characters, a number and a symbol.';
      case 4:
        if (gender.isEmpty) return 'Choose an option above.';
        if (yy.text.length < 4) return 'Add your birth year.';
      case 5:
        if (interests.length < 3) return 'Pick at least 3 interests.';
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
    setState(() {
      error = '';
      step++;
    });
    if (step == 6) {
      AppState.I.register(name: name.text.trim(), username: user.text.trim(), interests: List.of(interests));
    }
    Future.delayed(const Duration(milliseconds: 250), () {
      if (scroll.hasClients) {
        scroll.animateTo((step - 1) * 74.0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  double lenLook(String v) => ((v.length / 14) * 2 - 1).clamp(-1, 1).toDouble();

  (String, double, String) get umi {
    var mood = 'hello', look = 0.0, bubble = "Hi, I'm Umi! Let's get you live in under a minute.";
    if (step == 1 && fName.hasFocus) {
      mood = 'look';
      look = lenLook(name.text);
      bubble = name.text.length > 1 ? 'Nice to meet you, $first!' : 'What should we call you?';
    }
    if (step == 1 && fUser.hasFocus) {
      mood = 'look';
      look = lenLook(user.text);
      bubble = user.text.length > 2 ? '@${user.text} sounds like a star.' : 'Pick a handle fans will remember.';
    }
    if (step == 2) {
      mood = 'look';
      look = lenLook(fCode.hasFocus ? code.text + code.text : phone.text);
      bubble = fCode.hasFocus ? 'Check your SMS, the code is in there.' : "We'll text you a code. No spam, promise.";
    }
    if (step == 3) {
      mood = showPw ? 'peek' : 'hide';
      bubble = showPw ? 'Okay, just a tiny peek…' : "I'm not looking. Type away!";
    }
    if (step == 4) {
      mood = 'think';
      bubble = 'Tell me a little about you.';
    }
    if (step == 5) {
      mood = interests.isNotEmpty ? 'love' : 'think';
      bubble = interests.isNotEmpty ? '${interests.length} picks already. Great taste!' : 'What do you love watching?';
    }
    if (error.isNotEmpty) {
      mood = 'oops';
      bubble = 'Oops! $error';
    }
    if (step >= 6) {
      mood = 'party';
      bubble = 'Woohoo! Welcome to Umigo, $first!';
    }
    return (mood, look, bubble);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final (mood, look, bubble) = umi;
    return Scaffold(
      body: Column(children: [
        // Full-bleed top card with the reacting mascot
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(8, pad.top + 2, 14, 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [UC.primary, Color(0xFFE5677F), UC.accent]),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              Expanded(
                child: Text(step >= 6 ? 'All done' : 'Step $step of 5',
                    style: ts(13, w: FontWeight.w800, c: Colors.white.withValues(alpha: .9))),
              ),
              Text('umigo', style: ts(18, w: FontWeight.w800, c: Colors.white, ls: -0.6)),
            ]),
            const SizedBox(height: 2),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Mascot(mood: mood, look: look, size: 118),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      key: ValueKey(bubble),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      child: Text(bubble, style: ts(14, w: FontWeight.w800, c: mood == 'oops' ? UC.red : UC.ink, h: 1.3)),
                    ),
                  ),
                ),
              ),
            ]),
            Row(children: [
              for (var n = 1; n <= 5; n++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: n < step ? UC.ink.withValues(alpha: .55) : n == step ? Colors.white : Colors.white.withValues(alpha: .35),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
        Expanded(
          child: step >= 6
              ? _done()
              : ListView(
                  controller: scroll,
                  padding: EdgeInsets.fromLTRB(12, 12, 12, pad.bottom + 20),
                  children: [
                    for (var n = 1; n <= 5; n++) _stepCard(n),
                    const SizedBox(height: 10),
                    Center(child: Text('Already have an account?', style: ts(13, w: FontWeight.w600, c: UC.muted))),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text('Log in', style: ts(14, w: FontWeight.w800, c: UC.primary)),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }

  String summary(int n) => switch (n) {
        1 => '@${user.text} · ${name.text}',
        2 => '+91 ${phone.text} · verified',
        3 => '•••••••••• · strong',
        4 => '$gender · ${dd.text}/${mm.text}/${yy.text}',
        _ => interests.join(', '),
      };

  Widget _stepCard(int n) {
    final done = n < step, active = n == step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: done ? UC.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? UC.primary : UC.line, width: active ? 2 : 1.5),
        boxShadow: active ? [BoxShadow(color: UC.inkA(.07), blurRadius: 24, offset: const Offset(0, 8))] : null,
      ),
      child: Opacity(
        opacity: (!done && !active) ? .6 : 1,
        child: Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: done ? () => setState(() => step = n) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? UC.green : active ? UC.primary : UC.surface,
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                      : Text('$n', style: ts(13, w: FontWeight.w800, c: active ? Colors.white : UC.muted)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(titles[n - 1], style: ts(15, w: FontWeight.w800)),
                    if (done)
                      Text(summary(n), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12.5, w: FontWeight.w600, c: UC.muted)),
                  ]),
                ),
                if (done) Text('Edit', style: ts(13, w: FontWeight.w800, c: UC.deep)),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: active
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _body(n),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(error, style: ts(12.5, w: FontWeight.w700, c: UC.red)),
                      ],
                      const SizedBox(height: 12),
                      PrimaryButton(n == 5 ? 'Create account' : n == 2 ? 'Verify & continue' : 'Continue', onTap: next, height: 50),
                    ]),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ]),
      ),
    );
  }

  void clr(_) => setState(() => error = '');

  Widget _body(int n) {
    switch (n) {
      case 1:
        return Column(children: [
          FieldBox(label: 'Full name', controller: name, focus: fName, hint: 'Aarav Mehta', onChanged: clr, error: error.contains('name')),
          const SizedBox(height: 10),
          FieldBox(
            label: 'Username',
            controller: user,
            focus: fUser,
            hint: 'aarav.live',
            onChanged: clr,
            error: error.contains('username'),
            prefix: Text('@', style: ts(16, w: FontWeight.w800, c: UC.deep)),
            suffix: user.text.trim().length >= 3 ? const Icon(Icons.check_circle_rounded, color: UC.green, size: 20) : null,
          ),
        ]);
      case 2:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FieldBox(
            label: 'Mobile number',
            controller: phone,
            focus: fPhone,
            hint: '98765 43210',
            type: TextInputType.phone,
            onChanged: clr,
            prefix: Text('+91', style: ts(15, w: FontWeight.w800, c: UC.deep)),
            suffix: TextButton(
              onPressed: () {
                setState(() => codeSent = true);
                code.text = '482913';
                toast(context, 'Demo code 482913 filled in for you.');
              },
              child: Text(codeSent ? 'Resend' : 'Send code', style: ts(13, w: FontWeight.w800, c: UC.primary)),
            ),
          ),
          const SizedBox(height: 10),
          FieldBox(label: '6-digit code', controller: code, focus: fCode, hint: '••••••', type: TextInputType.number, maxLength: 6, onChanged: clr),
        ]);
      case 3:
        final cols = [UC.red, const Color(0xFFF79009), UC.green, UC.green];
        final rules = [
          ('8+ chars', pw.text.length >= 8),
          ('Number', RegExp(r'\d').hasMatch(pw.text)),
          ('Symbol', RegExp(r'[^A-Za-z0-9]').hasMatch(pw.text)),
          ('Capital', RegExp(r'[A-Z]').hasMatch(pw.text)),
        ];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FieldBox(
            label: 'Password',
            controller: pw,
            focus: fPw,
            obscure: !showPw,
            hint: 'Umigo@2026',
            onChanged: clr,
            suffix: IconButton(
              tooltip: showPw ? 'Hide password' : 'Show password',
              onPressed: () => setState(() => showPw = !showPw),
              icon: Icon(showPw ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: UC.muted, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i < pwScore ? cols[pwScore - 1] : UC.line,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final r in rules)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: r.$2 ? UC.greenSoft : UC.surface, borderRadius: BorderRadius.circular(99)),
                child: Text(r.$1, style: ts(11.5, w: FontWeight.w800, c: r.$2 ? UC.greenText : UC.muted)),
              ),
          ]),
        ]);
      case 4:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('I am', style: ts(12.5, w: FontWeight.w800, c: UC.muted)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final g in ['Male', 'Female', 'Non-binary', 'Prefer not to say'])
              ChoiceChipX(g, on: gender == g, onTap: () => setState(() {
                    gender = g;
                    error = '';
                  })),
          ]),
          const SizedBox(height: 12),
          Text('Birthday', style: ts(12.5, w: FontWeight.w800, c: UC.muted)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _dob(dd, 'DD', 2, fDob)),
            const SizedBox(width: 6),
            Expanded(child: _dob(mm, 'MM', 2, null)),
            const SizedBox(width: 6),
            Expanded(flex: 2, child: _dob(yy, 'YYYY', 4, null)),
          ]),
        ]);
      default:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pick 3 or more', style: ts(12.5, w: FontWeight.w800, c: UC.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final t in topics)
              ChoiceChipX(t, on: interests.contains(t), onTap: () => setState(() {
                    interests.contains(t) ? interests.remove(t) : interests.add(t);
                    error = '';
                  })),
          ]),
        ]);
    }
  }

  Widget _dob(TextEditingController c, String hint, int len, FocusNode? f) => Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: UC.line, width: 1.5)),
        child: TextField(
          controller: c,
          focusNode: f,
          maxLength: len,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          onChanged: clr,
          style: ts(15, w: FontWeight.w800),
          decoration: InputDecoration(counterText: '', hintText: hint, hintStyle: ts(14, w: FontWeight.w600, c: UC.muted.withValues(alpha: .6))),
        ),
      );

  Widget _done() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 10),
          Text("You're in, $first!", style: ts(26, w: FontWeight.w800, ls: -0.8)),
          const SizedBox(height: 6),
          Text('We added 100 welcome coins to your wallet. Go say hi to someone live.',
              textAlign: TextAlign.center, style: ts(14, w: FontWeight.w600, c: UC.muted, h: 1.4)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Avatar(img: 'assets/img/me.jpg', size: 48, border: UC.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.text, style: ts(16, w: FontWeight.w800)),
                  Text('@${user.text} · ${interests.take(3).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12.5, w: FontWeight.w600, c: UC.muted)),
                ]),
              ),
            ]),
          ),
          const Spacer(),
          PrimaryButton('Start watching', onTap: () {
            AppState.I.addCoins(100);
            Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
          }),
        ]),
      );
}
