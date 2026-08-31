import 'package:flutter/widgets.dart';

import 'app_scope.dart';

class FarmerLanguage {
  const FarmerLanguage._();

  static bool _ta(BuildContext context) =>
      AppScope.of(context).settings.value.languageCode == 'ta';

  static bool isTamil(BuildContext context) => _ta(context);

  static String label(BuildContext context, String key) {
    final map = _ta(context) ? _taLabels : _enLabels;
    return map[key] ?? _enLabels[key] ?? key;
  }

  static String firmware(BuildContext context, String? raw,
      {String fallback = ''}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final clean = raw.trim();
    final key = clean
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final map = _ta(context) ? _taFirmware : _enFirmware;
    return map[key] ?? clean;
  }

  static String confidence(BuildContext context, double? value) {
    if (value != null && value >= 80) return label(context, 'high');
    if (value != null && value >= 55) return label(context, 'medium');
    return label(context, 'low');
  }

  static const _enLabels = <String, String>{
    'analysis': 'Analysis',
    'live_sensors': 'Live Sensors',
    'farmer_analysis': 'Farmer Analysis',
    'farmer_subtitle': 'Simple guidance from the live plant condition.',
    'plant_condition': 'Plant Condition',
    'main_problem': 'Main Problem',
    'what_changed': 'What Changed',
    'what_to_do': 'What To Do',
    'analysis_confidence': 'Analysis Confidence',
    'advanced_details': 'Advanced Details',
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
    'no_problem': 'No major problem reported right now.',
    'no_change': 'No important recent change has been reported yet.',
    'keep_monitoring': 'Keep monitoring the plant.',
    'disconnected': 'ESP32 disconnected',
    'last_reading': 'Last reading',
    'live_subtitle': 'Real-time measurements and the ESP32 interpretation behind the plant result.',
    'air': 'Air',
    'light': 'Light',
    'soil_root': 'Soil & Root',
    'leaf': 'Leaf',
    'plant_signal': 'Plant Signal',
    'intelligence': 'Intelligence',
    'result': 'Result',
    'trend': 'Trend',
    'confidence': 'Confidence',
    'rate': 'Rate of change',
    'status': 'Status',
    'data_age': 'Data age',
    'effect': 'Effect on plant result',
    'technical': 'Technical',
    'raw': 'Raw reading',
    'unavailable': 'Sensor Unavailable',
    'no_interpretation': 'ESP32 interpretation not provided',
    'no_trend': 'Trend not provided',
    'no_confidence': 'Confidence not provided',
    'crop_profile': 'Crop Profile',
    'main_finding': 'Main finding',
    'secondary_finding': 'Secondary finding',
    'analysis_quality': 'Analysis quality',
    'disease_risk': 'Environmental Disease Risk',
    'disease_note': 'Environmental disease-conducive risk only — not a confirmed disease.',
    'air_temp': 'Air Temperature',
    'humidity': 'Relative Humidity',
    'light_lux': 'Light',
    'soil_moisture': 'Soil Moisture',
    'root_temp': 'Root / Soil Temperature',
    'leaf_wetness': 'Leaf Wetness',
    'bio_signal': 'Plant Bioelectric Signal',
    'bio_baseline': 'Bioelectric baseline',
    'bio_deviation': 'Bioelectric deviation',
    'air_root_delta': 'Air–Root Temperature Difference',
    'vpd': 'VPD / Air Drying Demand',
    'wet_duration': 'Leaf Wetness Duration',
    'day_phase': 'Day / Night phase',
    'health_score': 'Health score',
    'plant_state': 'Plant state',
    'baseline_note': 'Plant voltage is interpreted only relative to this plant’s learned baseline.',
    'vpd_note': 'This is a derived air-drying metric, not a direct sensor reading.',
  };

