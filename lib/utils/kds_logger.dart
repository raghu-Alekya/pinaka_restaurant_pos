import 'package:flutter/foundation.dart';

class KdsDebugLog {
  KdsDebugLog._();

  static final List<String> _logs = [];
  static final List<VoidCallback> _listeners = [];

  static List<String> get logs => List.unmodifiable(_logs);

  static void add(String tag, String message) {
    final line = '[${_time()}][$tag] $message';
    debugPrint(line);
    _logs.insert(0, line);
    if (_logs.length > 80) {
      _logs.removeLast();
    }
    for (final listener in _listeners) {
      listener();
    }
  }

  static void info(String message) => add('INFO', message);
  static void warn(String message) => add('WARN', message);
  static void error(String message) => add('ERROR', message);

  static void listen(VoidCallback callback) {
    _listeners.add(callback);
  }

  static void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  static void clear() => _logs.clear();

  static String _time() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }
}
