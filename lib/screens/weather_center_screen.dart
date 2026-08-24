import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/weather_snapshot.dart';
import '../services/app_scope.dart';
import '../widgets/page_frame.dart';

class WeatherCenterScreen extends StatelessWidget {
  const WeatherCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: scope.weather,
      builder: (context, _) {
        final snapshot = scope.weather.snapshot;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('weather_center')),
            actions: [
              IconButton(
                tooltip: context.tr('change_weather_location'),
                onPressed: () => _showLocationEditor(context),
                icon: const Icon(Icons.location_on_outlined),
              ),
              IconButton(
                tooltip: context.tr('refresh_weather'),
                onPressed: scope.weather.loading ? null : scope.weather.refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: PageFrame(
            children: [
              if (snapshot == null)
                _WeatherUnavailable(loading: scope.weather.loading)
              else ...[
                _WeatherHero(snapshot: snapshot),
                const SizedBox(height: 14),
                if (scope.weather.usingCachedData)
                  _StatusBanner(
                    icon: Icons.offline_bolt_outlined,
                    message: context.tr('weather_cached'),
                    color: phytoAmber,
                  ),
                if (scope.weather.usingCachedData) const SizedBox(height: 12),
                if (!scope.weather.isFresh)
                  _StatusBanner(
                    icon: Icons.history_toggle_off_rounded,
                    message: context.tr('weather_stale'),
                    color: phytoTerracotta,
                  )
                else
                  _RiskSummary(snapshot: snapshot),
                const SizedBox(height: 18),
                Text(
                  context.tr('five_day_forecast'),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < snapshot.forecast.length;
                          index++) ...[
                        _ForecastRow(day: snapshot.forecast[index]),
                        if (index < snapshot.forecast.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  color: phytoGreen.withValues(alpha: 0.06),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            color: phytoGreen),
                        const SizedBox(width: 10),
                        Expanded(child: Text(context.tr('weather_alert_note'))),
                        IconButton(
                          tooltip: context.tr('listen_guidance'),
                          onPressed: () => _speak(context, snapshot),
                          icon: const Icon(Icons.volume_up_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    context.tr('weather_attribution'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _speak(
    BuildContext context,
    WeatherSnapshot snapshot,
  ) async {
    final scope = AppScope.of(context);
    final risk = !scope.weather.isFresh
        ? context.tr('weather_stale')
        : snapshot.heavyRainRisk
            ? context.tr('weather_risk_heavy_rain_body')
            : snapshot.diseaseRisk
                ? context.tr('weather_risk_disease_body')
                : snapshot.drySpellRisk
                    ? context.tr('weather_risk_dry_body')
                    : context.tr('weather_risk_clear_body');
    final spoken = await scope.voice.speak(
      text:
          '${context.tr('weather_center')}. ${snapshot.temperature.round()} ${context.tr('degrees_celsius')}. $risk',
      languageCode: scope.settings.value.languageCode,
    );
    if (!spoken && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('voice_unavailable'))),
      );
    }
  }

  Future<void> _showLocationEditor(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _WeatherLocationSheet(),
    );
  }
}

class _WeatherLocationSheet extends StatefulWidget {
  const _WeatherLocationSheet();

  @override
  State<_WeatherLocationSheet> createState() => _WeatherLocationSheetState();
}

class _WeatherLocationSheetState extends State<_WeatherLocationSheet> {
  final nameController = TextEditingController();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  bool initialized = false;
  String? error;
  bool saving = false;
  bool locating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final weather = AppScope.of(context).weather;
    nameController.text = weather.location;
    latitudeController.text = weather.latitude.toStringAsFixed(4);
    longitudeController.text = weather.longitude.toStringAsFixed(4);
    initialized = true;
  }

  @override
  void dispose() {
    nameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final latitude = double.tryParse(latitudeController.text.trim());
    final longitude = double.tryParse(longitudeController.text.trim());
    final name = nameController.text.trim();
    if (name.isEmpty ||
        latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      setState(() => error = context.tr('weather_location_invalid'));
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    await AppScope.of(context).weather.configureLocation(
          name: name,
          latitude: latitude,
          longitude: longitude,
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _usePhoneLocation() async {
    setState(() {
      locating = true;
      error = null;
    });
    final weather = AppScope.of(context).weather;
    final success = await weather.useDeviceLocation();
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      locating = false;
      error = context.tr(weather.locationErrorKey ?? 'location_unavailable');
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('weather_location_title'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(context.tr('weather_location_body')),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving || locating ? null : _usePhoneLocation,
                icon: locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(context.tr(
                  locating ? 'detecting_location' : 'use_phone_location',
                )),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('phone_location_privacy'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(context.tr('or_enter_manually')),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: context.tr('weather_location_name'),
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('latitude'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.tr('longitude'),
                    ),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: phytoTerracotta)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving || locating ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(context.tr(
                  saving ? 'loading_weather' : 'save_weather_location',
                )),
              ),
            ),
          ],
        ),
      );
}

class _WeatherUnavailable extends StatelessWidget {
  final bool loading;

  const _WeatherUnavailable({required this.loading});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            children: [
              if (loading)
                const CircularProgressIndicator()
              else
                const Icon(Icons.cloud_off_outlined, size: 46),
              const SizedBox(height: 14),
              Text(context
                  .tr(loading ? 'loading_weather' : 'weather_unavailable')),
              if (!loading) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: AppScope.of(context).weather.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('retry')),
                ),
              ],
            ],
          ),
        ),
      );
}

