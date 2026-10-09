import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/services/app_integrity.dart';
import 'package:phytosense_ai/services/device_language_sync.dart';
import 'package:phytosense_ai/services/node_addresses.dart';
import 'package:phytosense_ai/services/node_light_control.dart';
import 'package:phytosense_ai/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal stand-in for firmware v12.x's /api/led and /api/audio routes.
class _FakeNode {
  late HttpServer server;
  final requests = <Uri>[];
  String Function(Uri uri) reply = (uri) {
    final q = uri.queryParameters;
    if (uri.path == '/api/audio') {
      return '{"ok":true,"language":"${q['language']}"}';
    }
    if (q['action'] == 'locate') return '{"ok":true,"action":"locate"}';
    return '{"ok":true,"state":"${q['state']}",'
        '"brightness":${q['brightness']},"source":"local"}';
  };

  String get url => 'http://127.0.0.1:${server.port}';

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      requests.add(req.uri);
      req.response
        ..statusCode = 200
        ..write(reply(req.uri));
      req.response.close();
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The test binding fakes every HTTP call as 400; talk to the real fake node.
  HttpOverrides.global = null;
  late _FakeNode node;
  late SettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppIntegrity.overrideForTest(true);
    NodeAddresses.lastWorking = null;
    NodeAddresses.homeAddress = null;
    node = _FakeNode();
    await node.start();
    settings = SettingsService()
      // Wrong address saved in Settings (nothing listens on port 9).
      ..value.esp32Endpoint = 'http://127.0.0.1:9';
  });
  tearDown(() => node.server.close(force: true));

  NodeLightControl control({bool cloudOk = false}) =>
      NodeLightControl(settings, extraAddresses: [node.url])
        ..remote = (_) async => cloudOk;

  test('Off and On reach the node even when Settings has a wrong address',
      () async {
    final c = control();
    await c.setMode(NodeLightMode.off);
    expect(node.requests.last.queryParameters['state'], 'off');
    expect(c.delivery, NodeLightDelivery.confirmed);

    await c.setMode(NodeLightMode.on);
    expect(node.requests.last.queryParameters['state'], 'on');
    expect(c.delivery, NodeLightDelivery.confirmed);
    expect(NodeAddresses.lastWorking, node.url);
  });

  test('brightness sends once with state on, as an int', () async {
    final c = control();
    Map<String, Object>? cloud;
    c.remote = (u) async {
      cloud = u;
      return true;
    };
    c.previewBrightness(40); // dragging sends nothing
    expect(node.requests, isEmpty);
    await c.commitBrightness(30);
    final q = node.requests.last.queryParameters;
    expect(q['state'], 'on');
    expect(q['brightness'], '30');
    expect(cloud!['led/brightness'], 30);
    expect(cloud!['led/state'], 'on');
    expect(cloud!['seq'], isA<int>());
    expect(c.delivery, NodeLightDelivery.confirmed);
  });

  test('a reply that does not echo the command is not a success', () async {
    final c = control();
    node.reply = (uri) => '{"ok":true}';
    await c.setMode(NodeLightMode.off);
    expect(c.delivery, isNot(NodeLightDelivery.confirmed));

    node.reply = (uri) => 'OK';
    await c.setMode(NodeLightMode.on);
    expect(c.delivery, isNot(NodeLightDelivery.confirmed));

    node.reply = (uri) => '{"state":"on","brightness":55}';
    await c.commitBrightness(80);
    expect(c.delivery, isNot(NodeLightDelivery.confirmed));
  });

  test('cloud only -> "sent, applies within ~10 s"', () async {
    final c = control(cloudOk: true);
    await node.server.close(force: true);
    await c.setMode(NodeLightMode.off);
    expect(c.delivery, NodeLightDelivery.queued);
    expect(c.mode, NodeLightMode.off);
    await node.start();
  });

  test('when both routes fail the UI reverts and says not reachable',
      () async {
    final c = control();
    await c.setMode(NodeLightMode.on); // confirmed baseline
    await node.server.close(force: true); // node gone, cloud unavailable
    await c.setMode(NodeLightMode.off);
    expect(c.delivery, NodeLightDelivery.failed);
    expect(c.mode, NodeLightMode.on, reason: 'optimistic change undone');
    await node.start(); // for tearDown
  });

  test('Find my node does not pretend to blink when nothing answered',
      () async {
    final c = NodeLightControl(settings, extraAddresses: const [])
      ..remote = (_) async => false;
    final watch = Stopwatch()..start();
    await c.locate();
    expect(c.locating, isFalse);
    expect(c.delivery, NodeLightDelivery.failed);
    expect(watch.elapsed, lessThan(const Duration(seconds: 6)));
  });

  test('echo rules match firmware replies', () {
    expect(
        NodeLightControl.echoes({'ok': true, 'state': 'on', 'brightness': 70},
            {'state': 'on', 'brightness': '70'}),
        isTrue);
    expect(
        NodeLightControl.echoes({'state': 'off', 'brightness': 70},
            {'state': 'on', 'brightness': '70'}),
        isFalse);
    expect(NodeLightControl.echoes({'ok': true}, {'action': 'locate'}), isTrue);
    expect(
        NodeLightControl.echoes({'ok': false, 'state': 'on'},
            {'state': 'on', 'brightness': '70'}),
        isFalse);
  });

  test('only real LAN addresses are cached as the home IP', () {
    expect(NodeAddresses.isPrivateIpv4('192.168.29.5'), isTrue);
    expect(NodeAddresses.isPrivateIpv4('10.0.0.7'), isTrue);
    expect(NodeAddresses.isPrivateIpv4('0.0.0.0'), isFalse);
    expect(NodeAddresses.isPrivateIpv4('8.8.8.8'), isFalse);
    expect(NodeAddresses.isPrivateIpv4(''), isFalse);
  });

  test('language is sent at start and again when the user changes it',
      () async {
    settings.value.esp32Endpoint = node.url;
    settings.value.languageCode = 'en';
    final sync = DeviceLanguageSync(settings)..start();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(node.requests.map((u) => u.queryParameters['language']),
        contains('en'));

    await settings.setLanguage('ta');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(node.requests.last.path, '/api/audio');
    expect(node.requests.last.queryParameters['language'], 'ta');
    sync.dispose();
  });

  test('unofficial copies cannot use the cloud', () async {
    AppIntegrity.overrideForTest(false);
    expect(await AppIntegrity.cloudAllowed(), isFalse);
    AppIntegrity.overrideForTest(true);
    expect(await AppIntegrity.cloudAllowed(), isTrue);
  });
}
