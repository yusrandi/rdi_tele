import 'dart:async';
import 'dart:io';

class PingService {
  final StreamController<double> _pingController = StreamController.broadcast();

  Stream<double> get pingStream => _pingController.stream;

  /// =====================================================
  /// TCP PING
  /// =====================================================

  Future<double> ping() async {
    final stopwatch = Stopwatch()..start();

    try {
      final socket = await Socket.connect(
        '216.239.38.120',
        443,
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
  /// AVERAGE PING
  /// =====================================================

  Future<double> averagePing({int count = 10}) async {
    final List<double> pings = [];

    /// warmup ping
    await ping();

    for (int i = 0; i < count; i++) {
      final result = await ping();

      if (result > 0) {
        pings.add(result);

        _pingController.add(result);
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (pings.isEmpty) return 0;

    return pings.reduce((a, b) => a + b) / pings.length;
  }

  /// =====================================================
  /// JITTER
  /// =====================================================

  Future<double> jitter({int count = 10}) async {
    final List<double> pings = [];

    await ping();

    for (int i = 0; i < count; i++) {
      final result = await ping();

      if (result > 0) {
        pings.add(result);
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (pings.length < 2) return 0;

    double jitter = 0;

    for (int i = 1; i < pings.length; i++) {
      jitter += (pings[i] - pings[i - 1]).abs();
    }

    return jitter / (pings.length - 1);
  }

  void dispose() {
    _pingController.close();
  }
}
