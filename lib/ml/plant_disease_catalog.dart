/// Farmer-facing names and safe advice for the 38 PlantVillage classes used by
/// the on-device leaf model (assets/ml/plant_disease_labels.json).
///
/// Advice is deliberately general and safe (sanitation, airflow, watering,
/// contacting the agriculture officer). No chemical names or doses: those
/// depend on local conditions and must come from the agriculture officer.
library;

/// A pair of strings, English and Tamil.
class Bi {
  final String en, ta;
  const Bi(this.en, this.ta);
  String of(bool tamil) => tamil ? ta : en;
}

class CropInfo {
  final String key; // stable id stored in history and Firebase ('tomato')
  final Bi name;
  final String emoji;
  final String labelPrefix; // model label prefix, e.g. 'Tomato___'
  const CropInfo(this.key, this.name, this.emoji, this.labelPrefix);
}

class UnsupportedCrop {
  final String key;
  final Bi name;
  final String emoji;
  const UnsupportedCrop(this.key, this.name, this.emoji);
}

enum ConditionKind { healthy, fungal, bacterial, viral, pest, urgentFungal }

class ConditionInfo {
  final String label; // exact model label
  final String cropKey;
  final String conditionKey; // e.g. 'early_blight', 'healthy'
  final Bi name;
  final ConditionKind kind;
  const ConditionInfo(
      this.label, this.cropKey, this.conditionKey, this.name, this.kind);
  bool get healthy => kind == ConditionKind.healthy;
}

class PlantDiseaseCatalog {
  PlantDiseaseCatalog._();

  /// Crops the farmer can check. Only crops where the model knows both a
  /// healthy leaf and at least one disease are offered.
  static const supportedCrops = <CropInfo>[
    CropInfo('tomato', Bi('Tomato', 'தக்காளி'), '🍅', 'Tomato___'),
    CropInfo('potato', Bi('Potato', 'உருளைக்கிழங்கு'), '🥔', 'Potato___'),
    CropInfo('pepper', Bi('Bell pepper (capsicum)', 'குடைமிளகாய்'), '🫑',
        'Pepper,_bell___'),
    CropInfo('corn', Bi('Maize (corn)', 'மக்காச்சோளம்'), '🌽', 'Corn_(maize)___'),
    CropInfo('grape', Bi('Grape', 'திராட்சை'), '🍇', 'Grape___'),
    CropInfo('apple', Bi('Apple', 'ஆப்பிள்'), '🍎', 'Apple___'),
    CropInfo('peach', Bi('Peach', 'பீச்'), '🍑', 'Peach___'),
    CropInfo('cherry', Bi('Cherry', 'செர்ரி'), '🍒', 'Cherry_(including_sour)___'),
    CropInfo('strawberry', Bi('Strawberry', 'ஸ்ட்ராபெர்ரி'), '🍓', 'Strawberry___'),
  ];

  /// Crops the model saw, but with only one class (only "healthy", or only
  /// one disease). A check would always give the same answer, so they are
  /// not offered; kept only to name them if a photo looks like one.
  static const modelOnlyCrops = <CropInfo>[
    CropInfo('orange', Bi('Orange / citrus', 'ஆரஞ்சு / எலுமிச்சை வகை'), '🍊',
        'Orange___'),
    CropInfo('squash', Bi('Squash / pumpkin', 'பூசணி வகை'), '🎃', 'Squash___'),
    CropInfo('soybean', Bi('Soybean', 'சோயாபீன்'), '🫘', 'Soybean___'),
    CropInfo('blueberry', Bi('Blueberry', 'புளூபெர்ரி'), '🫐', 'Blueberry___'),
    CropInfo('raspberry', Bi('Raspberry', 'ராஸ்பெர்ரி'), '🍇', 'Raspberry___'),
  ];

