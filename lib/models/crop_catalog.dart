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

/// Crop contexts available to the app. Firmware-supported profiles are kept
/// with the exact canonical names expected by `/api/config/crop` so hardware
/// mode can synchronize without hidden aliases or hard-coded Tomato logic.
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

    // Camera/screening contexts retained for backward compatibility. The
    // ESP32 crop endpoint may reject these if the active firmware does not
    // expose a matching profile.
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
    if (value.contains('universal')) return 'Universal';
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
    if (value.contains('papaya')) return 'Papaya';
    if (value.contains('hibiscus')) return 'Hibiscus';
    if (value.contains('okra') || value.contains('bhendi')) return 'Okra';
    if (value.contains('coconut')) return 'Coconut';
    if (value.contains('tomato')) return 'Tomato';
    if (value.contains('brinjal') || value.contains('eggplant')) {
      return 'Eggplant';
    }
    if (value.contains('chilli') ||
        value.contains('chili') ||
        value.contains('pepper')) {
      return 'Chilli';
    }
    return crop.trim();
  }
}
