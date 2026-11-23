// Instant on-device chat filter (0 network, < 1 ms). Same rules as the Umi Guard
// server bot (server/moderator/filter.js), which re-checks everything authoritatively.
import 'wordlist.dart';

enum ModAction { allow, mask, block }

class ModResult {
  final ModAction action;
  final String text;
  final String reason;
  const ModResult(this.action, this.text, [this.reason = '']);
}

class ChatFilter {
  static const _leet = {'0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '7': 't', '8': 'b', '@': 'a', r'$': 's', '!': 'i', '|': 'i', '+': 't'};

  static String normalize(String text) {
    var s = text.toLowerCase();
    s = s.split('').map((c) => _leet[c] ?? c).join();
    s = s.replaceAllMapped(RegExp(r'(\p{L})\1{2,}', unicode: true), (m) => '${m[1]}${m[1]}');
    return s;
  }

  static final _sep = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);
  static List<String> _tokens(String s) => s.split(_sep).where((t) => t.isNotEmpty).toList();
  static String _compact(String s) => s.replaceAll(_sep, '');
  static String _squeeze(String s) => s.replaceAllMapped(RegExp(r'(\p{L})\1+', unicode: true), (m) => m[1]!);

  static final Map<String, List<String>> _lists = {for (final e in modLists.entries) e.key: e.value.map(normalize).toList()};

  static final _suffix = RegExp(r'^(ing|in|ings|er|ers|ed|s|es|iya|ya|yan)$');

  static String? _hit(String norm, List<String> tokens, String comp, List<String> list) {
    for (final w in list) {
      if (w.contains(' ') || w.contains('.')) {
        if (norm.contains(w) || comp.contains(_compact(w))) return w;
        continue;
      }
      if (tokens.contains(w) || tokens.any((t) => _squeeze(t) == _squeeze(w))) return w;
      // word + common ending: facking, chutiyas, bitchy, randiyan
      if (w.length >= 4 && tokens.any((t) => t.startsWith(w) && _suffix.hasMatch(t.substring(w.length)))) return w;
      if (w.length >= 6 && comp.contains(w)) return w;
    }
    return null;
  }

  static final _url = RegExp(r'(https?://|www\.)\S+|\b[a-z0-9-]+\.(com|in|net|org|io|me|co|xyz|link|live|app|site|ly|gg)\b', caseSensitive: false);
  static final _phone = RegExp(r'(?:\+?91[\s-]?)?(?:\d[\s-]?){10,}');
  static final _email = RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.]+\b');

  static ModResult check(String text, {List<String> customWords = const []}) {
    var raw = text.trim();
    if (raw.length > 200) raw = raw.substring(0, 200);
    if (raw.isEmpty) return const ModResult(ModAction.block, '', 'empty');
    final norm = normalize(raw);
    final tokens = _tokens(norm);
    final comp = _compact(norm);

    if (_url.hasMatch(raw)) return ModResult(ModAction.block, raw, 'links are not allowed');
    if (_phone.hasMatch(raw.replaceAll(RegExp(r'[^\d+\s-]'), ' '))) return ModResult(ModAction.block, raw, 'phone numbers are not allowed');
    if (_email.hasMatch(raw)) return ModResult(ModAction.block, raw, 'emails are not allowed');
    if (_hit(norm, tokens, comp, _lists['hate']!) != null) return ModResult(ModAction.block, raw, 'hate or threats');
    if (_hit(norm, tokens, comp, _lists['sexual']!) != null) return ModResult(ModAction.block, raw, 'sexual content');
    if (_hit(norm, tokens, comp, _lists['scam']!) != null) return ModResult(ModAction.block, raw, 'scam or fraud');
    if (_hit(norm, tokens, comp, _lists['contact']!) != null) return ModResult(ModAction.block, raw, 'sharing contacts off the app');

    final letters = raw.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length >= 12 && letters.replaceAll(RegExp(r'[^A-Z]'), '').length / letters.length > 0.8) {
      return ModResult(ModAction.mask, raw.toLowerCase(), 'too much caps');
    }

    final all = [..._lists['profanity']!, ...customWords.map(normalize)];
    var masked = raw;
    var found = false;
    for (final part in raw.split(RegExp(r'\s+'))) {
      if (part.isEmpty) continue;
      final n = normalize(part);
      if (_hit(n, _tokens(n), _compact(n), all) != null) {
        found = true;
        masked = masked.replaceFirst(part, '✱' * part.length.clamp(3, 6));
      }
    }
    if (!found && _hit(norm, tokens, comp, all) != null) return ModResult(ModAction.block, raw, 'abusive language');
    if (found) return ModResult(ModAction.mask, masked, 'abusive language');
    return ModResult(ModAction.allow, raw);
  }
}

/// Client-side flood / repeat / slow-mode guard (the server enforces the same).
class ChatRateLimiter {
  final _times = <DateTime>[];
  String _last = '';
  int _repeats = 0;

  String? check(String text, {int slowSec = 0}) {
    final now = DateTime.now();
    _times.removeWhere((t) => now.difference(t).inSeconds >= 10);
    if (slowSec > 0 && _times.isNotEmpty && now.difference(_times.last).inMilliseconds < slowSec * 1000) {
      final wait = slowSec - now.difference(_times.last).inSeconds;
      return 'Slow mode is on. Wait ${wait}s.';
    }
    if (_times.length >= 6) return 'You are sending messages too fast.';
    final key = ChatFilter.normalize(text).replaceAll(RegExp(r'\s+'), ' ');
    _repeats = key == _last ? _repeats + 1 : 0;
    _last = key;
    if (_repeats >= 2) return 'No repeating the same message.';
    _times.add(now);
    return null;
  }
}
