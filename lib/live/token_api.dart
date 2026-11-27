import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../state/app_state.dart';

class TokenGrant {
  final String url, token;
  TokenGrant(this.url, this.token);
}

class LiveRoomInfo {
  final String name, title, hostName, hostId, tag;

  /// public, paid or subscribers (set in the Go live steps).
  final String access;
  final int fee;
  final int viewers;
  final int startedAt; // ms since epoch, 0 if unknown

  /// Thumbnail: a snapshot of the host's camera (URL) or, for demo lives, a photo asset.
  final String? img;

  /// Set for demo lives: the creator id whose demo live opens on tap.
  final String? demoId;
  LiveRoomInfo({
    required this.name,
    required this.title,
    required this.hostName,
    required this.hostId,
    required this.tag,
    required this.viewers,
    this.startedAt = 0,
    this.access = 'public',
    this.fee = 0,
    this.img,
    this.demoId,
  });

  bool get isPrivate => access != 'public';
}

/// Talks to the tiny Umigo token server (server/token-server). It signs LiveKit
/// access tokens with your own API key/secret, so no paid LiveKit Cloud is used.
class TokenApi {
  static String get _base => AppState.I.tokenUrl;

  static Future<TokenGrant> token({
    required String room,
    required String identity,
    required String name,
    required bool host,
    String title = '',
    String tag = '',
    String access = 'public',
    int fee = 0,
  }) async {
    final r = await http
        .post(
          Uri.parse('$_base/token'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({
            'room': room,
            'identity': identity,
            'name': name,
            'role': host ? 'host' : 'viewer',
            'title': title,
            'tag': tag,
            'access': access,
            'fee': fee,
          }),
        )
        .timeout(const Duration(seconds: 60)); // free hosting can take ~30s to wake up
    if (r.statusCode != 200) {
      throw Exception('Token server said ${r.statusCode}: ${r.body}');
    }
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return TokenGrant(j['url'] as String, j['token'] as String);
  }

  static Future<List<LiveRoomInfo>> rooms() async {
    final r = await http.get(Uri.parse('$_base/rooms')).timeout(const Duration(seconds: 45));
    if (r.statusCode != 200) throw Exception('rooms ${r.statusCode}');
    final list = (jsonDecode(r.body) as Map<String, dynamic>)['rooms'] as List;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return LiveRoomInfo(
        name: m['name'] ?? '',
        title: m['title'] ?? 'Live now',
        hostName: m['hostName'] ?? 'Host',
        hostId: m['hostId'] ?? '',
        tag: m['tag'] ?? '',
        viewers: (m['viewers'] ?? 0) as int,
        startedAt: (m['startedAt'] ?? 0) as int,
        access: '${m['access'] ?? 'public'}',
        fee: (m['fee'] ?? 0) as int,
        img: (m['thumb'] ?? 0) as int > 0 ? '$_base/thumb/${Uri.encodeComponent('${m['name']}')}?v=${m['thumb']}' : null,
      );
    }).toList();
  }

  /// The host posts a small snapshot of their camera so the Home feed can show it.
  /// [token] is the host's LiveKit token; the server checks it before storing.
  static Future<void> uploadThumb(String token, Uint8List png) async {
    await http
        .post(Uri.parse('$_base/thumb'), headers: {'content-type': 'image/png', 'authorization': 'Bearer $token'}, body: png)
        .timeout(const Duration(seconds: 30));
  }

  static Future<bool> health() async {
    try {
      final r = await http.get(Uri.parse('$_base/health')).timeout(const Duration(seconds: 45));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
