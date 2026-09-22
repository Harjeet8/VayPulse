import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/hardware_transport.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';
import 'about_screen.dart';
import '../services/phone_notification_service.dart';
import 'care_journal_screen.dart';
import 'setup_guide_screen.dart';
import 'voice_studio_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.settings;
    final value = settings.value;
    return AnimatedBuilder(
      animation: Listenable.merge([settings, scope.sensorManager]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(context.tr('settings_title'))),
        body: PageFrame(
          children: [
            PhytoPageIntro(
              eyebrow: FarmerLanguage.isTamil(context)
                  ? 'உங்கள் விருப்பம்'
                  : 'YOUR APP',
              title: FarmerLanguage.isTamil(context)
                  ? 'PhytoSense-ஐ அமைக்கவும்'
                  : 'Make PhytoSense yours',
              body: FarmerLanguage.isTamil(context)
                  ? 'தரவு மூலம், மொழி, தோற்றம் மற்றும் அறிவிப்புகளை ஒரே இடத்தில் மாற்றுங்கள்.'
                  : 'Choose the data source, language, appearance and alerts in one place.',
              icon: Icons.tune_rounded,
            ),
            const SizedBox(height: 22),
            Card(
                child: Column(children: [
              ListTile(
                  leading: const Icon(Icons.record_voice_over_outlined,
                      color: phytoWater),
                  title: Text(FarmerLanguage.isTamil(context)
                      ? 'குரல் வழிகாட்டுதல்'
                      : 'Voice guidance'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VoiceStudioScreen()))),
              ListTile(
                  leading: const Icon(Icons.auto_stories_outlined,
                      color: phytoTerracotta),
                  title: Text(FarmerLanguage.isTamil(context)
                      ? 'பராமரிப்பு பதிவு மற்றும் காப்புப்பிரதி'
                      : 'Care diary & backup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CareJournalScreen()))),
              ListTile(
                  leading: const Icon(Icons.explore_outlined, color: phytoSun),
                  title: Text(FarmerLanguage.isTamil(context)
                      ? 'தொடங்குவோம்'
                      : 'Getting started'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SetupGuideScreen()))),
            ])),
            const SizedBox(height: 22),
            _SettingsLabel(context.tr('source_control')),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('source_control_body')),
                    const SizedBox(height: 14),
                    Column(
                      children: [
                        _SettingsOption(
                          icon: Icons.science_outlined,
                          title: FarmerLanguage.label(context, 'simulation'),
                          selected: scope.sensorManager.source ==
                              SensorDataSource.simulation,
                          onTap: () async {
                            await HapticFeedback.mediumImpact();
                            await settings.setDataSource('simulation');
                            scope.alerts.clear();
                            scope.sensorManager.configure(
                              source: SensorDataSource.simulation,
                              endpoint: settings.value.esp32Endpoint,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _SettingsOption(
                          icon: Icons.memory_rounded,
                          title: context.tr('esp32_live'),
                          selected: scope.sensorManager.source ==
                              SensorDataSource.esp32,
                          onTap: () async {
                            await HapticFeedback.mediumImpact();
                            await settings.setDataSource('esp32');
                            scope.alerts.clear();
                            scope.sensorManager.configure(
                              source: SensorDataSource.esp32,
                              endpoint: settings.value.esp32Endpoint,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      scope.sensorManager.source == SensorDataSource.esp32
                          ? context.tr('esp32_description')
                          : FarmerLanguage.label(
                              context, 'simulation_description'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _HardwareConnectionCard(),
            const SizedBox(height: 18),
            _SettingsLabel(context.tr('language')),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('language_subtitle')),
                    const SizedBox(height: 14),
                    Column(
                      children: [
                        _SettingsOption(
                          icon: Icons.language_rounded,
                          title: context.tr('english'),
                          selected: value.languageCode == 'en',
                          onTap: () => settings.setLanguage('en'),
                        ),
                        const SizedBox(height: 8),
                        _SettingsOption(
                          icon: Icons.translate_rounded,
                          title: context.tr('tamil'),
                          selected: value.languageCode == 'ta',
                          onTap: () => settings.setLanguage('ta'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _VoicePreviewCard(),
            const SizedBox(height: 12),
            Card(
                child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(FarmerLanguage.isTamil(context)
                  ? 'அறிவிப்பு மாதிரியைப் பார்'
                  : 'Preview a notification'),
              subtitle: Text(FarmerLanguage.isTamil(context)
                  ? 'உங்கள் தொலைபேசியில் தோற்றத்தைச் சரிபார்க்கவும்'
                  : 'Check how alerts look on your phone'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final tamil = FarmerLanguage.isTamil(context);
                final ok = await PhoneNotificationService.showPreview(
                    scope.settings.value.languageCode);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? (tamil
                            ? 'மாதிரி அனுப்பப்பட்டது. அறிவிப்புப் பகுதியைப் பாருங்கள்.'
                            : 'Preview sent. Open your notification shade.')
                        : (tamil
                            ? 'தொலைபேசி அமைப்பில் PhytoSense அறிவிப்புகளை அனுமதிக்கவும்.'
                            : 'Allow PhytoSense notifications in phone settings.'))));
              },
            )),
            const SizedBox(height: 18),
            _SettingsLabel(context.tr('about')),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(
                  context.tr('about_settings_title'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(context.tr('about_settings_body')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutVayPulseScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _SettingsLabel(context.tr('appearance')),
            const SizedBox(height: 8),
            _ThemePicker(
              selected: value.themeMode,
              onChanged: settings.setTheme,
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.straighten_outlined),
                    title: Text(context.tr('units')),
                    subtitle: Text(context.tr('units_subtitle')),
                    value: value.metricUnits,
                    onChanged: settings.setMetricUnits,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: Text(context.tr('notifications')),
                    subtitle: Text(context.tr('notifications_subtitle')),
                    value: value.notificationsEnabled,
                    onChanged: settings.setNotifications,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.text_fields_rounded),
                    title: Text(context.tr('large_text')),
                    subtitle: Text(context.tr('large_text_body')),
                    value: value.largeText,
                    onChanged: settings.setLargeText,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.motion_photos_off_outlined),
                    title: Text(context.tr('reduced_motion')),
                    subtitle: Text(context.tr('reduced_motion_body')),
                    value: value.reducedMotion,
                    onChanged: settings.setReducedMotion,
                  ),
                ],
              ),
            ),
            if (scope.sensors.supportsScenarios) ...[
              const SizedBox(height: 18),
              const _SettingsLabel('Simulation controls'),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: scope.sensors.scenarioId,
                    decoration: const InputDecoration(
                      labelText: 'Simulation scenario',
                      prefixIcon: Icon(Icons.science_outlined),
                    ),
                    items: scope.sensors.scenarioIds
                        .map((scenario) => DropdownMenuItem(
                              value: scenario,
                              child: Text(context.tr('scenario_$scenario')),
                            ))
                        .toList(),
                    onChanged: (scenario) {
                      if (scenario == null) return;
                      settings.setScenario(scenario);
                      scope.sensors.setScenario(scenario);
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Card(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.memory_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('hardware_ready'),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(context.tr('hardware_ready_body')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemePicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('theme_picker_title'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('theme_picker_body'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              LayoutBuilder(
                builder: (context, _) {
                  final options = [
                    _ThemeOption(
                      mode: ThemeMode.system,
                      selected: selected == ThemeMode.system,
                      icon: Icons.brightness_auto_outlined,
                      label: context.tr('system_theme'),
                      onTap: onChanged,
                    ),
                    _ThemeOption(
                      mode: ThemeMode.light,
                      selected: selected == ThemeMode.light,
                      icon: Icons.light_mode_outlined,
                      label: context.tr('light_theme'),
                      onTap: onChanged,
                    ),
                    _ThemeOption(
                      mode: ThemeMode.dark,
                      selected: selected == ThemeMode.dark,
                      icon: Icons.dark_mode_outlined,
                      label: context.tr('dark_theme'),
                      onTap: onChanged,
                    ),
                  ];
                  return Row(
                    children: [
                      for (var i = 0; i < options.length; i++) ...[
                        Expanded(child: options[i]),
                        if (i < options.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 19,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(context.tr('theme_preview_note'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ThemeOption extends StatelessWidget {
  final ThemeMode mode;
  final bool selected;
  final IconData icon;
  final String label;
  final ValueChanged<ThemeMode> onTap;

  const _ThemeOption({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onTap(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  size: 25,
                ),
                if (selected)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: scheme.primary,
                      size: 15,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HardwareConnectionCard extends StatefulWidget {
  const _HardwareConnectionCard();

  @override
  State<_HardwareConnectionCard> createState() =>
      _HardwareConnectionCardState();
}

class _HardwareConnectionCardState extends State<_HardwareConnectionCard> {
  final controller = TextEditingController();
  bool initialized = false;
  bool testing = false;
  bool? testResult;
  String? validationError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      controller.text = AppScope.of(context).settings.value.esp32Endpoint;
      initialized = true;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool _validEndpoint(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> _setTransport(HardwareTransportMode mode) async {
    final scope = AppScope.of(context);
    await scope.settings.setHardwareTransportMode(mode.id);
    scope.sensorManager.setHardwareTransportMode(mode);
    if (mounted) setState(() {});
  }

  Future<void> _saveAndTest() async {
    final endpoint = controller.text.trim();
    if (!_validEndpoint(endpoint)) {
      setState(() {
        validationError = context.tr('endpoint_invalid');
        testResult = null;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.tr('endpoint_invalid'))),
        );
      return;
    }
    final scope = AppScope.of(context);
    setState(() {
      testing = true;
      validationError = null;
      testResult = null;
    });
    await scope.settings.setEsp32Endpoint(endpoint);
    scope.sensorManager.configure(
      source: scope.sensorManager.source,
      endpoint: endpoint,
    );
    final result = await scope.sensorManager.testEndpoint(endpoint);
    if (!mounted) return;
    setState(() {
      testing = false;
      testResult = result;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr(
              result ? 'connection_test_success' : 'connection_test_failed')),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.router_outlined),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      context.tr('configure_esp32'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(context.tr('configure_esp32_body')),
              const SizedBox(height: 14),
              Text(
                'Hardware connection',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<HardwareTransportMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: HardwareTransportMode.auto,
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: HardwareTransportMode.local,
                      label: Text('Local'),
                    ),
                    ButtonSegment(
                      value: HardwareTransportMode.remote,
                      label: Text('Remote'),
                    ),
                  ],
                  selected: {
                    HardwareTransportModeX.parse(
                      AppScope.of(context).settings.value.hardwareTransportMode,
                    ),
                  },
                  onSelectionChanged: (selection) {
                    if (selection.isNotEmpty) {
                      _setTransport(selection.first);
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                switch (HardwareTransportModeX.parse(
                  AppScope.of(context).settings.value.hardwareTransportMode,
                )) {
                  HardwareTransportMode.auto =>
                    'Auto prefers the direct ESP32 link and safely falls back to the fresh Firebase snapshot.',
                  HardwareTransportMode.local =>
                    'Local uses only the direct ESP32 Wi-Fi/API connection.',
                  HardwareTransportMode.remote =>
                    'Remote uses only the fresh Firebase snapshot sent by the ESP32.',
                },
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: context.tr('esp32_endpoint'),
                  hintText: 'http://192.168.4.1',
                  prefixIcon: const Icon(Icons.link_rounded),
                  errorText: validationError,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: testing ? null : _saveAndTest,
                  icon: testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cable_rounded),
                  label: Text(context.tr(
                    testing ? 'testing_connection' : 'save_and_test',
                  )),
                ),
              ),
              if (testResult != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      testResult!
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: testResult! ? phytoLeaf : phytoTerracotta,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(context.tr(testResult!
                          ? 'connection_test_success'
                          : 'connection_test_failed')),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
}

class _SettingsLabel extends StatelessWidget {
  final String text;

  const _SettingsLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
            ),
      );
}

class _VoicePreviewCard extends StatefulWidget {
  const _VoicePreviewCard();

  @override
  State<_VoicePreviewCard> createState() => _VoicePreviewCardState();
}

class _VoicePreviewCardState extends State<_VoicePreviewCard> {
  bool previewing = false;
  String? voiceName;
  String? voiceLanguage;

  Future<void> _preview() async {
    final scope = AppScope.of(context);
    final language = scope.settings.value.languageCode;
    final previewText = context.tr('voice_preview_sample');
    setState(() => previewing = true);
    final prepared = await scope.voice.prepareVoice(language);
    final spoken = await scope.voice.speak(
      text: previewText,
      languageCode: language,
    );
    if (!mounted) return;
    setState(() {
      previewing = false;
      voiceName = prepared;
      voiceLanguage = language;
    });
    if (!spoken) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('voice_unavailable'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = AppScope.of(context).settings.value.languageCode;
    final currentVoice = voiceLanguage == currentLanguage ? voiceName : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.record_voice_over_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('voice_quality'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(context.tr('voice_quality_body')),
                    ],
                  ),
                ),
              ],
            ),
            if (currentVoice != null) ...[
              const SizedBox(height: 10),
              Text(
                context.tr('voice_selected', {'value': currentVoice}),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: previewing ? null : _preview,
                icon: previewing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(context.tr(
                  previewing ? 'voice_preview_playing' : 'voice_preview',
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.52)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color:
                        selected ? scheme.onPrimaryContainer : scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
