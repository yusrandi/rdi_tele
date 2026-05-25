import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'ping_result.dart';

class PingService {
  /// =====================================================
  /// REALTIME PING STREAM
  /// =====================================================

  final StreamController<double> _pingController = StreamController.broadcast();

  Stream<double> get pingStream => _pingController.stream;

  /// =====================================================
  /// TCP PING
  /// =====================================================
  ///
  /// Melakukan koneksi TCP
  /// untuk estimasi latency.
  ///
  Future<double> tcpPing({String host = 'google.com', int port = 443}) async {
    final stopwatch = Stopwatch()..start();

    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );

      stopwatch.stop();

      socket.destroy();

      return stopwatch.elapsedMilliseconds.toDouble();
    } catch (_) {
      return -1;
    }
  }

  /// =====================================================
  /// START PING TEST
  /// =====================================================

  Future<PingResult> startPingTest({
    int pingCount = 10,
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    final List<double> pings = [];

    for (int i = 0; i < pingCount; i++) {
      final ping = await tcpPing();

      if (ping > 0) {
        pings.add(ping);
        log('Ping $i: $ping ms');

        /// realtime update
        _pingController.add(ping);
      }

      await Future.delayed(delay);
    }

    if (pings.isEmpty) {
      return const PingResult(averagePing: 0, jitter: 0, pings: []);
    }

    /// ===============================================
    /// AVERAGE LATENCY
    /// ===============================================

    final average = pings.reduce((a, b) => a + b) / pings.length;

    /// ===============================================
    /// JITTER
    /// ===============================================

    double jitter = 0;

    for (int i = 1; i < pings.length; i++) {
      jitter += (pings[i] - pings[i - 1]).abs();
    }

    jitter /= (pings.length - 1);

    return PingResult(averagePing: average, jitter: jitter, pings: pings);
  }

  void dispose() {
    _pingController.close();
  }
}