  /// Common local crops the model has never seen. For these the app says so
  /// clearly instead of guessing.
  static const unsupportedCrops = <UnsupportedCrop>[
    UnsupportedCrop('rice', Bi('Rice (paddy)', 'நெல்'), '🌾'),
    UnsupportedCrop('banana', Bi('Banana', 'வாழை'), '🍌'),
    UnsupportedCrop('coconut', Bi('Coconut', 'தென்னை'), '🥥'),
    UnsupportedCrop('brinjal', Bi('Brinjal', 'கத்திரி'), '🍆'),
    UnsupportedCrop('chilli', Bi('Chilli', 'மிளகாய்'), '🌶️'),
    UnsupportedCrop('groundnut', Bi('Groundnut', 'நிலக்கடலை'), '🥜'),
    UnsupportedCrop('sugarcane', Bi('Sugarcane', 'கரும்பு'), '🎋'),
    UnsupportedCrop('cotton', Bi('Cotton', 'பருத்தி'), '☁️'),
    UnsupportedCrop('mango', Bi('Mango', 'மா'), '🥭'),
    UnsupportedCrop('citrus', Bi('Lemon / orange', 'எலுமிச்சை / ஆரஞ்சு'), '🍋'),
    UnsupportedCrop('pumpkin', Bi('Pumpkin / gourd', 'பூசணி / சுரை'), '🎃'),
    UnsupportedCrop('other', Bi('Other crop', 'மற்ற பயிர்'), '🌿'),
  ];

  static CropInfo? crop(String key) {
    for (final c in supportedCrops) {
      if (c.key == key) return c;
    }
    return null;
  }

  static CropInfo? cropForLabel(String label) {
    for (final c in [...supportedCrops, ...modelOnlyCrops]) {
      if (label.startsWith(c.labelPrefix)) return c;
    }
    return null;
  }

  static const _h = ConditionKind.healthy;
  static const _f = ConditionKind.fungal;
  static const _b = ConditionKind.bacterial;
  static const _v = ConditionKind.viral;
  static const _p = ConditionKind.pest;
  static const _u = ConditionKind.urgentFungal;

  static const _healthy = Bi('Healthy', 'ஆரோக்கியமானது');

