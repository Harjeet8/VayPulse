import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/services/node_wifi_provisioning_service.dart';

void main() {
  test('Configure Node Wi-Fi opens ESP32 dashboard when local node is reachable',
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

  test('Configure Node Wi-Fi reports external browser launch failure', () async {
    final service = NodeWifiProvisioningService(
      canReach: (_) async => true,
      launchExternal: (_) async => false,
    );

    expect(
      await service.open(),
      NodeWifiProvisioningResult.launchFailed,
    );
  });
}
