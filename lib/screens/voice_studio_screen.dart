import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/phone_voice.dart';
import '../services/voice_names.dart';
import '../services/voice_guidance_service.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';

class VoiceStudioScreen extends StatefulWidget {
  const VoiceStudioScreen({super.key});
  @override
  State<VoiceStudioScreen> createState() => _VoiceStudioScreenState();
}

class _VoiceStudioScreenState extends State<VoiceStudioScreen>
    with WidgetsBindingObserver {
  double rate = .47;
  bool internet = false, loading = true;
  String language = 'en', selected = '';
  List<PhoneVoice> voices = [];
  Map<String, String> names = {};
  VoiceGuidanceService? voice;
  int generation = 0;
  String t(String en, String ta) => FarmerLanguage.isTamil(context) ? ta : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (voice == null) {
      voice = AppScope.of(context).voice;
      language = AppScope.of(context).settings.value.languageCode == 'ta'
          ? 'ta'
          : 'en';
      _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
    if (state == AppLifecycleState.paused) {
      voice?.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final service = voice;
    if (service != null) {
      Future.microtask(service.stop);
    }
    super.dispose();
  }

  Future<void> _load() async {
    final ticket = ++generation;
    if (mounted) {
      setState(() => loading = true);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('phyto.internetPhoneVoice') ?? false;
      final list =
          await voice!.availablePhoneVoices(language, allowInternet: enabled);
      if (!mounted) return;
      final aliases = await VoiceNames.forVoices(list, language,
          tamilLabels: FarmerLanguage.isTamil(context));
      if (!mounted || ticket != generation) {
        return;
      }
      final saved = prefs.getString('phyto.phoneVoice.$language') ?? '';
      setState(() {
        rate = (prefs.getDouble('phyto.voiceRate') ?? .47)
            .clamp(.32, .55)
            .toDouble();
        internet = enabled;
        voices = list;
        names = aliases;
        selected = list.any((v) => v.name == saved) ? saved : '';
        loading = false;
      });
    } catch (_) {
      if (mounted && ticket == generation) {
        setState(() {
          voices = [];
          loading = false;
        });
      }
    }
  }

  Future<void> _sample() async {
    if (voice!.speaking) {
      await voice!.stop();
      return;
    }
    final ok = await voice!.speak(
      text: language == 'ta'
          ? 'இது ஒரு குரல் மாதிரி. உதாரணமாக, மண் உலர்ந்திருந்தால், வேர் அருகே மெதுவாகத் தண்ணீர் ஊற்றுங்கள். இது உங்கள் செடியின் தற்போதைய நிலை அல்ல.'
          : 'This is a voice sample. For example, if the soil is dry, water slowly near the roots. This is not a reading from your plant.',
      languageCode: language,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t(
              'This voice could not play. Try another voice or check phone voice settings.',
              'இந்தக் குரல் இயங்கவில்லை. வேறு குரலைத் தேர்வு செய்யவும் அல்லது தொலைபேசி குரல் அமைப்பைப் பார்க்கவும்.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(t('Choose your voice', 'குரலைத் தேர்ந்தெடுக்கவும்'))),
      body: PageFrame(children: [
        PhytoPageIntro(
          eyebrow: t('NO PAID VOICE SERVICE', 'கட்டண குரல் சேவை இல்லை'),
          title: t('Hear it your way', 'உங்களுக்கு ஏற்ற குரல்'),
          body: t(
              'Listen to a sample and choose the clearest voice. English and Tamil remember separate choices.',
              'மாதிரியைக் கேட்டு தெளிவான குரலைத் தேர்வு செய்யுங்கள். ஆங்கிலம், தமிழ் குரல்கள் தனித்தனியாக சேமிக்கப்படும்.'),
          icon: Icons.record_voice_over_outlined,
        ),
        const SizedBox(height: 24),
        PhytoSurface(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'ta', label: Text('தமிழ்')),
                ],
                selected: {language},
                onSelectionChanged: (choice) async {
                  await voice!.stop();
                  if (!mounted) {
                    return;
                  }
                  setState(() => language = choice.first);
                  await _load();
                },
              ),
              const SizedBox(height: 20),
              if (loading)
                const LinearProgressIndicator()
              else if (voices.isEmpty)
                Text(t(
                    'No usable voice was found for this language. Open phone voice settings, install language data, then refresh.',
                    'இந்த மொழிக்கான குரல் கிடைக்கவில்லை. தொலைபேசி குரல் அமைப்பில் மொழித் தரவை நிறுவி, புதுப்பிக்கவும்.'))
              else
                DropdownButtonFormField<String>(
                  key: ValueKey('$language-$selected-$internet'),
                  initialValue: selected,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t('Voice', 'குரல்')),
                  items: [
                    DropdownMenuItem(
                        value: '',
                        child: Text(
                            t('Automatic · highest reported quality',
                                'தானியங்கி · சிறந்த தரம்'),
                            overflow: TextOverflow.ellipsis)),
                    for (var i = 0; i < voices.length; i++)
                      DropdownMenuItem(
                          value: voices[i].name,
                          child: Text(
                              '${names[voices[i].name] ?? t('Voice', 'குரல்')} · ${voices[i].locale} · ${voices[i].needsInternet ? t('Internet', 'இணையம்') : t('Offline', 'இணையம் தேவையில்லை')}',
                              overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (value) async {
                    await voice!
                        .selectPhoneVoice(language, value == '' ? null : value);
                    if (mounted) {
                      setState(() => selected = value ?? '');
                    }
                  },
                ),
              const SizedBox(height: 18),
              AnimatedBuilder(
                  animation: voice!,
                  builder: (_, __) => FilledButton.icon(
                        onPressed: loading || voices.isEmpty ? null : _sample,
                        icon: Icon(voice!.speaking
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded),
                        label: Text(voice!.speaking
                            ? t('Stop', 'நிறுத்து')
                            : t('Hear a sample', 'மாதிரியைக் கேளுங்கள்')),
                      )),
              const SizedBox(height: 8),
              Text(
                  t('Nila, Malar and the other names are friendly labels for your phone’s voices. Listen to choose; the names do not change the sound.',
                      'நிலா, மலர் போன்ற பெயர்கள் தொலைபேசி குரல்களை எளிதில் தேர்வு செய்வதற்கானவை. பெயர் மாறுவதால் ஒலி மாறாது. மாதிரியைக் கேட்டுத் தேர்வு செய்யுங்கள்.'),
                  style: theme.textTheme.bodySmall),
            ])),
        const SizedBox(height: 16),
        PhytoSurface(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('Speaking speed', 'பேசும் வேகம்'),
              style: theme.textTheme.titleLarge),
          Slider(
              value: rate,
              min: .32,
              max: .55,
              divisions: 23,
              label:
                  rate < .4 ? t('Slower', 'மெதுவாக') : t('Normal', 'சாதாரணம்'),
              onChanged: (v) => setState(() => rate = v),
              onChangeEnd: (v) async {
                await (await SharedPreferences.getInstance())
                    .setDouble('phyto.voiceRate', v);
              }),
          Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t('Allow internet-dependent phone voices',
                      'இணையம் தேவைப்படும் குரல்களை அனுமதி')),
                  subtitle: Text(t(
                      'Optional. Your phone speech provider may receive the advice text. Internet data may cost money. No paid PhytoSense API is used.',
                      'விருப்பம். தொலைபேசி குரல் சேவைக்கு ஆலோசனை உரை அனுப்பப்படலாம். இணையத் தரவுக்குக் கட்டணம் இருக்கலாம். கட்டண PhytoSense API பயன்படுத்தப்படாது.')),
                  value: internet,
                  onChanged: (value) async {
                    await voice!.stop();
                    await (await SharedPreferences.getInstance())
                        .setBool('phyto.internetPhoneVoice', value);
                    await _load();
                  })),
        ])),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              await const MethodChannel('com.harjeet.phytosense/care')
                  .invokeMethod('openVoiceSettings');
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(t(
                        'Open Text-to-speech in your phone settings.',
                        'தொலைபேசி அமைப்பில் உரை-குரல் பகுதியைத் திறக்கவும்.'))));
              }
            }
          },
          icon: const Icon(Icons.settings_voice_outlined),
          label: Text(t('Phone voice settings', 'தொலைபேசி குரல் அமைப்பு')),
        ),
        TextButton.icon(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t(
                'Refresh available voices', 'கிடைக்கும் குரல்களைப் புதுப்பி'))),
      ]),
    );
  }
}
