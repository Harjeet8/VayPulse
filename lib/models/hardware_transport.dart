enum HardwareTransportMode { auto, local, remote }

extension HardwareTransportModeX on HardwareTransportMode {
  String get id => name.toUpperCase();

  static HardwareTransportMode parse(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'LOCAL':
        return HardwareTransportMode.local;
      case 'REMOTE':
        return HardwareTransportMode.remote;
      default:
        return HardwareTransportMode.auto;
    }
  }
}

enum HardwareTransportKind { none, local, remote }

enum RemoteSnapshotFreshness { live, delayed, stale, offline }

extension RemoteSnapshotFreshnessX on RemoteSnapshotFreshness {
  bool get usable =>
      this == RemoteSnapshotFreshness.live ||
      this == RemoteSnapshotFreshness.delayed;
}

class HardwareConnectionMetadata {
  final HardwareTransportKind transport;
  final RemoteSnapshotFreshness freshness;
  final String connectionMode;
  final String remoteNetworkState;
  final bool? localApActive;
  final bool? internetConnected;
  final bool? cloudConnected;
  final String connectedStaSsid;
  final DateTime? lastCloudSync;
  final DateTime? lastSeen;
  final String firmwareVersion;
  final String firmwareEdition;
  final String buildState;

  const HardwareConnectionMetadata({
    this.transport = HardwareTransportKind.none,
    this.freshness = RemoteSnapshotFreshness.offline,
    this.connectionMode = '',
    this.remoteNetworkState = '',
    this.localApActive,
    this.internetConnected,
    this.cloudConnected,
    this.connectedStaSsid = '',
    this.lastCloudSync,
    this.lastSeen,
    this.firmwareVersion = '',
    this.firmwareEdition = '',
    this.buildState = '',
  });

  HardwareConnectionMetadata copyWith({
    HardwareTransportKind? transport,
    RemoteSnapshotFreshness? freshness,
    String? connectionMode,
    String? remoteNetworkState,
    bool? localApActive,
    bool? internetConnected,
    bool? cloudConnected,
    String? connectedStaSsid,
    DateTime? lastCloudSync,
    DateTime? lastSeen,
    String? firmwareVersion,
    String? firmwareEdition,
    String? buildState,
  }) =>
      HardwareConnectionMetadata(
        transport: transport ?? this.transport,
        freshness: freshness ?? this.freshness,
        connectionMode: connectionMode ?? this.connectionMode,
        remoteNetworkState: remoteNetworkState ?? this.remoteNetworkState,
        localApActive: localApActive ?? this.localApActive,
        internetConnected: internetConnected ?? this.internetConnected,
        cloudConnected: cloudConnected ?? this.cloudConnected,
        connectedStaSsid: connectedStaSsid ?? this.connectedStaSsid,
        lastCloudSync: lastCloudSync ?? this.lastCloudSync,
        lastSeen: lastSeen ?? this.lastSeen,
        firmwareVersion: firmwareVersion ?? this.firmwareVersion,
        firmwareEdition: firmwareEdition ?? this.firmwareEdition,
        buildState: buildState ?? this.buildState,
      );
}

class RemoteSnapshotFreshnessPolicy {
  static const liveWindow = Duration(seconds: 10);
  static const delayedWindow = Duration(seconds: 30);

  static RemoteSnapshotFreshness classify({
    required DateTime? lastSeen,
    DateTime? now,
    bool? internetConnected,
    bool? cloudConnected,
  }) {
    if (lastSeen == null) return RemoteSnapshotFreshness.offline;
    final reference = now ?? DateTime.now();
    var age = reference.difference(lastSeen);
    if (age.isNegative) age = Duration.zero;

    if (age <= liveWindow) {
      if (cloudConnected == false || internetConnected == false) {
        return RemoteSnapshotFreshness.delayed;
      }
      return RemoteSnapshotFreshness.live;
    }
    if (age <= delayedWindow) {
      return RemoteSnapshotFreshness.delayed;
    }
    if (cloudConnected == false || internetConnected == false) {
      return RemoteSnapshotFreshness.offline;
    }
    return RemoteSnapshotFreshness.stale;
  }

  static DateTime? parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final raw = value.toInt();
      final milliseconds = raw.abs() < 100000000000 ? raw * 1000 : raw;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }
    final text = '$value'.trim();
    if (text.isEmpty) return null;
    final numeric = int.tryParse(text);
    if (numeric != null) return parseTimestamp(numeric);
    return DateTime.tryParse(text);
  }
}

/// Small state machine used by AUTO mode so one packet loss does not flap the
/// UI between local and cloud transports.
class HardwareTransportController {
  final int failureThreshold;
  final int recoveryThreshold;

  HardwareTransportKind _active = HardwareTransportKind.none;
  int _localFailures = 0;
  int _localRecoverySuccesses = 0;

  HardwareTransportController({
    this.failureThreshold = 2,
    this.recoveryThreshold = 2,
  });

  HardwareTransportKind get active => _active;

  void reset() {
    _active = HardwareTransportKind.none;
    _localFailures = 0;
    _localRecoverySuccesses = 0;
  }

  HardwareTransportKind select({
    required HardwareTransportMode mode,
    required bool localAvailable,
    required RemoteSnapshotFreshness remoteFreshness,
  }) {
    final remoteAvailable = remoteFreshness.usable;

    if (mode == HardwareTransportMode.local) {
      _active = HardwareTransportKind.local;
      _localFailures = 0;
      _localRecoverySuccesses = 0;
      return localAvailable
          ? HardwareTransportKind.local
          : HardwareTransportKind.none;
    }

    if (mode == HardwareTransportMode.remote) {
      _active = HardwareTransportKind.remote;
      _localFailures = 0;
      _localRecoverySuccesses = 0;
      return remoteAvailable
          ? HardwareTransportKind.remote
          : HardwareTransportKind.none;
    }

    if (_active == HardwareTransportKind.none) {
      if (localAvailable) {
        _active = HardwareTransportKind.local;
        return HardwareTransportKind.local;
      }
      if (remoteAvailable) {
        _active = HardwareTransportKind.remote;
        return HardwareTransportKind.remote;
      }
      return HardwareTransportKind.none;
    }

    if (_active == HardwareTransportKind.local) {
      if (localAvailable) {
        _localFailures = 0;
        return HardwareTransportKind.local;
      }
      _localFailures++;
      if (_localFailures >= failureThreshold && remoteAvailable) {
        _active = HardwareTransportKind.remote;
        _localFailures = 0;
        _localRecoverySuccesses = 0;
        return HardwareTransportKind.remote;
      }
      return HardwareTransportKind.none;
    }

    // Currently remote: require consecutive local successes before returning,
    // unless the remote state is no longer usable.
    if (localAvailable) {
      _localRecoverySuccesses++;
      if (_localRecoverySuccesses >= recoveryThreshold || !remoteAvailable) {
        _active = HardwareTransportKind.local;
        _localRecoverySuccesses = 0;
        _localFailures = 0;
        return HardwareTransportKind.local;
      }
    } else {
      _localRecoverySuccesses = 0;
    }

    return remoteAvailable
        ? HardwareTransportKind.remote
        : HardwareTransportKind.none;
  }
}
