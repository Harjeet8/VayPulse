/// Home-only presentation states parsed from ESP32 soil telemetry.
///
/// This deliberately does not alter root-cause intelligence. Technical and
/// Judge views continue to display the firmware's original root cause.
enum HomeSoilState {
  veryDry,
  dry,
  low,
  good,
  wet,
  veryWet,
}

class HomeSoilPresentation {
  final HomeSoilState state;

  const HomeSoilPresentation(this.state);

  static HomeSoilPresentation? fromFirmware(String? raw) {
    final normalized = _normalize(raw);
    final state = switch (normalized) {
      'VERY_DRY' => HomeSoilState.veryDry,
      'DRY' => HomeSoilState.dry,
      'LOW' => HomeSoilState.low,
      'GOOD' => HomeSoilState.good,
      'OPTIMAL' => HomeSoilState.good,
      'WET' => HomeSoilState.wet,
      'VERY_WET' => HomeSoilState.veryWet,
      'TOO_WET' => HomeSoilState.veryWet,
      _ => null,
    };
    return state == null ? null : HomeSoilPresentation(state);
  }

  String title({required bool tamil}) {
    if (tamil) {
      return switch (state) {
        HomeSoilState.veryDry => 'மிகவும் உலர்',
        HomeSoilState.dry => 'உலர்',
        HomeSoilState.low => 'குறைந்த ஈரம்',
        HomeSoilState.good => 'நல்ல ஈர நிலை',
        HomeSoilState.wet => 'ஈரமாக உள்ளது',
        HomeSoilState.veryWet => 'மிக அதிக ஈரம்',
      };
    }
    return switch (state) {
      HomeSoilState.veryDry => 'VERY DRY',
      HomeSoilState.dry => 'DRY',
      HomeSoilState.low => 'LOW',
      HomeSoilState.good => 'GOOD',
      HomeSoilState.wet => 'WET',
      HomeSoilState.veryWet => 'VERY WET',
    };
  }

  String summary({required bool tamil}) {
    if (tamil) {
      return switch (state) {
        HomeSoilState.veryDry =>
          'வேர் பகுதியின் ஈரப்பதம் மிகவும் ஆபத்தான அளவிற்கு குறைவாக உள்ளது.',
        HomeSoilState.dry =>
          'வேர் பகுதியின் ஈரப்பதம் தேவையான அளவை விட குறைவாக உள்ளது.',
        HomeSoilState.low => 'வேர் பகுதியின் ஈரப்பதம் குறைவாக உள்ளது.',
        HomeSoilState.good => 'வேர் பகுதியின் ஈரப்பதம் சரியான அளவில் உள்ளது.',
        HomeSoilState.wet => 'வேர் பகுதியின் ஈரப்பதம் அதிகமாக உள்ளது.',
        HomeSoilState.veryWet =>
          'வேர் பகுதியின் ஈரப்பதம் மிகவும் அதிகமாக உள்ளது.',
      };
    }
    return switch (state) {
      HomeSoilState.veryDry => 'Root-zone moisture is critically low.',
      HomeSoilState.dry => 'Root-zone moisture is below the preferred range.',
      HomeSoilState.low => 'Root-zone moisture is low.',
      HomeSoilState.good => 'Root-zone moisture is in the preferred range.',
      HomeSoilState.wet => 'Root-zone moisture is high.',
      HomeSoilState.veryWet => 'Root-zone moisture is critically high.',
    };
  }

  static bool isSoilLedFinding(String? primaryRootCause) {
    if (primaryRootCause == null || primaryRootCause.trim().isEmpty) {
      return true;
    }
    final value = _normalize(primaryRootCause) ?? '';
    return value.contains('WATER_STRESS') ||
        value.contains('SOIL_MOISTURE') ||
        value.contains('DRY_SOIL') ||
        value.contains('ROOT_ZONE') ||
        value.contains('ROOTZONE') ||
        value.contains('OVERWATER') ||
        value.contains('WATERLOG') ||
        value.contains('DROUGHT') ||
        value.contains('IRRIGATION');
  }

  static String? _normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
