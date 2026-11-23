import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/demo_data.dart';
import '../live/token_api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'live_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String cat = 'For you';
  List<LiveRoomInfo> realRooms = [];
  String? serverError;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _load());
    AppState.I.addListener(_onState);
  }

  void _onState() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    if (!AppState.I.serverConfigured) {
      if (realRooms.isNotEmpty || serverError != null) {
        setState(() {
          realRooms = [];
          serverError = null;
        });
      }
      return;
    }
    try {
      final r = await TokenApi.rooms();
      if (!mounted) return;
      setState(() {
        realRooms = r.where((x) => x.hostId != AppState.I.userId).toList();
        serverError = null;
      });
    } catch (e) {
      if (mounted) setState(() => serverError = 'Live server not reachable');
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    AppState.I.removeListener(_onState);
    super.dispose();
  }

  String get greeting {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  }

  void openDemo(Host h) => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveViewerScreen.demo(h)));

  @override
  Widget build(BuildContext context) {
    final st = AppState.I;
    final pad = MediaQuery.paddingOf(context);
    final list = cat == 'For you' || cat == 'Nearby' || cat == 'New' ? demoHosts : demoHosts.where((h) => h.cat == cat).toList();
    return RefreshIndicator(
      color: UC.primary,
      onRefresh: _load,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, pad.top + 10, 12, 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$greeting, ${st.firstName}', style: ts(12.5, w: FontWeight.w700, c: UC.muted)),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('umigo', style: ts(26, w: FontWeight.w800, ls: -1.2)),
                    Container(width: 7, height: 7, margin: const EdgeInsets.only(left: 1), decoration: const BoxDecoration(color: UC.accent, shape: BoxShape.circle)),
                  ]),
                ]),
              ),
              CoinPill(st.coins, onTap: () => Navigator.pushNamed(context, '/coins')),
              const SizedBox(width: 8),
              Stack(children: [
                Material(
                  color: UC.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pushNamed(context, '/inbox'),
                    child: const SizedBox(width: 40, height: 40, child: Icon(Icons.notifications_none_rounded, size: 22)),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: UC.primary, shape: BoxShape.circle, border: Border.all(color: UC.surface, width: 2)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.only(left: 12, right: 6),
              decoration: BoxDecoration(color: UC.surface, borderRadius: BorderRadius.circular(15)),
              child: Row(children: [
                const Icon(Icons.search_rounded, color: UC.muted, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Search hosts, IDs, tags', style: ts(14, w: FontWeight.w600, c: UC.muted))),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.tune_rounded, size: 17, color: UC.deep),
                ),
              ]),
            ),
          ),
        ),
        // stories
        SliverToBoxAdapter(
          child: SizedBox(
            height: 98,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              children: [
                _story(
                  label: 'Go live',
                  onTap: () => Navigator.pushNamed(context, '/golive'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: UC.soft,
                      shape: BoxShape.circle,
                      border: Border.all(color: UC.primary, width: 2),
                    ),
                    child: const Icon(Icons.add_rounded, color: UC.primary, size: 26),
                  ),
                ),
                for (final r in realRooms)
                  _story(
                    label: r.hostName,
                    live: true,
                    onTap: () => _openReal(r),
                    child: Avatar(name: r.hostName, size: 62),
                  ),
                for (final s in demoStories)
                  _story(
                    label: s.name,
                    live: s.live,
                    onTap: () => openDemo(demoHosts.firstWhere((h) => h.name == s.name, orElse: () => demoHosts.first)),
                    child: Image.asset(s.img, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              children: [
                for (final k in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => cat = k),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: k == cat ? UC.deep : UC.surface, borderRadius: BorderRadius.circular(99)),
                        child: Text(k, style: ts(13, w: FontWeight.w800, c: k == cat ? Colors.white : UC.ink)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (serverError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text('$serverError · showing demo rooms', style: ts(12, w: FontWeight.w700, c: UC.accentText)),
            ),
          ),
        if (realRooms.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 12, 8),
              child: Row(children: [
                const LiveBadge(),
                const SizedBox(width: 8),
                Text('Live on your server', style: ts(15, w: FontWeight.w800)),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            sliver: SliverList.separated(
              itemCount: realRooms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _realCard(realRooms[i]),
            ),
          ),
        ],
        SliverToBoxAdapter(child: _featured()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 212),
            itemCount: list.length,
            itemBuilder: (_, i) => _card(list[i]),
          ),
        ),
      ]),
    );
  }

  void _openReal(LiveRoomInfo r) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LiveViewerScreen.real(room: r.name, hostName: r.hostName, title: r.title)),
      );

  Widget _story({required String label, required Widget child, bool live = false, VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 62,
          margin: const EdgeInsets.only(right: 10),
          child: Column(children: [
            Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: live ? UC.brandGradient : null, color: live ? null : UC.line),
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                  child: ClipOval(child: child),
                ),
              ),
              if (live)
                Positioned(
                  bottom: -4,
                  child: Container(
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(color: UC.primary, borderRadius: BorderRadius.circular(5), border: Border.all(color: Colors.white, width: 2)),
                    child: Text('LIVE', style: ts(8, w: FontWeight.w800, c: Colors.white, ls: .8)),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11.5, w: FontWeight.w700)),
          ]),
        ),
      );

  Widget _featured() => GestureDetector(
        onTap: () => openDemo(const Host('ava', 'Ava.s', 'assets/img/ava.jpg', 'Sunset PK: Ava vs Kabir', 'Goa', '18.2K', 'Music')),
        child: Container(
          height: 168,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: UC.inkA(.16), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/img/beach.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -0.4)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [UC.inkA(.82), UC.inkA(.35), UC.inkA(0)], stops: const [0, .55, 1]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const LiveBadge(scale: 1.1),
                  const SizedBox(width: 5),
                  Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: UC.accent, borderRadius: BorderRadius.circular(7)),
                    child: Text('PK NIGHT · 2× POINTS', style: ts(10.5, w: FontWeight.w800, c: UC.ink)),
                  ),
                ]),
                const Spacer(),
                SizedBox(width: 200, child: Text('Sunset PK: Ava vs Kabir', style: ts(20, w: FontWeight.w800, c: Colors.white, ls: -0.5, h: 1.2))),
                const SizedBox(height: 8),
                Row(children: [
                  SizedBox(
                    width: 52,
                    height: 22,
                    child: Stack(children: [
                      for (var i = 0; i < 3; i++)
                        Positioned(
                          left: i * 15.0,
                          child: Avatar(img: ['assets/img/meera.jpg', 'assets/img/rahul.jpg', 'assets/img/sana.jpg'][i], size: 22, border: Colors.white),
                        ),
                    ]),
                  ),
                  Text('18.2K watching', style: ts(12, w: FontWeight.w700, c: Colors.white.withValues(alpha: .9))),
                  const Spacer(),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                    child: Text('Join', style: ts(13, w: FontWeight.w800, c: UC.primary)),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      );

  Widget _card(Host h) => GestureDetector(
        onTap: () => openDemo(h),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: UC.surface,
            boxShadow: [BoxShadow(color: UC.inkA(.12), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Stack(fit: StackFit.expand, children: [
            Hero(tag: 'live_${h.id}', child: Image.asset(h.img, fit: BoxFit.cover, alignment: Alignment(0, h.posY))),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [UC.inkA(.3), UC.inkA(0), UC.inkA(0), UC.inkA(.82)],
                  stops: const [0, .28, .52, 1],
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Row(children: [
                const LiveBadge(),
                const SizedBox(width: 4),
                Container(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(color: UC.inkA(.5), borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    const Icon(Icons.visibility_outlined, size: 11, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(h.views, style: ts(10.5, w: FontWeight.w800, c: Colors.white)),
                  ]),
                ),
              ]),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13.5, w: FontWeight.w800, c: Colors.white)),
                const SizedBox(height: 4),
                Row(children: [
                  Avatar(img: h.img, size: 18, border: Colors.white, borderW: 1.5),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text('${h.name} · ${h.where}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(11.5, w: FontWeight.w700, c: Colors.white.withValues(alpha: .92))),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      );

  Widget _realCard(LiveRoomInfo r) => GestureDetector(
        onTap: () => _openReal(r),
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [UC.deep, UC.primary]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Avatar(name: r.hostName, size: 48, border: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.title.isEmpty ? '${r.hostName} is live' : r.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15, w: FontWeight.w800, c: Colors.white)),
                const SizedBox(height: 3),
                Text('${r.hostName}${r.tag.isEmpty ? '' : ' · #${r.tag}'} · ${r.viewers} watching',
                    style: ts(12, w: FontWeight.w700, c: Colors.white.withValues(alpha: .85))),
              ]),
            ),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
              child: Text('Watch', style: ts(13, w: FontWeight.w800, c: UC.primary)),
            ),
          ]),
        ),
      );
}
