// ─── engine/models.dart ───────────────────────────────────────────────────────
// Semua data model untuk speed test engine

/// Info client & server dari https://speed.cloudflare.com/meta
class NetworkMeta {
  final String clientIp;
  final int asn;
  final String isp; // asOrganization
  final String colo; // kode IATA datacenter Cloudflare, mis: SIN, CGK
  final String country;
  final String city;
  final String region;
  final String httpProtocol;

  const NetworkMeta({
    required this.clientIp,
    required this.asn,
    required this.isp,
    required this.colo,
    required this.country,
    required this.city,
    required this.region,
    required this.httpProtocol,
  });

  factory NetworkMeta.fromJson(Map<String, dynamic> j) => NetworkMeta(
    clientIp: j['clientIp'] ?? '-',
    asn: j['asn'] ?? 0,
    isp: j['asOrganization'] ?? '-',
    colo: j['colo'] ?? '-',
    country: j['country'] ?? '-',
    city: j['city'] ?? '-',
    region: j['region'] ?? '-',
    httpProtocol: j['httpProtocol'] ?? '-',
  );
}

/// Satu sample throughput dari satu chunk download/upload
class ThroughputSample {
  final int chunkBytes;
  final int durationMs;
  final double mbps;

  const ThroughputSample({
    required this.chunkBytes,
    required this.durationMs,
    required this.mbps,
  });
}

/// Hasil lengkap satu fase (download atau upload)
class DirectionResult {
  /// Semua raw samples throughput per chunk
  final List<ThroughputSample> samples;

  /// Semua latency yg diukur saat koneksi sedang loaded (ms)
  final List<int> loadedLatencies;

  /// p90 throughput — cara Cloudflare report final speed
  final double p90Mbps;

  /// p25 dan p75 untuk box plot / variance indicator
  final double p25Mbps;
  final double p75Mbps;

  /// Peak (max) throughput — untuk info
  final double peakMbps;

  /// Standard deviation Mbps — makin tinggi makin tidak stabil
  final double stdDevMbps;

  /// Loaded latency rata-rata (ms)
  final double avgLoadedLatencyMs;

  /// Loaded jitter (ms)
  final double loadedJitterMs;

  const DirectionResult({
    required this.samples,
    required this.loadedLatencies,
    required this.p90Mbps,
    required this.p25Mbps,
    required this.p75Mbps,
    required this.peakMbps,
    required this.stdDevMbps,
    required this.avgLoadedLatencyMs,
    required this.loadedJitterMs,
  });
}

/// Simulasi packet loss — hitung berapa persen request yang gagal/timeout
class PacketLossResult {
  final int totalSent;
  final int totalFailed;
  final double lossPercent;

  const PacketLossResult({
    required this.totalSent,
    required this.totalFailed,
    required this.lossPercent,
  });
}

/// Hasil akhir lengkap dari semua fase
class SpeedTestFinalResult {
  final NetworkMeta? meta;

  // Idle (sebelum test load)
  final double idleLatencyMs;
  final double idleJitterMs;
  final List<int> idleLatencySamples;

  // Download
  final DirectionResult? download;

  // Upload
  final DirectionResult? upload;

  // Packet loss simulation
  final PacketLossResult? packetLoss;

  // Bufferbloat = loaded latency - idle latency (makin kecil makin bagus)
  double get downloadBufferbloatMs =>
      download != null ? download!.avgLoadedLatencyMs - idleLatencyMs : 0;
  double get uploadBufferbloatMs =>
      upload != null ? upload!.avgLoadedLatencyMs - idleLatencyMs : 0;

  // Rating bufferbloat
  String get bufferbloatRating {
    final worst = [
      downloadBufferbloatMs,
      uploadBufferbloatMs,
    ].reduce((a, b) => a > b ? a : b);
    if (worst < 5) return 'A (Excellent)';
    if (worst < 30) return 'B (Good)';
    if (worst < 60) return 'C (Fair)';
    if (worst < 200) return 'D (Poor)';
    return 'F (Bad)';
  }

  const SpeedTestFinalResult({
    required this.meta,
    required this.idleLatencyMs,
    required this.idleJitterMs,
    required this.idleLatencySamples,
    required this.download,
    required this.upload,
    required this.packetLoss,
  });
}
