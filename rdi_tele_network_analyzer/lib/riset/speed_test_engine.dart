import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// ======================================================
/// RESULT MODEL
/// ======================================================

class SpeedTestResult {
  final double downloadMbps;
  final double uploadMbps;
  final double latencyMs;
  final double jitterMs;

  SpeedTestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.latencyMs,
    required this.jitterMs,
  });
}

/// ======================================================
/// SPEED TEST ENGINE
/// ======================================================

class SpeedTestEngine {
  /// TEST FILE
  static const String downloadUrl = 'http://speedtest.tele2.net/1GB.zip';

  bool _downloadRunning = false;
  bool _uploadRunning = false;

  /// DOWNLOAD STREAM
  final StreamController<double> _downloadController =
      StreamController.broadcast();

  Stream<double> get downloadStream => _downloadController.stream;

  /// UPLOAD STREAM
  final StreamController<double> _uploadController =
      StreamController.broadcast();

  Stream<double> get uploadStream => _uploadController.stream;

  /// ======================================================
  /// MAIN TEST
  /// ======================================================

  Future<SpeedTestResult> startTest() async {
    final latencyData = await measureLatencyAndJitter();

    final download = await startDownloadTest();

    final upload = await startFakeUploadTest();

    return SpeedTestResult(
      downloadMbps: download,
      uploadMbps: upload,
      latencyMs: latencyData['latency']!,
      jitterMs: latencyData['jitter']!,
    );
  }

  /// ======================================================
  /// DOWNLOAD TEST
  /// ======================================================

  Future<double> startDownloadTest({
    int threads = 24,
    int durationSeconds = 12,
  }) async {
    _downloadRunning = true;

    final client = HttpClient();

    client.maxConnectionsPerHost = 50;

    int totalBytes = 0;
    int measuredBytes = 0;

    final stopwatch = Stopwatch()..start();

    Future.delayed(Duration(seconds: durationSeconds), () {
      _downloadRunning = false;
    });

    List<Future> tasks = [];

    for (int i = 0; i < threads; i++) {
      tasks.add(() async {
        while (_downloadRunning) {
          try {
            final request = await client.getUrl(Uri.parse(downloadUrl));

            final response = await request.close();

            if (response.statusCode != 200) {
              continue;
            }

            await for (final chunk in response) {
              if (!_downloadRunning) {
                break;
              }

              totalBytes += chunk.length;

              /// IGNORE TCP WARMUP
              if (stopwatch.elapsed.inSeconds >= 2) {
                measuredBytes += chunk.length;
              }
            }
          } catch (e) {
            print(e);
          }
        }
      }());
    }

    /// REALTIME
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_downloadRunning) {
        timer.cancel();
        return;
      }

      final seconds = stopwatch.elapsedMilliseconds / 1000;

      if (seconds <= 0) return;

      final mbps = ((totalBytes * 8) / seconds) / 1000000;

      _downloadController.add(mbps);
    });

    await Future.wait(tasks);

    stopwatch.stop();

    final measuredSeconds = stopwatch.elapsedMilliseconds / 1000 - 2;

    final mbps = ((measuredBytes * 8) / measuredSeconds) / 1000000;

    return mbps;
  }

  /// ======================================================
  /// FAKE UPLOAD TEST
  /// ======================================================
  ///
  /// NOTE:
  /// Ini simulasi upload lokal dulu.
  /// Nanti tinggal ganti endpoint backend.
  ///
  Future<double> startFakeUploadTest({int durationSeconds = 8}) async {
    _uploadRunning = true;

    int uploadedBytes = 0;

    final random = Random();

    final stopwatch = Stopwatch()..start();

    Future.delayed(Duration(seconds: durationSeconds), () {
      _uploadRunning = false;
    });

    /// REALTIME
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_uploadRunning) {
        timer.cancel();
        return;
      }

      final seconds = stopwatch.elapsedMilliseconds / 1000;

      if (seconds <= 0) return;

      final mbps = ((uploadedBytes * 8) / seconds) / 1000000;

      _uploadController.add(mbps);
    });

    while (_uploadRunning) {
      /// GENERATE RANDOM DATA
      final data = Uint8List.fromList(
        List.generate(1024 * 1024, (_) => random.nextInt(255)),
      );

      uploadedBytes += data.length;

      await Future.delayed(const Duration(milliseconds: 50));
    }

    stopwatch.stop();

    final seconds = stopwatch.elapsedMilliseconds / 1000;

    final mbps = ((uploadedBytes * 8) / seconds) / 1000000;

    return mbps;
  }

  /// ======================================================
  /// TCP LATENCY
  /// ======================================================

  Future<double> tcpPing() async {
    final stopwatch = Stopwatch()..start();

    try {
      final socket = await Socket.connect(
        'google.com',
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

  /// ======================================================
  /// LATENCY + JITTER
  /// ======================================================

  Future<Map<String, double>> measureLatencyAndJitter() async {
    List<double> pings = [];

    for (int i = 0; i < 10; i++) {
      final ping = await tcpPing();

      if (ping > 0) {
        pings.add(ping);
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (pings.isEmpty) {
      return {'latency': 0, 'jitter': 0};
    }

    final latency = pings.reduce((a, b) => a + b) / pings.length;

    double jitter = 0;

    for (int i = 1; i < pings.length; i++) {
      jitter += (pings[i] - pings[i - 1]).abs();
    }

    jitter /= (pings.length - 1);

    return {'latency': latency, 'jitter': jitter};
  }

  void dispose() {
    _downloadController.close();
    _uploadController.close();
  }
}

/// ======================================================
/// UI
/// ======================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SpeedTestEngine engine = SpeedTestEngine();

  StreamSubscription? downloadSub;
  StreamSubscription? uploadSub;

  double realtimeDownload = 0;
  double realtimeUpload = 0;

  double finalDownload = 0;
  double finalUpload = 0;

  double latency = 0;
  double jitter = 0;

  bool testing = false;

  @override
  void initState() {
    super.initState();

    downloadSub = engine.downloadStream.listen((speed) {
      setState(() {
        realtimeDownload = speed;
      });
    });

    uploadSub = engine.uploadStream.listen((speed) {
      setState(() {
        realtimeUpload = speed;
      });
    });
  }

  Future<void> startTest() async {
    setState(() {
      testing = true;

      realtimeDownload = 0;
      realtimeUpload = 0;

      finalDownload = 0;
      finalUpload = 0;
    });

    final result = await engine.startTest();

    setState(() {
      testing = false;

      finalDownload = result.downloadMbps;

      finalUpload = result.uploadMbps;

      latency = result.latencyMs;
      jitter = result.jitterMs;
    });
  }

  Widget metric(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    downloadSub?.cancel();
    uploadSub?.cancel();

    engine.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Custom Speed Test')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              metric(
                'Realtime Download',
                '${realtimeDownload.toStringAsFixed(2)} Mbps',
              ),

              metric(
                'Realtime Upload',
                '${realtimeUpload.toStringAsFixed(2)} Mbps',
              ),

              const SizedBox(height: 20),

              metric(
                'Final Download',
                '${finalDownload.toStringAsFixed(2)} Mbps',
              ),

              metric('Final Upload', '${finalUpload.toStringAsFixed(2)} Mbps'),

              metric('Latency', '${latency.toStringAsFixed(2)} ms'),

              metric('Jitter', '${jitter.toStringAsFixed(2)} ms'),

              const SizedBox(height: 40),

              testing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: startTest,
                      child: const Text('START TEST'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