class _WeatherHero extends StatelessWidget {
  final WeatherSnapshot snapshot;

  const _WeatherHero({required this.snapshot});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF236FA8), Color(0xFF51A3C9)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Icon(_weatherIcon(snapshot.weatherCode),
                color: Colors.white, size: 58),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.location,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${snapshot.temperature.round()}°C',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    '${context.tr('humidity')} ${snapshot.humidity.round()}% • ${context.tr('wind')} ${snapshot.windSpeed.round()} km/h',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _RiskSummary extends StatelessWidget {
  final WeatherSnapshot snapshot;

  const _RiskSummary({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final risks = <Widget>[];
    if (snapshot.heavyRainRisk) {
      risks.add(_RiskCard(
        icon: Icons.thunderstorm_outlined,
        title: context.tr('weather_risk_heavy_rain'),
        body: context.tr('weather_risk_heavy_rain_body'),
        color: const Color(0xFF2775B6),
      ));
    }
    if (snapshot.diseaseRisk) {
      risks.add(_RiskCard(
        icon: Icons.coronavirus_outlined,
        title: context.tr('weather_risk_disease'),
        body: context.tr('weather_risk_disease_body'),
        color: phytoAmber,
      ));
    }
    if (snapshot.drySpellRisk) {
      risks.add(_RiskCard(
        icon: Icons.wb_sunny_outlined,
        title: context.tr('weather_risk_dry'),
        body: context.tr('weather_risk_dry_body'),
        color: phytoTerracotta,
      ));
    }
    if (risks.isEmpty) {
      risks.add(_RiskCard(
        icon: Icons.check_circle_outline_rounded,
        title: context.tr('weather_risk_clear'),
        body: context.tr('weather_risk_clear_body'),
        color: phytoLeaf,
      ));
    }
    return Column(children: [
      for (var index = 0; index < risks.length; index++) ...[
        risks[index],
        if (index < risks.length - 1) const SizedBox(height: 9),
      ],
    ]);
  }
}

class _RiskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _RiskCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Card(
        color: color.withValues(alpha: 0.06),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          leading: Icon(icon, color: color),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text(body),
        ),
      );
}

class _ForecastRow extends StatelessWidget {
  final WeatherDay day;

  const _ForecastRow({required this.day});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                context.tr('weekday_${day.date.weekday}'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Icon(_weatherIcon(day.weatherCode), color: const Color(0xFF2775B6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${day.minimumTemperature.round()}–${day.maximumTemperature.round()}°C',
              ),
            ),
            const Icon(Icons.water_drop_outlined,
                size: 17, color: Color(0xFF2775B6)),
            const SizedBox(width: 4),
            Text('${day.precipitationProbability.round()}%'),
          ],
        ),
      );
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Card(
        color: color.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 9),
            Expanded(child: Text(message)),
          ]),
        ),
      );
}

IconData _weatherIcon(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code <= 3) return Icons.cloud_outlined;
  if (code >= 95) return Icons.thunderstorm_rounded;
  if (code >= 51 && code <= 82) return Icons.water_drop_outlined;
  return Icons.cloud_queue_rounded;
}
