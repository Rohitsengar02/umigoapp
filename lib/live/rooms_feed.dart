import 'dart:async';

import 'package:flutter/foundation.dart';

import '../state/app_state.dart';
import '../data/demo_lives.dart';
import 'token_api.dart';

/// Real lives on your LiveKit server, refreshed every few seconds while any
/// screen is listening. No demo rooms: if nobody is live the list is empty.
class RoomsFeed extends ChangeNotifier {
  RoomsFeed._();
  static final RoomsFeed I = RoomsFeed._();

  List<LiveRoomInfo> rooms = [];
  bool loading = false;
  bool loadedOnce = false;
  String? error;
  Timer? _timer;
  int _users = 0;

  bool get serverConfigured => AppState.I.serverConfigured;

  /// Lives other than my own.
  List<LiveRoomInfo> get others => rooms.where((r) => r.hostId != AppState.I.userId).toList();

  /// Real lives first, then the demo lives (until the backend has real creators).
  List<LiveRoomInfo> get withDemo => [...others, ...demoLives];

  void attach() {
    _users++;
    if (_users == 1) {
      refresh();
      _timer = Timer.periodic(const Duration(seconds: 6), (_) => refresh());
    }
  }

  void detach() {
    _users = (_users - 1).clamp(0, 1 << 20);
    if (_users == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> refresh() async {
    if (!serverConfigured) {
      rooms = [];
      error = null;
      loadedOnce = true;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    try {
      rooms = await TokenApi.rooms();
      error = null;
    } catch (_) {
      error = 'Live server not reachable';
    }
    loading = false;
    loadedOnce = true;
    notifyListeners();
  }
}
