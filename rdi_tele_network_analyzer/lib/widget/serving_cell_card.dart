import 'package:flutter/material.dart';
import 'package:rdi_tele/models/telephony_info_model.dart';

class ServingCellCard extends StatefulWidget {
  final ServingCell servingCell;
  final List<NeighbourCell> neighbourCells;
  final Color primaryColor;
  final Color accentColor;
  final Color signalGoodColor;
  final Color signalFairColor;
  final Color signalPoorColor;

  const ServingCellCard({
    Key? key,
    required this.servingCell,
    this.neighbourCells = const [],
    this.primaryColor = Colors.blue,
    this.accentColor = Colors.green,
    this.signalGoodColor = Colors.green,
    this.signalFairColor = Colors.orange,
    this.signalPoorColor = Colors.red,
  }) : super(key: key);

  @override
  State<ServingCellCard> createState() => _ServingCellCardState();
}

class _ServingCellCardState extends State<ServingCellCard> {
  bool _showNeighbours = false;
  bool _showAdvancedDetails = false;

  @override
  Widget build(BuildContext context) {
    final cell = widget.servingCell;
    final rsrp = cell.rsrp ?? 0;
    final signalStrength = _getSignalStrength(rsrp);
    final signalColor = _getSignalColor(signalStrength);
    final hasNeighbours = widget.neighbourCells.isNotEmpty;

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
            _buildHeader(cell, signalStrength, signalColor),
            const SizedBox(height: 16),

            // Signal Strength Indicator
            _buildSignalIndicator(cell, rsrp, signalColor),
            const SizedBox(height: 20),

            // Basic Cell Info
            _buildBasicCellInfo(cell),
            const SizedBox(height: 16),

            // Advanced Details Toggle
            _buildAdvancedToggle(),

            // Advanced Details (Expandable)
            if (_showAdvancedDetails) ...[
              const SizedBox(height: 16),
              _buildAdvancedCellInfo(cell),
            ],

            // Neighbour Cells Section
            if (hasNeighbours) ...[
              const SizedBox(height: 20),
              _buildNeighbourCellsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    ServingCell cell,
    String signalStrength,
    Color signalColor,
  ) {
    final isRegistered = cell.isRegistered ?? false;

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
          child: Icon(Icons.cell_tower, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SERVING CELL',
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
                      color: signalColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: signalColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      signalStrength,
                      style: TextStyle(
                        fontSize: 10,
                        color: signalColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isRegistered
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isRegistered
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isRegistered ? 'REGISTERED' : 'NOT REGISTERED',
                      style: TextStyle(
                        fontSize: 10,
                        color: isRegistered ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.neighbourCells.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.accentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.devices, size: 14, color: widget.accentColor),
                const SizedBox(width: 4),
                Text(
                  '${widget.neighbourCells.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSignalIndicator(ServingCell cell, int rsrp, Color signalColor) {
    final rsrq = cell.rsrq ?? 0;
    final rssi = cell.rssi ?? 0;
    final dbm = cell.dbm ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: signalColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Signal Strength Bar
          _buildSignalBar(rsrp),
          const SizedBox(height: 20),

          // Signal Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildSignalMetric(
                  'RSRP',
                  '$rsrp dBm',
                  Icons.signal_cellular_alt,
                  _getMetricColor(rsrp, -85, -95, -105),
                ),
              ),
              Expanded(
                child: _buildSignalMetric(
                  'RSRQ',
                  '$rsrq dB',
                  Icons.show_chart,
                  _getMetricColor(rsrq, -5, -10, -15),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildSignalMetric(
                  'RSSI',
                  '$rssi dBm',
                  Icons.network_check,
                  _getMetricColor(rssi, -65, -75, -85),
                ),
              ),
              Expanded(
                child: _buildSignalMetric(
                  'dBm',
                  '$dbm dBm',
                  Icons.speed,
                  _getMetricColor(dbm, -85, -95, -105),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBar(int rsrp) {
    final signalLevel = _getSignalLevel(rsrp);
    final barWidth = (rsrp.abs() - 50).clamp(10.0, 80.0).toDouble();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SIGNAL STRENGTH',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getSignalColor(signalLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getSignalColor(signalLevel).withOpacity(0.3),
                ),
              ),
              child: Text(
                signalLevel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getSignalColor(signalLevel),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 24,
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
                  child: Text(
                    '$rsrp dBm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getSignalColor(signalLevel),
                    ),
                  ),
                ),
              ),
              // Signal progress
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      // Background
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // Signal indicator
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        // right: 0,
                        child: Container(
                          width: barWidth * 3,
                          //   height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getSignalColor(signalLevel).withOpacity(0.8),
                                _getSignalColor(signalLevel).withOpacity(0.4),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Signal quality indicator
              SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    '${_calculateSignalQuality(rsrp)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Poor',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            Text(
              'Excellent',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignalMetric(
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
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildBasicCellInfo(ServingCell cell) {
    return Container(
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
            'CELL INFORMATION',
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
                child: _buildCellInfoItem(
                  'Cell ID',
                  '${cell.ci ?? "N/A"}',
                  Icons.numbers,
                ),
              ),
              Expanded(
                child: _buildCellInfoItem(
                  'PCI',
                  '${cell.pci ?? "N/A"}',
                  Icons.tag,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildCellInfoItem(
                  'TAC',
                  '${cell.tac ?? "N/A"}',
                  Icons.location_on,
                ),
              ),
              Expanded(
                child: _buildCellInfoItem(
                  'EARFCN',
                  '${cell.earfcn ?? "N/A"}',
                  Icons.tune,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildCellInfoItem(
                  'MCC',
                  '${cell.mcc ?? "N/A"}',
                  Icons.public,
                ),
              ),
              Expanded(
                child: _buildCellInfoItem(
                  'MNC',
                  '${cell.mnc ?? "N/A"}',
                  Icons.numbers,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCellInfoItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: widget.primaryColor),
          const SizedBox(width: 8),
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
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

  Widget _buildAdvancedToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAdvancedDetails = !_showAdvancedDetails;
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
              _showAdvancedDetails
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
              _showAdvancedDetails ? Icons.expand_less : Icons.expand_more,
              color: widget.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedCellInfo(ServingCell cell) {
    final networkType = cell.networkType ?? 'Unknown';
    final level = cell.level ?? 0;

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
                  child: _buildAdvancedItem(
                    'Network Type',
                    networkType,
                    Icons.network_check,
                    _getNetworkTypeColor(networkType),
                  ),
                ),
                Expanded(
                  child: _buildAdvancedItem(
                    'Signal Level',
                    '$level',
                    Icons.signal_cellular_alt,
                    _getLevelColor(level),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildAdvancedItem(
                    'Registered',
                    cell.isRegistered == true ? 'Yes' : 'No',
                    Icons.check_circle,
                    cell.isRegistered == true ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildAdvancedItem(
                    'Cell Status',
                    _getCellStatus(cell),
                    Icons.info,
                    widget.primaryColor,
                  ),
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
                      'Cell ID: ${cell.ci ?? "N/A"} | PCI: ${cell.pci ?? "N/A"} | '
                      'TAC: ${cell.tac ?? "N/A"}',
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

  Widget _buildAdvancedItem(
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

  Widget _buildNeighbourCellsSection() {
    return Column(
      children: [
        // Neighbour Cells Header with toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _showNeighbours = !_showNeighbours;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.accentColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                    color: widget.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.devices,
                    color: widget.accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'NEIGHBOUR CELLS (${widget.neighbourCells.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  _showNeighbours ? Icons.expand_less : Icons.expand_more,
                  color: widget.accentColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Neighbour Cells List (Animated)
        AnimatedCrossFade(
          firstChild: _buildNeighboursCollapsed(),
          secondChild: _buildNeighboursExpanded(),
          crossFadeState: _showNeighbours
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildNeighboursCollapsed() {
    final visibleCells = widget.neighbourCells.length > 3
        ? widget.neighbourCells.sublist(0, 3)
        : widget.neighbourCells;

    return Column(
      children: [
        for (var i = 0; i < visibleCells.length; i++)
          _buildNeighbourCellItem(visibleCells[i], i, collapsed: true),
        if (widget.neighbourCells.length > 3)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '+${widget.neighbourCells.length - 3} more neighbour cells',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: widget.accentColor,
                  size: 16,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNeighboursExpanded() {
    return Column(
      children: [
        for (var i = 0; i < widget.neighbourCells.length; i++)
          _buildNeighbourCellItem(
            widget.neighbourCells[i],
            i,
            collapsed: false,
          ),
      ],
    );
  }

  Widget _buildNeighbourCellItem(
    NeighbourCell cell,
    int index, {
    bool collapsed = false,
  }) {
    final rsrp = cell.rsrp ?? 0;
    final signalStrength = _getSignalStrength(rsrp);
    final signalColor = _getSignalColor(signalStrength);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Cell Index Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getNeighbourColor(index),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PCI: ${cell.pci ?? "N/A"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Cell ID: ${cell.ci ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Signal Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: signalColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: signalColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getSignalIcon(signalStrength),
                      size: 12,
                      color: signalColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$rsrp dBm',
                      style: TextStyle(
                        fontSize: 10,
                        color: signalColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!collapsed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNeighbourDetail(
                    'RSRQ',
                    '${cell.rsrq ?? "N/A"} dB',
                    Icons.show_chart,
                  ),
                ),
                Expanded(
                  child: _buildNeighbourDetail(
                    'TAC',
                    '${cell.tac ?? "N/A"}',
                    Icons.location_on,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildNeighbourDetail(
                    'Network',
                    cell.networkType ?? 'N/A',
                    Icons.network_check,
                  ),
                ),
                Expanded(
                  child: _buildNeighbourDetail(
                    'Signal',
                    signalStrength,
                    Icons.signal_cellular_alt,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNeighbourDetail(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 6),
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
                  style: const TextStyle(
                    fontSize: 11,
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

  // Helper Methods
  String _getSignalStrength(int rsrp) {
    if (rsrp >= -85) return 'Excellent';
    if (rsrp >= -95) return 'Good';
    if (rsrp >= -105) return 'Fair';
    if (rsrp >= -115) return 'Weak';
    return 'Poor';
  }

  String _getSignalLevel(int rsrp) {
    if (rsrp >= -85) return 'excellent';
    if (rsrp >= -95) return 'good';
    if (rsrp >= -105) return 'fair';
    if (rsrp >= -115) return 'weak';
    return 'poor';
  }

  Color _getSignalColor(String strength) {
    switch (strength.toLowerCase()) {
      case 'excellent':
        return widget.signalGoodColor;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return widget.signalFairColor;
      case 'weak':
        return Colors.orange;
      default:
        return widget.signalPoorColor;
    }
  }

  Color _getMetricColor(int value, int good, int fair, int poor) {
    if (value >= good) return widget.signalGoodColor;
    if (value >= fair) return widget.signalFairColor;
    return widget.signalPoorColor;
  }

  int _calculateSignalQuality(int rsrp) {
    // Convert RSRP (-140 to -44) to percentage (0-100%)
    return ((rsrp.abs() - 50) / 90 * 100).clamp(0, 100).toInt();
  }

  Color _getNetworkTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'LTE':
        return Colors.blue;
      case '5G':
        return Colors.purple;
      case '3G':
        return Colors.orange;
      case '2G':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getLevelColor(int level) {
    if (level >= 4) return Colors.green;
    if (level >= 3) return Colors.lightGreen;
    if (level >= 2) return Colors.orange;
    return Colors.red;
  }

  String _getCellStatus(ServingCell cell) {
    if (cell.isRegistered == true) {
      final rsrp = cell.rsrp ?? 0;
      if (rsrp >= -85) return 'Strong';
      if (rsrp >= -95) return 'Good';
      if (rsrp >= -105) return 'Fair';
      return 'Weak';
    }
    return 'Not Registered';
  }

  Color _getNeighbourColor(int index) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.pink.shade600,
    ];
    return colors[index % colors.length];
  }

  IconData _getSignalIcon(String strength) {
    switch (strength.toLowerCase()) {
      case 'excellent':
        return Icons.signal_cellular_4_bar;
      case 'good':
        return Icons.signal_cellular_4_bar;
      case 'fair':
        return Icons.signal_cellular_alt_2_bar;
      case 'weak':
        return Icons.signal_cellular_alt_1_bar;
      default:
        return Icons.signal_cellular_0_bar;
    }
  }
}
