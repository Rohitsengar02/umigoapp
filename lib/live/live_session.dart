import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../data/demo_data.dart';
import '../state/app_state.dart';
import 'token_api.dart';

enum LiveEventType { chat, gift, join, like, system }

class LiveEvent {
  final LiveEventType type;
  final String name;
  final int lv;
  final String text;
  final String giftId;
  final int qty;
  final bool mine;
  LiveEvent(this.type, this.name, {this.lv = 1, this.text = '', this.giftId = '', this.qty = 1, this.mine = false});

  Map<String, dynamic> toJson() => {'t': type.name, 'n': name, 'lv': lv, 'x': text, 'g': giftId, 'q': qty};

  static LiveEvent? fromJson(Map<String, dynamic> j) {
    final t = LiveEventType.values.where((e) => e.name == j['t']).firstOrNull;
    if (t == null) return null;
    return LiveEvent(t, '${j['n'] ?? 'Someone'}',
        lv: (j['lv'] ?? 1) as int, text: '${j['x'] ?? ''}', giftId: '${j['g'] ?? ''}', qty: (j['q'] ?? 1) as int);
  }

  int get coins => type == LiveEventType.gift ? giftById(giftId).price * qty : 0;
}

/// One live room, for a host or a viewer.
///
/// Real mode: connects to your self-hosted LiveKit server. Video/audio go over
/// WebRTC, and chat/gifts/likes go over LiveKit data messages (topic "umigo").
/// Demo mode (no server set): local camera for hosts, simulated viewers and gifts.
class LiveSession extends ChangeNotifier {
  LiveSession.host({required this.title, required this.tag})
      : isHost = true,
        roomName = 'live_${AppState.I.userId}',
        hostName = AppState.I.firstName,
        demoHost = null;

  LiveSession.viewer({required this.roomName, required this.hostName, this.demoHost, this.title = ''})
      : isHost = false,
        tag = '';

  final bool isHost;
  final String roomName;
  final String hostName;
  final Host? demoHost; // set when watching a demo card
  String title;
  String tag;

  bool get demo => !AppState.I.serverConfigured || demoHost != null;

  Room? room;
  EventsListener<RoomEvent>? _listener;
  LocalVideoTrack? localVideo;
  VideoTrack? remoteVideo;
  bool connecting = true;
  String? error;
  bool ended = false;
  bool micOn = true;
  bool camFront = true;

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

  Timer? _bot;
  final _rnd = Random();
  DateTime startedAt = DateTime.now();

