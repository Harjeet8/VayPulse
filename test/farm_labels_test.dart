import 'package:flutter_test/flutter_test.dart';
import 'package:phytosense_ai/services/farm_label_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = FarmLabelService.instance;
  late List<(String, Map<String, Object>)> sent;
  late bool online;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service.resetForTest();
    sent = [];
    online = true;
    service.sender = (id, payload) async {
      if (!online) return false;
      sent.add((id, payload));
      return true;
    };
  });
  tearDown(service.resetForTest);

  test('a tap is sent with unix seconds (UTC), type and source', () async {
    final before = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await service.record('watered');
    await service.flush();
    expect(sent, hasLength(1));
    final p = sent.single.$2;
    expect(p['type'], 'watered');
    expect(p['source'], 'app');
    expect(p['t'], isA<int>());
    expect((p['t'] as int) - before, inInclusiveRange(0, 2));
    expect(service.pendingCount, 0);
  });

  test('offline taps are queued with the TAP time and sent later in order',
      () async {
    online = false;
    final a = await service.record('watered');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final b = await service.record('pests');
    await service.flush();
    expect(sent, isEmpty);
    expect(service.pendingCount, 2);
    expect(service.today().length, 2, reason: 'shown in today list offline');

    online = true;
    await service.flush();
    expect(sent.map((e) => e.$2['type']), ['watered', 'pests']);
    expect(sent.map((e) => e.$1), [a.id, b.id], reason: 'same ids on retry');
    expect(sent.first.$2['t'], a.t, reason: 'timestamp is tap time');
    expect(service.pendingCount, 0);
  });

  test('queue survives an app restart', () async {
    online = false;
    await service.record('spots');
    service.resetForTest(); // new app run, same phone storage
    service.sender = (id, p) async {
      sent.add((id, p));
      return true;
    };
    await service.start();
    await service.flush();
    expect(sent.single.$2['type'], 'spots');
  });

  test('leaf check sends text only, never the photo', () async {
    await service.recordLeafCheck(
        crop: 'tomato', result: 'early_blight', confidence: 0.8234);
    await service.flush();
    final p = sent.single.$2;
    expect(p.keys.toSet(),
        {'t', 'type', 'crop', 'result', 'confidence', 'source'});
    expect(p['type'], 'leaf_check');
    expect(p['confidence'], 0.823);
  });

  test('push ids sort by time like Firebase push()', () {
    final ids = [
      for (var i = 0; i < 50; i++) PushId.generate(1790000000000 + (i ~/ 5)),
    ];
    expect(ids.every((id) => id.length == 20), isTrue);
    expect([...ids]..sort(), ids);
    expect(ids.toSet().length, ids.length);
  });
}
