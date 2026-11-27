import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../data/demo_data.dart';
import '../data/social_data.dart' show creatorById, LiveAccess;
import '../moderation/chat_filter.dart';
import '../moderation/nsfw_classifier.dart';
import '../state/app_state.dart';
import 'fx.dart';
import 'live_setup.dart';
export 'live_setup.dart';
import 'token_api.dart';

enum LiveEventType { chat, gift, join, like, system, mod, tip }

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

  int get coins => switch (type) {
    LiveEventType.gift => giftById(giftId).price * qty,
    LiveEventType.tip => qty, // a tip carries its coin amount in qty
    _ => 0,
  };
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
  LiveSession.host({required this.title, required this.tag, LiveSetup? setup})
    : isHost = true,
      setup = setup ?? LiveSetup(title: title, tag: tag),
      roomName = 'live_${AppState.I.userId}',
      hostName = AppState.I.firstName,
      demoHost = null;

  LiveSession.viewer({required this.roomName, required this.hostName, this.demoHost, this.title = '', LiveSetup? setup})
    : isHost = false,
      tag = '',
      setup = setup ?? (demoHost != null ? LiveSetup.forCreator(creatorById(demoHost.id)) : LiveSetup(tipsOn: false, goalOn: false));

  /// The host's choices: access, tip menu, gift goal. Viewers get it from the host.
  LiveSetup setup;

  /// Coins from gifts and tips during this session (for the gift goal).
  int goalCollected = 0;
  int get goalProgress => setup.goalStart + goalCollected;

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
  final Map<String, DateTime> _mutedUsers = {}; // userKey -> until; everyone drops their chat
  bool get chatMuted => mutedUntil != null && DateTime.now().isBefore(mutedUntil!);

  // In-app guard: when the server bot is not in the room, every phone filters the
  // chat it receives, and the host's phone is the referee (strikes, mute, remove, ban).
  bool get inAppGuard => !guardOn && room != null;

  /// Umi Guard is protecting this live, by the server bot or inside the app.
  bool get guardActive => guardOn || room != null;
  final Map<String, int> _strikes = {};
  final Map<String, DateTime> _banned = {};
  int _selfStrikes = 0;
  static String userKey(String id) => id.split('~').first;
  bool _isSilenced(String key) {
    final now = DateTime.now();
    return (_mutedUsers[key]?.isAfter(now) ?? false) || (_banned[key]?.isAfter(now) ?? false);
  }

  // On-phone video check (no server needed): the host's phone checks its own camera,
  // viewers' phones check the video they receive and blur it for themselves.
  bool selfBlur = false;
  bool get videoHidden => videoBlocked || selfBlur;
  Timer? _vg;
  bool _vgBusy = false, _vgPaused = false, _viewersBlurred = false;
  int _vgHits = 0, _vgClean = 0, _vgStrikes = 0;

  Timer? _bot;

  // Home thumbnail: the host's phone posts a small camera snapshot now and then.
  Timer? _thumb;
  String? _token;
  bool _thumbBusy = false;
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
    _startVideoGuard();
    notifyListeners();
  }

  Future<void> _startReal() async {
    final me = AppState.I;
    myIdentity = isHost ? me.userId : '${me.userId}~${_rnd.nextInt(99999)}';
    final grant = await TokenApi.token(
      room: roomName,
      identity: myIdentity,
      name: me.firstName,
      host: isHost,
      title: title,
      tag: tag,
      access: setup.access.name,
      fee: setup.access == LiveAccess.paid ? setup.entryFee : 0,
    );
    final r = Room(roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
    room = r;
    final l = r.createListener();
    _listener = l;
    l
      ..on<ParticipantConnectedEvent>((e) {
        if (e.participant.identity == guardIdentity) _setGuard(true);
        if (isHost) _sendSetup(e.participant.identity);
        if (isHost && inAppGuard) _greet(e.participant.identity, e.participant.name);
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
    _token = grant.token;
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
      LiveFx.I.attach(localVideo); // beauty, looks and AR run on the camera before it is sent
      Timer(const Duration(seconds: 4), _postThumb);
      _thumb = Timer.periodic(const Duration(seconds: 30), (_) => _postThumb());
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
    final senderName = e.participant?.name ?? '${j['n'] ?? 'A viewer'}';
    if (j['t'] == 'setup') {
      // only the host can describe the live
      if (!isHost && sender == hostIdentity && hostIdentity.isNotEmpty) {
        setup = LiveSetup.fromJson(j);
        notifyListeners();
      }
      return;
    }
    if (j['t'] == 'mod') {
      // moderation comes from the server bot or from the host's phone
      if (sender == guardIdentity || (sender == hostIdentity && hostIdentity.isNotEmpty)) _onMod(j);
      return;
    }
    if (j['t'] == 'strike' || j['t'] == 'report') {
      if (isHost && inAppGuard) _onPeerReport(j, sender, senderName);
      return;
    }
    var masked = false;
    if (j['t'] == 'chat') {
      if (guardOn) {
        // with the server bot in the room, chat is only trusted when the bot relays it
        if (sender != guardIdentity) return;
      } else {
        // in-app guard: this phone checks the message itself
        if (_isSilenced(userKey(sender))) return;
        final r = ChatFilter.check('${j['x'] ?? ''}', customWords: customWords);
        if (r.action == ModAction.block) {
          removedCount++;
          if (isHost) {
            _log('Removed a message from $senderName · ${r.reason}');
            _strike(sender, senderName, r.reason);
            notifyListeners();
          }
          return;
        }
        if (r.action == ModAction.mask) {
          j['x'] = r.text;
          masked = true;
          if (isHost && r.reason == 'abusive language') _strike(sender, senderName, r.reason);
        }
      }
    }
    final ev = LiveEvent.fromJson(j, sender);
    if (ev == null) return;
    ev.masked = masked;
    _push(ev);
  }

  // ---------------- in-app referee (host's phone) ----------------
  void _bcast(Map<String, dynamic> m, {List<String>? to, bool local = true}) {
    room?.localParticipant?.publishData(utf8.encode(jsonEncode(m)), reliable: true, topic: 'umigo', destinationIdentities: to).catchError((_) {});
    if (local) _onMod(m);
  }

  void _sendTo(Map<String, dynamic> m, List<String> to) {
    room?.localParticipant?.publishData(utf8.encode(jsonEncode(m)), reliable: true, topic: 'umigo', destinationIdentities: to).catchError((_) {});
  }

  /// A newcomer gets the live's access rules, tip menu and goal.
  void _sendSetup(String id) {
    final m = setup.toJson();
    if (m['goal'] != null) m['goal'] = {...m['goal'] as Map<String, dynamic>, 's': goalProgress};
    _sendTo(m, [id]);
  }

  /// A newcomer gets the live's current rules, or is sent away if banned.
  void _greet(String id, String name) {
    final k = userKey(id);
    if (_banned[k]?.isAfter(DateTime.now()) ?? false) {
      _sendTo({'t': 'mod', 'a': 'kicked', 'who': id, 'n': name, 'x': 'you are banned from this live'}, [id]);
      return;
    }
    if (slowModeSec > 0) _sendTo({'t': 'mod', 'a': 'slow', 'sec': slowModeSec, 'q': true}, [id]);
    if (customWords.isNotEmpty) _sendTo({'t': 'mod', 'a': 'words', 'words': customWords}, [id]);
    if (_viewersBlurred) _sendTo({'t': 'mod', 'a': 'video_block', 'x': 'Video paused by Umi Guard (community rules)', 'strikes': _vgStrikes}, [id]);
    final until = _mutedUsers[k];
    if (until != null && until.isAfter(DateTime.now())) {
      _sendTo({'t': 'mod', 'a': 'muted', 'who': id, 'n': name, 'sec': until.difference(DateTime.now()).inSeconds, 'q': true}, [id]);
    }
    _sendTo({'t': 'mod', 'a': 'info', 'x': 'Umi Guard is on. Keep the chat kind.'}, [id]);
  }

  void _strike(String identity, String name, String reason) {
    final k = userKey(identity);
    if (k == userKey(myIdentity) || k == hostIdentity) return;
    final n = (_strikes[k] ?? 0) + 1;
    _strikes[k] = n;
    if (n >= 5) {
      _kick(identity, name, 'repeated violations', ban: const Duration(hours: 1));
    } else if (n >= 3) {
      if (!_isSilenced(k)) _bcast({'t': 'mod', 'a': 'muted', 'who': identity, 'n': name, 'sec': 300, 'x': 'muted for 5 min: $reason'});
    } else {
      _sendTo({'t': 'mod', 'a': 'warn', 'who': identity, 'x': 'Warning $n/3: $reason'}, [identity]);
    }
  }

  void _kick(String identity, String name, String reason, {Duration? ban}) {
    if (userKey(identity) == hostIdentity) return;
    if (ban != null) _banned[userKey(identity)] = DateTime.now().add(ban);
    _bcast({'t': 'mod', 'a': 'kicked', 'who': identity, 'n': name, 'x': reason});
  }

  void _onPeerReport(Map<String, dynamic> j, String sender, String name) {
    final x = '${j['x'] ?? ''}';
    if (j['t'] == 'strike') {
      _log('Stopped a message from $name · $x');
      removedCount++;
      _strike(sender, name, x);
    } else {
      final about = '${j['who'] ?? ''}';
      _log('$name reported ${about.isEmpty ? 'the live' : about}: $x');
      _noticeCtl.add(ModNotice('$name reported a viewer: $x', bad: false));
    }
    notifyListeners();
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
        final until = DateTime.now().add(Duration(seconds: sec));
        if (who.isNotEmpty) _mutedUsers[userKey(who)] = until;
        if (isMe) {
          mutedUntil = until;
          _noticeCtl.add(ModNotice('You are muted for ${(sec / 60).ceil()} min. $x'));
        }
        if (m['q'] != true) {
          _log('Muted $name · $x');
          events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: 'muted $name'));
        }
      case 'unmuted':
        if (who.isNotEmpty) _mutedUsers.remove(userKey(who));
        if (isMe) mutedUntil = null;
        _log('Unmuted $name');
      case 'kicked':
        _log('Removed $name · $x');
        if (who.isNotEmpty) {
          final k = userKey(who);
          _mutedUsers[k] = DateTime.now().add(const Duration(hours: 1));
          events.removeWhere((ev) => ev.type == LiveEventType.chat && userKey(ev.senderId) == k);
        }
        if (isMe) {
          ended = true;
          endReason = 'You were removed: $x';
          room?.disconnect().catchError((_) {});
        } else {
          events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: 'removed $name'));
        }
      case 'words':
        if (!isHost) customWords = [for (final w in (m['words'] as List? ?? const [])) '$w'];
      case 'slow':
        slowModeSec = (m['sec'] ?? 0) as int;
        if (m['q'] != true) events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: x));
      case 'video_block':
        videoBlocked = true;
        videoBlockReason = x;
        _log('Video paused: nudity detected (strike ${m['strikes'] ?? 1}/3)');
        if (isHost) _noticeCtl.add(ModNotice('Umi Guard paused your camera: nudity was detected. 3 strikes ends your live.'));
      case 'video_ok':
        videoBlocked = false;
        if (isHost) _viewersBlurred = false;
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
      LiveFx.I.attach(localVideo); // unmuting can restart the camera
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
        LiveFx.I.attach(localVideo);
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
      if (setup.tipsOn && setup.tips.isNotEmpty && _rnd.nextDouble() < .3) {
        final t = setup.tips[min(_rnd.nextInt(setup.tips.length), _rnd.nextInt(setup.tips.length))];
        _push(LiveEvent(LiveEventType.tip, b.$1, lv: b.$2, text: t.label, qty: t.coins, senderId: sid));
      } else {
        _push(LiveEvent(LiveEventType.gift, b.$1, lv: b.$2, giftId: g, qty: [1, 1, 3, 10][_rnd.nextInt(4)], senderId: sid));
      }
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
    if (e.type == LiveEventType.gift || e.type == LiveEventType.tip) {
      _gifters.add(e.name);
      giftersCount = _gifters.length;
      final d = e.coins ~/ 2; // host gets 50% of coin value as diamonds
      diamondsEarned += d;
      goalCollected += e.coins;
      if (isHost) AppState.I.addDiamonds(d);
      if (e.type == LiveEventType.gift) _giftCtl.add(e);
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
      if (!isHost) {
        _selfStrikes++;
        if (inAppGuard && hostIdentity.isNotEmpty) {
          _sendTo({'t': 'strike', 'x': r.reason}, [hostIdentity]); // the host's phone keeps the score
        } else if (!guardOn || room == null) {
          if (_selfStrikes >= 3 && !chatMuted) mutedUntil = DateTime.now().add(const Duration(minutes: 5));
        }
      }
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

  /// Pays a line of the host's tip menu. Returns false when the wallet is short.
  bool sendTip(TipItem t) {
    if (!AppState.I.spend(t.coins)) return false;
    final e = LiveEvent(LiveEventType.tip, AppState.I.firstName, lv: AppState.I.level, text: t.label, qty: t.coins, mine: true, senderId: myIdentity);
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
    } else if (room != null) {
      // in-app guard: the host's phone tells every phone in the room
      switch (cmd) {
        case 'mute':
          _bcast({'t': 'mod', 'a': 'muted', 'who': who, 'n': target.name, 'sec': sec, 'x': '$hostName muted ${target.name}'});
        case 'unmute':
          _strikes.remove(userKey(who));
          _bcast({'t': 'mod', 'a': 'unmuted', 'who': who, 'n': target.name});
        case 'kick':
          _kick(who, target.name, 'removed by $hostName');
        case 'ban':
          _kick(who, target.name, 'banned by $hostName', ban: const Duration(days: 1));
      }
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
    } else if (room != null) {
      _bcast({'t': 'mod', 'a': 'slow', 'sec': sec, 'x': sec == 0 ? 'Slow mode is off' : 'Slow mode: 1 message every ${sec}s'});
    } else {
      events.add(LiveEvent(LiveEventType.mod, 'Umi Guard', text: sec == 0 ? 'turned slow mode off' : 'set slow mode to ${sec}s'));
    }
    notifyListeners();
  }

  void setCustomWords(List<String> words) {
    customWords = words.map((w) => w.trim()).where((w) => w.isNotEmpty).toList();
    if (guardOn) {
      _sendRaw({'cmd': 'words', 'words': customWords}, 'umigo-mod-cmd');
    } else {
      _bcast({'t': 'mod', 'a': 'words', 'words': customWords}, local: false);
    }
    notifyListeners();
  }

  void report(String reason, {String who = ''}) {
    if (guardOn) {
      _sendRaw({'x': reason, 'who': who.isEmpty ? hostIdentity : who}, 'umigo-report');
    } else {
      // reports about a viewer go to the host's phone, which can mute or remove them
      if (room != null && !isHost && who.isNotEmpty && userKey(who) != hostIdentity) _sendTo({'t': 'report', 'x': reason, 'who': who}, [hostIdentity]);
      _noticeCtl.add(ModNotice('Thanks, Umi Guard got your report.', bad: false));
    }
  }

  // ---------------- Home thumbnail ----------------
  /// Sends a 360px-wide snapshot of the camera to the token server for the Home
  /// feed. Skipped while the camera is off or the video check flagged a frame.
  Future<void> _postThumb() async {
    final track = localVideo, token = _token;
    if (_thumbBusy || ended || track == null || token == null || track.muted || videoBlocked || _viewersBlurred || _vgHits > 0) return;
    _thumbBusy = true;
    try {
      final png = await track.mediaStreamTrack.captureFrame();
      final codec = await ui.instantiateImageCodec(png.asUint8List(), targetWidth: 360);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      if (data != null && !ended) await TokenApi.uploadThumb(token, data.buffer.asUint8List());
    } catch (_) {
      // no frame yet, or the server is waking up; the next tick tries again
    } finally {
      _thumbBusy = false;
    }
  }

  // ---------------- on-phone video check ----------------
  static bool unsafeScores(Map<String, double> s) => (s['Porn'] ?? 0) + (s['Hentai'] ?? 0) >= .7 || (s['Sexy'] ?? 0) >= .92;

  void _startVideoGuard() {
    if (kIsWeb) return;
    NsfwClassifier.I.load();
    _vg = Timer.periodic(Duration(milliseconds: isHost ? 1500 : 2500), (_) => _videoTick());
  }

  Future<void> _videoTick() async {
    if (_vgBusy || ended || !NsfwClassifier.I.available) return;
    if (isHost && guardOn && !demo) return; // the server bot already checks the host's video
    final track = isHost ? localVideo : remoteVideo;
    if (track == null || (isHost && _vgPaused)) return;
    _vgBusy = true;
    try {
      final png = await track.mediaStreamTrack.captureFrame();
      final s = await NsfwClassifier.I.classify(png.asUint8List());
      if (s == null || ended) return;
      final unsafe = unsafeScores(s);
      if (isHost) {
        _hostVideoResult(unsafe);
      } else {
        _viewerVideoResult(unsafe);
      }
    } catch (_) {
      // a frame could not be read (camera switching, track ending); try the next one
    } finally {
      _vgBusy = false;
    }
  }

  void _hostVideoResult(bool unsafe) {
    if (unsafe) {
      _vgClean = 0;
      if (++_vgHits >= 2) _hostBlockVideo();
      return;
    }
    _vgHits = 0;
    if (_viewersBlurred && ++_vgClean >= 2) {
      _viewersBlurred = false;
      _bcast({'t': 'mod', 'a': 'video_ok'}, local: false);
      notifyListeners();
    }
  }

  Future<void> _hostBlockVideo() async {
    _vgHits = 0;
    _vgClean = 0;
    _vgStrikes++;
    _viewersBlurred = true;
    _vgPaused = true;
    // stop sending the camera, then tell every phone to blur
    try {
      await room?.localParticipant?.videoTrackPublications.firstOrNull?.mute();
    } catch (_) {}
    _bcast({'t': 'mod', 'a': 'video_block', 'x': 'Video paused by Umi Guard (community rules)', 'strikes': _vgStrikes});
    if (_vgStrikes >= 3) {
      _bcast({'t': 'mod', 'a': 'end', 'x': 'Umi Guard ended this live: nudity was detected 3 times.'});
      return;
    }
    Timer(const Duration(seconds: 8), () {
      if (ended) return;
      _vgPaused = false;
      videoBlocked = false; // the host sees the camera again; viewers stay blurred until frames are clean
      _resumeCamera();
    });
  }

  void _viewerVideoResult(bool unsafe) {
    if (unsafe) {
      _vgClean = 0;
      if (!selfBlur) {
        selfBlur = true;
        _noticeCtl.add(ModNotice('Umi Guard blurred this video for you.', bad: false));
        notifyListeners();
      }
    } else if (selfBlur && ++_vgClean >= 2) {
      selfBlur = false;
      notifyListeners();
    }
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
      await LiveFx.I.attach(t); // flipping makes a new native camera track
    } catch (_) {}
    notifyListeners();
  }

  Duration get elapsed => DateTime.now().difference(startedAt);

  Future<void> end() async {
    _bot?.cancel();
    _vg?.cancel();
    _thumb?.cancel();
    if (isHost) LiveFx.I.detach();
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
