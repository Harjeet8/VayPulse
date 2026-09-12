import 'package:flutter/material.dart';
import '../services/app_scope.dart';
import '../services/care_journal.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../services/voice_guidance_service.dart';
import '../screens/care_journal_screen.dart';

class CareActions extends StatefulWidget {
  final String condition, problem, action, plant, source;
  final DateTime timestamp;
  final bool compact;
  const CareActions(
      {super.key,
      required this.condition,
      required this.problem,
      required this.action,
      required this.plant,
      required this.source,
      required this.timestamp,
      this.compact = false});
  @override
  State<CareActions> createState() => _CareActionsState();
}

class _CareActionsState extends State<CareActions> {
  bool _busy = false;
  VoiceGuidanceService? _voice;
  SensorDataProvider? _sensors;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    if (_sensors != scope.sensors) {
      _sensors?.removeListener(_connectionChanged);
      _sensors = scope.sensors;
      _sensors!.addListener(_connectionChanged);
    }
    _voice = scope.voice;
  }

  void _connectionChanged() {
    final sensors = _sensors;
    if (sensors == null) return;
    if (sensors.source == SensorDataSource.esp32 &&
        sensors.connectionStatus != SensorConnectionStatus.ready) {
      if (_voice?.speaking == true) _voice!.stop();
    }
  }

  @override
  void dispose() {
    _sensors?.removeListener(_connectionChanged);
    final voice = _voice;
    if (_busy && voice != null) Future.microtask(voice.stop);
    super.dispose();
  }

  bool get _tamil => FarmerLanguage.isTamil(context);
  String get _script => _tamil
      ? '${widget.source == 'simulation' ? 'இது பயிற்சி தரவு. ' : ''}${widget.condition}. பிரச்சினை: ${widget.problem} இப்போது செய்ய வேண்டியது: ${widget.action}'
      : '${widget.source == 'simulation' ? 'This is simulation practice. ' : ''}${widget.condition}. Here is the problem. ${widget.problem} Here is what to do now. ${widget.action}';
  Future<void> _listen() async {
    final scope = AppScope.of(context);
    final voice = scope.voice;
    if (voice.speaking) {
      await voice.stop();
      return;
    }
    // Re-check source and connection at tap time, not just when rendered.
    final hardware = scope.sensors.source == SensorDataSource.esp32;
    if ((hardware &&
            scope.sensors.connectionStatus != SensorConnectionStatus.ready) ||
        hardware != (widget.source == 'hardware')) return;
    setState(() => _busy = true);
    final ok = await voice.speak(
        text: _script, languageCode: scope.settings.value.languageCode);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_tamil
              ? 'குரல் கிடைக்கவில்லை. கீழே உள்ள ஆலோசனையைப் படிக்கவும்.'
              : 'Voice is unavailable. You can read the advice on screen.')));
  }

  @override
  Widget build(BuildContext context) {
    final voice = AppScope.of(context).voice;
    return AnimatedBuilder(
        animation: voice,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              FilledButton.icon(
                  onPressed: _listen,
                  icon: Icon(voice.speaking
                      ? Icons.stop_rounded
                      : Icons.volume_up_rounded),
                  label: Text(voice.speaking
                      ? (_tamil ? 'நிறுத்து' : 'Stop voice')
                      : _busy
                          ? (_tamil ? 'தயாராகிறது…' : 'Preparing voice…')
                          : (_tamil
                              ? 'ஆலோசனையைக் கேளுங்கள்'
                              : 'Listen to advice'))),
              const SizedBox(height: 4),
              Text(voice.statusLabel(tamil: _tamil),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              if (!widget.compact) ...[
                const SizedBox(height: 8),
                Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CareJournalScreen())),
                          icon: const Icon(Icons.edit_note_rounded),
                          label:
                              Text(_tamil ? 'பராமரிப்பு பதிவு' : 'Care diary')),
                      TextButton.icon(
                          onPressed: () async {
                            final sensors = AppScope.of(context).sensors;
                            if (widget.source == 'hardware' &&
                                sensors.connectionStatus !=
                                    SensorConnectionStatus.ready) return;
                            try {
                              await CareJournal.share(
                                  'PhytoSense AI\n${widget.plant}\n${widget.source.toUpperCase()} · ${widget.timestamp.toLocal()}\n$_script');
                            } catch (_) {
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Could not open sharing.')));
                            }
                          },
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(_tamil ? 'பகிர்' : 'Share report')),
                    ]),
              ],
            ]));
  }
}
