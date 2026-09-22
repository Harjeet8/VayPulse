import 'package:flutter/widgets.dart';

import 'app_scope.dart';

/// Normalizes known ESP32 phrases into farmer-friendly English/Tamil while
/// keeping unknown future firmware strings readable instead of crashing.
class FirmwareTextAdapter {
  const FirmwareTextAdapter._();

  static bool _tamil(BuildContext context) =>
      AppScope.of(context).settings.value.languageCode == 'ta';

  static String label(BuildContext context, String key) {
    final values = _tamil(context) ? _ta : _en;
    return values[key] ?? _en[key] ?? key;
  }

  static String text(BuildContext context, String? raw,
      {String fallback = ''}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    if (!_tamil(context)) return farmerEnglish(raw, fallback: fallback);
    final clean = raw.trim();
    final key = clean
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final known = _knownTa[key];
    if (known != null) return known;

    // The ESP32 remains the source of truth. These rules change wording only;
    // they never infer a new diagnosis or action from raw sensor values.
    final plain = _plainTamil(clean.toLowerCase());
    if (plain != null) return plain;

    // Never surface engineering shorthand as farmer advice. Unknown future
    // phrases are retained, but common implementation terms are softened.
    return _softenEnglish(clean);
  }

  /// Pure adapter used by tests and notification-safe presentation code.
  /// It changes wording only and never derives a condition from readings.
  static String farmerEnglish(String? raw, {String fallback = ''}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final clean = raw.trim();
    final key = clean
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final known = _knownEn[key];
    if (known != null) return known;
    final plain = _plainEnglish(clean.toLowerCase());
    return plain ?? _softenEnglish(clean);
  }

  static String _softenEnglish(String clean) => clean
      .replaceAll(RegExp(r'\bADC\b', caseSensitive: false), 'sensor reading')
      .replaceAll(RegExp(r'\bEMA\b', caseSensitive: false), 'recent trend')
      .replaceAll(RegExp(r'\bVPD\b', caseSensitive: false), 'air drying level')
      .replaceAll(
          RegExp(r'\bZ[- ]?score\b', caseSensitive: false), 'unusual change')
      .replaceAll(
          RegExp(r'\bbioelectric\b', caseSensitive: false), 'plant signal')
      .replaceAll(
          RegExp(r'\bbiotic\b', caseSensitive: false), 'pest or disease')
      .replaceAll(
          RegExp(r'\bcorroborated\b', caseSensitive: false), 'supported')
      .replaceAll(
          RegExp(r'\banomaly\b', caseSensitive: false), 'unusual change')
      .replaceAll(RegExp(r'\btelemetry\b', caseSensitive: false), 'sensor data')
      .replaceAll(
          RegExp(r'feature vector', caseSensitive: false), 'sensor pattern')
      .replaceAll(
          RegExp(r'regression slope', caseSensitive: false), 'rate of change')
      .replaceAll(RegExp(r'weighted fusion', caseSensitive: false),
          'combined sensor evidence');

