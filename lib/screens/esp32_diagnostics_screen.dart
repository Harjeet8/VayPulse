import 'package:flutter/material.dart';

import '../models/esp32_configuration.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';

class Esp32DiagnosticsScreen extends StatefulWidget {
  const Esp32DiagnosticsScreen({super.key});

  @override
  State<Esp32DiagnosticsScreen> createState() => _Esp32DiagnosticsScreenState();
}

class _Esp32DiagnosticsScreenState extends State<Esp32DiagnosticsScreen> {
  Esp32Diagnostics? _diagnostics;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final result = await AppScope.of(context).sensors.fetchHardwareDiagnostics();
    if (!mounted) return;
    setState(() {
      _diagnostics = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final d = _diagnostics;
    return Scaffold(
      appBar: AppBar(
        title: Text(tamil ? 'System Diagnostics' : 'System Diagnostics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            tamil
                ? 'ESP32 மற்றும் physical sensors-ன் தொழில்நுட்ப நிலை.'
                : 'Technical status reported by the ESP32 and physical sensors.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: LinearProgressIndicator(),
              ),
            )
          else if (d == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  tamil
                      ? '/api/diagnostics response கிடைக்கவில்லை. ESP32 இணைப்பு அல்லது firmware endpoint-ஐ சரிபார்க்கவும்.'
                      : 'No /api/diagnostics response was available. Check the ESP32 connection or firmware endpoint.',
                ),
              ),
            )
          else ...[
            _Group(
              title: tamil ? 'ESP32' : 'ESP32',
              children: [
                _Row('Firmware version', d.firmwareVersion),
                _Row('Uptime', _uptime(d.uptimeSeconds)),
                _Row('Free heap', _bytes(d.freeHeapBytes)),
                _Row('Wi-Fi status', d.wifiStatus ?? 'Unavailable'),
                _Row('Wi-Fi RSSI', d.wifiRssi == null ? 'Unavailable' : '${d.wifiRssi} dBm'),
                _Row('IP address', d.ipAddress ?? 'Unavailable'),
                _Row('RTC status', d.rtcStatus ?? 'Unavailable'),
              ],
            ),
            const SizedBox(height: 12),
            _Group(
              title: tamil ? 'Plant Intelligence' : 'Plant Intelligence',
              children: [
                _Row('Crop profile', d.cropProfile ?? 'Unavailable'),
                _Row('Growth stage', d.growthStage ?? 'Unavailable'),
                _Row('Baseline status', d.baselineStatus ?? 'Unavailable'),
                _Row('Analysis quality', d.analysisQuality ?? 'Unavailable'),
                _Row('Degraded mode', d.degradedMode ? 'Active' : 'Not active'),
                _Row('History buffer', _history(d.historySamples, d.historyCapacity)),
                _Row('TinyML', d.tinyMlStatus),
              ],
            ),
            const SizedBox(height: 12),
            _SensorDiagnostics(diagnostics: d),
          ],
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );
}

class _SensorDiagnostics extends StatelessWidget {
  final Esp32Diagnostics diagnostics;

  const _SensorDiagnostics({required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    final names = <String>{
      ...diagnostics.sensorAvailability.keys,
      ...diagnostics.sensorConfidence.keys,
      ...diagnostics.sensorAgeSeconds.keys,
      ...diagnostics.sensorErrorCounts.keys,
    }.toList()
      ..sort();

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.sensors_rounded),
        title: const Text('Sensor diagnostics',
            style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(names.isEmpty
            ? 'No per-sensor diagnostics reported'
            : '${names.length} channels reported'),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        children: names.isEmpty
            ? const [Text('Firmware did not expose per-sensor diagnostics.')]
            : names.map((name) {
                final available = diagnostics.sensorAvailability[name];
                final confidence = diagnostics.sensorConfidence[name];
                final age = diagnostics.sensorAgeSeconds[name];
                final errors = diagnostics.sensorErrorCounts[name];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_pretty(name),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (available != null)
                            Text(available ? 'Available' : 'Unavailable'),
                          if (confidence != null)
                            Text('Confidence ${confidence.round()}%'),
                          if (age != null) Text('Age ${age}s'),
                          if (errors != null) Text('Errors $errors'),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(growable: false),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

String _uptime(int? seconds) {
  if (seconds == null) return 'Unavailable';
  final d = Duration(seconds: seconds);
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours.remainder(24)}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
}

String _bytes(int? value) {
  if (value == null) return 'Unavailable';
  if (value >= 1024 * 1024) return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
  return '$value B';
}

String _history(int? samples, int? capacity) {
  if (samples == null && capacity == null) return 'Unavailable';
  if (samples != null && capacity != null) return '$samples / $capacity samples';
  return '${samples ?? capacity} samples';
}

String _pretty(String value) {
  final spaced = value
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}')
      .trim();
  if (spaced.isEmpty) return value;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
