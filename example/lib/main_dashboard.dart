import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rdi_tele/rdi_tele_method_channel.dart';
import 'package:rdi_tele/use_constant.dart';
import 'package:rdi_tele/use_tele.dart';
import 'package:rdi_tele_example/speed_test.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const String TAG = "RDI:Main";

  final _useTele = UseTele();
  final _rdiTelePlugin = MethodChannelRdiTele();
  Timer? _telephonyTimer;
  Timer? _countdownTimer;
  Duration _sessionDuration = const Duration(minutes: 3);

  // Data untuk tampilan
  final List<TelephonyData> _telephonyHistory = [];
  SpeedTestResult? _speedTestResult;
  bool _isTesting = false;
  bool _isMonitoring = false;

  // Informasi perangkat
  String _networkType = "Unknown";
  String _operatorName = "Unknown";
  String _deviceModel = "Unknown";
  String _currentSignal = "N/A";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _telephonyTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadDeviceInfo();
    // Mulai monitoring teleponi otomatis
    // _startTelephonyMonitoring();
  }

  Future<void> _loadDeviceInfo() async {
    if (Platform.isAndroid) {
      _networkType = _useTele.networkType;
      _operatorName = _useTele.operatorName;

      final deviceInfo = await _rdiTelePlugin.getDeviceInfo();
      setState(() {
        _deviceModel =
            deviceInfo[UseDeviceInfoConst.myDeviceModel] ?? "Unknown";
      });
    }
  }

  void _startTelephonyMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    // Update data teleponi setiap 2 detik
    _telephonyTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateTelephonyData();
    });
  }

  Future<void> _updateTelephonyData() async {
    if (Platform.isAndroid && _isMonitoring) {
      // Tambahkan kondisi
      try {
        final tmData = await _rdiTelePlugin.getTM();
        final now = DateTime.now();
        final formattedTime = DateFormat('HH:mm:ss').format(now);

        setState(() {
          _currentSignal = "${tmData[UseTMConst.dbm] ?? 0} dBm";

          _telephonyHistory.insert(
              0,
              TelephonyData(
                time: formattedTime,
                rsrp: tmData[UseTMConst.rsrp]?.toString() ?? "N/A",
                rsrq: tmData[UseTMConst.rsrq]?.toString() ?? "N/A",
                rssi: tmData[UseTMConst.rssi]?.toString() ?? "N/A",
                cellId: tmData[UseTMConst.cellid]?.toString() ?? "N/A",
              ));

          // Batasi history ke 20 item terbaru
          if (_telephonyHistory.length > 20) {
            _telephonyHistory.removeLast();
          }
        });
      } catch (e) {
        print("[$TAG] Error getting TM data: $e");
      }
    }
  }

  void _startTestSession() {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _sessionDuration = const Duration(minutes: 3);
      _telephonyHistory.clear();
    });

    // Mulai monitoring teleponi
    _startTelephonyMonitoring();

    // Mulai countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        final seconds = _sessionDuration.inSeconds - 1;
        if (seconds <= 0) {
          timer.cancel();
          _completeTestSession();
        } else {
          _sessionDuration = Duration(seconds: seconds);
        }
      });
    });
  }

  void _stopTelephonyMonitoring() {
    _telephonyTimer?.cancel();
    _telephonyTimer = null;
    _isMonitoring = false;
  }

  void _completeTestSession() {
    setState(() {
      _isTesting = false;
    });

    // Hentikan monitoring
    _stopTelephonyMonitoring();

    // Simpan atau kirim data hasil test
    _saveTestResults();
  }

  void _saveTestResults() {
    // Implementasi penyimpanan data
    print("[$TAG] Test session completed");
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _sessionDuration.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (_sessionDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Quality Monitor'),
        backgroundColor: Colors.blue[800],
        elevation: 2,
      ),
      body: SpeedTestPage(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTesting ? null : _startTestSession,
        icon: Icon(_isTesting ? Icons.stop : Icons.play_arrow),
        label: Text(_isTesting ? 'Testing...' : 'Start Test'),
        backgroundColor: _isTesting ? Colors.grey : Colors.blue,
      ),
    );
  }

  Column _body(String minutes, String seconds) {
    return Column(
      children: [
        // Header Info
        _buildInfoHeader(),

        // Speed Test Section
        const Expanded(
          flex: 2,
          child: Card(
            margin: EdgeInsets.all(12),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SpeedTestPage(
                  //   onTestComplete: (downloadRate, uploadRate, ping) {

                  //   },
                  ),
            ),
          ),
        ),

        // Telephony Monitoring Section
        Expanded(
          flex: 3,
          child: _buildTelephonySection(minutes, seconds),
        ),
      ],
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.network_cell, 'Network', _networkType),
          _buildInfoItem(Icons.business, 'Operator', _operatorName),
          _buildInfoItem(Icons.phone_android, 'Device', _deviceModel),
          _buildInfoItem(Icons.signal_cellular_alt, 'Signal', _currentSignal),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Colors.blue[700]),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTelephonySection(String minutes, String seconds) {
    return Column(
      children: [
        // Timer dan status
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: _isTesting ? Colors.orange[100] : Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isTesting ? Icons.sync : Icons.pause,
                color: _isTesting ? Colors.orange : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _isTesting ? 'Monitoring Active' : 'Monitoring Paused',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isTesting ? Colors.orange[800] : Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                '$minutes:$seconds',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),

        // History List
        Expanded(
          child: _telephonyHistory.isEmpty
              ? const Center(
                  child: Text('No telephony data available'),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: _telephonyHistory.length,
                  itemBuilder: (context, index) {
                    final data = _telephonyHistory[index];
                    return _buildTelephonyRow(data);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTelephonyRow(TelephonyData data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            data.time,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 12,
              children: [
                _buildDataChip('RSRP', data.rsrp, Colors.red),
                _buildDataChip('RSRQ', data.rsrq, Colors.orange),
                _buildDataChip('RSSI', data.rssi, Colors.green),
                _buildDataChip('Cell ID', data.cellId, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataChip(String label, String value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      labelStyle: const TextStyle(fontSize: 12),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      visualDensity: VisualDensity.compact,
    );
  }
}

// Model data untuk teleponi
class TelephonyData {
  final String time;
  final String rsrp;
  final String rsrq;
  final String rssi;
  final String cellId;

  TelephonyData({
    required this.time,
    required this.rsrp,
    required this.rsrq,
    required this.rssi,
    required this.cellId,
  });
}

// Model untuk hasil speed test
class SpeedTestResult {
  final double downloadSpeed;
  final double uploadSpeed;
  final double ping;

  SpeedTestResult({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
  });
}
