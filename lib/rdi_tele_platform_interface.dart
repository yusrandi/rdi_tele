import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rdi_tele_method_channel.dart';

abstract class RdiTelePlatform extends PlatformInterface {
  /// Constructs a RdiTelePlatform.
  RdiTelePlatform() : super(token: _token);

  static final Object _token = Object();

  static RdiTelePlatform _instance = MethodChannelRdiTele();

  /// The default instance of [RdiTelePlatform] to use.
  ///
  /// Defaults to [MethodChannelRdiTele].
  static RdiTelePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RdiTelePlatform] when
  /// they register themselves.
  static set instance(RdiTelePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Map> getDeviceInfo() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Map> getTM() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Map> getPing() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
