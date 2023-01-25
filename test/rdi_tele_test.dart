import 'package:flutter_test/flutter_test.dart';
import 'package:rdi_tele/rdi_tele.dart';
import 'package:rdi_tele/rdi_tele_platform_interface.dart';
import 'package:rdi_tele/rdi_tele_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRdiTelePlatform
    with MockPlatformInterfaceMixin
    implements RdiTelePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Map> getDeviceInfo() {
    // TODO: implement getDeviceInfo
    throw UnimplementedError();
  }

  @override
  Future<Map> getTM() {
    // TODO: implement getTM
    throw UnimplementedError();
  }
}

void main() {
  final RdiTelePlatform initialPlatform = RdiTelePlatform.instance;

  test('$MethodChannelRdiTele is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRdiTele>());
  });

  test('getPlatformVersion', () async {
    RdiTele rdiTelePlugin = RdiTele();
    MockRdiTelePlatform fakePlatform = MockRdiTelePlatform();
    RdiTelePlatform.instance = fakePlatform;

    expect(await rdiTelePlugin.getPlatformVersion(), '42');
  });
}
