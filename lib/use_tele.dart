import 'dart:io';

// import 'package:telephony/telephony.dart';
// import 'package:device_info_plus/device_info_plus.dart';

class UseTele {
  bool isNetworkRoaming = false;
  String dataState = "";
  String dataActivity = "";
  String networkOperator = "";
  String operatorName = "";
  String networkType = "";
  String phoneType = "";
  String simOperator = "";
  String simState = "";
  String serviceState = "";
  String uuid = "";

  UseTele() {
    telephonyTest();
  }

//   final Telephony telephony = Telephony.instance;
//   var deviceInfo = DeviceInfoPlugin();

  telephonyTest() async {
    // isNetworkRoaming = (await telephony.isNetworkRoaming)!;
    // dataState = (await telephony.cellularDataState).toString();
    // dataActivity = (await telephony.cellularDataState).toString();
    // networkOperator = (await telephony.networkOperator)!;
    // operatorName = (await telephony.networkOperatorName)!;

    // NetworkType? networkTypeIs = await telephony.dataNetworkType;

    // networkType = networkTypeIs.name;

    // phoneType = (await telephony.phoneType).toString();
    // simOperator = (await telephony.simOperator)!;
    // simState = (await telephony.simState).toString();
    // serviceState = (await telephony.serviceState).toString();

    if (Platform.isAndroid) {
      //   var androidDeviceInfo = await deviceInfo.androidInfo;
      //   uuid = androidDeviceInfo.id; // unique ID on Android
    }
  }
}
