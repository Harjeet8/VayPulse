import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/edge_intelligence.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/live_motion.dart';
import 'alerts_screen.dart';
import 'app_command_search.dart';
import 'farmer_analysis_screen.dart';
import 'home_screen.dart';
import 'leaf_screening_screen.dart';
import 'live_sensors_screen.dart';
import 'observation_timeline_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int index = 0;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();

  void _openAlerts() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlertsScreen()),
    );
  }

  Widget _withFarmerGuidance(Widget page) {
    final scope = AppScope.of(context);
    final sensors = scope.sensors;

    return AnimatedBuilder(
      animation: sensors,
      child: page,
      builder: (context, child) {
        final reading = sensors.current;
        if (reading == null) return child!;

        final live = sensors.source == SensorDataSource.esp32;
        final disconnected = live &&
            sensors.connectionStatus != SensorConnectionStatus.ready;
        final edge = sensors.edgeIntelligence;

        final problem = disconnected
            ? _farmerText(
                context,
                'The PhytoSense device is disconnected.',
                'PhytoSense சாதனம் இணைக்கப்படவில்லை.',
              )
            : _plainProblem(
                context,
                edge,
                reading.healthStatus,
              );
        final solution = disconnected
            ? _farmerText(
                context,
                'Reconnect the device, then wait for a new live reading.',
                'சாதனத்தை மீண்டும் இணைத்து, புதிய நேரடி அளவுக்காக காத்திருக்கவும்.',
              )
            : _plainSolution(
                context,
                edge?.recommendation,
                problem,
              );

        return Column(
          children: [
            Expanded(child: child!),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: _FarmerGuidanceDock(
                  problem: problem,
                  solution: solution,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _withFarmerGuidance(
        HomeScreen(
          onOpenAlerts: _openAlerts,
          onOpenFields: () => setState(() => index = 2),
        ),
      ),
      _withFarmerGuidance(
        const KeyedSubtree(
          key: PageStorageKey<String>('farmer-analysis-page'),
          child: FarmerAnalysisScreen(),
        ),
      ),
      const LiveSensorsScreen(),
      const ObservationTimelineScreen(),
      const LeafScreeningScreen(),
      const SettingsScreen(),
    ];

    final railDestinations = [
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.home_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.home_rounded),
        label: Text(context.tr('nav_home')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.psychology_alt_outlined),
        selectedIcon:
            const LiveMotionIcon(icon: Icons.psychology_alt_rounded),
        label: Text(FarmerLanguage.label(context, 'analysis')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.sensors_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.sensors_rounded),
        label: Text(FarmerLanguage.label(context, 'sensors')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.timeline_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.timeline_rounded),
        label: Text(FarmerLanguage.label(context, 'history')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.photo_camera_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.photo_camera_rounded),
        label: Text(FarmerLanguage.label(context, 'camera')),
      ),
      NavigationRailDestination(
        icon: const LiveMotionIcon(icon: Icons.settings_outlined),
        selectedIcon: const LiveMotionIcon(icon: Icons.settings_rounded),
        label: Text(FarmerLanguage.label(context, 'settings')),
      ),
    ];

    final pageStack = PageStorage(
      bucket: _pageStorageBucket,
      child: IndexedStack(index: index, children: pages),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
            setState(() => index = 0),
        const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
            setState(() => index = 1),
        const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () =>
            setState(() => index = 2),
        const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () =>
            setState(() => index = 3),
        const SingleActivator(LogicalKeyboardKey.digit5, alt: true): () =>
            setState(() => index = 4),
        const SingleActivator(LogicalKeyboardKey.digit6, alt: true): () =>
            setState(() => index = 5),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            showSearch<void>(
              context: context,
              delegate: AppCommandSearch(
                searchLabel: context.tr('command_search_hint'),
              ),
            ),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 880;
            if (wide) {
              return Scaffold(
                body: Row(
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: NavigationRail(
                            extended: constraints.maxWidth >= 1160,
                            selectedIndex: index,
                            onDestinationSelected: (value) =>
                                setState(() => index = value),
                            leading: Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 20),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [phytoGreen, phytoLeaf],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const LiveMotionIcon(
                                  icon: Icons.eco_rounded,
                                  color: Colors.white,
                                  style: LiveMotionStyle.sway,
                                ),
                              ),
                            ),
                            destinations: railDestinations,
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: pageStack),
                  ],
                ),
              );
            }
            return Scaffold(
              body: pageStack,
              bottomNavigationBar: BottomNav(
                index: index,
                onChanged: (value) => setState(() => index = value),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FarmerGuidanceDock extends StatelessWidget {
  final String problem;
  final String solution;

  const _FarmerGuidanceDock({
    required this.problem,
    required this.solution,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuidanceLine(
            icon: Icons.report_problem_outlined,
            label: _farmerText(context, 'Problem', 'பிரச்சினை'),
            value: problem,
          ),
          const SizedBox(height: 10),
          _GuidanceLine(
            icon: Icons.task_alt_rounded,
            label: _farmerText(context, 'Solution', 'தீர்வு'),
            value: solution,
          ),
        ],
      ),
    );
  }
}