  static const _taLabels = <String, String>{
    'analysis': 'பகுப்பாய்வு',
    'live_sensors': 'Live Sensors',
    'farmer_analysis': 'விவசாயி பகுப்பாய்வு',
    'farmer_subtitle': 'நேரடி செடி நிலையை எளிய வழிகாட்டலாக காட்டுகிறது.',
    'plant_condition': 'செடியின் நிலை',
    'main_problem': 'முக்கிய பிரச்சினை',
    'what_changed': 'என்ன மாற்றம் ஏற்பட்டது?',
    'what_to_do': 'என்ன செய்ய வேண்டும்?',
    'analysis_confidence': 'பகுப்பாய்வு நம்பிக்கை',
    'advanced_details': 'மேம்பட்ட விவரங்கள்',
    'high': 'உயர்',
    'medium': 'நடுத்தரம்',
    'low': 'குறைவு',
    'no_problem': 'இப்போது பெரிய பிரச்சினை எதுவும் தெரிவிக்கப்படவில்லை.',
    'no_change': 'முக்கியமான சமீப மாற்றம் இன்னும் தெரிவிக்கப்படவில்லை.',
    'keep_monitoring': 'செடியை தொடர்ந்து கண்காணிக்கவும்.',
    'disconnected': 'ESP32 இணைப்பு துண்டிக்கப்பட்டது',
    'last_reading': 'கடைசி reading',
    'live_subtitle': 'நேரடி அளவீடுகள் மற்றும் plant result-க்கு பின்னுள்ள ESP32 விளக்கம்.',
    'air': 'காற்று',
    'light': 'ஒளி',
    'soil_root': 'மண் & வேர்',
    'leaf': 'இலை',
    'plant_signal': 'செடி மின்சார சிக்னல்',
    'intelligence': 'பகுப்பாய்வு',
    'result': 'முடிவு',
    'trend': 'போக்கு',
    'confidence': 'நம்பிக்கை',
    'rate': 'மாற்ற வேகம்',
    'status': 'நிலை',
    'data_age': 'தரவு வயது',
    'effect': 'செடி முடிவில் தாக்கம்',
    'technical': 'தொழில்நுட்பம்',
    'raw': 'Raw reading',
    'unavailable': 'சென்சார் கிடைக்கவில்லை',
    'no_interpretation': 'ESP32 விளக்கம் வழங்கவில்லை',
    'no_trend': 'போக்கு தகவல் இல்லை',
    'no_confidence': 'நம்பிக்கை தகவல் இல்லை',
    'crop_profile': 'பயிர் Profile',
    'main_finding': 'முக்கிய கண்டுபிடிப்பு',
    'secondary_finding': 'இரண்டாம் கண்டுபிடிப்பு',
    'analysis_quality': 'பகுப்பாய்வு தரம்',
    'disease_risk': 'சுற்றுச்சூழல் நோய் அபாயம்',
    'disease_note': 'இது நோய்க்கு சாதகமான சூழல் அபாயம் மட்டும்; உறுதியான நோய் கண்டறிதல் அல்ல.',
    'air_temp': 'காற்று வெப்பநிலை',
    'humidity': 'ஈரப்பதம்',
    'light_lux': 'ஒளி',
    'soil_moisture': 'மண் ஈரப்பதம்',
    'root_temp': 'வேர் / மண் வெப்பநிலை',
    'leaf_wetness': 'இலை ஈரப்பதம்',
    'bio_signal': 'செடி மின்சார சிக்னல்',
    'bio_baseline': 'Bioelectric baseline',
    'bio_deviation': 'Bioelectric deviation',
    'air_root_delta': 'காற்று–வேர் வெப்பநிலை வேறுபாடு',
    'vpd': 'VPD / காற்றின் உலர்த்தும் தாக்கம்',
    'wet_duration': 'இலை ஈரமாக இருந்த நேரம்',
    'day_phase': 'பகல் / இரவு நிலை',
    'health_score': 'Health score',
    'plant_state': 'செடி நிலை',
    'baseline_note': 'செடி voltage இந்த செடியின் கற்ற baseline-ஐ ஒப்பிட்டு மட்டுமே விளக்கப்படுகிறது.',
    'vpd_note': 'இது நேரடி sensor reading அல்ல; கணக்கிடப்பட்ட air-drying metric.',
  };

