import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:realspeed_analyzer/integrated_network_dashboard.dart';
import 'package:realspeed_analyzer/screens/privacy_policy_screen.dart';
import 'package:realspeed_analyzer/services/permission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // First time launch, show privacy policy
      setState(() {
        _isLoading = false;
        _showPrivacyPolicy = true;
      });
    } else if (!permissionsAsked) {
      // Not first launch but haven't asked permissions
      _requestPermissions();
    } else {
      // Already have permissions, go to main app
      _checkPermissionsAndNavigate();
    }
  }

  Future<void> _onPrivacyAgree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);

    setState(() {
      _showPrivacyPolicy = false;
    });

    // Request permissions after agreeing
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final granted = await PermissionService.requestTelephonyPermissions();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_asked', true);

    if (granted) {
      // Permissions granted, go to main app
      setState(() {
        _permissionsGranted = true;
      });
    } else {
      // Permissions not granted, show manual permission screen
      setState(() {
        _permissionsGranted = false;
      });
    }
  }

  Future<void> _checkPermissionsAndNavigate() async {
    // Check if permissions are already granted
    final locationStatus = await Permission.location.status;
    final phoneStatus = await Permission.phone.status;

    if (locationStatus.isGranted && phoneStatus.isGranted) {
      setState(() {
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
          // User can skip but with limited functionality
          setState(() {
            _permissionsGranted = true;
          });
        },
      );
    }

    // All good, show main app
    return const IntegratedNetworkDashboard();
  }
}

// Splash Screen
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
            // App Logo
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
            Text(
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

// Manual Permission Screen (if user denies initially)
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
                      // Open app settings
                      await openAppSettings();
                      // Try again after settings
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
