// ─── engine/speed_engine.dart ─────────────────────────────────────────────────
// Engine utama — mirip cara kerja Cloudflare speed test asli:
//   • Multi-chunk sizes (makin besar makin saturate link)
//   • Loaded latency diukur paralel saat DL/UL berjalan
//   • Final speed = p90 dari semua samples (bukan peak, bukan average)
//   • Idle vs loaded latency → bufferbloat detection
//   • Packet loss simulation via concurrent timeout requests
//   • Speed variance via std deviation

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';
import 'stats.dart';

// Chunk sizes yang dipakai untuk saturate koneksi secara bertahap
// Mirip pendekatan Cloudflare: mulai kecil lalu besar
const _downloadChunks = [
  100 * 1024, // 100 KB  — representasi small web assets
  500 * 1024, // 500 KB
  1 * 1024 * 1024, // 1 MB
  5 * 1024 * 1024, // 5 MB
  10 * 1024 * 1024, // 10 MB
  25 * 1024 * 1024, // 25 MB  — untuk saturate koneksi cepat
];

const _uploadChunks = [
  100 * 1024, // 100 KB
  500 * 1024, // 500 KB
  1 * 1024 * 1024, // 1 MB
  5 * 1024 * 1024, // 5 MB
  10 * 1024 * 1024, // 10 MB
];

const _baseUrl = 'https://speed.cloudflare.com';

// Minimum durasi request untuk dianggap valid (hindari TCP warmup bias)
const _minValidDurationMs = 100;

// Timeout untuk packet loss probe
const _packetLossTimeout = Duration(milliseconds: 3000);

/// Event yang dikirim ke UI selama test berlangsung
class EngineEvent {
  final String phase;
  final String message;
  final double? progress; // 0.0 – 1.0
  final double? currentMbps;
  final int? currentLatencyMs;

  const EngineEvent({
    required this.phase,
    required this.message,
    this.progress,
    this.currentMbps,
    this.currentLatencyMs,
  });
}

class SpeedEngine {
  final void Function(EngineEvent event) onEvent;
  bool _cancelled = false;

  SpeedEngine({required this.onEvent});

  void cancel() => _cancelled = true;

  void _emit(EngineEvent e) => onEvent(e);

  // ── Public: run full test ──────────────────────────────────────────────────

  Future<SpeedTestFinalResult> runFullTest() async {
    _cancelled = false;

    // 1. Meta
    _emit(
      const EngineEvent(phase: 'meta', message: 'Mengambil info jaringan...'),
    );
    final meta = await _fetchMeta();
    _emit(
      EngineEvent(
        phase: 'meta',
        message: meta != null
            ? 'Server: ${meta.colo} · ISP: ${meta.isp}'
            : 'Info jaringan tidak tersedia',
      ),
    );

    if (_cancelled) return _emptyResult(meta);

    // 2. Idle latency (diukur SEBELUM load apapun)
    _emit(
      const EngineEvent(
        phase: 'idle_latency',
        message: 'Mengukur idle latency...',
      ),
    );
    final idleResult = await _measureIdleLatency(samples: 10);
    _emit(
      EngineEvent(
        phase: 'idle_latency',
        message:
            'Idle: ${idleResult.$1.toStringAsFixed(1)}ms · Jitter: ${idleResult.$2.toStringAsFixed(1)}ms',
        currentLatencyMs: idleResult.$1.round(),
      ),
    );

    if (_cancelled) return _emptyResult(meta);

    // 3. Download (dengan loaded latency paralel)
    _emit(
      const EngineEvent(
        phase: 'download',
        message: 'Mulai download test...',
        progress: 0,
      ),
    );
    final dlResult = await _measureDirection(
      isDownload: true,
      chunks: _downloadChunks,
    );

    if (_cancelled) return _emptyResult(meta);

    // 4. Upload (dengan loaded latency paralel)
    _emit(
      const EngineEvent(
        phase: 'upload',
        message: 'Mulai upload test...',
        progress: 0,
      ),
    );
    final ulResult = await _measureDirection(
      isDownload: false,
      chunks: _uploadChunks,
    );

    if (_cancelled) return _emptyResult(meta);

    // 5. Packet loss simulation
    _emit(
      const EngineEvent(
        phase: 'packet_loss',
        message: 'Simulasi packet loss...',
      ),
    );
    final plResult = await _measurePacketLoss(probes: 20);
    _emit(
      EngineEvent(
        phase: 'packet_loss',
        message:
            'Loss: ${plResult.lossPercent.toStringAsFixed(1)}% (${plResult.totalFailed}/${plResult.totalSent})',
      ),
    );

    _emit(const EngineEvent(phase: 'done', message: 'Test selesai'));

    return SpeedTestFinalResult(
      meta: meta,
      idleLatencyMs: idleResult.$1,
      idleJitterMs: idleResult.$2,
      idleLatencySamples: idleResult.$3,
      download: dlResult,
      upload: ulResult,
      packetLoss: plResult,
    );
  }

