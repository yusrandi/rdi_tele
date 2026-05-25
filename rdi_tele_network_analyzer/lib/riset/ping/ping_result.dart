class PingResult {
  /// Average latency (ms)
  final double averagePing;

  /// Jitter (ms)
  final double jitter;

  /// Raw ping list
  final List<double> pings;

  const PingResult({
    required this.averagePing,
    required this.jitter,
    required this.pings,
  });
}
