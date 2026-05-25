import 'package:geolocator/geolocator.dart';
import 'package:rdi_tele/models/telephony_info_model.dart';
import 'package:realspeed_analyzer/integrated_network_dashboard.dart';
import 'package:realspeed_analyzer/model/telephony_snapshot.dart';

// ─── Device ───────────────────────────────────────────────────────────────────
// + DITAMBAH: device, manufacturer, sdkInt, securityPatch
// - DIHAPUS : deviceId (tidak ada di DeviceInfo plugin)

class CaptureDevice {
  final String deviceId;
  final String brand;
  final String model;
  final String os;
  final String device;
  final String manufacturer;
  final String androidVersion;
  final int? sdkInt;
  final String? securityPatch;

  const CaptureDevice({
    required this.deviceId,
    required this.brand,
    required this.model,
    required this.os,
    required this.device,
    required this.manufacturer,
    required this.androidVersion,
    this.sdkInt,
    this.securityPatch,
  });

  factory CaptureDevice.fromDeviceInfo(DeviceInfo info) => CaptureDevice(
    deviceId: 'deviceID',
    brand: info.brand ?? '',
    model: info.model ?? '',
    device: info.device ?? '',
    manufacturer: info.manufacturer ?? '',
    androidVersion: info.androidVersion ?? '',
    sdkInt: info.sdkInt,
    os: 'Android',
    securityPatch: info.securityPatch,
  );

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'brand': brand,
    'model': model,
    'os': os,
    'device': device,
    'manufacturer': manufacturer,
    'android_version': androidVersion,
    'sdk_int': sdkInt,
    'security_patch': securityPatch,
  };
}

// ─── SIM — Default (data SIM aktif) ──────────────────────────────────────────
// + DITAMBAH: semua field DefaultSim
//   simOperator, simOperatorName, networkOperator, networkOperatorName,
//   networkType, networkTypeString, dataNetworkType, dataNetworkTypeString,
//   simCountryIso, networkCountryIso, simStateString, isNetworkRoaming
// - SEBELUMNYA: hanya operator + network (2 field)

class CaptureDefaultSim {
  final String? simOperator;
  final String? simOperatorName;
  final String? networkOperator;
  final String? networkOperatorName;
  final int? networkType;
  final String? networkTypeString;
  final int? dataNetworkType;
  final String? dataNetworkTypeString;
  final String? simCountryIso;
  final String? networkCountryIso;
  final String? simStateString;
  final bool? isNetworkRoaming;

  const CaptureDefaultSim({
    this.simOperator,
    this.simOperatorName,
    this.networkOperator,
    this.networkOperatorName,
    this.networkType,
    this.networkTypeString,
    this.dataNetworkType,
    this.dataNetworkTypeString,
    this.simCountryIso,
    this.networkCountryIso,
    this.simStateString,
    this.isNetworkRoaming,
  });

  factory CaptureDefaultSim.fromDefaultSim(DefaultSim s) => CaptureDefaultSim(
    simOperator: s.simOperator,
    simOperatorName: s.simOperatorName,
    networkOperator: s.networkOperator,
    networkOperatorName: s.networkOperatorName,
    networkType: s.networkType,
    networkTypeString: s.networkTypeString,
    dataNetworkType: s.dataNetworkType,
    dataNetworkTypeString: s.dataNetworkTypeString,
    simCountryIso: s.simCountryIso,
    networkCountryIso: s.networkCountryIso,
    simStateString: s.simStateString,
    isNetworkRoaming: s.isNetworkRoaming,
  );

  Map<String, dynamic> toJson() => {
    'sim_operator': simOperator,
    'sim_operator_name': simOperatorName,
    'network_operator': networkOperator,
    'network_operator_name': networkOperatorName,
    'network_type': networkType,
    'network_type_string': networkTypeString,
    'data_network_type': dataNetworkType,
    'data_network_type_string': dataNetworkTypeString,
    'sim_country_iso': simCountryIso,
    'network_country_iso': networkCountryIso,
    'sim_state': simStateString,
    'is_roaming': isNetworkRoaming,
  };
}

