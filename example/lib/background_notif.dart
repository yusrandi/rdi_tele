import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:intl/intl.dart';

class BackgroundNotif extends StatefulWidget {
  const BackgroundNotif({super.key});

  @override
  State<BackgroundNotif> createState() => _BackgroundNotifState();
}

class _BackgroundNotifState extends State<BackgroundNotif> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Bakcground Notif'),
    );
  }

  @override
  void initState() {
    super.initState();
    // initPlatformState();
  }

  @pragma("vm:entry-point")
  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Load persisted fetch events from SharedPreferences

    // Configure BackgroundFetch.
    try {
      var status = await BackgroundFetch.configure(
          BackgroundFetchConfig(
              minimumFetchInterval: 3,
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
      print('[BackgroundFetch] initPlatformState : configure success: $status');

      // task on init

      String cdate =
          DateFormat("EEEEE yyyy-MM-dd HH:mm:ss").format(DateTime.now());
      print("[BackgroundFetch] $cdate ");
    } on Exception catch (e) {
      print("[BackgroundFetch] initPlatformState : configure ERROR: $e");
    }
  }

  void _onBackgroundFetch(String taskId) async {
    String cdate =
        DateFormat("EEEEE yyyy-MM-dd HH:mm:ss").format(DateTime.now());

    var timestamp = DateTime.now();

    // This is the fetch-event callback.
    print("[BackgroundFetch] _onBackgroundFetch: Event received: $taskId");
    print(
        "[BackgroundFetch] _onBackgroundFetch : _onBackgroundFetch $cdate $taskId");

    print("[BackgroundFetch] $cdate ");

    // when receive task

    // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
    // for taking too long in the background.
    BackgroundFetch.finish(taskId);
  }

  /// This event fires shortly before your task is about to timeout.  You must finish any outstanding work and call BackgroundFetch.finish(taskId).
  void _onBackgroundFetchTimeout(String taskId) {
    print("[BackgroundFetch] _onBackgroundFetchTimeout:  TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
  }
}
