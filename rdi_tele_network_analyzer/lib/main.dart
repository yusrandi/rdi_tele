import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:realspeed_analyzer/integrated_network_dashboard.dart';
import 'package:realspeed_analyzer/screens/privacy_policy_screen.dart';
import 'package:realspeed_analyzer/services/location_permission_service.dart';
import 'package:realspeed_analyzer/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RealSpeed Analyzer',
      theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
      home: const AppEntryPoint(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _isLoading = true;
  bool _showPrivacyPolicy = false;
  bool _permissionsGranted = false;

  bool _showBackgroundLocationDialog = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    final permissionsAsked = prefs.getBool('permissions_asked') ?? false;

    if (isFirstLaunch) {
      setState(() {
        _isLoading = false;
        _showPrivacyPolicy = true;
      });
    } else if (!permissionsAsked) {
      _requestPermissions();
    } else {
      _checkPermissionsAndNavigate();
    }
  }

  Future<void> _onPrivacyAgree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);

    setState(() {
      _showPrivacyPolicy = false;
    });

    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final granted = await PermissionService.requestTelephonyPermissions();
    final locationGranted = await LocationPermissionService.request();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_asked', true);

    if (granted && locationGranted) {
      // ← Minta background location setelah foreground granted
      setState(() {
        _showBackgroundLocationDialog = true;
        _permissionsGranted = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _permissionsGranted = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPermissionsAndNavigate() async {
    final locationStatus = await Permission.location.status;
    final phoneStatus = await Permission.phone.status;

    setState(() {
      _permissionsGranted = locationStatus.isGranted && phoneStatus.isGranted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    if (_showPrivacyPolicy) {
      return PrivacyPolicyScreen(onAgree: _onPrivacyAgree);
    }

    if (!_permissionsGranted) {
      return ManualPermissionScreen(
        onRetry: _requestPermissions,
        onSkip: () {
          setState(() {
            _permissionsGranted = true;
          });
        },
      );
    }

    return UpgradeAlert(
      dialogStyle: UpgradeDialogStyle.cupertino,
      showIgnore: false,
      showLater: false,
      upgrader: Upgrader(
        // Set to false to disable debug logging in production
        debugLogging: true,
        // Show alert on every launch until user updates
        durationUntilAlertAgain: const Duration(days: 1),
        // Minimum version can be set server-side via store listing
        languageCode: 'id',
        countryCode: 'ID',
        messages: UpgraderMessages(code: 'id'),
        minAppVersion: '2.0.0',
      ),
      // Force update: remove all dismiss options
      barrierDismissible: false,
      child: const IntegratedNetworkDashboard(),
    );
  }
}

// ── Widget untuk request background location ──────────────

class _BackgroundLocationWrapper extends StatefulWidget {
  final bool showDialog;
  final VoidCallback onDone;
  final Widget child;

  const _BackgroundLocationWrapper({
    required this.showDialog,
    required this.onDone,
    required this.child,
  });

  @override
  State<_BackgroundLocationWrapper> createState() =>
      _BackgroundLocationWrapperState();
}

class _BackgroundLocationWrapperState
    extends State<_BackgroundLocationWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.showDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBackgroundLocationDialog();
      });
    }
  }

  Future<void> _showBackgroundLocationDialog() async {
    // Cek apakah sudah granted
    final already = await PermissionService.isBackgroundLocationGranted();
    if (already || !mounted) {
      widget.onDone();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Izin Lokasi Background',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Diperlukan untuk monitoring sinyal & GPS saat '
                      'aplikasi berjalan di background.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pada layar berikutnya, pilih:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _permStep(
              '"Izinkan Setiap Saat"',
              Icons.check_circle,
              Colors.green,
            ),
            _permStep('Bukan "Hanya saat digunakan"', Icons.cancel, Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDone();
            },
            child: Text(
              'Lewati',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await PermissionService.requestBackgroundLocation();
              widget.onDone();
            },
            child: const Text('Izinkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _permStep(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.network_check,
                size: 80,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'REAL SPEED ANALYZER',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Professional Network Testing Tool',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const Spacer(),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Manual Permission Screen ─────────────────────────────────────────────────
class ManualPermissionScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onSkip;

  const ManualPermissionScreen({
    super.key,
    required this.onRetry,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions Required'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(
              Icons.warning_rounded,
              size: 80,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 24),
            Text(
              'Permissions Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Network Analyzer needs certain permissions to function properly:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 32),
            _buildPermissionStep('1. Go to App Settings', Icons.settings),
            _buildPermissionStep('2. Find "Network Analyzer"', Icons.search),
            _buildPermissionStep('3. Tap "Permissions"', Icons.security),
            _buildPermissionStep(
              '4. Enable all permissions',
              Icons.check_circle,
            ),
            const SizedBox(height: 40),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await openAppSettings();
                      onRetry();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OPEN SETTINGS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Continue with Limited Features',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionStep(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.red.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
