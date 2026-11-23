import 'package:material_ui/material_ui.dart';

import '../live/token_api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Point the app at your own LiveKit + token server (e.g. your Hostinger VPS).
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});
  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final url = TextEditingController(text: AppState.I.tokenUrl);
  String? status;
  bool checking = false;

  Future<void> test() async {
    AppState.I.setServer(url.text);
    if (!AppState.I.serverConfigured) {
      setState(() => status = 'Cleared. The app runs in demo mode.');
      return;
    }
    setState(() {
      checking = true;
      status = null;
    });
    final ok = await TokenApi.health();
    if (!mounted) return;
    setState(() {
      checking = false;
      status = ok ? 'Connected. Go live and others will see you on Home.' : 'Could not reach ${AppState.I.tokenUrl}/health';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Column(children: [
        SizedBox(height: pad.top),
        const TopBar('Live server'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Text(
              'Umigo uses the free, open-source LiveKit server that you host yourself. '
              'Paste the address of the Umigo token server that runs next to it.',
              style: ts(13.5, w: FontWeight.w600, c: UC.muted, h: 1.45),
            ),
            const SizedBox(height: 14),
            FieldBox(label: 'Token server URL', controller: url, hint: 'https://live.yourdomain.com/api', type: TextInputType.url),
            const SizedBox(height: 6),
            Text('Leave empty to use demo mode (simulated viewers and gifts).', style: ts(12, w: FontWeight.w600, c: UC.muted)),
            const SizedBox(height: 14),
            PrimaryButton(checking ? 'Checking…' : 'Save & test', onTap: checking ? null : test),
            if (status != null) ...[
              const SizedBox(height: 10),
              Text(status!, style: ts(13.5, w: FontWeight.w800, c: status!.startsWith('Connected') ? UC.greenText : UC.accentText)),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('How to test a real live', style: ts(14.5, w: FontWeight.w800)),
                const SizedBox(height: 6),
                for (final s in [
                  '1. Run server/install.sh on your VPS (see README).',
                  '2. Put the same server URL on two phones.',
                  '3. Phone A: Go live. Phone B: Home › "Live on your server".',
                  '4. Chat, like and send gifts from B. A sees them and earns diamonds.',
                ])
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text(s, style: ts(12.5, w: FontWeight.w600, c: UC.ink, h: 1.4))),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
