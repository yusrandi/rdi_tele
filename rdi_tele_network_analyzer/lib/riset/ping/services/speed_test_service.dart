import '../models/latency_result.dart';
import '../models/speed_result.dart';

import 'download_service.dart';
import 'ping_service.dart';
import 'upload_service.dart';

class SpeedTestService {
  final PingService pingService = PingService();

  final DownloadService downloadService = DownloadService();

  final UploadService uploadService = UploadService();

  /// =====================================================
  /// FULL TEST
  /// =====================================================

  Future<SpeedResult> start() async {
    /// ===============================================
    /// UNLOADED LATENCY
    /// ===============================================

    final unloadedLatency = await pingService.averagePing();

    final jitter = await pingService.jitter();

    /// ===============================================
    /// DOWNLOAD
    /// ===============================================

    final downloadFuture = downloadService.start();

    /// ping during download
    final downloadLoadedLatency = await pingService.averagePing();

    final downloadMbps = await downloadFuture;

    /// ===============================================
    /// UPLOAD
    /// ===============================================

    final uploadFuture = uploadService.start();

    final uploadLoadedLatency = await pingService.averagePing();

    final uploadMbps = await uploadFuture;

    return SpeedResult(
      downloadMbps: downloadMbps,
      uploadMbps: uploadMbps,
      latency: LatencyResult(
        unloadedLatency: unloadedLatency,
        downloadLoadedLatency: downloadLoadedLatency,
        uploadLoadedLatency: uploadLoadedLatency,
        jitter: jitter,
      ),
    );
  }

  void dispose() {
    pingService.dispose();
  }
}