// ─── SIM — Per kartu fisik ────────────────────────────────────────────────────
// + BARU: tidak ada di payload sebelumnya
//   slotIndex, subscriptionId, displayName, carrierName,
//   countryIso, mcc, mnc, isEmbedded

class CaptureSimCard {
  final int? slotIndex;
  final int? subscriptionId;
  final String? displayName;
  final String? carrierName;
  final String? countryIso;
  final int? mcc;
  final int? mnc;
  final bool? isEmbedded;

  const CaptureSimCard({
    this.slotIndex,
    this.subscriptionId,
    this.displayName,
    this.carrierName,
    this.countryIso,
    this.mcc,
    this.mnc,
    this.isEmbedded,
  });

  factory CaptureSimCard.fromSimCard(SimCard c) => CaptureSimCard(
    slotIndex: c.slotIndex,
    subscriptionId: c.subscriptionId,
    displayName: c.displayName,
    carrierName: c.carrierName,
    countryIso: c.countryIso,
    mcc: c.mcc,
    mnc: c.mnc,
    isEmbedded: c.isEmbedded,
  );

  Map<String, dynamic> toJson() => {
    'slot_index': slotIndex,
    'subscription_id': subscriptionId,
    'display_name': displayName,
    'carrier_name': carrierName,
    'country_iso': countryIso,
    'mcc': mcc,
    'mnc': mnc,
    'is_embedded': isEmbedded,
  };
}

class CaptureSim {
  final CaptureDefaultSim? defaultSim;
  final List<CaptureSimCard> simCards; // + BARU: list kartu fisik

  const CaptureSim({this.defaultSim, this.simCards = const []});

  factory CaptureSim.fromSimInfo(SimInfo info) => CaptureSim(
    defaultSim: info.defaultSim != null
        ? CaptureDefaultSim.fromDefaultSim(info.defaultSim!)
        : null,
    simCards: info.simCards.map(CaptureSimCard.fromSimCard).toList(),
  );

  Map<String, dynamic> toJson() => {
    'default_sim': defaultSim?.toJson(),
    'sim_cards': simCards.map((c) => c.toJson()).toList(),
  };
}

// ─── Cellular Info ────────────────────────────────────────────────────────────
// + BARU SELURUHNYA: tidak ada di payload sebelumnya
//   voiceNetworkType, dataNetworkType, networkType, networkTypeString,
//   isNetworkRoaming, dataState, dataStateString, phoneTypeString

class CaptureCellularInfo {
  final int? voiceNetworkType;
  final int? dataNetworkType;
  final int? networkType;
  final String? networkTypeString;
  final bool? isNetworkRoaming;
  final int? dataState;
  final String? dataStateString;
  final String? phoneTypeString;

  const CaptureCellularInfo({
    this.voiceNetworkType,
    this.dataNetworkType,
    this.networkType,
    this.networkTypeString,
    this.isNetworkRoaming,
    this.dataState,
    this.dataStateString,
    this.phoneTypeString,
  });

  factory CaptureCellularInfo.fromCellularInfo(CellularInfo info) =>
      CaptureCellularInfo(
        voiceNetworkType: info.voiceNetworkType,
        dataNetworkType: info.dataNetworkType,
        networkType: info.networkType,
        networkTypeString: info.networkTypeString,
        isNetworkRoaming: info.isNetworkRoaming,
        dataState: info.dataState,
        dataStateString: info.dataStateString,
        phoneTypeString: info.phoneTypeString,
      );

  Map<String, dynamic> toJson() => {
    'voice_network_type': voiceNetworkType,
    'data_network_type': dataNetworkType,
    'network_type': networkType,
    'network_type_string': networkTypeString,
    'is_roaming': isNetworkRoaming,
    'data_state': dataState,
    'data_state_string': dataStateString,
    'phone_type': phoneTypeString,
  };
}

class CaptureCycle {
  final DateTime startedAt;
  final DateTime endedAt;

