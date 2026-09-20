/// Metadata reported by the phone's speech engine. No health inference.
class PhoneVoice {
  final String name, locale, features;
  final int quality;
  final bool needsInternet;
  const PhoneVoice(
      {required this.name,
      required this.locale,
      this.quality = 200,
      this.needsInternet = false,
      this.features = ''});

  static String normalize(String text) =>
      text.toLowerCase().replaceAll('_', '-');

  static List<PhoneVoice> ranked(dynamic raw, String language,
      {required bool allowInternet}) {
    if (raw is! List) return [];
    final code = language == 'ta' ? 'ta' : 'en';
    final voices = <String, PhoneVoice>{};
    for (final item in raw) {
      if (item is! Map || item['name'] is! String || item['locale'] is! String)
        continue;
      final locale = normalize(item['locale'] as String);
      final network =
          item['network_required'].toString().toLowerCase() == 'true';
      final features = (item['features'] ?? '').toString().toLowerCase();
      if (locale.split('-').first != code ||
          (!allowInternet && network) ||
          features.contains('notinstalled') ||
          features.contains('not_installed')) continue;
      final voice = PhoneVoice(
          name: item['name'],
          locale: item['locale'],
          needsInternet: network,
          features: features,
          quality: (int.tryParse('${item['quality']}') ?? 200)
              .clamp(0, 500)
              .toInt());
      voices[voice.name] = voice;
    }
    int score(PhoneVoice v) =>
        v.quality * 10 +
        (normalize(v.locale) == '$code-in' ? 50 : 0) +
        (v.needsInternet ? 0 : 1);
    return voices.values.toList()
      ..sort((a, b) {
        final quality = score(b).compareTo(score(a));
        return quality != 0 ? quality : a.name.compareTo(b.name);
      });
  }

  Map<String, String> get engineValue => {'name': name, 'locale': locale};
}
