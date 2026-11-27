import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/mascot.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String tab = 'Phone';
  final id = TextEditingController();
  final pw = TextEditingController();
  final fId = FocusNode(), fPw = FocusNode();
  bool keep = true, showPw = false;
  String? err;

  @override
  void initState() {
    super.initState();
    for (final f in [fId, fPw]) {
      f.addListener(() => setState(() {}));
    }
  }

  String get mood {
    if (err != null) return 'oops';
    if (fPw.hasFocus) return showPw ? 'peek' : 'hide';
    if (fId.hasFocus) return 'look';
    return 'hello';
  }

  void submit() {
    final v = id.text.trim();
    if (tab == 'Phone' && v.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() => err = 'Enter your 10-digit mobile number.');
      return;
    }
    if (tab == 'Email' && !v.contains('@')) {
      setState(() => err = 'That email looks off.');
      return;
    }
    if (pw.text.length < 6) {
      setState(() => err = 'Password needs 6+ characters.');
      return;
    }
    AppState.I.login();
    Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: AuroraBg(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, pad.top + 8, 20, pad.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GlassCircle(Icons.arrow_back_ios_new_rounded, label: 'Back', size: 42, onTap: () => Navigator.maybePop(context)),
                  const Spacer(),
                  Text('umigo', style: ds(22, c: UC.ink, ls: -1)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('Welcome back'),
                        const SizedBox(height: 8),
                        const HeroTitle('Your fans ', 'missed', tail: ' you', size: 36),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            err ?? 'Log in to keep the streak going.',
                            key: ValueKey(err),
                            style: ts(14.5, w: FontWeight.w600, c: err != null ? UC.red : UC.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .75),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: UC.primary.withValues(alpha: .15), blurRadius: 30, offset: const Offset(0, 12))],
                    ),
                    alignment: Alignment.center,
                    child: Mascot(mood: mood, look: (id.text.length / 7 - 1).clamp(-1, 1).toDouble(), size: 92),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SlideSegmented(
                items: const ['Phone', 'Email'],
                value: tab,
                onChanged: (v) => setState(() {
                  tab = v;
                  err = null;
                }),
              ),
              const SizedBox(height: 18),
              StaggerIn(
                index: 0,
                child: FieldBox(
                  label: tab == 'Phone' ? 'Mobile number' : 'Email address',
                  controller: id,
                  focus: fId,
                  hint: tab == 'Phone' ? '98765 43210' : 'you@example.com',
                  type: tab == 'Phone' ? TextInputType.phone : TextInputType.emailAddress,
                  prefix: tab == 'Phone'
                      ? Text(
                          '+91',
                          style: ts(16, w: FontWeight.w800, c: UC.deep),
                        )
                      : null,
                  error: err != null && !fPw.hasFocus,
                  onChanged: (_) => setState(() => err = null),
                ),
              ),
              const SizedBox(height: 14),
              StaggerIn(
                index: 1,
                child: FieldBox(
                  label: 'Password',
                  controller: pw,
                  focus: fPw,
                  obscure: !showPw,
                  hint: '••••••••',
                  onChanged: (_) => setState(() => err = null),
                  suffix: IconButton(
                    tooltip: showPw ? 'Hide password' : 'Show password',
                    onPressed: () => setState(() => showPw = !showPw),
                    icon: Icon(showPw ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: UC.muted, size: 21),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Switch.adaptive(value: keep, activeTrackColor: UC.primary, onChanged: (v) => setState(() => keep = v)),
                  const SizedBox(width: 4),
                  Text('Keep me logged in', style: ts(14, w: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => toast(context, 'Demo: a reset code would be sent by SMS.'),
                    child: Text(
                      'Forgot?',
                      style: ts(14, w: FontWeight.w800, c: UC.deep),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PrimaryButton('Log in', icon: Icons.arrow_forward_rounded, dark: true, onTap: submit),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: Divider(color: UC.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: ts(13, w: FontWeight.w600, c: UC.muted),
                    ),
                  ),
                  Expanded(child: Divider(color: UC.line)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _social('Google', Icons.g_mobiledata_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _social('Apple', Icons.apple_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _social('Guest', Icons.person_outline_rounded)),
                ],
              ),
              const SizedBox(height: 20),
              Pressable(
                onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                label: 'Create an account',
                child: Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'New to Umigo? ',
                      style: ts(14.5, w: FontWeight.w600, c: UC.muted),
                      children: [
                        TextSpan(
                          text: 'Create an account',
                          style: ts(14.5, w: FontWeight.w800, c: UC.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _social(String label, IconData icon) => SoftCard(
    radius: 99,
    padding: const EdgeInsets.symmetric(vertical: 13),
    onTap: () {
      AppState.I.login();
      Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
    },
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: UC.ink),
        const SizedBox(width: 6),
        Text(
          label,
          style: ts(14, w: FontWeight.w800, c: UC.ink),
        ),
      ],
    ),
  );
}
