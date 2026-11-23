import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../data/demo_data.dart';
import '../moderation/chat_filter.dart';
import '../state/app_state.dart';
import 'token_api.dart';

enum LiveEventType { chat, gift, join, like, system, mod }

class LiveEvent {
  final LiveEventType type;
  final String name;
  final int lv;
  String text;
  final String giftId;
  final int qty;
  final bool mine;
  final String id;
  final String senderId; // LiveKit identity of whoever wrote it (for host actions)
  bool masked;
  LiveEvent(
    this.type,
    this.name, {
    this.lv = 1,
    this.text = '',
    this.giftId = '',
    this.qty = 1,
    this.mine = false,
    String? id,
    this.senderId = '',
    this.masked = false,
  }) : id = id ?? _newId();

  static final _r = Random();
  static String _newId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_r.nextInt(1 << 20).toRadixString(36)}';

  Map<String, dynamic> toJson() => {'t': type.name, 'id': id, 'n': name, 'lv': lv, 'x': text, 'g': giftId, 'q': qty};

  static LiveEvent? fromJson(Map<String, dynamic> j, String sender) {
    final t = LiveEventType.values.where((e) => e.name == j['t']).firstOrNull;
    if (t == null || t == LiveEventType.mod || t == LiveEventType.system) return null;
    return LiveEvent(
      t,
      '${j['n'] ?? 'Someone'}',
      lv: (j['lv'] ?? 1) as int,
      text: '${j['x'] ?? ''}',
      giftId: '${j['g'] ?? ''}',
      qty: (j['q'] ?? 1) as int,
      id: j['id']?.toString(),
      senderId: '${j['s'] ?? sender}',
    );
  }

  int get coins => type == LiveEventType.gift ? giftById(giftId).price * qty : 0;
}

/// A moderation notice shown as a toast to this user.
class ModNotice {
  final String text;
  final bool bad;
  ModNotice(this.text, {this.bad = true});
}

const guardIdentity = 'umi-guard';

/// One live room, for a host or a viewer.
///
/// Real mode: connects to your self-hosted LiveKit server. Video/audio go over
/// WebRTC. Chat goes to the Umi Guard moderator bot (if it is in the room), which
/// filters it and re-broadcasts it; gifts, likes and joins go straight to the room.
/// Demo mode (no server set): local camera for hosts, simulated viewers and a
/// simulated guard so moderation can be tried.
class LiveSession extends ChangeNotifier {
  LiveSession.host({required this.title, required this.tag})
    : isHost = true,
      roomName = 'live_${AppState.I.userId}',
      hostName = AppState.I.firstName,
      demoHost = null;

  LiveSession.viewer({required this.roomName, required this.hostName, this.demoHost, this.title = ''}) : isHost = false, tag = '';

  final bool isHost;
  final String roomName;
  final String hostName;
  final Host? demoHost;
  String title;
  String tag;

  bool get demo => !AppState.I.serverConfigured || demoHost != null;
  String get hostIdentity => roomName.startsWith('live_') ? roomName.substring(5) : '';

  Room? room;
  EventsListener<RoomEvent>? _listener;
  LocalVideoTrack? localVideo;
  VideoTrack? remoteVideo;
  bool connecting = true;
  String? error;
  bool ended = false;
  String? endReason;
  bool micOn = true;
  bool camFront = true;
  String myIdentity = '';

  int viewers = 0;
  int likes = 0;
  int diamondsEarned = 0;
  int giftersCount = 0;
  final Set<String> _gifters = {};
  final List<LiveEvent> events = [];
  final _giftCtl = StreamController<LiveEvent>.broadcast();
  Stream<LiveEvent> get gifts => _giftCtl.stream;
  final _likeCtl = StreamController<void>.broadcast();
  Stream<void> get likeTaps => _likeCtl.stream;
  final _noticeCtl = StreamController<ModNotice>.broadcast();
  Stream<ModNotice> get notices => _noticeCtl.stream;

