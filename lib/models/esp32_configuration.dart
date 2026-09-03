class Esp32Config {
  final String cropId;
  final String cropName;
  final String growthStage;
  final String baselineStatus;
  final List<String> supportedCrops;
  final List<String> supportedStages;
  final bool baselineReset;

  const Esp32Config({
    required this.cropId,
    required this.cropName,
    required this.growthStage,
    required this.baselineStatus,
    this.supportedCrops = const [],
    this.supportedStages = const [],
    this.baselineReset = false,
  });

  Esp32Config copyWith({
    String? cropId,
    String? cropName,
    String? growthStage,
    String? baselineStatus,
    List<String>? supportedCrops,
    List<String>? supportedStages,
    bool? baselineReset,
  }) =>
      Esp32Config(
        cropId: cropId ?? this.cropId,
        cropName: cropName ?? this.cropName,
        growthStage: growthStage ?? this.growthStage,
        baselineStatus: baselineStatus ?? this.baselineStatus,
        supportedCrops: supportedCrops ?? this.supportedCrops,
        supportedStages: supportedStages ?? this.supportedStages,
        baselineReset: baselineReset ?? this.baselineReset,
      );

  factory Esp32Config.fromJson(Map<String, dynamic> root) {
    final data = _map(root['data']).isNotEmpty ? _map(root['data']) : root;
    final crop = _map(data['crop']).isNotEmpty
        ? _map(data['crop'])
        : _map(data['cropProfile']);
    final baseline = _map(data['baseline']).isNotEmpty
        ? _map(data['baseline'])
        : _map(data['adaptiveBaseline']);

    final cropId = _text(_first([
          crop['id'],
          crop['cropId'],
          data['cropId'],
          data['crop'] is String ? data['crop'] : null,
          data['cropProfileName'],
        ])) ??
        'universal';
    final cropName = _text(_first([
          crop['name'],
          crop['label'],
          data['cropName'],
          data['cropProfileName'],
        ])) ??
        _displayCrop(cropId);

    return Esp32Config(
      cropId: _normalId(cropId),
      cropName: cropName,
      growthStage: _normalId(_text(_first([
            crop['stage'],
            crop['growthStage'],
            data['stage'],
            data['growthStage'],
          ])) ??
          'general'),
      baselineStatus: _text(_first([
            baseline['status'],
            baseline['state'],
            data['baselineStatus'],
            data['adaptiveBaselineStatus'],
          ])) ??
          'UNKNOWN',
      supportedCrops: _strings(_first([
        crop['availableCrops'],
        crop['supportedProfiles'],
        crop['supportedCrops'],
        data['availableCrops'],
        data['supportedCropProfiles'],
        data['supportedCrops'],
      ])),
      supportedStages: _strings(_first([
        crop['supportedStages'],
        data['supportedGrowthStages'],
        data['supportedStages'],
      ])),
      baselineReset: _bool(_first([
            data['baselineReset'],
            baseline['reset'],
          ])) ==
          true,
    );
  }
}

class Esp32Diagnostics {
  final String firmwareVersion;
  final int? uptimeSeconds;
  final int? freeHeapBytes;
  final String? wifiStatus;
  final int? wifiRssi;
  final String? ipAddress;
  final Map<String, bool> sensorAvailability;
  final Map<String, double> sensorConfidence;
  final Map<String, int> sensorAgeSeconds;
  final Map<String, int> sensorErrorCounts;
  final int? historySamples;
  final int? historyCapacity;
  final String? cropProfile;
  final String? growthStage;
  final String? baselineStatus;
  final String? analysisQuality;
  final bool degradedMode;
  final String? rtcStatus;
  final String tinyMlStatus;

  const Esp32Diagnostics({
    required this.firmwareVersion,
    this.uptimeSeconds,
    this.freeHeapBytes,
    this.wifiStatus,
    this.wifiRssi,
    this.ipAddress,
    this.sensorAvailability = const {},
    this.sensorConfidence = const {},
    this.sensorAgeSeconds = const {},
    this.sensorErrorCounts = const {},
    this.historySamples,
    this.historyCapacity,
    this.cropProfile,
    this.growthStage,
    this.baselineStatus,
    this.analysisQuality,
    this.degradedMode = false,
    this.rtcStatus,
    this.tinyMlStatus = 'Disabled · No trained model loaded',
  });

