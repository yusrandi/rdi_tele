import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({Key? key}) : super(key: key);

  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  final internetSpeedTest = FlutterInternetSpeedTest()..enableLog();

  bool _testInProgress = false;
  double _downloadRate = 0;
  double _uploadRate = 0;
  double _downloadProgress = 0;
  double _uploadProgress = 0;
  int _downloadCompletionTime = 0;
  int _uploadCompletionTime = 0;
  bool _isServerSelectionInProgress = false;

  String? _ip;
  String? _asn;
  String? _isp;
  String _unitText = 'Mbps';

  // Untuk animasi
  late AnimationController _downloadAnimationController;
  late AnimationController _uploadAnimationController;
  late Animation<double> _downloadAnimation;
  late Animation<double> _uploadAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reset();
    });
  }

  @override
  void dispose() {
    internetSpeedTest.cancelTest();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // Download Section
            _buildSpeedCard(
              title: 'DOWNLOAD',
              icon: Icons.download_rounded,
              color: Colors.green,
              rate: _downloadRate,
              progress: _downloadProgress,
              unit: _unitText,
              completionTime: _downloadCompletionTime,
              isActive: _testInProgress && _downloadProgress < 100,
            ),
            const SizedBox(height: 20),

            // Upload Section
            _buildSpeedCard(
              title: 'UPLOAD',
              icon: Icons.upload_rounded,
              color: Colors.orange,
              rate: _uploadRate,
              progress: _uploadProgress,
              unit: _unitText,
              completionTime: _uploadCompletionTime,
              isActive: _testInProgress &&
                  _downloadProgress >= 100 &&
                  _uploadProgress < 100,
            ),
            const SizedBox(height: 20),

            // Server Info
            _buildServerInfo(),
            const SizedBox(height: 24),

            // Control Buttons
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SPEED TEST',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Test your internet connection speed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _testInProgress
                ? Colors.orange.shade100
                : Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _testInProgress ? Icons.sync : Icons.wifi,
            color: _testInProgress ? Colors.orange : Colors.green,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedCard({
    required String title,
    required IconData icon,
    required Color color,
    required double rate,
    required double progress,
    required String unit,
    required int completionTime,
    required bool isActive,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: color.withOpacity(0.3), width: 2)
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
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                if (completionTime > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(completionTime / 1000).toStringAsFixed(1)}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${isActive ? 'Testing...' : 'Completed'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? color : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Speed Display
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        rate.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unit,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Current Speed',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_rounded, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'SERVER INFORMATION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isServerSelectionInProgress)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Selecting optimal server...',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('IP Address', _ip ?? '--'),
                const SizedBox(height: 8),
                _buildInfoRow('ASN', _asn ?? '--'),
                const SizedBox(height: 8),
                _buildInfoRow('ISP', _isp ?? '--'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _testInProgress ? null : _startTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _testInProgress ? Icons.sync : Icons.play_arrow_rounded,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _testInProgress ? 'TESTING...' : 'START TEST',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_testInProgress) ...[
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _cancelTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade200),
              ),
              elevation: 0,
            ),
            child: const Row(
              children: [
                Icon(Icons.stop_rounded, size: 20),
                SizedBox(width: 8),
                Text('STOP'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _startTest() async {
    reset();

    await internetSpeedTest.startTesting(
      onStarted: () {
        setState(() => _testInProgress = true);
      },
      onCompleted: (TestResult download, TestResult upload) {
        if (kDebugMode) {
          print(
              'Test completed: Download ${download.transferRate}, Upload ${upload.transferRate}');
        }
        setState(() {
          _downloadRate = download.transferRate;
          _unitText = download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          _downloadProgress = 100;
          _downloadCompletionTime = download.durationInMillis;

          _uploadRate = upload.transferRate;
          _uploadProgress = 100;
          _uploadCompletionTime = upload.durationInMillis;
          _testInProgress = false;
        });

        // Callback jika ada
        // if (widget.onTestComplete != null) {
        //   widget.onTestComplete!(SpeedTestResult(
        //     downloadSpeed: download.transferRate,
        //     uploadSpeed: upload.transferRate,
        //     ping: 0, // Tidak tersedia dari package ini
        //   ));
        // }
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          if (data.type == TestType.download) {
            _downloadRate = data.transferRate;
            _downloadProgress = percent;
          } else {
            _uploadRate = data.transferRate;
            _uploadProgress = percent;
          }
        });
      },
      onError: (String errorMessage, String speedTestError) {
        if (kDebugMode) {
          print('Error: $errorMessage, $speedTestError');
        }
        _showErrorDialog(errorMessage);
        reset();
      },
      onDefaultServerSelectionInProgress: () {
        setState(() {
          _isServerSelectionInProgress = true;
        });
      },
      onDefaultServerSelectionDone: (Client? client) {
        setState(() {
          _isServerSelectionInProgress = false;
          _ip = client?.ip;
          _asn = client?.asn;
          _isp = client?.isp;
        });
      },
      onDownloadComplete: (TestResult data) {
        setState(() {
          _downloadRate = data.transferRate;
          _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          _downloadCompletionTime = data.durationInMillis;
        });
      },
      onUploadComplete: (TestResult data) {
        setState(() {
          _uploadRate = data.transferRate;
          _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          _uploadCompletionTime = data.durationInMillis;
        });
      },
      onCancel: () {
        reset();
      },
    );
  }

  void _cancelTest() {
    internetSpeedTest.cancelTest();
    reset();
  }

  void reset() {
    setState(() {
      _testInProgress = false;
      _downloadRate = 0;
      _uploadRate = 0;
      _downloadProgress = 0;
      _uploadProgress = 0;
      _unitText = 'Mbps';
      _downloadCompletionTime = 0;
      _uploadCompletionTime = 0;
      _isServerSelectionInProgress = false;
    });
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Test Error'),
          ],
        ),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

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