  static const conditions = <ConditionInfo>[
    ConditionInfo('Apple___Apple_scab', 'apple', 'apple_scab',
        Bi('Apple scab', 'ஆப்பிள் சொறி நோய்'), _f),
    ConditionInfo('Apple___Black_rot', 'apple', 'black_rot',
        Bi('Black rot', 'கருப்பு அழுகல் நோய்'), _f),
    ConditionInfo('Apple___Cedar_apple_rust', 'apple', 'cedar_apple_rust',
        Bi('Cedar apple rust', 'துரு நோய்'), _f),
    ConditionInfo('Apple___Healthy', 'apple', 'healthy', _healthy, _h),
    ConditionInfo('Blueberry___Healthy', 'blueberry', 'healthy', _healthy, _h),
    ConditionInfo('Cherry_(including_sour)___Powdery_mildew', 'cherry',
        'powdery_mildew', Bi('Powdery mildew', 'சாம்பல் நோய்'), _f),
    ConditionInfo(
        'Cherry_(including_sour)___Healthy', 'cherry', 'healthy', _healthy, _h),
    ConditionInfo('Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot', 'corn',
        'gray_leaf_spot', Bi('Gray leaf spot', 'சாம்பல் இலைப்புள்ளி நோய்'), _f),
    ConditionInfo('Corn_(maize)___Common_rust_', 'corn', 'common_rust',
        Bi('Common rust', 'துரு நோய்'), _f),
    ConditionInfo('Corn_(maize)___Northern_Leaf_Blight', 'corn',
        'northern_leaf_blight', Bi('Northern leaf blight', 'இலைக் கருகல் நோய்'), _f),
    ConditionInfo('Corn_(maize)___Healthy', 'corn', 'healthy', _healthy, _h),
    ConditionInfo('Grape___Black_rot', 'grape', 'black_rot',
        Bi('Black rot', 'கருப்பு அழுகல் நோய்'), _f),
    ConditionInfo('Grape___Esca_(Black_Measles)', 'grape', 'esca',
        Bi('Esca (black measles)', 'எஸ்கா (கரும்புள்ளி) நோய்'), _f),
    ConditionInfo('Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'grape',
        'leaf_blight', Bi('Leaf blight', 'இலைக் கருகல் நோய்'), _f),
    ConditionInfo('Grape___Healthy', 'grape', 'healthy', _healthy, _h),
    ConditionInfo('Orange___Haunglongbing_(Citrus_greening)', 'orange',
        'citrus_greening', Bi('Citrus greening', 'சிட்ரஸ் பசுமை நோய்'), _v),
    ConditionInfo('Peach___Bacterial_spot', 'peach', 'bacterial_spot',
        Bi('Bacterial spot', 'பாக்டீரியா இலைப்புள்ளி நோய்'), _b),
    ConditionInfo('Peach___Healthy', 'peach', 'healthy', _healthy, _h),
    ConditionInfo('Pepper,_bell___Bacterial_spot', 'pepper', 'bacterial_spot',
        Bi('Bacterial spot', 'பாக்டீரியா இலைப்புள்ளி நோய்'), _b),
    ConditionInfo('Pepper,_bell___Healthy', 'pepper', 'healthy', _healthy, _h),
    ConditionInfo('Potato___Early_blight', 'potato', 'early_blight',
        Bi('Early blight', 'முன் இலைக் கருகல் நோய்'), _f),
    ConditionInfo('Potato___Late_blight', 'potato', 'late_blight',
        Bi('Late blight', 'பின் இலைக் கருகல் நோய்'), _u),
    ConditionInfo('Potato___Healthy', 'potato', 'healthy', _healthy, _h),
    ConditionInfo('Raspberry___Healthy', 'raspberry', 'healthy', _healthy, _h),
    ConditionInfo('Soybean___Healthy', 'soybean', 'healthy', _healthy, _h),
    ConditionInfo('Squash___Powdery_mildew', 'squash', 'powdery_mildew',
        Bi('Powdery mildew', 'சாம்பல் நோய்'), _f),
    ConditionInfo('Strawberry___Leaf_scorch', 'strawberry', 'leaf_scorch',
        Bi('Leaf scorch', 'இலை எரிவு நோய்'), _f),
    ConditionInfo('Strawberry___Healthy', 'strawberry', 'healthy', _healthy, _h),
    ConditionInfo('Tomato___Bacterial_spot', 'tomato', 'bacterial_spot',
        Bi('Bacterial spot', 'பாக்டீரியா இலைப்புள்ளி நோய்'), _b),
    ConditionInfo('Tomato___Early_blight', 'tomato', 'early_blight',
        Bi('Early blight', 'முன் இலைக் கருகல் நோய்'), _f),
    ConditionInfo('Tomato___Late_blight', 'tomato', 'late_blight',
        Bi('Late blight', 'பின் இலைக் கருகல் நோய்'), _u),
    ConditionInfo('Tomato___Leaf_Mold', 'tomato', 'leaf_mold',
        Bi('Leaf mould', 'இலைப் பூஞ்சண நோய்'), _f),
    ConditionInfo('Tomato___Septoria_leaf_spot', 'tomato', 'septoria_leaf_spot',
        Bi('Septoria leaf spot', 'செப்டோரியா இலைப்புள்ளி நோய்'), _f),
    ConditionInfo('Tomato___Spider_mites Two-spotted_spider_mite', 'tomato',
        'spider_mites', Bi('Spider mites', 'சிலந்திப் பேன்'), _p),
    ConditionInfo('Tomato___Target_Spot', 'tomato', 'target_spot',
        Bi('Target spot', 'இலக்குப் புள்ளி நோய்'), _f),
    ConditionInfo('Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'tomato',
        'yellow_leaf_curl_virus', Bi('Yellow leaf curl virus', 'மஞ்சள் இலைச் சுருள் நோய்'), _v),
    ConditionInfo('Tomato___Tomato_mosaic_virus', 'tomato', 'mosaic_virus',
        Bi('Mosaic virus', 'தேமல் நோய்'), _v),
    ConditionInfo('Tomato___Healthy', 'tomato', 'healthy', _healthy, _h),
  ];

  static ConditionInfo? condition(String label) {
    for (final c in conditions) {
      if (c.label == label) return c;
    }
    return null;
  }

