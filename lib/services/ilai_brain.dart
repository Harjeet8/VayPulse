import 'ilai_guide.dart';

/// Everything Ilai may talk about, gathered by the screen for each question.
class IlaiContext {
  final IlaiSnapshot snapshot;
  final double? soilMoisture; // %
  final double? temperature; // °C
  final double? humidity; // %
  final String? lastLeafCrop; // farmer-language crop name
  final String? lastLeafResult; // farmer-language result
  final bool lastLeafHealthy;
  final DateTime? lastLeafTime;
  final int labelsToday;
  final int labelsPending;
  final DateTime now;

  const IlaiContext({
    required this.snapshot,
    this.soilMoisture,
    this.temperature,
    this.humidity,
    this.lastLeafCrop,
    this.lastLeafResult,
    this.lastLeafHealthy = false,
    this.lastLeafTime,
    this.labelsToday = 0,
    this.labelsPending = 0,
    required this.now,
  });
}

class IlaiReply {
  final String text;
  final String intent;
  final List<String> followUps; // chip texts, in the farmer's language
  final String? recordLabel; // label type to save for the farmer
  final bool openLeafCheck;
  const IlaiReply(this.text, this.intent, this.followUps,
      {this.recordLabel, this.openLeafCheck = false});
}

/// Offline, rule-based conversation for Ilai. Understands English, Tamil and
/// Tanglish, remembers the last topic for follow-ups ("why?", "tell me
/// more"), and answers from the live readings. It is not a general AI: when
/// a question is outside farming it says so honestly.
class IlaiBrain {
  String? _last; // last answered intent
  int _turn = 0;

  String? get lastIntent => _last;

  // intent -> keywords (English, Tanglish, Tamil). Multi-word entries match
  // as phrases; single words match whole tokens (with small-typo tolerance).
  static const _intents = <String, List<String>>{
    'greet': ['hi', 'hello', 'hey', 'hai', 'vanakkam', 'வணக்கம்', 'namaste',
      'good morning', 'good evening', 'good afternoon'],
    'thanks': ['thanks', 'thank', 'thx', 'nandri', 'நன்றி', 'super', 'great', 'ok thanks'],
    'bye': ['bye', 'goodbye', 'see you', 'poitu varen', 'போய் வருகிறேன்', 'சென்று வருகிறேன்'],
    'identity': ['who are you', 'your name', 'what are you', 'yaar nee', 'யார் நீ',
      'உன் பெயர்', 'நீ யார்', 'are you human', 'are you ai'],
    'howareyou': ['how are you', 'eppadi irukka', 'எப்படி இருக்கிறாய்', 'எப்படி இருக்கீங்க'],
    'help': ['help', 'what can you do', 'options', 'features', 'menu',
      'என்ன செய்ய முடியும்', 'உதவி'],
    'summary': ['plant', 'status', 'condition', 'health', 'healthy', 'how is',
      'sedi', 'chedi', 'செடி', 'நிலை', 'problem', 'wrong', 'பிரச்சினை', 'பிரச்சனை'],
    'action': ['what should i do', 'what to do', 'what do i do', 'next step',
      'solution', 'fix', 'enna seiya', 'என்ன செய்ய', 'தீர்வு', 'செய்ய வேண்டும்'],
    'reason': ['why', 'reason', 'how do you know', 'evidence', 'yen', 'ஏன்',
      'காரணம்', 'எதனால்'],
    'water': ['water', 'watering', 'irrigate', 'irrigation', 'dry', 'moisture',
      'thanni', 'neer', 'தண்ணீர்', 'நீர்', 'ஈரம்', 'பாசனம்', 'soil'],
    'heat': ['temperature', 'hot', 'heat', 'cold', 'veyil', 'veppam', 'வெப்பம்',
      'வெயில்', 'குளிர்'],
    'humidity': ['humidity', 'humid', 'damp', 'ஈரப்பத'],
    'nodeLight': ['led', 'lamp', 'bulb', 'node light', 'turn on', 'switch on',
      'turn off', 'switch off', 'vilakku', 'விளக்கு'],
    'disease': ['disease', 'diseases', 'spots', 'spot', 'fungus', 'fungal', 'blight',
      'mold', 'mould', 'rust', 'sick', 'yellow leaves', 'noi', 'நோய்', 'புள்ளி',
      'பூஞ்சை', 'மஞ்சள்'],
    'leafCheck': ['leaf check', 'check a leaf', 'check leaf', 'scan', 'photo',
      'camera', 'picture', 'இலை சோதனை', 'படம்', 'last check', 'leaf result'],
    'pests': ['pest', 'pests', 'insect', 'insects', 'worm', 'worms', 'bug', 'bugs',
      'aphid', 'whitefly', 'mites', 'poochi', 'பூச்சி', 'புழு', 'பேன்'],
    'fertilizer': ['fertilizer', 'fertiliser', 'manure', 'compost', 'urea',
      'nutrient', 'uram', 'உரம்', 'எரு'],
    'labels': ['record', 'log', 'label', 'labels', 'note down', 'பதிவு'],
    'connection': ['connect', 'connection', 'offline', 'wifi', 'wi-fi', 'internet',
      'firebase', 'not working', 'node', 'sensor', 'இணை', 'இணைப்பு', 'சாதனம்'],
    'language': ['language', 'tamil', 'english', 'மொழி', 'தமிழ்', 'ஆங்கிலம்'],
    'weather': ['weather', 'rain', 'forecast', 'mazhai', 'மழை', 'வானிலை'],
    'otherCrop': ['rice', 'paddy', 'banana', 'coconut', 'brinjal', 'chilli',
      'groundnut', 'sugarcane', 'cotton', 'mango', 'நெல்', 'வாழை', 'தென்னை',
      'கத்திரி', 'மிளகாய்', 'நிலக்கடலை', 'கரும்பு', 'பருத்தி'],
    'time': ['what time', 'time now', 'date today', 'today date', 'என்ன நேரம்', 'இன்று தேதி'],
    'more': ['more', 'tell me more', 'explain', 'details', 'then', 'and then',
      'go on', 'innum', 'மேலும்', 'இன்னும்'],
  };