  static String? _plainEnglish(String value) {
    if (value.contains('collecting live sensor data') ||
        value.contains('first complete sensor frame') ||
        value.contains('waiting for a complete reliable sensor frame')) {
      return 'Waiting for the first good sensor reading.';
    }
    if (value.contains('baseline learning paused')) {
      return 'Learning is paused while the plant is stressed.';
    }
    if ((value.contains('electrical response uncertain') ||
            value.contains('signal quality is not reliable')) &&
        (value.contains('electrode') || value.contains('plant electrical'))) {
      return 'The plant sensor reading is not clear. Check that it touches the plant properly.';
    }
    if (value.contains('electrical activity normal') ||
        value.contains('normal relative to learned baseline')) {
      return 'The plant signal looks normal.';
    }
    if (value.contains('root soil is dry') ||
        value.contains('root zone is critically dry')) {
      return 'The soil near the roots is too dry.';
    }
    if (value.contains('air or root-zone temperature is elevated') ||
        value.contains('air or root zone temperature is elevated') ||
        value.contains('severe daytime heat') ||
        value.contains('severe night heat')) {
      return 'The air or soil around the roots is too hot.';
    }
    if (value.contains('atmospheric drying') ||
        value.contains('high vpd') ||
        value.contains('vpd indicates')) {
      return 'Dry air is pulling water from the plant quickly.';
    }
    if (value.contains('root-zone heat') ||
        value.contains('root zone heat') ||
        value.contains('root temperature high')) {
      return 'The soil around the roots is too hot.';
    }
    if (value.contains('water stress') ||
        value.contains('moisture deficit') ||
        value.contains('root zone is dry')) {
      return 'The plant needs more water.';
    }
    if (value.contains('possible biotic') ||
        value.contains('biotic stress') ||
        value.contains('unexplained plant stress')) {
      return 'A pest or disease may be affecting the plant. Check it closely.';
    }
    if (value.contains('camera') &&
        (value.contains('scan') || value.contains('inspect'))) {
      return 'Use the camera to check the plant.';
    }
    if (value.contains('probable watering') ||
        value.contains('irrigation likely')) {
      return 'Watering may have happened.';
    }
    if (value.contains('conditions improved') &&
        value.contains('stress remains')) {
      return 'Conditions are better, but the plant still needs attention.';
    }
    if (value.contains('recovering') &&
        value.contains('stress signal decreasing')) {
      return 'The plant is recovering.';
    }
    if (value.contains('root temperature is unavailable')) {
      return 'The root-temperature sensor is not working. The other sensors are still active.';
    }
    if (value.contains('light sensor is unavailable')) {
      return 'The light sensor is not working. The main plant check continues.';
    }
    if (value.contains('one or more channels have reduced confidence')) {
      return 'Some sensor information is unclear, so this result is less certain.';
    }
    if (value.contains('check the root-zone soil') &&
        value.contains('water if')) {
      return 'Check the soil near the roots. Water it if it is dry.';
    }
    if (value.contains('reduce heat exposure') &&
        value.contains('root-zone moisture')) {
      return 'Protect the plant from strong heat and check the soil near the roots.';
    }
    if (value.contains('inspect root-zone temperature') &&
        value.contains('drainage')) {
      return 'Check the soil near the roots, its temperature, and drainage.';
    }
    if (value.contains('reduce drying stress') &&
        value.contains('root-zone moisture')) {
      return 'Protect the plant from dry air and watch the soil near the roots.';
    }
    if (value.contains('no strong measured stress cause')) {
      return 'No main stress cause is clear now.';
    }
    if (value.contains('learning') && value.contains('baseline')) {
      return 'PhytoSense is learning this plant’s normal signal.';
    }
    if (value.contains('noisy') || value.contains('noise')) {
      return 'The plant sensor reading is not clear. Check that it touches the plant properly.';
    }
    if (value.contains('electrode') &&
        (value.contains('contact') || value.contains('check'))) {
      return 'Check that the plant sensor touches the plant properly.';
    }
    if (value.contains('reduced confidence') ||
        value.contains('low confidence')) {
      return 'This result is less certain because some sensor information is not clear.';
    }
    if (value.contains('sensor') &&
        (value.contains('unavailable') ||
            value.contains('missing') ||
            value.contains('fault'))) {
      return 'A sensor is not working now. Check its connection.';
    }
    if (value.contains('soil probe')) {
      return value
          .replaceAll('soil probe', 'soil sensor')
          .replaceAll('calibration', 'setup');
    }
    if (value.contains('leaf wetness') && value.contains('calibrat')) {
      return 'Set up the leaf sensor again.';
    }
    if (value.contains('disease conducive')) {
      return 'The weather may help disease grow. This does not confirm a disease.';
    }
    return null;
  }

