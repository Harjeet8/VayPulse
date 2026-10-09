import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../ml/leaf_classifier.dart';
import '../ml/plant_disease_catalog.dart';
import '../services/farm_label_service.dart';
import '../services/farmer_language.dart';
import '../services/leaf_check_history.dart';
import '../widgets/page_frame.dart';

String _t(BuildContext context, String en, String ta) =>
    FarmerLanguage.isTamil(context) ? ta : en;

/// Human words for confidence; the farmer never sees raw numbers.
String confidenceWord(BuildContext context, double c) => c >= 0.85
    ? _t(context, 'High', 'அதிகம்')
    : c >= 0.60
        ? _t(context, 'Medium', 'நடுத்தரம்')
        : _t(context, 'Low', 'குறைவு');

/// Entry: big "Check a leaf" button + saved leaf checks.
class LeafCheckScreen extends StatefulWidget {
  const LeafCheckScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LeafCheckScreen()));

  @override
  State<LeafCheckScreen> createState() => _LeafCheckScreenState();
}

class _LeafCheckScreenState extends State<LeafCheckScreen> {
  final history = LeafCheckHistory.instance;

  @override
  void initState() {
    super.initState();
    history.addListener(_changed);
    unawaited(history.load());
  }

  @override
  void dispose() {
    history.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _start() async {
    final crop = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const _CropPickPage()));
    if (crop == null || !mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => _PhotoGuidePage(cropKey: crop)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = history.items;
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'Leaf check', 'இலை சோதனை'))),
      body: PageFrame(children: [
        SizedBox(
          height: 76,
          child: FilledButton.icon(
            key: const Key('check-a-leaf'),
            onPressed: _start,
            icon: const Icon(Icons.eco_rounded, size: 30),
            label: Text(_t(context, 'Check a leaf', 'இலையைச் சோதி'),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
            _t(context, 'Works without internet. The photo stays on your phone.',
                'இணையம் இல்லாமலும் வேலை செய்யும். படம் உங்கள் போனிலேயே இருக்கும்.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 22),
        Text(_t(context, 'Leaf checks', 'இலை சோதனைகள்'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(_t(context, 'No leaf checks yet.', 'இன்னும் இலை சோதனை இல்லை.'),
              style: TextStyle(color: scheme.onSurfaceVariant))
        else
          for (final r in items) _HistoryTile(record: r),
      ]),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final LeafCheckRecord record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final crop = PlantDiseaseCatalog.crop(record.crop);
    ConditionInfo? condition;
    for (final c in PlantDiseaseCatalog.conditions) {
      if (c.cropKey == record.crop && c.conditionKey == record.result) {
        condition = c;
      }
    }
    final title = condition?.name.of(tamil) ??
        switch (record.result) {
          'other_crop' => _t(context, 'Looked like another crop',
              'வேறு பயிர் போலத் தெரிந்தது'),
          _ => _t(context, 'Not sure', 'உறுதியாகத் தெரியவில்லை'),
        };
    final healthy = condition?.healthy == true;
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: record.thumbnail == null
              ? const SizedBox(width: 52, height: 52, child: Icon(Icons.eco))
              : Image.memory(record.thumbnail!,
                  width: 52, height: 52, fit: BoxFit.cover),
        ),
        title: Text('${crop?.emoji ?? '🌿'} $title',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: healthy ? Colors.green.shade700 : null)),
        subtitle: Text('${crop?.name.of(tamil) ?? record.crop} · '
            '${DateFormat('d MMM, h:mm a').format(record.time)} · '
            '${confidenceWord(context, record.confidence)}'),
      ),
    );
  }
}

/// Step 1: pick the crop, so the app never guesses across crops.
class _CropPickPage extends StatelessWidget {
  const _CropPickPage();

