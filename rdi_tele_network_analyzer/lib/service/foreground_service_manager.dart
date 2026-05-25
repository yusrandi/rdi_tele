import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'network_task_handler.dart';

class ForegroundServiceManager {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'network_monitor_channel',
        channelName: 'Network Monitor',
        channelDescription: 'Sedang menganalisis jaringan...',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        // buttons: [const NotificationButton(id: 'btn_stop', text: 'Stop Test')],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> start() async {
    final result = await FlutterForegroundTask.startService(
      serviceId: 1001,
      notificationTitle: 'Real Speed Analyzer',
      notificationText: 'Memulai sesi analisis jaringan...',
      callback: startCallback,
    );
    return result is ServiceRequestSuccess;
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  static Future<void> resetTimer() async {
    FlutterForegroundTask.sendDataToTask({'action': 'reset_timer'});
  }

  static void addDataCallback(Function(Object) callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  static void removeDataCallback(Function(Object) callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}
