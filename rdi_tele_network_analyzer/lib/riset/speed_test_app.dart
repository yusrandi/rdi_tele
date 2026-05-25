// ─── main.dart ────────────────────────────────────────────────────────────────
import 'dart:math';
import 'package:flutter/material.dart';

import 'engine/models.dart';
import 'engine/speed_engine.dart';

void main() => runApp(const SpeedTestApp());

class SpeedTestApp extends StatelessWidget {
  const SpeedTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetProbe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080C14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SpeedTestPage(),
    );
  }
}

// ─── Page State ───────────────────────────────────────────────────────────────

enum AppPhase { idle, meta, idleLatency, download, upload, packetLoss, done }

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage>
    with TickerProviderStateMixin {
  // ── State vars ──────────────────────────────────────────────────────────────
  AppPhase _phase = AppPhase.idle;
  String _statusMessage = '';
  double _progress = 0;
  double _currentMbps = 0;
  int _currentLatencyMs = 0;

  // Live log stream (untuk scrolling log)
  final List<String> _log = [];

  // Engine & results
  SpeedEngine? _engine;
  SpeedTestFinalResult? _result;

  // Partial results for live display
  NetworkMeta? _meta;
  double _idleLatency = 0;
  double _idleJitter = 0;
  double _dlP90 = 0;
  double _ulP90 = 0;
  double _loadedLatencyDl = 0;
  double _loadedLatencyUl = 0;
  double _packetLossPercent = 0;

  // Animation
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _progressCtrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  // ── Control ──────────────────────────────────────────────────────────────────

  void _set(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _handleEvent(EngineEvent event) {
    _set(() {
      _statusMessage = event.message;
      if (event.progress != null) _progress = event.progress!;
      if (event.currentMbps != null) _currentMbps = event.currentMbps!;
      if (event.currentLatencyMs != null)
        _currentLatencyMs = event.currentLatencyMs!;

      // Update phase display
      switch (event.phase) {
        case 'meta':
          _phase = AppPhase.meta;
          break;
        case 'idle_latency':
          _phase = AppPhase.idleLatency;
          if (event.currentLatencyMs != null)
            _idleLatency = event.currentLatencyMs!.toDouble();
          break;
        case 'download':
          _phase = AppPhase.download;
          if (event.currentMbps != null) _dlP90 = event.currentMbps!;
          break;
        case 'upload':
          _phase = AppPhase.upload;
          if (event.currentMbps != null) _ulP90 = event.currentMbps!;
          break;
        case 'packet_loss':
          _phase = AppPhase.packetLoss;
          break;
        case 'done':
          _phase = AppPhase.done;
          break;
      }

      // Tambah ke log (max 50 baris)
      _log.add('[${event.phase.toUpperCase()}] ${event.message}');
      if (_log.length > 50) _log.removeAt(0);
    });
  }

  Future<void> _startTest() async {
    _set(() {
      _phase = AppPhase.meta;
      _log.clear();
      _result = null;
      _meta = null;
      _idleLatency = 0;
      _idleJitter = 0;
      _dlP90 = 0;
      _ulP90 = 0;
      _loadedLatencyDl = 0;
      _loadedLatencyUl = 0;
      _packetLossPercent = 0;
      _currentMbps = 0;
      _currentLatencyMs = 0;
      _progress = 0;
    });

    _engine = SpeedEngine(onEvent: _handleEvent);

    try {
      final result = await _engine!.runFullTest();
      _set(() {
        _result = result;
        _phase = AppPhase.done;
        _meta = result.meta;
        _idleLatency = result.idleLatencyMs;
        _idleJitter = result.idleJitterMs;
        _dlP90 = result.download?.p90Mbps ?? 0;
        _ulP90 = result.upload?.p90Mbps ?? 0;
        _loadedLatencyDl = result.download?.avgLoadedLatencyMs ?? 0;
        _loadedLatencyUl = result.upload?.avgLoadedLatencyMs ?? 0;
        _packetLossPercent = result.packetLoss?.lossPercent ?? 0;
      });
    } catch (e) {
      _set(() {
        _phase = AppPhase.done;
        _log.add('[ERROR] $e');
      });
    }
  }

  void _cancelTest() {
    _engine?.cancel();
    _set(() => _phase = AppPhase.idle);
  }

  void _reset() => _set(() {
    _phase = AppPhase.idle;
    _result = null;
    _log.clear();
  });

  bool get _isRunning => _phase != AppPhase.idle && _phase != AppPhase.done;

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildMetaCard(),
              const SizedBox(height: 16),
              _buildGaugeRow(),
              const SizedBox(height: 16),
              _buildMetricGrid(),
              const SizedBox(height: 16),
              if (_result != null) ...[
                _buildBufferbloatCard(),
                const SizedBox(height: 16),
                _buildVarianceCard(),
                const SizedBox(height: 16),
              ],
              _buildLogCard(),
              const SizedBox(height: 20),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00D4FF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
          ),
          child: const Text(
            'NetProbe',
            style: TextStyle(
              color: Color(0xFF00D4FF),
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _isRunning ? _statusMessage : 'Cloudflare Engine · Multi-metric',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (_isRunning)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: const Color(0xFF00D4FF).withOpacity(0.6),
            ),
          ),
      ],
    );
  }

  // ── Meta Card ─────────────────────────────────────────────────────────────

  Widget _buildMetaCard() {
    final m = _meta;
    return _card(
      child: m == null
          ? Row(
              children: [
                Icon(
                  Icons.lan_outlined,
                  color: Colors.white.withOpacity(0.2),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Info jaringan tersedia setelah test',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 11,
                  ),
                ),
              ],
            )
          : Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _metaChip(
                  Icons.phone_android_rounded,
                  m.clientIp,
                  const Color(0xFF00D4FF),
                ),
                _metaChip(
                  Icons.business_rounded,
                  '${m.isp} (AS${m.asn})',
                  const Color(0xFF00FF9D),
                ),
                _metaChip(
                  Icons.dns_rounded,
                  'CF: ${m.colo}',
                  const Color(0xFFFFAA00),
                ),
                _metaChip(
                  Icons.location_on_outlined,
                  '${m.city}, ${m.country}',
                  Colors.white54,
                ),
                _metaChip(
                  Icons.http_rounded,
                  m.httpProtocol,
                  const Color(0xFFCC88FF),
                ),
              ],
            ),
    );
  }

  Widget _metaChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Gauge Row ─────────────────────────────────────────────────────────────

  Widget _buildGaugeRow() {
    return Row(
      children: [
        Expanded(
          child: _buildGauge(
            label: 'Download',
            value: _dlP90,
            unit: 'Mbps',
            color: const Color(0xFF00D4FF),
            isActive: _phase == AppPhase.download,
            icon: Icons.download_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGauge(
            label: 'Upload',
            value: _ulP90,
            unit: 'Mbps',
            color: const Color(0xFF00FF9D),
            isActive: _phase == AppPhase.upload,
            icon: Icons.upload_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildGauge({
    required String label,
    required double value,
    required String unit,
    required Color color,
    required bool isActive,
    required IconData icon,
  }) {
    final isFinal = _result != null;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: isActive ? _pulseAnim.value : 1.0,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                color.withOpacity(isActive ? 0.13 : 0.04),
                const Color(0xFF080C14),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? color.withOpacity(0.6)
                  : color.withOpacity(0.15),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20)]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color.withOpacity(0.7), size: 16),
              const SizedBox(height: 8),
              Text(
                value > 0 ? value.toStringAsFixed(1) : '--',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFinal && value > 0 ? label : (isActive ? label : '---'),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Metric Grid ───────────────────────────────────────────────────────────

  Widget _buildMetricGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        _metricTile(
          label: 'Idle Latency',
          value: _idleLatency > 0
              ? '${_idleLatency.toStringAsFixed(1)}'
              : '---',
          unit: 'ms',
          color: const Color(0xFFFFAA00),
          icon: Icons.network_ping_rounded,
          isActive: _phase == AppPhase.idleLatency,
        ),
        _metricTile(
          label: 'Idle Jitter',
          value: _idleJitter > 0 ? '${_idleJitter.toStringAsFixed(1)}' : '---',
          unit: 'ms',
          color: const Color(0xFFFF6B9D),
          icon: Icons.stacked_line_chart_rounded,
          isActive: _phase == AppPhase.idleLatency,
        ),
        _metricTile(
          label: 'Packet Loss',
          value: _result != null
              ? '${_packetLossPercent.toStringAsFixed(1)}'
              : '---',
          unit: '%',
          color: _packetLossPercent > 1
              ? Colors.redAccent
              : const Color(0xFF88FF99),
          icon: Icons.wifi_tethering_error_rounded,
          isActive: _phase == AppPhase.packetLoss,
        ),
        _metricTile(
          label: 'Loaded DL',
          value: _loadedLatencyDl > 0
              ? '${_loadedLatencyDl.toStringAsFixed(0)}'
              : '---',
          unit: 'ms',
          color: const Color(0xFF88CCFF),
          icon: Icons.download_done_rounded,
          isActive: _phase == AppPhase.download,
        ),
        _metricTile(
          label: 'Loaded UL',
          value: _loadedLatencyUl > 0
              ? '${_loadedLatencyUl.toStringAsFixed(0)}'
              : '---',
          unit: 'ms',
          color: const Color(0xFF88FFCC),
          icon: Icons.upload_file_rounded,
          isActive: _phase == AppPhase.upload,
        ),
        _metricTile(
          label: 'DL Peak',
          value: _result?.download?.peakMbps != null
              ? '${_result!.download!.peakMbps.toStringAsFixed(1)}'
              : '---',
          unit: 'Mbps',
          color: const Color(0xFFCCAA00),
          icon: Icons.rocket_launch_rounded,
          isActive: false,
        ),
      ],
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isActive
            ? color.withOpacity(0.08)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? color.withOpacity(0.4)
              : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withOpacity(0.7), size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: color.withOpacity(0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bufferbloat Card ──────────────────────────────────────────────────────

  Widget _buildBufferbloatCard() {
    final r = _result!;
    final dlBB = r.downloadBufferbloatMs;
    final ulBB = r.uploadBufferbloatMs;
    final rating = r.bufferbloatRating;
    final ratingColor = rating.startsWith('A')
        ? const Color(0xFF00FF9D)
        : rating.startsWith('B')
        ? const Color(0xFF88FF44)
        : rating.startsWith('C')
        ? const Color(0xFFFFAA00)
        : Colors.redAccent;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Bufferbloat',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ratingColor.withOpacity(0.4)),
                ),
                child: Text(
                  rating,
                  style: TextStyle(
                    color: ratingColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bufferbloat = loaded latency − idle latency. Makin kecil makin baik.\nTinggi = ISP atau router kamu tidak handle queue dengan baik.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 9.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _bbBar(
                  label: 'DL Bufferbloat',
                  value: dlBB,
                  idleMs: r.idleLatencyMs,
                  loadedMs: r.download?.avgLoadedLatencyMs ?? 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bbBar(
                  label: 'UL Bufferbloat',
                  value: ulBB,
                  idleMs: r.idleLatencyMs,
                  loadedMs: r.upload?.avgLoadedLatencyMs ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bbBar({
    required String label,
    required double value,
    required double idleMs,
    required double loadedMs,
  }) {
    final color = value < 5
        ? const Color(0xFF00FF9D)
        : value < 30
        ? const Color(0xFFFFAA00)
        : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)} ms',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          '${idleMs.toStringAsFixed(0)}ms → ${loadedMs.toStringAsFixed(0)}ms',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9),
        ),
      ],
    );
  }

  // ── Variance Card ─────────────────────────────────────────────────────────

  Widget _buildVarianceCard() {
    final dl = _result!.download;
    final ul = _result!.upload;
    if (dl == null && ul == null) return const SizedBox();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Speed Variance & Samples',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (dl != null) ...[
            _varianceRow('Download', dl, const Color(0xFF00D4FF)),
            const SizedBox(height: 8),
          ],
          if (ul != null) _varianceRow('Upload', ul, const Color(0xFF00FF9D)),
          const SizedBox(height: 10),
          // Mini sparkline dots untuk tiap sample
          if (dl != null)
            _sampleDots('DL Samples', dl, const Color(0xFF00D4FF)),
          if (ul != null) ...[
            const SizedBox(height: 6),
            _sampleDots('UL Samples', ul, const Color(0xFF00FF9D)),
          ],
        ],
      ),
    );
  }

  Widget _varianceRow(String label, DirectionResult r, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // p25 – p90 bar
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final maxMbps = max(r.peakMbps, 1.0);
                  final p25x = (r.p25Mbps / maxMbps * constraints.maxWidth)
                      .clamp(0.0, constraints.maxWidth);
                  final p90x = (r.p90Mbps / maxMbps * constraints.maxWidth)
                      .clamp(0.0, constraints.maxWidth);
                  final peakX = (r.peakMbps / maxMbps * constraints.maxWidth)
                      .clamp(0.0, constraints.maxWidth);
                  return SizedBox(
                    height: 14,
                    child: Stack(
                      children: [
                        // Background track
                        Container(
                          height: 4,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // p25–p90 range
                        Positioned(
                          left: p25x,
                          top: 3,
                          child: Container(
                            width: max(p90x - p25x, 4),
                            height: 8,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        // p90 marker
                        Positioned(
                          left: p90x - 1,
                          top: 1,
                          child: Container(
                            width: 3,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'p25: ${r.p25Mbps.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: color.withOpacity(0.5),
                      fontSize: 8,
                    ),
                  ),
                  Text(
                    'p90: ${r.p90Mbps.toStringAsFixed(1)} Mbps',
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'σ: ${r.stdDevMbps.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sampleDots(String label, DirectionResult r, Color color) {
    if (r.samples.isEmpty) return const SizedBox();
    final maxMbps = r.samples.map((s) => s.mbps).reduce(max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: r.samples.map((s) {
              final h = max((s.mbps / maxMbps * 36), 4.0);
              final isP90 = (s.mbps - r.p90Mbps).abs() < 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Tooltip(
                    message:
                        '${_formatBytes(s.chunkBytes)}: ${s.mbps.toStringAsFixed(1)} Mbps',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: isP90 ? color : color.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatBytes(s.chunkBytes),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Log Card ──────────────────────────────────────────────────────────────

  Widget _buildLogCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                'Engine Log',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _log.isEmpty
                ? Center(
                    child: Text(
                      'Log akan muncul saat test berjalan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 10,
                      ),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _log.length,
                    itemBuilder: (_, i) {
                      final line = _log[_log.length - 1 - i];
                      Color lineColor = Colors.white.withOpacity(0.45);
                      if (line.contains('[DOWNLOAD]'))
                        lineColor = const Color(0xFF00D4FF).withOpacity(0.8);
                      if (line.contains('[UPLOAD]'))
                        lineColor = const Color(0xFF00FF9D).withOpacity(0.8);
                      if (line.contains('[IDLE_LATENCY]'))
                        lineColor = const Color(0xFFFFAA00).withOpacity(0.8);
                      if (line.contains('[ERROR]'))
                        lineColor = Colors.redAccent;
                      return Text(
                        line,
                        style: TextStyle(
                          color: lineColor,
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────────────────────────────

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isRunning
                ? null
                : (_phase == AppPhase.done ? _reset : _startTest),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 50,
              decoration: BoxDecoration(
                gradient: _isRunning
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF00D4FF), Color(0xFF006EA8)],
                      ),
                color: _isRunning ? const Color(0xFF131B27) : null,
                borderRadius: BorderRadius.circular(13),
                boxShadow: _isRunning
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Center(
                child: _isRunning
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _phaseName(_phase),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _phase == AppPhase.done ? 'Tes Ulang' : 'Mulai Tes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (_isRunning) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _cancelTest,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _phaseName(AppPhase p) {
    switch (p) {
      case AppPhase.meta:
        return 'Inisialisasi...';
      case AppPhase.idleLatency:
        return 'Idle Latency...';
      case AppPhase.download:
        return 'Download...';
      case AppPhase.upload:
        return 'Upload...';
      case AppPhase.packetLoss:
        return 'Packet Loss...';
      default:
        return '';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: child,
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()}K';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)}M';
  }
}
