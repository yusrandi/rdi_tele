import 'package:flutter/material.dart';
import 'package:rdi_tele/models/telephony_info_model.dart';

class DeviceInfoCard extends StatefulWidget {
  final DeviceInfo deviceInfo;
  final Color primaryColor;
  final Color accentColor;

  const DeviceInfoCard({
    Key? key,
    required this.deviceInfo,
    this.primaryColor = Colors.deepPurple,
    this.accentColor = Colors.amber,
  }) : super(key: key);

  @override
  State<DeviceInfoCard> createState() => _DeviceInfoCardState();
}

class _DeviceInfoCardState extends State<DeviceInfoCard> {
  bool _showDetails = true;

  @override
  Widget build(BuildContext context) {
    final device = widget.deviceInfo;
    final sdkInt = device.sdkInt ?? 0;
    final androidVersion = device.androidVersion ?? 'Unknown';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, widget.primaryColor.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.primaryColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Device Identity
            _buildDeviceIdentity(device),
            const SizedBox(height: 20),

            // Android Version & SDK
            _buildAndroidInfo(androidVersion, sdkInt),
            const SizedBox(height: 20),

            // Security Patch
            if (device.securityPatch != null) _buildSecurityInfo(),
            const SizedBox(height: 20),

            // Toggle Button for Details
            _buildToggleButton(),

            // Detailed Info (Expandable)
            if (_showDetails) ...[
              const SizedBox(height: 20),
              _buildDetailedInfo(device),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.primaryColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.phone_android, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEVICE INFORMATION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Hardware & Software Details',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceIdentity(DeviceInfo device) {
    final brand = device.brand ?? 'Unknown';
    final model = device.model ?? 'Unknown';
    final manufacturer = device.manufacturer ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Device Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getDeviceIcon(brand.toLowerCase()),
              color: widget.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '$brand ($manufacturer)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidInfo(String androidVersion, int sdkInt) {
    final versionColor = _getAndroidVersionColor(androidVersion);
    final sdkColor = _getSdkColor(sdkInt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.android, color: Colors.green, size: 20),
              const SizedBox(width: 12),
              const Text(
                'ANDROID VERSION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: versionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: versionColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.system_update, size: 14, color: versionColor),
                    const SizedBox(width: 6),
                    Text(
                      androidVersion,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: versionColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVersionDetail(
                  'SDK Version',
                  'API $sdkInt',
                  Icons.code,
                  sdkColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildVersionDetail(
                  'Codename',
                  _getAndroidCodename(sdkInt),
                  Icons.label,
                  widget.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionDetail(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityInfo() {
    final securityPatch = widget.deviceInfo.securityPatch!;
    final isUpdated = _isSecurityUpdated(securityPatch);
    final monthsOutdated = _getMonthsOutdated(securityPatch);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUpdated
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: isUpdated ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'SECURITY PATCH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isUpdated
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUpdated
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isUpdated ? 'UP TO DATE' : 'OUTDATED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUpdated ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            securityPatch,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUpdated
                ? 'Your device has the latest security patch'
                : '${monthsOutdated > 0 ? '$monthsOutdated month${monthsOutdated > 1 ? 's' : ''} outdated' : 'Check for updates'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetails = !_showDetails;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showDetails ? 'HIDE DETAILS' : 'SHOW DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _showDetails ? Icons.expand_less : Icons.expand_more,
              color: widget.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedInfo(DeviceInfo device) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TECHNICAL DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Device',
                    device.device ?? 'Unknown',
                    Icons.devices,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailItem(
                    'Manufacturer',
                    device.manufacturer ?? 'Unknown',
                    Icons.factory,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Brand',
                    device.brand ?? 'Unknown',
                    Icons.business,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailItem(
                    'Model',
                    device.model ?? 'Unknown',
                    Icons.phone_iphone,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Android Version',
                    device.androidVersion ?? 'Unknown',
                    Icons.android,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailItem(
                    'SDK Level',
                    'API ${device.sdkInt ?? "Unknown"}',
                    Icons.code,
                    Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  IconData _getDeviceIcon(String brand) {
    if (brand.contains('samsung')) return Icons.phone_android;
    if (brand.contains('xiaomi') || brand.contains('redmi'))
      return Icons.phone_android;
    if (brand.contains('oppo')) return Icons.phone_android;
    if (brand.contains('vivo')) return Icons.phone_android;
    if (brand.contains('realme')) return Icons.phone_android;
    if (brand.contains('oneplus')) return Icons.phone_android;
    if (brand.contains('google')) return Icons.phone_android;
    if (brand.contains('pixel')) return Icons.phone_android;
    if (brand.contains('sony')) return Icons.phone_android;
    if (brand.contains('nokia')) return Icons.phone_android;
    if (brand.contains('motorola')) return Icons.phone_android;
    if (brand.contains('lg')) return Icons.phone_android;
    if (brand.contains('huawei') || brand.contains('honor'))
      return Icons.phone_android;
    return Icons.phone_android;
  }

  Color _getAndroidVersionColor(String version) {
    if (version.contains('14')) return Colors.deepPurple;
    if (version.contains('13')) return Colors.purple;
    if (version.contains('12')) return Colors.blue;
    if (version.contains('11')) return Colors.green;
    if (version.contains('10')) return Colors.orange;
    return Colors.grey;
  }

  Color _getSdkColor(int sdkInt) {
    if (sdkInt >= 34) return Colors.deepPurple; // Android 14
    if (sdkInt >= 33) return Colors.purple; // Android 13
    if (sdkInt >= 31) return Colors.blue; // Android 12
    if (sdkInt >= 30) return Colors.green; // Android 11
    if (sdkInt >= 29) return Colors.orange; // Android 10
    return Colors.grey;
  }

  String _getAndroidCodename(int sdkInt) {
    switch (sdkInt) {
      case 34:
        return 'Upside Down Cake';
      case 33:
        return 'Tiramisu';
      case 32:
        return 'Snow Cone';
      case 31:
        return 'Snow Cone';
      case 30:
        return 'Red Velvet Cake';
      case 29:
        return 'Q';
      case 28:
        return 'Pie';
      case 27:
        return 'Oreo';
      case 26:
        return 'Oreo';
      case 25:
        return 'Nougat';
      case 24:
        return 'Nougat';
      default:
        return 'Unknown';
    }
  }

  bool _isSecurityUpdated(String securityPatch) {
    try {
      //   final patchDate = DateTime.parse('$securityPatch-01');
      DateTime patchDate;

      if (securityPatch.length == 7) {
        // format YYYY-MM
        patchDate = DateTime.parse('$securityPatch-01');
      } else {
        // format YYYY-MM-DD
        patchDate = DateTime.parse(securityPatch);
      }
      final now = DateTime.now();
      final difference = now.difference(patchDate).inDays;
      return difference <= 90; // Updated if within 3 months
    } catch (e) {
      return false;
    }
  }

  int _getMonthsOutdated(String securityPatch) {
    try {
      //   final patchDate = DateTime.parse('$securityPatch-01');
      DateTime patchDate;

      if (securityPatch.length == 7) {
        // format YYYY-MM
        patchDate = DateTime.parse('$securityPatch-01');
      } else {
        // format YYYY-MM-DD
        patchDate = DateTime.parse(securityPatch);
      }
      final now = DateTime.now();
      final years = now.year - patchDate.year;
      final months = now.month - patchDate.month;
      return (years * 12) + months;
    } catch (e) {
      return 0;
    }
  }
}