class _GuidanceLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _GuidanceLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: RichText(
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    height: 1.3,
                  ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _plainProblem(
  BuildContext context,
  EdgeIntelligence? edge,
  String healthStatus,
) {
  final raw = '${edge?.rootCause.primary ?? ''} '
          '${edge?.farmerSummary ?? ''} '
          '$healthStatus'
      .toUpperCase();

  if (raw.contains('SOIL PROBE') ||
      raw.contains('PROBE PLACEMENT') ||
      raw.contains('CALIBRATION')) {
    return _farmerText(
      context,
      'The soil sensor may not be placed correctly.',
      'மண் சென்சார் சரியாக வைக்கப்படாமல் இருக்கலாம்.',
    );
  }
  if (raw.contains('OVERWATER') ||
      raw.contains('VERY WET') ||
      raw.contains('TOO WET')) {
    return _farmerText(
      context,
      'The soil may be too wet.',
      'மண் அதிகமாக ஈரமாக இருக்கலாம்.',
    );
  }
  if (raw.contains('ATMOSPHERIC') ||
      raw.contains('DRYING DEMAND') ||
      raw.contains('WATER LOSS') ||
      raw.contains('VPD')) {
    return _farmerText(
      context,
      'Hot or dry air may be making the plant lose water too quickly.',
      'சூடான அல்லது உலர் காற்றால் செடி விரைவாக நீரை இழக்கலாம்.',
    );
  }
  if (raw.contains('WATER STRESS') ||
      raw.contains('ROOT SOIL IS DRY') ||
      raw.contains('ROOT_ZONE_IS_DRY') ||
      raw.contains('VERY DRY')) {
    return _farmerText(
      context,
      'The plant may not be getting enough water.',
      'செடிக்கு போதுமான நீர் கிடைக்காமல் இருக்கலாம்.',
    );
  }
  if (raw.contains('HEAT') || raw.contains('HOT')) {
    return _farmerText(
      context,
      'The plant may be getting too hot.',
      'செடி அதிக வெப்பமாக இருக்கலாம்.',
    );
  }
  if (raw.contains('LOW LIGHT')) {
    return _farmerText(
      context,
      'The plant may not be getting enough light.',
      'செடிக்கு போதுமான ஒளி கிடைக்காமல் இருக்கலாம்.',
    );
  }
  if (raw.contains('ELECTRODE') ||
      raw.contains('BIOELECTRIC') ||
      raw.contains('PLANT SIGNAL') ||
      raw.contains('CONTACT VERIFY')) {
    return _farmerText(
      context,
      'The plant signal sensor needs a quick check.',
      'செடி சிக்னல் சென்சாரை சரிபார்க்க வேண்டும்.',
    );
  }
  if (raw.contains('SENSOR') || raw.contains('FAULT')) {
    return _farmerText(
      context,
      'One of the sensors needs to be checked.',
      'ஒரு சென்சாரை சரிபார்க்க வேண்டும்.',
    );
  }
  if (raw.contains('EXCELLENT') ||
      raw.contains('HEALTHY') ||
      raw.contains('NORMAL') ||
      raw.contains('OPTIMAL')) {
    return _farmerText(
      context,
      'No major problem detected.',
      'பெரிய பிரச்சினை எதுவும் கண்டறியப்படவில்லை.',
    );
  }

  return _farmerText(
    context,
    'The plant needs attention.',
    'செடிக்கு கவனம் தேவை.',
  );
}

String _plainSolution(
  BuildContext context,
  String? recommendation,
  String problem,
) {
  final raw = '${recommendation ?? ''} $problem'.toUpperCase();

  if (raw.contains('SOIL SENSOR') ||
      raw.contains('SOIL PROBE') ||
      raw.contains('PLACEMENT')) {
    return _farmerText(
      context,
      'Push the soil sensor firmly into the soil near the roots, then check again.',
      'மண் சென்சாரை வேர் அருகே நன்றாக நுழைத்து மீண்டும் பார்க்கவும்.',
    );
  }
  if (raw.contains('TOO WET') ||
      raw.contains('OVERWATER') ||
      raw.contains('DRAIN')) {
    return _farmerText(
      context,
      'Do not add more water now. Check that extra water can drain away.',
      'இப்போது மேலும் நீர் விட வேண்டாம். அதிக நீர் வெளியேறுகிறதா பாருங்கள்.',
    );
  }
  if (raw.contains('WATER') ||
      raw.contains('IRRIGAT') ||
      raw.contains('DRY')) {
    return _farmerText(
      context,
      'Check the soil near the roots. Water only if the soil is actually dry.',
      'வேர் அருகே மண்ணை பாருங்கள். மண் உண்மையில் உலர்ந்திருந்தால் மட்டும் நீர் விடுங்கள்.',
    );
  }
  if (raw.contains('ELECTRODE') ||
      raw.contains('PLANT SIGNAL') ||
      raw.contains('CONTACT')) {
    return _farmerText(
      context,
      'Check that both plant electrodes are firmly attached and are not touching each other.',
      'இரண்டு எலக்ட்ரோடுகளும் செடியில் நன்றாக பொருந்தியுள்ளதா, ஒன்றை ஒன்று தொடாதா பாருங்கள்.',
    );
  }
  if (raw.contains('HEAT') || raw.contains('HOT')) {
    return _farmerText(
      context,
      'Check the plant and soil moisture. Avoid extra stress during the hottest part of the day.',
      'செடியையும் மண் ஈரத்தையும் பாருங்கள். அதிக வெப்ப நேரத்தில் கூடுதல் அழுத்தத்தை தவிர்க்கவும்.',
    );
  }
  if (raw.contains('LIGHT') || raw.contains('SHADE')) {
    return _farmerText(
      context,
      'Check for shade or anything blocking the light sensor.',
      'நிழல் அல்லது ஒளி சென்சாரை மறைக்கும் பொருள் உள்ளதா பாருங்கள்.',
    );
  }
  if (raw.contains('NO MAJOR PROBLEM') ||
      raw.contains('KEEP MONITOR') ||
      raw.contains('NO IMMEDIATE')) {
    return _farmerText(
      context,
      'Keep watching the plant. No immediate action is needed.',
      'செடியை தொடர்ந்து கவனியுங்கள். உடனடி நடவடிக்கை தேவையில்லை.',
    );
  }

  return _farmerText(
    context,
    'Check the plant and the sensor readings, then follow the latest PhytoSense guidance.',
    'செடியையும் சென்சார் அளவுகளையும் பார்த்து, PhytoSense வழிகாட்டுதலை பின்பற்றவும்.',
  );
}

String _farmerText(BuildContext context, String english, String tamil) =>
    FarmerLanguage.isTamil(context) ? tamil : english;