  Future<void> start() async {
    events.add(LiveEvent(LiveEventType.system, 'Umigo',
        text: isHost
            ? 'You are live! Be kind, follow the community rules.'
            : 'Welcome! Be kind, no spam. Gifts help $hostName climb the daily rank.'));
    try {
      if (demo) {
        await _startDemo();
      } else {
        await _startReal();
      }
    } catch (e) {
      error = '$e';
      if (isHost) {
        // Fall back to a local-only demo so the screen is still usable.
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
    final grant = await TokenApi.token(
      room: roomName,
      identity: isHost ? me.userId : '${me.userId}_${_rnd.nextInt(9999)}',
      name: me.firstName,
      host: isHost,
      title: title,
      tag: tag,
    );
    final r = Room(roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
    room = r;
    final l = r.createListener();
    _listener = l;
    l
      ..on<ParticipantConnectedEvent>((e) {
        _recount(); // the viewer announces itself with a "join" data message
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        _recount();
        if (!isHost && remoteVideo != null && e.participant.videoTrackPublications.any((p) => p.track == remoteVideo)) {
          remoteVideo = null;
          ended = true;
          notifyListeners();
        }
      })
      ..on<TrackSubscribedEvent>((e) {
        if (e.track is VideoTrack) {
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
      ..on<DataReceivedEvent>((e) {
        if (e.topic != 'umigo') return;
        try {
          final ev = LiveEvent.fromJson(jsonDecode(utf8.decode(e.data)) as Map<String, dynamic>);
          if (ev != null) _push(ev);
        } catch (_) {}
      })
      ..on<RoomDisconnectedEvent>((e) {
        if (!isHost) ended = true;
        notifyListeners();
      });

    await r.connect(grant.url, grant.token);
    if (isHost) {
      try {
        await r.localParticipant?.setCameraEnabled(true,
            cameraCaptureOptions: const CameraCaptureOptions(cameraPosition: CameraPosition.front));
        await r.localParticipant?.setMicrophoneEnabled(true);
      } catch (e) {
        error = 'Camera/mic blocked: $e';
      }
      final pub = r.localParticipant?.videoTrackPublications.firstOrNull;
      localVideo = pub?.track;
    } else {
      for (final p in r.remoteParticipants.values) {
        for (final pub in p.videoTrackPublications) {
          if (pub.track != null) remoteVideo = pub.track;
        }
      }
      _send(LiveEvent(LiveEventType.join, AppState.I.firstName, lv: AppState.I.level, text: 'joined the room'));
    }
    _recount();
  }

  void _recount() {
    final r = room;
    if (r == null) return;
    // Everyone except the host counts as a viewer. For a viewer, remote
    // participants are the host plus other viewers, so the count is the same.
    viewers = r.remoteParticipants.length;
    notifyListeners();
  }

  Future<void> _startDemo() async {
    if (isHost) {
      try {
        localVideo = await LocalVideoTrack.createCameraTrack(const CameraCaptureOptions());
      } catch (e) {
        error = 'Camera not available here ($e). Showing a photo instead.';
      }
      viewers = 0;
    } else {
      viewers = 1200 + _rnd.nextInt(11000);
      events.addAll([
        LiveEvent(LiveEventType.chat, 'Meera', lv: 24, text: 'your voice is magic'),
        LiveEvent(LiveEventType.chat, 'arjun_07', lv: 8, text: 'play Kesariya next please'),
        LiveEvent(LiveEventType.gift, 'Rahul_K', lv: 41, giftId: 'rose', qty: 10),
      ]);
    }
    _bot = Timer.periodic(Duration(milliseconds: isHost ? 2600 : 2200), (_) => _botTick());
  }

  void _botTick() {
    final b = botViewers[_rnd.nextInt(botViewers.length)];
    final roll = _rnd.nextDouble();
    if (isHost) viewers += _rnd.nextInt(4);
    if (!isHost) viewers += _rnd.nextInt(7) - 2;
    if (roll < 0.55) {
      _push(LiveEvent(LiveEventType.chat, b.$1, lv: b.$2, text: botLines[_rnd.nextInt(botLines.length)]));
    } else if (roll < 0.75) {
      final cheap = ['rose', 'heart', 'coffee', 'star', 'crown', 'rocket'];
      final g = cheap[min(_rnd.nextInt(cheap.length), _rnd.nextInt(cheap.length))];
      _push(LiveEvent(LiveEventType.gift, b.$1, lv: b.$2, giftId: g, qty: [1, 1, 3, 10][_rnd.nextInt(4)]));
    } else if (roll < 0.9) {
      _push(LiveEvent(LiveEventType.join, b.$1, lv: b.$2, text: 'joined the room'));
    } else {
      likes += 5;
      _likeCtl.add(null);
      notifyListeners();
    }
  }

  void _push(LiveEvent e) {
    events.add(e);
    if (events.length > 60) events.removeAt(1);
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

  void _send(LiveEvent e) {
    final r = room;
    if (r == null) return;
    r.localParticipant
        ?.publishData(utf8.encode(jsonEncode(e.toJson())), reliable: e.type != LiveEventType.like, topic: 'umigo')
        .catchError((_) {});
  }

  void sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final e = LiveEvent(LiveEventType.chat, isHost ? '$hostName (host)' : AppState.I.firstName,
        lv: AppState.I.level, text: t, mine: true);
    _push(e);
    _send(e);
  }

  /// Returns false when the wallet is short.
  bool sendGift(Gift g, int qty) {
    if (!AppState.I.spend(g.price * qty)) return false;
    final e = LiveEvent(LiveEventType.gift, AppState.I.firstName, lv: AppState.I.level, giftId: g.id, qty: qty, mine: true);
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

  Future<void> toggleMic() async {
    micOn = !micOn;
    if (room != null) {
      await room!.localParticipant?.setMicrophoneEnabled(micOn);
    }
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
    super.dispose();
  }
}
