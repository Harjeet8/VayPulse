import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phytosense_ai/services/ilai_guide.dart';
import 'package:phytosense_ai/services/ilai_speech.dart';
import 'package:phytosense_ai/services/phone_voice.dart';
import 'package:phytosense_ai/services/voice_names.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('guide repeats supplied advice without deriving a new diagnosis', () {
    const data = IlaiSnapshot(available: true, simulation: false,
      condition: 'Needs checking', problem: 'Verify soil probe placement',
      action: 'Check the sensor before watering', reason: 'Probe outside reference range');
    final answer = IlaiGuide.reply(IlaiTopic.action, data, tamil: false);
    expect(answer, contains('Check the sensor before watering'));
    expect(answer, isNot(contains('Water the soil')));
    expect(IlaiGuide.reply(IlaiTopic.reason, data, tamil: false), contains(data.reason));
  });
  test('unavailable hardware never repeats stale supplied advice', () {
    const stale = IlaiSnapshot(available: false, simulation: false, action: 'Water now');
    for (final topic in [IlaiTopic.summary, IlaiTopic.action, IlaiTopic.reason]) {
      expect(IlaiGuide.reply(topic, stale, tamil: false), isNot(contains('Water now')));
    }
  });
  test('simulation and absent device details are explicit in both languages', () {
    const data = IlaiSnapshot(available: true, simulation: true);
    expect(IlaiGuide.reply(IlaiTopic.action, data, tamil: false), contains('Practice data only'));
    expect(IlaiGuide.reply(IlaiTopic.reason, data, tamil: true), contains('பயிற்சிக்கான தரவு மட்டும்'));
    expect(IlaiGuide.reply(IlaiTopic.action, data, tamil: false), contains('has not supplied'));
  });
  test('English and Tamil questions choose supported topics; unknown asks get help', () {
    expect(IlaiGuide.topic('Why is this happening?'), IlaiTopic.reason);
    expect(IlaiGuide.topic('ஏன் இப்படி?'), IlaiTopic.reason);
    expect(IlaiGuide.topic('என்ன செய்ய வேண்டும்?'), IlaiTopic.action);
    expect(IlaiGuide.topic('What should I do?'), IlaiTopic.action);
    expect(IlaiGuide.topic('ESP32 இணைப்பு'), IlaiTopic.connection);
    expect(IlaiGuide.topic('Tell me a joke'), IlaiTopic.help);
  });
  test('voice names stay stable across ordering and available-voice changes', () async {
    SharedPreferences.setMockInitialValues({});
    const a = PhoneVoice(name: 'engine-a', locale: 'en-IN');
    const b = PhoneVoice(name: 'engine-b', locale: 'en-IN');
    final first = await VoiceNames.forVoices([a, b], 'en', tamilLabels: false);
    final reordered = await VoiceNames.forVoices([b, a], 'en', tamilLabels: false);
    expect(reordered, first);
    expect(first[a.name], isNot(first[b.name]));
    expect((await VoiceNames.forVoices([b], 'en', tamilLabels: false))[b.name], first[b.name]);
    final ta = await VoiceNames.forVoices([a, b], 'en', tamilLabels: true);
    expect(ta[a.name], 'நிலா');
    expect(a.engineValue['name'], 'engine-a');
  });
  test('cancelled speech does not send a late recognition result', () async {
    final gate = Completer<String?>();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(IlaiSpeech.channel, (call) async {
      if (call.method == 'listen') return gate.future;
      return null;
    });
    final speech = IlaiSpeech();
    final pending = speech.listen('ta');
    expect(speech.busy, isTrue);
    await speech.cancel();
    gate.complete('தண்ணீர் தேவையா');
    expect(await pending, isNull);
    expect(speech.busy, isFalse);
    speech.dispose();
    messenger.setMockMethodCallHandler(IlaiSpeech.channel, null);
  });
  test('microphone denial exits the listening state', () async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(IlaiSpeech.channel, (call) async {
      if (call.method == 'listen') throw PlatformException(code: 'permission');
      return null;
    });
    final speech = IlaiSpeech();
    await expectLater(speech.listen('en'), throwsA(isA<PlatformException>()));
    expect(speech.busy, isFalse);
    speech.dispose();
    messenger.setMockMethodCallHandler(IlaiSpeech.channel, null);
  });
}