  // ---- moderation state ----
  bool guardOn = false;
  bool videoBlocked = false;
  String videoBlockReason = '';
  DateTime? mutedUntil;
  int slowModeSec = 0;
  List<String> customWords = [];
  int removedCount = 0; // messages Umi Guard stopped in this live
  final List<String> modLog = []; // newest first, shown to the host
  final _limiter = ChatRateLimiter();
  final Map<String, DateTime> _mutedUsers = {}; // demo/guardless fallback
  bool get chatMuted => mutedUntil != null && DateTime.now().isBefore(mutedUntil!);

  Timer? _bot;
  final _rnd = Random();
  DateTime startedAt = DateTime.now();

  Future<void> start() async {
    events.add(
      LiveEvent(
        LiveEventType.system,
        'Umigo',
        text: isHost ? 'You are live! Be kind, follow the community rules.' : 'Welcome! Be kind, no spam. Gifts help $hostName climb the daily rank.',
      ),
    );
    try {
      if (demo) {
        await _startDemo();
      } else {
        await _startReal();
      }
    } catch (e) {
      error = '$e'.replaceFirst('Exception: ', '');
      if (isHost) {
        try {
          localVideo ??= await LocalVideoTrack.createCameraTrack(const CameraCaptureOptions());
        } catch (_) {}
      }
    }
    connecting = false;
    startedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> _startReal() async {
    final me = AppState.I;
    myIdentity = isHost ? me.userId : '${me.userId}~${_rnd.nextInt(99999)}';
    final grant = await TokenApi.token(room: roomName, identity: myIdentity, name: me.firstName, host: isHost, title: title, tag: tag);
    final r = Room(roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
    room = r;
    final l = r.createListener();
    _listener = l;
    l
      ..on<ParticipantConnectedEvent>((e) {
        if (e.participant.identity == guardIdentity) _setGuard(true);
        _recount();
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        if (e.participant.identity == guardIdentity) _setGuard(false);
        if (!isHost && e.participant.identity == hostIdentity) {
          remoteVideo = null;
          ended = true;
          endReason ??= '$hostName ended the live.';
        }
        _recount();
      })
      ..on<TrackSubscribedEvent>((e) {
        if (e.track is VideoTrack && e.participant.identity != guardIdentity) {
          remoteVideo = e.track as VideoTrack;
          notifyListeners();
        }
      })
      ..on<TrackUnsubscribedEvent>((e) {
        if (e.track == remoteVideo) {
          remoteVideo = null;
          notifyListeners();
        }
      })
      ..on<DataReceivedEvent>((e) => _onData(e))
      ..on<RoomDisconnectedEvent>((e) {
        if (!isHost) ended = true;
        if (e.reason == DisconnectReason.participantRemoved) endReason ??= 'You were removed from this live.';
        if (e.reason == DisconnectReason.roomDeleted) endReason ??= 'This live was ended.';
        notifyListeners();
      });

    await r.connect(grant.url, grant.token);
    myIdentity = r.localParticipant?.identity ?? myIdentity; // the server may normalise it
    if (r.remoteParticipants.values.any((p) => p.identity == guardIdentity)) _setGuard(true);
    if (isHost) {
      try {
        await r.localParticipant?.setCameraEnabled(true, cameraCaptureOptions: const CameraCaptureOptions(cameraPosition: CameraPosition.front));
        await r.localParticipant?.setMicrophoneEnabled(true);
      } catch (e) {
        error = 'Camera/mic blocked: $e';
      }
      localVideo = r.localParticipant?.videoTrackPublications.firstOrNull?.track;
    } else {
      for (final p in r.remoteParticipants.values) {
        if (p.identity == guardIdentity) continue;
        for (final pub in p.videoTrackPublications) {
          if (pub.track != null) remoteVideo = pub.track;
        }
      }
      _send(LiveEvent(LiveEventType.join, AppState.I.firstName, lv: AppState.I.level, text: 'joined the room'));
    }
    _recount();
  }

  void _setGuard(bool on) {
    if (guardOn == on) return;
    guardOn = on;
    if (on) events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: 'is moderating chat and video in this live'));
    notifyListeners();
  }

