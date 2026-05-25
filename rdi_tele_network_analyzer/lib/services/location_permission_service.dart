import 'package:permission_handler/permission_handler.dart';

class LocationPermissionService {
  static const String TAG = "RDI:LocationPermission";

  static Future<bool> request() async {
    final whenInUse = await Permission.locationWhenInUse.request();
    _log("whenInUse = $whenInUse");

    if (!whenInUse.isGranted) return false;

    final always = await Permission.locationAlways.request();
    _log("always = $always");

    return true;
  }

  static Future<bool> hasForeground() async =>
      Permission.locationWhenInUse.isGranted;

  static Future<bool> hasBackground() async =>
      Permission.locationAlways.isGranted;

  static void _log(String msg) => print("[$TAG] $msg");
}