  static const _enFirmware = <String, String>{
    'HEALTHY': 'Healthy', 'EXCELLENT': 'Excellent', 'GOOD': 'Good', 'ACCEPTABLE': 'Acceptable',
    'NEEDS_ATTENTION': 'Needs Attention', 'WATCH': 'Needs Attention', 'STRESSED': 'Stressed',
    'HIGH_STRESS': 'High Stress', 'CRITICAL': 'Critical', 'RECOVERING': 'Recovering',
    'LOW': 'Low', 'HIGH': 'High', 'DRY': 'Dry', 'VERY_DRY': 'Very Dry', 'WET': 'Wet',
    'TOO_WET': 'Too Wet', 'VERY_WET': 'Very Wet', 'COOL': 'Cool', 'WARM': 'Warm',
    'WARM_NIGHT': 'Warm Night', 'HOT': 'Too Hot', 'HEAT_STRESS': 'Heat Stress',
    'EXTREME_HEAT': 'Extreme Heat', 'OPTIMAL': 'Good', 'STABLE': 'Stable', 'RISING': 'Rising',
    'RISING_FAST': 'Rising Quickly', 'RISING_QUICKLY': 'Rising Quickly', 'FALLING': 'Falling',
    'FALLING_FAST': 'Falling Quickly', 'FALLING_QUICKLY': 'Falling Quickly',
    'MISSING': 'Sensor Unavailable', 'UNAVAILABLE': 'Sensor Unavailable',
    'INVALID': 'Reading Unreliable', 'STALE': 'Reading Delayed',
    'LEARNING_BASELINE': 'Learning this plant’s normal electrical pattern',
    'BASELINE_STABLE': 'Stable relative to learned baseline',
    'STRESS_CORROBORATED': 'Electrical change supports stress seen by other sensors',
    'STRONG_EP_CHANGE': 'Strong change from learned baseline', 'EP_CHANGE': 'Changed from learned baseline',
    'KEEP_MONITORING': 'Keep monitoring the plant.', 'WATER_SOON': 'Water the root zone soon.',
    'WATER_ROOT_ZONE_NOW': 'Water the root zone now.',
    'DRY_LEAVES_VENTILATE': 'Dry the leaves and improve airflow.',
    'KEEP_LEAVES_DRY': 'Keep the leaves dry and improve airflow.',
    'CHECK_DRAINAGE_PAUSE_WATER': 'Check drainage and pause watering.',
    'COOL_ROOT_ZONE': 'Reduce heat around the root zone.',
    'PROTECT_ROOT_ZONE': 'Protect the root zone from temperature extremes.',
    'INSPECT_PLANT_TODAY': 'Inspect the plant today.',
    'CALIBRATE_LEAF_SENSOR': 'Calibrate the leaf-wetness sensor.',
    'CHECK_SENSOR_WIRING': 'Check the sensor connection.',
    'NO_URGENT_STRESS_DETECTED': 'No urgent stress detected',
    'ROOT_ZONE_IS_DRY': 'Root-zone moisture is low',
    'HIGH_DISEASE_CONDUCIVE_CONDITIONS': 'Conditions are highly favourable for disease development',
    'LEAF_WETNESS_RISK_IS_RISING': 'Leaf-wetness related environmental risk is rising',
    'SOIL_INDEX_STAYED_VERY_WET': 'Soil has stayed very wet',
  };