  @override
  Widget build(BuildContext context) {
    final tamil = FarmerLanguage.isTamil(context);
    final scheme = Theme.of(context).colorScheme;
    Widget tile(String emoji, String name, VoidCallback onTap,
            {bool supported = true, Key? key}) =>
        Material(
          key: key,
          color: supported
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(height: 4),
                Text(name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'Which crop?', 'எந்தப் பயிர்?'))),
      body: PageFrame(children: [
        Text(_t(context, 'Tap your crop', 'உங்கள் பயிரைத் தொடுங்கள்'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            for (final c in PlantDiseaseCatalog.supportedCrops)
              tile(c.emoji, c.name.of(tamil),
                  () => Navigator.pop(context, c.key),
                  key: Key('crop-${c.key}')),
          ],
        ),
        const SizedBox(height: 22),
        Text(_t(context, 'Not supported yet', 'இன்னும் ஆதரவு இல்லை'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
            _t(context,
                'The leaf model has not learned these crops, so it cannot check them.',
                'இந்தப் பயிர்களை இலை மாதிரி இன்னும் கற்கவில்லை, அதனால் சோதிக்க முடியாது.'),
            style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            for (final c in PlantDiseaseCatalog.unsupportedCrops)
              tile(c.emoji, c.name.of(tamil),
                  () => _notSupported(context, c.name.of(tamil)),
                  supported: false, key: Key('unsupported-${c.key}')),
          ],
        ),
      ]),
    );
  }

  void _notSupported(BuildContext context, String crop) => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.info_outline_rounded),
          title: Text(_t(context, '$crop is not supported yet',
              '$crop இன்னும் ஆதரிக்கப்படவில்லை')),
          content: Text(_t(context,
              'The leaf check has not learned $crop leaves, so it would only guess. We will not show a guess. Please show the leaf to your agriculture officer.',
              'இலை சோதனை $crop இலைகளைக் கற்கவில்லை; ஊகம் மட்டுமே செய்யும். ஊகத்தைக் காட்ட மாட்டோம். இலையை வேளாண் அலுவலரிடம் காட்டுங்கள்.')),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_t(context, 'OK', 'சரி'))),
          ],
        ),
      );
}

/// Step 2: short photo guide, then camera or gallery.
class _PhotoGuidePage extends StatelessWidget {
  final String cropKey;
  const _PhotoGuidePage({required this.cropKey});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
          source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 92);
      if (file == null || !context.mounted) return;
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => LeafResultPage(cropKey: cropKey, photo: bytes)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_t(context, 'Could not open the camera or photos.',
              'கேமரா அல்லது படங்களைத் திறக்க முடியவில்லை.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tips = [
      ('🍃', _t(context, 'One leaf only', 'ஒரே ஒரு இலை')),
      ('🔍', _t(context, 'Fill the frame with the leaf', 'இலை படம் முழுவதும் தெரியட்டும்')),
      ('⬜', _t(context, 'Plain background (paper or cloth)', 'சாதாரணப் பின்னணி (தாள் அல்லது துணி)')),
      ('☀️', _t(context, 'Daylight, not direct harsh sun', 'பகல் வெளிச்சம்; கடும் வெயில் வேண்டாம்')),
      ('✋', _t(context, 'Hold still — no blur', 'அசையாமல் பிடியுங்கள் — மங்கல் வேண்டாம்')),
    ];
    return Scaffold(
      appBar: AppBar(
          title: Text(_t(context, 'Take a good photo', 'நல்ல படம் எடுங்கள்'))),
      body: PageFrame(children: [
        for (final tip in tips)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Text(tip.$1, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(tip.$2,
                      style: Theme.of(context).textTheme.titleMedium)),
            ]),
          ),
        const SizedBox(height: 18),
        SizedBox(
          height: 64,
          child: FilledButton.icon(
              key: const Key('leaf-camera'),
              onPressed: () => _pick(context, ImageSource.camera),
              icon: const Icon(Icons.photo_camera_rounded, size: 28),
              label: Text(_t(context, 'Take photo', 'படம் எடு'),
                  style: const TextStyle(fontSize: 19))),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
              key: const Key('leaf-gallery'),
              onPressed: () => _pick(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: Text(_t(context, 'Choose from photos',
                  'படங்களில் இருந்து தேர்வு'))),
        ),
      ]),
    );
  }
}