  static String? _plainTamil(String value) {
    if (value.contains('collecting live sensor data') ||
        value.contains('first complete sensor frame') ||
        value.contains('waiting for a complete reliable sensor frame')) {
      return 'முதல் நல்ல சென்சார் அளவீட்டுக்காக காத்திருக்கிறது.';
    }
    if (value.contains('baseline learning paused')) {
      return 'செடிக்கு பிரச்சினை உள்ளதால் கற்றல் தற்காலிகமாக நிறுத்தப்பட்டுள்ளது.';
    }
    if ((value.contains('electrical response uncertain') ||
            value.contains('signal quality is not reliable')) &&
        (value.contains('electrode') || value.contains('plant electrical'))) {
      return 'செடி சென்சார் அளவீடு தெளிவாக இல்லை. அது செடியை சரியாக தொடுகிறதா பாருங்கள்.';
    }
    if (value.contains('electrical activity normal') ||
        value.contains('normal relative to learned baseline')) {
      return 'செடி சிக்னல் இயல்பாக உள்ளது.';
    }
    if (value.contains('root soil is dry') ||
        value.contains('root zone is critically dry')) {
      return 'வேர் அருகிலுள்ள மண் மிகவும் உலர்ந்துள்ளது.';
    }
    if (value.contains('air or root-zone temperature is elevated') ||
        value.contains('air or root zone temperature is elevated') ||
        value.contains('severe daytime heat') ||
        value.contains('severe night heat')) {
      return 'காற்று அல்லது வேர் சுற்றியுள்ள மண் மிகவும் சூடாக உள்ளது.';
    }
    if (value.contains('atmospheric drying') ||
        value.contains('high vpd') ||
        value.contains('vpd indicates')) {
      return 'உலர் காற்று செடியிலிருந்து நீரை வேகமாக இழுக்கிறது.';
    }
    if (value.contains('root-zone heat') ||
        value.contains('root zone heat') ||
        value.contains('root temperature high')) {
      return 'வேர் சுற்றியுள்ள மண் மிகவும் சூடாக உள்ளது.';
    }
    if (value.contains('water stress') ||
        value.contains('moisture deficit') ||
        value.contains('root zone is dry')) {
      return 'செடிக்கு அதிக நீர் தேவை.';
    }
    if (value.contains('possible biotic') ||
        value.contains('biotic stress') ||
        value.contains('unexplained plant stress')) {
      return 'பூச்சி அல்லது நோய் செடியை பாதிக்கலாம். செடியை நன்றாக பாருங்கள்.';
    }
    if (value.contains('camera') &&
        (value.contains('scan') || value.contains('inspect'))) {
      return 'கேமராவால் செடியை சரிபார்க்கவும்.';
    }
    if (value.contains('probable watering') ||
        value.contains('irrigation likely')) {
      return 'நீர் பாய்ச்சியிருக்கலாம்.';
    }
    if (value.contains('conditions improved') &&
        value.contains('stress remains')) {
      return 'சூழல் மேம்பட்டுள்ளது. ஆனால் செடிக்கு இன்னும் கவனம் தேவை.';
    }
    if (value.contains('recovering') &&
        value.contains('stress signal decreasing')) {
      return 'செடி மீண்டு வருகிறது.';
    }
    if (value.contains('root temperature is unavailable')) {
      return 'வேர் வெப்ப சென்சார் வேலை செய்யவில்லை. மற்ற சென்சார்கள் இயங்குகின்றன.';
    }
    if (value.contains('light sensor is unavailable')) {
      return 'ஒளி சென்சார் வேலை செய்யவில்லை. முக்கிய செடி சோதனை தொடர்கிறது.';
    }
    if (value.contains('one or more channels have reduced confidence')) {
      return 'சில சென்சார் தகவல்கள் தெளிவாக இல்லை. அதனால் முடிவு குறைவாக உறுதியாக உள்ளது.';
    }
    if (value.contains('check the root-zone soil') &&
        value.contains('water if')) {
      return 'வேர் அருகிலுள்ள மண்ணை பாருங்கள். உலர்ந்தால் நீர் பாய்ச்சவும்.';
    }
    if (value.contains('reduce heat exposure') &&
        value.contains('root-zone moisture')) {
      return 'அதிக வெப்பத்திலிருந்து செடியை பாதுகாத்து, வேர் அருகிலுள்ள மண்ணை பாருங்கள்.';
    }
    if (value.contains('inspect root-zone temperature') &&
        value.contains('drainage')) {
      return 'வேர் அருகிலுள்ள மண், அதன் வெப்பம் மற்றும் வடிகாலை பாருங்கள்.';
    }
    if (value.contains('reduce drying stress') &&
        value.contains('root-zone moisture')) {
      return 'உலர் காற்றிலிருந்து செடியை பாதுகாத்து, வேர் அருகிலுள்ள மண்ணை கவனிக்கவும்.';
    }
    if (value.contains('no strong measured stress cause')) {
      return 'இப்போது முக்கிய பிரச்சினைக்கான காரணம் தெளிவாக இல்லை.';
    }
    if (value.contains('learning') && value.contains('baseline')) {
      return 'இந்த செடியின் இயல்பான சிக்னலை PhytoSense கற்றுக்கொள்கிறது.';
    }
    if (value.contains('noisy') || value.contains('noise')) {
      return 'செடி சென்சார் அளவீடு தெளிவாக இல்லை. அது செடியை சரியாக தொடுகிறதா பாருங்கள்.';
    }
    if (value.contains('electrode') &&
        (value.contains('contact') || value.contains('check'))) {
      return 'செடி சென்சார் செடியை சரியாக தொடுகிறதா பாருங்கள்.';
    }
    if (value.contains('reduced confidence') ||
        value.contains('low confidence')) {
      return 'சில சென்சார் தகவல்கள் தெளிவாக இல்லாததால் இந்த முடிவு குறைவாக உறுதியாக உள்ளது.';
    }
    if (value.contains('sensor') &&
        (value.contains('unavailable') ||
            value.contains('missing') ||
            value.contains('fault'))) {
      return 'ஒரு சென்சார் இப்போது வேலை செய்யவில்லை. அதன் இணைப்பை பாருங்கள்.';
    }
    if (value.contains('leaf wetness') && value.contains('calibrat')) {
      return 'இலை சென்சாரை மீண்டும் அமைக்கவும்.';
    }
    if (value.contains('disease conducive')) {
      return 'இந்த வானிலை நோய் வளர உதவலாம். இது நோயை உறுதி செய்யவில்லை.';
    }
    return null;
  }

