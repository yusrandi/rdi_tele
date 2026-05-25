// lib/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestTelephonyPermissions() async {
    final statuses = await [
      Permission.phone,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted || s.isLimited);

    // Android 13+ butuh notification permission untuk foreground service
    // if (await Permission.notification.isDenied) {
    //   await Permission.notification.request();
    // }

    return allGranted;
  }

  // ← TAMBAH method baru untuk background location
  // Harus diminta SETELAH locationWhenInUse granted
  static Future<bool> requestBackgroundLocation() async {
    // Cek dulu apakah foreground location sudah granted
    final foreground = await Permission.locationWhenInUse.status;
    if (!foreground.isGranted) return false;

    final status = await Permission.locationAlways.request();
    return status.isGranted;
  }

  static Future<bool> isBackgroundLocationGranted() async {
    return await Permission.locationAlways.isGranted;
  }
}
