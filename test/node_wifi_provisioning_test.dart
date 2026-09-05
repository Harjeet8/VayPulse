import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/services/node_wifi_provisioning_service.dart';

void main() {
  test(
      'Configure Node Wi-Fi opens ESP32 dashboard when local node is reachable',
      () async {
    Uri? launched;
    final service = NodeWifiProvisioningService(
      canReach: (endpoint) async {
        expect(endpoint, NodeWifiProvisioningService.dashboardUrl);
        return true;
      },
      launchExternal: (uri) async {
        launched = uri;
        return true;
      },
    );

    final result = await service.open();

    expect(result, NodeWifiProvisioningResult.opened);
    expect(launched, Uri.parse('http://192.168.4.1'));
  });

  test('Configure Node Wi-Fi does not launch when local node is unreachable',
      () async {
    var launchCalled = false;
    final service = NodeWifiProvisioningService(
      canReach: (_) async => false,
      launchExternal: (_) async {
        launchCalled = true;
        return true;
      },
    );

    final result = await service.open();

    expect(result, NodeWifiProvisioningResult.localNodeUnreachable);
    expect(launchCalled, isFalse);
  });

  test('Configure Node Wi-Fi reports external browser launch failure',
      () async {
    final service = NodeWifiProvisioningService(
      canReach: (_) async => true,
      launchExternal: (_) async => false,
    );

    expect(
      await service.open(),
      NodeWifiProvisioningResult.launchFailed,
    );
  });
  test('Devices UI wires provisioning to external ESP32 dashboard', () {
    final source = File('lib/screens/devices_screen.dart').readAsStringSync();

    expect(source, contains("'configure_node_wifi'"));
    expect(source, contains('NodeWifiProvisioningService('));
    expect(source, contains('LaunchMode.externalApplication'));
    expect(source, contains('sensorManager.testEndpoint'));
  });

  test('Flutter source does not store router passwords', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final source = files.map((file) => file.readAsStringSync()).join('\n');

    expect(
      RegExp(
        r'(routerPassword|wifiPassword|wiFiPassword|staPassword)',
        caseSensitive: false,
      ).hasMatch(source),
      isFalse,
    );
  });
}
