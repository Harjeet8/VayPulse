import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phytosense_ai/services/phone_voice.dart';
import 'package:phytosense_ai/services/voice_guidance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const low = {
    'name': 'basic',
    'locale': 'en-IN',
    'quality': '100',
    'network_required': 'false'
  };
  const high = {
    'name': 'clear',
    'locale': 'en-IN',
    'quality': '500',
    'network_required': 'false'
  };
  const online = {
    'name': 'online',
    'locale': 'en-IN',
    'quality': '500',
    'network_required': 'true'
  };
  const tamil = {
    'name': 'tamil',
    'locale': 'ta-IN',
    'quality': '400',
    'network_required': 'false'
  };
  test('actual quality outranks names and keeps language isolated', () {
    final voices =
        PhoneVoice.ranked([low, high, tamil], 'en', allowInternet: false);
    expect(voices.map((v) => v.name), ['clear', 'basic']);
    expect(
        PhoneVoice.ranked([low, tamil], 'ta', allowInternet: false).single.name,
        'tamil');
  });
  test('network consent and not-installed flags are honored', () {
    expect(PhoneVoice.ranked([online], 'en', allowInternet: false), isEmpty);
    expect(
        PhoneVoice.ranked([online], 'en', allowInternet: true)
            .single
            .needsInternet,
        isTrue);
    expect(
        PhoneVoice.ranked([
          {...high, 'features': '[notInstalled]'}
        ], 'en', allowInternet: true),
        isEmpty);
  });
  final calls = <MethodCall>[];
  var voices = <Map<String, Object>>[];
  Future<Object?> Function(MethodCall)? speech;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    voices = [low, high, tamil];
    speech = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
            (call) async {
      calls.add(call);
      if (call.method == 'getVoices') {
        return voices;
      }
      if (call.method == 'speak' && speech != null) {
        return await speech!(call);
      }
      return 1;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.harjeet.phytosense/care'),
            (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('com.harjeet.phytosense/care'), null);
  });
  test('saved English choice does not override Tamil', () async {
    final service = VoiceGuidanceService();
    await service.selectPhoneVoice('en', 'basic');
    expect(await service.prepareVoice('en'), 'basic');
    expect(await service.prepareVoice('ta'), 'tamil');
    service.dispose();
  });
  test('missing Tamil does not speak through English default', () async {
    voices = [high];
    final service = VoiceGuidanceService();
    expect(await service.speak(text: 'வணக்கம்', languageCode: 'ta'), isFalse);
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
    expect(service.speaking, isFalse);
    service.dispose();
  });
  test('Tamil speaks measurement units in Tamil', () async {
    final service = VoiceGuidanceService();
    expect(await service.speak(text: '30°C, 40%', languageCode: 'ta'), isTrue);
    final args =
        calls.lastWhere((c) => c.method == 'speak').arguments.toString();
    expect(args, contains('டிகிரி செல்சியஸ்'));
    expect(args, contains('சதவீதம்'));
    expect(service.cloudConfigured, isFalse);
    service.dispose();
  });
  test('failed internet voice falls back to same-language offline voice',
      () async {
    SharedPreferences.setMockInitialValues(
        {'phyto.internetPhoneVoice': true, 'phyto.phoneVoice.en': 'online'});
    voices = [online, high];
    var count = 0;
    speech = (_) async {
      if (count++ == 0) {
        throw PlatformException(code: 'network');
      }
      return 1;
    };
    final service = VoiceGuidanceService();
    expect(await service.speak(text: 'Check the soil.', languageCode: 'en'),
        isTrue);
    expect(service.activeVoiceName, 'clear');
    expect(count, 2);
    service.dispose();
  });
  test('stop cancels an in-flight utterance state', () async {
    final gate = Completer<Object?>();
    final started = Completer<void>();
    speech = (_) {
      started.complete();
      return gate.future;
    };
    final service = VoiceGuidanceService();
    final pending = service.speak(text: 'Check the soil.', languageCode: 'en');
    await started.future;
    await service.stop();
    gate.complete(1);
    await pending;
    expect(service.speaking, isFalse);
    service.dispose();
  });
}
