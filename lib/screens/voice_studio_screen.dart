import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../widgets/page_frame.dart';
import '../widgets/phyto_ui.dart';

class VoiceStudioScreen extends StatefulWidget {
  const VoiceStudioScreen({super.key});
  @override
  State<VoiceStudioScreen> createState() => _VoiceStudioScreenState();
}

class _VoiceStudioScreenState extends State<VoiceStudioScreen> {
  double rate = .47;
  bool consent = false;
  String t(String en, String ta) => FarmerLanguage.isTamil(context) ? ta : en;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted)
      setState(() {
        rate = p.getDouble('phyto.voiceRate') ?? .47;
        consent = p.getBool('phyto.cloudVoiceConsent') ?? false;
      });
  }

  @override
  Widget build(BuildContext context) {
    final voice = AppScope.of(context).voice;
    return Scaffold(
        appBar: AppBar(title: Text(t('Voice guidance', 'குரல் வழிகாட்டுதல்'))),
        body: PageFrame(children: [
          PhytoPageIntro(
              eyebrow: t('LISTEN. UNDERSTAND. CARE.',
                  'கேளுங்கள். புரிந்துகொள்ளுங்கள்.'),
              title: t('Advice you can hear', 'கேட்கக்கூடிய ஆலோசனை'),
              body: t(
                  'Hear the plant condition, the problem, and what to do next.',
                  'செடியின் நிலை, பிரச்சினை, அடுத்து என்ன செய்வது என்பதைக் கேளுங்கள்.'),
              icon: Icons.record_voice_over_outlined),
          const SizedBox(height: 24),
          PhytoSurface(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(t('Natural cloud voice', 'இயல்பான இணையக் குரல்'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(voice.cloudConfigured
                    ? t('With your permission, advice text is sent to our voice service and ElevenLabs to generate audio. Internet is required.',
                        'உங்கள் அனுமதியுடன் ஆலோசனை உரை குரல் சேவைக்கும் ElevenLabs-க்கும் அனுப்பப்படும். இணையம் தேவை.')
                    : t('Cloud voice is not activated in this build. Phone voice is available.',
                        'இந்தப் பதிப்பில் இணையக் குரல் செயல்படுத்தப்படவில்லை. தொலைபேசி குரல் கிடைக்கும்.')),
                if (voice.cloudConfigured)
                  SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                          t('Use cloud voice', 'இணையக் குரலைப் பயன்படுத்து')),
                      value: consent,
                      onChanged: (v) async {
                        await (await SharedPreferences.getInstance())
                            .setBool('phyto.cloudVoiceConsent', v);
                        if (mounted) setState(() => consent = v);
                      }),
              ])),
          const SizedBox(height: 16),
          PhytoSurface(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(t('Phone voice speed', 'தொலைபேசி குரல் வேகம்'),
                    style: Theme.of(context).textTheme.titleLarge),
                Slider(
                    value: rate,
                    min: .32,
                    max: .55,
                    divisions: 23,
                    label: rate < .4
                        ? t('Slower', 'மெதுவாக')
                        : t('Normal', 'சாதாரணம்'),
                    onChanged: (v) => setState(() => rate = v),
                    onChangeEnd: (v) async {
                      await (await SharedPreferences.getInstance())
                          .setDouble('phyto.voiceRate', v);
                    }),
                Text(t(
                    'Voice quality depends on the speech voices installed on your phone.',
                    'குரல் தரம் உங்கள் தொலைபேசியில் உள்ள குரல்களைப் பொறுத்தது.')),
              ])),
          const SizedBox(height: 20),
          AnimatedBuilder(
              animation: voice,
              builder: (_, __) => FilledButton.icon(
                  onPressed: () async {
                    if (voice.speaking) {
                      await voice.stop();
                      return;
                    }
                    final ok = await voice.speak(
                        text: t(
                            'This is a voice sample. PhytoSense explains the plant condition first, then the problem, and what to do next.',
                            'இது ஒரு குரல் மாதிரி. முதலில் செடியின் நிலை, பிறகு பிரச்சினை, அடுத்து என்ன செய்வது என்று விளக்கப்படும்.'),
                        languageCode:
                            AppScope.of(context).settings.value.languageCode);
                    if (!ok && context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              t('Voice unavailable', 'குரல் கிடைக்கவில்லை'))));
                  },
                  icon: Icon(voice.speaking
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(voice.speaking
                      ? t('Stop', 'நிறுத்து')
                      : t('Hear a sample', 'மாதிரியைக் கேளுங்கள்')))),
        ]));
  }
}
