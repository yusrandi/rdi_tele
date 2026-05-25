import 'package:rdi_tele/models/telephony_info_model.dart';
import 'package:rdi_tele/use_constant.dart';

// ══════════════════════════════════════════════════════════════════════════════
// TelephonySnapshot — diperluas sesuai semua key di UseTMConst
// + DITAMBAH: level, ta, cqi  (sebelumnya tidak ada)
// ══════════════════════════════════════════════════════════════════════════════

class TelephonySnapshot {
  final DateTime timestamp;

  // Signal metrics (dari UseTMConst)
  final int rsrp;
  final int rsrq;
  final int rssi;
  final int rssnr; // SINR
  final int level; // + BARU
  final int dbm;
  final int cellId;
  final int? ta; // + BARU — Timing Advance
  final int? cqi; // + BARU — Channel Quality Indicator

  // Related info per snapshot
  final SimInfo simInfo;
  final DeviceInfo deviceInfo;
  final ServingCell servingCell;
  final CellularInfo cellularInfo;
  final List<NeighbourCell> neighbourCells;

  const TelephonySnapshot({
    required this.timestamp,
    required this.rsrp,
    required this.rsrq,
    required this.rssi,
    required this.rssnr,
    required this.level,
    required this.dbm,
    required this.cellId,
    this.ta,
    this.cqi,
    required this.simInfo,
    required this.deviceInfo,
    required this.servingCell,
    required this.cellularInfo,
    required this.neighbourCells,
  });

  /// Factory dari raw map hasil _rdiTelePlugin.getTM()
  factory TelephonySnapshot.fromTmMap({
    required Map<dynamic, dynamic> tmData,
    required SimInfo simInfo,
    required DeviceInfo deviceInfo,
    required ServingCell servingCell,
    required CellularInfo cellularInfo,
    required List<NeighbourCell> neighbourCells,
    required DateTime timestamp,
  }) {
    return TelephonySnapshot(
      timestamp: timestamp,
      rsrp: tmData[UseTMConst.rsrp] as int? ?? 0,
      rsrq: tmData[UseTMConst.rsrq] as int? ?? 0,
      rssi: tmData[UseTMConst.rssi] as int? ?? 0,
      rssnr: tmData[UseTMConst.rssnr] as int? ?? 0,
      level: tmData[UseTMConst.level] as int? ?? 0,
      dbm: tmData[UseTMConst.dbm] as int? ?? 0,
      cellId: tmData[UseTMConst.cellid] as int? ?? 0,
      ta: tmData[UseTMConst.ta] as int?,
      cqi: tmData[UseTMConst.cqi] as int?,
      simInfo: simInfo,
      deviceInfo: deviceInfo,
      servingCell: servingCell,
      cellularInfo: cellularInfo,
      neighbourCells: neighbourCells,
    );
  }
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
