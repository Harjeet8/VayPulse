class CropProfile {
  final String id;
  final String name;
  final String localizationKey;

  const CropProfile({
    required this.id,
    required this.name,
    required this.localizationKey,
  });
}

/// Crop contexts available to PhytoSense AI.
///
/// Firmware-supported profiles use the exact canonical names expected
/// by the ESP32 crop endpoint. Camera-only contexts are retained so no
/// established screening capability is removed.
class CropCatalog {
  static const supported = <CropProfile>[
    CropProfile(
      id: 'universal',
      name: 'Universal',
      localizationKey: 'crop_universal',
    ),
    CropProfile(id: 'tomato', name: 'Tomato', localizationKey: 'crop_tomato'),
    CropProfile(
      id: 'hibiscus',
      name: 'Hibiscus',
      localizationKey: 'crop_hibiscus',
    ),
    CropProfile(id: 'rice', name: 'Rice', localizationKey: 'crop_rice'),
    CropProfile(
      id: 'sugarcane',
      name: 'Sugarcane',
      localizationKey: 'crop_sugarcane',
    ),
    CropProfile(id: 'banana', name: 'Banana', localizationKey: 'crop_banana'),
    CropProfile(id: 'papaya', name: 'Papaya', localizationKey: 'crop_papaya'),
    CropProfile(
      id: 'eggplant',
      name: 'Eggplant',
      localizationKey: 'crop_brinjal',
    ),
    CropProfile(id: 'okra', name: 'Okra', localizationKey: 'crop_okra'),
    CropProfile(id: 'maize', name: 'Maize', localizationKey: 'crop_maize'),
    CropProfile(
      id: 'groundnut',
      name: 'Groundnut',
      localizationKey: 'crop_groundnut',
    ),
    CropProfile(id: 'cotton', name: 'Cotton', localizationKey: 'crop_cotton'),
    CropProfile(
      id: 'coconut',
      name: 'Coconut',
      localizationKey: 'crop_coconut',
    ),
    CropProfile(id: 'chilli', name: 'Chilli', localizationKey: 'crop_chilli'),
  ];

  static const firmwareSupportedNames = <String>{
    'Universal',
    'Tomato',
    'Hibiscus',
    'Rice',
    'Sugarcane',
    'Banana',
    'Papaya',
    'Eggplant',
    'Okra',
    'Maize',
    'Groundnut',
  };

  static bool supports(String crop) =>
      supported.any((profile) => profile.name == normalize(crop));

  static bool firmwareSupports(String crop) =>
      firmwareSupportedNames.contains(normalize(crop));

  static CropProfile profileFor(String crop) {
    final normalized = normalize(crop);
    return supported.firstWhere(
      (profile) => profile.name == normalized,
      orElse: () => supported.first,
    );
  }

  static String normalize(String crop) {
    final value = crop.trim().toLowerCase();
    if (value.isEmpty ||
        value.contains('universal') ||
        value.contains('neutral') ||
        value == 'default') {
      return 'Universal';
    }
    if (value.contains('paddy') || value.contains('rice')) return 'Rice';
    if (value.contains('corn') || value.contains('maize')) return 'Maize';
    if (value.contains('peanut') || value.contains('groundnut')) {
      return 'Groundnut';
    }
    if (value.contains('cotton')) return 'Cotton';
    if (value.contains('sugarcane') || value.contains('sugar cane')) {
      return 'Sugarcane';
    }
    if (value.contains('banana') || value.contains('plantain')) return 'Banana';
    if (value.contains('papaya') || value.contains('pawpaw')) return 'Papaya';
    if (value.contains('coconut')) return 'Coconut';
    if (value.contains('tomato')) return 'Tomato';
    if (value.contains('hibiscus') ||
        value.contains('rose mallow') ||
        value.contains('shoe flower') ||
        value.contains('chembaruthi') ||
        value.contains('செம்பருத்தி')) {
      return 'Hibiscus';
    }
    if (value.contains('brinjal') || value.contains('eggplant')) {
      return 'Eggplant';
    }
    if (value.contains('chilli') ||
        value.contains('chili') ||
        value.contains('pepper')) {
      return 'Chilli';
    }
    if (value.contains('okra') ||
        value.contains('lady finger') ||
        value.contains('ladyfinger') ||
        value.contains('bhindi') ||
        value.contains('bhendi') ||
        value.contains('vendakkai') ||
        value.contains('வெண்டைக்காய்')) {
      return 'Okra';
    }
    return crop.trim();
  }
}
