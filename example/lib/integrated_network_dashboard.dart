import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:intl/intl.dart';
import 'package:rdi_tele/rdi_tele_method_channel.dart';
import 'package:rdi_tele/use_constant.dart';
import 'package:rdi_tele/use_tele.dart';

class IntegratedNetworkDashboard extends StatefulWidget {
  const IntegratedNetworkDashboard({super.key});

  @override
  State<IntegratedNetworkDashboard> createState() =>
      _IntegratedNetworkDashboardState();
}

class _IntegratedNetworkDashboardState
    extends State<IntegratedNetworkDashboard> {
  static const String TAG = "NetworkDashboard";

  // Telephony
  final _useTele = UseTele();
  final _rdiTelePlugin = MethodChannelRdiTele();
  Timer? _telephonyTimer;

  // Speed Test
  final _speedTest = FlutterInternetSpeedTest();

  // Theme Colors (Red Theme)
  final Color _primaryRed = const Color(0xFFE53935); // Vibrant Red
  final Color _darkRed = const Color(0xFFB71C1C); // Dark Red
  final Color _lightRed = const Color(0xFFFFCDD2); // Light Red
  final Color _accentOrange = const Color(0xFFFF9800); // Orange for accents

  // State Variables
  bool _isTesting = false;
  bool _isMonitoring = false;
  Duration _sessionDuration = const Duration(minutes: 3);
  Timer? _sessionTimer;

  // Telephony Data
  String _networkType = "Unknown";
  String _operatorName = "Unknown";
  String _deviceModel = "Unknown";
  String _currentSignal = "N/A";
  int _currentRsrp = 0;
  int _currentRsrq = 0;
  int _currentRssi = 0;
  int _currentCellId = 0;
  List<TelephonySnapshot> _telemetryHistory = [];

  // Speed Test Data
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  double _ping = 0;
  double _downloadProgress = 0;
  double _uploadProgress = 0;
  bool _speedTestRunning = false;
  String _speedUnit = 'Mbps';

  // Server Info
  String? _serverIp;
  String? _serverIsp;

  // Test Results
  final List<TestSession> _testSessions = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _telephonyTimer?.cancel();
    _sessionTimer?.cancel();
    _speedTest.cancelTest();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadDeviceInfo();
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

  void _startIntegratedTest() {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _isMonitoring = true;
      _sessionDuration = const Duration(minutes: 3);
      _telemetryHistory.clear();
    });

    // Start telephony monitoring
    _startTelemetryMonitoring();

    // Start session timer
    _startSessionTimer();

    // Start speed test after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      _runSpeedTest();
    });
  }

  void _startTelemetryMonitoring() {
    _telephonyTimer?.cancel();
    _telephonyTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      await _updateTelemetryData();
    });
  }

  Future<void> _updateTelemetryData() async {
    if (!_isMonitoring || !Platform.isAndroid) return;

    try {
      final tmData = await _rdiTelePlugin.getTM();
      final now = DateTime.now();

      final snapshot = TelephonySnapshot(
        timestamp: now,
        rsrp: tmData[UseTMConst.rsrp] as int? ?? 0,
        rsrq: tmData[UseTMConst.rsrq] as int? ?? 0,
        rssi: tmData[UseTMConst.rssi] as int? ?? 0,
        cellId: tmData[UseTMConst.cellid] as int? ?? 0,
        dbm: tmData[UseTMConst.dbm] as int? ?? 0,
      );

      setState(() {
        _currentRsrp = snapshot.rsrp;
        _currentRsrq = snapshot.rsrq;
        _currentRssi = snapshot.rssi;
        _currentCellId = snapshot.cellId;
        _currentSignal = "${snapshot.dbm} dBm";

        _telemetryHistory.insert(0, snapshot);

        // Keep last 30 snapshots
        if (_telemetryHistory.length > 30) {
          _telemetryHistory.removeLast();
        }
      });
    } catch (e) {
      print("[$TAG] Telemetry error: $e");
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  Future<void> _runSpeedTest() async {
    if (_speedTestRunning) return;

    setState(() => _speedTestRunning = true);

    await _speedTest.startTesting(
      useFastApi: true, // Nonaktifkan Fast API jika bermasalah
      //   downloadTestServer: "https://fast.com/", // Server alternatif
      //   uploadTestServer: "", // Server alternatif
      fileSizeInBytes: 100000000, // Kurangi file size (100MB)

      onStarted: () {
        setState(() {
          _downloadProgress = 0;
          _uploadProgress = 0;
        });
      },
      onCompleted: (TestResult download, TestResult upload) {
        setState(() {
          _downloadSpeed = download.transferRate;
          _uploadSpeed = upload.transferRate;
          _downloadProgress = 100;
          _uploadProgress = 100;
          _speedUnit = download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          _speedTestRunning = false;

          // Simulate ping based on speed
          _ping = _calculateSimulatedPing(download.transferRate);
        });
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          _speedUnit = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          if (data.type == TestType.download) {
            _downloadSpeed = data.transferRate;
            _downloadProgress = percent;
          } else {
            _uploadSpeed = data.transferRate;
            _uploadProgress = percent;
          }
        });
      },
      onDefaultServerSelectionDone: (client) {
        setState(() {
          _serverIp = client?.ip;
          _serverIsp = client?.isp;
        });
      },
      onError: (errorMessage, speedTestError) {
        print("Speed test error: $errorMessage");
        setState(() => _speedTestRunning = false);
      },
    );
  }

  double _calculateSimulatedPing(double speed) {
    if (speed > 100) return 5.0;
    if (speed > 50) return 15.0;
    if (speed > 20) return 30.0;
    if (speed > 5) return 60.0;
    return 120.0;
  }

  void _completeTestSession() {
    setState(() {
      _isTesting = false;
      _isMonitoring = false;
      _speedTestRunning = false;
    });

    _telephonyTimer?.cancel();
    _sessionTimer?.cancel();
    _speedTest.cancelTest();

    // Save session results
    _saveTestSession();
  }

  void _saveTestSession() {
    final session = TestSession(
      timestamp: DateTime.now(),
      telemetryData: List.from(_telemetryHistory),
      downloadSpeed: _downloadSpeed,
      uploadSpeed: _uploadSpeed,
      ping: _ping,
      networkType: _networkType,
      operatorName: _operatorName,
    );

    setState(() {
      _testSessions.insert(0, session);
      if (_testSessions.length > 5) {
        _testSessions.removeLast();
      }
    });

    // Show summary
    _showSessionSummary(session);
  }

  void _showSessionSummary(TestSession session) {
    final minutes = _sessionDuration.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (_sessionDuration.inSeconds % 60).toString().padLeft(2, '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.assessment, color: _primaryRed),
            const SizedBox(width: 8),
            const Text('Test Session Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: $minutes:$seconds'),
            const SizedBox(height: 8),
            Text('Download: ${_downloadSpeed.toStringAsFixed(1)} $_speedUnit'),
            Text('Upload: ${_uploadSpeed.toStringAsFixed(1)} $_speedUnit'),
            Text('Ping: ${_ping.toStringAsFixed(0)} ms'),
            const SizedBox(height: 8),
            Text('Samples Collected: ${_telemetryHistory.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _sessionDuration.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (_sessionDuration.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar dengan tema merah
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            backgroundColor: _darkRed,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'REAL SPEED ANALYZER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _darkRed,
                      _primaryRed,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Pattern overlay
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.speed,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Logo/Icon
                    Positioned(
                      top: 40,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.network_check,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Network Status Card dengan tema merah
                _buildNetworkStatusCard(),
                const SizedBox(height: 16),

                // Speed Test Card dengan tema merah
                _buildSpeedTestCard(),
                const SizedBox(height: 16),

                // Telemetry Card dengan tema merah
                _buildTelemetryCard(minutes, seconds),
                const SizedBox(height: 16),

                // Signal Quality Chart
                if (_telemetryHistory.isNotEmpty) _buildSignalChart(),

                // Previous Sessions
                if (_testSessions.isNotEmpty) _buildPreviousSessions(),
              ]),
            ),
          ),
        ],
      ),

      // Floating Action Button merah
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isTesting ? null : _startIntegratedTest,
        backgroundColor: _isTesting ? Colors.grey : _primaryRed,
        foregroundColor: Colors.white,
        icon: Icon(
          _isTesting ? Icons.stop : Icons.play_arrow,
          size: 24,
        ),
        label: Text(
          _isTesting ? 'STOP TEST' : 'START TEST',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildNetworkStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _lightRed,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryRed.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.network_cell,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'NETWORK STATUS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _primaryRed.withOpacity(0.3)),
                  ),
                  child: Text(
                    _networkType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primaryRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Signal Strength Indicator
            _buildSignalIndicator(),
            const SizedBox(height: 8),

            // Network Info Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildInfoTile(
                    'OPERATOR', _operatorName, Icons.business, _primaryRed),
                _buildInfoTile(
                    'DEVICE', _deviceModel, Icons.phone_android, _primaryRed),
                _buildInfoTile('CELL ID', _currentCellId.toString(),
                    Icons.location_on, _primaryRed),
                _buildInfoTile(
                    'TIME',
                    DateFormat('HH:mm:ss').format(DateTime.now()),
                    Icons.access_time,
                    _primaryRed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalIndicator() {
    Color signalColor = Colors.red[900]!;
    String signalText = 'POOR';
    IconData signalIcon = Icons.signal_cellular_0_bar;

    if (_currentRsrp >= -85) {
      signalColor = Colors.green;
      signalText = 'EXCELLENT';
      signalIcon = Icons.signal_cellular_4_bar;
    } else if (_currentRsrp >= -95) {
      signalColor = Colors.green[700]!;
      signalText = 'GOOD';
      signalIcon = Icons.signal_cellular_4_bar;
    } else if (_currentRsrp >= -105) {
      signalColor = Colors.orange;
      signalText = 'FAIR';
      signalIcon = Icons.signal_cellular_alt_2_bar;
    } else if (_currentRsrp >= -115) {
      signalColor = Colors.orange[800]!;
      signalText = 'WEAK';
      signalIcon = Icons.signal_cellular_alt_1_bar;
    } else {
      signalIcon = Icons.signal_cellular_0_bar;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(signalIcon, color: signalColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SIGNAL QUALITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: signalColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: signalColor.withOpacity(0.3)),
              ),
              child: Text(
                signalText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: signalColor,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Signal Bars dengan style modern
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Signal value
              SizedBox(
                width: 80,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentSignal,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: signalColor,
                        ),
                      ),
                      Text(
                        'dBm',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Signal bars
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(5, (index) {
                      double height = 20 + (index * 8.0);
                      bool isActive = index <= _getSignalBarsCount();

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color:
                                isActive ? signalColor : Colors.grey.shade300,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3),
                            ),
                          ),
                          height: isActive ? height : height * 0.3,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Signal Details
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSignalDetail(
                  'RSRP', '${_currentRsrp}', 'dBm', Icons.signal_cellular_alt),
              _buildSignalDetail(
                  'RSRQ', '${_currentRsrq}', 'dB', Icons.show_chart),
              _buildSignalDetail(
                  'RSSI', '${_currentRssi}', 'dBm', Icons.network_check),
            ],
          ),
        ),
      ],
    );
  }

  int _getSignalBarsCount() {
    if (_currentRsrp >= -85) return 4;
    if (_currentRsrp >= -95) return 3;
    if (_currentRsrp >= -105) return 2;
    if (_currentRsrp >= -115) return 1;
    return 0;
  }

  Widget _buildSignalDetail(
      String label, String value, String unit, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: _primaryRed),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            children: [
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
      String title, String value, IconData icon, Color color) {
    return Container(
      //   height: 50,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedTestCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFFEBEE), // Light red background
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryRed.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.speed, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SPEED TEST',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                if (_serverIp != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done,
                            size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Download Speed
            _buildSpeedItem(
              label: 'DOWNLOAD',
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF4CAF50), // Green for download
              speed: _downloadSpeed,
              progress: _downloadProgress,
              isActive: _speedTestRunning && _downloadProgress < 100,
            ),
            const SizedBox(height: 20),

            // Upload Speed
            _buildSpeedItem(
              label: 'UPLOAD',
              icon: Icons.arrow_upward_rounded,
              color: _accentOrange, // Orange for upload
              speed: _uploadSpeed,
              progress: _uploadProgress,
              isActive: _speedTestRunning &&
                  _downloadProgress >= 100 &&
                  _uploadProgress < 100,
            ),
            const SizedBox(height: 20),

            // Ping & Server Info
            _buildPingAndServerInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedItem({
    required String label,
    required IconData icon,
    required Color color,
    required double speed,
    required double progress,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isActive ? color.withOpacity(0.3) : Colors.grey.shade200),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (isActive)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Speed display with progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Bar
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          isActive ? 'Testing...' : 'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        speed.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _speedUnit,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Current Speed',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPingAndServerInfo() {
    Color pingColor = Colors.green;
    if (_ping > 100)
      pingColor = Colors.red;
    else if (_ping > 50) pingColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Ping
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed, color: pingColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'LATENCY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_ping.toStringAsFixed(0)} ms',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: pingColor,
                  ),
                ),
                Text(
                  _getPingQuality(_ping),
                  style: TextStyle(
                    fontSize: 11,
                    color: pingColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            width: 1,
            height: 60,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Server Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud, color: _primaryRed, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'SERVER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _serverIsp ?? 'Not Connected',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _serverIp ?? '--',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPingQuality(double ping) {
    if (ping < 20) return 'EXCELLENT';
    if (ping < 50) return 'GOOD';
    if (ping < 100) return 'FAIR';
    return 'POOR';
  }

  Widget _buildTelemetryCard(String minutes, String seconds) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFFCE4EC), // Light pink
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryRed.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'TELEMETRY MONITOR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isMonitoring
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _isMonitoring
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMonitoring
                            ? Icons.wifi_tethering
                            : Icons.wifi_tethering_off,
                        size: 14,
                        color: _isMonitoring ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isMonitoring ? 'LIVE' : 'OFF',
                        style: TextStyle(
                          fontSize: 10,
                          color: _isMonitoring ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Session Timer
            _buildSessionTimer(minutes, seconds),
            const SizedBox(height: 20),

            // Telemetry Stats
            if (_telemetryHistory.isNotEmpty) _buildTelemetryStats(),

            // Live Data Stream
            if (_isMonitoring) _buildLiveDataStream(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTimer(String minutes, String seconds) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isTesting
            ? Color(0xFFFFF8E1)
            : Colors.grey.shade100, // Light orange when testing
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isTesting
              ? _accentOrange.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
        boxShadow: _isTesting
            ? [
                BoxShadow(
                  color: _accentOrange.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isTesting ? _accentOrange : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isTesting ? Icons.timer : Icons.timer_off,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isTesting ? 'TEST SESSION ACTIVE' : 'READY FOR TESTING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isTesting ? _accentOrange : Colors.grey.shade600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isTesting
                      ? 'Collecting network data...'
                      : 'Start a session to monitor network',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isTesting ? Colors.black87 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isTesting
                  ? _accentOrange.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isTesting
                      ? _accentOrange.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3)),
            ),
            child: Text(
              '$minutes:$seconds',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _isTesting ? _accentOrange : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryStats() {
    final lastSnapshot = _telemetryHistory.first;
    final samples = _telemetryHistory.length;

    return Column(
      children: [
        Row(
          children: [
            _buildStatTile(
                'SAMPLES', samples.toString(), Icons.data_usage, _primaryRed),
            _buildStatTile('LAST RSRP', '${lastSnapshot.rsrp}',
                Icons.signal_cellular_alt, _primaryRed),
            _buildStatTile('AVG RSSI', _calculateAverageRssi(),
                Icons.show_chart, _primaryRed),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryRed.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _primaryRed.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.update, size: 12, color: _primaryRed),
              const SizedBox(width: 6),
              Text(
                'Last Update: ${DateFormat('HH:mm:ss').format(lastSnapshot.timestamp)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateAverageRssi() {
    if (_telemetryHistory.isEmpty) return '0';
    final sum = _telemetryHistory.map((e) => e.rssi).reduce((a, b) => a + b);
    return (sum / _telemetryHistory.length).toStringAsFixed(0);
  }

  Widget _buildStatTile(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDataStream() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'LIVE DATA STREAM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_telemetryHistory.length} points',
                style: TextStyle(
                  fontSize: 10,
                  color: _primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _telemetryHistory.take(15).length,
            itemBuilder: (context, index) {
              final data = _telemetryHistory[index];
              return _buildLiveDataPoint(data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLiveDataPoint(TelephonySnapshot data) {
    final Color pointColor = data.rsrp >= -85
        ? Colors.green
        : data.rsrp >= -95
            ? Colors.orange
            : Colors.red;

    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          // Value
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pointColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: pointColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '${data.rsrp}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: pointColor,
                  ),
                ),
                Text(
                  'RSRP',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Time
          Text(
            DateFormat('HH:mm').format(data.timestamp),
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: _primaryRed, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'SIGNAL TREND',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Last 20 samples',
                    style: TextStyle(
                      fontSize: 10,
                      color: _primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _telemetryHistory.take(20).length,
                itemBuilder: (context, index) {
                  final data = _telemetryHistory[index];
                  final height =
                      ((data.rsrp + 140) / 90 * 80).clamp(10.0, 80.0);
                  return Container(
                    width: 4,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: height > 60
                          ? Colors.green
                          : height > 40
                              ? Colors.orange
                              : Colors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    height: height,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: SignalChartPainter(
                  data: _telemetryHistory.take(20).toList(),
                  primaryColor: _primaryRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousSessions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: _primaryRed, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'RECENT SESSIONS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_testSessions.length} tests',
                    style: TextStyle(
                      fontSize: 11,
                      color: _primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._testSessions
                .take(3)
                .map((session) => _buildSessionItem(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(TestSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Date/Time
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(session.timestamp),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryRed,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(session.timestamp).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(session.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.2)),
                      ),
                      child: Text(
                        session.networkType,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSessionStat(
                        '↓ ${session.downloadSpeed.toStringAsFixed(1)}',
                        Colors.green),
                    const SizedBox(width: 8),
                    _buildSessionStat(
                        '↑ ${session.uploadSpeed.toStringAsFixed(1)}',
                        _accentOrange),
                    const SizedBox(width: 8),
                    _buildSessionStat(
                        '⏱ ${session.ping.toStringAsFixed(0)}ms', Colors.blue),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Operator: ${session.operatorName}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStat(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Custom Painter untuk chart signal
class SignalChartPainter extends CustomPainter {
  final List<TelephonySnapshot> data;
  final Color primaryColor;

  SignalChartPainter({required this.data, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final points = <Offset>[];

    // Convert data to points
    for (int i = 0; i < data.length; i++) {
      final x = (size.width / (data.length - 1)) * i;
      // Normalize RSRP to y coordinate (-140 to -50 range to 0-size.height)
      final normalizedY =
          ((data[i].rsrp + 140) / 90 * size.height).clamp(0.0, size.height);
      final y = size.height - normalizedY;
      points.add(Offset(x, y));
    }

    // Draw filled area
    final path = Path();
    path.moveTo(points.first.dx, size.height);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = primaryColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Models
class TelephonySnapshot {
  final DateTime timestamp;
  final int rsrp;
  final int rsrq;
  final int rssi;
  final int cellId;
  final int dbm;

  TelephonySnapshot({
    required this.timestamp,
    required this.rsrp,
    required this.rsrq,
    required this.rssi,
    required this.cellId,
    required this.dbm,
  });
}

class TestSession {
  final DateTime timestamp;
  final List<TelephonySnapshot> telemetryData;
  final double downloadSpeed;
  final double uploadSpeed;
  final double ping;
  final String networkType;
  final String operatorName;

  TestSession({
    required this.timestamp,
    required this.telemetryData,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    required this.networkType,
    required this.operatorName,
  });
}