  // ── Fetch Meta ─────────────────────────────────────────────────────────────

  Future<NetworkMeta?> _fetchMeta() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/meta'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return NetworkMeta.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('meta error: $e');
    }
    return null;
  }

  // ── Idle Latency ───────────────────────────────────────────────────────────

  Future<(double avgMs, double jitterMs, List<int> samples)>
  _measureIdleLatency({int samples = 10}) async {
    final List<int> results = [];

    for (int i = 0; i < samples; i++) {
      if (_cancelled) break;
      final sw = Stopwatch()..start();
      try {
        await http
            .get(Uri.parse('$_baseUrl/__down?bytes=1'))
            .timeout(const Duration(seconds: 3));
        sw.stop();
        results.add(sw.elapsedMilliseconds);
        _emit(
          EngineEvent(
            phase: 'idle_latency',
            message: 'Ping ${i + 1}/$samples: ${sw.elapsedMilliseconds}ms',
            progress: (i + 1) / samples,
            currentLatencyMs: sw.elapsedMilliseconds,
          ),
        );
      } catch (_) {
        sw.stop();
      }
      await Future.delayed(const Duration(milliseconds: 80));
    }

    if (results.isEmpty) return (0.0, 0.0, <int>[]);

    final doubles = results.map((e) => e.toDouble()).toList();
    final avg = Stats.mean(doubles);
    final j = Stats.jitter(results);

    return (avg, j, results);
  }

  // ── Direction (Download / Upload) ──────────────────────────────────────────

  Future<DirectionResult> _measureDirection({
    required bool isDownload,
    required List<int> chunks,
  }) async {
    final List<ThroughputSample> samples = [];
    final List<int> loadedLatencies = [];
    final String phase = isDownload ? 'download' : 'upload';

    int totalChunks = chunks.length;

    for (int i = 0; i < chunks.length; i++) {
      if (_cancelled) break;

      final chunkSize = chunks[i];
      final chunkLabel = _formatBytes(chunkSize);

      _emit(
        EngineEvent(
          phase: phase,
          message:
              '${isDownload ? "DL" : "UL"} $chunkLabel (${i + 1}/$totalChunks)',
          progress: i / totalChunks,
        ),
      );

      // Jalankan throughput + loaded latency PARALEL
      final futures = await Future.wait([
        _measureThroughputChunk(
          isDownload: isDownload,
          bytes: chunkSize,
          onProgress: (mbps) {
            _emit(
              EngineEvent(
                phase: phase,
                message: '${isDownload ? "DL" : "UL"} $chunkLabel',
                progress: (i + (mbps > 0 ? 0.5 : 0)) / totalChunks,
                currentMbps: mbps,
              ),
            );
          },
        ),
        // Loaded latency: kirim probe kecil paralel setiap 300ms
        _collectLoadedLatency(durationMs: _estimateChunkDuration(chunkSize)),
      ]);

      final sample = futures[0] as ThroughputSample?;
      final latencies = futures[1] as List<int>;

      if (sample != null && sample.durationMs >= _minValidDurationMs) {
        samples.add(sample);
        _emit(
          EngineEvent(
            phase: phase,
            message:
                '${isDownload ? "DL" : "UL"} $chunkLabel → ${sample.mbps.toStringAsFixed(1)} Mbps',
            progress: (i + 1) / totalChunks,
            currentMbps: sample.mbps,
          ),
        );
      }

      loadedLatencies.addAll(latencies);
    }

    if (samples.isEmpty) {
      return DirectionResult(
        samples: [],
        loadedLatencies: [],
        p90Mbps: 0,
        p25Mbps: 0,
        p75Mbps: 0,
        peakMbps: 0,
        stdDevMbps: 0,
        avgLoadedLatencyMs: 0,
        loadedJitterMs: 0,
      );
    }

    final mbpsList = samples.map((s) => s.mbps).toList();
    final p90 = Stats.percentile(mbpsList, 0.90);
    final p25 = Stats.percentile(mbpsList, 0.25);
    final p75 = Stats.percentile(mbpsList, 0.75);
    final peak = mbpsList.reduce(max);
    final sd = Stats.stdDev(mbpsList);

    double avgLoaded = 0;
    double loadedJitter = 0;
    if (loadedLatencies.isNotEmpty) {
      avgLoaded = Stats.mean(loadedLatencies.map((e) => e.toDouble()).toList());
      loadedJitter = Stats.jitter(loadedLatencies);
    }

    return DirectionResult(
      samples: samples,
      loadedLatencies: loadedLatencies,
      p90Mbps: p90,
      p25Mbps: p25,
      p75Mbps: p75,
      peakMbps: peak,
      stdDevMbps: sd,
      avgLoadedLatencyMs: avgLoaded,
      loadedJitterMs: loadedJitter,
    );
  }

  // ── Throughput satu chunk ──────────────────────────────────────────────────

  Future<ThroughputSample?> _measureThroughputChunk({
    required bool isDownload,
    required int bytes,
    void Function(double mbps)? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    int transferred = 0;

    try {
      if (isDownload) {
        // Streaming download untuk progress real-time
        final req = http.Request(
          'GET',
          Uri.parse('$_baseUrl/__down?bytes=$bytes'),
        );
        final streamed = await http.Client()
            .send(req)
            .timeout(const Duration(seconds: 60));

        await for (final chunk in streamed.stream) {
          if (_cancelled) break;
          transferred += chunk.length;
          final sec = sw.elapsedMilliseconds / 1000;
          if (sec > 0) {
            onProgress?.call((transferred * 8) / (sec * 1_000_000));
          }
        }
      } else {
        // Upload: kirim dummy data
        final dummy = List<int>.filled(bytes, 0);
        final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/__up'));
        req.files.add(
          http.MultipartFile.fromBytes('file', dummy, filename: 'test'),
        );

        // Simulasi progress selama upload
        final timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
          final sec = sw.elapsedMilliseconds / 1000;
          if (sec > 0) {
            // estimasi linear
            final est = (bytes * (sw.elapsedMilliseconds / 10000))
                .clamp(0, bytes)
                .toInt();
            onProgress?.call((est * 8) / (sec * 1_000_000));
          }
        });

        await req.send().timeout(const Duration(seconds: 60));
        timer.cancel();
        transferred = bytes;
      }
    } catch (e) {
      debugPrint('chunk error: $e');
      sw.stop();
      return null;
    }

    sw.stop();
    if (transferred == 0 || sw.elapsedMilliseconds == 0) return null;

    final sec = sw.elapsedMilliseconds / 1000;
    final mbps = (transferred * 8) / (sec * 1_000_000);

    return ThroughputSample(
      chunkBytes: bytes,
      durationMs: sw.elapsedMilliseconds,
      mbps: mbps,
    );
  }

  // ── Loaded Latency (paralel saat DL/UL berjalan) ──────────────────────────

  /// Kirim probe kecil secara periodik selama [durationMs] ms
  /// untuk mengukur RTT saat koneksi sedang dipakai (loaded latency)
  Future<List<int>> _collectLoadedLatency({required int durationMs}) async {
    final results = <int>[];
    final end = DateTime.now().add(Duration(milliseconds: durationMs));
    const interval = Duration(milliseconds: 250);

    while (DateTime.now().isBefore(end) && !_cancelled) {
      final sw = Stopwatch()..start();
      try {
        await http
            .get(Uri.parse('$_baseUrl/__down?bytes=1'))
            .timeout(const Duration(milliseconds: 1500));
        sw.stop();
        results.add(sw.elapsedMilliseconds);
      } catch (_) {
        sw.stop();
      }
      await Future.delayed(interval);
    }

    return results;
  }

  // ── Packet Loss Simulation ─────────────────────────────────────────────────

  /// Kirim [probes] request secara bersamaan (concurrent), hitung yg timeout/error.
  /// Ini bukan ICMP packet loss (butuh native), tapi HTTP-level loss simulation.
  /// Berguna untuk deteksi jaringan tidak stabil.
  Future<PacketLossResult> _measurePacketLoss({int probes = 20}) async {
    int failed = 0;

    final futures = List.generate(probes, (i) async {
      await Future.delayed(Duration(milliseconds: i * 30)); // stagger sedikit
      try {
        await http
            .get(
              Uri.parse(
                '$_baseUrl/__down?bytes=1&nocache=${Random().nextInt(9999999)}',
              ),
            )
            .timeout(_packetLossTimeout);
        return true;
      } catch (_) {
        return false;
      }
    });

    final results = await Future.wait(futures);
    failed = results.where((r) => !r).length;

    return PacketLossResult(
      totalSent: probes,
      totalFailed: failed,
      lossPercent: (failed / probes) * 100,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Estimasi berapa lama chunk akan selesai (untuk durasi loaded latency probe)
  /// Asumsi koneksi minimal 1 Mbps → bytes / (1Mbps / 8) = seconds
  int _estimateChunkDuration(int bytes) {
    // Estimasi konservatif: asumsi 2 Mbps minimum
    const assumedBps = 2 * 1024 * 1024 / 8; // 2 Mbps in bytes/sec
    return ((bytes / assumedBps) * 1000 + 1000).toInt().clamp(1000, 60000);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }

  SpeedTestFinalResult _emptyResult(NetworkMeta? meta) => SpeedTestFinalResult(
    meta: meta,
    idleLatencyMs: 0,
    idleJitterMs: 0,
    idleLatencySamples: [],
    download: null,
    upload: null,
    packetLoss: null,
  );
}