/// Step 3: runs the model and shows the result.
class LeafResultPage extends StatefulWidget {
  final String cropKey;
  final Uint8List photo;
  const LeafResultPage({super.key, required this.cropKey, required this.photo});

  @override
  State<LeafResultPage> createState() => _LeafResultPageState();
}

class _LeafResultPageState extends State<LeafResultPage> {
  LeafDiagnosis? diagnosis;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      final run = await LeafClassifier.run(widget.photo);
      final d = LeafClassifier.diagnose(run.probs, run.labels, widget.cropKey);
      if (!mounted) return;
      setState(() => diagnosis = d);
      final t = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      await LeafCheckHistory.instance.add(LeafCheckRecord(
          t: t,
          crop: widget.cropKey,
          result: d.resultKey,
          confidence: d.confidence,
          thumbnail: run.thumbnail));
      await FarmLabelService.instance.recordLeafCheck(
          crop: widget.cropKey, result: d.resultKey, confidence: d.confidence);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  void _again() => Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => _PhotoGuidePage(cropKey: widget.cropKey)));

  @override
  Widget build(BuildContext context) {
    final d = diagnosis;
    return Scaffold(
      appBar: AppBar(
          title: Text(_t(context, 'Leaf check result', 'இலை சோதனை முடிவு'))),
      body: PageFrame(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
              aspectRatio: 1,
              child: Image.memory(widget.photo, fit: BoxFit.cover)),
        ),
        const SizedBox(height: 16),
        if (failed)
          _MessageCard(
              color: Colors.orange,
              icon: Icons.broken_image_outlined,
              title: _t(context, 'Could not read this photo',
                  'இந்தப் படத்தைப் படிக்க முடியவில்லை'),
              body: _t(context, 'Please take the photo again.',
                  'மீண்டும் படம் எடுங்கள்.'))
        else if (d == null)
          const _Checking()
        else
          ..._result(context, d),
        const SizedBox(height: 16),
        const _GuideNote(),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
              onPressed: _again,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_t(
                  context, 'Check another leaf', 'இன்னொரு இலையைச் சோதி'))),
        ),
      ]),
    );
  }

  List<Widget> _result(BuildContext context, LeafDiagnosis d) {
    final tamil = FarmerLanguage.isTamil(context);
    final crop = PlantDiseaseCatalog.crop(d.cropKey);
    final cropName = crop?.name.of(tamil) ?? d.cropKey;
    switch (d.verdict) {
      case LeafVerdict.unsure:
        return [
          _MessageCard(
              key: const Key('leaf-unsure'),
              color: Colors.orange,
              icon: Icons.help_outline_rounded,
              title: _t(context,
                  'Not sure – please take a clearer photo of one leaf',
                  'உறுதியாகத் தெரியவில்லை – ஒரு இலையைத் தெளிவாக மீண்டும் படம் எடுங்கள்'),
              body: _t(context,
                  'Follow the photo tips: one leaf, fill the frame, plain background, daylight.',
                  'படக் குறிப்புகளைப் பின்பற்றுங்கள்: ஒரு இலை, படம் முழுவதும், சாதாரணப் பின்னணி, பகல் வெளிச்சம்.')),
        ];
      case LeafVerdict.otherCrop:
        final other = d.looksLike!.name.of(tamil);
        return [
          _MessageCard(
              key: const Key('leaf-other-crop'),
              color: Colors.orange,
              icon: Icons.swap_horiz_rounded,
              title: _t(context, 'This does not look like a $cropName leaf',
                  'இது $cropName இலை போலத் தெரியவில்லை'),
              body: _t(context,
                  'It looks more like $other. Check that you picked the right crop, then try again.',
                  'இது $other போலத் தெரிகிறது. சரியான பயிரைத் தேர்வு செய்தீர்களா எனப் பார்த்து மீண்டும் முயலுங்கள்.')),
        ];
      case LeafVerdict.unsupportedCrop:
        return [
          _MessageCard(
              color: Colors.grey,
              icon: Icons.info_outline,
              title: _t(context, 'This crop is not supported yet',
                  'இந்தப் பயிர் இன்னும் ஆதரிக்கப்படவில்லை'),
              body: ''),
        ];
      case LeafVerdict.confident:
        final best = d.best!;
        return [
          if (best.healthy)
            _MessageCard(
                key: const Key('leaf-healthy'),
                color: Colors.green,
                icon: Icons.check_circle_rounded,
                title: _t(context, 'Leaf looks healthy',
                    'இலை ஆரோக்கியமாகத் தெரிகிறது'),
                body: '${crop?.emoji ?? ''} $cropName')
          else
            _MessageCard(
                key: const Key('leaf-disease'),
                color: Colors.deepOrange,
                icon: Icons.coronavirus_outlined,
                title: '${crop?.emoji ?? ''} $cropName — ${best.name.of(tamil)}',
                // The other language underneath, as asked.
                body: '${crop?.name.of(!tamil) ?? ''} — ${best.name.of(!tamil)}'),
          const SizedBox(height: 12),
          _ConfidenceBar(value: d.confidence),
          const SizedBox(height: 16),
          Text(_t(context, 'What to do', 'என்ன செய்ய வேண்டும்'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final line in PlantDiseaseCatalog.advice(best, tamil: tamil))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('•  ', style: TextStyle(fontSize: 18)),
                Expanded(
                    child: Text(line,
                        style: Theme.of(context).textTheme.bodyLarge)),
              ]),
            ),
          if (d.top3.length > 1) ...[
            const SizedBox(height: 16),
            Text(_t(context, 'Other possibilities', 'மற்ற வாய்ப்புகள்'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final e in d.top3)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(flex: 5, child: Text(e.$1.name.of(tamil))),
                  Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                            value: e.$2.clamp(0.0, 1.0), minHeight: 10),
                      )),
                ]),
              ),
          ],
        ];
    }
  }
}

