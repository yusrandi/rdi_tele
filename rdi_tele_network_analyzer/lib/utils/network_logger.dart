// Buat file baru: network_logger.dart
import 'dart:async';
import 'package:intl/intl.dart';

class NetworkLogger {
  // Singleton pattern
  static final NetworkLogger _instance = NetworkLogger._internal();
  factory NetworkLogger() => _instance;
  NetworkLogger._internal();

  static final List<LogEntry> _logs = [];
  static const int maxLogs = 1000;

  // StreamController untuk broadcast ke UI
  final StreamController<LogEntry> _logController =
      StreamController<LogEntry>.broadcast();

  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  // Method untuk menambah log
  void log(String type, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      type: type,
      message: message,
    );

    _logs.insert(0, entry);

    if (_logs.length > maxLogs) {
      _logs.removeLast();
    }

    _logController.add(entry);

    // Juga print ke console
    print(
      '[${DateFormat('HH:mm:ss').format(entry.timestamp)}] [$type] $message',
    );
  }

  // Helper methods untuk berbagai tipe log
  void speed(String message) => log('SPEED', message);
  void telephony(String message) => log('TELE', message);
  void servingCell(String message) => log('SERVING_CELL', message);
  void location(String message) => log('LOC', message);
  void session(String message) => log('SESSION', message);
  void error(String message) => log('ERROR', message);

  // Clear logs
  void clear() {
    _logs.clear();
    _logController.add(
      LogEntry(
        timestamp: DateTime.now(),
        type: 'SYSTEM',
        message: 'Logs cleared',
      ),
    );
  }

  void dispose() {
    _logController.close();
  }
}

class LogEntry {
  final DateTime timestamp;
  final String type;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
  });
}