  // First-person statements Ilai records as labels.
  static final _statements = <String, RegExp>{
    'watered': RegExp(
        r"\bi (just )?watered\b|\bwatered (it|the|today|now)\b|நீர் ஊற்றினேன்|தண்ணீர் ஊற்றினேன்|thanni ((oothi|ootti|oothu)nen|vitten)"),
    'fertilizer': RegExp(
        r"\bi (just )?(added|put|gave) (some )?(fertili[sz]er|manure|compost|urea)\b|உரம் (போட்டேன்|இட்டேன்|வைத்தேன்)|uram (potten|pottaen)"),
    'pests': RegExp(
        r"\bi (saw|see|found) (some )?(pests?|insects?|worms?|bugs?)\b|பூச்சி(கள்)? (பார்த்தேன்|தெரிகிறது)"),
    'wilted': RegExp(r"\b(plant|it) (is |looks )?wilt(ed|ing)\b|செடி வாடி"),
  };

  IlaiReply respond(String question, IlaiContext c, {required bool tamil}) {
    _turn++;
    String t(String en, String ta) => tamil ? ta : en;
    final q = _normalise(question);

    // 1. Statements the farmer makes about their field are recorded.
    // Questions ("why is my plant wilting?") are never recorded.
    final asking = question.contains('?') ||
        RegExp(r'^(why|what|how|is|are|does|do|should|can|when|where|ஏன்|என்ன|எப்படி)\b')
            .hasMatch(q);
    for (final e
        in asking ? const <MapEntry<String, RegExp>>[] : _statements.entries) {
      if (e.value.hasMatch(q)) {
        _last = 'labels';
        return IlaiReply(_recorded(e.key, tamil), 'recorded',
            _chips(['summary', 'water', 'leafCheck'], tamil),
            recordLabel: e.key);
      }
    }

    // 2. Score intents.
    final scores = <String, double>{};
    final tokens = q.split(' ').where((w) => w.isNotEmpty).toList();
    for (final e in _intents.entries) {
      var s = 0.0;
      for (final k in e.value) {
        if (k.contains(' ')) {
          // Longer phrases are more specific.
          if (q.contains(k)) s += 1.0 + k.split(' ').length;
        } else if (tokens.contains(k)) {
          s += 1.0;
        } else if (k.length >= 5 && tokens.any((w) => _near(w, k))) {
          s += 0.6;
        } else if (!_isAscii(k) && q.contains(k)) {
          s += 1.0; // Tamil words carry suffixes (செடியின், நீரை ...)
        }
      }
      if (s > 0) scores[e.key] = s;
    }
    // Short follow-ups lean on the previous topic.
    final followUp = scores.containsKey('more') ||
        (tokens.length <= 3 &&
            (scores.containsKey('reason') || scores.containsKey('action')));
    if (scores.containsKey('more') && _last != null && scores.length == 1) {
      return _answer(_last!, c, tamil, deeper: true);
    }
    scores.remove('more');
    if (followUp &&
        _last != null &&
        scores.containsKey('reason') &&
        scores.length == 1) {
      return _answer(_last!, c, tamil, why: true);
    }

    if (scores.isEmpty) {
      return IlaiReply(
          t('Sorry, I didn\'t catch that. I can help with your plant\'s condition, watering, leaf diseases, pests, fertilizer, and recording what you did. Try one of these:',
              'மன்னிக்கவும், எனக்குப் புரியவில்லை. செடியின் நிலை, நீர்ப்பாசனம், இலை நோய், பூச்சி, உரம், நீங்கள் செய்ததைப் பதிவு செய்தல் பற்றி உதவுவேன். இவற்றில் ஒன்றை முயலுங்கள்:'),
          'unknown',
          _chips(['summary', 'water', 'leafCheck', 'help'], tamil));
    }
    // Ties go to the more specific topic; general ones rank last.
    const general = {'help': 0, 'summary': 1, 'connection': 2};
    final ranked = scores.entries.toList()
      ..sort((a, b) {
        final byScore = b.value.compareTo(a.value);
        if (byScore != 0) return byScore;
        return (general[a.key] ?? 9).compareTo(general[b.key] ?? 9) * -1;
      });
    // Very weak, ambiguous match -> ask instead of guessing.
    if (ranked.first.value < 1.0 &&
        ranked.length > 1 &&
        ranked[1].value >= ranked.first.value * 0.8) {
      return IlaiReply(
          t('Did you mean one of these?', 'இவற்றில் ஒன்றைக் கேட்கிறீர்களா?'),
          'clarify',
          _chips([ranked[0].key, ranked[1].key], tamil));
    }
    return _answer(ranked.first.key, c, tamil);
  }