  const CaptureCycle({required this.startedAt, required this.endedAt});

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.toUtc().toIso8601String(),
    'endedAt': endedAt.toUtc().toIso8601String(),
  };
}

// ─── Location ─────────────────────────────────────────────────────────────────
// + DITAMBAH: altitude, speed, heading
// - SEBELUMNYA: lat, lng, acc, ts saja
class CaptureLocation {
  final double lat;
  final double lng;
  final double acc;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime ts;

  const CaptureLocation({
    required this.lat,
    required this.lng,
    required this.acc,
    this.altitude,
    this.speed,
    this.heading,
    required this.ts,
  });

  factory CaptureLocation.fromPosition(Position position) => CaptureLocation(
    lat: position.latitude,
    lng: position.longitude,
    acc: position.accuracy,
    altitude: position.altitude,
    speed: position.speed,
    heading: position.heading,
    ts: position.timestamp ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'acc': acc,
    'altitude': altitude,
    'speed': speed,
    'heading': heading,
    'ts': ts.toUtc().toIso8601String(),
  };
}

// ─── Telephony (per snapshot 2 detik) ────────────────────────────────────────
// + DITAMBAH: rssi, level, dbm, cell_id, ta, cqi
// - SEBELUMNYA: rsrp, rsrq, sinr, ts saja
class CaptureTelephony {
  final int rsrp;
  final int rsrq;
  final int rssi;
  final int sinr; // = rssnr dari UseTMConst
  final int dbm;
  final int cellId;
  final DateTime ts;

  const CaptureTelephony({
    required this.rsrp,
    required this.rsrq,
    required this.rssi,
    required this.sinr,
    required this.dbm,
    required this.cellId,
    required this.ts,
  });

  factory CaptureTelephony.fromSnapshot(TelephonySnapshot snapshot) =>
      CaptureTelephony(
        rsrp: snapshot.rsrp,
        rsrq: snapshot.rsrq,
        rssi: snapshot.rssi,
        sinr: snapshot.rssnr,
        dbm: snapshot.dbm,
        cellId: snapshot.cellId,
        ts: snapshot.timestamp,
      );

  Map<String, dynamic> toJson() => {
    'rsrp': rsrp,
    'rsrq': rsrq,
    'rssi': rssi,
    'sinr': sinr,
    'dbm': dbm,
    'cell_id': cellId,
    'ts': ts.toUtc().toIso8601String(),
  };
}

// ─── Speed ────────────────────────────────────────────────────────────────────
// + DITAMBAH: unit (Mbps / Kbps)
// - SEBELUMNYA: dl, ul, ping, ts saja
class CaptureSpeed {
  final double dl;
  final double ul;
  final double ping;
  final String unit;
  final DateTime ts;

  const CaptureSpeed({
    required this.dl,
    required this.ul,
    required this.ping,
    required this.unit,
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
    'dl': dl,
    'ul': ul,
    'ping': ping,
    'unit': unit,
    'ts': ts.toUtc().toIso8601String(),
  };
} // ─── Serving Cell ─────────────────────────────────────────────────────────────
// + DITAMBAH: tac, mcc, mnc, rssi, dbm, level, networkType, isRegistered
// - SEBELUMNYA: hanya eci(ci), pci, earfcn, band, rsrp, rsrq
// - DIHAPUS  : band (tidak ada di ServingCell plugin)

class CaptureServingCell {
  final int? ci;
  final int? tac;
  final int? pci;
  final int? earfcn;
  final int? mcc;
  final int? mnc;
  final int? rsrp;
  final int? rsrq;
  final int? rssi;
  final int? dbm;
  final int? level;
  final String? networkType;
  final bool? isRegistered;

  const CaptureServingCell({
    this.ci,
    this.tac,
    this.pci,
    this.earfcn,
    this.mcc,
    this.mnc,
    this.rsrp,
    this.rsrq,
    this.rssi,
    this.dbm,
    this.level,
    this.networkType,
    this.isRegistered,
  });