  factory Esp32Diagnostics.fromJson(Map<String, dynamic> root) {
    final data = _map(root['data']).isNotEmpty ? _map(root['data']) : root;
    final wifi = _map(data['wifi']).isNotEmpty ? _map(data['wifi']) : _map(data['network']);
    final history = _map(data['history']);
    final crop = _map(data['crop']).isNotEmpty ? _map(data['crop']) : _map(data['cropProfile']);
    final baseline = _map(data['baseline']).isNotEmpty ? _map(data['baseline']) : _map(data['adaptiveBaseline']);
    final quality = _map(data['analysisQuality']);
    final rtc = _map(data['rtc']);
    final tiny = _map(data['tinyMl']).isNotEmpty ? _map(data['tinyMl']) : _map(data['tinyML']);

    final availability = <String, bool>{};
    final availabilityRaw = _first([
      data['sensorAvailability'],
      data['sensorsAvailable'],
      _map(data['sensors'])['availability'],
    ]);
    if (availabilityRaw is Map) {
      for (final entry in availabilityRaw.entries) {
        final value = _bool(entry.value);
        if (value != null) availability['${entry.key}'] = value;
      }
    }

    final confidence = <String, double>{};
    final confidenceRaw = _first([
      data['sensorConfidence'],
      quality['sensorConfidence'],
    ]);
    if (confidenceRaw is Map) {
      for (final entry in confidenceRaw.entries) {
        final details = _map(entry.value);
        final value = _num(details.isEmpty
            ? entry.value
            : _first([details['confidence'], details['percent'], details['score']]));
        if (value != null) confidence['${entry.key}'] = value.clamp(0, 100).toDouble();
      }
    }

    final ages = <String, int>{};
    final ageRaw = _first([data['sensorAgeSeconds'], data['sensorAges']]);
    if (ageRaw is Map) {
      for (final entry in ageRaw.entries) {
        final value = _int(entry.value);
        if (value != null) ages['${entry.key}'] = value;
      }
    }

    final errors = <String, int>{};
    final errorRaw = _first([data['sensorErrorCounts'], data['sensorErrors']]);
    if (errorRaw is Map) {
      for (final entry in errorRaw.entries) {
        final value = _int(entry.value);
        if (value != null) errors['${entry.key}'] = value;
      }
    }

    final tinyExplicit = _text(_first([
      tiny['status'],
      data['tinyMlStatus'],
      data['tinyMLStatus'],
    ]));
    final modelLoaded = _bool(_first([
      tiny['modelLoaded'],
      data['tinyMlModelLoaded'],
    ])) ==
        true;
    final tinyStatus = modelLoaded
        ? (tinyExplicit ?? 'Model loaded')
        : 'Disabled · No trained model loaded';

    return Esp32Diagnostics(
      firmwareVersion: _text(_first([
            data['firmware'],
            data['firmwareVersion'],
            root['firmware'],
            root['firmwareVersion'],
          ])) ??
          'Unknown',
      uptimeSeconds: _int(_first([data['uptimeSeconds'], data['uptimeSec'], data['uptime']])),
      freeHeapBytes: _int(_first([data['freeHeap'], data['freeHeapBytes'], data['heapFree']])),
      wifiStatus: _text(_first([wifi['status'], data['wifiStatus'], data['networkStatus']])),
      wifiRssi: _int(_first([wifi['rssi'], data['wifiRssi'], data['rssi']])),
      ipAddress: _text(_first([wifi['ip'], wifi['ipAddress'], data['ip'], data['ipAddress']])),
      sensorAvailability: availability,
      sensorConfidence: confidence,
      sensorAgeSeconds: ages,
      sensorErrorCounts: errors,
      historySamples: _int(_first([history['samples'], history['fill'], data['historySamples']])),
      historyCapacity: _int(_first([history['capacity'], data['historyCapacity']])),
      cropProfile: _text(_first([crop['name'], crop['id'], data['cropProfileName']])),
      growthStage: _text(_first([crop['stage'], crop['growthStage'], data['growthStage']])),
      baselineStatus: _text(_first([baseline['status'], data['baselineStatus']])),
      analysisQuality: _text(_first([quality['level'], quality['label'], data['analysisQualityLevel']])),
      degradedMode: _bool(_first([quality['degraded'], data['degradedMode'], data['degradedAnalysis']])) == true,
      rtcStatus: _text(_first([rtc['status'], data['rtcStatus']])),
      tinyMlStatus: tinyStatus,
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

dynamic _first(List<dynamic> values) {
  for (final value in values) {
    if (value != null) return value;
  }
  return null;
}

String? _text(dynamic value) {
  if (value == null || value is Map || value is List) return null;
  final text = '$value'.trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

double? _num(dynamic value) {
  if (value == null || value is bool) return null;
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  return parsed?.isFinite == true ? parsed : null;
}

int? _int(dynamic value) {
  if (value == null || value is bool) return null;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

bool? _bool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = _text(value)?.toLowerCase();
  if (text == 'true' || text == 'yes' || text == '1' || text == 'online' || text == 'ready') return true;
  if (text == 'false' || text == 'no' || text == '0' || text == 'offline') return false;
  return null;
}

List<String> _strings(dynamic value) {
  if (value is List) {
    return value.map(_text).whereType<String>().map(_normalId).toList(growable: false);
  }
  return const [];
}

String _normalId(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

String _displayCrop(String id) {
  final normalized = _normalId(id);
  if (normalized.isEmpty) return 'Universal';
  return normalized
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