  IlaiReply _answer(String intent, IlaiContext c, bool tamil,
      {bool deeper = false, bool why = false}) {
    String t(String en, String ta) => tamil ? ta : en;
    String pick(List<String> options) => options[_turn % options.length];
    final s = c.snapshot;
    _last = intent;
    final hour = c.now.hour;

    switch (intent) {
      case 'greet':
        final part = hour < 12
            ? t('Good morning', 'காலை வணக்கம்')
            : hour < 17
                ? t('Good afternoon', 'மதிய வணக்கம்')
                : t('Good evening', 'மாலை வணக்கம்');
        final status = s.available && s.condition.isNotEmpty
            ? t(' Your plant right now: ${s.condition}.',
                ' இப்போது உங்கள் செடி: ${s.condition}.')
            : '';
        return IlaiReply(
            '$part! ${pick([
                  t('I\'m Ilai. How can I help today?', 'நான் இலை. இன்று எப்படி உதவலாம்?'),
                  t('Ilai here. What would you like to know?', 'இலை இங்கே. என்ன தெரிந்துகொள்ள வேண்டும்?')
                ])}$status',
            intent,
            _chips(['summary', 'water', 'leafCheck'], tamil));
      case 'howareyou':
        return IlaiReply(
            t('I\'m doing well, thank you! More importantly — shall I check how your plant is doing?',
                'நான் நன்றாக இருக்கிறேன், நன்றி! முக்கியமாக — உங்கள் செடி எப்படி இருக்கிறது என்று பார்க்கட்டுமா?'),
            intent,
            _chips(['summary', 'water'], tamil));
      case 'thanks':
        return IlaiReply(
            pick([
              t('You\'re welcome! Ask me anytime.',
                  'மகிழ்ச்சி! எப்போது வேண்டுமானாலும் கேளுங்கள்.'),
              t('Happy to help. Take care of your plants!',
                  'உதவியதில் மகிழ்ச்சி. செடிகளைக் கவனித்துக்கொள்ளுங்கள்!'),
            ]),
            intent,
            _chips(['summary', 'leafCheck'], tamil));
      case 'bye':
        return IlaiReply(
            t('Goodbye! I\'ll keep watching the sensor readings for you.',
                'போய் வாருங்கள்! சென்சார் அளவீடுகளை நான் கவனித்துக்கொள்கிறேன்.'),
            intent,
            const []);
      case 'identity':
        return IlaiReply(
            t('I\'m Ilai (இலை means "leaf"), the helper inside VayPulse. I read your PhytoSense node\'s sensors, explain what they mean, help you check leaves, and save what you did in the field. I work on your phone, even without internet. I\'m not a person, and I\'m not a general-purpose AI.',
                'நான் இலை, VayPulse உள்ளே இருக்கும் உதவியாளர். உங்கள் PhytoSense கருவியின் சென்சார்களைப் படித்து விளக்குவேன், இலைச் சோதனைக்கு உதவுவேன், வயலில் நீங்கள் செய்ததைப் பதிவு செய்வேன். இணையம் இல்லாமலும் போனிலேயே வேலை செய்வேன். நான் மனிதர் அல்ல; பொதுவான செயற்கை நுண்ணறிவும் அல்ல.'),
            intent,
            _chips(['help', 'summary'], tamil));
      case 'help':
        return IlaiReply(
            t('Here\'s what I can do:\n• Tell you how your plant is and why\n• Say if it needs water, based on soil moisture\n• Explain heat and humidity risks\n• Help you check a leaf for disease (offline)\n• Talk about pests and fertilizer\n• Save what you did — just tell me, like "I watered"\nFor anything outside farming, please ask your agriculture officer.',
                'நான் செய்யக்கூடியவை:\n• செடியின் நிலையும் காரணமும்\n• மண் ஈரத்தைக் கொண்டு நீர் தேவையா என்பது\n• வெப்பம், ஈரப்பத ஆபத்துகள்\n• இலை நோய்ச் சோதனை (இணையம் தேவையில்லை)\n• பூச்சி, உரம் பற்றிய ஆலோசனை\n• நீங்கள் செய்ததைப் பதிவு செய்தல் — "நீர் ஊற்றினேன்" என்று சொன்னால் போதும்\nவிவசாயம் தவிர்த்த கேள்விகளுக்கு வேளாண் அலுவலரைக் கேளுங்கள்.'),
            intent,
            _chips(['summary', 'water', 'leafCheck', 'pests'], tamil));
      case 'summary':
      case 'action':
      case 'reason':
        final topic = why || intent == 'reason'
            ? IlaiTopic.reason
            : intent == 'action'
                ? IlaiTopic.action
                : IlaiTopic.summary;
        var text = IlaiGuide.reply(topic, s, tamil: tamil);
        if (deeper && s.available) {
          text += '\n\n${_readingsLine(c, tamil)}';
        }
        return IlaiReply(
            text,
            intent,
            _chips(
                intent == 'summary'
                    ? ['action', 'reason', 'water']
                    : ['summary', 'water', 'leafCheck'],
                tamil));
      case 'water':
        return IlaiReply(_water(c, tamil, why: why || deeper), intent,
            _chips(why ? ['summary', 'heat'] : ['reason', 'heat', 'labels'], tamil));
      case 'heat':
        return IlaiReply(
            _heat(c, tamil), intent, _chips(['water', 'humidity'], tamil));
      case 'humidity':
        return IlaiReply(
            _humidity(c, tamil), intent, _chips(['disease', 'water'], tamil));
      case 'nodeLight':
        return IlaiReply(
            t('Use the Node light card on the Home screen: tap On, Off or Auto, and slide for brightness. When you are near the node, it changes at once; from far away it takes about 10 seconds.',
                'முகப்புத் திரையில் உள்ள "கருவி விளக்கு" அட்டையைப் பயன்படுத்துங்கள்: On, Off அல்லது Auto தொட்டு, ஒளியளவை நகர்த்துங்கள். கருவிக்கு அருகில் உடனே மாறும்; தொலைவில் சுமார் 10 வினாடிகள் ஆகும்.'),
            intent,
            _chips(['connection', 'summary'], tamil));
      case 'disease':
        final last = c.lastLeafResult == null
            ? ''
            : t('\n\nYour last leaf check (${c.lastLeafCrop}): ${c.lastLeafResult}.',
                '\n\nகடைசி இலை சோதனை (${c.lastLeafCrop}): ${c.lastLeafResult}.');
        return IlaiReply(
            t('Spots, yellow patches or powder on leaves can mean a disease. The best first step: take a clear photo of one leaf with "Check a leaf" — it works offline. Meanwhile, remove badly spotted leaves, water at the root (not on the leaves), and keep space between plants for air.$last',
                'இலையில் புள்ளி, மஞ்சள் திட்டு அல்லது பொடி இருந்தால் நோயாக இருக்கலாம். முதல் படி: "இலையைச் சோதி" மூலம் ஒரு இலையைத் தெளிவாகப் படம் எடுங்கள் — இணையம் தேவையில்லை. அதுவரை கடுமையாகப் பாதித்த இலைகளை அகற்றுங்கள், இலையில் அல்ல வேரில் நீர் ஊற்றுங்கள், காற்றோட்டத்திற்கு இடைவெளி விடுங்கள்.$last'),
            intent,
            _chips(['leafCheck', 'humidity', 'pests'], tamil),
            openLeafCheck: true);
      case 'leafCheck':
        if (c.lastLeafResult != null && !deeper) {
          final when = c.lastLeafTime == null
              ? ''
              : ' (${_ago(c.lastLeafTime!, c.now, tamil)})';
          return IlaiReply(
              t('Your last leaf check$when: ${c.lastLeafCrop} — ${c.lastLeafResult}.${c.lastLeafHealthy ? ' Good news!' : ''}\n\nTo check another leaf, tap "Check a leaf". Pick your crop, then take one clear photo in daylight.',
                  'கடைசி இலை சோதனை$when: ${c.lastLeafCrop} — ${c.lastLeafResult}.${c.lastLeafHealthy ? ' நல்ல செய்தி!' : ''}\n\nஇன்னொரு இலையைச் சோதிக்க "இலையைச் சோதி" தொடுங்கள். பயிரைத் தேர்வு செய்து, பகல் வெளிச்சத்தில் ஒரு தெளிவான படம் எடுங்கள்.'),
              intent,
              _chips(['disease', 'summary'], tamil),
              openLeafCheck: true);
        }
        return IlaiReply(
            t('Tap "Check a leaf" (on Home or the Camera tab). Pick your crop, then photograph ONE leaf: fill the frame, plain background, daylight, no blur. It works without internet and the photo stays on your phone. Supported: tomato, potato, capsicum, maize, grape, apple, peach, cherry, strawberry.',
                '"இலையைச் சோதி" தொடுங்கள் (முகப்பு அல்லது கேமரா பகுதி). பயிரைத் தேர்வு செய்து, ஒரே ஒரு இலையைப் படம் எடுங்கள்: படம் முழுவதும் இலை, சாதாரணப் பின்னணி, பகல் வெளிச்சம், மங்கல் இல்லாமல். இணையம் தேவையில்லை; படம் போனிலேயே இருக்கும். ஆதரவு: தக்காளி, உருளை, குடைமிளகாய், மக்காச்சோளம், திராட்சை, ஆப்பிள், பீச், செர்ரி, ஸ்ட்ராபெர்ரி.'),
            intent,
            _chips(['otherCrop', 'disease'], tamil),
            openLeafCheck: true);
      case 'otherCrop':
        return IlaiReply(
            t('The leaf check has not learned rice, banana, coconut, brinjal, chilli, groundnut, sugarcane, cotton or mango yet, so I won\'t guess for those. For these crops, show a sample leaf to your agriculture officer or the nearest Krishi Vigyan Kendra. The sensors still work for any crop.',
                'நெல், வாழை, தென்னை, கத்திரி, மிளகாய், நிலக்கடலை, கரும்பு, பருத்தி, மா ஆகியவற்றை இலை சோதனை இன்னும் கற்கவில்லை; அதனால் ஊகிக்க மாட்டேன். இவற்றுக்கு இலையை வேளாண் அலுவலர் அல்லது அருகிலுள்ள வேளாண் அறிவியல் நிலையத்தில் காட்டுங்கள். சென்சார்கள் எல்லாப் பயிருக்கும் வேலை செய்யும்.'),
            intent,
            _chips(['water', 'summary'], tamil));
      case 'pests':
        return IlaiReply(
            t('Look under the leaves and at new shoots in the morning. Pick off caterpillars by hand; a strong spray of plain water removes aphids and mites. Yellow sticky cards help catch whiteflies. If many plants are hit, ask your agriculture officer before spraying anything.\n\nIf you saw pests today, tell me "I saw pests" and I\'ll record it.',
                'காலையில் இலைகளின் அடிப்பக்கத்தையும் புதிய தளிர்களையும் பாருங்கள். கம்பளிப் புழுக்களைக் கையால் அகற்றுங்கள்; வெறும் நீரை வேகமாகத் தெளித்தால் அசுவினி, பேன் போகும். மஞ்சள் ஒட்டும் அட்டைகள் வெள்ளை ஈயைப் பிடிக்கும். பல செடிகள் பாதித்தால், எதையும் தெளிக்கும் முன் வேளாண் அலுவலரைக் கேளுங்கள்.\n\nஇன்று பூச்சி பார்த்தீர்களா? "பூச்சி பார்த்தேன்" என்று சொன்னால் பதிவு செய்வேன்.'),
            intent,
            _chips(['disease', 'labels'], tamil));
      case 'fertilizer':
        return IlaiReply(
            t('Give fertilizer in small amounts, near the root but not touching the stem, and water after. Well-rotted compost or farmyard manure is safe for most crops. Too much fertilizer can burn roots — for exact amounts, follow a soil test or ask your agriculture officer.\n\nAdded some today? Say "I added fertilizer" and I\'ll record it.',
                'உரத்தைச் சிறிது சிறிதாக, வேருக்கு அருகில், தண்டைத் தொடாமல் இட்டு, பின் நீர் ஊற்றுங்கள். நன்கு மக்கிய தொழு உரம் பெரும்பாலான பயிர்களுக்குப் பாதுகாப்பானது. அதிக உரம் வேரை எரிக்கும் — சரியான அளவுக்கு மண் பரிசோதனை அல்லது வேளாண் அலுவலரைப் பின்பற்றுங்கள்.\n\nஇன்று உரம் இட்டீர்களா? "உரம் இட்டேன்" என்று சொன்னால் பதிவு செய்வேன்.'),
            intent,
            _chips(['water', 'labels'], tamil));
      case 'labels':
        final count = c.labelsToday == 0
            ? t('Nothing recorded today yet.', 'இன்று இன்னும் எதுவும் பதிவு இல்லை.')
            : t('Today you recorded ${c.labelsToday}.',
                'இன்று ${c.labelsToday} பதிவு செய்தீர்கள்.');
        final pending = c.labelsPending == 0
            ? ''
            : t(' ${c.labelsPending} will be sent when you are online.',
                ' ${c.labelsPending} இணையம் வந்ததும் அனுப்பப்படும்.');
        return IlaiReply(
            t('Use the "What did you do / see?" card on Home — one tap each: watered, fertilizer, wilted, spots, healthy, pests. Or just tell me, like "I watered". This teaches VayPulse how your plants react. $count$pending',
                'முகப்பில் "என்ன செய்தீர்கள் / பார்த்தீர்கள்?" அட்டையைப் பயன்படுத்துங்கள் — ஒவ்வொன்றும் ஒரே தொடுதல். அல்லது "நீர் ஊற்றினேன்" என்று என்னிடம் சொல்லுங்கள். இது உங்கள் செடிகளை VayPulse கற்க உதவும். $count$pending'),
            intent,
            _chips(['water', 'summary'], tamil));
      case 'connection':
        return IlaiReply(IlaiGuide.reply(IlaiTopic.connection, s, tamil: tamil),
            intent, _chips(['nodeLight', 'summary'], tamil));
      case 'language':
        return IlaiReply(
            t('To switch between Tamil and English, open Settings → Language. I\'ll follow the app, and the node\'s voice will switch too.',
                'தமிழ்/ஆங்கிலம் மாற்ற, அமைப்புகள் → மொழி திறக்கவும். நான் செயலியின் மொழியைப் பின்பற்றுவேன்; கருவியின் குரலும் மாறும்.'),
            intent,
            _chips(['help'], tamil));
      case 'weather':
        return IlaiReply(
            t('See the Weather card on the Home screen for rain and heat today. Tip: if rain is expected soon, you can skip watering; after heavy rain, check for standing water around roots.',
                'இன்றைய மழை, வெப்பம் அறிய முகப்பில் உள்ள வானிலை அட்டையைப் பாருங்கள். குறிப்பு: விரைவில் மழை வரும் என்றால் நீர் ஊற்றுவதைத் தவிர்க்கலாம்; கனமழைக்குப் பின் வேரைச் சுற்றி நீர் தேங்கியுள்ளதா எனப் பாருங்கள்.'),
            intent,
            _chips(['water', 'heat'], tamil));
      case 'time':
        final hh = c.now.hour % 12 == 0 ? 12 : c.now.hour % 12;
        final mm = c.now.minute.toString().padLeft(2, '0');
        final ampm = c.now.hour < 12 ? 'AM' : 'PM';
        return IlaiReply(
            t('It\'s $hh:$mm $ampm, ${c.now.day}/${c.now.month}/${c.now.year}.',
                'இப்போது $hh:$mm $ampm, ${c.now.day}/${c.now.month}/${c.now.year}.'),
            intent,
            _chips(['summary'], tamil));
    }
    return IlaiReply(IlaiGuide.reply(IlaiTopic.help, s, tamil: tamil), 'help',
        _chips(['summary', 'water', 'leafCheck'], tamil));
  }

  String _water(IlaiContext c, bool tamil, {bool why = false}) {
    String t(String en, String ta) => tamil ? ta : en;
    final m = c.soilMoisture;
    if (!c.snapshot.available || m == null) {
      return t('I can\'t see a fresh soil reading right now, so I won\'t guess. Push a finger 5 cm into the soil: if it feels dry there, water slowly at the root. Early morning or evening is best.',
          'இப்போது புதிய மண் அளவீடு இல்லை; ஊகிக்க மாட்டேன். மண்ணில் 5 செ.மீ விரலை வைத்துப் பாருங்கள்: அங்கே உலர்ந்திருந்தால், வேரில் மெதுவாக நீர் ஊற்றுங்கள். அதிகாலை அல்லது மாலை சிறந்தது.');
    }
    final pct = m.round();
    final practice =
        c.snapshot.simulation ? t(' (practice data)', ' (பயிற்சித் தரவு)') : '';
    String main;
    if (m < 30) {
      main = t('Soil moisture is $pct%$practice — the soil is dry. Yes, water now: slowly, at the root, until the top soil is damp.',
          'மண் ஈரம் $pct%$practice — மண் உலர்ந்துள்ளது. ஆம், இப்போது நீர் ஊற்றுங்கள்: மெதுவாக, வேரில், மேல் மண் ஈரமாகும் வரை.');
    } else if (m < 70) {
      main = t('Soil moisture is $pct%$practice — that\'s fine. No need to water now; check again this evening.',
          'மண் ஈரம் $pct%$practice — சரியான அளவு. இப்போது நீர் தேவையில்லை; மாலையில் மீண்டும் பாருங்கள்.');
    } else {
      main = t('Soil moisture is $pct%$practice — the soil is very wet. Don\'t water. Too much water can rot the roots; make sure water can drain away.',
          'மண் ஈரம் $pct%$practice — மண் மிக ஈரமாக உள்ளது. நீர் ஊற்ற வேண்டாம். அதிக நீர் வேரை அழுகச் செய்யும்; நீர் வடிய வழி இருக்கட்டும்.');
    }
    if (why) {
      main += t('\n\nWhy: roots need both water and air. Below about 30% the plant struggles to drink; above about 70% the soil holds too little air.',
          '\n\nஏன்: வேருக்கு நீரும் காற்றும் தேவை. சுமார் 30%க்குக் கீழே செடி நீரை உறிஞ்சக் கஷ்டப்படும்; சுமார் 70%க்கு மேலே மண்ணில் காற்று குறையும்.');
    }
    final temp = c.temperature;
    if (temp != null && temp >= 35 && m < 70) {
      main += t('\n\nIt\'s hot (${temp.round()}°C), so the soil will dry faster today.',
          '\n\nவெப்பம் அதிகம் (${temp.round()}°C); இன்று மண் வேகமாக உலரும்.');
    }
    return main;
  }

  String _heat(IlaiContext c, bool tamil) {
    String t(String en, String ta) => tamil ? ta : en;
    final temp = c.temperature;
    if (!c.snapshot.available || temp == null) {
      return t('I don\'t have a fresh temperature reading. On hot days, water early in the morning and give young plants some shade at noon.',
          'புதிய வெப்பநிலை அளவீடு இல்லை. வெயில் நாட்களில் அதிகாலையில் நீர் ஊற்றி, நண்பகலில் இளம் செடிகளுக்கு நிழல் கொடுங்கள்.');
    }
    final v = temp.round();
    if (temp >= 38) {
      return t('It\'s very hot: $v°C. Plants can wilt in the afternoon. Water early morning, mulch the soil with dry leaves or straw, and shade young plants at noon.',
          'மிகவும் வெப்பம்: $v°C. மதியம் செடிகள் வாடலாம். அதிகாலையில் நீர் ஊற்றி, காய்ந்த இலை அல்லது வைக்கோலால் மண்ணை மூடுங்கள்; நண்பகலில் இளம் செடிகளுக்கு நிழல் கொடுங்கள்.');
    }
    if (temp >= 32) {
      return t('It\'s warm: $v°C. Keep an eye on soil moisture — it dries faster in this heat.',
          'சூடாக உள்ளது: $v°C. மண் ஈரத்தைக் கவனியுங்கள் — இந்த வெப்பத்தில் வேகமாக உலரும்.');
    }
    if (temp <= 12) {
      return t('It\'s cold: $v°C. Growth slows down; water less, and only in the daytime.',
          'குளிராக உள்ளது: $v°C. வளர்ச்சி குறையும்; குறைவாக, பகலில் மட்டும் நீர் ஊற்றுங்கள்.');
    }
    return t('Temperature is $v°C — comfortable for most crops.',
        'வெப்பநிலை $v°C — பெரும்பாலான பயிர்களுக்கு ஏற்றது.');
  }

  String _humidity(IlaiContext c, bool tamil) {
    String t(String en, String ta) => tamil ? ta : en;
    final h = c.humidity;
    if (!c.snapshot.available || h == null) {
      return t('I don\'t have a fresh humidity reading. In damp weather, water in the morning so leaves dry quickly.',
          'புதிய ஈரப்பத அளவீடு இல்லை. ஈரமான காலநிலையில் இலைகள் விரைவில் உலர காலையில் நீர் ஊற்றுங்கள்.');
    }
    final v = h.round();
    if (h >= 85) {
      return t('Air humidity is high: $v%. Leaf diseases (fungus) spread easily now. Water only at the root, keep space between plants, and check leaves for spots.',
          'காற்று ஈரப்பதம் அதிகம்: $v%. இப்போது பூஞ்சை நோய்கள் எளிதில் பரவும். வேரில் மட்டும் நீர் ஊற்றி, செடிகளுக்கு இடைவெளி விட்டு, இலைகளில் புள்ளி உள்ளதா எனப் பாருங்கள்.');
    }
    if (h <= 35) {
      return t('Air is dry: $v% humidity. Plants lose water fast; mulching helps keep the soil moist.',
          'காற்று வறண்டுள்ளது: ஈரப்பதம் $v%. செடிகள் விரைவில் நீரை இழக்கும்; மூடாக்கு மண் ஈரத்தைக் காக்கும்.');
    }
    return t('Humidity is $v% — normal.', 'ஈரப்பதம் $v% — சாதாரணம்.');
  }

  String _readingsLine(IlaiContext c, bool tamil) {
    final parts = <String>[
      if (c.soilMoisture != null)
        '${tamil ? 'மண் ஈரம்' : 'Soil moisture'} ${c.soilMoisture!.round()}%',
      if (c.temperature != null)
        '${tamil ? 'வெப்பம்' : 'Temperature'} ${c.temperature!.round()}°C',
      if (c.humidity != null)
        '${tamil ? 'ஈரப்பதம்' : 'Humidity'} ${c.humidity!.round()}%',
    ];
    return parts.isEmpty
        ? ''
        : '${tamil ? 'அளவீடுகள்' : 'Readings'}: ${parts.join(' · ')}';
  }

  static String _recorded(String type, bool tamil) {
    const en = {
      'watered':
          'Noted ✓ — I saved "I watered" for today. I\'ll match it with the soil readings.',
      'fertilizer': 'Noted ✓ — I saved "Added fertilizer" for today.',
      'pests':
          'Noted ✓ — I saved "Pests seen". Check under the leaves; ask me about pests for tips.',
      'wilted':
          'Noted ✓ — I saved "Plant looks wilted". Check the soil moisture: ask me "does it need water?"',
    };
    const ta = {
      'watered':
          'பதிவு செய்தேன் ✓ — இன்று "நீர் ஊற்றினேன்" சேமிக்கப்பட்டது. மண் அளவீடுகளுடன் ஒப்பிடுவேன்.',
      'fertilizer': 'பதிவு செய்தேன் ✓ — இன்று "உரம் இட்டேன்" சேமிக்கப்பட்டது.',
      'pests':
          'பதிவு செய்தேன் ✓ — "பூச்சிகள் தெரிகின்றன" சேமிக்கப்பட்டது. இலைகளின் அடிப்பக்கத்தைப் பாருங்கள்.',
      'wilted':
          'பதிவு செய்தேன் ✓ — "செடி வாடியுள்ளது" சேமிக்கப்பட்டது. மண் ஈரத்தைப் பார்க்க "நீர் தேவையா?" என்று கேளுங்கள்.',
    };
    return (tamil ? ta : en)[type]!;
  }

  /// Chip texts; each one is understood by [respond].
  static List<String> _chips(List<String> intents, bool tamil) {
    const en = {
      'summary': 'How is my plant?',
      'action': 'What should I do?',
      'reason': 'Why?',
      'water': 'Does it need water?',
      'heat': 'Is it too hot?',
      'humidity': 'Humidity risk?',
      'disease': 'Leaves have spots',
      'leafCheck': 'Check a leaf',
      'pests': 'Pests help',
      'labels': 'Record what I did',
      'help': 'What can you do?',
      'otherCrop': 'Rice / banana / coconut?',
      'connection': 'Connect my sensor',
      'nodeLight': 'Node light',
    };
    const ta = {
      'summary': 'செடி எப்படி உள்ளது?',
      'action': 'என்ன செய்ய வேண்டும்?',
      'reason': 'ஏன்?',
      'water': 'நீர் தேவையா?',
      'heat': 'வெப்பம் அதிகமா?',
      'humidity': 'ஈரப்பத ஆபத்து?',
      'disease': 'இலைகளில் புள்ளிகள்',
      'leafCheck': 'இலை சோதனை',
      'pests': 'பூச்சி உதவி',
      'labels': 'செய்ததைப் பதிவு செய்',
      'help': 'என்ன செய்ய முடியும்?',
      'otherCrop': 'நெல் / வாழை / தென்னை?',
      'connection': 'சாதனத்தை இணை',
      'nodeLight': 'கருவி விளக்கு',
    };
    final map = tamil ? ta : en;
    return [
      for (final i in intents)
        if (map[i] != null) map[i]!
    ];
  }

  static String _ago(DateTime then, DateTime now, bool tamil) {
    final d = now.difference(then);
    if (d.inMinutes < 60) {
      return tamil ? '${d.inMinutes} நிமிடம் முன்' : '${d.inMinutes} min ago';
    }
    if (d.inHours < 24) {
      return tamil ? '${d.inHours} மணி நேரம் முன்' : '${d.inHours} h ago';
    }
    return tamil ? '${d.inDays} நாள் முன்' : '${d.inDays} days ago';
  }

  static String _normalise(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[?!.,;:()\[\]{}'" '"' r"“”‘’]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _isAscii(String s) => s.codeUnits.every((c) => c < 128);

  /// Edit distance <= 1 (one typo), for English words of 5+ letters.
  static bool _near(String a, String b) {
    if (!_isAscii(a) || (a.length - b.length).abs() > 1) return false;
    var i = 0, j = 0, edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (a.length < b.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }
}
