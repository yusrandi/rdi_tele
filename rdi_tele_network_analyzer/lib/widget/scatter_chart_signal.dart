import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:realspeed_analyzer/integrated_network_dashboard.dart';
import 'package:realspeed_analyzer/model/telephony_snapshot.dart';

class ScatterChartSignalPage extends StatefulWidget {
  final List<TelephonySnapshot> data;
  const ScatterChartSignalPage({super.key, required this.data});

  @override
  State<ScatterChartSignalPage> createState() => _ScatterChartSignalPageState();
}

class _ScatterChartSignalPageState extends State<ScatterChartSignalPage> {
  final TAG = "ScatterChartSignalPage";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Cek jika data kosong
    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.signal_cellular_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Signal Data Available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start monitoring to see signal charts',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: screenWidth * 0.9,
            height: 300,
            child: _buildChart(
              title: 'RSSI vs Cell ID',
              yLabel: 'RSSI (dBm)',
              color: Colors.blue,
              getData: (d) => d.rssi.toDouble(),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: screenWidth * 0.9,
            height: 300,
            child: _buildChart(
              title: 'RSRQ vs Cell ID',
              yLabel: 'RSRQ (dB)',
              color: Colors.green,
              getData: (d) => d.rsrq.toDouble(),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: screenWidth * 0.9,
            height: 300,
            child: _buildChart(
              title: 'RSRP vs Cell ID',
              yLabel: 'RSRP (dBm)',
              color: Colors.orange,
              getData: (d) => d.rsrp.toDouble(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart({
    required String title,
    required String yLabel,
    required Color color,
    required double Function(TelephonySnapshot) getData,
  }) {
    // Group data berdasarkan koordinat (x,y) yang sama untuk menghitung jumlah overlapping
    final spotsData = <String, List<TelephonySnapshot>>{};

    for (var d in widget.data) {
      final key = '${d.cellId.toDouble()}_${getData(d)}';
      if (!spotsData.containsKey(key)) {
        spotsData[key] = [];
      }
      spotsData[key]!.add(d);
    }

    // Buat scatter spots dengan dotPainter custom berdasarkan jumlah data yang bertumpuk
    final spots = spotsData.entries.map((entry) {
      final data = entry.value.first;
      final count = entry.value.length;

      // Ukuran radius: 4 untuk 1 data, bertambah untuk data yang bertumpuk
      // Formula: base radius (4) + (count - 1) * 2
      final radius = 4.0 + (count - 1) * 2.0;

      return ScatterSpot(
        data.cellId.toDouble(),
        getData(data),
        dotPainter: FlDotCirclePainter(color: color, radius: radius),
      );
    }).toList();

    // Hitung min dan max untuk sumbu Y dengan pengecekan
    final yValues = widget.data.map((d) => getData(d)).toList();
    final minY = yValues.isEmpty
        ? 0.0
        : yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.isEmpty
        ? 0.0
        : yValues.reduce((a, b) => a > b ? a : b);
    final yRange = (maxY - minY).abs();
    final yPadding = yRange > 0 ? yRange * 0.1 : 5.0;

    // Hitung min dan max untuk sumbu X (Cell ID) dengan pengecekan
    final xValues = widget.data.map((d) => d.cellId.toDouble()).toList();
    final minXRaw = xValues.isEmpty
        ? 0.0
        : xValues.reduce((a, b) => a < b ? a : b);
    final maxXRaw = xValues.isEmpty
        ? 0.0
        : xValues.reduce((a, b) => a > b ? a : b);

    // Jika semua Cell ID sama (minX == maxX), beri padding manual
    final double minX, maxX;
    if (minXRaw == maxXRaw) {
      // Jika Cell ID sama semua, kurangi 1 untuk min dan tambah 1 untuk max
      minX = minXRaw - 1.0;
      maxX = maxXRaw + 1.0;
    } else {
      // Jika berbeda, gunakan padding 5% dari range
      final xRange = (maxXRaw - minXRaw).abs();
      final xPadding = xRange * 0.05;
      minX = minXRaw - xPadding;
      maxX = maxXRaw + xPadding;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.data.length} samples',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _chart(
            spots,
            spotsData,
            minX,
            maxX,
            minY,
            yPadding,
            maxY,
            yLabel,
          ),
        ),
      ],
    );
  }

  Widget _chart(
    List<ScatterSpot> spots,
    Map<String, List<TelephonySnapshot>> spotsData,
    double minX,
    double maxX,
    double minY,
    double yPadding,
    double maxY,
    String yLabel,
  ) {
    // print("[$TAG] : _chart minX $minX maxX $maxX minY $minY maxY $maxY");
    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        minX: minX,
        maxX: maxX,
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: ScatterTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            getTooltipItems: (ScatterSpot spot) {
              // Cari semua data yang sesuai dengan koordinat ini
              final key = '${spot.x}_${spot.y}';
              final matchingData = spotsData[key];

              if (matchingData != null && matchingData.isNotEmpty) {
                final count = matchingData.length;
                if (count > 1) {
                  // Jika ada beberapa data yang bertumpuk
                  final firstTime = DateFormat(
                    'HH:mm:ss',
                  ).format(matchingData.first.timestamp);
                  final lastTime = DateFormat(
                    'HH:mm:ss',
                  ).format(matchingData.last.timestamp);
                  return ScatterTooltipItem(
                    'Cell ID: ${spot.x.toInt()}\n$yLabel: ${spot.y.toStringAsFixed(1)}\nCount: $count samples\nTime: $firstTime - $lastTime',
                    // const TextStyle(color: Colors.black87, fontSize: 11),
                  );
                } else {
                  // Jika hanya satu data
                  final data = matchingData.first;
                  final timeStr = DateFormat('HH:mm:ss').format(data.timestamp);
                  return ScatterTooltipItem(
                    'Time: $timeStr\nCell ID: ${spot.x.toInt()}\n$yLabel: ${spot.y.toStringAsFixed(1)}',
                    // const TextStyle(color: Colors.black87, fontSize: 11),
                  );
                }
              }
              return ScatterTooltipItem(
                'Cell ID: ${spot.x.toInt()}\n$yLabel: ${spot.y.toStringAsFixed(1)}',
                // const TextStyle(color: Colors.black87, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              'Cell ID',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                yLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        scatterLabelSettings: ScatterLabelSettings(showLabel: false),
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
      swapAnimationCurve: Curves.easeInOut,
    );
  }
}
