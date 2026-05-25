import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(NetworkTaskHandler());
}

class NetworkTaskHandler extends TaskHandler {
  int _elapsedSeconds = 0; // ← field ada di sini
  static const int sessionDurationSeconds = 180;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _elapsedSeconds = 0;
    print('[NetworkTask] Foreground service started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _elapsedSeconds++;
    final remaining = sessionDurationSeconds - _elapsedSeconds;

    FlutterForegroundTask.sendDataToMain({
      'type': 'tick',
      'elapsed': _elapsedSeconds,
      'remaining': remaining,
    });

    // Update notifikasi tiap 10 detik
    if (_elapsedSeconds % 10 == 0) {
      final mm = (remaining ~/ 60).toString().padLeft(2, '0');
      final ss = (remaining % 60).toString().padLeft(2, '0');
      FlutterForegroundTask.updateService(
        notificationTitle: 'Real Speed Analyzer — Sesi Aktif',
        notificationText: 'Sisa waktu: $mm:$ss',
      );
    }

    // Sesi habis
    if (_elapsedSeconds >= sessionDurationSeconds) {
      FlutterForegroundTask.sendDataToMain({'type': 'session_timeout'});
      _elapsedSeconds = 0;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('[NetworkTask] Foreground service destroyed');
  }

  // ← onReceiveData ada di sini, bukan di ForegroundServiceManager
  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      if (data['action'] == 'reset_timer') {
        _elapsedSeconds = 0;
        print('[NetworkTask] Timer reset');
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_stop') {
      FlutterForegroundTask.sendDataToMain({'type': 'stop_requested'});
    }
  }
}