  factory CaptureServingCell.fromServingCell(ServingCell s) =>
      CaptureServingCell(
        ci: s.ci,
        tac: s.tac,
        pci: s.pci,
        earfcn: s.earfcn,
        mcc: s.mcc,
        mnc: s.mnc,
        rsrp: s.rsrp,
        rsrq: s.rsrq,
        rssi: s.rssi,
        dbm: s.dbm,
        level: s.level,
        networkType: s.networkType,
        isRegistered: s.isRegistered,
      );

  Map<String, dynamic> toJson() => {
    'ci': ci,
    'tac': tac,
    'pci': pci,
    'earfcn': earfcn,
    'mcc': mcc,
    'mnc': mnc,
    'rsrp': rsrp,
    'rsrq': rsrq,
    'rssi': rssi,
    'dbm': dbm,
    'level': level,
    'network_type': networkType,
    'is_registered': isRegistered,
  };
}

// ─── Neighbour Cell ───────────────────────────────────────────────────────────
// + DITAMBAH: ci, tac, rsrq, networkType
// - SEBELUMNYA: hanya pci, earfcn, rsrp
// - DIHAPUS  : earfcn (tidak ada di NeighbourCell plugin)

class CaptureNeighbourCell {
  final int? ci;
  final int? pci;
  final int? tac;
  final int? rsrp;
  final int? rsrq;
  final String? networkType;

  const CaptureNeighbourCell({
    this.ci,
    this.pci,
    this.tac,
    this.rsrp,
    this.rsrq,
    this.networkType,
  });

  factory CaptureNeighbourCell.fromNeighbourCell(NeighbourCell n) =>
      CaptureNeighbourCell(
        ci: n.ci,
        pci: n.pci,
        tac: n.tac,
        rsrp: n.rsrp,
        rsrq: n.rsrq,
        networkType: n.networkType,
      );

  Map<String, dynamic> toJson() => {
    'ci': ci,
    'pci': pci,
    'tac': tac,
    'rsrp': rsrp,
    'rsrq': rsrq,
    'network_type': networkType,
  };
}

// ─── Cell (per snapshot) ──────────────────────────────────────────────────────

class CaptureCell {
  final DateTime ts;
  final CaptureServingCell serving;
  final List<CaptureNeighbourCell> neighbours;

  const CaptureCell({
    required this.ts,
    required this.serving,
    required this.neighbours,
  });

  Map<String, dynamic> toJson() => {
    'ts': ts.toUtc().toIso8601String(),
    'serving': serving.toJson(),
    'neighbours': neighbours.map((n) => n.toJson()).toList(),
  };
}

// ─── Root Payload ─────────────────────────────────────────────────────────────

class CaptureFullPayload {
  final CaptureDevice device;
  final CaptureSim sim;
  final CaptureCellularInfo? cellularInfo;
  final CaptureCycle cycle;
  final List<CaptureLocation> locations;
  final List<CaptureTelephony> telephony;
  final List<CaptureSpeed> speed;
  final List<CaptureCell> cell;

  const CaptureFullPayload({
    required this.device,
    required this.sim,
    this.cellularInfo,
    required this.cycle,
    required this.locations,
    required this.telephony,
    required this.speed,
    required this.cell,
  });

  Map<String, dynamic> toJson() => {
    'device': device.toJson(),
    'sim': sim.toJson(),
    'cellular_info': cellularInfo?.toJson(),
    'cycle': cycle.toJson(),
    'locations': locations.map((l) => l.toJson()).toList(),
    'telephony': telephony.map((t) => t.toJson()).toList(),
    'speed': speed.map((s) => s.toJson()).toList(),
    'cell': cell.map((c) => c.toJson()).toList(),
  };
}

// ─── Response ─────────────────────────────────────────────────────────────────

class CaptureFullResponse {
  final String message;
  final int captureId;

  const CaptureFullResponse({required this.message, required this.captureId});

  factory CaptureFullResponse.fromJson(Map<String, dynamic> json) =>
      CaptureFullResponse(
        message: json['message'] as String,
        captureId: json['capture_id'] as int,
      );
}
