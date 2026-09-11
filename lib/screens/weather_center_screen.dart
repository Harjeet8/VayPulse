import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/weather_snapshot.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';

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
            title: Text(
              _weatherText(
                context,
                'Weather & Location',
                'வானிலை & இடம்',
              ),
            ),
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
              PhytoPageIntro(
                eyebrow:
                    _weatherText(context, 'LOCAL WEATHER', 'உள்ளூர் வானிலை'),
                title: _weatherText(
                  context,
                  'Weather around your plant',
                  'உங்கள் செடியை சுற்றிய வானிலை',
                ),
                body: _weatherText(
                  context,
                  'See heat, rain, and drying conditions in one place.',
                  'வெப்பம், மழை மற்றும் உலர் நிலையை ஒரே இடத்தில் பாருங்கள்.',
                ),
                icon: Icons.partly_cloudy_day_outlined,
              ),
              const SizedBox(height: 16),
              if (snapshot == null)
                _WeatherUnavailable(loading: scope.weather.loading)
              else ...[
                _LocationCard(
                  location: scope.weather.location,
                  usingPhone: scope.weather.usingDeviceLocation,
                  onTap: () => _showLocationEditor(context),
                ),
                const SizedBox(height: 12),
                _WeatherHero(snapshot: snapshot),
                const SizedBox(height: 12),
                _WeatherMetrics(snapshot: snapshot),
                const SizedBox(height: 12),
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
                if (snapshot.hourly.isNotEmpty) ...[
                  Text(
                    _weatherText(
                      context,
                      'Next few hours',
                      'அடுத்த சில மணிநேரங்கள்',
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  _HourlyForecast(hours: snapshot.hourly),
                  const SizedBox(height: 18),
                ],
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
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: scope.weather.locating
                        ? null
                        : () => _refreshPhoneWeather(context),
                    icon: scope.weather.locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: Text(
                      _weatherText(
                        context,
                        'Refresh phone location & weather',
                        'Phone இடம் & வானிலையை புதுப்பிக்கவும்',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Center(
                  child: Text(
                    '${scope.weather.usingDeviceLocation ? _weatherText(context, 'Phone GPS', 'Phone GPS') : _weatherText(context, 'Saved farm location', 'சேமித்த பண்ணை இடம்')}  •  ${_weatherText(context, 'Updated', 'புதுப்பிப்பு')} ${_weatherAge(snapshot.updatedAt)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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
        ? _weatherText(
            context,
            'Saved weather is being shown. Refresh when internet is available.',
            'சேமித்த வானிலை காட்டப்படுகிறது. Internet கிடைக்கும்போது புதுப்பிக்கவும்.',
          )
        : snapshot.heavyRainRisk
            ? _weatherText(
                context,
                'Heavy rain may come. Check field drainage.',
                'கனமழை வரலாம். வயல் வடிகாலை பார்க்கவும்.',
              )
            : snapshot.diseaseRisk
                ? _weatherText(
                    context,
                    'Wet weather may raise leaf disease risk. Inspect the leaves.',
                    'ஈரமான வானிலை இலை நோய் அபாயத்தை உயர்த்தலாம். இலைகளை பாருங்கள்.',
                  )
                : snapshot.drySpellRisk
                    ? _weatherText(
                        context,
                        'Dry days are expected. Check root-zone soil each day.',
                        'உலர் நாட்கள் வரலாம். தினமும் வேர் பகுதி மண்ணை பாருங்கள்.',
                      )
                    : _weatherText(
                        context,
                        'No urgent weather problem. Keep monitoring as usual.',
                        'அவசர வானிலை பிரச்சினை இல்லை. வழக்கம்போல் கண்காணிக்கவும்.',
                      );
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

  Future<void> _refreshPhoneWeather(BuildContext context) async {
    final weather = AppScope.of(context).weather;
    final success = await weather.useDeviceLocation();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(weather.locationErrorKey ?? 'location_unavailable'),
          ),
        ),
      );
    }
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

class _LocationCard extends StatelessWidget {
  final String location;
  final bool usingPhone;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.usingPhone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    usingPhone
                        ? Icons.my_location_rounded
                        : Icons.location_on_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        usingPhone
                            ? _weatherText(
                                context,
                                'Phone GPS location',
                                'Phone GPS இடம்',
                              )
                            : _weatherText(
                                context,
                                'Saved farm location',
                                'சேமித்த பண்ணை இடம்',
                              ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _weatherText(
                          context,
                          'Saved on this phone for offline use',
                          'Internet இல்லாதபோதும் இந்த phone-ல் சேமிக்கப்பட்டிருக்கும்',
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_location_alt_outlined),
              ],
            ),
          ),
        ),
      );
}

class _WeatherMetrics extends StatelessWidget {
  final WeatherSnapshot snapshot;

