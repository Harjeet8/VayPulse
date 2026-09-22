import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../l10n/app_strings.dart';
import '../models/farm_impact_projection.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/sensor_data_provider.dart';
import '../widgets/page_frame.dart';
import '../widgets/plant_pulse.dart';

class AboutVayPulseScreen extends StatelessWidget {
  const AboutVayPulseScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.tr('about'))),
        body: PageFrame(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D4934), Color(0xFF23815C)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.35,
                      child: PlantPulse(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'PhytoSense AI',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.tr('tagline'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        context.tr('powered_by_vaypulse'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.68),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('10.2.2 • Verdant',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            _AboutSection(
              icon: Icons.flag_outlined,
              title: context.tr('about_mission_title'),
              body: context.tr('about_mission_body'),
            ),
            const SizedBox(height: 12),
            const _CreatorCard(),
            const SizedBox(height: 12),
            const _FarmImpactEstimator(),
            const SizedBox(height: 12),
            _AboutSection(
              icon: Icons.route_outlined,
              title: context.tr('about_how_title'),
              body: context.tr('about_how_body'),
              bullets: [
                context.tr('about_how_1'),
                context.tr('about_how_2'),
                context.tr('about_how_3'),
                context.tr('about_how_4'),
              ],
            ),
            const SizedBox(height: 12),
            _AboutSection(
              icon: Icons.engineering_outlined,
              title: context.tr('about_engineering_title'),
              body: context.tr('about_engineering_body'),
              bullets: [
                context.tr('about_engineering_1'),
                context.tr('about_engineering_2'),
                context.tr('about_engineering_3'),
              ],
            ),
            const SizedBox(height: 12),
            _AboutSection(
              icon: Icons.auto_awesome_outlined,
              title: context.tr('about_capabilities_title'),
              body: context.tr('about_capabilities_body'),
              bullets: [
                context.tr('about_capabilities_1'),
                context.tr('about_capabilities_2'),
                context.tr('about_capabilities_3'),
                context.tr('about_capabilities_4'),
              ],
            ),
            const SizedBox(height: 12),
            _AboutSection(
              icon: Icons.people_alt_outlined,
              title: context.tr('about_farmer_title'),
              body: context.tr('about_farmer_body'),
              bullets: [
                context.tr('about_farmer_1'),
                context.tr('about_farmer_2'),
                context.tr('about_farmer_3'),
              ],
            ),
            const SizedBox(height: 12),
            _AboutSection(
              icon: Icons.verified_user_outlined,
              title: context.tr('about_responsible_title'),
              body: context.tr('about_responsible_body'),
            ),
            const SizedBox(height: 12),
            Card(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'PhytoSense AI',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(FarmerLanguage.isTamil(context)
                    ? 'ESP32 வழங்கும் பகுப்பாய்வு • விவசாயிகளுக்கான எளிய செயலி • ஆங்கிலம்/தமிழ் • சென்சார் மற்றும் பட ஆதாரங்கள் தனித்தனி'
                    : 'ESP32-authoritative intelligence • Farmer-first UI • English/Tamil • Sensor and visual evidence kept separate'),
              ),
            ),
          ],
        ),
      );
}

class _CreatorCard extends StatelessWidget {
  const _CreatorCard();
  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const PageStorageKey('creator-details'),
        maintainState: true,
        leading: const Icon(Icons.person_outline_rounded),
        title: Text(tamil ? 'உருவாக்குநர்' : 'Meet the creator'),
        subtitle: Text(tamil
            ? 'Harjeet D. · மாணவர் பொறியாளர்'
            : 'Harjeet D. · Student engineer'),
        childrenPadding: const EdgeInsets.all(20),
        children: const [CreatorProfile()],
      ),
    );
  }
}

