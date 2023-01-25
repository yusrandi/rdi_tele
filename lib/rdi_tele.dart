import 'dart:io';

import 'package:rdi_tele/models/cit_model.dart';
import 'package:rdi_tele/rdi_tele_method_channel.dart';
import 'package:rdi_tele/use_connectivity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rdi_tele/use_location.dart';
import 'package:rdi_tele/use_services.dart';
import 'package:rdi_tele/use_tele.dart';

import 'rdi_tele_platform_interface.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_speedtest/flutter_speedtest.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:intl/intl.dart';

class RdiTele {
  static const String TAG = "[RdiTele]";
  final _rdiTelePlugin = MethodChannelRdiTele();
  final _useTele = UseTele();

  final _speedtest = FlutterSpeedtest(
    pathUpload: '/upload',
    pathDownload: '/download',
    pathResponseTime: '/ping',
    baseUrl: 'https://speedtest.gsmnet.id.prod.hosts.ooklaserver.net:8080',
  );

  String resCqi = '0';
  String resSignalQuality = '0';
  String resSignalStrength = '0';
  String resRsrp = '0';
  String resRsrq = '0';
  String resRssnr = '0';
  String resRssi = '0';
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

  RdiTele() {
    initData();
  }
  Future<String?> getPlatformVersion() {
    return RdiTelePlatform.instance.getPlatformVersion();
  }

  initData() async {
    await permissionStatus();

    await initPlatformState();
  }