  static const _en = <String, String>{
    'nav': 'Analysis',
    'title': 'Farmer Analysis',
    'subtitle': 'What the ESP32 understands, explained clearly.',
    'overall': 'Overall condition',
    'do_now': 'What should I do now?',
    'happening': 'What is happening?',
    'next': 'What may happen next?',
    'why': 'Why is PhytoSense saying this?',
    'recovery': 'Recovery / Did watering help?',
    'sensor_summary': 'Sensor summary',
    'confidence': 'How sure is PhytoSense?',
    'avoid': 'What should I avoid?',
    'watch': 'What should I watch next?',
    'events': 'Recent important events',
    'technical': 'View Technical Details',
    'edge_source': 'Generated locally on ESP32',
    'fallback_source': 'Compatibility analysis in app',
    'node_score': 'Node Edge Score',
    'profile': 'Crop Profile',
    'stage': 'Growth stage',
    'primary': 'Primary',
    'secondary': 'Secondary',
    'contributor': 'Additional contributor',
    'no_major_stress': 'No major stress detected right now.',
    'monitor': 'Continue monitoring the live readings.',
    'no_prediction': 'No reliable near-term warning is available yet.',
    'no_recovery': 'No active recovery phase is being reported.',
    'no_events': 'No important recent events are being reported.',
    'full_analysis': 'Full analysis',
    'degraded_analysis': 'Reduced-confidence analysis',
    'active_channels': 'Active channels',
    'sensor_issues': 'Sensor issues',
    'environmental_risk': 'Environmental disease risk',
    'environmental_note':
        'This describes favourable conditions, not a confirmed disease.',
    'vpd': 'VPD (derived)',
    'air_drying': 'Air drying demand',
    'baseline': 'Adaptive baseline',
    'tinyml': 'TinyML model',
    'model_loaded': 'Loaded',
    'model_not_loaded': 'Not loaded',
    'explainable_engine':
        'Current edge intelligence uses explainable sensor fusion, root-cause analysis and recovery verification.',
    'irrigation_detected': 'Probable watering detected',
    'no_action_from_node':
        'The ESP32 has not issued a specific action. Keep monitoring.',
    'low_confidence_warning':
        'Check unreliable sensors before making a major decision.',
    'disconnected': 'ESP32 disconnected',
    'last_reading': 'Last reading',
  };