  const _WeatherMetrics({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final rain = snapshot.currentRainChance?.round();
    final uv = snapshot.uvIndex;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _WeatherMetric(
                icon: Icons.water_drop_outlined,
                label: _weatherText(context, 'Humidity', 'ஈரப்பதம்'),
                value: '${snapshot.humidity.round()}%',
                color: const Color(0xFF2E86C1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WeatherMetric(
                icon: Icons.umbrella_outlined,
                label: _weatherText(context, 'Rain chance', 'மழை வாய்ப்பு'),
                value: rain == null ? '—' : '$rain%',
                color: const Color(0xFF4D77C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _WeatherMetric(
                icon: Icons.air_rounded,
                label: _weatherText(context, 'Wind', 'காற்று'),
                value: '${snapshot.windSpeed.round()} km/h',
                color: const Color(0xFF238C78),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WeatherMetric(
                icon: Icons.wb_sunny_outlined,
                label: 'UV',
                value: uv == null ? '—' : _uvLabel(context, uv),
                color: phytoAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeatherMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WeatherMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _HourlyForecast extends StatelessWidget {
  final List<WeatherHour> hours;

  const _HourlyForecast({required this.hours});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 126,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: hours.take(8).length,
          separatorBuilder: (_, __) => const SizedBox(width: 9),
          itemBuilder: (context, index) {
            final hour = hours[index];
            return Container(
              width: 82,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _hourLabel(hour.time),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Icon(
                    _weatherIcon(hour.weatherCode),
                    color: const Color(0xFF327FB8),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${hour.temperature.round()}°C',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${hour.precipitationProbability.round()}% rain',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            );
          },
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
        padding: const EdgeInsets.all(20),
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
                    _weatherDescription(context, snapshot.weatherCode),
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
                    snapshot.apparentTemperature == null
                        ? _weatherText(context, 'Current farm weather',
                            'தற்போதைய பண்ணை வானிலை')
                        : '${_weatherText(context, 'Feels like', 'உணரும் வெப்பம்')} ${snapshot.apparentTemperature!.round()}°C',
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
        title: _weatherText(
          context,
          'Heavy rain may affect the field',
          'கனமழை வயலை பாதிக்கலாம்',
        ),
        body: _weatherText(
          context,
          'Check drainage and avoid watering before the rain.',
          'வடிகாலை பார்த்து, மழைக்கு முன் நீர் ஊற்ற வேண்டாம்.',
        ),
        color: const Color(0xFF2775B6),
      ));
    }
    if (snapshot.diseaseRisk) {
      risks.add(_RiskCard(
        icon: Icons.coronavirus_outlined,
        title: _weatherText(
          context,
          'Wet weather may raise leaf disease risk',
          'ஈரமான வானிலை இலை நோய் அபாயத்தை உயர்த்தலாம்',
        ),
        body: _weatherText(
          context,
          'Keep leaves dry where possible and inspect them for visible spots.',
          'முடிந்தவரை இலைகளை உலர வைத்து, புள்ளிகள் உள்ளதா பாருங்கள்.',
        ),
        color: phytoAmber,
      ));
    }
    if (snapshot.drySpellRisk) {
      risks.add(_RiskCard(
        icon: Icons.wb_sunny_outlined,
        title: _weatherText(
          context,
          'Several dry days are expected',
          'பல உலர் நாட்கள் வரலாம்',
        ),
        body: _weatherText(
          context,
          'Check root-zone soil each day. Water only when it is becoming dry.',
          'தினமும் வேர் பகுதி மண்ணை பாருங்கள். மண் உலர்ந்தால் மட்டும் நீர் ஊற்றவும்.',
        ),
        color: phytoTerracotta,
      ));
    }
    if (snapshot.temperature >= 32 && snapshot.humidity <= 55) {
      risks.add(_RiskCard(
        icon: Icons.air_rounded,
        title: _weatherText(
          context,
          'Hot, dry air may pull water quickly',
          'சூடான உலர் காற்று நீரை வேகமாக இழுக்கலாம்',
        ),
        body: _weatherText(
          context,
          'Check root-zone moisture and give shade during the hottest hours.',
          'வேர் பகுதி ஈரத்தை பார்த்து, அதிக வெப்ப நேரத்தில் நிழல் கொடுங்கள்.',
        ),
        color: phytoTerracotta,
      ));
    }
    if (risks.isEmpty) {
      risks.add(_RiskCard(
        icon: Icons.check_circle_outline_rounded,
        title: _weatherText(
          context,
          'No urgent weather problem',
          'அவசர வானிலை பிரச்சினை இல்லை',
        ),
        body: _weatherText(
          context,
          'Keep checking the plant and soil as usual.',
          'வழக்கம்போல் செடி மற்றும் மண்ணை பார்த்து வரவும்.',
        ),
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

String _weatherDescription(BuildContext context, int code) {
  if (code == 0) return _weatherText(context, 'Clear sky', 'தெளிவான வானம்');
  if (code <= 3) {
    return _weatherText(context, 'Partly cloudy', 'ஓரளவு மேகமூட்டம்');
  }
  if (code >= 95) {
    return _weatherText(context, 'Thunderstorm', 'இடியுடன் மழை');
  }
  if (code >= 51 && code <= 82) {
    return _weatherText(context, 'Rain', 'மழை');
  }
  if (code == 45 || code == 48) {
    return _weatherText(context, 'Fog', 'மூடுபனி');
  }
  return _weatherText(context, 'Cloudy', 'மேகமூட்டம்');
}

String _uvLabel(BuildContext context, double value) {
  if (value >= 8) return _weatherText(context, 'Very high', 'மிக அதிகம்');
  if (value >= 6) return _weatherText(context, 'High', 'அதிகம்');
  if (value >= 3) return _weatherText(context, 'Medium', 'நடுத்தரம்');
  return _weatherText(context, 'Low', 'குறைவு');
}

String _hourLabel(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour ${time.hour < 12 ? 'AM' : 'PM'}';
}

String _weatherAge(DateTime updatedAt) {
  final age = DateTime.now().difference(updatedAt);
  if (age.isNegative || age.inMinutes < 1) return 'now';
  if (age.inMinutes < 60) return '${age.inMinutes}m ago';
  if (age.inHours < 24) return '${age.inHours}h ago';
  return '${age.inDays}d ago';
}

String _weatherText(BuildContext context, String english, String tamil) =>
    FarmerLanguage.isTamil(context) ? tamil : english;
