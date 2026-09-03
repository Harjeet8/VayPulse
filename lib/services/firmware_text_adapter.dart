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

  static String text(BuildContext context, String? raw, {String fallback = ''}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final clean = raw.trim();
    final key = clean
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final known = (_tamil(context) ? _knownTa : _knownEn)[key];
    if (known != null) return known;

    // Never surface engineering shorthand as farmer advice. Unknown future
    // phrases are retained, but common implementation terms are softened.
    return clean
        .replaceAll(RegExp(r'\bADC\b', caseSensitive: false), 'sensor reading')
        .replaceAll(RegExp(r'\bEMA\b', caseSensitive: false), 'recent trend')
        .replaceAll(RegExp(r'\bZ[- ]?score\b', caseSensitive: false), 'unusual change')
        .replaceAll(RegExp(r'feature vector', caseSensitive: false), 'sensor pattern')
        .replaceAll(RegExp(r'regression slope', caseSensitive: false), 'rate of change')
        .replaceAll(RegExp(r'weighted fusion', caseSensitive: false), 'combined sensor evidence');
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
    'environmental_note': 'This describes favourable conditions, not a confirmed disease.',
    'vpd': 'VPD (derived)',
    'air_drying': 'Air drying demand',
    'baseline': 'Adaptive baseline',
    'tinyml': 'TinyML model',
    'model_loaded': 'Loaded',
    'model_not_loaded': 'Not loaded',
    'explainable_engine': 'Current edge intelligence uses explainable sensor fusion, root-cause analysis and recovery verification.',
    'irrigation_detected': 'Probable watering detected',
    'no_action_from_node': 'The ESP32 has not issued a specific action. Keep monitoring.',
    'low_confidence_warning': 'Check unreliable sensors before making a major decision.',
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
    'fallback_source': 'பழைய firmware-க்கு app compatibility analysis',
    'node_score': 'Node Edge மதிப்பெண்',
    'profile': 'பயிர் Profile',
    'stage': 'வளர்ச்சி நிலை',
    'primary': 'முக்கிய காரணம்',
    'secondary': 'இரண்டாம் காரணம்',
    'contributor': 'கூடுதல் காரணம்',
    'no_major_stress': 'இப்போது பெரிய stress எதுவும் கண்டறியப்படவில்லை.',
    'monitor': 'Live readings-ஐ தொடர்ந்து கவனிக்கவும்.',
    'no_prediction': 'நம்பகமான அருகிலுள்ள எச்சரிக்கை இன்னும் இல்லை.',
    'no_recovery': 'செயலில் உள்ள recovery நிலை தற்போது தெரிவிக்கப்படவில்லை.',
    'no_events': 'சமீபத்திய முக்கிய நிகழ்வுகள் எதுவும் தெரிவிக்கப்படவில்லை.',
    'full_analysis': 'முழு பகுப்பாய்வு',
    'degraded_analysis': 'குறைந்த நம்பிக்கை பகுப்பாய்வு',
    'active_channels': 'செயலில் உள்ள channels',
    'sensor_issues': 'சென்சார் பிரச்சினைகள்',
    'environmental_risk': 'சுற்றுச்சூழல் நோய் அபாயம்',
    'environmental_note': 'இது நோய்க்கு சாதகமான சூழலை மட்டும் குறிக்கும்; உறுதியான நோய் கண்டறிதல் அல்ல.',
    'vpd': 'VPD (கணக்கிடப்பட்டது)',
    'air_drying': 'காற்றின் உலர்த்தும் தாக்கம்',
    'baseline': 'தகவமைக்கும் baseline',
    'tinyml': 'TinyML model',
    'model_loaded': 'Loaded',
    'model_not_loaded': 'Load செய்யப்படவில்லை',
    'explainable_engine': 'தற்போதைய edge intelligence விளக்கக்கூடிய sensor fusion மற்றும் prediction பயன்படுத்துகிறது.',
    'irrigation_detected': 'நீர்ப்பாய்ச்சி நடந்திருக்கலாம்',
    'no_action_from_node': 'ESP32 குறிப்பிட்ட செயலை இன்னும் சொல்லவில்லை. தொடர்ந்து கண்காணிக்கவும்.',
    'low_confidence_warning': 'பெரிய முடிவு எடுப்பதற்கு முன் நம்பகமற்ற சென்சார்களைச் சரிபார்க்கவும்.',
    'disconnected': 'ESP32 இணைப்பு துண்டிக்கப்பட்டது',
    'last_reading': 'கடைசி reading',
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
    'STRESS_CORROBORATED': 'Electrical change supports stress seen by other sensors',
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
    'HEALTHY': 'ஆரோக்கியமான நிலை',
    'EXCELLENT': 'மிக நல்ல நிலை',
    'GOOD': 'நல்ல நிலை',
    'WATCH': 'கவனமாக கண்காணிக்கவும்',
    'STRESSED': 'Stress உள்ளது',
    'HIGH_STRESS': 'அதிக stress',
    'CRITICAL': 'முக்கிய அவசர நிலை',
    'RECOVERING': 'மீண்டு வருகிறது',
    'LOW_CONFIDENCE': 'குறைந்த நம்பிக்கை',
    'KEEP_MONITORING': 'தொடர்ந்து கண்காணிக்கவும்.',
    'CONTINUE_MONITORING': 'தொடர்ந்து கண்காணிக்கவும்.',
    'WATER_THE_ROOT_ZONE': 'வேர் பகுதியை சமமாக நீர்ப்பாய்ச்சவும்.',
    'WATER_ROOT_ZONE': 'வேர் பகுதியை சமமாக நீர்ப்பாய்ச்சவும்.',
    'CHECK_SOIL_SENSOR': 'மண் ஈரப்பத சென்சார் மற்றும் இணைப்பைச் சரிபார்க்கவும்.',
    'CHECK_DRAINAGE': 'மேலும் நீர் சேர்ப்பதற்கு முன் drainage-ஐ சரிபார்க்கவும்.',
    'REDUCE_HEAT_EXPOSURE': 'முடிந்தால் அதிக வெப்ப தாக்கத்தை குறைக்கவும்.',
    'IMPROVE_AIRFLOW': 'காற்றோட்டத்தை மேம்படுத்தி இலைகளை இயன்றவரை உலர வைத்திருக்கவும்.',
    'LEARNING_BASELINE': 'இந்த செடியின் இயல்பான மின்சார pattern கற்றுக்கொள்ளப்படுகிறது',
    'BASELINE_STABLE': 'மின்சார pattern கற்ற baseline-க்கு அருகில் உள்ளது',
    'STRESS_CORROBORATED': 'மற்ற சென்சார்கள் காட்டும் stress-ஐ மின்சார மாற்றமும் ஆதரிக்கிறது',
    'NO_DATA': 'நம்பகமான reading இல்லை',
  };
}