  static const _ta = <String, String>{
    'nav': 'பகுப்பாய்வு',
    'title': 'விவசாயி பகுப்பாய்வு',
    'subtitle': 'ESP32 புரிந்துகொண்டதை எளிய மொழியில் காட்டுகிறது.',
    'overall': 'மொத்த நிலை',
    'do_now': 'இப்போது என்ன செய்ய வேண்டும்?',
    'happening': 'இப்போது என்ன நடக்கிறது?',
    'next': 'அடுத்து என்ன நடக்கலாம்?',
    'why': 'PhytoSense ஏன் இதை சொல்கிறது?',
    'recovery': 'மீட்பு / நீர்ப்பாய்ச்சி உதவியதா?',
    'sensor_summary': 'சென்சார் சுருக்கம்',
    'confidence': 'PhytoSense எவ்வளவு நம்பிக்கையுடன் உள்ளது?',
    'avoid': 'எதை தவிர்க்க வேண்டும்?',
    'watch': 'அடுத்து எதை கவனிக்க வேண்டும்?',
    'events': 'சமீபத்திய முக்கிய நிகழ்வுகள்',
    'technical': 'தொழில்நுட்ப விவரங்கள்',
    'edge_source': 'ESP32-ல் உள்ளூராக உருவாக்கப்பட்டது',
    'fallback_source': 'பழைய சாதன மென்பொருளுக்கான இணக்கப் பகுப்பாய்வு',
    'node_score': 'சாதனம் வழங்கிய மதிப்பெண்',
    'profile': 'பயிர் விவரம்',
    'stage': 'வளர்ச்சி நிலை',
    'primary': 'முக்கிய காரணம்',
    'secondary': 'இரண்டாம் காரணம்',
    'contributor': 'கூடுதல் காரணம்',
    'no_major_stress': 'இப்போது பெரிய பிரச்சினை எதுவும் கண்டறியப்படவில்லை.',
    'monitor': 'நேரடி அளவீடுகளைத் தொடர்ந்து கவனிக்கவும்.',
    'no_prediction': 'நம்பகமான அருகிலுள்ள எச்சரிக்கை இன்னும் இல்லை.',
    'no_recovery': 'செடி மீளும் நிலை தற்போது தெரிவிக்கப்படவில்லை.',
    'no_events': 'சமீபத்திய முக்கிய நிகழ்வுகள் எதுவும் தெரிவிக்கப்படவில்லை.',
    'full_analysis': 'முழு பகுப்பாய்வு',
    'degraded_analysis': 'குறைந்த நம்பிக்கை பகுப்பாய்வு',
    'active_channels': 'செயலில் உள்ள சென்சார்கள்',
    'sensor_issues': 'சென்சார் பிரச்சினைகள்',
    'environmental_risk': 'சுற்றுச்சூழல் நோய் அபாயம்',
    'environmental_note':
        'இது நோய்க்கு சாதகமான சூழலை மட்டும் குறிக்கும்; உறுதியான நோய் கண்டறிதல் அல்ல.',
    'vpd': 'VPD (கணக்கிடப்பட்டது)',
    'air_drying': 'காற்றின் உலர்த்தும் தாக்கம்',
    'baseline': 'செடிக்கு ஏற்ப மாறும் இயல்பு அளவு',
    'tinyml': 'சிறிய இயந்திரக் கற்றல் மாதிரி',
    'model_loaded': 'ஏற்றப்பட்டது',
    'model_not_loaded': 'ஏற்றப்படவில்லை',
    'explainable_engine':
        'சாதனம் சென்சார் தகவல்களை இணைத்து, காரணத்தையும் அடுத்து ஏற்படக்கூடிய மாற்றத்தையும் விளக்குகிறது.',
    'irrigation_detected': 'நீர்ப்பாய்ச்சி நடந்திருக்கலாம்',
    'no_action_from_node':
        'ESP32 குறிப்பிட்ட செயலை இன்னும் சொல்லவில்லை. தொடர்ந்து கண்காணிக்கவும்.',
    'low_confidence_warning':
        'பெரிய முடிவு எடுப்பதற்கு முன் நம்பகமற்ற சென்சார்களைச் சரிபார்க்கவும்.',
    'disconnected': 'ESP32 இணைப்பு துண்டிக்கப்பட்டது',
    'last_reading': 'கடைசி அளவீடு',
  };

