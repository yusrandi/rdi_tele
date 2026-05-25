// ─── engine/stats.dart ────────────────────────────────────────────────────────
// Helper statistik: percentile, std dev, jitter

import 'dart:math';

class Stats {
  /// Percentile dari list doubles (0.0–1.0)
  /// List tidak perlu sorted dulu, fungsi ini sort sendiri.
  static double percentile(List<double> values, double p) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final index = p * (sorted.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    if (lower == upper) return sorted[lower];
    return sorted[lower] + (sorted[upper] - sorted[lower]) * (index - lower);
  }

  /// Mean (rata-rata)
  static double mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Standard deviation population
  static double stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final m = mean(values);
    final variance =
        values.map((v) => pow(v - m, 2).toDouble()).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }

  /// Jitter = rata-rata selisih absolut antara sample berurutan
  static double jitter(List<int> latencies) {
    if (latencies.length < 2) return 0;
    double totalDiff = 0;
    for (int i = 1; i < latencies.length; i++) {
      totalDiff += (latencies[i] - latencies[i - 1]).abs();
    }
    return totalDiff / (latencies.length - 1);
  }

  /// Jitter dari list doubles
  static double jitterDouble(List<double> values) {
    if (values.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < values.length; i++) {
      total += (values[i] - values[i - 1]).abs();
    }
    return total / (values.length - 1);
  }

  /// Coefficient of variation (stdDev / mean) — ukuran relative instabilitas
  static double cv(List<double> values) {
    final m = mean(values);
    if (m == 0) return 0;
    return stdDev(values) / m;
  }
}
