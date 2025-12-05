import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const String TAG = "RDI:Testing";

  static Future<bool> requestTelephonyPermissions() async {
    final statuses = await [
      //   Permission.sms,
      Permission.location,
      //   Permission.locationWhenInUse,
      //   Permission.locationAlways,
      Permission.phone,
    ].request();

    print("[$TAG] location = ${await Permission.location.status}");
    print("[$TAG] phone = ${await Permission.phone.status}");
    // print("[$TAG] sms = ${await Permission.sms.status}");

    return statuses.values.every((status) => status.isGranted);
  }
}