  static const _knownEn = <String, String>{
    'HEALTHY': 'Healthy',
    'EXCELLENT': 'Excellent',
    'GOOD': 'Good',
    'WATCH': 'Watch closely',
    'STRESSED': 'Stressed',
    'HIGH_STRESS': 'High stress',
    'CRITICAL': 'Critical',
    'RECOVERING': 'Recovering',
    'LOW_CONFIDENCE': 'Low confidence',
    'KEEP_MONITORING': 'Continue monitoring.',
    'CONTINUE_MONITORING': 'Continue monitoring.',
    'WATER_THE_ROOT_ZONE': 'Water the root zone evenly.',
    'WATER_ROOT_ZONE': 'Water the root zone evenly.',
    'CHECK_SOIL_SENSOR': 'Check the soil-moisture sensor and its connection.',
    'CHECK_DRAINAGE': 'Check drainage before adding more water.',
    'REDUCE_HEAT_EXPOSURE': 'Reduce heat exposure if practical.',
    'IMPROVE_AIRFLOW': 'Improve airflow and keep leaves dry where possible.',
    'LEARNING_BASELINE': 'Learning this plant’s normal electrical pattern',
    'BASELINE_STABLE': 'Electrical pattern is close to its learned baseline',
    'STRESS_CORROBORATED':
        'Electrical change supports stress seen by other sensors',
    'COMPOUND_HEAT_AND_WATER_STRESS':
        'Heat and dry soil are stressing the plant',
    'VERY_LOW_SOIL_MOISTURE_HIGH_TEMPERATURE_AND_HIGH_VPD_AGREE':
        'Soil is very dry and the air is hot and dry.',
    'BIOELECTRIC_RESPONSE_IS_STRONG_AND_CORROBORATED_BY_ENVIRONMENTAL_CHANNELS':
        'The plant signal agrees with the soil and climate readings.',
    'VPD_IS_HIGH_WHILE_ROOT_ZONE_MOISTURE_REMAINS_ADEQUATE':
        'The air is drying the plant quickly, but the root zone still has moisture.',
    'NO_DATA': 'No reliable reading',
  };

