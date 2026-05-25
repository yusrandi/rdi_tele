import 'dart:async';
import 'dart:io';

class DownloadService {
  static const String testUrl = 'http://speedtest.tele2.net/1GB.zip';

  bool _running = false;

  final StreamController<double> _speedController =
      StreamController.broadcast();

  Stream<double> get speedStream => _speedController.stream;

  bool get isRunning => _running;

  /// =====================================================
  /// DOWNLOAD TEST
  /// =====================================================

  Future<double> start({int threads = 8, int durationSeconds = 10}) async {
    _running = true;

    final client = HttpClient();

    client.maxConnectionsPerHost = 12;

    int totalBytes = 0;
    int lastBytes = 0;

    final stopwatch = Stopwatch()..start();

    Future.delayed(Duration(seconds: durationSeconds), () {
      _running = false;
    });

    final List<Future> tasks = [];

    for (int i = 0; i < threads; i++) {
      tasks.add(() async {
        while (_running) {
          try {
            final request = await client.getUrl(Uri.parse(testUrl));

            final response = await request.close();

            await for (final chunk in response) {
              if (!_running) break;

              totalBytes += chunk.length;
            }
          } catch (_) {}
        }
      }());
    }

    /// realtime Mbps
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_running) {
        timer.cancel();
        return;
      }

      final delta = totalBytes - lastBytes;

      lastBytes = totalBytes;

      final mbps = ((delta * 8) / 0.5) / 1000000;

      _speedController.add(mbps);
    });

    await Future.wait(tasks);

    stopwatch.stop();

    final seconds = stopwatch.elapsedMilliseconds / 1000;

    final mbps = ((totalBytes * 8) / seconds) / 1000000;

    return mbps;
  }
}
