import 'package:flutter_tts/flutter_tts.dart';

class VoiceGuidanceService {
  final FlutterTts _tts = FlutterTts();
  final Map<String, Map<String, String>?> _voiceCache = {};
  bool _initialized = false;
  String? _activeVoiceName;

  String? get activeVoiceName => _activeVoiceName;

  Future<bool> speak({
    required String text,
    required String languageCode,
  }) async {
    try {
      await _tts.stop();
      await _configure(languageCode);
      final result = await _tts.speak(_speechFriendly(text));
      return result == null || result == 1;
    } catch (_) {
      return false;
    }
  }

  Future<String?> prepareVoice(String languageCode) async {
    try {
      await _configure(languageCode);
      return _activeVoiceName;
    } catch (_) {
      return null;
    }
  }

  Future<void> _configure(String languageCode) async {
    if (!_initialized) {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1);
      _initialized = true;
    }

    final locale = languageCode == 'ta' ? 'ta-IN' : 'en-IN';
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(languageCode == 'ta' ? 0.43 : 0.47);
    await _tts.setPitch(languageCode == 'ta' ? 1.0 : 0.98);

    if (!_voiceCache.containsKey(locale)) {
      _voiceCache[locale] = await _findBestVoice(locale);
    }
    final voice = _voiceCache[locale];
    _activeVoiceName = voice?['name'];
    if (voice != null) {
      try {
        await _tts.setVoice(voice);
      } catch (_) {
        _activeVoiceName = null;
      }
    }
  }

  Future<Map<String, String>?> _findBestVoice(String targetLocale) async {
    final rawVoices = await _tts.getVoices;
    if (rawVoices is! List) return null;
    final voices = <Map<String, String>>[];
    for (final raw in rawVoices) {
      if (raw is! Map) continue;
      final voice = <String, String>{};
      for (final entry in raw.entries) {
        if (entry.value != null) {
          voice[entry.key.toString()] = entry.value.toString();
        }
      }
      if (voice['name'] != null && voice['locale'] != null) {
        voices.add(voice);
      }
    }
    if (voices.isEmpty) return null;

    final target = _normaliseLocale(targetLocale);
    final targetLanguage = target.split('-').first;
    final matching = voices.where((voice) {
      final locale = _normaliseLocale(voice['locale'] ?? '');
      if (targetLanguage == 'ta') return locale.startsWith('ta');
      return locale.startsWith('en');
    }).toList();
    if (matching.isEmpty) return null;
    matching.sort(
      (a, b) => _voiceScore(b, target).compareTo(_voiceScore(a, target)),
    );
    final selected = matching.first;
    return {
      'name': selected['name']!,
      'locale': selected['locale']!,
    };
  }

  int _voiceScore(Map<String, String> voice, String targetLocale) {
    final locale = _normaliseLocale(voice['locale'] ?? '');
    final searchable = voice.values.join(' ').toLowerCase();
    var score = 0;
    if (locale == targetLocale) score += 1000;
    if (targetLocale == 'en-in' && locale == 'en-gb') score += 650;
    if (targetLocale == 'en-in' && locale == 'en-us') score += 520;
    if (searchable.contains('natural')) score += 500;
    if (searchable.contains('neural')) score += 450;
    if (searchable.contains('premium')) score += 300;
    if (searchable.contains('enhanced')) score += 260;
    if (searchable.contains('online')) score += 180;
    if (searchable.contains('microsoft')) score += 100;
    if (searchable.contains('google')) score += 90;
    if (searchable.contains('apple') || searchable.contains('siri')) {
      score += 90;
    }
    if (searchable.contains('compact')) score -= 250;
    if (searchable.contains('espeak')) score -= 400;
    if (searchable.contains('basic')) score -= 150;
    return score;
  }

  String _normaliseLocale(String value) =>
      value.trim().replaceAll('_', '-').toLowerCase();

  String _speechFriendly(String value) {
    var text = value.trim();
    text = text.replaceAll('VayPulse', 'Vay Pulse');
    text = text.replaceAll('ESP32', 'E S P thirty two');
    text = text.replaceAll('•', ', ');
    text = text.replaceAll('°C', ' degrees Celsius');
    text = text.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*%'),
      (match) => '${match.group(1)} percent',
    );
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
