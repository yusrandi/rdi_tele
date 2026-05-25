class LatencyResult {
  /// idle ping
  final double unloadedLatency;

  /// ping saat download
  final double downloadLoadedLatency;

  /// ping saat upload
  final double uploadLoadedLatency;

  /// ping stability
  final double jitter;

  const LatencyResult({
    required this.unloadedLatency,
    required this.downloadLoadedLatency,
    required this.uploadLoadedLatency,
    required this.jitter,
  });
}
