import 'package:flutter/material.dart';
import 'package:rdi_tele/models/telephony_info_model.dart';

class CellularInfoCard extends StatefulWidget {
  final CellularInfo cellularInfo;
  final Color primaryColor;
  final Color accentColor;
  final Color connectedColor;
  final Color disconnectedColor;

  const CellularInfoCard({
    super.key,
    required this.cellularInfo,
    this.primaryColor = Colors.purple,
    this.accentColor = Colors.amber,
    this.connectedColor = Colors.green,
    this.disconnectedColor = Colors.red,
  });

  @override
  State<CellularInfoCard> createState() => _CellularInfoCardState();
}

class _CellularInfoCardState extends State<CellularInfoCard> {
  bool _showDetailedInfo = false;

  @override
  Widget build(BuildContext context) {
    final info = widget.cellularInfo;
    final isRoaming = info.isNetworkRoaming ?? false;
    final isDataConnected = _isDataConnected(info.dataState);
    final networkType = info.networkTypeString ?? 'Unknown';

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
            // Header dengan status koneksi
            _buildHeader(info, isRoaming, isDataConnected),
            const SizedBox(height: 20),

            // Network Status Grid
            _buildNetworkStatusGrid(info),
            const SizedBox(height: 16),

            // Connection Details
            _buildConnectionDetails(info),
            const SizedBox(height: 16),

            // Network Type Visualization
            const SizedBox(height: 16),
            _buildNetworkTypeVisualization(networkType),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CellularInfo info, bool isRoaming, bool isDataConnected) {
    final networkType = info.networkTypeString ?? 'Unknown';
    final phoneType = info.phoneTypeString ?? 'Unknown';

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
          child: Icon(Icons.network_cell, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NETWORK CONNECTION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getNetworkTypeColor(networkType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getNetworkTypeColor(
                          networkType,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      networkType,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getNetworkTypeColor(networkType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (isRoaming)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'ROAMING',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Connection Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDataConnected
                ? widget.connectedColor.withOpacity(0.1)
                : widget.disconnectedColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDataConnected
                  ? widget.connectedColor.withOpacity(0.3)
                  : widget.disconnectedColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isDataConnected ? Icons.wifi : Icons.wifi_off,
                size: 14,
                color: isDataConnected
                    ? widget.connectedColor
                    : widget.disconnectedColor,
              ),
              const SizedBox(width: 4),
              Text(
                isDataConnected ? 'CONNECTED' : 'DISCONNECTED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDataConnected
                      ? widget.connectedColor
                      : widget.disconnectedColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkStatusGrid(CellularInfo info) {
    final voiceType = _getNetworkTypeDescription(info.voiceNetworkType);
    final dataType = _getNetworkTypeDescription(info.dataNetworkType);
    final networkType = info.networkTypeString ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NETWORK STATUS',
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
                child: _buildStatusItem(
                  'Primary Network',
                  networkType,
                  Icons.network_check,
                  _getNetworkTypeColor(networkType),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  'Phone Type',
                  info.phoneTypeString ?? 'Unknown',
                  Icons.phone,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Voice Network',
                  voiceType,
                  Icons.voice_chat,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusItem(
                  'Data Network',
                  dataType,
                  Icons.data_usage,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildConnectionDetails(CellularInfo info) {
    final isDataConnected = _isDataConnected(info.dataState);
    final dataState = info.dataStateString ?? 'Unknown';
    final dataStateColor = isDataConnected
        ? widget.connectedColor
        : widget.disconnectedColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dataStateColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_ethernet, color: dataStateColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'DATA CONNECTION',
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
                  color: dataStateColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dataStateColor.withOpacity(0.3)),
                ),
                child: Text(
                  dataState,
                  style: TextStyle(
                    fontSize: 11,
                    color: dataStateColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildConnectionMetric(
                  'Status',
                  isDataConnected ? 'Connected' : 'Disconnected',
                  isDataConnected ? Icons.check_circle : Icons.cancel,
                  dataStateColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _buildConnectionMetric(
                  'Roaming',
                  info.isNetworkRoaming == true ? 'Active' : 'Inactive',
                  info.isNetworkRoaming == true
                      ? Icons.travel_explore
                      : Icons.home,
                  info.isNetworkRoaming == true ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionMetric(
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

  Widget _buildDetailToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showDetailedInfo = !_showDetailedInfo;
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
              _showDetailedInfo
                  ? 'HIDE TECHNICAL DETAILS'
                  : 'SHOW TECHNICAL DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _showDetailedInfo ? Icons.expand_less : Icons.expand_more,
              color: widget.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTechnicalInfo(CellularInfo info) {
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
              'TECHNICAL PARAMETERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildTechnicalItem(
                  'Voice Network Type',
                  '${info.voiceNetworkType ?? "N/A"}',
                  Icons.phone,
                  _getNetworkTypeColorByCode(info.voiceNetworkType),
                ),
                _buildTechnicalItem(
                  'Data Network Type',
                  '${info.dataNetworkType ?? "N/A"}',
                  Icons.data_usage,
                  _getNetworkTypeColorByCode(info.dataNetworkType),
                ),
                _buildTechnicalItem(
                  'Network Type',
                  '${info.networkType ?? "N/A"}',
                  Icons.network_check,
                  _getNetworkTypeColorByCode(info.networkType),
                ),
                _buildTechnicalItem(
                  'Data State',
                  '${info.dataState ?? "N/A"}',
                  Icons.settings_ethernet,
                  _getDataStateColor(info.dataState),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Voice: ${_getNetworkTypeDescription(info.voiceNetworkType)} | '
                      'Data: ${_getNetworkTypeDescription(info.dataNetworkType)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
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

  Widget _buildTechnicalItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkTypeVisualization(String networkType) {
    final color = _getNetworkTypeColor(networkType);
    final icon = _getNetworkTypeIcon(networkType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE NETWORK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  networkType,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  _getNetworkTypeDescriptionFromString(networkType),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Network Speed Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.speed, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  _getNetworkSpeedEstimate(networkType),
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  bool _isDataConnected(int? dataState) {
    // Data state 2 = CONNECTED
    return dataState == 2;
  }

  String _getNetworkTypeDescription(int? typeCode) {
    if (typeCode == null) return 'Unknown';

    switch (typeCode) {
      case 1:
        return 'GPRS';
      case 2:
        return 'EDGE';
      case 3:
        return 'UMTS';
      case 4:
        return 'CDMA';
      case 5:
        return 'EVDO 0';
      case 6:
        return 'EVDO A';
      case 7:
        return '1xRTT';
      case 8:
        return 'HSDPA';
      case 9:
        return 'HSUPA';
      case 10:
        return 'HSPA';
      case 11:
        return 'IDEN';
      case 12:
        return 'EVDO B';
      case 13:
        return 'LTE';
      case 14:
        return 'eHRPD';
      case 15:
        return 'HSPA+';
      case 16:
        return 'GSM';
      case 17:
        return 'TD-SCDMA';
      case 18:
        return 'IWLAN';
      case 19:
        return 'LTE CA';
      case 20:
        return '5G NR';
      default:
        return 'Unknown ($typeCode)';
    }
  }

  String _getNetworkTypeDescriptionFromString(String type) {
    switch (type.toUpperCase()) {
      case 'LTE':
        return '4G Long Term Evolution';
      case '5G':
        return '5G New Radio';
      case '4G':
        return '4G LTE';
      case '3G':
        return '3G HSPA/HSPA+';
      case '2G':
        return '2G GSM/GPRS/EDGE';
      case 'GSM':
        return 'Global System for Mobile';
      case 'CDMA':
        return 'Code Division Multiple Access';
      default:
        return 'Mobile Network';
    }
  }

  String _getNetworkSpeedEstimate(String type) {
    switch (type.toUpperCase()) {
      case '5G':
        return '1-10 Gbps';
      case 'LTE':
      case '4G':
        return '10-300 Mbps';
      case '3G':
        return '0.5-42 Mbps';
      case '2G':
        return '0.1-0.3 Mbps';
      case 'GSM':
        return '9.6-14.4 Kbps';
      default:
        return 'Unknown';
    }
  }

  Color _getNetworkTypeColor(String type) {
    switch (type.toUpperCase()) {
      case '5G':
        return Colors.purple;
      case 'LTE':
      case '4G':
        return Colors.blue;
      case '3G':
        return Colors.green;
      case '2G':
        return Colors.orange;
      case 'GSM':
        return Colors.red;
      case 'CDMA':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Color _getNetworkTypeColorByCode(int? code) {
    final type = _getNetworkTypeDescription(code);
    return _getNetworkTypeColor(type);
  }

  Color _getDataStateColor(int? state) {
    if (state == 2) return widget.connectedColor; // CONNECTED
    if (state == 1) return Colors.orange; // CONNECTING
    if (state == 3) return Colors.orange; // SUSPENDED
    return widget.disconnectedColor; // DISCONNECTED
  }

  IconData _getNetworkTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case '5G':
        return Icons.network_check;
      case 'LTE':
      case '4G':
        return Icons.network_cell;
      case '3G':
        return Icons.network_wifi;
      case '2G':
        return Icons.signal_cellular_alt;
      default:
        return Icons.network_check;
    }
  }
}