  /// 2-3 short, safe lines for the farmer.
  static List<String> advice(ConditionInfo c, {required bool tamil}) {
    String t(String en, String ta) => tamil ? ta : en;
    final officer = t(
        'If it spreads, show the leaf to your agriculture officer before spraying anything.',
        'பரவினால், எதையும் தெளிக்கும் முன் இலையை வேளாண் அலுவலரிடம் காட்டுங்கள்.');
    return switch (c.kind) {
      ConditionKind.healthy => [
          t('Keep your normal care: water at the root, and check leaves once a week.',
              'வழக்கமான பராமரிப்பைத் தொடருங்கள்: வேரில் நீர் ஊற்றுங்கள், வாரம் ஒருமுறை இலைகளைப் பாருங்கள்.'),
          t('Check another leaf if some plants look different.',
              'சில செடிகள் வேறுபட்டுத் தெரிந்தால் இன்னொரு இலையையும் சோதியுங்கள்.'),
        ],
      ConditionKind.fungal => [
          t('Pick off the spotted leaves and destroy them away from the field. Do not leave them on the ground.',
              'புள்ளி உள்ள இலைகளைப் பறித்து வயலுக்கு வெளியே அழியுங்கள். தரையில் விடாதீர்கள்.'),
          t('Water at the root, not on the leaves, and give plants space for air to move.',
              'இலைகளில் அல்ல, வேரில் நீர் ஊற்றுங்கள். காற்று செல்லச் செடிகளுக்கு இடைவெளி விடுங்கள்.'),
          officer,
        ],
      ConditionKind.urgentFungal => [
          t('This can spread fast in cool, wet weather. Remove affected leaves or plants today.',
              'குளிர்ந்த, ஈரமான காலநிலையில் இது வேகமாகப் பரவும். பாதித்த இலைகள் அல்லது செடிகளை இன்றே அகற்றுங்கள்.'),
          t('Keep leaves dry: water at the root in the morning.',
              'இலைகளை உலர வைத்திருங்கள்: காலையில் வேரில் நீர் ஊற்றுங்கள்.'),
          t('Contact your agriculture officer soon for the right treatment.',
              'சரியான சிகிச்சைக்கு விரைவில் வேளாண் அலுவலரைத் தொடர்பு கொள்ளுங்கள்.'),
        ],
      ConditionKind.bacterial => [
          t('Remove spotted leaves. Wash hands and tools after touching sick plants.',
              'புள்ளி உள்ள இலைகளை அகற்றுங்கள். நோயுற்ற செடிகளைத் தொட்ட பின் கை, கருவிகளைக் கழுவுங்கள்.'),
          t('Avoid sprinkling water on leaves, and don\'t work among plants when they are wet.',
              'இலைகளில் நீர் தெளிக்காதீர்கள். செடிகள் ஈரமாக இருக்கும்போது அவற்றிடையே வேலை செய்யாதீர்கள்.'),
          officer,
        ],
      ConditionKind.viral => [
          t('There is no cure for a virus in the plant. Remove badly affected plants so it does not spread.',
              'செடியில் உள்ள நச்சுயிரிக்கு மருந்து இல்லை. பரவாமல் இருக்க, கடுமையாகப் பாதித்த செடிகளை அகற்றுங்கள்.'),
          t('Small insects (whitefly, aphids) carry it. Keep them under control.',
              'சிறு பூச்சிகள் (வெள்ளை ஈ, அசுவினி) இதைப் பரப்பும். அவற்றைக் கட்டுப்படுத்துங்கள்.'),
          t('Ask your agriculture officer about healthy seedlings and resistant varieties.',
              'நல்ல நாற்றுகள், எதிர்ப்புத் திறன் கொண்ட ரகங்கள் பற்றி வேளாண் அலுவலரிடம் கேளுங்கள்.'),
        ],
      ConditionKind.pest => [
          t('Look under the leaves. Spray plain water on the underside to knock the mites off.',
              'இலைகளின் அடிப்பக்கத்தைப் பாருங்கள். பேன்களை அகற்ற அடிப்பக்கத்தில் வெறும் நீரைத் தெளியுங்கள்.'),
          t('Remove heavily affected leaves. Mites like hot, dry, dusty conditions.',
              'கடுமையாகப் பாதித்த இலைகளை அகற்றுங்கள். வெப்பமான, வறண்ட, தூசியான சூழலில் பேன் அதிகரிக்கும்.'),
          officer,
        ],
    };
  }
}
