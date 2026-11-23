import 'dart:convert';

import 'package:http/http.dart' as http;

import '../state/app_state.dart';

class TokenGrant {
  final String url, token;
  TokenGrant(this.url, this.token);
}

class LiveRoomInfo {
  final String name, title, hostName, hostId, tag;
  final int viewers;
  LiveRoomInfo({required this.name, required this.title, required this.hostName, required this.hostId, required this.tag, required this.viewers});
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
  }) async {
    final r = await http
        .post(
          Uri.parse('$_base/token'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'room': room, 'identity': identity, 'name': name, 'role': host ? 'host' : 'viewer', 'title': title, 'tag': tag}),
        )
        .timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) {
      throw Exception('Token server said ${r.statusCode}: ${r.body}');
    }
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return TokenGrant(j['url'] as String, j['token'] as String);
  }

  static Future<List<LiveRoomInfo>> rooms() async {
    final r = await http.get(Uri.parse('$_base/rooms')).timeout(const Duration(seconds: 8));
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
      );
    }).toList();
  }

  static Future<bool> health() async {
    try {
      final r = await http.get(Uri.parse('$_base/health')).timeout(const Duration(seconds: 6));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
