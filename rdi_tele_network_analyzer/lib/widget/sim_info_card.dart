import 'package:flutter/material.dart';
import 'package:rdi_tele/models/telephony_info_model.dart';

class SimInfoCard extends StatefulWidget {
  final SimInfo simInfo;
  final Color primaryColor;
  final Color accentColor;

  const SimInfoCard({
    Key? key,
    required this.simInfo,
    this.primaryColor = Colors.blue,
    this.accentColor = Colors.green,
  }) : super(key: key);

  @override
  State<SimInfoCard> createState() => _SimInfoCardState();
}

class _SimInfoCardState extends State<SimInfoCard> {
  bool _isExpanded = false;
  bool _simCardsExpanded = false; // New state for SIM cards collapse

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 8 * 2),

            // Default SIM Info
            if (widget.simInfo.defaultSim != null) _buildDefaultSimInfo(),

            const SizedBox(height: 8 * 2),

            // SIM Cards List dengan collapse functionality
            _buildSimCardsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final simCount = widget.simInfo.simCards.length;
    final activeCount = widget.simInfo.simCards
        .where((sim) => sim.subscriptionId != null)
        .length;

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
          child: Icon(Icons.sim_card, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIM INFORMATION',
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$simCount SIM${simCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$activeCount Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (!_isExpanded) {
                _simCardsExpanded = false; // Also collapse SIM cards
              }
            });
          },
          icon: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: widget.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultSimInfo() {
    final defaultSim = widget.simInfo.defaultSim!;
    final isRoaming = defaultSim.isNetworkRoaming ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRoaming
              ? Colors.orange
              : widget.accentColor.withOpacity(0.2),
        ),
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
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 8),
              const Text(
                'DATA SIM',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (isRoaming)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.travel_explore,
                        size: 14,
                        color: Colors.orange[800],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ROAMING',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Operator Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business,
                    color: widget.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        defaultSim.simOperatorName ?? 'Unknown Operator',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${defaultSim.simOperator ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Network Type',
                  defaultSim.networkTypeString ?? 'Unknown',
                  Icons.network_check,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoItem(
                  'Data Network',
                  defaultSim.dataNetworkTypeString ?? 'Unknown',
                  Icons.data_usage,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Country',
                  defaultSim.simCountryIso?.toUpperCase() ?? 'N/A',
                  Icons.flag,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoItem(
                  'SIM State',
                  defaultSim.simStateString ?? 'Unknown',
                  Icons.sim_card,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
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
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimCardsSection() {
    if (widget.simInfo.simCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.sim_card_alert, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 12),
            Text(
              'No SIM Cards Detected',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Insert SIM card to see details',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // SIM Cards Header with toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _simCardsExpanded = !_simCardsExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.sim_card, color: widget.primaryColor, size: 20),
                const SizedBox(width: 12),
                Text(
                  'SIM CARDS (${widget.simInfo.simCards.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Icon(
                  _simCardsExpanded ? Icons.expand_less : Icons.expand_more,
                  color: widget.primaryColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // SIM Cards List (Animated)
        AnimatedCrossFade(
          firstChild: _buildSimCardsCollapsed(),
          secondChild: _buildSimCardsExpanded(),
          crossFadeState: _simCardsExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),

        // Summary (always visible)
        if (widget.simInfo.simCards.isNotEmpty) _buildSimCardsSummary(),
      ],
    );
  }

  Widget _buildSimCardsCollapsed() {
    final visibleCards = widget.simInfo.simCards.length > 2
        ? widget.simInfo.simCards.sublist(0, 2)
        : widget.simInfo.simCards;

    return Column(
      children: [
        for (var i = 0; i < visibleCards.length; i++)
          _buildSimCardItem(visibleCards[i], i, collapsed: true),
        if (widget.simInfo.simCards.length > 2)
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
                  '+${widget.simInfo.simCards.length - 2} more SIM cards',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: widget.primaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSimCardsExpanded() {
    return Column(
      children: [
        for (var i = 0; i < widget.simInfo.simCards.length; i++)
          _buildSimCardItem(widget.simInfo.simCards[i], i, collapsed: false),
      ],
    );
  }

  Widget _buildSimCardItem(
    SimCard simCard,
    int index, {
    bool collapsed = false,
  }) {
    final isEmbedded = simCard.isEmbedded ?? false;
    final hasSubscription = simCard.subscriptionId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSubscription
              ? widget.accentColor.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // SIM Slot Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getSlotColor(index),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sim_card, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'SLOT ${simCard.slotIndex ?? index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      simCard.carrierName ??
                          simCard.displayName ??
                          'Unknown Carrier',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      simCard.displayName ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Embedded Badge
              if (isEmbedded && !collapsed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.memory, size: 12, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        'eSIM',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (!collapsed) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSimDetail(
                    'MCC',
                    simCard.mcc?.toString() ?? 'N/A',
                    Icons.public,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSimDetail(
                    'MNC',
                    simCard.mnc?.toString() ?? 'N/A',
                    Icons.numbers,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSimDetail(
                    'Country',
                    simCard.countryIso?.toUpperCase() ?? 'N/A',
                    Icons.flag,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSimDetail(
                    'Subscription',
                    simCard.subscriptionId?.toString() ?? 'N/A',
                    Icons.badge,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimDetail(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
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
    );
  }

  Widget _buildSimCardsSummary() {
    final simCount = widget.simInfo.simCards.length;
    final activeCount = widget.simInfo.simCards
        .where((sim) => sim.subscriptionId != null)
        .length;
    final embeddedCount = widget.simInfo.simCards
        .where((sim) => sim.isEmbedded ?? false)
        .length;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            'Total',
            '$simCount',
            Icons.sim_card,
            widget.primaryColor,
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildSummaryItem(
            'Active',
            '$activeCount',
            Icons.check_circle,
            widget.accentColor,
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildSummaryItem(
            'eSIM',
            '$embeddedCount',
            Icons.memory,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Color _getSlotColor(int index) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.orange.shade700,
      Colors.purple.shade700,
    ];
    return colors[index % colors.length];
  }
}
