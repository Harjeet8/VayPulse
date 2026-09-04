class SensorNode {
  final String id;
  final String name;
  final String farmId;
  final String fieldId;
  final String zoneId;
  final int batteryPercent;
  final int signalPercent;
  final DateTime lastSeen;
  final bool isOnline;

  const SensorNode({
    required this.id,
    required this.name,
    required this.farmId,
    required this.fieldId,
    required this.zoneId,
    required this.batteryPercent,
    required this.signalPercent,
    required this.lastSeen,
    required this.isOnline,
  });

  SensorNode copyWith({
    int? batteryPercent,
    int? signalPercent,
    DateTime? lastSeen,
    bool? isOnline,
  }) => SensorNode(
    id: id,
    name: name,
    farmId: farmId,
    fieldId: fieldId,
    zoneId: zoneId,
    batteryPercent: batteryPercent ?? this.batteryPercent,
    signalPercent: signalPercent ?? this.signalPercent,
    lastSeen: lastSeen ?? this.lastSeen,
    isOnline: isOnline ?? this.isOnline,
  );
}
