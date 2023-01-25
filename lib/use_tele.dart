import 'package:telephony/telephony.dart';

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

  UseTele() {
    telephonyTest();
  }

  final Telephony telephony = Telephony.instance;

  telephonyTest() async {
    isNetworkRoaming = (await telephony.isNetworkRoaming)!;
    dataState = (await telephony.cellularDataState).toString();
    dataActivity = (await telephony.cellularDataState).toString();
    networkOperator = (await telephony.networkOperator)!;
    operatorName = (await telephony.networkOperatorName)!;
    networkType = (await telephony.dataNetworkType).toString();
    phoneType = (await telephony.phoneType).toString();
    simOperator = (await telephony.simOperator)!;
    simState = (await telephony.simState).toString();
    serviceState = (await telephony.serviceState).toString();
  }
}
