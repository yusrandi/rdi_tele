import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:rdi_tele/models/cit_model.dart';
import 'package:rdi_tele/rdi_tele_method_channel.dart';
import 'package:rdi_tele/use_connectivity.dart';
import 'package:intl/intl.dart';
import 'package:rdi_tele/use_constant.dart';
import 'package:rdi_tele/use_location.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rdi_tele/use_services.dart';
import 'package:rdi_tele/use_tele.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class RdiTesting extends StatefulWidget {
  const RdiTesting({super.key});

  @override
  State<RdiTesting> createState() => _RdiTestingState();
}

class _RdiTestingState extends State<RdiTesting> {
  static const String TAG = "RDI:Testing";

  Timer? countdownTimer;
  Duration myDuration = const Duration(minutes: 3);

  final List<String> _events = [];
  final List<String> dateTime = [];
  final List<Map<dynamic, dynamic>> _eventsResult = [];

  final _useTele = UseTele();
  final _rdiTelePlugin = MethodChannelRdiTele();

  String resConnection = '';
  String resCqi = '0';
  String resSignalQuality = '0';
  String resSignalStrength = '0';
  String resRsrp = '0';
  String resRsrq = '0';
  String resRssnr = '0';
  String resRssi = '0';
  String resTA = '0';
  String resJitter = '0.0';
  String resRtPing = '0.0';
  String resUpload = '0.0';
  String resDownload = '0.0';
  String resLat = '0.0';
  String resLng = '0.0';
  String resNetworkType = "";
  String resNetworkOperator = "";
  String resUuid = "";
  String resBrand = "";
  String resDevice = "";
  String resModel = "";
  String resCellId = "";
  String resAddress = "";
  String resDataConnect = "";
  String resDateTime = "";
  String resVersion = "";