  Future<void> permissionStatus() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.phone,
    ].request();
    print("[$TAG], Permission.location1 ${statuses[Permission.location]}");
  }

  @pragma("vm:entry-point")
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Load persisted fetch events from SharedPreferences

    // Configure BackgroundFetch.
    try {
      var status = await BackgroundFetch.configure(
          BackgroundFetchConfig(
              minimumFetchInterval: 5,
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
      print('[BackgroundFetch] configure success: $status');

      // task on init

      String cdate =
          DateFormat("EEEEE yyyy-MM-dd HH:mm:ss").format(DateTime.now());
      print("[BackgroundFetch] $cdate ");
      todo();
    } on Exception catch (e) {
      print("[BackgroundFetch] configure ERROR: $e");
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    // if (!mounted) return;
  }

  void _onBackgroundFetch(String taskId) async {
    String cdate =
        DateFormat("EEEEE yyyy-MM-dd HH:mm:ss").format(DateTime.now());

    var timestamp = DateTime.now();

    // This is the fetch-event callback.
    print("[BackgroundFetch] Event received: $taskId");
    print("[BackgroundFetch] : _onBackgroundFetch $cdate $taskId");
    todo();

    // when receive task

    // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
    // for taking too long in the background.
    BackgroundFetch.finish(taskId);
  }

  /// This event fires shortly before your task is about to timeout.  You must finish any outstanding work and call BackgroundFetch.finish(taskId).
  void _onBackgroundFetchTimeout(String taskId) {
    print("[BackgroundFetch] TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
  }

  void todo() async {
    await pingTest();
    flutterSpeedTest();

    String connect = await UseConnectivity().checkConnectivity();
    print("$TAG : checkConnectivity $connect");

    Position position = await UseLocation().getGeoLocationPosition();
    print("[$TAG], Lat: ${position.latitude} , Long: ${position.longitude}");
    print("[BackgroundFetch] : dataActivity ${_useTele.dataActivity}");

    if (Platform.isAndroid) {
      // print("$TAG : operatorName ${useTele.operatorName}");
      Map<dynamic, dynamic> deviceInfo = await _rdiTelePlugin.getDeviceInfo();
      Map<dynamic, dynamic> tmChanel = await _rdiTelePlugin.getTM();
      print("[$TAG] getUuid $deviceInfo");
      print("[$TAG] $tmChanel");
    }
  }

  pingTest() async {
    int countPing = 5;
    final ping = Ping('google.com', count: countPing);

    print('Running command: ${ping.command}');

    List<int> listPing = [];

    try {
      ping.stream.listen((event) {
        print("[$TAG] ping $event");

        final res = event.response;
        if (res == null) return;

        listPing.add(event.response!.time!.inMilliseconds);

        final ip = res.ip;
        final ttl = res.ttl;
        final time = res.time;

        print("[$TAG] ping ip $ip, ttl $ttl, time $time");

        if (listPing.length == countPing) {
          // print("Ping Count ${listPing.length}");

          int sum = listPing.fold(0, (p, c) => p + c);
          int max = listPing.reduce((curr, next) => curr > next ? curr : next);
          int min = listPing.reduce((curr, next) => curr < next ? curr : next);

          // print("Sum ${sum}");
          print(
              "RT  sum $sum / length ${listPing.length}  = ${sum / listPing.length}");
          print("Jitter Max $max -  Min $min  = ${max - min} ");
        }
      });
    } catch (e) {}
  }

  double downloadRate = 0;
  double uploadRate = 0;
  int stepsDown = 0;
  int stepsUp = 0;

  flutterSpeedTest() {
    _speedtest.getDataspeedtest(
      downloadOnProgress: ((percent, transferRate) {
        String cdate = DateFormat("HH:mm:ss").format(DateTime.now());
        var proggress = transferRate.toStringAsFixed(2);
        print(
            '[$TAG][$cdate] :  download percent ${(percent * 100).round()}%, transferrate $proggress');
        downloadRate += transferRate;
        stepsDown++;
      }),
      uploadOnProgress: ((percent, transferRate) {
        String cdate = DateFormat("HH:mm:ss").format(DateTime.now());
        var proggress = transferRate.toStringAsFixed(2);
        print(
            '[$TAG][$cdate] :  upload percent ${(percent * 100).round()}%, transferrate $proggress');

        uploadRate += transferRate;
        stepsUp++;
      }),
      progressResponse: ((responseTime, jitter) {
        String cdate = DateFormat("HH:mm:ss").format(DateTime.now());
        print(
            '[$TAG][$cdate] : progressResponse ping $responseTime, jitter $jitter');
      }),
      onError: ((errorMessage) {
        String cdate = DateFormat("HH:mm:ss").format(DateTime.now());
        print('[$TAG][$cdate] : onError  $errorMessage');
      }),
      onDone: () {
        String cdate = DateFormat("HH:mm:ss").format(DateTime.now());
        print('[$TAG][$cdate] : onDone');
        print('[$TAG][$cdate] : total downloadrate $downloadRate');
        print('[$TAG][$cdate] : total steps $stepsDown');
        print('[$TAG][$cdate] : average ${downloadRate / stepsDown}');
        print('[$TAG][$cdate] : total uploadrate $uploadRate');
        print('[$TAG][$cdate] : total steps $stepsUp');
        print('[$TAG][$cdate] : average ${uploadRate / stepsUp}');

        var resDownload = (downloadRate / stepsDown).toStringAsFixed(2);
        print('[$TAG][$cdate] : resdownload $resDownload');

        var resUpload = (uploadRate / stepsUp).toStringAsFixed(2);
        print('[$TAG][$cdate] : resUpload $resUpload');

        storeToCit();
      },
      // isDone: (bool isDone) {
      //   String cdate = DateFormat("HH:mm:ss").format(DateTime.now());

      //   print('[SpeedTest][$cdate] : onIsDone $isDone');
      //   print('[SpeedTest][$cdate] : total downloadrate $downloadRate');
      //   print('[SpeedTest][$cdate] : total steps $stepsDown');
      //   print('[SpeedTest][$cdate] : average ${downloadRate / stepsDown}');

      //   if (isDone) {
      //     resDownload = (downloadRate / stepsDown).toStringAsFixed(2);

      //   }
      // },
    );
  }

  storeToCit() async {
    CitModel model = CitModel(
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
        data: resDataConnect);

    var response = await UserServcies().passDataCit(model);
    print('$TAG response $response');
  }
}
