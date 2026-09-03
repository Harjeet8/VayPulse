import 'package:flutter/material.dart';

import '../models/esp32_configuration.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';

class PlantIntelligenceSettingsScreen extends StatefulWidget {
  const PlantIntelligenceSettingsScreen({super.key});

  @override
  State<PlantIntelligenceSettingsScreen> createState() =>
      _PlantIntelligenceSettingsScreenState();
}

class _PlantIntelligenceSettingsScreenState
    extends State<PlantIntelligenceSettingsScreen> {
  static const _crops = <String, String>{
    'universal': 'Universal',
    'tomato': 'Tomato',
    'hibiscus': 'Hibiscus',
    'rice': 'Rice',
    'sugarcane': 'Sugarcane',
    'banana': 'Banana',
    'papaya': 'Papaya',
    'eggplant': 'Eggplant',
    'okra': 'Okra',
    'maize': 'Maize',
    'groundnut': 'Groundnut',
  };

  static const _stages = <String, String>{
    'general': 'General',
    'young': 'Young',
    'vegetative': 'Vegetative',
    'flowering': 'Flowering',
    'fruiting': 'Fruiting',
    'mature': 'Mature',
  };

  Esp32Config? _config;
  bool _loading = true;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final sensors = AppScope.of(context).sensors;
    setState(() {
      _loading = true;
      _message = null;
    });
    final config = await sensors.fetchHardwareConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _loading = false;
      if (config == null) {
        _message = FarmerLanguage.isTamil(context)
            ? 'ESP32 configuration கிடைக்கவில்லை. இணைப்பை சரிபார்க்கவும்.'
            : 'ESP32 configuration is unavailable. Check the connection.';
      }
    });
  }

  Future<void> _setCrop(String? cropId) async {
    if (cropId == null || _saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    final confirmed = await AppScope.of(context).sensors.setCropProfile(cropId);
    if (!mounted) return;
    setState(() {
      _config = confirmed ?? _config;
      _saving = false;
      _message = confirmed == null
          ? (FarmerLanguage.isTamil(context)
              ? 'CROP PROFILE ஒத்திசைக்கப்படவில்லை. PhytoSense node-ஐ மீண்டும் இணைத்து முயற்சிக்கவும்.'
              : 'CROP PROFILE NOT SYNCED. Reconnect to the PhytoSense node and try again.')
          : (FarmerLanguage.isTamil(context)
              ? 'Active crop: ${confirmed.cropName}'
              : 'Active Crop: ${confirmed.cropName}');
    });
  }

  Future<void> _setStage(String? stageId) async {
    if (stageId == null || _saving) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    final confirmed =
        await AppScope.of(context).sensors.setGrowthStage(stageId);
    if (!mounted) return;
    setState(() {
      _config = confirmed ?? _config;
      _saving = false;
      _message = confirmed == null
          ? (FarmerLanguage.isTamil(context)
              ? 'Growth stage மாற்றத்தை ESP32 உறுதிப்படுத்தவில்லை.'
              : 'The ESP32 did not confirm the growth-stage change.')
          : (FarmerLanguage.isTamil(context)
              ? 'வளர்ச்சி நிலை: ${_stages[confirmed.growthStage] ?? confirmed.growthStage}'
              : 'Growth Stage: ${_stages[confirmed.growthStage] ?? confirmed.growthStage}');
    });
  }

  Future<void> _resetBaseline() async {
    final sensors = AppScope.of(context).sensors;
    final tamil = FarmerLanguage.isTamil(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tamil ? 'Baseline reset செய்யவா?' : 'Reset adaptive baseline?'),
        content: Text(
          tamil
              ? 'செடியின் கற்ற மின்சார baseline மறுபடியும் ஆரம்பிக்கும். புதிய normal pattern கற்க சிறிது நேரம் தேவைப்படும்.'
              : 'This restarts learning of the plant’s electrical baseline. The node will need time to learn a new normal pattern.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tamil ? 'ரத்து' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tamil ? 'Reset' : 'Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    final result = await sensors.resetAdaptiveBaseline();
    if (!mounted) return;
    setState(() {
      _config = result ?? _config;
      _saving = false;
      _message = result == null
          ? (tamil
              ? 'Baseline reset-ஐ ESP32 உறுதிப்படுத்தவில்லை.'
              : 'The ESP32 did not confirm the baseline reset.')
          : (tamil
              ? 'Baseline learning மீண்டும் தொடங்கியது.'
              : 'Baseline learning restarted.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    final tamil = FarmerLanguage.isTamil(context);
    final live = sensors.source == SensorDataSource.esp32;
    final edge = sensors.edgeIntelligence;
    final cropId = _config?.cropId ??
        _normalId(edge?.cropProfile.profile) ??
        'universal';
    final stageId = _config?.growthStage ??
        _normalId(edge?.cropProfile.growthStage) ??
        'general';
    final baselineStatus = _config?.baselineStatus ??
        edge?.baseline.status ??
        (edge?.baseline.ready == true ? 'READY' : 'UNKNOWN');

    return Scaffold(
      appBar: AppBar(
        title: Text(tamil ? 'Plant Intelligence' : 'Plant Intelligence'),
        actions: [
          IconButton(
            tooltip: tamil ? 'Refresh' : 'Refresh',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (!live)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  tamil
                      ? 'இந்த அமைப்புகள் ESP32 Live mode-ல் மட்டுமே மாற்றப்படும்.'
                      : 'These settings are changed on the ESP32 only in Live mode.',
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tamil ? 'Plant Intelligence' : 'Plant Intelligence',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tamil
                        ? 'Crop selection சென்சார் node வெப்பநிலை, மண் ஈரம், humidity, root-zone மற்றும் environmental stress-ஐ எப்படி விளக்குகிறது என்பதை மாற்றுகிறது.'
                        : 'Crop selection changes how the sensor node interprets temperature, moisture, humidity, root-zone conditions and environmental stress.',
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const LinearProgressIndicator()
                  else ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('crop-$cropId'),
                      initialValue: _crops.containsKey(cropId) ? cropId : 'universal',
                      decoration: InputDecoration(
                        labelText: tamil ? 'Crop Profile' : 'Crop Profile',
                        prefixIcon: const Icon(Icons.eco_outlined),
                      ),
                      items: _crops.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: live && !_saving ? _setCrop : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey('stage-$stageId'),
                      initialValue: _stages.containsKey(stageId) ? stageId : 'general',
                      decoration: InputDecoration(
                        labelText: tamil ? 'Growth Stage' : 'Growth Stage',
                        prefixIcon: const Icon(Icons.timeline_rounded),
                      ),
                      items: _stages.entries
                          .map(
                            (entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: live && !_saving ? _setStage : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded),
                  title: Text(tamil ? 'Active Crop' : 'Active Crop'),
                  subtitle: Text(_crops[cropId] ?? _config?.cropName ?? 'Universal'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(tamil ? 'Growth Stage' : 'Growth Stage'),
                  subtitle: Text(_stages[stageId] ?? stageId),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: Text(tamil ? 'Adaptive Baseline' : 'Adaptive Baseline'),
                  subtitle: Text(FarmerLanguage.firmware(context, baselineStatus)),
                  trailing: TextButton(
                    onPressed: live && !_saving ? _resetBaseline : null,
                    child: Text(tamil ? 'Reset' : 'Reset'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.memory_rounded),
                  title: Text(tamil ? 'Analysis Mode' : 'Analysis Mode'),
                  subtitle: const Text('ESP32 Edge Intelligence'),
                ),
              ],
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_message!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String? _normalId(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
