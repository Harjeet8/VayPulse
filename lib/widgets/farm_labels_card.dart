import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../ml/plant_disease_catalog.dart';
import '../screens/leaf_check_screen.dart';
import '../services/farm_label_service.dart';
import '../services/farmer_language.dart';

String _t(BuildContext context, String en, String ta) =>
    FarmerLanguage.isTamil(context) ? ta : en;

/// (emoji, English, Tamil) for each label type.
const labelText = <String, (String, String, String)>{
  'watered': ('💧', 'I watered', 'நீர் ஊற்றினேன்'),
  'fertilizer': ('🌱', 'Added fertilizer', 'உரம் இட்டேன்'),
  'wilted': ('🥀', 'Plant looks wilted', 'செடி வாடியுள்ளது'),
  'spots': ('🟤', 'Leaves have spots', 'இலைகளில் புள்ளிகள்'),
  'healthy': ('✅', 'Plant looks healthy', 'செடி நன்றாக உள்ளது'),
  'pests': ('🐛', 'Pests seen', 'பூச்சிகள் தெரிகின்றன'),
  'leaf_check': ('🍃', 'Leaf check', 'இலை சோதனை'),
};

/// Big "Check a leaf" button for Home and the Camera tab.
class LeafCheckEntryCard extends StatelessWidget {
  const LeafCheckEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        key: const Key('open-leaf-check'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => LeafCheckScreen.open(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const Text('🍃', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_t(context, 'Check a leaf', 'இலையைச் சோதி'),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    _t(context, 'Photo → disease check. Works offline.',
                        'படம் → நோய்ச் சோதனை. இணையம் தேவையில்லை.'),
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.primary, size: 32),
          ]),
        ),
      ),
    );
  }
}

/// "What did you do / see?" one-tap labels.
class FarmLabelsCard extends StatefulWidget {
  const FarmLabelsCard({super.key});

  @override
  State<FarmLabelsCard> createState() => _FarmLabelsCardState();
}

class _FarmLabelsCardState extends State<FarmLabelsCard> {
  final service = FarmLabelService.instance;
  String? justSaved;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    service.addListener(_changed);
    unawaited(service.start());
  }

  @override
  void dispose() {
    service.removeListener(_changed);
    _hide?.cancel();
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _tap(String type) async {
    await service.record(type);
    if (!mounted) return;
    setState(() => justSaved = type);
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => justSaved = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final scheme = Theme.of(context).colorScheme;
    final today = service.today();
    final pending = service.pendingCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              _t(context, 'What did you do / see?',
                  'என்ன செய்தீர்கள் / பார்த்தீர்கள்?'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              _t(context, 'One tap. This helps VayPulse learn your plants.',
                  'ஒரே தொடுதல். இது VayPulse உங்கள் செடிகளைக் கற்க உதவும்.'),
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: [
              for (final type in FarmLabelService.types)
                Material(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    key: Key('label-$type'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _tap(type),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(labelText[type]!.$1,
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 4),
                            Text(
                                tamil
                                    ? labelText[type]!.$3
                                    : labelText[type]!.$2,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ),
                ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: justSaved == null
                ? const SizedBox(height: 8)
                : Padding(
                    key: const Key('label-saved'),
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text(_t(context, '✓ Saved', '✓ சேமிக்கப்பட்டது'),
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
          ),
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Icon(Icons.cloud_upload_outlined,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      _t(context, '$pending waiting — will send when online',
                          '$pending காத்திருக்கிறது — இணையம் வந்ததும் அனுப்பப்படும்'),
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ]),
            ),
          const SizedBox(height: 10),
          Text(_t(context, 'Today', 'இன்று'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (today.isEmpty)
            Text(
                _t(context, 'Nothing recorded today.',
                    'இன்று எதுவும் பதிவு இல்லை.'),
                style: TextStyle(color: scheme.onSurfaceVariant))
          else
            for (final e in today.take(12))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Text(labelText[e.type]?.$1 ?? '•',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_eventText(context, e, tamil))),
                  Text(DateFormat('h:mm a').format(e.time),
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 6),
                  Icon(
                      e.sent
                          ? Icons.cloud_done_rounded
                          : Icons.schedule_rounded,
                      size: 18,
                      color: e.sent ? Colors.green.shade600 : scheme.outline),
                ]),
              ),
        ]),
      ),
    );
  }

  String _eventText(BuildContext context, LabelEvent e, bool tamil) {
    final base = labelText[e.type];
    final name = base == null ? e.type : (tamil ? base.$3 : base.$2);
    if (e.type != 'leaf_check') return name;
    final crop = PlantDiseaseCatalog.crop('${e.payload['crop']}');
    return '$name · ${crop?.name.of(tamil) ?? e.payload['crop']}';
  }
}