class _Checking extends StatelessWidget {
  const _Checking();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(_t(context, 'Checking the leaf…', 'இலையைச் சோதிக்கிறது…')),
        ]),
      );
}

class _ConfidenceBar extends StatelessWidget {
  final double value;
  const _ConfidenceBar({required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text('${_t(context, 'How sure', 'உறுதி')}: ',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                key: const Key('leaf-confidence-bar'),
                value: value.clamp(0.0, 1.0),
                minHeight: 14),
          ),
        ),
        const SizedBox(width: 10),
        Text(confidenceWord(context, value),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ]);
}

class _MessageCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title, body;
  const _MessageCard(
      {super.key,
      required this.color,
      required this.icon,
      required this.title,
      required this.body});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ]),
          ),
        ]),
      );
}

class _GuideNote extends StatelessWidget {
  const _GuideNote();
  @override
  Widget build(BuildContext context) {
    final muted =
        TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          key: const Key('leaf-guide-note'),
          _t(context, 'This is a guide, not a lab diagnosis.',
              'இது ஒரு வழிகாட்டி மட்டுமே, ஆய்வக முடிவு அல்ல.'),
          style: muted.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(
          _t(context,
              'The check learned from lab photos, so field photos can be less accurate. Good photos help.',
              'இந்தச் சோதனை ஆய்வகப் படங்களில் கற்றது; வயல் படங்களில் துல்லியம் குறையலாம். நல்ல படம் உதவும்.'),
          style: muted),
    ]);
  }
}
