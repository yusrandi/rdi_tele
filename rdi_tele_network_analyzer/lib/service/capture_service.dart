import 'dart:developer';
import 'package:geolocator/geolocator.dart';
import 'package:rdi_tele/models/telephony_info_model.dart';
import 'package:realspeed_analyzer/model/capture_model.dart';
import 'package:realspeed_analyzer/model/telephony_snapshot.dart';
import 'package:realspeed_analyzer/repository/capture_repository.dart';
import 'package:realspeed_analyzer/utils/api_client.dart';

// ─── Result wrapper ───────────────────────────────────────────────────────────

sealed class CaptureResult {
  const CaptureResult();
}

class CaptureSuccess extends CaptureResult {
  final CaptureFullResponse response;
  const CaptureSuccess(this.response);
}

class CaptureFailure extends CaptureResult {
  final String error;
  const CaptureFailure(this.error);
}

// ─── Service ──────────────────────────────────────────────────────────────────

class CaptureService {
  CaptureService({ICaptureRepository? repository})
    : _repository = repository ?? CaptureRepository();

  final ICaptureRepository _repository;
  static const _tag = 'CaptureService';

  Future<CaptureResult> submitFullCapture({
    required DeviceInfo deviceInfo,
    required SimInfo simInfo,
    required CellularInfo? cellularInfo,
    required DateTime sessionStartedAt,
    required DateTime sessionEndedAt,
    required List<Position> positions,
    required List<TelephonySnapshot> telemetryHistory,
    required double downloadSpeed,
    required double uploadSpeed,
    required double ping,
    required String speedUnit,
    required ServingCell? servingCell,
    required List<NeighbourCell> neighbourCells,
  }) async {
    try {
      final payload = _buildPayload(
        deviceInfo: deviceInfo,
        simInfo: simInfo,
        cellularInfo: cellularInfo,
        sessionStartedAt: sessionStartedAt,
        sessionEndedAt: sessionEndedAt,
        positions: positions,
        telemetryHistory: telemetryHistory,
        downloadSpeed: downloadSpeed,
        uploadSpeed: uploadSpeed,
        ping: ping,
        speedUnit: speedUnit,
        servingCell: servingCell,
        neighbourCells: neighbourCells,
      );

      log(
        '[$_tag] Submitting — '
        'payload: ${payload.toJson()},',
      );

      final response = await _repository.submitCapture(payload);
      log('[$_tag] Saved — capture_id: ${response.captureId}');
      return CaptureSuccess(response);
    } on ApiException catch (e) {
      log('[$_tag] ApiException: $e');
      return CaptureFailure(e.message);
    } catch (e, st) {
      log('[$_tag] Unexpected: $e', stackTrace: st);
      return CaptureFailure('Unexpected error: $e');
    }
  }

  // ─── Payload builder ────────────────────────────────────────────────────────

  CaptureFullPayload _buildPayload({
    required DeviceInfo deviceInfo,
    required SimInfo simInfo,
    required CellularInfo? cellularInfo,
    required DateTime sessionStartedAt,
    required DateTime sessionEndedAt,
    required List<Position> positions,
    required List<TelephonySnapshot> telemetryHistory,
    required double downloadSpeed,
    required double uploadSpeed,
    required double ping,
    required String speedUnit,
    required ServingCell? servingCell,
    required List<NeighbourCell> neighbourCells,
  }) {
    // Ambil cell snapshot per-timestamp dari history
    // (tiap snapshot sudah punya servingCell & neighbours-nya sendiri)
    final cellSnapshots = telemetryHistory
        .map(
          (s) => CaptureCell(
            ts: s.timestamp,
            serving: CaptureServingCell.fromServingCell(s.servingCell),
            neighbours: s.neighbourCells
                .map(CaptureNeighbourCell.fromNeighbourCell)
                .toList(),
          ),
        )
        .toList();

    return CaptureFullPayload(
      device: CaptureDevice.fromDeviceInfo(deviceInfo),
      sim: CaptureSim.fromSimInfo(simInfo),
      cellularInfo: cellularInfo != null
          ? CaptureCellularInfo.fromCellularInfo(cellularInfo)
          : null,
      cycle: CaptureCycle(startedAt: sessionStartedAt, endedAt: sessionEndedAt),
      locations: positions.map(CaptureLocation.fromPosition).toList(),
      telephony:
          telemetryHistory.map(CaptureTelephony.fromSnapshot).toList()
              as List<CaptureTelephony>,
      speed: [
        CaptureSpeed(
          dl: downloadSpeed,
          ul: uploadSpeed,
          ping: ping,
          unit: speedUnit,
          ts: sessionEndedAt,
        ),
      ],
      // Jika tidak ada history, fallback ke servingCell terakhir
      cell: cellSnapshots.isNotEmpty
          ? cellSnapshots
          : _buildFallbackCell(servingCell, neighbourCells, sessionEndedAt),
    );
  }

  List<CaptureCell> _buildFallbackCell(
    ServingCell? serving,
    List<NeighbourCell> neighbours,
    DateTime ts,
  ) {
    if (serving == null) return [];
    return [
      CaptureCell(
        ts: ts,
        serving: CaptureServingCell.fromServingCell(serving),
        neighbours: neighbours
            .map(CaptureNeighbourCell.fromNeighbourCell)
            .toList(),
      ),
    ];
  }
}