  void _recount() {
    final r = room;
    if (r == null) return;
    viewers = r.remoteParticipants.values.where((p) => p.identity != guardIdentity && p.identity != hostIdentity).length + (isHost ? 0 : 1);
    notifyListeners();
  }

  void _onData(DataReceivedEvent e) {
    if (e.topic != 'umigo') return;
    Map<String, dynamic> j;
    try {
      j = jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final sender = e.participant?.identity ?? e.participantIdentity;
    if (j['t'] == 'mod') {
      if (sender == guardIdentity) _onMod(j);
      return;
    }
    // with a guard in the room, chat is only trusted when the guard relays it
    if (j['t'] == 'chat' && guardOn && sender != guardIdentity) return;
    final ev = LiveEvent.fromJson(j, sender);
    if (ev != null) _push(ev);
  }

  void _onMod(Map<String, dynamic> m) {
    final a = '${m['a']}';
    final x = '${m['x'] ?? ''}';
    final who = '${m['who'] ?? ''}';
    final isMe = who.isNotEmpty && who == myIdentity;
    final name = '${m['n'] ?? 'A viewer'}';
    switch (a) {
      case 'guard_on':
        _setGuard(true);
      case 'warn':
      case 'info':
        _noticeCtl.add(ModNotice(x, bad: a == 'warn'));
      case 'removed':
        events.removeWhere((ev) => ev.id == '${m['id']}');
        removedCount++;
        _noticeCtl.add(ModNotice(x));
      case 'mask':
        for (final ev in events.where((ev) => ev.id == '${m['id']}')) {
          ev.text = x;
          ev.masked = true;
        }
      case 'muted':
        final sec = (m['sec'] ?? 300) as int;
        if (isMe) {
          mutedUntil = DateTime.now().add(Duration(seconds: sec));
          _noticeCtl.add(ModNotice('You are muted for ${sec ~/ 60} min. $x'));
        }
        _log('Muted $name · $x');
        events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: 'muted $name'));
      case 'unmuted':
        if (isMe) mutedUntil = null;
        _log('Unmuted $name');
      case 'kicked':
        _log('Removed $name · $x');
        if (isMe) {
          ended = true;
          endReason = 'You were removed: $x';
        } else {
          events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: 'removed $name'));
        }
      case 'slow':
        slowModeSec = (m['sec'] ?? 0) as int;
        events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: x));
      case 'video_block':
        videoBlocked = true;
        videoBlockReason = x;
        _log('Video paused: nudity detected (strike ${m['strikes'] ?? 1}/3)');
        if (isHost) _noticeCtl.add(ModNotice('Umi Guard paused your camera: nudity was detected. 3 strikes ends your live.'));
      case 'video_ok':
        videoBlocked = false;
      case 'video_resume':
        if (isHost) {
          videoBlocked = false; // the host sees their camera again; viewers stay blurred until it is clean
          _resumeCamera();
        }
      case 'end':
        ended = true;
        endReason = x;
        _log('Live ended: $x');
    }
    notifyListeners();
  }

  void _log(String s) {
    modLog.insert(0, s);
    if (modLog.length > 50) modLog.removeLast();
  }

  Future<void> _resumeCamera() async {
    try {
      final pub = room?.localParticipant?.videoTrackPublications.firstOrNull;
      if (pub == null || !pub.muted) return;
      await pub.unmute();
      localVideo = room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
      _noticeCtl.add(ModNotice('Camera is back on. Keep it clean!', bad: false));
    } catch (_) {}
    notifyListeners();
  }

  // ---------------- demo mode ----------------
  Future<void> _startDemo() async {
    myIdentity = 'me';
    guardOn = true;
    if (isHost) {
      try {
        localVideo = await LocalVideoTrack.createCameraTrack(const CameraCaptureOptions());
      } catch (e) {
        error = 'Camera not available here. Showing a photo instead.';
      }
      viewers = 0;
    } else {
      viewers = 1200 + _rnd.nextInt(11000);
      events.addAll([
        LiveEvent(LiveEventType.chat, 'Meera', lv: 24, text: 'your voice is magic', senderId: 'meera'),
        LiveEvent(LiveEventType.chat, 'arjun_07', lv: 8, text: 'play Kesariya next please', senderId: 'arjun_07'),
        LiveEvent(LiveEventType.gift, 'Rahul_K', lv: 41, giftId: 'rose', qty: 10, senderId: 'rahul'),
      ]);
    }
    events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: 'is moderating chat and video in this live'));
    _bot = Timer.periodic(Duration(milliseconds: isHost ? 2600 : 2200), (_) => _botTick());
  }

  static const _badBotLines = ['dm me on whatsapp 98765 43210', 'f4ck this song', 'free coins at www.coins-hack.xyz', 'send nudes', 'tu chutiya hai'];

  void _botTick() {
    final b = botViewers[_rnd.nextInt(botViewers.length)];
    final roll = _rnd.nextDouble();
    if (isHost) viewers += _rnd.nextInt(4);
    if (!isHost) viewers += _rnd.nextInt(7) - 2;
    final sid = b.$1.toLowerCase();
    if (_mutedUsers[sid]?.isAfter(DateTime.now()) ?? false) return;
    if (roll < 0.08) {
      // a bad message: the simulated guard removes or masks it, like the real one
      final r = ChatFilter.check(_badBotLines[_rnd.nextInt(_badBotLines.length)], customWords: customWords);
      if (r.action == ModAction.block) {
        removedCount++;
        _log('Removed a message from ${b.$1} · ${r.reason}');
        events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: 'removed a message from ${b.$1} (${r.reason})'));
        notifyListeners();
      } else {
        _push(LiveEvent(LiveEventType.chat, b.$1, lv: b.$2, text: r.text, senderId: sid, masked: true));
      }
    } else if (roll < 0.55) {
      _push(LiveEvent(LiveEventType.chat, b.$1, lv: b.$2, text: botLines[_rnd.nextInt(botLines.length)], senderId: sid));
    } else if (roll < 0.75) {
      final cheap = ['rose', 'heart', 'coffee', 'star', 'crown', 'rocket'];
      final g = cheap[min(_rnd.nextInt(cheap.length), _rnd.nextInt(cheap.length))];
      _push(LiveEvent(LiveEventType.gift, b.$1, lv: b.$2, giftId: g, qty: [1, 1, 3, 10][_rnd.nextInt(4)], senderId: sid));
    } else if (roll < 0.9) {
      _push(LiveEvent(LiveEventType.join, b.$1, lv: b.$2, text: 'joined the room', senderId: sid));
    } else {
      likes += 5;
      _likeCtl.add(null);
      notifyListeners();
    }
  }

  void _push(LiveEvent e) {
    events.add(e);
    if (events.length > 80) events.removeAt(1);
    if (e.type == LiveEventType.gift) {
      _gifters.add(e.name);
      giftersCount = _gifters.length;
      final d = e.coins ~/ 2; // host gets 50% of coin value as diamonds
      diamondsEarned += d;
      if (isHost) AppState.I.addDiamonds(d);
      _giftCtl.add(e);
    }
    if (e.type == LiveEventType.like) {
      likes++;
      _likeCtl.add(null);
    }
    notifyListeners();
  }

  void _send(LiveEvent e, {String topic = 'umigo', List<String>? to}) {
    final r = room;
    if (r == null) return;
    r.localParticipant
        ?.publishData(utf8.encode(jsonEncode(e.toJson())), reliable: e.type != LiveEventType.like, topic: topic, destinationIdentities: to)
        .catchError((_) {});
  }

  void _sendRaw(Map<String, dynamic> m, String topic) {
    final r = room;
    if (r == null || !guardOn) return;
    r.localParticipant?.publishData(utf8.encode(jsonEncode(m)), reliable: true, topic: topic, destinationIdentities: [guardIdentity]).catchError((_) {});
  }

  /// Returns a reason when the message was not sent.
  String? sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    if (chatMuted) {
      final left = mutedUntil!.difference(DateTime.now());
      return 'You are muted for ${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    final rl = _limiter.check(t, slowSec: isHost ? 0 : slowModeSec);
    if (rl != null) return rl;
    final r = ChatFilter.check(t, customWords: customWords);
    if (r.action == ModAction.block) {
      removedCount++;
      _log('Stopped your message · ${r.reason}');
      return 'Umi Guard stopped it: ${r.reason}';
    }
    final e = LiveEvent(
      LiveEventType.chat,
      isHost ? '$hostName (host)' : AppState.I.firstName,
      lv: AppState.I.level,
      text: r.text,
      mine: true,
      senderId: myIdentity,
      masked: r.action == ModAction.mask,
    );
    _push(e);
    if (guardOn && room != null) {
      _send(e, topic: 'umigo-mod-in', to: [guardIdentity]); // guard filters + relays to everyone
    } else {
      _send(e);
    }
    return r.action == ModAction.mask ? 'Some words were hidden by Umi Guard' : null;
  }

  /// Returns false when the wallet is short.
  bool sendGift(Gift g, int qty) {
    if (!AppState.I.spend(g.price * qty)) return false;
    final e = LiveEvent(LiveEventType.gift, AppState.I.firstName, lv: AppState.I.level, giftId: g.id, qty: qty, mine: true, senderId: myIdentity);
    _push(e);
    _send(e);
    return true;
  }

  void sendLike() {
    final e = LiveEvent(LiveEventType.like, AppState.I.firstName, mine: true);
    likes++;
    _likeCtl.add(null);
    notifyListeners();
    _send(e);
  }

  // ---------------- host moderation tools ----------------
  void hostAction(String cmd, LiveEvent target, {int sec = 600}) {
    if (!isHost) return;
    final who = target.senderId;
    if (room != null && guardOn) {
      _sendRaw({'cmd': cmd, 'who': who, 'n': target.name, 'sec': sec}, 'umigo-mod-cmd');
    } else {
      // demo / no guard: apply locally
      _mutedUsers[who] = DateTime.now().add(Duration(seconds: cmd == 'unmute' ? 0 : sec * (cmd == 'mute' ? 1 : 100)));
      events.removeWhere((e) => e.senderId == who && e.type == LiveEventType.chat && cmd != 'mute' && cmd != 'unmute');
      final verb = {'mute': 'muted', 'unmute': 'unmuted', 'kick': 'removed', 'ban': 'banned'}[cmd] ?? cmd;
      events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: '$verb ${target.name}'));
      _log('${verb[0].toUpperCase()}${verb.substring(1)} ${target.name}');
    }
    notifyListeners();
  }

  void setSlowMode(int sec) {
    slowModeSec = sec;
    if (room != null && guardOn) {
      _sendRaw({'cmd': 'slow', 'sec': sec}, 'umigo-mod-cmd');
    } else {
      events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: sec == 0 ? 'turned slow mode off' : 'set slow mode to ${sec}s'));
    }
    notifyListeners();
  }

  void setCustomWords(List<String> words) {
    customWords = words.map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
    _sendRaw({'cmd': 'words', 'words': customWords}, 'umigo-mod-cmd');
    notifyListeners();
  }

  void report(String reason, {String who = ''}) {
    _sendRaw({'x': reason, 'who': who.isEmpty ? hostIdentity : who}, 'umigo-report');
    if (room == null || !guardOn) _noticeCtl.add(ModNotice('Thanks, Umi Guard got your report.', bad: false));
  }

  Future<void> toggleMic() async {
    micOn = !micOn;
    if (room != null) await room!.localParticipant?.setMicrophoneEnabled(micOn);
    notifyListeners();
  }

  Future<void> flipCamera() async {
    final t = localVideo;
    if (t == null) return;
    camFront = !camFront;
    try {
      await t.setCameraPosition(camFront ? CameraPosition.front : CameraPosition.back);
    } catch (_) {}
    notifyListeners();
  }

  Duration get elapsed => DateTime.now().difference(startedAt);

  Future<void> end() async {
    _bot?.cancel();
    await _listener?.dispose();
    try {
      await room?.disconnect();
    } catch (_) {}
    if (demo) {
      try {
        await localVideo?.stop();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    end();
    _giftCtl.close();
    _likeCtl.close();
    _noticeCtl.close();
    super.dispose();
  }
}