  static const _knownTa = <String, String>{
    'KEEP_THE_ELECTRODES_STABLE_AND_ALLOW_BASELINE_LEARNING_TO_FINISH':
        'செடி சென்சாரை அசையாமல் வைத்து, இயல்பான சிக்னலைக் கற்றுக்கொள்ள விடுங்கள்.',
    'CHECK_ROOT_ZONE_MOISTURE_FIRST_IF_THE_SOIL_IS_DRYING_IRRIGATE_DURING_THE_COOLER_PART_OF_THE_DAY_OTHERWISE_REDUCE_AVOIDABLE_HEAT_WIND_OR_DIRECT_EXPOSURE_WHERE_PRACTICAL':
        'முதலில் வேர் அருகே மண் ஈரத்தைப் பாருங்கள். மண் உலர்ந்தால் குளிரான நேரத்தில் நீர் ஊற்றுங்கள். இல்லையெனில் முடிந்த அளவு அதிக வெப்பம், காற்று, நேரடி வெளிச்சத்திலிருந்து பாதுகாக்கவும்.',
    'CONFIRM_THE_ROOT_ZONE_IS_ACTUALLY_DRY_THEN_IRRIGATE_APPROPRIATELY_FOR_THE_PLANT_AND_POT':
        'வேர் அருகே மண் உலர்ந்துள்ளதா உறுதி செய்யுங்கள். பிறகு செடிக்கும் தொட்டிக்கும் ஏற்ற அளவு நீர் ஊற்றுங்கள்.',
    'AVOID_UNNECESSARY_WATERING_AND_CHECK_DRAINAGE_AND_ROOT_ZONE_AERATION':
        'தேவையின்றி நீர் ஊற்ற வேண்டாம். அதிக நீர் வெளியேறவும் வேர் பகுதியில் காற்று செல்லவும் வழி உள்ளதா பாருங்கள்.',
    'CHECK_ROOT_ZONE_MOISTURE_AND_REDUCE_AVOIDABLE_HEAT_EXPOSURE_WHERE_PRACTICAL':
        'வேர் அருகே மண் ஈரத்தைப் பாருங்கள். முடிந்தால் அதிக வெப்பத்திலிருந்து பாதுகாக்கவும்.',
    'KEEP_MONITORING_THE_PLANT_RESPONSE_AND_INSPECT_THE_PLANT_IF_THE_SIGNAL_PERSISTS_WITHOUT_AN_ENVIRONMENTAL_EXPLANATION':
        'செடி சிக்னலை தொடர்ந்து கவனிக்கவும். சூழலில் காரணம் தெரியாமல் சிக்னல் மாற்றம் தொடர்ந்தால் செடியை நேரில் பாருங்கள்.',
    'CONTINUE_MONITORING_AND_AVOID_UNNECESSARY_INTERVENTION_WHILE_RECOVERY_CONTINUES':
        'செடி மீண்டு வரும்போது தொடர்ந்து கண்காணிக்கவும். தேவையற்ற மாற்றங்களைத் தவிர்க்கவும்.',
    'IMPROVE_AIRFLOW_WHERE_PRACTICAL_AND_INSPECT_LEAVES_AND_STEMS_FOR_VISIBLE_SYMPTOMS':
        'முடிந்தால் காற்றோட்டத்தை அதிகரிக்கவும். இலைகளிலும் தண்டிலும் பாதிப்பு உள்ளதா பாருங்கள்.',
    'CHECK_SHADE_COVER_OR_PLACEMENT_BEFORE_CHANGING_IRRIGATION':
        'நீர் ஊற்றும் முறையை மாற்றும் முன் நிழல், மூடல், செடி வைக்கப்பட்ட இடத்தைப் பாருங்கள்.',
    'INSPECT_THE_ROOT_ZONE_IMMEDIATELY_AND_REDUCE_HEAT_EXPOSURE_WHERE_PRACTICAL':
        'வேர் அருகே மண்ணை உடனே பாருங்கள். முடிந்தால் அதிக வெப்பத்திலிருந்து செடியைப் பாதுகாக்கவும்.',
    'CHECK_SENSOR_CONNECTIONS_OR_SWITCH_BACK_TO_A_HEALTHY_SIMULATION_SCENARIO':
        'சென்சார் இணைப்புகளைச் சரிபார்க்கவும் அல்லது ஆரோக்கியமான மாதிரி நிலையைத் தேர்வு செய்யவும்.',
    'RETRY_THE_SIMULATION_CONNECTION_OR_CHOOSE_ANOTHER_SCENARIO':
        'மாதிரி இணைப்பை மீண்டும் முயற்சிக்கவும் அல்லது வேறு நிலையைத் தேர்வு செய்யவும்.',
    'CONTINUE_NORMAL_MONITORING': 'வழக்கம்போல் தொடர்ந்து கண்காணிக்கவும்.',
    'INSPECT_LEAVES_AND_STEMS_FOR_SYMPTOMS_AND_IMPROVE_AIRFLOW_WHERE_PRACTICAL':
        'இலைகளிலும் தண்டிலும் பாதிப்பு உள்ளதா பாருங்கள். முடிந்தால் காற்றோட்டத்தை அதிகரிக்கவும்.',
    'USE_THE_CAMERA_INSPECTION_FLOW_TO_LOOK_FOR_VISIBLE_SYMPTOMS':
        'கேமரா மூலம் செடியில் தெரியும் பாதிப்புகளைப் பாருங்கள்.',
    'COMPOUND_HEAT_AND_WATER_STRESS':
        'அதிக வெப்பமும் நீர் பற்றாக்குறையும் செடியை பாதிக்கின்றன',
    'VERY_LOW_SOIL_MOISTURE_HIGH_TEMPERATURE_AND_HIGH_VPD_AGREE':
        'மண்ணில் ஈரம் மிகக் குறைவு. காற்று சூடாகவும் உலர்ந்தும் உள்ளது.',
    'BIOELECTRIC_RESPONSE_IS_STRONG_AND_CORROBORATED_BY_ENVIRONMENTAL_CHANNELS':
        'செடி சிக்னல் மாற்றத்தை மற்ற சூழல் அளவீடுகளும் ஆதரிக்கின்றன.',
    'CONDITIONS_ARE_CURRENTLY_ACCEPTABLE': 'இப்போது நிலை ஏற்றதாக உள்ளது.',
    'HEALTHY': 'ஆரோக்கியமான நிலை',
    'EXCELLENT': 'மிக நல்ல நிலை',
    'GOOD': 'நல்ல நிலை',
    'WATCH': 'கவனமாக கண்காணிக்கவும்',
    'STRESSED': 'செடிக்கு பாதிப்பு உள்ளது',
    'HIGH_STRESS': 'அதிக பாதிப்பு',
    'CRITICAL': 'முக்கிய அவசர நிலை',
    'RECOVERING': 'மீண்டு வருகிறது',
    'LOW_CONFIDENCE': 'குறைந்த நம்பிக்கை',
    'KEEP_MONITORING': 'தொடர்ந்து கண்காணிக்கவும்.',
    'CONTINUE_MONITORING': 'தொடர்ந்து கண்காணிக்கவும்.',
    'WATER_THE_ROOT_ZONE': 'வேர் பகுதியை சமமாக நீர்ப்பாய்ச்சவும்.',
    'WATER_ROOT_ZONE': 'வேர் பகுதியை சமமாக நீர்ப்பாய்ச்சவும்.',
    'CHECK_SOIL_SENSOR':
        'மண் ஈரப்பத சென்சார் மற்றும் இணைப்பைச் சரிபார்க்கவும்.',
    'CHECK_DRAINAGE': 'மேலும் நீர் சேர்ப்பதற்கு முன் வடிகாலைச் சரிபார்க்கவும்.',
    'REDUCE_HEAT_EXPOSURE': 'முடிந்தால் அதிக வெப்ப தாக்கத்தை குறைக்கவும்.',
    'IMPROVE_AIRFLOW':
        'காற்றோட்டத்தை மேம்படுத்தி இலைகளை இயன்றவரை உலர வைத்திருக்கவும்.',
    'LEARNING_BASELINE':
        'இந்த செடியின் இயல்பான மின்சார மாற்றம் கற்றுக்கொள்ளப்படுகிறது',
    'BASELINE_STABLE':
        'மின்சார மாற்றம் கற்றுக்கொண்ட இயல்பு நிலைக்கு அருகில் உள்ளது',
    'STRESS_CORROBORATED':
        'மற்ற சென்சார்கள் காட்டும் பாதிப்பை மின்சார மாற்றமும் ஆதரிக்கிறது',
    'NO_DATA': 'நம்பகமான அளவீடு இல்லை',
  };
}
