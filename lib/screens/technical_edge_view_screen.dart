import 'package:flutter/material.dart';

import '../models/edge_intelligence.dart';
import '../models/sensor_reading.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';

class TechnicalEdgeViewScreen extends StatelessWidget {
  const TechnicalEdgeViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensors = AppScope.of(context).sensors;
    return AnimatedBuilder(
      animation: sensors,
      builder: (context, _) {
        final edge = sensors.edgeIntelligence;
        final reading = sensors.current;
        return Scaffold(
          appBar: AppBar(title: Text(FarmerLanguage.label(context, 'technical_judge_view'))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            children: [
              _Hero(edge: edge),
              const SizedBox(height: 12),
              _Bio(edge: edge),
              const SizedBox(height: 12),
              _Environment(edge: edge, reading: reading),
              const SizedBox(height: 12),
              _Causes(edge: edge),
              const SizedBox(height: 12),
              _SensorConfidence(edge: edge),
              const SizedBox(height: 12),
              _Events(edge: edge),
            ],
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final EdgeIntelligence? edge;
  const _Hero({required this.edge});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PHYTOSENSE EDGE INTELLIGENCE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
            const SizedBox(height: 10),
            _row('Firmware', edge?.firmwareVersion ?? 'Unavailable'),
            _row('Active crop', edge?.cropProfile.profile ?? 'Universal'),
            if (edge?.cropProfile.regionProfile != null) _row('Region profile', edge!.cropProfile.regionProfile!),
            if (edge?.cropProfile.growthStage != null) _row('Growth stage', edge!.cropProfile.growthStage!),
            _row('Health Index', edge?.healthScore == null ? 'Unavailable' : '${edge!.healthScore!.round()} / 100'),
            _row('Plant State', edge?.plantState ?? 'Unavailable'),
            _row('Priority', edge?.urgency ?? 'Unavailable'),
            _row('Analysis quality', edge?.analysisQuality ?? 'Unavailable'),
            _row('Fusion confidence', edge?.overallConfidence == null ? 'Unavailable' : '${edge!.overallConfidence!.round()}%'),
          ]),
        ),
      );
}

class _Bio extends StatelessWidget {
  final EdgeIntelligence? edge;
  const _Bio({required this.edge});
  @override
  Widget build(BuildContext context) {
    final b = edge?.bioelectric;
    return _section('Bioelectric intelligence', [
      _row('Bio state', b?.stressState ?? 'Unavailable'),
      _row('Bio Stress Score', b?.stressScore == null ? 'Unavailable' : '${b!.stressScore!.round()} / 100'),
      _row('Baseline', b?.baselineMv == null ? 'Unavailable' : '${b!.baselineMv!.toStringAsFixed(1)} mV'),
      _row('Current electrical value', b?.voltageMv == null ? 'Unavailable' : '${b!.voltageMv!.toStringAsFixed(1)} mV'),
      _row('Signed deviation', b?.signedChangeMv == null ? 'Unavailable' : '${b!.signedChangeMv!.toStringAsFixed(1)} mV'),
      _row('Z-score', b?.zScore == null ? 'Unavailable' : b!.zScore!.toStringAsFixed(2)),
      _row('MAD / robust noise', b?.noiseMv == null ? 'Unavailable' : '${b!.noiseMv!.toStringAsFixed(1)} mV'),
      _row('Signal span', b?.spanMv == null ? 'Unavailable' : '${b!.spanMv!.toStringAsFixed(1)} mV'),
      _row('Signal quality', b?.signalQuality == null ? (b?.signalQualityState ?? 'Unavailable') : '${b!.signalQuality!.round()}% ${b.signalQualityState ?? ''}'),
      _row('Bio confidence', b?.confidence == null ? 'Unavailable' : '${b!.confidence!.round()}%'),
      _row('Persistence', b?.persistenceSeconds == null ? 'Unavailable' : '${b!.persistenceSeconds!.round()} sec'),
      _row('Baseline progress', b?.baselineSamples == null ? 'Unavailable' : '${b!.baselineSamples}${b.baselineTarget == null ? '' : '/${b.baselineTarget}'}'),
      _row('Included in fusion', b?.includedInFusion == null ? 'Unavailable' : b!.includedInFusion! ? 'YES' : 'NO'),
      _row('Interpretation', b?.interpretation ?? b?.farmerResult ?? 'Unavailable'),
      _row('Raw ADC GPIO33', b?.rawAdc == null ? 'Unavailable' : b!.rawAdc!.round().toString()),
    ]);
  }
}

