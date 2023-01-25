import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rdi_tele/rdi_tele_method_channel.dart';

void main() {
  MethodChannelRdiTele platform = MethodChannelRdiTele();
  const MethodChannel channel = MethodChannel('rdi_tele');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
