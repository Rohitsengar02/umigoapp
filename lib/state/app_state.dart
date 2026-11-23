import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default live server addresses. Override at build time:
///   flutter build apk --dart-define=TOKEN_URL=https://live.example.com/api
/// or change them inside the app: Profile > Live server.
const _defaultTokenUrl = String.fromEnvironment('TOKEN_URL', defaultValue: 'https://umigo-token.onrender.com');

/// One global store for the demo: wallet, profile and server settings.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState I = AppState._();

  SharedPreferences? _p;

  bool loggedIn = false;
  String name = 'Aarav Mehta';
  String username = 'aarav.live';
  late String userId;
  int coins = 12450;
  int diamonds = 48210;
  int level = 12;
  int xp = 2340;
  List<String> interests = ['Music', 'Gaming'];
  bool checkedInToday = false;

  /// Token server base URL, e.g. https://live.example.com/api . Empty means demo mode.
  String tokenUrl = _defaultTokenUrl;

  bool get serverConfigured => tokenUrl.trim().isNotEmpty;

  final List<String> history = []; // newest first, simple log of wallet actions

  /// Hosts this user follows: hostId -> display name.
  final Map<String, String> following = {};

  /// Lives this user watched, newest first: "hostId|hostName|title|epochMs".
  final List<String> watched = [];

  Future<void> load() async {
    try {
      _p = await SharedPreferences.getInstance();
    } catch (_) {}
    final p = _p;
    userId = p?.getString('uid') ?? 'u${Random().nextInt(899999) + 100000}';
    p?.setString('uid', userId);
    if (p == null) return;
    loggedIn = p.getBool('loggedIn') ?? false;
    name = p.getString('name') ?? name;
    username = p.getString('username') ?? username;
    coins = p.getInt('coins') ?? coins;
    diamonds = p.getInt('diamonds') ?? diamonds;
    final savedUrl = p.getString('tokenUrl') ?? '';
    if (savedUrl.isNotEmpty) tokenUrl = savedUrl; // empty means "never set", so use the built-in server
    interests = p.getStringList('interests') ?? interests;
    for (final f in p.getStringList('following') ?? const <String>[]) {
      final i = f.indexOf('|');
      if (i > 0) following[f.substring(0, i)] = f.substring(i + 1);
    }
    watched.addAll(p.getStringList('watched') ?? const <String>[]);
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setBool('loggedIn', loggedIn);
    p.setString('name', name);
    p.setString('username', username);
    p.setInt('coins', coins);
    p.setInt('diamonds', diamonds);
    p.setString('tokenUrl', tokenUrl);
    p.setStringList('interests', interests);
    p.setStringList('following', [for (final e in following.entries) '${e.key}|${e.value}']);
    p.setStringList('watched', watched);
  }

  bool isFollowing(String hostId) => following.containsKey(hostId);

  void toggleFollow(String hostId, String hostName) {
    if (hostId.isEmpty) return;
    following.containsKey(hostId) ? following.remove(hostId) : following[hostId] = hostName;
    _save();
    notifyListeners();
  }

  void addWatched(String hostId, String hostName, String title) {
    if (hostId.isEmpty) return;
    watched.removeWhere((w) => w.startsWith('$hostId|'));
    watched.insert(0, '$hostId|$hostName|${title.replaceAll('|', ' ')}|${DateTime.now().millisecondsSinceEpoch}');
    if (watched.length > 50) watched.removeLast();
    _save();
    notifyListeners();
  }

  String get firstName => name.trim().split(' ').first;
  String get displayId => '1${userId.hashCode.abs().toString().padLeft(7, '0').substring(0, 7)}';

  void login({String? asName}) {
    loggedIn = true;
    if (asName != null && asName.trim().isNotEmpty) name = asName.trim();
    _save();
    notifyListeners();
  }

  void register({required String name, required String username, required List<String> interests}) {
    this.name = name;
    this.username = username;
    this.interests = interests;
    loggedIn = true;
    _save();
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    _save();
    notifyListeners();
  }

  bool spend(int amount) {
    if (amount > coins) return false;
    coins -= amount;
    xp += amount ~/ 2;
    _save();
    notifyListeners();
    return true;
  }

  void addCoins(int amount) {
    coins += amount;
    _save();
    notifyListeners();
  }

  void addDiamonds(int amount) {
    diamonds += amount;
    _save();
    notifyListeners();
  }

  bool withdraw(int rupees) {
    final need = rupees * 10;
    if (need > diamonds) return false;
    diamonds -= need;
    _save();
    notifyListeners();
    return true;
  }

  void checkIn() {
    if (checkedInToday) return;
    checkedInToday = true;
    coins += 10;
    _save();
    notifyListeners();
  }

  void setServer(String token) {
    tokenUrl = token.trim().replaceAll(RegExp(r'/+$'), '');
    _save();
    notifyListeners();
  }
}
