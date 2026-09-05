enum NodeWifiProvisioningResult {
  opened,
  localNodeUnreachable,
  launchFailed,
}

typedef LocalNodeReachability = Future<bool> Function(String endpoint);
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

class NodeWifiProvisioningService {
  static const String dashboardUrl = 'http://192.168.4.1';

  final LocalNodeReachability canReach;
  final ExternalUrlLauncher launchExternal;

  const NodeWifiProvisioningService({
    required this.canReach,
    required this.launchExternal,
  });

  Future<NodeWifiProvisioningResult> open() async {
    final reachable = await canReach(dashboardUrl);
    if (!reachable) return NodeWifiProvisioningResult.localNodeUnreachable;

    final launched = await launchExternal(Uri.parse(dashboardUrl));
    return launched
        ? NodeWifiProvisioningResult.opened
        : NodeWifiProvisioningResult.launchFailed;
  }
}
