enum AlertSeverity { info, warning, critical }

class PlantAlert {
  final String id;
  final String nodeId;
  final DateTime timestamp;
  final String titleKey;
  final String messageKey;
  final String? titleText;
  final String? messageText;
  final AlertSeverity severity;
  bool isRead;

  PlantAlert({
    required this.id,
    required this.nodeId,
    required this.timestamp,
    required this.titleKey,
    required this.messageKey,
    this.titleText,
    this.messageText,
    required this.severity,
    this.isRead = false,
  });
}
