import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ml/plant_disease_catalog.dart';
import '../services/farm_label_service.dart';
import '../services/ilai_brain.dart';
import '../services/leaf_check_history.dart';
import 'leaf_check_screen.dart';
import '../services/app_scope.dart';
import '../services/farmer_language.dart';
import '../services/firmware_text_adapter.dart';
import '../services/ilai_guide.dart';
import '../services/ilai_speech.dart';
import '../services/sensor_data_provider.dart';
import '../services/voice_guidance_service.dart';
import '../widgets/ilai_avatar.dart';
import 'voice_studio_screen.dart';

class IlaiScreen extends StatefulWidget {
  const IlaiScreen({super.key});
  @override
  State<IlaiScreen> createState() => _IlaiScreenState();
}

class _IlaiScreenState extends State<IlaiScreen> with WidgetsBindingObserver {
  final input = TextEditingController();
  final scroll = ScrollController();
  final speech = IlaiSpeech();
  final messages = <({String text, bool user, DateTime time, bool leaf})>[];
  final brain = IlaiBrain();
  List<String> suggestions = const [];
  bool typing = false;
  SensorDataProvider? sensors;
  VoiceGuidanceService? voice;
  SensorDataSource? previousSource;
  bool previousReady = false, readAloud = false;
  int generation = 0;
  String? notice;
  bool get currentFindingAvailable =>
      sensors!.current != null &&
      sensors!.edgeIntelligence?.firmwareCompatible == true &&
      (sensors!.source == SensorDataSource.simulation ||
          sensors!.connectionStatus == SensorConnectionStatus.ready);
  bool get tamil => FarmerLanguage.isTamil(context);
  String t(String en, String ta) => tamil ? ta : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (sensors == null) {
      final scope = AppScope.of(context);
      sensors = scope.sensors;
      voice = scope.voice;
      previousSource = sensors!.source;
      previousReady = currentFindingAvailable;
      sensors!.addListener(_sourceChanged);
    }
  }

  void _sourceChanged() {
    if (!mounted) return;
    final ready = currentFindingAvailable;
    if (previousSource != sensors!.source || (previousReady && !ready)) {
      generation++;
      unawaited(voice!.stop());
      unawaited(speech.cancel());
      messages.clear();
      notice = t(
          'The data source or connection changed. Ask again for a current answer.',
          'தரவு மூலம் அல்லது இணைப்பு மாறியுள்ளது. தற்போதைய பதிலுக்கு மீண்டும் கேளுங்கள்.');
    }
    previousSource = sensors!.source;
    previousReady = ready;
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      generation++;
      unawaited(speech.cancel());
      unawaited(voice!.stop());
    }
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    sensors?.removeListener(_sourceChanged);
    speech.dispose();
    final service = voice;
    if (service != null) Future.microtask(service.stop);
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  IlaiSnapshot _snapshot() {
    final data = sensors!;
    final edge = data.edgeIntelligence;
    final reading = data.current;
    final simulation = data.source == SensorDataSource.simulation;
    if (reading == null ||
        edge == null ||
        !edge.firmwareCompatible ||
        (!simulation &&
            data.connectionStatus != SensorConnectionStatus.ready)) {
      return IlaiSnapshot(available: false, simulation: simulation);
    }
    String words(String? raw) => FirmwareTextAdapter.text(context, raw);
    return IlaiSnapshot(
        available: true,
        simulation: simulation,
        condition: FarmerLanguage.firmware(context, edge.plantState),
        problem: words(edge.rootCause.primary ?? edge.farmerSummary),
        action: words(edge.recommendation),
        reason: words(
            edge.rootCause.primaryCandidate?.evidenceFor ?? edge.farmerSummary),
        timestamp: reading.timestamp);
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !scroll.hasClients) return;
        if (MediaQuery.disableAnimationsOf(context)) {
          scroll.jumpTo(scroll.position.maxScrollExtent);
        } else {
          scroll.animateTo(scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut);
        }
      });
  IlaiContext _context() {
    final snapshot = _snapshot();
    final reading = sensors!.current;
    final live = snapshot.available && reading != null;
    final last = LeafCheckHistory.instance.latest;
    String? leafCrop, leafResult;
    var leafHealthy = false;
    if (last != null) {
      leafCrop =
          PlantDiseaseCatalog.crop(last.crop)?.name.of(tamil) ?? last.crop;
      for (final c in PlantDiseaseCatalog.conditions) {
        if (c.cropKey == last.crop && c.conditionKey == last.result) {
          leafResult = c.name.of(tamil);
          leafHealthy = c.healthy;
        }
      }
      leafResult ??= last.result == 'other_crop'
          ? t('looked like another crop', 'வேறு பயிர் போலத் தெரிந்தது')
          : t('not sure (unclear photo)', 'உறுதியில்லை (தெளிவற்ற படம்)');
    }
    final labels = FarmLabelService.instance;
    return IlaiContext(
      snapshot: snapshot,
      soilMoisture: live ? reading.soilMoisture : null,
      temperature: live ? reading.temperature : null,
      humidity: live ? reading.humidity : null,
      lastLeafCrop: leafCrop,
      lastLeafResult: leafResult,
      lastLeafHealthy: leafHealthy,
      lastLeafTime: last?.time,
      labelsToday: labels.today().length,
      labelsPending: labels.pendingCount,
      now: DateTime.now(),
    );
  }

  Future<void> _ask(String question) async {
    question = question.trim();
    if (question.isEmpty || typing) return;
    final ticket = ++generation;
    await speech.cancel();
    await voice!.stop();
    if (!mounted || ticket != generation) return;
    await LeafCheckHistory.instance.load();
    if (!mounted) return;
    final reply = brain.respond(question, _context(), tamil: tamil);
    if (reply.recordLabel != null) {
      await FarmLabelService.instance.record(reply.recordLabel!);
    }
    if (!mounted) return;
    final instant = MediaQuery.disableAnimationsOf(context);
    setState(() {
      input.clear();
      notice = null;
      typing = true;
      messages.add(
          (text: question, user: true, time: DateTime.now(), leaf: false));
    });
    _bottom();
    // A short pause reads like a conversation, not a lookup table.
    await Future<void>.delayed(Duration(milliseconds: instant ? 0 : 450));
    if (!mounted || ticket != generation) {
      if (mounted) setState(() => typing = false);
      return;
    }
    setState(() {
      typing = false;
      suggestions = reply.followUps;
      messages.add((
        text: reply.text,
        user: false,
        time: DateTime.now(),
        leaf: reply.openLeafCheck
      ));
      if (messages.length > 40) messages.removeRange(0, messages.length - 40);
    });
    _bottom();
    if (readAloud) await _speak(reply.text, ticket);
  }

  Future<void> _speak(String answer, int ticket) async {
    final ok =
        await voice!.speak(text: answer, languageCode: tamil ? 'ta' : 'en');
    if (mounted && ticket == generation && !ok) {
      setState(() => notice = t(
          'Voice is unavailable. Read the answer or choose a voice in Voice settings.',
          'குரல் கிடைக்கவில்லை. பதிலைப் படிக்கவும் அல்லது குரல் அமைப்பில் வேறு குரலைத் தேர்வு செய்யவும்.'));
    }
  }

  Future<void> _microphone() async {
    if (speech.busy) {
      await speech.cancel();
      return;
    }
    await voice!.stop();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool('phyto.speechConsent') != true) {
      final allow = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(t('Talk to Ilai', 'இலையிடம் பேசுங்கள்')),
                content: Text(t(
                    'Your phone’s speech service turns your words into text. It may use the internet and process audio through its provider. VayPulse does not save audio. You can type instead.',
                    'உங்கள் தொலைபேசியின் குரல் சேவை பேச்சை எழுத்தாக மாற்றும். இணையம் வழியாக அதன் வழங்குநர் ஒலியைச் செயலாக்கலாம். PhytoSense ஒலியைச் சேமிக்காது. பதிலாகத் தட்டச்சு செய்யலாம்.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(t('Type instead', 'தட்டச்சு செய்'))),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                          t('Use microphone', 'ஒலிவாங்கியைப் பயன்படுத்து')))
                ],
              ));
      if (allow != true || !mounted) return;
      await prefs.setBool('phyto.speechConsent', true);
    }
    if (!mounted) return;
    setState(() {
      readAloud = true;
      notice = null;
    });
    try {
      final question = await speech.listen(tamil ? 'ta' : 'en');
      if (!mounted) return;
      if (question != null && question.trim().isNotEmpty) await _ask(question);
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => notice = error.code == 'permission'
          ? t('Microphone permission is off. Allow it in phone settings, or type your question.',
              'ஒலிவாங்கி அனுமதி இல்லை. தொலைபேசி அமைப்பில் அனுமதிக்கவும் அல்லது தட்டச்சு செய்யவும்.')
          : t('Could not hear your question. Try again, check your phone’s speech language, or type instead.',
              'கேள்வி கேட்கவில்லை. மீண்டும் பேசவும், தொலைபேசி குரல் மொழியைச் சரிபார்க்கவும் அல்லது தட்டச்சு செய்யவும்.'));
    } on MissingPluginException {
      if (mounted)
        setState(() => notice = t(
            'Voice input is unavailable on this device. Please type.',
            'இந்த சாதனத்தில் குரல் உள்ளீடு இல்லை. தட்டச்சு செய்யவும்.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t('Ilai', 'இலை')), actions: [
        IconButton(
            tooltip: t('Voice settings', 'குரல் அமைப்பு'),
            icon: const Icon(Icons.record_voice_over_outlined),
            onPressed: () async {
              await speech.cancel();
              await voice!.stop();
              if (!context.mounted) return;
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VoiceStudioScreen()));
            }),
        IconButton(
            tooltip: t('Clear conversation', 'உரையாடலை அழி'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              generation++;
              speech.cancel();
              voice!.stop();
              setState(() {
                messages.clear();
                notice = null;
              });
            }),
      ]),
      body: SafeArea(
          top: false,
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedBuilder(
                                animation: Listenable.merge([speech, voice!]),
                                builder: (_, __) => Column(children: [
                                      IlaiAvatar(
                                          size: 88,
                                          active: speech.listening ||
                                              voice!.speaking),
                                      const SizedBox(height: 12),
                                      Text(
                                          t('A little leaf. Clear answers.',
                                              'சிறிய இலை. தெளிவான பதில்கள்.'),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge),
                                      const SizedBox(height: 8),
                                      Text(
                                          t('Talk to me like a friend — ask about your plant, watering, leaf spots, pests, or tell me what you did ("I watered"). I work offline, on your phone.',
                                              'நண்பரிடம் பேசுவது போலப் பேசுங்கள் — செடி, நீர், இலைப் புள்ளி, பூச்சி பற்றிக் கேளுங்கள், அல்லது நீங்கள் செய்ததைச் சொல்லுங்கள் ("நீர் ஊற்றினேன்"). இணையம் இல்லாமல் போனிலேயே வேலை செய்வேன்.'),
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 10),
                                      Text(
                                          _snapshot().simulation
                                              ? t('Simulation · Practice only',
                                                  'சிமுலேஷன் · பயிற்சி மட்டும்')
                                              : _snapshot().available
                                                  ? t('Using your ESP32 finding',
                                                      'உங்கள் ESP32 முடிவைப் பயன்படுத்துகிறது')
                                                  : t('Waiting for your sensor',
                                                      'உணரிக்காகக் காத்திருக்கிறது'),
                                          style: TextStyle(
                                              color: colors.primary,
                                              fontWeight: FontWeight.w700)),
                                    ])),
                            const SizedBox(height: 20),
                            for (final message in messages)
                              Align(
                                  alignment: message.user
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                      key: message == messages.last
                                          ? const Key('ilai-last-reply')
                                          : null,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                          color: message.user
                                              ? colors.primaryContainer
                                              : colors.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                message.user
                                                    ? t('You', 'நீங்கள்')
                                                    : '${t('Ilai · Reply at', 'இலை · பதில் நேரம்')} ${TimeOfDay.fromDateTime(message.time).format(context)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall),
                                            const SizedBox(height: 6),
                                            SelectableText(message.text),
                                            if (message.leaf)
                                              Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 10),
                                                  child: FilledButton.tonalIcon(
                                                      onPressed: () =>
                                                          LeafCheckScreen.open(
                                                              context),
                                                      icon: const Icon(
                                                          Icons.eco_rounded),
                                                      label: Text(t(
                                                          'Check a leaf',
                                                          'இலையைச் சோதி')))),
                                          ]))),
                            if (notice != null)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(notice!,
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant))),
                            if (typing)
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                      key: const Key('ilai-typing'),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                          color: colors.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(
                                          t('Ilai is typing…',
                                              'இலை பதில் எழுதுகிறது…'),
                                          style: TextStyle(
                                              color: colors.onSurfaceVariant,
                                              fontStyle: FontStyle.italic)))),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              for (final choice in (suggestions.isNotEmpty
                                  ? suggestions
                                  : [
                                      t('How is my plant?',
                                          'செடி எப்படி உள்ளது?'),
                                      t('Does it need water?', 'நீர் தேவையா?'),
                                      t('Check a leaf', 'இலை சோதனை'),
                                      t('What can you do?',
                                          'என்ன செய்ய முடியும்?'),
                                    ]))
                                ActionChip(
                                    label: Text(choice,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge),
                                    onPressed: () => _ask(choice)),
                            ]),
                          ]))),
              AnimatedBuilder(
                  animation: Listenable.merge([speech, voice!]),
                  builder: (_, __) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Expanded(
                              child: Text(t('Read replies aloud',
                                  'பதில்களைக் குரலில் கேள்'))),
                          Switch(
                              value: readAloud,
                              onChanged: (value) {
                                setState(() => readAloud = value);
                                if (!value) voice!.stop();
                              }),
                          if (voice!.speaking)
                            IconButton(
                                tooltip: t('Stop voice', 'குரலை நிறுத்து'),
                                onPressed: voice!.stop,
                                icon: const Icon(Icons.stop_circle_outlined)),
                        ]),
                        if (speech.busy)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(speech.listening
                                  ? t('Listening… tap the microphone to cancel',
                                      'கேட்கிறது… நிறுத்த ஒலிவாங்கியைத் தொடவும்')
                                  : t('Preparing or processing speech…',
                                      'குரல் தயாராகிறது அல்லது செயலாக்கப்படுகிறது…'))),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  child: TextField(
                                      controller: input,
                                      maxLines: 3,
                                      minLines: 1,
                                      maxLength: 500,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (text) => _ask(text),
                                      decoration: InputDecoration(
                                          counterText: '',
                                          hintText: t('Ask Ilai…',
                                              'இலையிடம் கேளுங்கள்…')))),
                              IconButton.filledTonal(
                                  key: const Key('ilai-microphone'),
                                  tooltip:
                                      t('Talk to Ilai', 'இலையிடம் பேசுங்கள்'),
                                  onPressed: _microphone,
                                  icon: Icon(speech.busy
                                      ? Icons.mic_off_rounded
                                      : Icons.mic_rounded)),
                              IconButton(
                                  key: const Key('ilai-send'),
                                  tooltip: t('Send', 'அனுப்பு'),
                                  onPressed: () => _ask(input.text),
                                  icon: const Icon(Icons.arrow_upward_rounded)),
                            ]),
                      ]))),
            ]),
          ))),
    );
  }
}
