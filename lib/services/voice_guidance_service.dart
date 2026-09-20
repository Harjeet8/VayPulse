import 'dart:convert';
import 'phone_voice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceGuidanceService extends ChangeNotifier {
  static const _audio = MethodChannel('com.harjeet.phytosense/care');
  static const cloudEndpoint = String.fromEnvironment('PHYTO_VOICE_ENDPOINT');
  bool speaking = false;
  bool usingCloud = false;
  bool cloudFailed = false;
  double rate = 0.47;
  int _request = 0;
  static const freeVoiceBuild = bool.fromEnvironment('PHYTO_FREE_VOICE', defaultValue: true);
  bool get cloudConfigured => !freeVoiceBuild && Uri.tryParse(cloudEndpoint)?.scheme == 'https';
  String statusLabel({bool tamil = false}) => cloudFailed
      ? (tamil
          ? 'இணையக் குரல் கிடைக்கவில்லை · தொலைபேசி குரல்'
          : 'Cloud voice unavailable · using phone voice')
      : usingCloud
          ? (tamil ? 'இயல்பான இணையக் குரல்' : 'Natural cloud voice')
          : (tamil ? (activeVoiceNeedsInternet ? 'இணையம் தேவை · தொலைபேசி குரல்' : 'தொலைபேசி குரல்') : (activeVoiceNeedsInternet ? 'Phone voice · internet required' : 'Phone voice'));
  final FlutterTts _tts = FlutterTts();
  bool activeVoiceNeedsInternet = false;
  bool _initialized = false;
  String? _activeVoiceName;

  String? get activeVoiceName => _activeVoiceName;

  Future<bool> speak({
    required String text,
    required String languageCode,
  }) async {
    final request = ++_request;
    cloudFailed = false;
    usingCloud = false;
    speaking = true;
    notifyListeners();
    try {
      await _tts.stop();
      try {
        await _audio.invokeMethod('stopAudio');
      } catch (_) {}
      if (request != _request) return true;
      if (cloudConfigured) {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (prefs.getBool('phyto.cloudVoiceConsent') == true) {
            if (Firebase.apps.isEmpty)
              throw StateError('Voice sign-in unavailable');
            final auth = FirebaseAuth.instance;
            final user =
                auth.currentUser ?? (await auth.signInAnonymously()).user;
            final token = await user?.getIdToken();
            if (token == null) throw StateError('Voice sign-in unavailable');
            final response = await http
                .post(Uri.parse(cloudEndpoint),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json'
                    },
                    body: jsonEncode({'text': text, 'language': languageCode}))
                .timeout(const Duration(seconds: 18));
            if (request != _request) return true;
            if (response.statusCode != 200 ||
                response.bodyBytes.length > 8000000 ||
                !(response.headers['content-type'] ?? '').startsWith('audio/'))
              throw StateError('Voice unavailable');
            usingCloud = true;
            notifyListeners();
            final played = await _audio
                .invokeMethod<bool>('playAudio', {'bytes': response.bodyBytes});
            if (request != _request) return true;
            if (played == true) return true;
            throw StateError('Could not play audio');
          }
        } catch (_) {
          if (request != _request) return true;
          cloudFailed = true;
          usingCloud = false;
        }
      }
      rate = (await SharedPreferences.getInstance())
              .getDouble('phyto.voiceRate') ??
          0.47;
      await _configure(languageCode);
      if (request != _request) return true;
      notifyListeners();
      dynamic result;
      try {
        result = await _tts.speak(_speechFriendly(text, languageCode));
      } catch (_) {
        if (!activeVoiceNeedsInternet || request != _request) rethrow;
        result = 0;
      }
      if (request != _request) return true;
      if (result != 1 && result != null && activeVoiceNeedsInternet) {
        await _configure(languageCode, offlineOnly: true);
        if (request != _request) return true;
        notifyListeners();
        result = await _tts.speak(_speechFriendly(text, languageCode));
      }
      return result == null || result == 1;
    } catch (_) {
      return false;
    } finally {
      if (request == _request) {
        speaking = false;
        notifyListeners();
      }
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

  Future<List<PhoneVoice>> availablePhoneVoices(String languageCode,
      {bool? allowInternet}) async {
    final prefs = await SharedPreferences.getInstance();
    return PhoneVoice.ranked(await _tts.getVoices, languageCode,
        allowInternet: allowInternet ?? prefs.getBool('phyto.internetPhoneVoice') ?? false);
  }

  Future<void> selectPhoneVoice(String languageCode, String? name) async {
    await stop();
    final prefs = await SharedPreferences.getInstance();
    final key = 'phyto.phoneVoice.${languageCode == 'ta' ? 'ta' : 'en'}';
    if (name == null) { await prefs.remove(key); }
    else { await prefs.setString(key, name); }
  }

  Future<void> _configure(String languageCode, {bool offlineOnly = false}) async {
    if (!_initialized) {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1);
      _initialized = true;
    }
    final language = languageCode == 'ta' ? 'ta' : 'en';
    final prefs = await SharedPreferences.getInstance();
    final candidates = await availablePhoneVoices(language,
        allowInternet: offlineOnly ? false : null);
    if (candidates.isEmpty) {
      _activeVoiceName = null;
      throw StateError('Install a voice for this language in phone settings.');
    }
    final preferred = prefs.getString('phyto.phoneVoice.$language');
    var selected = candidates.first;
    for (final voice in candidates) {
      if (voice.name == preferred) { selected = voice; break; }
    }
    await _tts.setLanguage(selected.locale);
    await _tts.setSpeechRate(language == 'ta' ? rate * .92 : rate);
    await _tts.setPitch(1.0);
    final result = await _tts.setVoice(selected.engineValue);
    if (result == 0) { throw StateError('Selected phone voice is unavailable'); }
    _activeVoiceName = selected.name;
    activeVoiceNeedsInternet = selected.needsInternet;
  }

  String _speechFriendly(String value, String languageCode) {
    final tamil = languageCode == 'ta';
    var text = value.trim();
    text = text.replaceAll('PhytoSense AI', 'Phyto Sense A I');
    text = text.replaceAll('VayPulse', 'Vay Pulse');
    text = text.replaceAll('ESP32', 'E S P thirty two');
    text = text.replaceAll('•', ', ');
    text = text.replaceAll('°C', tamil ? ' டிகிரி செல்சியஸ்' : ' degrees Celsius');
    text = text.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*%'),
      (match) => '${match.group(1)} ${tamil ? 'சதவீதம்' : 'percent'}',
    );
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> stop() async {
    ++_request;
    speaking = false;
    notifyListeners();
    try { await _tts.stop(); } catch (_) {}
    try {
      await _audio.invokeMethod('stopAudio');
    } catch (_) {}
  }
}