  void startTimer() {
    countdownTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd  kk:mm:ss:SSS').format(now);
      //   resDateTime = formattedDate;
      setCountDown();
    });
  }

  void stopTimer() {
    setState(() => countdownTimer!.cancel());
  }

  void resetTimer() {
    stopTimer();
    setState(() => myDuration = const Duration(minutes: 3));
  }

  void setCountDown() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd  kk:mm:ss:SSS').format(now);
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = myDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        resetTimer();
        _events.insert(0, "$formattedDate Sending request . . .");

        // print(_eventsResult.toString());

        List<int> listCqi = [];
        List<int> listRsrq = [];
        List<int> listSignalStrength = [];
        List<int> listSignalQuality = [];
        List<int> listRsrp = [];
        List<int> listRssi = [];
        List<int> listRssnr = [];
        List<int> listCellId = [];
        List<int> listTA = [];

        for (var element in _eventsResult) {
          listCqi.add(element[UseTMConst.cqi]);
          listRsrq.add(element[UseTMConst.rsrq]);
          listSignalStrength.add(element[UseTMConst.dbm]);
          listSignalQuality.add(element[UseTMConst.rsrq]);
          listRsrp.add(element[UseTMConst.rsrp]);
          listRssi.add(element[UseTMConst.rssi]);
          listRssnr.add(element[UseTMConst.rssnr]);
          listCellId.add(element[UseTMConst.cellid]);
          listTA.add(element[UseTMConst.ta]);
        }

        print(listRssi.join(","));
        resCqi = listCqi.join(",");
        resRsrq = listRsrq.join(",");
        resSignalStrength = listSignalStrength.join(",");
        resSignalQuality = listSignalQuality.join(",");
        resRsrp = listRsrp.join(",");
        resRssi = listRssi.join(",");
        resRssnr = listRssnr.join(",");
        resCellId = listCellId.join(",");
        resTA = listTA.join(",");
        resDateTime = dateTime.join(",");

        storeToCit(formattedDate);
      } else {
        myDuration = Duration(seconds: seconds);
        // todo();
        todoInPriodic(formattedDate);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    startTimer();
    todo();
    // tesLooping();
    // initPlatformState();

    // alarmManager();
  }

  // Be sure to annotate your callback function to avoid issues in release mode on Flutter >= 3.3.0
  @pragma('vm:entry-point')
  static void printHello() {
    final DateTime now = DateTime.now();
    final int isolateId = Isolate.current.hashCode;
    print(
        "$TAG : [$now] Hello, world! isolate=${isolateId} function='$printHello'");
    // todoInPriodic('$now');
    final instance = _RdiTestingState();
    instance.todoInPriodic('$now');
  }

  @pragma('vm:entry-point')
  Future<void> callback() async {
    print("[$TAG] this is callback");
  }

  void alarmManager() async {
    final int helloAlarmID = 10;
    await AndroidAlarmManager.periodic(
        const Duration(minutes: 1), helloAlarmID, printHello);
  }

  @pragma("vm:entry-point")
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Load persisted fetch events from SharedPreferences

    // Configure BackgroundFetch.
    try {
      var status = await BackgroundFetch.configure(
          BackgroundFetchConfig(
              minimumFetchInterval: 1,
              forceAlarmManager: true,
              stopOnTerminate: false,
              startOnBoot: true,
              enableHeadless: true,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresStorageNotLow: false,
              requiresDeviceIdle: false,
              requiredNetworkType: NetworkType.NONE),
          _onBackgroundFetch,
          _onBackgroundFetchTimeout);
      print('[$TAG] initPlatformState : configure success: $status');

      // task on init

      String cdate =
          DateFormat("EEEEE yyyy-MM-dd HH:mm:ss").format(DateTime.now());
      print("[$TAG] $cdate ");
    } on Exception catch (e) {
      print("[$TAG] initPlatformState : configure ERROR: $e");
    }
  }

  void _onBackgroundFetch(String taskId) async {
    String cdate =
        DateFormat("EEEEE yyyy-MM-dd HH:mm:ss").format(DateTime.now());

    var timestamp = DateTime.now();

    // This is the fetch-event callback.
    print("[$TAG] _onBackgroundFetch: Event received: $taskId");
    print("[$TAG] _onBackgroundFetch : _onBackgroundFetch $cdate $taskId");

    print("[$TAG] $cdate ");
    Map<dynamic, dynamic> tmChanel = await _rdiTelePlugin.getTM();
    print("[$TAG] tmChanel $tmChanel");
    // startTimer();

    // when receive task

    // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
    // for taking too long in the background.
    BackgroundFetch.finish(taskId);
  }

  /// This event fires shortly before your task is about to timeout.  You must finish any outstanding work and call BackgroundFetch.finish(taskId).
  void _onBackgroundFetchTimeout(String taskId) {
    print("[$TAG] _onBackgroundFetchTimeout:  TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
  }

  tesLooping() async {
    String formattedDate =
        DateFormat('yyyy-MM-dd  kk:mm:ss:SSS').format(DateTime.now());

    for (var i = 0; i < 50; i++) {
      print("$TAG $i $formattedDate");
      Map<dynamic, dynamic> tmChanel = await _rdiTelePlugin.getTM();
      print("[$TAG] tmChanel $tmChanel");
    }
  }

  @override
  Widget build(BuildContext context) {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));

    return Stack(
      children: [
        ListView.builder(
            itemCount: _events.length,
            itemBuilder: (BuildContext context, int index) {
              String timestamp = _events[index];
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(timestamp),
                    const Divider(),
                  ],
                ),
              );
            }),
        Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("$minutes : $seconds",
                  style: Theme.of(context).textTheme.headlineLarge),
            ))
      ],
    );
  }

  void todo() async {
    await checkConnectivity();
    await getUserLocation();

    if (Platform.isAndroid) {
      print("$TAG : operatorName ${_useTele.operatorName}");

      Map<dynamic, dynamic> deviceInfo = await _rdiTelePlugin.getDeviceInfo();
      print("[$TAG] deviceInfo $deviceInfo");

      resNetworkType = _useTele.networkType;
      resNetworkOperator = _useTele.operatorName;
      resUuid = _useTele.uuid;

      resBrand = deviceInfo[UseDeviceInfoConst.myBrand];
      resDevice = deviceInfo[UseDeviceInfoConst.myDevice];
      resModel = deviceInfo[UseDeviceInfoConst.myDeviceModel];
      resVersion = deviceInfo[UseDeviceInfoConst.myVersionRelease];
    }
  }

  void todoInPriodic(String formattedDate) async {
    if (Platform.isAndroid) {
      Map<dynamic, dynamic> tmChanel = await _rdiTelePlugin.getTM();
      //   print("[$TAG] tmChanel $tmChanel");

      String resCqi = tmChanel[UseTMConst.cqi].toString();
      String resRsrq = tmChanel[UseTMConst.rsrq].toString();
      String resSignalStrength = tmChanel[UseTMConst.dbm].toString();
      String resSignalQuality = tmChanel[UseTMConst.rsrq].toString();
      String resRsrp = tmChanel[UseTMConst.rsrp].toString();
      String resRssi = tmChanel[UseTMConst.rssi].toString();
      String resRssnr = tmChanel[UseTMConst.rssnr].toString();
      String resCellId = tmChanel[UseTMConst.cellid].toString();
      String resTA = tmChanel[UseTMConst.ta].toString();

      String result =
          "$formattedDate rsrq: $resRsrq, rsrp: $resRsrp, rssi: $resRssi, rssnr: $resRssnr, cqi: $resCqi ta: $resTA, cellid: $resCellId";

      print("$TAG $result");

      setState(() {
        _events.insert(0, "$formattedDate\n${tmChanel.toString()}");
        _eventsResult.insert(0, tmChanel);
        dateTime.insert(0, formattedDate);
      });
    }
  }

  Future<String> checkConnectivity() async {
    String connect = await UseConnectivity().checkConnectivity();
    print("$TAG CheckConnectivity $connect");

    resConnection = connect;

    // setState(() {
    //   _events.insert(0, "$TAG Connectivity $connect");
    // });

    return connect;
  }

  Future<Position> getUserLocation() async {
    Position position = await UseLocation().getGeoLocationPosition();
    print("[$TAG], Lat: ${position.latitude} , Long: ${position.longitude}");

    resLat = position.latitude.toString();
    resLng = position.longitude.toString();

    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    // print(placemarks);
    Placemark place = placemarks[0];
    var loc =
        '${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}, ${place.country}';
    print('[$TAG], $loc');

    resAddress = loc;

    setState(() {
      _events.insert(0,
          "Latitude: ${position.latitude} , Longitude: ${position.longitude}");
      _events.insert(0, "Address $loc");
    });

    return position;
  }

  storeToCit(String formattedDate) async {
    CitModel model = CitModel(
        connection: resConnection,
        cqi: resCqi,
        signalQuality: resSignalQuality,
        signalStrength: resSignalStrength,
        rssnr: resRssnr,
        upload: resUpload,
        download: resDownload,
        jitter: resJitter,
        rtPing: resRtPing,
        latPos: resLat,
        lngPos: resLng,
        networkType: resNetworkType,
        networkOperator: resNetworkOperator,
        uuid: resUuid,
        cellid: resCellId,
        brand: resBrand,
        device: resDevice,
        model: resModel,
        address: resAddress,
        ta: resTA,
        data: resDataConnect,
        date: resDateTime,
        version: resVersion);

    var response = await UserServcies().passDataCit(model);
    _events.insert(0, "$formattedDate has been sending request . . .");
    _events.insert(0, "$formattedDate response $response");

    print('$TAG response $response');
    startTimer();
  }
}
