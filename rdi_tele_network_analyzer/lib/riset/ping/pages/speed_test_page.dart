import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/speed_result.dart';
import '../services/speed_test_service.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage>
    with SingleTickerProviderStateMixin {
  final SpeedTestService service = SpeedTestService();

  StreamSubscription? pingSub;
  StreamSubscription? downloadSub;
  StreamSubscription? uploadSub;

  double realtimePing = 0;
  double realtimeDownload = 0;
  double realtimeUpload = 0;

  SpeedResult? result;
  bool testing = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Maximum speed for the gauge (Mbps)
  static const double maxGaugeSpeed = 500.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    pingSub = service.pingService.pingStream.listen((event) {
      setState(() {
        realtimePing = event;
      });
    });

    downloadSub = service.downloadService.speedStream.listen((event) {
      setState(() {
        realtimeDownload = event;
      });
    });

    uploadSub = service.uploadService.speedStream.listen((event) {
      setState(() {
        realtimeUpload = event;
      });
    });
  }

  Future<void> startTest() async {
    setState(() {
      testing = true;
      result = null;
    });

    final testResult = await service.start();

    setState(() {
      testing = false;
      result = testResult;
    });
  }

  @override
  void dispose() {
    pingSub?.cancel();
    downloadSub?.cancel();
    uploadSub?.cancel();
    _pulseController.dispose();
    service.dispose();
    super.dispose();
  }

  // Display values (show realtime during test, final result after test)
  double get displayDownloadSpeed =>
      testing ? realtimeDownload : (result?.downloadMbps ?? 0);
  double get displayUploadSpeed =>
      testing ? realtimeUpload : (result?.uploadMbps ?? 0);
  double get displayPing =>
      testing ? realtimePing : (result?.latency.unloadedLatency ?? 0);
  double get displayJitter => result?.latency.jitter ?? 0;
  double get downloadLoadedLatency =>
      result?.latency.downloadLoadedLatency ?? 0;
  double get uploadLoadedLatency => result?.latency.uploadLoadedLatency ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text(
          'Real Speed Analyzer',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F172A).withOpacity(0.95),
                const Color(0xFF0A0E1A),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Server Info Bar (mimicking Ookla)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF334155), width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto Select',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          'Best Server Available',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Main Speed Gauge
            _buildSpeedGauge(),

            const SizedBox(height: 32),

            // Realtime / Result Metrics Row
            _buildMetricsRow(),

            const SizedBox(height: 24),

            // Start Test Button
            _buildStartButton(),

            const SizedBox(height: 32),

            // Detailed Results (only shown after test completion)
            if (result != null && !testing) _buildDetailedResults(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedGauge() {
    final speedValue = displayDownloadSpeed.clamp(0.0, maxGaugeSpeed);
    final percentage = speedValue / maxGaugeSpeed;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Gauge background and needle
            SizedBox(
              width: 280,
              height: 160,
              child: CustomPaint(
                painter: SpeedGaugePainter(
                  percentage: percentage,
                  isTesting: testing,
                ),
              ),
            ),
            // Center speed text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (testing)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.speed,
                      color: Color(0xFF3B82F6),
                      size: 32,
                    ),
                  ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    speedValue.toStringAsFixed(speedValue < 10 ? 1 : 0),
                    key: ValueKey(speedValue),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: const Color(0xFF3B82F6).withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text(
                  'Mbps',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    testing ? 'DOWNLOAD TESTING' : 'DOWNLOAD SPEED',
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Legend for gauge max
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '0 Mbps',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(width: 180),
            Text(
              '${maxGaugeSpeed.toInt()} Mbps',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Upload Speed Card
          Expanded(
            child: _buildMetricTile(
              title: 'UPLOAD',
              value: displayUploadSpeed,
              unit: 'Mbps',
              icon: Icons.cloud_upload,
              color: const Color(0xFF8B5CF6),
              isLoading: testing && realtimeUpload == 0 && realtimeDownload > 0,
            ),
          ),
          const SizedBox(width: 16),
          // Ping Card
          Expanded(
            child: _buildMetricTile(
              title: 'PING',
              value: displayPing,
              unit: 'ms',
              icon: Icons.timer,
              color: const Color(0xFF10B981),
              isLoading: testing && realtimePing == 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required double value,
    required String unit,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1E293B), const Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            )
          else
            Text(
              value.toStringAsFixed(value < 10 ? 1 : 0),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: testing
              ? const LinearGradient(
                  colors: [Color(0xFF334155), Color(0xFF1E293B)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: testing
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: testing ? null : startTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: testing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'TESTING...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'START TEST',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDetailedResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF1F2937), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF3B82F6), size: 20),
              SizedBox(width: 8),
              Text(
                'DETAILED RESULTS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildResultCard(
                'Download',
                '${result!.downloadMbps.toStringAsFixed(2)} Mbps',
                Icons.arrow_downward,
                const Color(0xFF3B82F6),
              ),
              _buildResultCard(
                'Upload',
                '${result!.uploadMbps.toStringAsFixed(2)} Mbps',
                Icons.arrow_upward,
                const Color(0xFF8B5CF6),
              ),
              _buildResultCard(
                'Unloaded Ping',
                '${result!.latency.unloadedLatency.toStringAsFixed(1)} ms',
                Icons.speed,
                const Color(0xFF10B981),
              ),
              _buildResultCard(
                'Jitter',
                '${result!.latency.jitter.toStringAsFixed(1)} ms',
                Icons.show_chart,
                const Color(0xFFF59E0B),
              ),
              _buildResultCard(
                'DL Loaded Latency',
                '${result!.latency.downloadLoadedLatency.toStringAsFixed(1)} ms',
                Icons.cloud_download,
                const Color(0xFF06B6D4),
              ),
              _buildResultCard(
                'UL Loaded Latency',
                '${result!.latency.uploadLoadedLatency.toStringAsFixed(1)} ms',
                Icons.cloud_upload,
                const Color(0xFFEC4899),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Custom Gauge Painter for Speedometer style
class SpeedGaugePainter extends CustomPainter {
  final double percentage;
  final bool isTesting;

  SpeedGaugePainter({required this.percentage, required this.isTesting});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    final startAngle = -pi;
    final sweepAngle = pi;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Draw gradient arc (speed progress)
    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: isTesting
          ? [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)]
          : [const Color(0xFF10B981), const Color(0xFF3B82F6)],
      stops: const [0.0, 1.0],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressAngle =
        startAngle + (sweepAngle * percentage.clamp(0.0, 1.0));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle - startAngle,
      false,
      progressPaint,
    );

    // Draw needle
    final needleAngle = startAngle + (sweepAngle * percentage.clamp(0.0, 1.0));
    final needleLength = radius * 0.8;
    final needleX = center.dx + cos(needleAngle) * needleLength;
    final needleY = center.dy + sin(needleAngle) * needleLength;

    final needlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(needleX, needleY), needlePaint);

    // Draw center circle
    final centerPaint = Paint()
      ..color = isTesting ? const Color(0xFF3B82F6) : const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerPaint);

    // Add glow effect for testing
    if (isTesting) {
      final glowPaint = Paint()
        ..color = const Color(0xFF3B82F6).withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, 14, glowPaint);
    }

    // Draw tick marks
    const int ticks = 8;
    for (int i = 0; i <= ticks; i++) {
      final tickPercent = i / ticks;
      final tickAngle = startAngle + (sweepAngle * tickPercent);
      final innerRadius = radius - 8;
      final outerRadius = radius - 2;
      final x1 = center.dx + cos(tickAngle) * innerRadius;
      final y1 = center.dy + sin(tickAngle) * innerRadius;
      final x2 = center.dx + cos(tickAngle) * outerRadius;
      final y2 = center.dy + sin(tickAngle) * outerRadius;

      final tickPaint = Paint()
        ..color = Colors.white54
        ..strokeWidth = 1.5;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), tickPaint);
    }
  }

  @override
  bool shouldRepaint(SpeedGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.isTesting != isTesting;
  }
}