class _Environment extends StatelessWidget {
  final EdgeIntelligence? edge;
  final SensorReading? reading;
  const _Environment({required this.edge, required this.reading});
  @override
  Widget build(BuildContext context) => _section('Environmental + root-zone context', [
        _row('Air temperature', reading?.temperatureAvailable == true ? '${reading!.temperature.toStringAsFixed(1)} °C' : 'Unavailable'),
        _row('Humidity', reading?.humidityAvailable == true ? '${reading!.humidity.toStringAsFixed(0)} %' : 'Unavailable'),
        _row('VPD', edge?.derivedEnvironment.vpdValid == false || edge?.derivedEnvironment.vpdKpa == null ? 'Unavailable' : '${edge!.derivedEnvironment.vpdKpa!.toStringAsFixed(2)} kPa'),
        _row('Drying state', edge?.derivedEnvironment.dryingDemandState ?? edge?.derivedEnvironment.vpdState ?? 'Unavailable'),
        _row('Soil moisture', reading?.soilMoistureAvailable == true ? '${reading!.soilMoisture.toStringAsFixed(0)} %' : 'Unavailable'),
        _row('Water balance', edge?.waterBalance.score == null ? (edge?.waterBalance.state ?? 'Unavailable') : '${edge!.waterBalance.score!.round()} / 100 ${edge!.waterBalance.state ?? ''}'),
        _row('Root temperature', reading?.soilTemperatureAvailable == true && reading?.soilTemperature != null ? '${reading!.soilTemperature!.toStringAsFixed(1)} °C' : 'Unavailable'),
        _row('Disease-conducive risk', edge?.diseaseRiskScore == null ? (edge?.diseaseRiskLevel ?? 'Unavailable') : '${edge!.diseaseRiskScore!.round()} / 100 ${edge!.diseaseRiskLevel ?? ''}'),
        _row('Biotic state', edge?.bioticStress.normalizedState ?? 'Unavailable'),
        _row('Biotic evidence', edge?.bioticStress.evidenceScore == null ? 'Unavailable' : '${edge!.bioticStress.evidenceScore!.round()}%'),
        _row('Camera handoff', edge?.cameraInspectionRecommended == true ? 'RECOMMENDED' : 'Not recommended'),
        _row('Recovery', edge?.recovery.state ?? (edge?.recovery.active == true ? 'RECOVERING' : 'NONE')),
      ]);
}

class _Causes extends StatelessWidget {
  final EdgeIntelligence? edge;
  const _Causes({required this.edge});
  @override
  Widget build(BuildContext context) {
    final causes = edge?.rootCause.ranked ?? const <RootCauseCandidate>[];
    return _section('Ranked root cause', [
      if (causes.isEmpty) _row('Primary', edge?.rootCause.primary ?? 'Unavailable'),
      for (var i = 0; i < causes.length && i < 3; i++)
        _row('#${i + 1}', '${causes[i].name ?? 'Unknown'}${causes[i].confidence == null ? '' : ' — ${causes[i].confidence!.round()}%'}'),
      if (edge?.rootCause.primaryCandidate?.evidenceFor != null) _row('Evidence for', edge!.rootCause.primaryCandidate!.evidenceFor!),
      if (edge?.rootCause.primaryCandidate?.evidenceAgainst != null) _row('Evidence against', edge!.rootCause.primaryCandidate!.evidenceAgainst!),
    ]);
  }
}

class _SensorConfidence extends StatelessWidget {
  final EdgeIntelligence? edge;
  const _SensorConfidence({required this.edge});
  @override
  Widget build(BuildContext context) => _section('Sensor confidence', [
        if (edge?.sensorConfidence.isEmpty != false) _row('Status', 'No per-sensor confidence supplied'),
        for (final item in edge?.sensorConfidence ?? const <SensorConfidence>[])
          _row(item.channel, '${item.percent?.round() ?? 0}% ${item.state ?? edge?.sensorStatus[item.channel] ?? ''}'),
      ]);
}

class _Events extends StatelessWidget {
  final EdgeIntelligence? edge;
  const _Events({required this.edge});
  @override
  Widget build(BuildContext context) {
    final events = edge?.recentEvents ?? const <PhytoEvent>[];
    return _section('Event timeline', [
      if (events.isEmpty) _row('Events', 'No recent ESP32 events'),
      for (final e in events.take(12))
        _row(e.timestamp == null ? e.type : _time(e.timestamp!), e.message),
    ]);
  }
}

Widget _section(String title, List<Widget> children) => Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 9),
          ...children,
        ]),
      ),
    );

Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 4, child: Text(label)),
        const SizedBox(width: 10),
        Expanded(flex: 6, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
    );

String _time(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
}