/// Shared profile keeps the expandable About section compact and testable.
class CreatorProfile extends StatelessWidget {
  const CreatorProfile({super.key});
  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final theme = Theme.of(context);
    String t(String en, String ta) => tamil ? ta : en;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Harjeet D.', style: theme.textTheme.headlineSmall),
      const SizedBox(height: 5),
      Text(
          t('Student engineer from Tamil Nadu',
              'தமிழ்நாட்டைச் சேர்ந்த மாணவர் பொறியாளர்'),
          style: theme.textTheme.titleSmall
              ?.copyWith(color: theme.colorScheme.primary)),
      const SizedBox(height: 12),
      Text(t(
          'I bring electronics, embedded programming and app design together to build practical tools that people can understand.',
          'மின்னணுவியல், சாதன நிரலாக்கம், செயலி வடிவமைப்பு ஆகியவற்றை இணைத்து, மக்கள் எளிதாகப் பயன்படுத்தும் கருவிகளை உருவாக்குகிறேன்.')),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final label in [
          t('Electronics', 'மின்னணுவியல்'),
          t('Embedded systems', 'சாதன நிரலாக்கம்'),
          t('Apps & AI', 'செயலிகள் மற்றும் செயற்கை நுண்ணறிவு')
        ])
          Chip(label: Text(label, style: theme.textTheme.labelLarge)),
      ]),
      const SizedBox(height: 18),
      Text(t('How I build', 'எனது அணுகுமுறை'),
          style: theme.textTheme.titleMedium),
      const SizedBox(height: 7),
      Text(t(
          'Start with a real problem. Build a working prototype. Test it, learn from it, and make the result easier to use.',
          'உண்மையான பிரச்சினையிலிருந்து தொடங்குவது. இயங்கும் மாதிரியை உருவாக்குவது. சோதித்து கற்றுக்கொண்டு, பயன்படுத்துவதை எளிதாக்குவது.')),
      const SizedBox(height: 20),
      Text(t('Selected projects', 'தேர்ந்தெடுக்கப்பட்ட திட்டங்கள்'),
          style: theme.textTheme.titleMedium),
      const SizedBox(height: 12),
      _CreatorBuild(
          title: 'PhytoSense AI',
          description: t(
              'Plant sensing, ESP32 intelligence and clear guidance for farmers.',
              'செடி அளவீடுகள், ESP32 பகுப்பாய்வு, விவசாயிகளுக்கான தெளிவான வழிகாட்டுதல்.')),
      const SizedBox(height: 12),
      _CreatorBuild(
          title: 'EchoSkin AI',
          description: t(
              'A prototype that uses vibration sensing to explore structural monitoring.',
              'அதிர்வு அளவீடுகள் மூலம் கட்டமைப்பைக் கண்காணிப்பதை ஆராயும் மாதிரி.')),
      const SizedBox(height: 12),
      _CreatorBuild(
          title: 'AURA',
          description: t(
              'An elder-care app prototype focused on clear emergency-response steps.',
              'அவசர நேரத்தில் தெளிவான செயல்படிகளை வழங்கும் முதியோர் பராமரிப்பு செயலி மாதிரி.')),
      const SizedBox(height: 18),
      Text(
          t('PhytoSense was developed with a student team and teacher guidance.',
              'மாணவர் குழு மற்றும் ஆசிரியர் வழிகாட்டுதலுடன் PhytoSense உருவாக்கப்பட்டது.'),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _CreatorBuild extends StatelessWidget {
  final String title;
  final String description;

  const _CreatorBuild({required this.title, required this.description});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.arrow_outward_rounded,
              size: 17,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(description),
              ],
            ),
          ),
        ],
      );
}

class _FarmImpactEstimator extends StatefulWidget {
  const _FarmImpactEstimator();

  @override
  State<_FarmImpactEstimator> createState() => _FarmImpactEstimatorState();
}

