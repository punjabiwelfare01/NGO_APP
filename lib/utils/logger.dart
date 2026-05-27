import 'dart:collection';
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class _Entry {
  _Entry(this.level, this.tag, this.message, this.timestamp, [this.error]);
  final LogLevel level;
  final String tag;
  final String message;
  final DateTime timestamp;
  final Object? error;
}

/// Lightweight in-process logger.
///
/// - Always writes to [debugPrint] in debug builds.
/// - Keeps the last [bufferSize] entries in memory for display (e.g. a
///   debug log screen or bug reports).
/// - Zero dependencies — no pub packages required.
class AppLogger {
  AppLogger._();

  static const int bufferSize = 200;
  static final _buf = Queue<_Entry>();

  // ── public API ─────────────────────────────────────────────────────────────

  static void debug(String msg, {String tag = 'App', Object? error}) =>
      _log(LogLevel.debug, tag, msg, error);

  static void info(String msg, {String tag = 'App', Object? error}) =>
      _log(LogLevel.info, tag, msg, error);

  static void warning(String msg, {String tag = 'App', Object? error}) =>
      _log(LogLevel.warning, tag, msg, error);

  static void error(String msg, {String tag = 'App', Object? error}) =>
      _log(LogLevel.error, tag, msg, error);

  /// HTTP request shorthand — called from ApiClient.
  static void request(String method, String path) =>
      _log(LogLevel.debug, 'HTTP', '→ $method $path', null);

  /// HTTP response shorthand — called from ApiClient.
  static void response(int status, String path) {
    final level = status >= 400 ? LogLevel.error : LogLevel.debug;
    _log(level, 'HTTP', '← $status $path', null);
  }

  // ── buffer access ──────────────────────────────────────────────────────────

  /// Returns up to [count] most-recent log lines as formatted strings.
  static List<String> recent({int count = 100}) {
    return _buf.toList().reversed.take(count).map(_format).toList();
  }

  static void clear() => _buf.clear();

  // ── internals ──────────────────────────────────────────────────────────────

  static void _log(LogLevel level, String tag, String msg, Object? err) {
    final entry = _Entry(level, tag, msg, DateTime.now(), err);
    _buf.addLast(entry);
    if (_buf.length > bufferSize) _buf.removeFirst();

    if (kDebugMode) {
      debugPrint(_format(entry));
      if (err != null) debugPrint('  ↳ $err');
    }
  }

  static String _format(_Entry e) {
    final ts = e.timestamp.toIso8601String().substring(11, 23);
    final lvl = switch (e.level) {
      LogLevel.debug   => 'DEBUG',
      LogLevel.info    => 'INFO ',
      LogLevel.warning => 'WARN ',
      LogLevel.error   => 'ERROR',
    };
    return '$ts [$lvl] ${e.tag}: ${e.message}';
  }
}
