import 'latency_result.dart';

class SpeedResult {
  final double downloadMbps;
  final double uploadMbps;

  final LatencyResult latency;

  const SpeedResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.latency,
  });
}
