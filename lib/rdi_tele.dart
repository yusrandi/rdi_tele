import 'dart:io';

import 'package:rdi_tele/models/cit_model.dart';
import 'package:rdi_tele/rdi_tele_method_channel.dart';
import 'package:rdi_tele/use_connectivity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rdi_tele/use_constant.dart';
import 'package:rdi_tele/use_location.dart';
import 'package:rdi_tele/use_services.dart';
import 'package:rdi_tele/use_tele.dart';

import 'rdi_tele_platform_interface.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:background_fetch/background_fetch.dart';
// import 'package:flutter_speedtest/flutter_speedtest.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';

import 'package:intl/intl.dart';

class RdiTele {
  static const String TAG = "[RdiTele]";
  final _rdiTelePlugin = MethodChannelRdiTele();
  final _useTele = UseTele();

  // final _speedtest = FlutterSpeedtest(
  //   pathUpload: '/upload',
  //   pathDownload: '/download',
  //   pathResponseTime: '/ping',
  //   baseUrl: 'https://speedtest.gsmnet.id.prod.hosts.ooklaserver.net:8080',
  // );

  final internetSpeedTest =
      FlutterInternetSpeedTest(); //FlutterInternetSpeedTest()..enableLog();

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
      Permission.sms,
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
    // flutterSpeedTest();
    internetSpeedTestPlugin();

    String connect = await UseConnectivity().checkConnectivity();

    resConnection = connect;
    print("$TAG : checkConnectivity $connect");

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

    print("[BackgroundFetch] : dataActivity ${_useTele.dataActivity}");

    if (Platform.isAndroid) {
      print("$TAG : operatorName ${_useTele.operatorName}");
      Map<dynamic, dynamic> deviceInfo = await _rdiTelePlugin.getDeviceInfo();
      Map<dynamic, dynamic> tmChanel = await _rdiTelePlugin.getTM();
      print("[$TAG] getUuid $deviceInfo");

      // resUuid = deviceInfo[UseDeviceInfoConst.myProduct];
      resBrand = deviceInfo[UseDeviceInfoConst.myBrand];
      resDevice = deviceInfo[UseDeviceInfoConst.myDevice];
      resModel = deviceInfo[UseDeviceInfoConst.myDeviceModel];

      print("[$TAG] resBrand $resBrand");

      resNetworkType = _useTele.networkType;

      // var operatorNameSplit = _useTele.operatorName.split("-");
      resNetworkOperator = _useTele.operatorName;
      resUuid = _useTele.uuid;
      // resCellId = _useTele.uuid;

      print("[$TAG] $tmChanel");

      resCqi = tmChanel[UseTMConst.cqi].toString();
      resRsrq = tmChanel[UseTMConst.rsrq].toString();
      resSignalStrength = tmChanel[UseTMConst.dbm].toString();
      resSignalQuality = tmChanel[UseTMConst.rsrq].toString();
      resRsrp = tmChanel[UseTMConst.rsrp].toString();
      resRssi = tmChanel[UseTMConst.rssi].toString();
      resRssnr = tmChanel[UseTMConst.rssnr].toString();
      resCellId = tmChanel[UseTMConst.cellid].toString();
      resTA = tmChanel[UseTMConst.ta].toString();
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

          resRtPing = (sum / listPing.length).toString();
          resJitter = (max - min).toString();
        }
      });
    } catch (e) {}
  }

  double downloadRate = 0;
  double uploadRate = 0;
  int stepsDown = 0;
  int stepsUp = 0;

  double _downloadRate = 0;
  double _uploadRate = 0;
  String _downloadProgress = '0';
  String _uploadProgress = '0';
  int _downloadCompletionTime = 0;
  int _uploadCompletionTime = 0;
  bool _isServerSelectionInProgress = false;
  String _unitText = 'Mb/s';

  String? _ip;
  String? _asn;
  String? _isp;

  internetSpeedTestPlugin() async {
    reset();
    await internetSpeedTest.startTesting(
      onStarted: () {
        reset();
        print('onStarted');
      },
      onCompleted: (TestResult download, TestResult upload) {
        print(
            'the transfer rate ${download.transferRate}, ${upload.transferRate}');

        _downloadRate = download.transferRate;
        _unitText = download.unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
        _downloadProgress = '100';
        _downloadCompletionTime = download.durationInMillis;

        _uploadRate = upload.transferRate;
        _unitText = upload.unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
        _uploadProgress = '100';
        _uploadCompletionTime = upload.durationInMillis;

        resDownload = (downloadRate / stepsDown).toStringAsFixed(2);
        print('[$TAG] : resdownload $resDownload');

        resUpload = (uploadRate / stepsUp).toStringAsFixed(2);
        print('[$TAG] : resUpload $resUpload');

        storeToCit();
      },
      onProgress: (double percent, TestResult data) {
        _unitText = data.unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
        if (data.type == TestType.DOWNLOAD) {
          _downloadRate = data.transferRate;
          _downloadProgress = percent.toStringAsFixed(2);
          stepsDown++;
          downloadRate += _downloadRate;

          print(
              'Download : the transfer rate $_downloadRate, the percent $_downloadProgress');
        } else {
          _uploadRate = data.transferRate;
          _uploadProgress = percent.toStringAsFixed(2);
          stepsUp++;
          uploadRate += _uploadRate;

          print(
              'Upload : the transfer rate $_uploadRate, the percent $_uploadProgress');
        }
      },
      onError: (String errorMessage, String speedTestError) {
        print(
            'the errorMessage $errorMessage, the speedTestError $speedTestError');

        reset();
      },
      onDefaultServerSelectionInProgress: () {
        _isServerSelectionInProgress = true;

        print('onDefaultServerSelectionInProgress');
      },
      onDefaultServerSelectionDone: (Client? client) {
        print('onDefaultServerSelectionDone');

        _isServerSelectionInProgress = false;
        _ip = client?.ip;
        _asn = client?.asn;
        _isp = client?.isp;
      },
      onDownloadComplete: (TestResult data) {
        _downloadRate = data.transferRate;
        _unitText = data.unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
        _downloadCompletionTime = data.durationInMillis;

        print('[$TAG] : average ${downloadRate / stepsDown}');

        print(
            'onDownloadComplete : the transfer rate $_downloadRate, the percent $_downloadCompletionTime step $stepsDown');
      },
      onUploadComplete: (TestResult data) {
        _uploadRate = data.transferRate;
        _unitText = data.unit == SpeedUnit.Kbps ? 'Kb/s' : 'Mb/s';
        _uploadCompletionTime = data.durationInMillis;

        print('[$TAG] : average ${uploadRate / stepsUp}');

        print(
            'onUploadComplete : the transfer rate $_uploadRate, the percent $_uploadCompletionTime step $stepsUp');
      },
    );
  }

  void reset() {
    _downloadRate = 0;
    _uploadRate = 0;
    _downloadProgress = '0';
    _uploadProgress = '0';
    _unitText = 'Mb/s';
    _downloadCompletionTime = 0;
    _uploadCompletionTime = 0;

    downloadRate = 0;
    uploadRate = 0;
    stepsDown = 0;
    stepsUp = 0;
  }

  storeToCit() async {
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
        data: resDataConnect);

    var response = await UserServcies().passDataCit(model);
    print('$TAG response $response');
  }
}
