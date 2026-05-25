import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

class UploadService {
  bool _running = false;

  final StreamController<double> _speedController =
      StreamController.broadcast();

  Stream<double> get speedStream => _speedController.stream;

  bool get isRunning => _running;

  /// =====================================================
  /// FAKE UPLOAD
  /// =====================================================
  ///
  /// nanti tinggal ganti
  /// dengan API upload backend
  ///
  Future<double> start({int durationSeconds = 8}) async {
    _running = true;

    int uploadedBytes = 0;
    int lastBytes = 0;

    final random = Random();

    final stopwatch = Stopwatch()..start();

    Future.delayed(Duration(seconds: durationSeconds), () {
      _running = false;
    });

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_running) {
        timer.cancel();
        return;
      }

      final delta = uploadedBytes - lastBytes;

      lastBytes = uploadedBytes;

      final mbps = ((delta * 8) / 0.5) / 1000000;

      _speedController.add(mbps);
    });

    while (_running) {
      final data = Uint8List.fromList(
        List.generate(1024 * 1024, (_) => random.nextInt(255)),
      );

      uploadedBytes += data.length;

      await Future.delayed(const Duration(milliseconds: 50));
    }

    stopwatch.stop();

    final seconds = stopwatch.elapsedMilliseconds / 1000;

    return ((uploadedBytes * 8) / seconds) / 1000000;
  }
}
