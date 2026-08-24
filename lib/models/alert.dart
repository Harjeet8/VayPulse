enum AlertSeverity { info, warning, critical }

class PlantAlert {
  final String id;
  final String nodeId;
  final DateTime timestamp;
  final String titleKey;
  final String messageKey;
  final AlertSeverity severity;
  bool isRead;

  PlantAlert({
    required this.id,
    required this.nodeId,
    required this.timestamp,
    required this.titleKey,
    required this.messageKey,
    required this.severity,
    this.isRead = false,
  });
}
