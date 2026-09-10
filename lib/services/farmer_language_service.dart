class FarmerLanguageService {
  const FarmerLanguageService._();

  static String hardwareProblem({
    required String rootCause,
    required String because,
    required bool needsAttention,
  }) {
    if (!needsAttention) return 'No major problem detected.';

    final text = '$rootCause $because'.toLowerCase();
    if (_hasAny(text, ['soil probe', 'probe placement', 'calibration'])) {
      return 'The soil sensor may not be placed correctly.';
    }
    if (_hasAny(text, ['water stress', 'very dry', 'root soil is dry'])) {
      return 'The plant may not be getting enough water.';
    }
    if (_hasAny(text, [
      'atmospheric drying',
      'dry air',
      'high vpd',
      'water loss',
    ])) {
      return 'Hot or dry air may be making the plant lose water too quickly.';
    }
    if (_hasAny(text, ['overwater', 'very wet', 'excess moisture'])) {
      return 'The soil may be too wet.';
    }
    if (_hasAny(text, ['heat stress', 'high temperature', 'too hot'])) {
      return 'The plant may be getting too hot.';
    }
    if (_hasAny(text, ['low light', 'not enough light'])) {
      return 'The plant may not be getting enough light.';
    }
    if (_hasAny(text, [
      'electrode',
      'contact verify',
      'electrodes open',
      'bioelectric',
      'plant signal',
    ])) {
      return 'The plant signal sensor needs a quick check.';
    }
    if (_hasAny(text, ['disease', 'biotic', 'leaf wet'])) {
      return 'Conditions may be suitable for plant disease.';
    }
    if (_hasAny(text, ['sensor', 'integrity', 'fault'])) {
      return 'One of the sensors needs to be checked.';
    }
    return 'The plant needs attention.';
  }

  static String hardwareSolution({
    required String farmerAction,
    required String problem,
  }) {
    final text = farmerAction.toLowerCase();
    if (_hasAny(text, ['soil probe', 'insert probe', 'probe placement'])) {
      return 'Push the soil sensor firmly into the soil near the roots, then check the reading again.';
    }
    if (_hasAny(text, ['avoid extra irrigation', 'pause irrigation'])) {
      return 'Do not add more water now. Check whether the soil is already wet.';
    }
    if (_hasAny(text, [
      'water if',
      'irrigat',
      'genuinely dry',
      'actually dry',
    ])) {
      return 'Check the soil near the roots. Water only if the soil is actually dry.';
    }
    if (_hasAny(text, ['drainage', 'drain'])) {
      return 'Check that extra water can drain away from the roots.';
    }
    if (_hasAny(text, ['electrode', 'contact'])) {
      return 'Check that both plant electrodes are firmly attached and are not touching each other.';
    }
    if (_hasAny(text, ['midday', 'heat', 'hot'])) {
      return 'Check the plant and soil moisture. Avoid extra stress during the hottest part of the day.';
    }
    if (_hasAny(text, ['shade', 'light sensor', 'low light'])) {
      return 'Check for shade or anything blocking the light sensor.';
    }
    if (_hasAny(text, ['camera', 'photo', 'leaf'])) {
      return 'Look closely at the leaves. Take a clear leaf photo if you see spots, damage, or unusual colour.';
    }
    if (_hasAny(text, ['continue', 'monitor', 'no action'])) {
      return 'Keep watching the plant. No immediate action is needed.';
    }

    if (farmerAction.trim().isNotEmpty) {
      return _simplifyAction(farmerAction);
    }
    if (problem == 'No major problem detected.') {
      return 'Keep the current routine. No immediate action is needed.';
    }
    return 'Check the plant and the nearby sensors, then review the latest reading again.';
  }

  static String simulationProblem(String headlineKey, String fallback) {
    return switch (headlineKey) {
      'ai_combined_stress' => 'The plant may be too dry and too hot.',
      'ai_water_stress' ||
      'ai_early_water_stress' => 'The plant may not be getting enough water.',
      'ai_overwatering' => 'The soil may be too wet.',
      'ai_paddy_water_expected' =>
        'The wet soil level looks normal for this rice field.',
      'ai_heat_stress' => 'The plant may be getting too hot.',
      'ai_low_light' => 'The plant may not be getting enough light.',
      'ai_signal_stress' => 'The plant signal needs a quick check.',
      'ai_healthy' => 'No major problem detected.',
      _ => _simpleFallbackProblem(fallback),
    };
  }

  static String simulationSolution(String recommendationKey, String fallback) {
    return switch (recommendationKey) {
      'ai_combined_stress_action' => 'Check the soil near the roots. If it is dry, water the plant and check the irrigation line.',
      'ai_water_stress_action' || 'ai_early_water_stress_action' => 'Check the soil near the roots. Water only if the soil is actually dry.',
      'ai_overwatering_action' =>
        'Do not add more water now. Check drainage and soil wetness.',
      'ai_paddy_water_expected_action' => 'Check the standing water and drainage. Add water only if the field really needs it.',
      'ai_heat_stress_action' => 'Check the plant and soil moisture. Avoid extra stress during the hottest part of the day.',
      'ai_low_light_action' =>
        'Check for shade, covering, or dirt on the light sensor.',
      'ai_signal_stress_action' => 'Check that the plant electrodes are attached properly, then inspect the plant.',
      'ai_healthy_action' =>
        'Keep the current routine. No immediate action is needed.',
      _ => _simplifyAction(fallback),
    };
  }

  static String _simpleFallbackProblem(String value) {
    final text = value.toLowerCase();
    if (_hasAny(text, ['dry', 'water stress', 'moisture'])) {
      return 'The plant may need a water check.';
    }
    if (_hasAny(text, ['heat', 'temperature', 'hot'])) {
      return 'The plant may be getting too hot.';
    }
    if (_hasAny(text, ['light', 'shade'])) {
      return 'The plant may not be getting enough light.';
    }
    if (_hasAny(text, ['signal', 'electrode', 'sensor'])) {
      return 'A plant sensor needs a quick check.';
    }
    return 'The plant needs attention.';
  }

  static String _simplifyAction(String value) {
    var result = value.trim();
    if (result.isEmpty) {
      return 'Check the plant and nearby sensors, then review the reading again.';
    }
    result = result
        .replaceAll(
          RegExp('root-zone', caseSensitive: false),
          'soil near the roots',
        )
        .replaceAll(RegExp('irrigation', caseSensitive: false), 'watering')
        .replaceAll(RegExp('probe', caseSensitive: false), 'soil sensor')
        .replaceAll(RegExp('genuinely', caseSensitive: false), 'actually')
        .replaceAll(RegExp('ESP32', caseSensitive: false), 'device');
    return result;
  }

  static bool _hasAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}