  static const _taFirmware = <String, String>{
    'HEALTHY': 'ஆரோக்கியமான நிலை', 'EXCELLENT': 'மிக நல்ல நிலை', 'GOOD': 'நல்ல நிலை',
    'ACCEPTABLE': 'ஏற்ற நிலை', 'NEEDS_ATTENTION': 'கவனம் தேவை', 'WATCH': 'கவனம் தேவை',
    'STRESSED': 'Stress உள்ளது', 'HIGH_STRESS': 'அதிக stress', 'CRITICAL': 'அவசர நிலை',
    'RECOVERING': 'மீண்டு வருகிறது', 'LOW': 'குறைவு', 'HIGH': 'அதிகம்', 'DRY': 'உலர்',
    'VERY_DRY': 'மிகவும் உலர்', 'WET': 'ஈரமாக உள்ளது', 'TOO_WET': 'அதிக ஈரம்',
    'VERY_WET': 'மிக அதிக ஈரம்', 'COOL': 'குளிர்ச்சி', 'WARM': 'சூடாக உள்ளது',
    'WARM_NIGHT': 'சூடான இரவு', 'HOT': 'அதிக வெப்பம்', 'HEAT_STRESS': 'வெப்ப stress',
    'EXTREME_HEAT': 'மிக அதிக வெப்பம்', 'OPTIMAL': 'நல்ல நிலை', 'STABLE': 'நிலையாக உள்ளது',
    'RISING': 'அதிகரிக்கிறது', 'RISING_FAST': 'வேகமாக அதிகரிக்கிறது',
    'RISING_QUICKLY': 'வேகமாக அதிகரிக்கிறது', 'FALLING': 'குறைகிறது',
    'FALLING_FAST': 'வேகமாக குறைகிறது', 'FALLING_QUICKLY': 'வேகமாக குறைகிறது',
    'MISSING': 'சென்சார் கிடைக்கவில்லை', 'UNAVAILABLE': 'சென்சார் கிடைக்கவில்லை',
    'INVALID': 'Reading நம்பகமில்லை', 'STALE': 'Reading தாமதமாக உள்ளது',
    'LEARNING_BASELINE': 'இந்த செடியின் இயல்பான மின்சார pattern கற்றுக்கொள்ளப்படுகிறது',
    'BASELINE_STABLE': 'கற்ற baseline-ஐ ஒப்பிடும்போது நிலையாக உள்ளது',
    'STRESS_CORROBORATED': 'மற்ற சென்சார்கள் காட்டும் stress-ஐ மின்சார மாற்றமும் ஆதரிக்கிறது',
    'STRONG_EP_CHANGE': 'கற்ற baseline-இலிருந்து பெரிய மாற்றம்', 'EP_CHANGE': 'கற்ற baseline-இலிருந்து மாற்றம்',
    'KEEP_MONITORING': 'செடியை தொடர்ந்து கண்காணிக்கவும்.',
    'WATER_SOON': 'வேர் பகுதியை விரைவில் நீர்ப்பாய்ச்சவும்.',
    'WATER_ROOT_ZONE_NOW': 'வேர் பகுதியை இப்போது நீர்ப்பாய்ச்சவும்.',
    'DRY_LEAVES_VENTILATE': 'இலைகளை உலர வைத்து காற்றோட்டத்தை மேம்படுத்தவும்.',
    'KEEP_LEAVES_DRY': 'இலைகளை உலர வைத்துக் காற்றோட்டத்தை மேம்படுத்தவும்.',
    'CHECK_DRAINAGE_PAUSE_WATER': 'Drainage-ஐ சரிபார்த்து நீர்ப்பாய்ச்சலை தற்காலிகமாக நிறுத்தவும்.',
    'COOL_ROOT_ZONE': 'வேர் பகுதியின் வெப்பத்தை குறைக்கவும்.',
    'PROTECT_ROOT_ZONE': 'வேர் பகுதியை அதிக வெப்பம்/குளிரிலிருந்து பாதுகாக்கவும்.',
    'INSPECT_PLANT_TODAY': 'இன்று செடியை நேரில் பாருங்கள்.',
    'CALIBRATE_LEAF_SENSOR': 'Leaf-wetness sensor-ஐ calibrate செய்யவும்.',
    'CHECK_SENSOR_WIRING': 'சென்சார் இணைப்பைச் சரிபார்க்கவும்.',
    'NO_URGENT_STRESS_DETECTED': 'அவசரமான stress இல்லை',
    'ROOT_ZONE_IS_DRY': 'வேர் பகுதியில் ஈரப்பதம் குறைவாக உள்ளது',
    'HIGH_DISEASE_CONDUCIVE_CONDITIONS': 'நோய் வளர்ச்சிக்கு மிகவும் சாதகமான சூழல் உள்ளது',
    'LEAF_WETNESS_RISK_IS_RISING': 'இலை ஈரத்துடன் தொடர்புடைய சுற்றுச்சூழல் அபாயம் அதிகரிக்கிறது',
    'SOIL_INDEX_STAYED_VERY_WET': 'மண் நீண்ட நேரமாக மிகவும் ஈரமாக உள்ளது',
  };
}
