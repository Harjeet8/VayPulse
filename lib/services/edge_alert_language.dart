import 'package:flutter/widgets.dart';

import 'app_scope.dart';

class EdgeAlertLanguage {
  const EdgeAlertLanguage._();

  static String? text(BuildContext context, String key) {
    final tamil = AppScope.of(context).settings.value.languageCode == 'ta';
    return (tamil ? _ta : _en)[key];
  }

  static const _en = <String, String>{
    'alert_sensor_attention': 'Sensor needs attention',
    'alert_sensor_attention_message':
        'A reading is unreliable or unavailable. Check the sensor connection while PhytoSense continues with reliable sensors.',
    'alert_plant_recovering': 'Plant recovering',
    'alert_plant_recovering_message':
        'Stress is decreasing after conditions improved. Continue monitoring.',
    'alert_possible_biotic': 'Possible pest or infection-related stress',
    'alert_possible_biotic_message':
        'The plant shows unexplained stress. Inspect leaves and stems for visible pests or symptoms.',
    'alert_water_stress_edge': 'Water stress detected',
    'alert_water_stress_edge_message':
        'Root-zone evidence and the plant response indicate water stress. Check the soil and water if it is genuinely dry.',
    'alert_heat_stress_edge': 'Heat stress detected',
    'alert_heat_stress_edge_message':
        'Heat is contributing to plant stress. Reduce heat exposure if possible and check root-zone moisture.',
    'alert_root_stress_edge': 'Root-zone stress detected',
    'alert_root_stress_edge_message':
        'The ESP32 identified the root zone as the main stress contributor. Check moisture, temperature and drainage.',
    'alert_plant_stress_edge': 'Plant stress detected',
    'alert_plant_stress_edge_message':
        'The plant is showing a stress response. Open Analysis to see the ESP32 evidence and recommended action.',
  };

  static const _ta = <String, String>{
    'alert_sensor_attention': 'சென்சாரை சரிபார்க்க வேண்டும்',
    'alert_sensor_attention_message':
        'ஒரு reading நம்பகமில்லை அல்லது கிடைக்கவில்லை. இணைப்பைச் சரிபார்க்கவும்; நம்பகமான மற்ற சென்சார்களுடன் PhytoSense தொடரும்.',
    'alert_plant_recovering': 'செடி மீண்டு வருகிறது',
    'alert_plant_recovering_message':
        'சூழல் மேம்பட்ட பிறகு stress குறைந்து வருகிறது. தொடர்ந்து கண்காணிக்கவும்.',
    'alert_possible_biotic': 'பூச்சி அல்லது தொற்று தொடர்பான stress இருக்கலாம்',
    'alert_possible_biotic_message':
        'காரணம் முழுமையாக விளங்காத stress உள்ளது. இலை மற்றும் தண்டுகளில் பூச்சி அல்லது அறிகுறிகள் உள்ளதா பாருங்கள்.',
    'alert_water_stress_edge': 'நீர் பற்றாக்குறை stress கண்டறியப்பட்டது',
    'alert_water_stress_edge_message':
        'வேர் பகுதி தகவலும் செடியின் பதிலும் water stress-ஐ காட்டுகின்றன. மண் உண்மையில் உலர்ந்திருந்தால் நீர் விடவும்.',
    'alert_heat_stress_edge': 'வெப்ப stress கண்டறியப்பட்டது',
    'alert_heat_stress_edge_message':
        'அதிக வெப்பம் செடியின் stress-ஐ அதிகரிக்கிறது. முடிந்தால் வெப்பத்தை குறைத்து வேர் பகுதி ஈரத்தைச் சரிபார்க்கவும்.',
    'alert_root_stress_edge': 'வேர் பகுதி stress கண்டறியப்பட்டது',
    'alert_root_stress_edge_message':
        'ESP32 வேர் பகுதியை முக்கிய stress காரணமாக காட்டுகிறது. ஈரம், வெப்பநிலை மற்றும் drainage-ஐ சரிபார்க்கவும்.',
    'alert_plant_stress_edge': 'செடி stress காட்டுகிறது',
    'alert_plant_stress_edge_message':
        'செடி stress பதிலை காட்டுகிறது. ESP32 evidence மற்றும் செய்ய வேண்டியதை Analysis-ல் பாருங்கள்.',
  };
}