class _FarmImpactEstimatorState extends State<_FarmImpactEstimator> {
  bool initialized = false;
  double areaAcres = 3.2;
  double seasonalValuePerAcre = 60000;
  double lossRiskPercent = 15;
  double preventableSharePercent = 35;
  double inputSavingsPerAcre = 1500;
  double systemCost = 6000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final scope = AppScope.of(context);
    final field = scope.farms.selectedField;
    final crop = _activeCrop(scope, field.crop);
    areaAcres = field.areaAcres.clamp(1, 20).toDouble();
    seasonalValuePerAcre = _defaultCropValue(crop);
    initialized = true;
  }

  String _activeCrop(AppScope scope, String fallback) {
    if (scope.sensors.source != SensorDataSource.esp32) return fallback;
    return scope.sensors.hardwareTelemetry?.cropProfile ??
        scope.sensors.edgeIntelligence?.cropProfile.profile ??
        fallback;
  }

  double _defaultCropValue(String crop) {
    final name = crop.toLowerCase();
    if (name.contains('rice') || name.contains('paddy')) return 60000;
    if (name.contains('tomato')) return 140000;
    return 80000;
  }

  void _reset() {
    final scope = AppScope.of(context);
    final field = scope.farms.selectedField;
    final crop = _activeCrop(scope, field.crop);
    setState(() {
      areaAcres = field.areaAcres.clamp(1, 20).toDouble();
      seasonalValuePerAcre = _defaultCropValue(crop);
      lossRiskPercent = 15;
      preventableSharePercent = 35;
      inputSavingsPerAcre = 1500;
      systemCost = 6000;
    });
  }

  String _money(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      ).format(value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scope = AppScope.of(context);
    final field = scope.farms.selectedField;
    final crop = _activeCrop(scope, field.crop);
    final projection = FarmImpactProjection(
      areaAcres: areaAcres,
      seasonalValuePerAcre: seasonalValuePerAcre,
      lossRiskPercent: lossRiskPercent,
      preventableSharePercent: preventableSharePercent,
      inputSavingsPerAcre: inputSavingsPerAcre,
      systemCost: systemCost,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D4C35), Color(0xFF21835C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('impact_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.tr('impact_subtitle'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.grass_outlined, size: 17),
                      label: Text(crop),
                    ),
                    Chip(
                      avatar: const Icon(Icons.landscape_outlined, size: 17),
                      label: Text(context.tr('impact_area_chip', {
                        'value': areaAcres.toStringAsFixed(1),
                      })),
                    ),
                    Chip(
                      avatar: const Icon(Icons.calculate_outlined, size: 17),
                      label: Text(context.tr('impact_projection_badge')),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 620;
                    final width = wide
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: width,
                          child: _ImpactMetric(
                            icon: Icons.shield_outlined,
                            label: context.tr('impact_loss_prevented'),
                            value: _money(projection.estimatedLossPrevented),
                            color: scheme.primary,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _ImpactMetric(
                            icon: Icons.water_drop_outlined,
                            label: context.tr('impact_input_savings'),
                            value: _money(projection.estimatedInputSavings),
                            color: const Color(0xFF2F85C8),
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _ImpactMetric(
                            icon: Icons.account_balance_wallet_outlined,
                            label: context.tr('impact_net_benefit'),
                            value: _money(projection.firstSeasonNetBenefit),
                            color: projection.firstSeasonNetBenefit >= 0
                                ? scheme.primary
                                : scheme.error,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _ImpactMetric(
                            icon: Icons.trending_up_rounded,
                            label: context.tr('impact_benefit_cost'),
                            value:
                                '${projection.benefitCostRatio.toStringAsFixed(1)}×',
                            color: scheme.tertiary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      _ImpactBreakdownRow(
                        label: context.tr('impact_season_value'),
                        value: _money(projection.seasonalCropValue),
                      ),
                      const SizedBox(height: 8),
                      _ImpactBreakdownRow(
                        label: context.tr('impact_value_at_risk'),
                        value: _money(projection.cropValueAtRisk),
                      ),
                      const SizedBox(height: 8),
                      _ImpactBreakdownRow(
                        label: context.tr('impact_gross_benefit'),
                        value: _money(projection.grossSeasonalBenefit),
                        strong: true,
                      ),
                      const SizedBox(height: 8),
                      _ImpactBreakdownRow(
                        label: context.tr('impact_system_cost'),
                        value: '− ${_money(projection.systemCost)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.tune_rounded),
                    title: Text(
                      context.tr('impact_adjust_title'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(context.tr('impact_adjust_body')),
                    children: [
                      _ImpactSlider(
                        label: context.tr('impact_area'),
                        valueText: context.tr('impact_acres_value', {
                          'value': areaAcres.toStringAsFixed(1),
                        }),
                        value: areaAcres,
                        minimum: 1,
                        maximum: 20,
                        divisions: 190,
                        onChanged: (value) => setState(() => areaAcres = value),
                      ),
                      _ImpactSlider(
                        label: context.tr('impact_crop_value_per_acre'),
                        valueText: _money(seasonalValuePerAcre),
                        value: seasonalValuePerAcre,
                        minimum: 20000,
                        maximum: 200000,
                        divisions: 36,
                        onChanged: (value) =>
                            setState(() => seasonalValuePerAcre = value),
                      ),
                      _ImpactSlider(
                        label: context.tr('impact_loss_risk'),
                        valueText: '${lossRiskPercent.toStringAsFixed(0)}%',
                        value: lossRiskPercent,
                        minimum: 5,
                        maximum: 30,
                        divisions: 25,
                        onChanged: (value) =>
                            setState(() => lossRiskPercent = value),
                      ),
                      _ImpactSlider(
                        label: context.tr('impact_preventable_share'),
                        valueText:
                            '${preventableSharePercent.toStringAsFixed(0)}%',
                        value: preventableSharePercent,
                        minimum: 10,
                        maximum: 60,
                        divisions: 25,
                        onChanged: (value) => setState(
                          () => preventableSharePercent = value,
                        ),
                      ),
                      _ImpactSlider(
                        label: context.tr('impact_savings_per_acre'),
                        valueText: _money(inputSavingsPerAcre),
                        value: inputSavingsPerAcre,
                        minimum: 0,
                        maximum: 5000,
                        divisions: 20,
                        onChanged: (value) =>
                            setState(() => inputSavingsPerAcre = value),
                      ),
                      _ImpactSlider(
                        label: context.tr('impact_cost_input'),
                        valueText: _money(systemCost),
                        value: systemCost,
                        minimum: 2000,
                        maximum: 15000,
                        divisions: 26,
                        onChanged: (value) =>
                            setState(() => systemCost = value),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: Text(context.tr('impact_reset')),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.fact_check_outlined,
                          color: scheme.tertiary, size: 20),
                      const SizedBox(width: 9),
                      Expanded(child: Text(context.tr('impact_disclaimer'))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ImpactMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ImpactBreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _ImpactBreakdownRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              color: strong ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      );
}

class _ImpactSlider extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double minimum;
  final double maximum;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _ImpactSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  valueText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: minimum,
              max: maximum,
              divisions: divisions,
              label: valueText,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}

class _AboutSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final List<String> bullets;

  const _AboutSection({
    required this.icon,
    required this.title,
    required this.body,
    this.bullets = const [],
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(body),
              for (final bullet in bullets) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_rounded,
                          size: 17, color: phytoLeaf),
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(bullet)),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
}
