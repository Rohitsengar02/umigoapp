import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/mascot.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // full-bleed top card with the mascot
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(12, pad.top + 4, 12, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [UC.soft, UC.accentSoft]),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded)),
                  ),
                  Mascot(mood: mood, look: (id.text.length / 7 - 1).clamp(-1, 1).toDouble(), size: 150),
                  const SizedBox(height: 8),
                  TextReveal('Welcome back!', style: ds(30), align: TextAlign.center, delay: const Duration(milliseconds: 200)),
                  const SizedBox(height: 4),
                  Text(
                    err ?? 'Your fans missed you.',
                    style: ts(14, w: FontWeight.w700, c: err != null ? UC.red : UC.muted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Segmented(
                      items: const ['Phone', 'Email'],
                      value: tab,
                      onChanged: (v) => setState(() {
                        tab = v;
                        err = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FieldBox(
                    label: tab == 'Phone' ? 'Mobile number' : 'Email address',
                    controller: id,
                    focus: fId,
                    hint: tab == 'Phone' ? '98765 43210' : 'you@example.com',
                    type: tab == 'Phone' ? TextInputType.phone : TextInputType.emailAddress,
                    prefix: tab == 'Phone'
                        ? Text(
                            '+91',
                            style: ts(15, w: FontWeight.w800, c: UC.deep),
                          )
                        : null,
                    error: err != null && !fPw.hasFocus,
                    onChanged: (_) => setState(() => err = null),
                  ),
                  const SizedBox(height: 12),
                  FieldBox(
                    label: 'Password',
                    controller: pw,
                    focus: fPw,
                    obscure: !showPw,
                    hint: '••••••••',
                    onChanged: (_) => setState(() => err = null),
                    suffix: IconButton(
                      tooltip: showPw ? 'Hide password' : 'Show password',
                      onPressed: () => setState(() => showPw = !showPw),
                      icon: Icon(showPw ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: UC.muted, size: 20),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: keep,
                        activeColor: UC.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (v) => setState(() => keep = v ?? true),
                      ),
                      Text('Keep me logged in', style: ts(13, w: FontWeight.w700)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => toast(context, 'Demo: a reset code would be sent by SMS.'),
                        child: Text(
                          'Forgot password?',
                          style: ts(13, w: FontWeight.w800, c: UC.deep),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  PrimaryButton('Log in', onTap: submit),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: UC.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or continue with',
                          style: ts(12, w: FontWeight.w700, c: UC.muted),
                        ),
                      ),
                      const Expanded(child: Divider(color: UC.line)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _social('Google', Icons.g_mobiledata_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _social('Apple', Icons.apple_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _social('Guest', Icons.person_outline_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'New to Umigo? ',
                        style: ts(13.5, w: FontWeight.w600, c: UC.muted),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/register'),
                        child: Text(
                          'Create an account',
                          style: ts(13.5, w: FontWeight.w800, c: UC.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _social(String label, IconData icon) => SizedBox(
    height: 48,
    child: OutlinedButton.icon(
      onPressed: () {
        AppState.I.login();
        Navigator.pushNamedAndRemoveUntil(context, '/app', (_) => false);
      },
      icon: Icon(icon, size: 22, color: UC.ink),
      label: Text(
        label,
        style: ts(13, w: FontWeight.w800, c: UC.ink),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: UC.line, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: EdgeInsets.zero,
      ),
    ),
  );
}
