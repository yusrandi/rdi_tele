import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rdi_tele_platform_interface.dart';

/// An implementation of [RdiTelePlatform] that uses method channels.
class MethodChannelRdiTele extends RdiTelePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rdi_tele');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<Map> getDeviceInfo() async {
    try {
      LinkedHashMap<Object?, Object?> data =
          await methodChannel.invokeMethod('getUid');
      return data;
    } on PlatformException catch (e) {
      return {};
    }
  }

  @override
  Future<Map> getTM() async {
    try {
      LinkedHashMap<Object?, Object?> data =
          await methodChannel.invokeMethod('getTM');
      return data;
    } on PlatformException catch (e) {
      return {};
    }
  }

  @override
  Future<Map> getPing() async {
    try {
      LinkedHashMap<Object?, Object?> data =
          await methodChannel.invokeMethod('getPing');
      return data;
    } on PlatformException catch (e) {
      return {};
    }
  }
}
