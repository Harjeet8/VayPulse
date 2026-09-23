import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'phone_voice.dart';

/// Friendly display aliases only. The original engine ID selects the audio.
class VoiceNames {
  static const english = ['Nila', 'Malar', 'Kavin', 'Arun', 'Thendral', 'Kayal',
    'Iris', 'Rowan', 'Sage', 'Maya', 'Fern', 'Asha'];
  static const tamil = ['நிலா', 'மலர்', 'கவின்', 'அருண்', 'தென்றல்', 'கயல்',
    'ஐரிஸ்', 'ரோவன்', 'சேஜ்', 'மாயா', 'ஃபெர்ன்', 'ஆஷா'];
  static Future<Map<String, String>> forVoices(List<PhoneVoice> voices,
      String language, {required bool tamilLabels}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'phyto.voiceAliases.${language == 'ta' ? 'ta' : 'en'}';
    final indices = <String, int>{};
    try {
      final saved = jsonDecode(prefs.getString(key) ?? '{}');
      if (saved is Map) {
        for (final entry in saved.entries) {
          if (entry.key is String && entry.value is int && entry.value >= 0) {
            indices[entry.key] = entry.value;
          }
        }
      }
    } catch (_) { /* Rebuild corrupt display preferences without altering voice selection. */ }
    var next = indices.values.fold<int>(-1, (a, b) => a > b ? a : b) + 1;
    final result = <String, String>{};
    final names = tamilLabels ? tamil : english;
    for (final voice in voices) {
      final id = '${voice.locale}|${voice.name}';
      final index = indices.putIfAbsent(id, () => next++);
      final round = index ~/ names.length;
      result[voice.name] = '${names[index % names.length]}${round == 0 ? '' : ' ${round + 1}'}';
    }
    await prefs.setString(key, jsonEncode(indices));
    return result;
  }
}
