import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/services/ilai_brain.dart';
import 'package:phytosense_ai/services/ilai_guide.dart';

void main() {
  IlaiContext ctx(
          {double? moisture, double? temp, double? hum, bool live = true}) =>
      IlaiContext(
        snapshot: IlaiSnapshot(
            available: live,
            simulation: false,
            condition: 'Needs water',
            problem: 'Soil is drying',
            action: 'Water at the root',
            reason: 'Soil moisture fell'),
        soilMoisture: moisture,
        temperature: temp,
        humidity: hum,
        now: DateTime(2026, 9, 30, 9),
      );

  test('every suggestion chip leads to its own topic, in both languages', () {
    const intents = {
      'summary', 'action', 'reason', 'water', 'heat', 'humidity', 'disease',
      'leafCheck', 'pests', 'labels', 'help', 'otherCrop', 'connection',
      'nodeLight',
    };
    for (final tamil in [false, true]) {
      for (final intent in intents) {
        final chip = _chipFor(intent, tamil);
        final r = IlaiBrain().respond(chip, ctx(moisture: 40), tamil: tamil);
        expect(r.intent, intent, reason: '"$chip" (tamil=$tamil)');
      }
    }
  });

  test('water answer uses the real soil reading', () {
    final b = IlaiBrain();
    expect(b.respond('does it need water', ctx(moisture: 20), tamil: false).text,
        contains('20%'));
    expect(b.respond('should I water now', ctx(moisture: 85), tamil: false).text,
        contains("Don't water"));
    expect(b.respond('நீர் தேவையா?', ctx(moisture: 50), tamil: true).text,
        contains('50%'));
  });

  test('no fresh reading -> honest, no guess', () {
    final r = IlaiBrain()
        .respond('does it need water', ctx(live: false), tamil: false);
    expect(r.text, contains("won't guess"));
  });

  test('"why?" follows the previous topic', () {
    final b = IlaiBrain();
    b.respond('does it need water', ctx(moisture: 20), tamil: false);
    final r = b.respond('why?', ctx(moisture: 20), tamil: false);
    expect(r.intent, 'water');
    expect(r.text, contains('Why'));
  });

  test('statements are recorded; questions are not', () {
    final b = IlaiBrain();
    expect(b.respond('I watered the plants', ctx(), tamil: false).recordLabel,
        'watered');
    expect(b.respond('நீர் ஊற்றினேன்', ctx(), tamil: true).recordLabel,
        'watered');
    expect(b.respond('I added fertilizer', ctx(), tamil: false).recordLabel,
        'fertilizer');
    expect(
        b.respond('why is my plant wilting?', ctx(), tamil: false).recordLabel,
        isNull);
    expect(b.respond('should I water now', ctx(), tamil: false).recordLabel,
        isNull);
  });

  test('small talk, identity and typos', () {
    final b = IlaiBrain();
    expect(b.respond('vanakkam', ctx(), tamil: true).intent, 'greet');
    expect(b.respond('thank you!', ctx(), tamil: false).intent, 'thanks');
    final who = b.respond('who are you', ctx(), tamil: false);
    expect(who.intent, 'identity');
    expect(who.text, contains('VayPulse'));
    expect(b.respond('my plant has fungus', ctx(), tamil: false).intent,
        'disease');
    expect(b.respond('temperture?', ctx(temp: 39), tamil: false).intent, 'heat');
    expect(b.respond('can I check my rice leaf', ctx(), tamil: false).intent,
        'otherCrop');
  });

  test('nonsense gets a friendly way forward, not a dead end', () {
    final r = IlaiBrain().respond('qwzx plomb', ctx(), tamil: false);
    expect(r.intent, 'unknown');
    expect(r.followUps, isNotEmpty);
  });
}

String _chipFor(String intent, bool tamil) {
  const en = {
    'summary': 'How is my plant?', 'action': 'What should I do?', 'reason': 'Why?',
    'water': 'Does it need water?', 'heat': 'Is it too hot?',
    'humidity': 'Humidity risk?', 'disease': 'Leaves have spots',
    'leafCheck': 'Check a leaf', 'pests': 'Pests help',
    'labels': 'Record what I did', 'help': 'What can you do?',
    'otherCrop': 'Rice / banana / coconut?', 'connection': 'Connect my sensor',
    'nodeLight': 'Node light',
  };
  const ta = {
    'summary': 'செடி எப்படி உள்ளது?', 'action': 'என்ன செய்ய வேண்டும்?',
    'reason': 'ஏன்?', 'water': 'நீர் தேவையா?', 'heat': 'வெப்பம் அதிகமா?',
    'humidity': 'ஈரப்பத ஆபத்து?', 'disease': 'இலைகளில் புள்ளிகள்',
    'leafCheck': 'இலை சோதனை', 'pests': 'பூச்சி உதவி',
    'labels': 'செய்ததைப் பதிவு செய்', 'help': 'என்ன செய்ய முடியும்?',
    'otherCrop': 'நெல் / வாழை / தென்னை?', 'connection': 'சாதனத்தை இணை',
    'nodeLight': 'கருவி விளக்கு',
  };
  return (tamil ? ta : en)[intent]!;
}
