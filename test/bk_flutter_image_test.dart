import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bk_flutter_image/bk_flutter_image.dart';

void main() {
  const MethodChannel channel = MethodChannel('bk_flutter_image');

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
//    expect(await BkFlutterImage.platformVersion, '42');
  });
}
