import 'package:connectivity_plus/connectivity_plus.dart';

class UseConnectivity {
  Future<String> checkConnectivity() async {
    var result = "";
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      result = 'Mobile';
    } else if (connectivityResult == ConnectivityResult.wifi) {
      result = 'Wifi';
    }

    return result;
  }
}
